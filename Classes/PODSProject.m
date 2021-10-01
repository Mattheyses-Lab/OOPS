classdef PODSProject < handle
    % experimental groups class
    properties
        % group info
        ProjectName = '';      
        
        % replicates within group
        Group PODSGroup
        
        % indexing group members
        CurrentGroupIndex uint8
        
        CurrentChannelIndex uint8
        
        % handles to all gui objects
        Handles struct       
        
        Settings

    end
    
    
    properties (Dependent = true)  
        nGroups double % depends on the size of dim 1 of Group
        nChannels double % depends on te size of dim 2 of Groups
        
        CurrentGroup PODSGroup % depends on user selection
        CurrentImage PODSImage
        CurrentObject PODSObject

        GroupNames
    end

     methods
         
         function obj = PODSProject()
             obj.Settings = PODSSettings;
             obj.CurrentChannelIndex = 1;
         end
         
         function GroupNames = get.GroupNames(obj)
             for i = 1:size(obj.Group,1)
                 GroupNames{i} = obj.Group(i,1).GroupName;
             end
         end

         function nGroups = get.nGroups(obj)
             nGroups = size(obj.Group,1); % each row of Group is separate group of replicates
         end
         
         function nChannels = get.nChannels(obj)
             nChannels = size(obj.Group,2); % each column of Group is separate emission channel
         end

         % can use PODSProject.CurrentGroup.CurrentImage to get current image of current group in project
         function CurrentGroup = get.CurrentGroup(obj)
             CurrentGroup = obj.Group(obj.CurrentGroupIndex,obj.CurrentChannelIndex);
         end  
         
         function CurrentImage = get.CurrentImage(obj)
             cGroup = obj.CurrentGroup;
             CurrentImage = cGroup.CurrentImage;
         end
         
         function CurrentObject = get.CurrentObject(obj)
             cImage = obj.CurrentImage;
             cObject = cImage.CurrentObject;
             
         end

     end
     
end