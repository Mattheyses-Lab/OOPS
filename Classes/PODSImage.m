classdef PODSImage < handle
    
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
        
        % size of image
        Width double
        Height double
        SelfChannelIdx uint8
        ChannelName char
        
%% Experimental Data
        % raw image stack - pol_rawdata(y/row,x/col,PolIdx)
        %   PolIdx: 1 = 0 deg | 2 = 45 deg | 3 = 90 deg | 4 = 135 deg
        pol_rawdata
        RawPolAvg
        % flat-field corrected image stack - same indexing as raw
        pol_ffc
        % average image stack - Pol_ImAvg(y/row,x/col)
        Pol_ImAvg
        % normalized image stack - same indexing as raw
        norm
        
        r1
        
%% Status Tracking        
        % status parameters - false by default as we haven't started yet
        FilesLoaded = false
        FFCDone = false
        MaskDone = false
        OFDone = false
        ObjectDetectionDone = false
        LocalSBDone = false
        
%% Masking            
        % masks
        bw logical
        bwFiltered logical
        
        % label matrices
        L

        % threshhold
        ThresholdAdjusted logical
        level double
        
        % masking steps
        I double
        BGImg double
        BGSubtractedImg double
        MedianFilteredImg double
        
        % mask threshold adjustment (for display purposes)
        IntensityBinCenters
        IntensityHistPlot
        
%% Object Data        
        % objects
        CurrentObjectIdx uint16 % i.e. no more than 65535 objects per group (seems reasonable, right?)
        
        ObjectContours
        
%% Output Images

        AzimuthImage double
        OF_image double
        masked_OF_image double
        a double
        b double
        
%% Output Values        
        
        % output values
        OFAvg double
        OFMax double
        OFMin double
        OFList double
        
        SBAvg double
        
