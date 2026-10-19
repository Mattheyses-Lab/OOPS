% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Image < handle
    %IMAGE Owns a four-angle source, a mask, objects, and numerical results.
    % Processing belongs in oops.analysis; graphics belong to the controller.
    % Active/selected IDs are persistent navigation bookmarks, not UI handles.

    properties
        Name (1,1) string = "Image"
    end

    properties (SetAccess=private)
        ID (1,1) string = ""
        PixelSize (1,1) struct = struct('X',1,'Y',1,'UnitX',"px",'UnitY',"px")
        ActiveObjectID (1,1) string = ""
        SelectedObjectIDs (:,1) string = strings(0,1)
        Input (:,1) matlabx.image.Image5D = matlabx.image.Image5D.empty(0,1)
        FrameLocations (4,3) double % [component Z T], in PolarizationAngles order
        Mask (:,:) logical = false(0,0)
        Objects (:,1) oops.model.Object = oops.model.Object.empty(0,1)
        Results (1,1) struct = struct()
        CorrectionProvenance (1,1) oops.model.CorrectionProvenance = ...
            oops.model.CorrectionProvenance.raw()
        MaskProvenance (1,1) oops.model.MaskProvenance = ...
            oops.model.MaskProvenance.unknown()
        SegmentationParameters (:,1) oops.analysis.segment.Parameters = oops.analysis.segment.Parameters.empty(0,1)
        IntensityDisplayRange double = []
        OrderDisplayRange (1,2) double = [0 1]
        AuxiliaryChannels (:,1) oops.model.AuxiliaryChannelAssignment = ...
            oops.model.AuxiliaryChannelAssignment.empty(0,1)
    end

    properties (Constant)
        PolarizationAngles = [0 45 90 135] % counterclockwise, degrees
    end

    properties (SetAccess=?oops.model.Group)
        Parent (:,1) oops.model.Group = oops.model.Group.empty(0,1)
    end

    properties (Access=private, Transient)
        ObjectListeners event.listener = event.listener.empty()
    end

    properties (Dependent, SetAccess=private)
        SummaryTable (:,:) table
        IsLoaded
        ActiveObject
        Order
        Azimuth
    end

    %% Model events
    events
        NavigationChanged
        ObjectsChanged
        DataChanged
    end

    %% Construction
    methods (Access=?oops.model.Group)

        function obj = Image(parent,input,name)
        %IMAGE Validate four-angle geometry and attach an input to its owning group.

            obj.ID = matlabx.utils.text.uniqueID();

            % Four polarization-frame locations, stored as [component Z T] rows.
            locations = oops.io.fourAngleLocations(input);
            obj.Parent = parent;
            obj.Input = input;
            obj.PixelSize = oops.io.pixelSize(input);
            obj.FrameLocations = locations;
            obj.Name = name;
        end

    end

    %% Lifecycle
    methods

        function delete(obj)
        %DELETE Release owned listeners and descendants without processing image data.

            % Release each image's input buffer, objects, and forwarding subscriptions.
            for k = 1:numel(obj)
                delete(obj(k).ObjectListeners);

                if ~isempty(obj(k).Input)
                    obj(k).Input.unload();
                end

                delete(obj(k).Objects);
                delete(obj(k).AuxiliaryChannels);
            end

        end

    end

    %% Input access and memory residency
    methods

        function S = toStruct(obj,projectFolder)
        %TOSTRUCT Capture file identity and compact reproducible analysis state.

            arguments
                obj
                projectFolder (1,1) string = ""
            end

            objectData = arrayfun(@(item) item.toStruct(),obj.Objects);
            parameters = struct.empty(0,1);

            if ~isempty(obj.SegmentationParameters)
                parameters = obj.SegmentationParameters.toStruct();
            end

            auxiliaryChannels = arrayfun( ...
                @(item) item.toStruct(projectFolder),obj.AuxiliaryChannels);

            S = struct( ...
                'ID',obj.ID, ...
                'Name',obj.Name, ...
                'Source',oops.io.project.sourceReference(obj.Input,projectFolder), ...
                'PixelSize',obj.PixelSize, ...
                'FrameLocations',obj.FrameLocations, ...
                'AuxiliaryChannels',auxiliaryChannels, ...
                'Objects',objectData, ...
                'FPMCalculated',~isempty(obj.Order) && ~isempty(obj.Azimuth), ...
                'CorrectionProvenance',obj.CorrectionProvenance.toStruct(), ...
                'MaskProvenance',obj.MaskProvenance.toStruct(), ...
                'SegmentationParameters',parameters, ...
                'IntensityDisplayRange',obj.IntensityDisplayRange, ...
                'OrderDisplayRange',obj.OrderDisplayRange, ...
                'ActiveObjectID',obj.ActiveObjectID, ...
                'SelectedObjectIDs',obj.SelectedObjectIDs);
        end

        function restoreStruct(obj,S,assignedCalibrationIDs)
        %RESTORESTRUCT Restore compact state after the source has been reopened.

            if nargin < 3
                assignedCalibrationIDs = strings(0,1);
            end

            obj.ID = string(S.ID);
            obj.PixelSize = S.PixelSize;
            obj.FrameLocations = double(S.FrameLocations);
            obj.IntensityDisplayRange = double(S.IntensityDisplayRange);
            obj.OrderDisplayRange = double(S.OrderDisplayRange);

            if isfield(S,'CorrectionProvenance')
                obj.CorrectionProvenance = ...
                    oops.model.CorrectionProvenance.fromStruct(S.CorrectionProvenance);
            else
                % Projects saved before provenance tracking used the group's
                % assigned calibration whenever corrected results were generated.
                obj.CorrectionProvenance = ...
                    oops.model.CorrectionProvenance.flatField(assignedCalibrationIDs);
            end

            if isfield(S,'MaskProvenance')
                provenance = oops.model.MaskProvenance.fromStruct(S.MaskProvenance);
            elseif ~isempty(S.Objects)
                provenance = oops.model.MaskProvenance.segmented(obj.CorrectionProvenance);
            else
                provenance = oops.model.MaskProvenance.unknown();
            end

            if ~isempty(S.Objects)
                lists = arrayfun(@(item) double(item.PixelIdxList(:)),S.Objects, ...
                    'UniformOutput',false);
                mask = false(obj.Input.SizeY,obj.Input.SizeX);

                for k = 1:numel(lists)
                    mask(lists{k}) = true;
                end

                parameters = oops.analysis.segment.Parameters.empty(0,1);

                if ~isempty(S.SegmentationParameters)
                    parameters = oops.analysis.segment.Parameters.fromStruct(S.SegmentationParameters);
                end

                obj.setMask(mask,lists,parameters,provenance);

                for k = 1:numel(obj.Objects)
                    obj.Objects(k).restoreStruct(S.Objects(k));
                end

            end

            obj.setActiveObject(string(S.ActiveObjectID));
            obj.setSelectedObjects(string(S.SelectedObjectIDs));
        end

        function assignment = addAuxiliaryChannel(obj,channelID,input,componentIndex,displayRange)
        %ADDAUXILIARYCHANNEL Assign one single-plane source component by semantic ID.

            arguments
                obj
                channelID (1,1) string
                input (1,1) matlabx.image.Image5D
                componentIndex (1,1) double {mustBeInteger,mustBePositive}
                displayRange double = []
            end

            if isempty(obj.Parent) || isempty(obj.Parent.Parent) || ...
                    isempty(obj.Parent.Parent.AuxiliaryChannels.findByID(channelID))
                error('oops:model:UnknownAuxiliaryChannel', ...
                    'The auxiliary channel ID is not registered with this project.');
            end

            component = input.getComponent(componentIndex);

            if component.SizeY ~= obj.Input.SizeY || component.SizeX ~= obj.Input.SizeX
                error('oops:model:AuxiliarySizeMismatch', ...
                    'Auxiliary channel size [%d %d] does not match image size [%d %d].', ...
                    component.SizeY,component.SizeX,obj.Input.SizeY,obj.Input.SizeX);
            end

            assignment = oops.model.AuxiliaryChannelAssignment( ...
                channelID,input,componentIndex,displayRange);
            channelIDs = string({obj.AuxiliaryChannels.ChannelID});
            existing = find(channelIDs == channelID,1);

            if isempty(existing)
                obj.AuxiliaryChannels(end+1,1) = assignment;
            else
                old = obj.AuxiliaryChannels(existing);
                obj.AuxiliaryChannels(existing) = assignment;
                delete(old);
            end

            notify(obj,'DataChanged', ...
                oops.model.events.DataChanged(obj.ID,"AuxiliaryChannels"));
        end

        function assignment = getAuxiliaryChannel(obj,channelID)
        %GETAUXILIARYCHANNEL Resolve this image's assignment for a semantic ID.

            channelIDs = string({obj.AuxiliaryChannels.ChannelID});
            index = find(channelIDs == string(channelID),1);

            if isempty(index)
                assignment = oops.model.AuxiliaryChannelAssignment.empty(0,1);
            else
                assignment = obj.AuxiliaryChannels(index);
            end
        end

        function tf = get.IsLoaded(obj)
        %GET.ISLOADED Report whether the source has a resident full input buffer.

            tf = obj.Input.IsLoaded;
        end

        function loadInput(obj)
        %LOADINPUT Load the source buffer and notify only when residency changes.

            try

                % Input residency before loading, used to detect an actual state change.
                wasLoaded = obj.IsLoaded;

                if ~wasLoaded
                    oops.Log.INFO("Loading input pixels for " + obj.Name + ".");
                end

                obj.Input.load();

                if obj.IsLoaded ~= wasLoaded
                    oops.Log.INFO("Input loaded for " + obj.Name + ".");
                    notify(obj,'DataChanged',oops.model.events.DataChanged(obj.ID,"InputLoaded"));
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function unloadInput(obj)
        %UNLOADINPUT Release a file-backed input buffer and notify residency changes.

            try

                % Input residency before unloading, used to detect an actual state change.
                wasLoaded = obj.IsLoaded;
                obj.Input.unload();

                if obj.IsLoaded ~= wasLoaded
                    notify(obj,'DataChanged',oops.model.events.DataChanged(obj.ID,"InputUnloaded"));
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function frame = getFrame(obj,index)
        %GETFRAME Read one polarization frame in 0/45/90/135-degree order.

            arguments
                obj
                index (1,1) double {mustBeInteger,mustBeInRange(index,1,4)}
            end

            try

                % Component, Z, and T indices corresponding to this polarization angle.
                location = obj.FrameLocations(index,:);

                % Numeric image plane read from the mapped four-angle input location.
                frame = obj.Input.getPlane(location(1),location(2),location(3));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Stored analysis outputs
    methods

        function values = get.Order(obj)
        %GET.ORDER Return numeric per-pixel order without creating display images.

            % Empty result until per-pixel order has been computed.
            values = [];

            if isfield(obj.Results,'Order')
                values = obj.Results.Order;
            end

        end

        function values = get.Azimuth(obj)
        %GET.AZIMUTH Return numeric axial angles in radians, counterclockwise from X.

            % Empty result until per-pixel axial angles have been computed.
            values = [];

            if isfield(obj.Results,'Azimuth')
                values = obj.Results.Azimuth;
            end

        end

        function setCorrectionResults(obj,average,calibrationIDs)
        %SETCORRECTIONRESULTS Commit durable outputs from a new correction.

            validateattributes(average,{'double'},{'real','size',[obj.Input.SizeY,obj.Input.SizeX]});

            % Correction state changes can make a generated mask stale, but
            % object membership remains user-owned until explicitly replaced.
            obj.CorrectionProvenance = ...
                oops.model.CorrectionProvenance.flatField(calibrationIDs);
            obj.setResults(struct('AverageIntensity',average));
        end

        function setAverageIntensity(obj,average)
        %SETAVERAGEINTENSITY Cache a current average without resetting objects.
        % This path restores an omitted raster cache whose correction provenance
        % already matches the source assignment represented by the project.

            validateattributes(average,{'double'}, ...
                {'real','size',[obj.Input.SizeY,obj.Input.SizeX]});
            obj.Results.AverageIntensity = average;
            notify(obj,'DataChanged',oops.model.events.DataChanged( ...
                obj.ID,"AverageIntensity"));
        end

        function setResults(obj,results)
        %SETRESULTS Store image-level analysis outputs and notify listeners.

            arguments
                obj
                results (1,1) struct
            end

            try
                obj.Results = results;

                % Reset stored intensity and polarization measurements on each
                % existing object, leaving its morphology measurements unchanged.
                for k = 1:numel(obj.Objects)
                    obj.Objects(k).resetMeasurements(oops.model.Object.imageMeasurementNames());
                end

                notify(obj,'DataChanged',oops.model.events.DataChanged(obj.ID,"Results"));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function setSegmentationCache(obj,average,cache)
        %SETSEGMENTATIONCACHE Store reconstructible threshold-adjustment inputs.
        % This cache does not change the committed mask, object membership, or
        % scalar measurements, so restoring it does not publish a model event.

            arguments
                obj
                average (:,:) double
                cache (1,1) struct
            end

            validateattributes(average,{'double'}, ...
                {'real','size',[obj.Input.SizeY,obj.Input.SizeX]});
            obj.Results.AverageIntensity = average;
            obj.Results.Segmentation = cache;
        end

    end

    %% Mask and object membership
    methods

        function clearSegmentation(obj)
        %CLEARSEGMENTATION Remove objects whose membership belongs to obsolete inputs.

            % Previously owned objects to destroy after clearing their bookmarks.
            old = obj.Objects;

            % Previous object IDs included in the collection-change notification.
            oldIDs = oops.model.internal.ids(old);
            delete(obj.ObjectListeners);
            obj.ObjectListeners = event.listener.empty();
            obj.SegmentationParameters = oops.analysis.segment.Parameters.empty(0,1);
            obj.MaskProvenance = oops.model.MaskProvenance.unknown();
            obj.Mask = false(0,0);
            obj.Objects = oops.model.Object.empty(0,1);

            % Reset bookmarks before destroying the objects they referred to.
            obj.setActiveObject("");
            obj.setSelectedObjects(strings(0,1));
            delete(old);
            notify(obj,'ObjectsChanged',oops.model.events.ObjectsChanged(obj.ID,strings(0,1),oldIDs));
            notify(obj,'DataChanged',oops.model.events.DataChanged(obj.ID,"Mask"));
        end

        function setMask(obj,mask,pixelLists,parameters,provenance)
        %SETMASK Validate and replace mask membership and its owned object collection.

            % Analysis supplies the partition; the model only validates/stores it.
            arguments
                obj
                mask (:,:) logical
                pixelLists (1,:) cell
                parameters (:,1) oops.analysis.segment.Parameters = oops.analysis.segment.Parameters.empty(0,1)
                provenance (1,1) oops.model.MaskProvenance = oops.model.MaskProvenance.unknown()
            end

            try

                if ~isequal(size(mask),[obj.Input.SizeY,obj.Input.SizeX])
                    error( ...
                    'oops:model:MaskSizeMismatch','Mask must match the input image dimensions.');
                end

                % Combined pixel-index buffer used to check that the object lists
                % cover the entire mask exactly once before replacing any objects.
                allPixels = zeros(sum(cellfun(@numel,pixelLists)),1);

                % Number of indices already copied into the combined pixel buffer.
                offset = 0;

                % Validate and concatenate the pixel indices of each candidate object.
                for k = 1:numel(pixelLists)

                    % Parent-image linear indices belonging to the current candidate object.
                    pixels = pixelLists{k};
                    validateattributes(pixels,{'numeric'}, ...
                        {'vector','nonempty','integer','positive','<=',numel(mask)});
                    allPixels(offset+(1:numel(pixels))) = double(pixels(:));
                    offset = offset + numel(pixels);
                end

                if ~isequal(sort(allPixels),find(mask))
                    error( ...
                    'oops:model:InvalidObjectPartition', ...
                    'Object pixel lists must partition the mask without omissions or overlaps.');
                end

                if numel(parameters) > 1
                    error('oops:model:InvalidParameters','Expected at most one segmentation recipe.');
                end

                % Replacement objects, built from the validated pixel lists before
                % retiring the previous collection.
                next = oops.model.Object.empty(0,1);

                % Create one replacement object for each validated pixel-index list.
                for k = 1:numel(pixelLists)
                    next(end+1,1) = oops.model.Object(obj,pixelLists{k}); %#ok<AGROW>
                end

                % Previous object collection to retire after committing the replacements.
                old = obj.Objects;

                % Previous object IDs for the collection-change notification.
                oldIDs = strings(0,1);

                % Replacement object IDs for the collection-change notification.
                newIDs = strings(0,1);

                % Collect the previous object IDs for the membership-change event.
                for k = 1:numel(old)
                    oldIDs(k,1) = old(k).ID;
                end

                % Collect the replacement object IDs for the membership-change event.
                for k = 1:numel(next)
                    newIDs(k,1) = next(k).ID;
                end

                % Subscriptions that forward replacement-object changes through this image.
                nextListeners = event.listener.empty();

                % Forward data-change events from each replacement object through this image.
                for k = 1:numel(next)
                    nextListeners(end+1) = addlistener(next(k),'DataChanged', ...
                        @(~,e) notify(obj,'DataChanged',e)); %#ok<AGROW>
                end

                % Commit membership, then publish events against the new state.
                delete(obj.ObjectListeners);
                obj.ObjectListeners = nextListeners;
                obj.SegmentationParameters = parameters;
                obj.MaskProvenance = provenance;
                obj.Mask = mask;
                obj.Objects = next;
                obj.setActiveObject("");
                obj.setSelectedObjects(strings(0,1));
                delete(old);
                notify(obj,'ObjectsChanged',oops.model.events.ObjectsChanged(obj.ID,newIDs,oldIDs));
                oops.Log.INFO(sprintf("Stored mask for %s: %d objects.",obj.Name,numel(next)));
                notify(obj,'DataChanged',oops.model.events.DataChanged(obj.ID,"Mask"));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function removeObjects(obj,regions)
        %REMOVEOBJECTS Remove owned regions and their pixels without recreating survivors.
        % IDs and measurements of surviving objects remain unchanged. The mask
        % continues to be partitioned exactly by the remaining PixelIdxLists.

            try

                % Validated IDs of the objects requested for deletion.
                ids = oops.model.internal.validateIDs(regions,obj.Objects,'oops:model:UnknownObject',false);

                if isempty(ids)
                    return;
                end

                % Object IDs before deletion, aligned with the object and listener arrays.
                oldIDs = oops.model.internal.ids(obj.Objects);

                % Logical membership flags marking which objects/listeners to remove.
                remove = ismember(oldIDs,ids);

                % Object handles to destroy after removing their pixels and bookmarks.
                removed = obj.Objects(remove);

                % Clear each deleted object's pixels from the parent mask.
                for k = 1:numel(removed)
                    obj.Mask(removed(k).PixelIdxList) = false;
                end

                % Listener order follows Objects. Keep survivor subscriptions
                % instead of destroying/recreating the whole collection.
                delete(obj.ObjectListeners(remove));
                obj.ObjectListeners = obj.ObjectListeners(~remove);
                obj.Objects = obj.Objects(~remove);

                if ismember(obj.ActiveObjectID,ids)
                    obj.setActiveObject("");
                end

                obj.setSelectedObjects(obj.SelectedObjectIDs(~ismember(obj.SelectedObjectIDs,ids)));
                delete(removed);

                % Surviving object IDs used to update counts and notify observers.
                newIDs = oops.model.internal.ids(obj.Objects);

                if ~isempty(obj.SegmentationParameters)
                    obj.SegmentationParameters = obj.SegmentationParameters.withCounts( ...
                        obj.SegmentationParameters.CandidateCount,numel(newIDs));
                end

                notify(obj,'ObjectsChanged',oops.model.events.ObjectsChanged(obj.ID,newIDs,oldIDs));
                notify(obj,'DataChanged',oops.model.events.DataChanged(obj.ID,"Mask"));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Active and selected navigation
    methods

        function setObjectLabels(obj,regions,label)
        %SETOBJECTLABELS Apply one project label to an owned object batch.

            try

                % Object IDs validated against this image and ordered by membership.
                ids = oops.model.internal.validateIDs( ...
                    regions,obj.Objects,'oops:model:UnknownObject',false);

                if isempty(ids)
                    return;
                end

                % Stable label ID accepted from either a label handle or text ID.
                if isa(label,'oops.model.ObjectLabel')
                    labelID = label.ID;
                else
                    labelID = string(label);
                end

                % Project registry is authoritative for valid label identities.
                project = obj.Parent.Parent;
                registered = project.Labels.getByID(labelID);

                if isempty(registered)
                    error('oops:model:UnknownLabel','Unknown object label ID: %s',labelID);
                end

                % Requested object handles resolved once for an atomic batch update.
                targets = obj.Objects(ismember(oops.model.internal.ids(obj.Objects),ids));

                % Store only changed label IDs and emit one image-level data event.
                changed = false;

                for k = 1:numel(targets)

                    if targets(k).LabelID ~= labelID
                        targets(k).assignLabelID(labelID);
                        changed = true;
                    end

                end

                if changed
                    notify(obj,'DataChanged', ...
                        oops.model.events.DataChanged(obj.ID,"ObjectLabels"));
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function region = get.ActiveObject(obj)
        %GET.ACTIVEOBJECT Resolve the image bookmark against its current mask objects.

            region = oops.model.internal.resolve(obj.Objects,obj.ActiveObjectID);
        end

        function setActiveObject(obj,region)
        %SETACTIVEOBJECT Remember an object independently of the checked batch set.

            try

                % Validated ID of the member to activate, or an empty active bookmark.
                id = oops.model.internal.validateIDs(region,obj.Objects,'oops:model:UnknownObject',true);

                % Previously active object ID, retained for the navigation event.
                old = obj.ActiveObjectID;

                if old == id
                    return;
                end

                obj.ActiveObjectID = id;
                notify(obj,'NavigationChanged',oops.model.events.NavigationChanged( ...
                    "Image",obj.ID,"ActiveObjectID",old,id));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function setSelectedObjects(obj,regions)
        %SETSELECTEDOBJECTS Store batch membership by ID, without moving the active object.

            try

                % Validated member IDs in canonical collection order.
                ids = oops.model.internal.validateIDs(regions,obj.Objects,'oops:model:UnknownObject',false);

                % Previously selected object IDs, retained to detect unchanged selection.
                old = obj.SelectedObjectIDs;

                if isequal(old,ids)
                    return;
                end

                obj.SelectedObjectIDs = ids;
                notify(obj,'NavigationChanged',oops.model.events.NavigationChanged( ...
                    "Image",obj.ID,"SelectedObjectIDs",old,ids));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Persistent display ranges
    methods

        function value = getDisplayRange(obj,domain)
        %GETDISPLAYRANGE Return the explicitly stored user display limits.

            domain = string(domain);

            if ~ismember(domain,["Intensity","Order"])
                error('oops:model:UnknownDisplayDomain','Unknown display domain: %s',domain);
            end

            value = obj.(domain+"DisplayRange");
        end

        function setDisplayRange(obj,domain,value)
        %SETDISPLAYRANGE Store user limits without applying project auto-scale policy.

            try
                domain = string(domain);

                if ~ismember(domain,["Intensity","Order"])
                    error('oops:model:UnknownDisplayDomain','Unknown display domain: %s',domain);
                end

                validateattributes(value,{'double'},{'real','finite','vector','numel',2});
                value = sort(reshape(value,1,2));

                if value(1) >= value(2)
                    error('oops:model:InvalidDisplayRange','Display limits must span a positive range.');
                end

                if domain == "Order" && (value(1) < 0 || value(2) > 1)
                    error('oops:model:InvalidDisplayRange','Order limits must lie between zero and one.');
                end

                obj.(domain+"DisplayRange") = value;
                notify(obj,'DataChanged',oops.model.events.DataChanged(obj.ID,"DisplayRange"));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Derived summaries
    methods

        function info = infoStruct(obj)
        %INFOSTRUCT Return compact diagnostic metadata without numerical image arrays.

            % File-backed source identity used to reopen this image between sessions.
            source = struct('FilePath',"",'SeriesIndex',NaN);

            if ~isempty(obj.Input) && obj.Input.IsFileBacked
                source.FilePath = string(obj.Input.Source.FilePath);
                source.SeriesIndex = double(obj.Input.Source.SeriesIndex);
            end

            % Parent group assignment compared against the correction represented by results.
            assignedCalibrationIDs = strings(0,1);
            groupName = "";

            if ~isempty(obj.Parent)
                groupName = obj.Parent.Name;
                assignedCalibrationIDs = obj.Parent.CalibrationIDs;
            end

            % Stored segmentation recipe, empty for imported/manual/unknown masks.
            segmentation = struct();

            if ~isempty(obj.SegmentationParameters)
                segmentation = obj.SegmentationParameters.toStruct();
            end

            % Result field names communicate availability without copying raster values.
            resultFields = string(fieldnames(obj.Results));
            correctionMatches = obj.CorrectionProvenance.matchesAssignments( ...
                assignedCalibrationIDs);
            maskCurrent = ~isempty(obj.Mask) && ...
                obj.MaskProvenance.isCurrent(obj.CorrectionProvenance);

            % Semantic assignments summarized without reading their source planes.
            auxiliary = struct('ChannelID',{},'ChannelName',{},'SourceChannel',{}, ...
                'ComponentIndex',{},'FilePath',{},'DisplayRange',{});

            for k = 1:numel(obj.AuxiliaryChannels)
                assignment = obj.AuxiliaryChannels(k);
                definition = oops.model.AuxiliaryChannelDefinition.empty(0,1);
                channelName = "Unknown";

                if ~isempty(obj.Parent) && ~isempty(obj.Parent.Parent)
                    definition = obj.Parent.Parent.AuxiliaryChannels.findByID(assignment.ChannelID);
                end

                if ~isempty(definition)
                    channelName = definition.Name;
                end

                filePath = "In-memory source";

                if assignment.Input.IsFileBacked
                    filePath = string(assignment.Input.Source.FilePath);
                end

                auxiliary(end+1) = struct( ... %#ok<AGROW>
                    'ChannelID',assignment.ChannelID, ...
                    'ChannelName',channelName, ...
                    'SourceChannel',assignment.Input.getComponentName(assignment.ComponentIndex), ...
                    'ComponentIndex',assignment.ComponentIndex, ...
                    'FilePath',filePath, ...
                    'DisplayRange',assignment.DisplayRange);
            end

            info = struct( ...
                'Identity',struct( ...
                    'Name',obj.Name, ...
                    'ID',obj.ID, ...
                    'Group',groupName), ...
                'Input',struct( ...
                    'Source',source, ...
                    'Dimensions',struct( ...
                        'Y',obj.Input.SizeY, ...
                        'X',obj.Input.SizeX, ...
                        'Components',obj.Input.NumComponents, ...
                        'Z',obj.Input.SizeZ, ...
                        'T',obj.Input.SizeT), ...
                    'ComponentClass',string(obj.Input.getComponentClass(1)), ...
                    'PixelSize',obj.PixelSize, ...
                    'FrameLocations',obj.FrameLocations, ...
                    'Loaded',obj.IsLoaded), ...
                'AuxiliaryChannels',auxiliary, ...
                'Correction',struct( ...
                    'Provenance',obj.CorrectionProvenance.toStruct(), ...
                    'AssignedCalibrationIDs',assignedCalibrationIDs, ...
                    'MatchesAssignment',correctionMatches, ...
                    'AverageIntensityAvailable',isfield(obj.Results,'AverageIntensity')), ...
                'Mask',struct( ...
                    'Provenance',obj.MaskProvenance.toStruct(), ...
                    'CurrentAgainstCorrection',maskCurrent, ...
                    'SegmentationParameters',segmentation, ...
                    'ForegroundPixels',nnz(obj.Mask), ...
                    'ObjectCount',numel(obj.Objects)), ...
                'Analysis',struct( ...
                    'ResultFields',resultFields, ...
                    'OrderAvailable',isfield(obj.Results,'Order'), ...
                    'AzimuthAvailable',isfield(obj.Results,'Azimuth')), ...
                'Display',struct( ...
                    'IntensityRange',obj.IntensityDisplayRange, ...
                    'OrderRange',obj.OrderDisplayRange), ...
                'Navigation',struct( ...
                    'ActiveObjectID',obj.ActiveObjectID, ...
                    'SelectedObjectCount',numel(obj.SelectedObjectIDs)));
        end

        function T = get.SummaryTable(obj)
        %GET.SUMMARYTABLE Describe input metadata, stored segmentation, and results.
        % No input buffer is loaded and no analysis is performed for this table.

            % Row labels for input metadata and currently stored analysis values.
            names = ["Name","Dimensions","Input image class","Pixel size", ...
                "Total objects","Mean pixel Order","FPM stack loaded","Input in memory"];

            % Per-axis pixel sizes and units extracted from the input metadata.
            pixelSize = obj.PixelSize;

            % Mean per-pixel order, initially unavailable until order data exist.
            meanOrder = NaN;

            if ~isempty(obj.Order)
                meanOrder = mean(obj.Order,'all','omitnan');
            end

            % Text and scalar values corresponding to the summary row labels.
            values = {obj.Name,sprintf('%d x %d',obj.Input.SizeY,obj.Input.SizeX), ...
                obj.Input.getComponentClass(1), ...
                sprintf('X: %g %s; Y: %g %s',pixelSize.X,pixelSize.UnitX,pixelSize.Y,pixelSize.UnitY), ...
                numel(obj.Objects),sprintf('%.2f',meanOrder),true,obj.IsLoaded};

            % Use the image's committed recipe, never the project's next-run
            % defaults. Other strategies may supply a different parameter set.

            % Segmentation parameters committed with this image's current mask.
            recipe = obj.SegmentationParameters;

            if ~isempty(recipe)
                names(end+1) = "Mask strategy";
                values{end+1} = recipe.Strategy;

                % Append the committed value of each strategy-specific segmentation parameter.
                for parameter = string(fieldnames(recipe.Values))'
                    names(end+1) = "Mask " + parameter; %#ok<AGROW>
                    values{end+1} = recipe.Values.(parameter); %#ok<AGROW>
                end

                names(end+1) = "Mask parameter mode";
                values{end+1} = recipe.Mode;
            end

            % Processing-status row labels and formatted image counts.
            [statusNames,statusValues] = oops.model.internal.processingSummary(obj);

            % Single-column summary with statistic names supplied as table row names.
            T = oops.model.internal.summaryTable([names statusNames],[values statusValues]);
        end

    end

end
