classdef PODSProject < handle
    % experimental groups class
    properties
        % group info
        ProjectName = '';      
        
        % replicates within group
        Group PODSGroup
        
        % number of groups in project
        %nGroups uint16
        
        % indexing group members
        CurrentGroupIndex double
        
        % handles to all gui objects
        Handles struct       
        
        Settings = PODSSettings;
        
        GroupNames
    end
    
    
    properties (Dependent = true)  
        nGroups double
        CurrentGroup PODSGroup
        CurrentImage PODSImage
    end

     methods
         function nGroups = get.nGroups(obj)
             nGroups = length(obj.Group);
         end
         
         % can use PODSProject.CurrentGroup.CurrentImage to get current image of current group in project
         function CurrentGroup = get.CurrentGroup(obj)
             CurrentGroup = obj.Group(obj.CurrentGroupIndex);
         end  
         
         function CurrentImage = get.CurrentImage(obj)
             cGroup = obj.CurrentGroup;
             CurrentImage = cGroup.CurrentImage;
         end

     end
     
end