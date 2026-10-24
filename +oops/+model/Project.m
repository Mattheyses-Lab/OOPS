% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Project < handle
    %PROJECT Owns user-defined groups and project-wide settings; no UI handles.

    properties
        Name (1,1) string = "Untitled"
        SourcePath (1,1) string = ""
    end

    properties (SetAccess=private)
        ID (1,1) string = ""
        Version (1,1) string = oops.Info.Version
        SchemaVersion (1,1) string = oops.Info.ProjectSchemaVersion
        Groups (:,1) oops.model.Group = oops.model.Group.empty(0,1)
        Calibrations (:,1) oops.model.Calibration = oops.model.Calibration.empty(0,1)
        Channels (1,1) oops.model.ChannelRegistry
        Settings oops.config.Settings
        Labels oops.model.LabelRegistry
        ActiveGroupID (1,1) string = ""
        SelectedGroupIDs (:,1) string = strings(0,1)
    end

    properties (SetAccess=private, Transient)
        CacheManager oops.runtime.CacheManager
    end

    properties (Dependent, SetAccess=private)
        SummaryTable (:,:) table
        ActiveGroup
        ActiveImage
        ActiveObject
        NextGroupColor
    end

    properties (Access=private)
        GroupListeners cell = {}
        LabelListeners event.listener = event.listener.empty()
    end

    %% Model events
    events
        CalibrationChanged
        NavigationChanged
        GroupAdded
        GroupRemoved
        GroupChanged
        ImagesAdded
        ImagesRemoved
        ObjectsChanged
        DataChanged
        LabelsChanged
        ActiveLabelChanged
    end

    %% Lifecycle
    methods

        function obj = Project(name,settings)
        %PROJECT Construct project metadata and project-wide settings.

            try
                obj.ID = matlabx.utils.text.uniqueID();

                if nargin >= 1
                    obj.Name = name;
                end

                if nargin < 2
                    settings = oops.config.Settings();
                end

                validateattributes(settings,{'oops.config.Settings'},{'scalar'});
                obj.Settings = settings;
                obj.CacheManager = oops.runtime.CacheManager();
                obj.Labels = oops.model.LabelRegistry.default();
                obj.Channels = oops.model.ChannelRegistry();
                obj.LabelListeners(1) = addlistener(obj.Labels,'LabelsChanged', ...
                    @(~,~) notify(obj,'LabelsChanged'));
                obj.LabelListeners(2) = addlistener(obj.Labels,'ActiveChanged', ...
                    @(~,~) notify(obj,'ActiveLabelChanged'));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function delete(obj)
        %DELETE Release owned listeners and descendants without processing image data.

            % Release each project's owned groups, calibrations, and event subscriptions.
            for i = 1:numel(obj)

                % Delete the subscriptions stored for each owned group.
                for k = 1:numel(obj(i).GroupListeners)
                    delete(obj(i).GroupListeners{k});
                end

                delete(obj(i).Groups);
                delete(obj(i).Calibrations);
                delete(obj(i).Channels);
                delete(obj(i).CacheManager);
                delete(obj(i).LabelListeners);
                delete(obj(i).Labels);
            end

        end

        function S = toStruct(obj,projectFolder)
        %TOSTRUCT Capture compact project state without raster data or runtime caches.

            arguments
                obj
                projectFolder (1,1) string = ""
            end

            groups = arrayfun(@(item) item.toStruct(projectFolder),obj.Groups);
            calibrations = arrayfun( ...
                @(item) item.toStruct(projectFolder),obj.Calibrations);
            S = struct( ...
                'Format',"OOPS Project", ...
                'Version',obj.Version, ...
                'SchemaVersion',obj.SchemaVersion, ...
                'ID',obj.ID, ...
                'Name',obj.Name, ...
                'Settings',obj.Settings.toStruct(), ...
                'Labels',obj.Labels.toStruct(), ...
                'Channels',obj.Channels.toStruct(), ...
                'Calibrations',calibrations, ...
                'Groups',groups, ...
                'ActiveGroupID',obj.ActiveGroupID, ...
                'SelectedGroupIDs',obj.SelectedGroupIDs);
        end

    end

    methods (Static)

        function [obj,resolution] = fromStruct(S,projectFolder,searchRoot,opts)
        %FROMSTRUCT Restore compact state and resolve each external image source.

            arguments
                S (1,1) struct
                projectFolder (1,1) string = ""
                searchRoot (1,1) string = ""
                opts.Progress = []
            end

            if ~isfield(S,'Format') || string(S.Format) ~= "OOPS Project"
                error('oops:project:InvalidFile','The selected file is not an OOPS project.');
            end

            if ~isfield(S,'SchemaVersion') || ...
                    string(S.SchemaVersion) ~= oops.Info.ProjectSchemaVersion
                found = "missing";
                if isfield(S,'SchemaVersion')
                    found = string(S.SchemaVersion);
                end
                error('oops:project:IncompatibleSchema', ...
                    'Project schema %s is incompatible with required schema %s.', ...
                    found,oops.Info.ProjectSchemaVersion);
            end

            % Resolve every external source before allocating a partial model.
            resolution = oops.io.project.resolveSources( ...
                S,projectFolder,searchRoot,Progress=opts.Progress);
            oops.Log.DEBUG("All project sources resolved; constructing project model.");

            oops.runtime.updateProgress(opts.Progress,"Restoring project settings...",.45);
            settings = oops.config.Settings();
            settings.fromStruct(S.Settings);
            obj = oops.model.Project(string(S.Name),settings);
            obj.ID = string(S.ID);

            delete(obj.Channels);

            obj.Channels = oops.model.ChannelRegistry.fromStruct(S.Channels);

            delete(obj.LabelListeners);
            delete(obj.Labels);
            obj.Labels = oops.model.LabelRegistry.fromStruct(S.Labels);
            obj.LabelListeners(1) = addlistener(obj.Labels,'LabelsChanged', ...
                @(~,~) notify(obj,'LabelsChanged'));
            obj.LabelListeners(2) = addlistener(obj.Labels,'ActiveChanged', ...
                @(~,~) notify(obj,'ActiveLabelChanged'));

            % Total file-backed members used to report reconstruction progress.
            imageCount = sum(arrayfun(@(group) numel(group.Images),S.Groups));
            auxiliaryCount = 0;

            for g = 1:numel(S.Groups)

                for i = 1:numel(S.Groups(g).Images)

                    auxiliaryCount = auxiliaryCount + ...
                        numel(S.Groups(g).Images(i).AuxiliaryChannels);

                end
            end

            sourceCount = numel(S.Calibrations)+imageCount+auxiliaryCount;
            sourceIndex = 0;

            % Images whose saved state included per-pixel FPM results. The large
            % result arrays are regenerated after every model member is restored.
            fpmImages = oops.model.Image.empty(0,1);

            % All restored images receive a durable average-intensity result.
            restoredImages = oops.model.Image.empty(0,1);

            for k = 1:numel(S.Calibrations)
                data = S.Calibrations(k);
                path = resolution.Calibrations(k);

                sourceIndex = sourceIndex+1;
                reportSourceProgress(opts.Progress,"Loading calibration", ...
                    data.Name,sourceIndex,sourceCount);

                input = oops.io.readInput(path,SeriesIndex=data.Source.SeriesIndex);
                calibration = obj.addCalibration(input,string(data.Name));
                calibration.restoreID(data.ID);
            end

            for g = 1:numel(S.Groups)
                data = S.Groups(g);
                group = obj.addGroup(string(data.Name),double(data.Color));

                for i = 1:numel(data.Images)
                    imageData = data.Images(i);
                    path = resolution.Images{g}(i);

                    sourceIndex = sourceIndex+1;
                    reportSourceProgress(opts.Progress,"Loading image", ...
                        imageData.Name,sourceIndex,sourceCount);

                    input = oops.io.readInput(path, ...
                        SeriesIndex=imageData.Source.SeriesIndex);
                    primaryChannel = obj.Channels.findByID( ...
                        string(imageData.PrimaryChannelID));
                    image = group.addImage( ...
                        input,string(imageData.Name),primaryChannel);
                    image.restoreStruct(imageData);
                    restoredImages(end+1,1) = image; %#ok<AGROW>

                    if image.PolarizationProvenance.Calculated
                        fpmImages(end+1,1) = image; %#ok<AGROW>
                    end

                    for a = 1:numel(imageData.AuxiliaryChannels)
                        assignmentData = imageData.AuxiliaryChannels(a);
                        auxiliaryPath = resolution.AuxiliaryChannels{g}{i}(a);

                        sourceIndex = sourceIndex+1;
                        reportSourceProgress(opts.Progress,"Loading auxiliary channel", ...
                            assignmentData.ChannelID,sourceIndex,sourceCount);

                        auxiliaryInput = matlabx.image.Image5D.fromFile( ...
                            auxiliaryPath, ...
                            SeriesIndex=assignmentData.Source.SeriesIndex);
                        image.addAuxiliaryChannel( ...
                            string(assignmentData.ChannelID), ...
                            auxiliaryInput, ...
                            double(assignmentData.ComponentIndex), ...
                            double(assignmentData.DisplayRange));
                    end
                end

                group.restoreIdentity(data);
            end

            % FPM reconstruction also writes the average. Initialize the
            % remaining images without retaining their corrected stacks.
            fpmIDs = oops.model.internal.ids(fpmImages);
            averageImages = restoredImages(~ismember( ...
                oops.model.internal.ids(restoredImages),fpmIDs));

            for k = 1:numel(averageImages)
                oops.runtime.updateProgress(opts.Progress,sprintf( ...
                    'Restoring average intensity %d of %d: %s', ...
                    k,numel(averageImages),averageImages(k).Name), ...
                    .9+.05*(k-1)/max(1,numel(averageImages)));
                oops.analysis.Analyzer.ensureAverageIntensity(averageImages(k));
            end

            if ~isempty(fpmImages)
                oops.Log.INFO(sprintf( ...
                    'Recomputing FPM results for %d saved project images.', ...
                    numel(fpmImages)));
                analysisProgress = @(message,value) reportAnalysisProgress( ...
                    opts.Progress,message,value);
                oops.analysis.Analyzer.analyzeImages( ...
                    fpmImages,obj.Settings,Progress=analysisProgress);
            end

            oops.runtime.updateProgress(opts.Progress,"Restoring project navigation...",.99);
            obj.setActiveGroup(string(S.ActiveGroupID));
            obj.setSelectedGroups(string(S.SelectedGroupIDs));
            oops.Log.DEBUG("Project model construction completed: " + obj.Name);
        end

    end

    %% Group membership
    methods

        function color = get.NextGroupColor(obj)
        %GET.NEXTGROUPCOLOR Preview the default color for the next appended group.

            color = obj.nextGroupColor();
        end

        function group = addGroup(obj,name,color)
        %ADDGROUP Create and attach a freely named group, forwarding child events.

            arguments
                obj
                name (1,1) string
                color (1,3) double {mustBeFinite,mustBeInRange(color,0,1)} = obj.nextGroupColor()
            end

            try

                % New group model attached to this project.
                group = oops.model.Group(obj,name,color);
                obj.Groups(end+1,1) = group;
                % Subscriptions that forward each child change through the project,
                % letting consumers observe all groups through one set of listeners.
                listeners = event.listener.empty();

                % Subscribe to each group event that the project forwards to consumers.
                for eventName = ["ImagesAdded","ImagesRemoved","ObjectsChanged","DataChanged", ...
                        "NavigationChanged","CalibrationChanged","GroupChanged"]
                    listeners(end+1) = addlistener(group,char(eventName), ...
                        @(~,e) obj.forward(eventName,e)); %#ok<AGROW>
                end

                obj.GroupListeners{end+1} = listeners;
                notify(obj,'GroupAdded',oops.model.events.GroupAdded(group.ID));
                oops.Log.INFO("Added group: " + group.Name);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function removeGroup(obj,group)
        %REMOVEGROUP Detach a group and its images, clearing any active selection.

            try

                % Index of this member in its owning collection; empty if not found.
                idx = find(obj.Groups == group,1);

                if isempty(idx)
                    error('oops:model:UnknownGroup','Group does not belong to this project.');
                end

                % Image removal and active-image clearing precede GroupRemoved.
                if ~isempty(group.Images)
                    group.removeImages(group.Images);
                end

                % Keep listener slots aligned with the surviving group array.
                delete(obj.GroupListeners{idx});
                obj.GroupListeners(idx) = [];
                obj.Groups(idx) = [];
                group.Parent = oops.model.Project.empty(0,1);
                obj.setSelectedGroups(obj.SelectedGroupIDs(obj.SelectedGroupIDs ~= group.ID));

                if obj.ActiveGroupID == group.ID
                    obj.setActiveGroup("");
                end

                notify(obj,'GroupRemoved',oops.model.events.GroupRemoved(group.ID));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Object label registry
    methods

        function id = addLabel(obj,name,opts)
        %ADDLABEL Register a project label through the model-owned label bank.

            arguments
                obj
                name (1,1) string
                opts.ID (1,1) string = ""
                opts.Hotkey (1,1) string = ""
                opts.Color (1,3) double = [1 1 1]
            end

            id = obj.Labels.add(name,ID=opts.ID,Hotkey=opts.Hotkey,Color=opts.Color);
        end

        function newID = editLabel(obj,id,opts)
        %EDITLABEL Edit registry metadata and migrate objects when the ID changes.

            arguments
                obj
                id (1,1) string
                opts.Name (1,1) string
                opts.ID (1,1) string
                opts.Hotkey (1,1) string
                opts.Color (1,3) double
            end

            oldID = string(id);

            % Image/object memberships are collected before the registry is re-keyed.
            affectedImages = oops.model.Image.empty(0,1);
            affectedIDs = cell(0,1);

            for group = reshape(obj.Groups,1,[])

                for image = reshape(group.Images,1,[])
                    if isempty(image.Objects)
                        continue;
                    end

                    matches = image.Objects([image.Objects.LabelID] == oldID);

                    if ~isempty(matches)
                        affectedImages(end+1,1) = image; %#ok<AGROW>
                        affectedIDs{end+1,1} = oops.model.internal.ids(matches); %#ok<AGROW>
                    end

                end

            end

            newID = obj.Labels.edit(oldID,Name=opts.Name,ID=opts.ID, ...
                Hotkey=opts.Hotkey,Color=opts.Color);

            % Object references follow the updated registry identity image by image.
            if newID ~= oldID

                for k = 1:numel(affectedImages)
                    affectedImages(k).setObjectLabels(affectedIDs{k},newID);
                end

            end
        end

        function removeLabel(obj,id)
        %REMOVELABEL Reassign labeled objects before unregistering a user label.

            id = string(id);

            if id == "unlabeled"
                error('oops:model:ReservedLabelID', ...
                    'The default unlabeled label cannot be deleted.');
            end

            % Reassignment precedes removal so Image can validate the fallback ID.
            for group = reshape(obj.Groups,1,[])

                for image = reshape(group.Images,1,[])
                    if isempty(image.Objects)
                        continue;
                    end

                    matches = image.Objects([image.Objects.LabelID] == id);

                    if ~isempty(matches)
                        image.setObjectLabels(oops.model.internal.ids(matches),"unlabeled");
                    end

                end

            end

            obj.Labels.remove(id);
        end

        function newID = mergeLabels(obj,ids,name,opts)
        %MERGELABELS Reassign several user labels into one new registry entry.

            arguments
                obj
                ids (:,1) string
                name (1,1) string
                opts.ID (1,1) string = ""
                opts.Hotkey (1,1) string = ""
                opts.Color (1,3) double = [1 1 1]
            end

            ids = unique(ids(:),'stable');

            if numel(ids) < 2
                error('oops:model:InsufficientLabels', ...
                    'Merging requires at least two labels.');
            end

            if any(ids == "unlabeled")
                error('oops:model:ReservedLabelID', ...
                    'The default unlabeled label cannot be merged.');
            end

            for k = 1:numel(ids)
                if isempty(obj.Labels.getByID(ids(k)))
                    error('oops:model:UnknownLabel','Unknown object label ID: %s',ids(k));
                end
            end

            newID = obj.addLabel(name,ID=opts.ID,Hotkey=opts.Hotkey,Color=opts.Color);

            % Migrate each image once, then remove the unused registry entries.
            for group = reshape(obj.Groups,1,[])
                for image = reshape(group.Images,1,[])
                    matches = image.Objects(ismember([image.Objects.LabelID],ids));
                    image.setObjectLabels(matches,newID);
                end
            end

            for k = 1:numel(ids)
                obj.Labels.remove(ids(k));
            end
        end

    end

    %% Shared calibration registry
    methods

        function calibration = addCalibration(obj,input,name)
        %ADDCALIBRATION Register one shared source, reusing an existing source identity.

            if nargin < 3
                name = "Calibration";
            end

            try

                % Compare the supplied source against each already registered calibration.
                for k = 1:numel(obj.Calibrations)

                    % Input source of the calibration currently being checked for reuse.
                    existing = obj.Calibrations(k).Input;

                    % Whether the supplied input wraps the same source instance.
                    sameSource = existing.Source == input.Source;

                    % Whether both inputs refer to the same file and image series.
                    sameFile = existing.IsFileBacked && input.IsFileBacked && ...
                        matlabx.files.isSamePath(existing.Source.FilePath,input.Source.FilePath) && ...
                        existing.Source.SeriesIndex == input.Source.SeriesIndex;

                    if sameSource || sameFile

                        % New shared calibration model registered after checking existing sources.
                        calibration = obj.Calibrations(k);
                        return;
                    end

                end

                % Multiple groups may reference the same registered source.
                calibration = oops.model.Calibration(input,name);
                obj.Calibrations(end+1,1) = calibration;
                oops.Log.INFO("Registered calibration: " + calibration.Name);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Active and selected navigation
    methods

        function group = get.ActiveGroup(obj)
        %GET.ACTIVEGROUP Resolve the project bookmark without storing handles.

            group = oops.model.internal.resolve(obj.Groups,obj.ActiveGroupID);
        end

        function image = get.ActiveImage(obj)
        %GET.ACTIVEIMAGE Resolve the remembered image of the active group.

            % Empty result until the active group supplies its remembered image.
            image = oops.model.Image.empty(0,1);

            % Group resolved from the project's active-group bookmark.
            group = obj.ActiveGroup;

            if ~isempty(group)
                image = group.ActiveImage;
            end

        end

        function region = get.ActiveObject(obj)
        %GET.ACTIVEOBJECT Resolve the remembered object of the active image.

            % Empty result until the active image supplies its remembered object.
            region = oops.model.Object.empty(0,1);

            % Image resolved through the active group's bookmark.
            image = obj.ActiveImage;

            if ~isempty(image)
                region = image.ActiveObject;
            end

        end

        function setActiveGroup(obj,group)
        %SETACTIVEGROUP Activate a group and restore its remembered image/object.

            try

                % Validated ID of the member to activate, or an empty active bookmark.
                id = oops.model.internal.validateIDs(group,obj.Groups,'oops:model:UnknownGroup',true);

                % Previous active group ID, retained for the navigation event.
                old = obj.ActiveGroupID;
                obj.ActiveGroupID = id;
                obj.syncActiveImage();

                if old ~= id
                    notify(obj,'NavigationChanged',oops.model.events.NavigationChanged( ...
                        "Project",obj.ID,"ActiveGroupID",old,id));
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function setActiveImage(obj,image)
        %SETACTIVEIMAGE Activate an owned image and apply project cache policy.
        % This convenience also switches groups; bookmarks in other groups survive.

            try

                % Flat collection of all project images used to validate ownership.
                images = oops.model.Image.empty(0,1);

                % Gather each group's images into the ownership-validation collection.
                for k = 1:numel(obj.Groups)
                    images = [images;obj.Groups(k).Images]; %#ok<AGROW>
                end

                % Validated ID of the member to activate, or an empty active bookmark.
                id = oops.model.internal.validateIDs(image,images,'oops:model:UnknownImage',true);

                % Image resolved from the validated ID.
                next = oops.model.internal.resolve(images,id);

                if isempty(next)

                    % Currently active group whose image bookmark will be cleared.
                    group = obj.ActiveGroup;

                    if ~isempty(group)
                        group.setActiveImage("");
                    end

                else
                    next.Parent.setActiveImage(next.ID);
                    obj.setActiveGroup(next.Parent.ID);
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function setSelectedGroups(obj,groups)
        %SETSELECTEDGROUPS Update the batch set independently of the active group.

            try

                % Validated member IDs in canonical collection order.
                ids = oops.model.internal.validateIDs(groups,obj.Groups,'oops:model:UnknownGroup',false);

                % Previously selected group IDs, retained to detect unchanged selection.
                old = obj.SelectedGroupIDs;

                if isequal(old,ids)
                    return;
                end

                obj.SelectedGroupIDs = ids;
                notify(obj,'NavigationChanged',oops.model.events.NavigationChanged( ...
                    "Project",obj.ID,"SelectedGroupIDs",old,ids));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Derived summaries
    methods

        function T = get.SummaryTable(obj)
        %GET.SUMMARYTABLE Summarize project membership and current pipeline outputs.

            % Flat collection of project images used to compute counts and status.
            images = oops.model.Image.empty(0,1);

            % Gather all group images for the project-wide counts and status rows.
            for group = reshape(obj.Groups,1,[])
                images = [images; group.Images]; %#ok<AGROW>
            end

            % Number of objects currently owned by all project images.
            totalObjects = sum(arrayfun(@(image) numel(image.Objects),images));

            % Row labels for project membership and registered calibrations.
            names = ["Name","Total groups","Total images","Total objects","FFC files loaded"];

            % Project name and counts corresponding to those summary labels.
            values = {obj.Name,numel(obj.Groups),numel(images),totalObjects,numel(obj.Calibrations)};

            % Processing-status row labels and formatted image counts.
            [statusNames,statusValues] = oops.model.internal.processingSummary(images);

            % Single-column summary with statistic names supplied as table row names.
            T = oops.model.internal.summaryTable([names statusNames],[values statusValues]);
        end

    end

    %% Input cache and child event forwarding
    methods (Access=private)

        function color = nextGroupColor(obj)
        %NEXTGROUPCOLOR Cycle through MATLAB's default axes color order.

            % MATLAB session default used consistently by plots and group creation.
            order = get(groot,'defaultAxesColorOrder');

            % One-based cyclic palette position for the group being appended.
            index = mod(numel(obj.Groups),size(order,1))+1;
            color = order(index,:);
        end

        function syncActiveImage(obj)
        %SYNCACTIVEIMAGE Apply input residency policy and publish global activation.

            % Image resolved from the current group/image bookmarks.
            image = obj.ActiveImage;

            % The cache manager decides whether navigation should retain a full
            % raw buffer. With the default zero-byte budget, Image5D remains lazy.
            obj.CacheManager.activateInput(image,obj.allImages());

        end

        function forward(obj,name,e)
        %FORWARD Bubble child events and maintain the global active-image cache.

            if name == "ImagesRemoved"
                for imageID = reshape(e.ImageIDs,1,[])
                    obj.CacheManager.removeImage(imageID);
                end
                obj.syncActiveImage();
            elseif name == "CalibrationChanged"

                % Corrected entries produced under the former group assignment are stale.
                group = oops.model.internal.resolve(obj.Groups,e.GroupID);

                if ~isempty(group)

                    % Release every cached correction owned by the changed group.
                    for image = reshape(group.Images,1,[])
                        obj.CacheManager.removeImage(image.ID);
                    end

                end

            elseif name == "NavigationChanged" && e.Domain == "Group" && ...
                    e.Name == "ActiveImageID" && e.OwnerID == obj.ActiveGroupID
                obj.syncActiveImage();
            end

            notify(obj,char(name),e);
        end

        function images = allImages(obj)
        %ALLIMAGES Flatten project image membership for runtime cache policy.

            images = oops.model.Image.empty(0,1);

            for group = reshape(obj.Groups,1,[])
                images = [images;group.Images]; %#ok<AGROW>
            end
        end

    end

end

function reportSourceProgress(progress,operation,name,index,count)
%REPORTSOURCEPROGRESS Describe model reconstruction for one file-backed member.

if count == 0
    value = .9;
else
    value = .5+.4*(index/count);
end

message = operation + " " + string(index) + " of " + string(count) + ...
    ": " + string(name);
oops.runtime.updateProgress(progress,message,value);
end

function reportAnalysisProgress(progress,message,value)
%REPORTANALYSISPROGRESS Map analyzer progress into the project-load interval.

if isempty(value)
    mapped = [];
else
    mapped = .95 + .04*value;
end

oops.runtime.updateProgress(progress,message,mapped);
end
