% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Group < handle
    %GROUP A freely named collection of related images.

    properties (SetAccess=private)
        Name (1,1) string = "Group"
        Color (1,3) double {mustBeFinite,mustBeInRange(Color,0,1)} = [0 0.4470 0.7410]
    end

    properties (SetAccess=private)
        ID (1,1) string = ""
        CalibrationIDs (:,1) string = strings(0,1)
        ActiveImageID (1,1) string = ""
        SelectedImageIDs (:,1) string = strings(0,1)
        Images (:,1) oops.model.Image = oops.model.Image.empty(0,1)
    end

    properties (SetAccess=?oops.model.Project)
        Parent (:,1) oops.model.Project = oops.model.Project.empty(0,1)
    end

    properties (Dependent, SetAccess=private)
        SummaryTable (:,:) table
        ActiveImage
        Calibrations
    end

    properties (Access=private)
        ImageListeners cell = {}
    end

    %% Model events
    events
        CalibrationChanged
        GroupChanged
        NavigationChanged
        ImageAdded
        ImageRemoved
        ObjectsChanged
        DataChanged
    end

    %% Construction
    methods (Access=?oops.model.Project)

        function obj = Group(parent,name,color)
        %GROUP Construct a group owned by a project.

            arguments
                parent (1,1) oops.model.Project
                name (1,1) string
                color (1,3) double {mustBeFinite,mustBeInRange(color,0,1)}
            end

            obj.ID = matlabx.utils.text.uniqueID();
            obj.Parent = parent;
            obj.Name = name;
            obj.Color = color;
        end

    end

    %% Lifecycle
    methods

        function delete(obj)
        %DELETE Release owned listeners and descendants without processing image data.

            % Release each group's owned images and event subscriptions.
            for i = 1:numel(obj)

                % Delete the subscriptions stored for each owned image.
                for k = 1:numel(obj(i).ImageListeners)
                    delete(obj(i).ImageListeners{k});
                end

                delete(obj(i).Images);
            end

        end

    end

    %% Image membership
    methods

        function image = addImage(obj,input,name)
        %ADDIMAGE Attach an independently owned four-angle Image5D source.

            arguments
                obj
                input (1,1) matlabx.image.Image5D
                name (1,1) string = "Image"
            end

            try
                oops.io.fourAngleLocations(input);

                % A buffer must have one owner so unloading one image cannot
                % silently unload another image sharing the same source.

                % Groups to inspect for an existing owner of the supplied input source.
                groups = obj;

                if ~isempty(obj.Parent)
                    groups = obj.Parent.Groups;
                end

                % Check each project group for an image already owning this input source.
                for g = 1:numel(groups)

                    % Compare the supplied source against every image in this group.
                    for i = 1:numel(groups(g).Images)

                        if groups(g).Images(i).Input.Source == input.Source
                            error( ...
                            'oops:model:InputAlreadyOwned', ...
                            'Create a separate Image5D source for each image.');
                        end

                    end

                end

                % Attach the model and its subscriptions before announcing it.

                % New image model attached to this group after input validation.
                image = oops.model.Image(obj,input,name);
                obj.Images(end+1,1) = image;

                % Subscriptions forwarding object, data, and navigation changes from this image.
                listeners(1) = addlistener(image,'ObjectsChanged',@(~,e) notify(obj,'ObjectsChanged',e));
                listeners(2) = addlistener(image,'DataChanged',@(~,e) notify(obj,'DataChanged',e));
                listeners(3) = addlistener(image,'NavigationChanged',@(~,e) notify(obj,'NavigationChanged',e));
                obj.ImageListeners{end+1} = listeners;
                notify(obj,'ImageAdded',oops.model.events.ImageAdded(image.ID,obj.ID));
                oops.Log.INFO("Added image: " + image.Name);
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function removeImage(obj,image)
        %REMOVEIMAGE Unload and detach an image, removing forwarded listeners.

            try

                % Index of this member in its owning collection; empty if not found.
                idx = find(obj.Images == image,1);

                if isempty(idx)
                    error('oops:model:UnknownImage','Image does not belong to this group.');
                end

                % Release residency before detaching the parent relationship.
                image.unloadInput();
                delete(obj.ImageListeners{idx});
                obj.ImageListeners(idx) = [];
                obj.Images(idx) = [];
                image.Parent = oops.model.Group.empty(0,1);
                obj.setSelectedImages(obj.SelectedImageIDs(obj.SelectedImageIDs ~= image.ID));

                if obj.ActiveImageID == image.ID
                    obj.setActiveImage("");
                end

                notify(obj,'ImageRemoved',oops.model.events.ImageRemoved(image.ID,obj.ID));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Calibration assignments
    methods

        function calibrations = get.Calibrations(obj)
        %GET.CALIBRATIONS Resolve assigned IDs through the project registry.

            calibrations = oops.model.Calibration.empty(0,1);

            if isempty(obj.Parent) || isempty(obj.CalibrationIDs)
                return;
            end

            % Registry members whose IDs occur in this group's canonical assignment.
            ids = oops.model.internal.ids(obj.Parent.Calibrations);
            calibrations = obj.Parent.Calibrations(ismember(ids,obj.CalibrationIDs));
        end

        function setCalibrations(obj,calibrations)
        %SETCALIBRATIONS Store project registry IDs; observers orchestrate correction.
        % The model validates relationships but never calls analysis or UI code.

            try

                if isempty(obj.Parent)
                    error('oops:model:DetachedGroup','A detached group cannot assign calibrations.');
                end

                % Validated calibration IDs from the parent project's shared registry.
                ids = oops.model.internal.validateIDs(calibrations,obj.Parent.Calibrations, ...
                    'oops:model:UnknownCalibration',false);

                % Previous calibration assignment, retained for the change event.
                old = obj.CalibrationIDs;

                if isequal(old,ids)
                    return;
                end

                % Observers decide when to compute a correction from these IDs.
                obj.CalibrationIDs = ids;
                notify(obj,'CalibrationChanged',oops.model.events.CalibrationChanged(obj.ID,old,ids));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Identity and appearance
    methods

        function setProperties(obj,name,color)
        %SETPROPERTIES Update the user-facing group name and identifying color.

            arguments
                obj
                name (1,1) string
                color (1,3) double {mustBeFinite,mustBeInRange(color,0,1)}
            end

            name = strtrim(name);

            if strlength(name) == 0
                error('oops:model:EmptyGroupName','Group name cannot be empty.');
            end

            if obj.Name == name && isequal(obj.Color,color)
                return;
            end

            obj.Name = name;
            obj.Color = color;
            notify(obj,'GroupChanged');
        end

    end

    %% Active and selected navigation
    methods

        function image = get.ActiveImage(obj)
        %GET.ACTIVEIMAGE Resolve the group bookmark against its owned images.

            image = oops.model.internal.resolve(obj.Images,obj.ActiveImageID);
        end

        function setActiveImage(obj,image)
        %SETACTIVEIMAGE Remember an image without modifying the batch selection.

            try

                % Validated ID of the member to activate, or an empty active bookmark.
                id = oops.model.internal.validateIDs(image,obj.Images,'oops:model:UnknownImage',true);

                % Previously active image ID, retained to detect a bookmark change.
                old = obj.ActiveImageID;

                if old == id
                    return;
                end

                % Image resolved from the validated ID, whose input may need loading.
                next = oops.model.internal.resolve(obj.Images,id);

                if ~isempty(next) && ~isempty(obj.Parent) && obj.Parent.ActiveGroupID == obj.ID
                    next.loadInput(); % validate residency before publishing the bookmark
                end

                obj.ActiveImageID = id;
                notify(obj,'NavigationChanged',oops.model.events.NavigationChanged( ...
                    "Group",obj.ID,"ActiveImageID",old,id));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function setSelectedImages(obj,images)
        %SETSELECTEDIMAGES Store an independent batch set in canonical image order.

            try

                % Validated member IDs in canonical collection order.
                ids = oops.model.internal.validateIDs(images,obj.Images,'oops:model:UnknownImage',false);

                % Previously selected image IDs, retained to detect unchanged selection.
                old = obj.SelectedImageIDs;

                if isequal(old,ids)
                    return;
                end

                obj.SelectedImageIDs = ids;
                notify(obj,'NavigationChanged',oops.model.events.NavigationChanged( ...
                    "Group",obj.ID,"SelectedImageIDs",old,ids));
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Derived summaries
    methods

        function T = get.SummaryTable(obj)
        %GET.SUMMARYTABLE Summarize this freely defined collection of images.

            % Number of objects currently owned by all images in this group.
            totalObjects = sum(arrayfun(@(image) numel(image.Objects),obj.Images));

            % Row labels for group membership and calibration information.
            names = ["Name","Total images","Total objects","FFC files assigned"];

            % Group name and counts corresponding to those summary labels.
            values = {obj.Name,numel(obj.Images),totalObjects,numel(obj.CalibrationIDs)};

            % Processing-status row labels and formatted image counts.
            [statusNames,statusValues] = oops.model.internal.processingSummary(obj.Images);

            % Single-column summary with statistic names supplied as table row names.
            T = oops.model.internal.summaryTable([names statusNames],[values statusValues]);
        end

    end

end
