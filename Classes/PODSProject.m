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
        
        %CurrentChannelIndex uint8
        
        % handles to all gui objects
        Handles struct       
        
        Settings

    end
    
    
    properties (Dependent = true)  
        nGroups double % depends on the size of dim 1 of Group
%        nChannels double % depends on the size of dim 2 of Group
        
        CurrentGroup PODSGroup % depends on user selection
        CurrentImage PODSImage
        CurrentObject PODSObject

        GroupNames
    end

     methods
         
         function obj = PODSProject()
             obj.Settings = PODSSettings;
             %obj.CurrentChannelIndex = 1;
         end
         
         function MakeNewGroup(obj,GroupName,GroupIndex)
             obj.Group(GroupIndex,1) = PODSGroup(GroupName,GroupIndex,obj.Settings);
         end

         function GroupNames = get.GroupNames(obj)
             for i = 1:obj.nGroups
                 GroupNames{i} = obj.Group(i).GroupName;
             end
         end

         function nGroups = get.nGroups(obj)
             nGroups = size(obj.Group,1); % each row of Group is separate group of replicates
         end

         function CurrentGroup = get.CurrentGroup(obj)
             CurrentGroup = obj.Group(obj.CurrentGroupIndex);
         end  
         
         function CurrentImage = get.CurrentImage(obj)
             cGroup = obj.CurrentGroup;
             CurrentImage = cGroup.CurrentImage;
         end
         
         function CurrentObject = get.CurrentObject(obj)
             cImage = obj.CurrentImage;
             cObject = cImage.CurrentObject;
         end
         
         function ObjectDataByLabel = GetObjectDataByLabel(obj,Var2Get)
             nGroups = obj.nGroups;
             nLabels = length(obj.Settings.ObjectLabels);

             % cell array to hold all object data for the project, split by group and label
             %   each row is one group, each column is a unique label
             ObjectDataByLabel = cell(nGroups,nLabels);
             
             for i = 1:nGroups
                 % cell array of ObjectDataByLabel for one replicate
                 % each cell is a vector of values for one label
                 %GroupObjectDataByLabel = obj.Group(i).GetObjectDataByLabel(Var2Get);
                 ObjectDataByLabel(i,:) = obj.Group(i).GetObjectDataByLabel(Var2Get);
             end

        end

     end
     
end