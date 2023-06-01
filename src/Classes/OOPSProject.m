classdef OOPSProject < handle
    % experimental groups class
    properties
        % name of the project
        ProjectName = 'Untitled';
        % array of OOPSGroup objects
        Group OOPSGroup
        % indicates which OOPSGroup is selected in the GUI
        CurrentGroupIndex double
        % handles to all gui objects
        Handles struct
        % handle to the main OOPSSettings object (shared across multiple objects)
        Settings OOPSSettings
    end

    properties (Dependent = true)
        nGroups double % depends on the size of dim 1 of Group
        CurrentGroup OOPSGroup
        CurrentImage OOPSImage
        CurrentObject OOPSObject

        GroupNames

        
        GroupColors (:,3) double

        ProjectSummaryDisplayTable

        % total number of objects across all groups
        nObjects (1,1) uint16

        % nGroups x nLabels array of the number of objects with each label in this project
        labelCounts
    end

    methods

        % constructor method
        function obj = OOPSProject(settings)
            if nargin > 0
                obj.Settings = settings;
            else
                obj.Settings = OOPSSettings;
            end
        end

        function delete(obj)
            obj.deleteGroups()
        end

        function deleteGroups(obj)
            % collect and delete the groups in this project
            Groups = obj.Group;
            delete(Groups);
            % clear the placeholders
            clear Groups
            % reinitialize the obj.Group vector
            obj.Group = OOPSGroup.empty();
        end

        % save method, for saving the project to continue later
        function proj = saveobj(obj)

            proj.ProjectName = obj.ProjectName;
            
            % save the settings
            proj.Settings = obj.Settings.saveobj();

            proj.CurrentGroupIndex = obj.CurrentGroupIndex;
            proj.Handles = [];

            if obj.nGroups==0
                proj.Group = [];
            else
                for i = 1:obj.nGroups
                    disp('calling saveobj(Group)')
                    % save each OOPSGroup
                    proj.Group(i,1) = obj.Group(i,1).saveobj();
                end
            end
        end

%% manipulate objects

        % delete all objects with Label:Label
        function DeleteObjectsByLabel(obj,Label)
            for i = 1:obj.nGroups
                obj.Group(i).DeleteObjectsByLabel(Label);
            end
        end

        % find all objects with the Label:OldLabel and replace it with NewLabel
        function SwapObjectLabels(obj,OldLabel,NewLabel)
            % get all of the objects with the old label
            ObjectsWithOldLabel = obj.getObjectsByLabel(OldLabel);
            % add the new label to each of the objects
            [ObjectsWithOldLabel(:).Label] = deal(NewLabel);
        end

        % select all objects with OOPSLabel:Label
        function SelectObjectsByLabel(obj,Label)
            ObjectsToSelect = obj.getObjectsByLabel(Label);
            [ObjectsToSelect.Selected] = deal(true);
        end

         % apply OOPSLabel:Label to all selected objects in project
        function LabelSelectedObjects(obj,Label)
            for i = 1:obj.nGroups
                obj.Group(i).LabelSelectedObjects(Label);
            end
        end    

        % return the currently selected OOPSObject in GUI
        function CurrentObject = get.CurrentObject(obj)
            % get the current image
            cImage = obj.CurrentImage;
            % if the image is not empty
            if ~isempty(cImage)
                CurrentObject = obj.CurrentImage(1).CurrentObject;
            else
                CurrentObject = OOPSObject.empty();
            end
        end

        % total number of objects across all groups
        function nObjects = get.nObjects(obj)
            nObjects = sum(obj.Group(:).TotalObjects);
        end

        % return all objects with Label:Label
        function Objects = getObjectsByLabel(obj,Label)
            Objects = OOPSObject.empty();
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

%% retrieve object data

        % return Var2Get data for each object, grouped by object label
        function ObjectDataByLabel = GetObjectDataByLabel(obj,Var2Get)
            nLabels = length(obj.Settings.ObjectLabels);

            % cell array to hold all object data for the project, split by group and label
            %   each row is one group, each column is a unique label
            ObjectDataByLabel = cell(obj.nGroups,nLabels);

            for i = 1:obj.nGroups
                % cell array of ObjectDataByLabel for one replicate
                % each cell is a vector of values for one label
                ObjectDataByLabel(i,:) = obj.Group(i).GetObjectDataByLabel(Var2Get);
            end
        end

        % get array of object data with one column for each specified variable in the list, vars
        function objectData = getAllObjectData(obj,vars)
            % vars is a cell array of char vectors, each specifying an object data variable
            % note, we could also retrieve all the objects first then access the data at the object level
            % will test that in the future
            % the number of distinct object variables we are retrieving
            nVariables = numel(vars);
            % cell array to hold the object data for each group
            objectData = cell(obj.nGroups,1);
            % for each group in the project
            for groupIdx = 1:obj.nGroups
                % preallocate array of object data for this group
                objectData{groupIdx} = zeros(obj.Group(groupIdx).TotalObjects,nVariables);
                % for each variable
                for varIdx = 1:numel(vars)
                    % get all object data for this variable in this group
                    objectData{groupIdx}(:,varIdx) = obj.Group(groupIdx).GetAllObjectData(vars{varIdx});
                end
            end
            % finally concatenate the data and return a single array of objects 
            objectData = cell2mat(objectData);
        end

