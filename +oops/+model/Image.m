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
        SegmentationParameters (:,1) oops.analysis.segment.Parameters = oops.analysis.segment.Parameters.empty(0,1)
        IntensityDisplayRange double = []
        OrderDisplayRange (1,2) double = [0 1]
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
            end

        end

    end

    %% Input access and memory residency
    methods

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

            % A new correction invalidates downstream membership and measurements.
            obj.clearSegmentation();
            obj.setResults(struct('AverageIntensity',average, ...
                'CalibrationIDs',string(calibrationIDs(:))));
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
            obj.Mask = false(0,0);
            obj.Objects = oops.model.Object.empty(0,1);

            % Reset bookmarks before destroying the objects they referred to.
            obj.setActiveObject("");
            obj.setSelectedObjects(strings(0,1));
            delete(old);
            notify(obj,'ObjectsChanged',oops.model.events.ObjectsChanged(obj.ID,strings(0,1),oldIDs));
            notify(obj,'DataChanged',oops.model.events.DataChanged(obj.ID,"Mask"));
        end

        function setMask(obj,mask,pixelLists,parameters)
        %SETMASK Validate and replace mask membership and its owned object collection.

            % Analysis supplies the partition; the model only validates/stores it.
            arguments
                obj
                mask (:,:) logical
                pixelLists (1,:) cell
                parameters (:,1) oops.analysis.segment.Parameters = oops.analysis.segment.Parameters.empty(0,1)
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
        %GETDISPLAYRANGE Return user limits, lazily initializing intensity from raw data.
        % Initial limits are data bounds; automatic display choices never write here.

            domain = string(domain);

            if ~ismember(domain,["Intensity","Order"])
                error('oops:model:UnknownDisplayDomain','Unknown display domain: %s',domain);
            end

            % Initialize a missing manual range once. Auto-scaling belongs to
            % rendering and must never replace this remembered user range.
            if domain == "Intensity" && isempty(obj.IntensityDisplayRange)

                % Running minimum finite intensity across the four raw input frames.
                low = Inf;

                % Running maximum finite intensity across the four raw input frames.
                high = -Inf;

                % Read each input angle and accumulate its finite intensity extrema.
                for k = 1:4

                    % Numeric pixels from the current polarization frame, converted to double.
                    values = double(obj.getFrame(k));
                    values = values(isfinite(values));

                    if ~isempty(values)
                        low = min(low,min(values));
                        high = max(high,max(values));
                    end

                end

                if ~isfinite(low)
                    low = 0;
                    high = 1;
                end

                if high <= low
                    high = low+max(1,eps(low));
                end

                obj.IntensityDisplayRange = [low high];
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
                    names(end+1) = "Mask " + parameter;
                    values{end+1} = recipe.Values.(parameter);
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
