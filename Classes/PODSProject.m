classdef PODSProject
    % experimental groups class
    properties
        % group info
        ProjectName = '';      
        
        % replicates within group
        Group PODSGroup
        
        % number of groups in project
        nGroups uint16
        
        % indexing group members
        CurrentGroupIdx uint16
        
        % handles to all gui objects
        Handles struct       
        
        Settings = PODSSettings;
       
    end
    
%     methods
%         % assign default values
%         function obj = PODSProject(ProjectName)
%             
% 
%         end
%     end
end