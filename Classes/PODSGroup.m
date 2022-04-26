classdef PODSGroup < handle
    % experimental groups class
    properties
        % group info
        GroupName char        

        % replicates within group, no problem storing in memory (handle class)
        Replicate PODSImage

        % indexing group members (Replicate/PODSImage objects)
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
        MaskAllDone = false
        
        
        SelfChannelIdx uint8
        ChannelName char
        
        CoLocFilesLoaded = false
        
    end
    
    properties (Dependent = true)
        
        % number of 'images' in this experimental group, depends on the size of obj.Replicate
        nReplicates uint8
        
        % total number of objects in this group, changes depending on user-defined mask
        TotalObjects uint16
        
        % Only the PODSImage objects will store their name in memory, combining them is quick
        ImageNames cell
        
        % currently selected image in GUI
        CurrentImage PODSImage
        
        % currently selected object - updates based on user selection
        CurrentObject PODSObject
        
        % don't want to store in memory for every group
        AllObjectData table

        FilteredObjectData table
        
        OFAllDone logical
    
    end
    
    methods
        
        % class constructor method
        function obj = PODSGroup(GroupName,ChannelName,ChannelIdx)
            if nargin > 0
                obj.GroupName = GroupName;
                obj.ChannelName = ChannelName;
                obj.SelfChannelIdx = ChannelIdx;
            end
        end
            
        function nReplicates = get.nReplicates(obj)
            nReplicates = length(obj.Replicate);
        end
        
        function TotalObjects = get.TotalObjects(obj)
            TotalObjects = 0;
            for i = 1:obj.nReplicates
                TotalObjects = TotalObjects + obj.Replicate(i).nObjects;
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
        
        function CurrentObject = get.CurrentObject(obj)
            cImage = obj.CurrentImage;
            CurrentObject = cImage.CurrentObject;
        end
        
        function OFAllDone = get.OFAllDone(obj)
            if obj.nReplicates == 0
                OFAllDone = false;
                return
            end
            
            for i = 1:obj.nReplicates
                if ~obj.Replicate(i).OFDone
                    OFAllDone = false;
                    return
                end
            end
            OFAllDone = true;
        end
           
        % get x,y data for all objects in group, from first to last replicate
        %       WILL UPDATE TO ALLOW FOR varargin for more flexibility of use
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
        end % end of CombineObjectData()
        
        function VariableObjectData = GetAllObjectData(obj,Var2get)
            %% return a list of Var2Get for all objects in the group
            count = 0;
            last = 1;
            VariableObjectData = [];
            for i = 1:obj.nReplicates
                count = count + obj.Replicate(i).nObjects;
                % column 1 holds x data
                VariableObjectData(last:count,1) = [obj.Replicate(i).Object.(Var2get)];
                last = count+1;
            end            

        end
        

    end

end