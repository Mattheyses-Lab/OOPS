% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Project < handle
    %PROJECT Owns user-defined groups and project-wide settings; no UI handles.

    properties
        Name (1,1) string = "Untitled"
    end

    properties (SetAccess=private)
        ID (1,1) string = ""
        Version (1,1) string = oops.Info.Version
        SchemaVersion (1,1) string = oops.Info.ProjectSchemaVersion
        Groups (:,1) oops.model.Group = oops.model.Group.empty(0,1)
        Calibrations (:,1) oops.model.Calibration = oops.model.Calibration.empty(0,1)
        Settings oops.config.Settings
        Labels oops.model.LabelRegistry
        ActiveGroupID (1,1) string = ""
        SelectedGroupIDs (:,1) string = strings(0,1)
    end

    properties (SetAccess=private, Transient)
        AnalysisCache oops.runtime.AnalysisCache
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
        LastActiveImageID (1,1) string = ""
        RecentImageIDs (:,1) string = strings(0,1)
    end

    properties (Constant)
        ImageDataCacheSize = 2 % active image plus one previously active image
    end

    %% Model events
    events
        CalibrationChanged
        NavigationChanged
        GroupAdded
        GroupRemoved
        GroupChanged
        ImageAdded
        ImageRemoved
        ActiveImageChanged
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
                obj.AnalysisCache = oops.runtime.AnalysisCache();
                obj.Labels = oops.model.LabelRegistry.default();
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
                delete(obj(i).AnalysisCache);
                delete(obj(i).LabelListeners);
                delete(obj(i).Labels);
            end

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
                for eventName = ["ImageAdded","ImageRemoved","ObjectsChanged","DataChanged", ...
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

                % Image removal events and active-image clearing precede GroupRemoved.

                % Detach each child image before removing the group itself.
                while ~isempty(group.Images)
                    group.removeImage(group.Images(1));
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

                % Group resolved from the validated ID, including its remembered image.
                next = oops.model.internal.resolve(obj.Groups,id);

                if ~isempty(next) && ~isempty(next.ActiveImage)
                    next.ActiveImage.loadInput();
                end

                % Publish the bookmark only after its remembered input loads.

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
        %SETACTIVEIMAGE Activate an owned image, retaining active plus previous inputs.
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
                    next.loadInput(); % failure must leave all navigation unchanged
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
        %SYNCACTIVEIMAGE Maintain the shared input cache and publish global activation.

            % Image resolved from the current group/image bookmarks.
            image = obj.ActiveImage;

            % Active image ID to publish; remains empty when no image is active.
            id = "";

            if ~isempty(image)
                image.loadInput();
                id = image.ID;
                obj.RecentImageIDs(obj.RecentImageIDs == id) = [];
                obj.RecentImageIDs = [id;obj.RecentImageIDs];
                obj.RecentImageIDs = obj.RecentImageIDs(1:min(end,obj.ImageDataCacheSize));
            end

            % Retain only recent inputs; numeric analysis outputs are unaffected.

            % Visit every group to check image residency against the shared cache.
            for g = 1:numel(obj.Groups)

                % Unload each image whose ID is no longer in the recent-input cache.
                for i = 1:numel(obj.Groups(g).Images)

                    % Image being checked against the recently used input-cache IDs.
                    candidate = obj.Groups(g).Images(i);

                    if ~ismember(candidate.ID,obj.RecentImageIDs)
                        candidate.unloadInput();
                    end

                end

            end

            % Notify observers after the residency policy reaches its final state.

            % Last published active image ID, used to detect a global activation change.
            old = obj.LastActiveImageID;
            obj.LastActiveImageID = id;

            if old ~= id
                notify(obj,'ActiveImageChanged',oops.model.events.ActiveImageChanged(id,old));
            end

        end

        function forward(obj,name,e)
        %FORWARD Bubble child events and maintain the global active-image cache.

            if name == "ImageRemoved"
                obj.RecentImageIDs(obj.RecentImageIDs == e.ImageID) = [];
                obj.AnalysisCache.removeImage(e.ImageID);
                obj.syncActiveImage();
            elseif name == "CalibrationChanged"

                % Corrected entries produced under the former group assignment are stale.
                group = oops.model.internal.resolve(obj.Groups,e.GroupID);

                if ~isempty(group)

                    % Release every cached correction owned by the changed group.
                    for image = reshape(group.Images,1,[])
                        obj.AnalysisCache.removeImage(image.ID);
                    end

                end

            elseif name == "NavigationChanged" && e.Domain == "Group" && ...
                    e.Name == "ActiveImageID" && e.OwnerID == obj.ActiveGroupID
                obj.syncActiveImage();
            end

            notify(obj,char(name),e);
        end

    end

end
