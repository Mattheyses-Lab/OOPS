classdef PODSGroup
    % experimental groups class
    properties
        % group info
        GroupName char        

        % replicates within group
        Replicate PODSImage

        % indexing group members
        CurrentImageIndex double
        PreviousImageIndex double
        
        % FFC info for group
        FFCData struct
        
        % output values
        OFAvg double
        OFMax double
        OFMin double
        FiltOFAvg double
        
        % status parameters
        MaskAllDone logical
        OFAllDone logical
        
    end
    
    properties (Dependent = true)
        
        nReplicates
        
        TotalObjects
        
        ImageNames
        
        CurrentImage PODSImage
                
    end
    
    methods
        
         function nReplicates = get.nReplicates(obj)
             nReplicates = length(obj.Replicate);
         end
         
         function TotalObjects = get.TotalObjects(obj)
             try
                TotalObjects = length(obj.Replicate.Object);
             catch
                TotalObjects = 0;
             end
         end
         
         function ImageNames = get.ImageNames(obj)
            % new cell array of image names
            ImageNames = {};
            [ImageNames{1:obj.nReplicates,1}] = obj.Replicate.pol_shortname;             
         end
         
         
         function CurrentImage = get.CurrentImage(obj)
             CurrentImage = obj.Replicate(obj.CurrentImageIndex);
         end
         
         
         % get x,y data for all objects in group, from first to last replicate
         function ObjectData = CombineObjectData(obj,XVar,YVar)
             
             count = 0;
             last = 1;
             
             for i = 1:obj.nReplicates
                 
                 count = count + obj.Replicate(i).nObjects;

                 % column 1 holds x data
                 ObjectData(last:count,1) = [obj.Replicate(i).Object.(XVar)];
                 % column 2 holds y data
                 ObjectData(last:count,2) = [obj.Replicate(i).Object.(YVar)];
                 
                 last = count+1;
             
             end
         end % end of CombinedObjectData

    end

end