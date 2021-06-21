classdef PODSGroup
    % experimental groups class
    properties
        % group info
        GroupName char        

        % replicates within group
        Replicate PODSImage
        
        nImages uint16
        
        % indexing group members
        CurrentImageIdx uint16
        
        % Object info
        TotalObjects uint16
        
        % FFC info for group
        FFCData struct
        
        % output values
        OFGroupAvg double
        OFGroupMax double
        OFGroupMin double
        FiltOFGroupAvg double
        
        % status parameters
        MaskAllDone logical
        OFAllDone logical
    end
    
    methods
         % assign default values
         function obj = PODSGroup(GroupName)
             obj.GroupName = GroupName;
         end

    end

end