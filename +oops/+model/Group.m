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
        ImagesAdded
        ImagesRemoved
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

        function S = toStruct(obj,projectFolder)
        %TOSTRUCT Capture group metadata, assignments, navigation, and images.

            images = arrayfun(@(item) item.toStruct(projectFolder),obj.Images);
            S = struct( ...
                'ID',obj.ID, ...
                'Name',obj.Name, ...
                'Color',obj.Color, ...
                'CalibrationIDs',obj.CalibrationIDs, ...
                'ActiveImageID',obj.ActiveImageID, ...
                'SelectedImageIDs',obj.SelectedImageIDs, ...
                'Images',images);
        end

        function restoreIdentity(obj,S)
        %RESTOREIDENTITY Restore durable IDs and navigation after members exist.

            obj.ID = string(S.ID);
            obj.setCalibrations(string(S.CalibrationIDs));
            obj.setActiveImage(string(S.ActiveImageID));
            obj.setSelectedImages(string(S.SelectedImageIDs));
        end

        function image = addImage(obj,input,name,primaryChannel)
        %ADDIMAGE Attach an independently owned four-angle Image5D source.

            arguments
                obj
                input (1,1) matlabx.image.Image5D
                name (1,1) string = "Image"
                primaryChannel (:,1) oops.model.ChannelDefinition = ...
                    oops.model.ChannelDefinition.empty(0,1)
            end

            image = obj.addImages(input,name,primaryChannel);
        end

        function images = addImages(obj,inputs,names,primaryChannels)
        %ADDIMAGES Validate and attach a complete batch before notifying observers.

            arguments
                obj
                inputs (:,1) matlabx.image.Image5D
                names (:,1) string = strings(0,1)
                primaryChannels (:,1) oops.model.ChannelDefinition = ...
                    oops.model.ChannelDefinition.empty(0,1)
            end

            try
                count = numel(inputs);

                if count == 0
                    images = oops.model.Image.empty(0,1);
                    return;
                end

                if isempty(names)
                    names = repmat("Image",count,1);
                elseif numel(names) ~= count
                    error('oops:model:ImageBatchSizeMismatch', ...
                        'Supply one name for every image input.');
                end

                if ~isempty(primaryChannels) && numel(primaryChannels) ~= count
                    error('oops:model:ImageBatchSizeMismatch', ...
                        'Supply one primary channel for every image input.');
                end

                % Validate layouts and unique source ownership before modifying
                % the group or creating any image model.
                groups = obj;

                if ~isempty(obj.Parent)
                    groups = obj.Parent.Groups;
                end

                for k = 1:count
                    oops.io.fourAngleLocations(inputs(k));

                    for g = 1:numel(groups)
                        for i = 1:numel(groups(g).Images)
                            if groups(g).Images(i).Input.Source == inputs(k).Source
                                error('oops:model:InputAlreadyOwned', ...
                                    'Create a separate Image5D source for each image.');
                            end
                        end
                    end

                    for previous = 1:k-1
                        if inputs(previous).Source == inputs(k).Source
                            error('oops:model:InputAlreadyOwned', ...
                                'Create a separate Image5D source for each image.');
                        end
                    end
                end

                if isempty(primaryChannels)
                    primaryChannels = oops.model.ChannelDefinition.empty(0,1);

                    for k = 1:count
                        primaryChannels(k,1) = obj.defaultPrimaryChannel(inputs(k)); %#ok<AGROW>
                    end
                end

                for k = 1:count
                    if isempty(obj.Parent.Channels.findByID(primaryChannels(k).ID))
                        error('oops:model:UnknownPrimaryChannel', ...
                            'Every primary channel must belong to this project.');
                    end
                end

                images = oops.model.Image.empty(0,1);
                listenersByImage = cell(count,1);

                for k = 1:count
                    image = oops.model.Image(obj,inputs(k),names(k));
                    image.setPrimaryChannel(primaryChannels(k));
                    images(k,1) = image;
                    listeners(1) = addlistener(image,'ObjectsChanged',@(~,e) notify(obj,'ObjectsChanged',e));
                    listeners(2) = addlistener(image,'DataChanged',@(~,e) notify(obj,'DataChanged',e));
                    listeners(3) = addlistener(image,'NavigationChanged',@(~,e) notify(obj,'NavigationChanged',e));
                    listenersByImage{k} = listeners;
                end

                obj.Images = [obj.Images; images];
                obj.ImageListeners = [obj.ImageListeners reshape(listenersByImage,1,[])];
                notify(obj,'ImagesAdded',oops.model.events.ImagesAdded([images.ID],obj.ID));

                for image = reshape(images,1,[])
                    oops.Log.INFO("Added image: " + image.Name);
                end
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function removeImage(obj,image)
        %REMOVEIMAGE Detach one image through the aggregate removal path.

            obj.removeImages(image);
        end

        function removeImages(obj,images)
        %REMOVEIMAGES Validate and detach a complete image batch before notifying.

            arguments
                obj
                images (:,1) oops.model.Image
            end

            try
                if isempty(images)
                    return;
                end

                indices = zeros(numel(images),1);

                for k = 1:numel(images)
                    index = find(obj.Images == images(k),1);

                    if isempty(index)
                        error('oops:model:UnknownImage', ...
                            'Every image must belong to this group.');
                    end

                    indices(k) = index;
                end

                if numel(unique(indices)) ~= numel(indices)
                    error('oops:model:DuplicateImageRemoval', ...
                        'Each image may appear only once in a removal batch.');
                end

                ids = [images.ID]';

                % Release residency and forwarded subscriptions before detaching
                % the complete validated set from the owned collection.
                for k = 1:numel(images)
                    images(k).unloadInput();
                    delete(obj.ImageListeners{indices(k)});
                end

                keep = true(numel(obj.Images),1);
                keep(indices) = false;
                obj.Images = obj.Images(keep);
                obj.ImageListeners = obj.ImageListeners(reshape(keep,1,[]));

                for image = reshape(images,1,[])
                    image.Parent = oops.model.Group.empty(0,1);
                end

                obj.setSelectedImages(obj.SelectedImageIDs( ...
                    ~ismember(obj.SelectedImageIDs,ids)));

                if ismember(obj.ActiveImageID,ids)
                    obj.setActiveImage("");
                end

                notify(obj,'ImagesRemoved', ...
                    oops.model.events.ImagesRemoved(ids,obj.ID));
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

    methods (Access=private)

        function channel = defaultPrimaryChannel(obj,input)
        %DEFAULTPRIMARYCHANNEL Reuse metadata identity for noninteractive imports.

            locations = oops.io.fourAngleLocations(input);
            component = input.getComponent(locations(1,1));
            name = strtrim(string(component.Name));

            if name == ""
                name = "Primary channel";
            end

            channel = obj.Parent.Channels.findByName(name);

            if ~isempty(channel)
                return;
            end

            color = component.Color;

            if isempty(color)
                color = [1 1 1];
            end

            channel = obj.Parent.Channels.add(name,double(color));
        end

    end

end
