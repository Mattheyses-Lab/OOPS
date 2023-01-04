classdef PODSProject < handle
    % experimental groups class
    properties
        % name of the project
        ProjectName = '';

        % array of PODSGroup objects
        Group PODSGroup

        % indicates which PODSGroup is selected in the GUI
        CurrentGroupIndex uint8

        % handles to all gui objects
        Handles struct

        % handle to the main PODSSettings object (shared across multiple objects)
        Settings
    end

    properties (Dependent = true)
        nGroups double % depends on the size of dim 1 of Group
        CurrentGroup PODSGroup
        CurrentImage PODSImage
        CurrentObject PODSObject

        GroupNames
    end

    methods

        % constructor method
        function obj = PODSProject()
            obj.Settings = PODSSettings;
        end

        % save method, for saving the project to continue later
        function proj = saveobj(obj)

            proj.ProjectName = obj.ProjectName;
            proj.Settings = obj.Settings;
            proj.CurrentGroupIndex = obj.CurrentGroupIndex;
            proj.Handles = [];

            if obj.nGroups==0
                proj.Group = [];
            else
                for i = 1:obj.nGroups
                    disp('calling saveobj(Group)')
                    %proj.Group(i) = saveobj(obj.Group(i));
                    proj.Group(i,1) = obj.Group(i,1).saveobj();
                end
            end
        end

        % add a new group with only group name as input
        function AddNewGroup(obj,GroupName)
            NewColor = obj.getUniqueGroupColor();
            obj.Group(end+1,1) = PODSGroup(GroupName,obj.Settings,obj);
            obj.Group(end).Color = NewColor;
        end

        % find unique group color based on existing group colors
        function NewColor = getUniqueGroupColor(obj)
            if obj.nGroups>0
                CurrentColors = zeros(obj.nGroups,3);
                for i = 1:obj.nGroups
                    CurrentColors(i,:) = obj.Group(i).Color;
                end
                NewColor = distinguishable_colors(1,CurrentColors);
            else
                NewColor = distinguishable_colors(1);
            end
        end

        % return all objects with Label:Label
        function Objects = getObjectsByLabel(obj,Label)
            ObjsFound = 0;
            Objects = PODSObject.empty();
            if obj.nGroups >= 1
                for i = 1:obj.nGroups
                    TotalObjsCounted = numel(Objects);
                    tempObjects = obj.Group(i).getObjectsByLabel(Label);
                    ObjsFound = numel(tempObjects);
                    Objects(TotalObjsCounted+1:TotalObjsCounted+ObjsFound,1) = tempObjects;
                end
            else
                Objects = [];
            end
        end

        % delete all objects with Label:Label
        function DeleteObjectsByLabel(obj,Label)
            for i = 1:obj.nGroups
                obj.Group(i).DeleteObjectsByLabel(Label);
            end
        end

        % select all objects with PODSLabel:Label
        function SelectObjectsByLabel(obj,Label)
            ObjectsToSelect = obj.getObjectsByLabel(Label);
            [ObjectsToSelect.Selected] = deal(true);
        end

        % find all objects with the Label:OldLabel and replace it with NewLabel
        function SwapObjectLabels(obj,OldLabel,NewLabel)
            % get all of the objects with the old label
            ObjectsWithOldLabel = obj.getObjectsByLabel(OldLabel);
            % add the new label to each of the objects
            [ObjectsWithOldLabel(:).Label] = deal(NewLabel);
        end

        % apply PODSLabel:Label to all selected objects in project
        function LabelSelectedObjects(obj,Label)
            for i = 1:obj.nGroups
                obj.Group(i).LabelSelectedObjects(Label);
            end
        end

        % delete the PODSGroup indicated by input:Group
        function DeleteGroup(obj,Group)
            Group2Delete = Group;
            GroupIdx = Group2Delete.SelfIdx;
            if GroupIdx == 1
                if obj.nGroups > 1
                    obj.Group = obj.Group(2:end);
                else
                    obj.Group = PODSGroup.empty();
                end
            elseif GroupIdx == obj.nGroups
                obj.Group = obj.Group(1:end-1);
            else
                obj.Group = [obj.Group(1:GroupIdx-1);obj.Group(GroupIdx+1:end)];
            end
            delete(Group2Delete);
            if obj.CurrentGroupIndex>obj.nGroups
                obj.CurrentGroupIndex = obj.nGroups;
            end
        end

        % return list of group names
        function GroupNames = get.GroupNames(obj)
            GroupNames = cell(obj.nGroups,1);
            for i = 1:obj.nGroups
                GroupNames{i} = obj.Group(i).GroupName;
            end
        end

        % get the number of groups in this project
        function nGroups = get.nGroups(obj)
            nGroups = numel(obj.Group);
        end

        % return currently selected PODSGroup in GUI
        function CurrentGroup = get.CurrentGroup(obj)
            try
                CurrentGroup = obj.Group(obj.CurrentGroupIndex);
            catch
                CurrentGroup = PODSGroup.empty();
            end
        end

        % return the currently selected PODSImage in GUI
        function CurrentImage = get.CurrentImage(obj)
            cGroup = obj.CurrentGroup;
            CurrentImage = cGroup.CurrentImage;
        end

        % return the currently selected PODSObject in GUI
        function CurrentObject = get.CurrentObject(obj)
            CurrentObject = obj.CurrentImage.CurrentObject;
        end

        % return Var2Get data for each object, grouped by object label
        function ObjectDataByLabel = GetObjectDataByLabel(obj,Var2Get)
            nLabels = length(obj.Settings.ObjectLabels);

            % cell array to hold all object data for the project, split by group and label
            %   each row is one group, each column is a unique label
            ObjectDataByLabel = cell(obj.nGroups,nLabels);

            for i = 1:obj.nGroups
                % cell array of ObjectDataByLabel for one replicate
                % each cell is a vector of values for one label
                %GroupObjectDataByLabel = obj.Group(i).GetObjectDataByLabel(Var2Get);
                ObjectDataByLabel(i,:) = obj.Group(i).GetObjectDataByLabel(Var2Get);
            end
        end
    end

    methods (Static)
        function obj = loadobj(proj)
            obj = PODSProject();

            NewScreenSize = obj.Settings.ScreenSize;
            NewFontSize = obj.Settings.FontSize;

            obj.ProjectName = proj.ProjectName;
            obj.Settings = proj.Settings;
            obj.CurrentGroupIndex = proj.CurrentGroupIndex;
            obj.Handles = proj.Handles;

            obj.Settings.ScreenSize = NewScreenSize;
            obj.Settings.FontSize = NewFontSize;

            % load each group (calls loadobj() of PODSGroup)
            for i = 1:length(proj.Group)
                obj.Group(i,1) = PODSGroup.loadobj(proj.Group(i,1));
                obj.Group(i,1).Parent = obj;
                obj.Group(i,1).Settings = obj.Settings;

                for ii = 1:obj.Group(i,1).nReplicates
                    obj.Group(i,1).Replicate(ii).Settings = obj.Settings;
                    obj.Group(i,1).Replicate(ii).Parent = obj.Group(i,1);
                end
            end
        end
    end

end