%% manipulate groups

        % add a new group with only group name as input
        function AddNewGroup(obj,GroupName)
            NewColor = obj.getUniqueGroupColor();
            obj.Group(end+1,1) = OOPSGroup(GroupName,obj);
            obj.Group(end).Color = NewColor;
        end

        % find unique group color based on existing group colors
        function NewColor = getUniqueGroupColor(obj)
            % we want to avoid having these colors set as group colors
            BGColors = [1 1 1];
            if obj.nGroups>0
                CurrentColors = zeros(obj.nGroups,3);    
                for i = 1:obj.nGroups
                    CurrentColors(i,:) = obj.Group(i).Color;
                end
                NewColor = distinguishable_colors(1,[CurrentColors;BGColors]);
            else
                NewColor = distinguishable_colors(1,BGColors);
            end
        end

        % delete the OOPSGroup indicated by input:Group
        function DeleteGroup(obj,Group)
            Group2Delete = Group;
            GroupIdx = Group2Delete.SelfIdx;
            if GroupIdx == 1
                if obj.nGroups > 1
                    obj.Group = obj.Group(2:end);
                else
                    obj.Group = OOPSGroup.empty();
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

%% retrieve group data

        % return list of group names
        function GroupNames = get.GroupNames(obj)
            GroupNames = cell(obj.nGroups,1);
            for i = 1:obj.nGroups
                GroupNames{i} = obj.Group(i).GroupName;
            end
        end

        function GroupColors = get.GroupColors(obj)
            % initialize label colors array
            GroupColors = zeros(obj.nGroups,3);
            % add the colors from each label
            for i = 1:obj.nGroups
                GroupColors(i,:) = obj.Group(i).Color;
            end
        end

        % get the number of groups in this project
        function nGroups = get.nGroups(obj)
            if isvalid(obj.Group)
                nGroups = numel(obj.Group);
            else
                nGroups = 0;
            end
        end

        % return currently selected OOPSGroup in GUI
        function CurrentGroup = get.CurrentGroup(obj)
            try
                CurrentGroup = obj.Group(obj.CurrentGroupIndex);
            catch
                CurrentGroup = OOPSGroup.empty();
            end
        end

        function labelCounts = get.labelCounts(obj)
            % preallocate our array of label counts
            labelCounts = zeros(obj.nGroups,obj.Settings.nLabels);
            % get the counts for each group in the project
            for gIdx = 1:obj.nGroups
                % for each group, get the label counts by summing the label counts for each image
                labelCounts(gIdx,:) = sum(obj.Group(gIdx).labelCounts,1);
            end
        end

%% retrieve image data

        % return the currently selected OOPSImage in GUI
        function CurrentImage = get.CurrentImage(obj)
            % get the currently selected group
            cGroup = obj.CurrentGroup;
            % if the group is not empty
            if ~isempty(cGroup) 
                % get its current image
                CurrentImage = cGroup.CurrentImage; 
            else
                % otherwise, return empty
                CurrentImage = OOPSImage.empty(); 
            end
        end

%% retrieve project summary

        function ProjectSummaryDisplayTable = get.ProjectSummaryDisplayTable(obj)

            varNames = [...
                "Project name",...
                "Number of groups",...
                "Current tab",...
                "Previous tab",...
                "Mask type",...
                "Mask name",...
                "GUI font size",...
                "GUI background color",...
                "GUI foreground color",...
                "GUI highlight color"];

            ProjectSummaryDisplayTable = table(...
                {obj.ProjectName},...
                {num2str(obj.nGroups)},...
                {obj.Settings.CurrentTab},...
                {obj.Settings.PreviousTab},...
                {obj.Settings.MaskType},...
                {obj.Settings.MaskName},...
                {num2str(obj.Settings.FontSize)},...
                {num2str(obj.Settings.GUIBackgroundColor)},...
                {num2str(obj.Settings.GUIForegroundColor)},...
                {num2str(obj.Settings.GUIHighlightColor)},...
                'VariableNames',varNames,...
                'RowNames',"Project");

            ProjectSummaryDisplayTable = rows2vars(ProjectSummaryDisplayTable,"VariableNamingRule","preserve");

            ProjectSummaryDisplayTable.Properties.RowNames = varNames;
        end

    end

    methods (Static)
        function obj = loadobj(proj)

            obj = OOPSProject(OOPSSettings.loadobj(proj.Settings));

            obj.ProjectName = proj.ProjectName;
            %obj.Settings = proj.Settings;
            obj.CurrentGroupIndex = proj.CurrentGroupIndex;
            obj.Handles = proj.Handles;
            % for each group in the saved data structure
            for i = 1:length(proj.Group)
                % load the group
                obj.Group(i,1) = OOPSGroup.loadobj(proj.Group(i,1));
                % and set its parent project (this project)
                obj.Group(i,1).Parent = obj;
            end
        end
    end

end