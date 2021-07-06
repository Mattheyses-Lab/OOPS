classdef PODSImage
    
    % normal properties
    properties
%% Parent/Child
        Parent PODSGroup
        Object PODSObject
        
%% Input Image Properties        
        % image info
        filename char
        pol_shortname char
        pol_fullname char
        Dimensions double
        Width double
        Height double        
        
        % polarization data
        pol_rawdata
        
        pol_ffc
        
        Pol_ImAvg
        
        norm
        
        r1
        
%% Status Tracking        
        % status parameters
        FilesLoaded = false
        FFCDone = false
        MaskDone = false
        OFDone = false
        ObjectDetectionDone = false
        LocalSBDone = false
        
%% Masking            
        % masks
        bw logical
        
        % label matrices
        L

        % masking parameters
        SE char
        SESize
        SELines
        FilterType char
        ThresholdAdjusted logical
        level double
        
        % masking steps
        I
        BGImg
        BGSubtractedImg
        MedianFilteredImg
        
        % mask threshold adjustment
        IntensityBinCenters
        IntensityHistPlot
        
%% Object Data        
        % objects
        CurrentObjectIdx
        
        ObjectContours
        
%% Output Images
        OF_image
        masked_OF_image
        a
        b
        
%% Output Values        
        
        % output values
        OFAvg double
        OFMax double
        OFMin double
        OFList double
        
        FiltOFAvg double
        
        SBAvg double
    end
    
    % dependent properties
    properties (Dependent = true) 
        ObjectProperties struct
        ObjectNames
        pol_ffc_normalizedbystack
        pol_rawdata_normalizedbystack
        nObjects
    end
    
    methods
        
        % default values for image object
        function obj = PODSImage
            obj.OFAvg = 0;
            obj.OFMax = 0;
            obj.OFMin = 0;       
            obj.FiltOFAvg = 0;
            obj.pol_shortname = '';
            obj.level = 0;
            obj.Width = 0;
            obj.Height = 0;
            obj.ThresholdAdjusted = logical(0);
            obj.MaskDone = logical(0);
            obj.OFDone = logical(0);
            obj.SE = 'disk';
            obj.SESize = num2str(5);
            obj.SELines = num2str(4);
            obj.FilterType = 'Median';
            obj.ObjectNames = {['No Objects Found']};
            obj.CurrentObjectIdx = 0;
        end

        function Object = DetectObjects(obj)
            
            % call get method
            props = obj.ObjectProperties;
            
            if length(props)==0 % if no objects
                Object = PODSObject(props);
                return
            else
                for i = 1:length(props) % for each detected object
                   Object(i) = PODSObject(props(i,1)) % create an instance of PODSObject
                   Object(i).Name = ['Object ',num2str(i)];
                   Object(i).OriginalIdx = i;
                   Object(i).Parent = obj;
                end
            end
        end % end of DetectObjects
        
        % detect local signal to BG ratio
        function obj = FindLocalSB(obj,source)
            
            if obj.ObjectDetectionDone
                
                % square structuring element for object dilation
                se = ones(3,3);
                all_object_pixels = obj.bw;
                all_buffer_pixels = zeros(size(all_object_pixels));
                all_BG_pixels = zeros(size(all_object_pixels));
                
                N = obj.nObjects;
                logmsg = ['Detecting object buffer zone and local BG pixels for ', num2str(N), ' objects...'];
                UpdateLog3(source,logmsg,'append');
                
                
                %% First Step: Treat each object individually, ignoring others.
                %   for each object:
                %       find buffer and BG pixels and store in
                %       SBObjectProperties struct
                for i = 1:N
                    % empty logical matrix
                    object_bw = zeros(size(obj.bw));
                    % get object pixels for current object
                    object_pixels = obj.Object(i).PixelIdxList;
                    % set object pixels to 1
                    object_bw(object_pixels) = 1;

                    % new logical matrix to hold buffer pixels
                    buffer_bw = object_bw;

                    % dilate the object matrix to create the object buffer
                    for j = 1:3
                        buffer_bw = imdilate(buffer_bw,se);
                    end

                    % new logical matrix to hold BG pixels
                    BG_bw = buffer_bw;

                    % dilate the buffer matrix to locate local BG pixels
                    for j = 1:2
                        BG_bw = imdilate(BG_bw,se);
                    end

                    % remove buffer and object pixels from BG matrix
                    BG_bw = BG_bw & ~buffer_bw;

                    % remove object pixels from the buffer matrix
                    buffer_bw = buffer_bw & ~object_bw;

                    % store buffer pixels 
                    obj.Object(i).BufferIdxList = find(buffer_bw==1);
                    % store BG pixels
                    obj.Object(i).BGIdxList = find(BG_bw==1);

                    all_buffer_pixels(obj.Object(i).BufferIdxList) = 1;
                    all_BG_pixels(obj.Object(i).BGIdxList) = 1;
                end

                logmsg = ['Summing signal and BG intensities, computing SB ratio...'];
                UpdateLog3(source,logmsg,'append');    

                %% Second Step: Filter pixels found in step 1
                %   for each object: 
                %       remove any buffer pxs overlapping with object or buffer pxs
                %       remove BG pixels that overlap with object or buffer pixels 
                for i = 1:obj.nObjects
                    buffer_count = 0;
                    BG_count = 0;

                    % check each buffer pixel for overlap with objects
                    for j = 1:length(obj.Object(i).BufferIdxList)
                        if ~(all_object_pixels(obj.Object(i).BufferIdxList(j)) == 1)
                            buffer_count = buffer_count+1;
                            new_buffer(buffer_count) = obj.Object(i).BufferIdxList(j);
                        end
                    end

                    % check each BG pixel for overlap with objects or object buffers
                    for j = 1:length(obj.Object(i).BGIdxList)
                        if ~(all_object_pixels(obj.Object(i).BGIdxList(j)) == 1 | all_buffer_pixels(obj.Object(i).BGIdxList(j)) == 1)
                            BG_count = BG_count+1;
                            new_BG(BG_count) = obj.Object(i).BGIdxList(j);
                        end            
                    end

                    % update buffer and BG pixel lists
                    obj.Object(i).BufferIdxList = new_buffer;
                    obj.Object(i).BGIdxList = new_BG;

                    % calculate signal and BG levels
                    obj.Object(i).SignalAverage = mean(obj.Pol_ImAvg(obj.Object(i).PixelIdxList));
                    obj.Object(i).BGAverage = mean(obj.Pol_ImAvg(obj.Object(i).BGIdxList));
                    obj.Object(i).SBRatio = obj.Object(i).SignalAverage / obj.Object(i).BGAverage;

                    clear new_buffer new_BG

                end

            else
                error('Cannot calculate local S:B until objects are detected');
            end
            
        end
        
        
  
%% Object Methods

        % get ObjectProperties
        function ObjectProperties = get.ObjectProperties(obj)
            % label matrix should be 4-connected, so ObjectProperties
            % should as well
            ObjectProperties = regionprops(full(obj.L),full(obj.bw),'all');
        end

        % get ObjectNames
        function ObjectNames = get.ObjectNames(obj)
            ObjectNames = {};
            [ObjectNames{1:obj.nObjects,1}] = deal(obj.Object.Name);
        end
        
        % set ObjectNames
        function obj = set.ObjectNames(obj,names)
            ObjectNames = names;
        end
        
        % get nObjects
        function nObjects = get.nObjects(obj)
            nObjects = length(obj.Object);
        end      
        
%% Normalize Image Stacks

        % get normalized FFC stack
        function pol_ffc_normalizedbystack = get.pol_ffc_normalizedbystack(obj)
            pol_ffc_normalizedbystack = obj.pol_ffc./(max(max(max(obj.pol_ffc))));
        end
         
        % get normalized raw emission images stack
        function pol_rawdata_normalizedbystack = get.pol_rawdata_normalizedbystack(obj)
            pol_rawdata_normalizedbystack = obj.pol_rawdata./(max(max(max(obj.pol_rawdata))));
        end

    end
end