classdef PODSProject < handle
    % experimental groups class
    properties
        % group info
        ProjectName = '';      
        
        % replicates within group
        % row idx: group
        % col idx: channel (for multi-channel data)
        Group PODSGroup
        
        % indexing group members
        CurrentGroupIndex uint8
        
        % handles to all gui objects
        Handles struct       
        
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
         
         function obj = PODSProject()
             obj.Settings = PODSSettings;
         end

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
                    proj.Group(i) = obj.Group(i).saveobj();
                end
            end

            %return

         end
         

         function AddNewGroup(obj,GroupName)
            NewColor = obj.getUniqueGroupColor();
            obj.Group(end+1,1) = PODSGroup(GroupName,obj.Settings,obj);
            %obj.Group(end).Color = obj.Settings.DefaultGroupColors{obj.Group(end).SelfIdx};
            obj.Group(end).Color = NewColor;
         end

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

         function GroupNames = get.GroupNames(obj)
             GroupNames = cell(obj.nGroups,1);
             for i = 1:obj.nGroups
                 GroupNames{i} = obj.Group(i).GroupName;
             end
         end

         function nGroups = get.nGroups(obj)
             nGroups = numel(obj.Group);
         end

         function CurrentGroup = get.CurrentGroup(obj)
             CurrentGroup = obj.Group(obj.CurrentGroupIndex);
         end  
         
         function CurrentImage = get.CurrentImage(obj)
             cGroup = obj.CurrentGroup;
             CurrentImage = cGroup.CurrentImage;
         end
         
         function CurrentObject = get.CurrentObject(obj)
%              cImage = obj.CurrentImage;
%              cObject = cImage.CurrentObject;
            CurrentObject = obj.CurrentImage.CurrentObject;
         end
         
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

            obj.ProjectName = proj.ProjectName;
            obj.Settings = proj.Settings;
            obj.CurrentGroupIndex = proj.CurrentGroupIndex;
            obj.Handles = proj.Handles;

            % load each group (calls loadobj() of PODSGroup)
            for i = 1:length(proj.Group)
                obj.Group(i) = PODSGroup.loadobj(proj.Group(i));
                obj.Group(i).Parent = obj;
                obj.Group(i).Settings = obj.Settings;

                for ii = 1:obj.Group(i).nReplicates
                    obj.Group(i).Replicate(ii).Settings = obj.Settings;
                    obj.Group(i).Replicate(ii).Parent = obj.Group(i);
                end
            end
         end
     end
     
end