%% Filtering

        SBCutoff = 3
        OFFiltered double

    end
    
    % dependent properties
    properties (Dependent = true)
        
        % no need to keep this in memory, calculating is pretty fast and it will change frequently
        ObjectProperties struct
        
        % only the individual PODSObject objects themselves will store their names in memory
        ObjectNames cell
        
        % image stacks normalized to the stack-max. again, quick to calculate, expensive to store
        pol_ffc_normalizedbystack
        pol_rawdata_normalizedbystack
        
        % depends on the size of PODSObject
        nObjects uint16
        
        % depends on user-selected index
        CurrentObject PODSObject
        
        % image dimensions, returned as char array for display purposes: 'dim1xdim2'
        Dimensions
        
        % depends on bwFiltered
        FiltOFAvg
    end
    
    methods
        
        % class constructor
        function obj = PODSImage(Group)
            obj.Parent = Group;
            
            % handle multiple channels
            obj.ChannelName = Group.ChannelName;
            obj.SelfChannelIdx = Group.SelfChannelIdx;
            
            % default values for scalar outputs
            obj.OFAvg = 0;
            obj.OFMax = 0;
            obj.OFMin = 0;
            
            % image name (minus path and file extension)
            obj.pol_shortname = '';
            
            % default threshold level (used to set binary mask)
            obj.level = 0;
            
            % default image dimensions
            obj.Width = 0;
            obj.Height = 0;
            
            % status tracking (false by default)
            obj.ThresholdAdjusted = logical(0);
            obj.MaskDone = logical(0);
            obj.OFDone = logical(0);
            
            % default object names, updated once we detect some objects
            %obj.ObjectNames = {['No Objects Found']};

            obj.CurrentObjectIdx = 0;
        end
        
        % performs flat field correction for 1 PODSImage
        function FlatFieldCorrection(obj)
            for i = 1:4
                obj.pol_ffc(:,:,i) = obj.pol_rawdata(:,:,i)./obj.Parent.FFCData.cal_norm(:,:,i);
            end
            obj.FFCDone = true;
        end

        % detects objects in one PODSImage
        function DetectObjects(obj)
            
            % call get method
            props = obj.ObjectProperties;
            
            if length(props)==0 % if no objects
                obj.Object = [];
                return
            else
                for i = 1:length(props) % for each detected object
                   Object(i) = PODSObject(props(i,1),obj); % create an instance of PODSObject
                   Object(i).Name = ['Object ',num2str(i),' (Channel:',obj.ChannelName,')'];
                   Object(i).OriginalIdx = i;
                   Object(i).Parent = obj;
                end
            end
            
            obj.Object = Object;
            
        end % end of DetectObjects        

        % detect local signal to BG ratio
        function obj = FindLocalSB(obj,source)
            
            % can't detect local S/B until we detect the objects!
            if obj.ObjectDetectionDone
                
                % square structuring element for object dilation
                se = ones(3,3);
                all_object_pixels = sparse(obj.bw);
                all_buffer_pixels = sparse(false(size(all_object_pixels)));
                all_BG_pixels = sparse(false(size(all_object_pixels)));
                
                N = obj.nObjects;
                logmsg = ['Detecting object buffer zone and local BG pixels for ', num2str(N), ' objects...'];
                UpdateLog3(source,logmsg,'append');
                
                
                %% First Step: Treat each object individually, ignoring others.
                %   for each object:
                %       find buffer and BG pixels and store in
                %       SBObjectProperties struct
                for i = 1:N
                    % empty logical matrix
                    object_bw = sparse(false(size(obj.bw)));
                    % get object pixels for current object
                    %object_pixels = obj.Object(i).PixelIdxList;
                    % set object pixels to 1
                    object_bw(obj.Object(i).PixelIdxList) = 1;

                    % new logical matrix to hold buffer pixels
                    buffer_bw = object_bw;

                    % dilate the object matrix to create the object buffer
                    for j = 1:3
                        buffer_bw = sparse(imdilate(full(buffer_bw),se));
                    end

                    % new logical matrix to hold BG pixels
                    BG_bw = buffer_bw;

                    % dilate the buffer matrix to locate local BG pixels
                    for j = 1:2
                        BG_bw = sparse(imdilate(full(BG_bw),se));
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

                    % check each buffer pixel for overlap with objects (i = 1 object, j = 1 buffer px)
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

                    %% BUG IDENTIFIED HERE: If there are too many objects within a small region, code may fail to identify 
                        % any BG or buffer pixels. In that case new_buffer and/or new_BG will be empty. Still need to 
                        % implement a fix for this... (maybe delete the object then re-index if no BG pxs found?)
                    % update buffer and BG pixel lists
                    obj.Object(i).BufferIdxList = new_buffer;
                    obj.Object(i).BGIdxList = new_BG;

                    % calculate signal and BG levels
                    obj.Object(i).SignalAverage = mean(obj.RawPolAvg(obj.Object(i).PixelIdxList));
                    obj.Object(i).BGAverage = mean(obj.RawPolAvg(obj.Object(i).BGIdxList));
                    obj.Object(i).SBRatio = obj.Object(i).SignalAverage / obj.Object(i).BGAverage;

                    clear new_buffer new_BG

                end

            else
                error('Cannot calculate local S:B until objects are detected');
            end
            
        end
        
        function Dimensions = get.Dimensions(obj)
            
            Dimensions = [num2str(obj.Height),'x',num2str(obj.Width)];
            
        end 
        
        function FiltOFAvg = get.FiltOFAvg(obj)
            
            FiltOFAvg = sum(sum(obj.OFFiltered))/nnz(obj.OFFiltered);
            
        end

%% PODSObject Methods

        % get current Object (PODSObject)
        function CurrentObject = get.CurrentObject(obj)
            CurrentObject = obj.Object(obj.CurrentObjectIdx);
        end

        % get ObjectProperties
        function ObjectProperties = get.ObjectProperties(obj)
            % label matrix should be 4-connected, so ObjectProperties
            % should as well
            ObjectProperties = regionprops(full(obj.L),full(obj.bw),'all');
        end

        % get ObjectNames
        function ObjectNames = get.ObjectNames(obj)
            ObjectNames = {};
            try
                [ObjectNames{1:obj.nObjects,1}] = deal(obj.Object.Name);
            catch
                [ObjectNames{1:1}] = 'No Objects Found...';
            end
            
        end
        
        % get nObjects
        function nObjects = get.nObjects(obj)
            if isvalid(obj.Object)
                nObjects = length(obj.Object);
            else
                nObjects = 0;
            end
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