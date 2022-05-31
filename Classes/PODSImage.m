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
        
%% Experimental Data
        % raw image stack - pol_rawdata(y/row,x/col,PolIdx)
        %   PolIdx: 1 = 0 deg | 2 = 45 deg | 3 = 90 deg | 4 = 135 deg
        pol_rawdata
        RawPolAvg
        % flat-field corrected image stack - same indexing as raw
        pol_ffc
        % average image stack - Pol_ImAvg(y/row,x/col)
        Pol_ImAvg
        % pixel-normalized image stack - same indexing as raw
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
        ColocFilesLoaded = false
        
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
        CurrentObjectIdx uint16 % i.e. no more than 65535 objects per group
        
%% Reference Image

        ReferenceImage double
        ReferenceImageLoaded = false
        
%%

        AzimuthLineData double
        
%% Output Images

        AzimuthImage double
        OF_image double
        masked_OF_image double
        a double
        b double
        
%% Output Values        
        
        % output values
        
        SBAvg double
        
%% Filtering

        SBCutoff = 3
        OFFiltered double
        
%% Settings
        % store handle to settings object to speed up retrieval of various settings
        Settings PODSSettings

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
        Dimensions char
        
        % depends on bwFiltered
        FiltOFAvg double
        
        % depend on objects
        OFAvg double
        OFMax double
        OFMin double
        OFList double        
    end
    
    methods
        
        % class constructor
        function obj = PODSImage(Group)
            obj.Parent = Group;
            obj.Settings = Group.Settings;
            
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

            obj.CurrentObjectIdx = 0;
        end
        
        % performs flat field correction for 1 PODSImage
        function FlatFieldCorrection(obj)
            % divide each raw data image by the corresponding flatfield image
            for i = 1:4
                obj.pol_ffc(:,:,i) = obj.pol_rawdata(:,:,i)./obj.Parent.FFCData.cal_norm(:,:,i);
            end
            % average FFC intensity
            obj.Pol_ImAvg = mean(obj.pol_ffc,3);
            % normalized average FFC intensity (normalized to max)
            obj.I = obj.Pol_ImAvg./max(max(obj.Pol_ImAvg));
            % done with FFC
            obj.FFCDone = true;
        end

        % detects objects in one PODSImage
        function DetectObjects(obj)
            
            % call get method
            props = obj.ObjectProperties;

            if length(props)==0 % if no objects
                delete(obj.Object);
                return
            else
                % get default label from settings object
                DefaultLabel = obj.Settings.ObjectLabels(1);
                for i = 1:length(props) % for each detected object
                   % create an instance of PODSObject 
                   Object(i) = PODSObject(props(i,1),...
                       obj,...
                       ['Object ',num2str(i)],...
                       i,...
                       DefaultLabel);
                end
            end
            
            obj.Object = Object;
            obj.ObjectDetectionDone = true;
            
        end % end of DetectObjects
        
        % delete seleted objects from one PODSImage
        function DeleteSelectedObjects(obj)
            
            Selected = find([obj.Object.Selected]);
            NotSelected = find(~[obj.Object.Selected]);
            
            % get handles to all objects in this image
            AllObjects = obj.Object;
            
            % get list of 'good' objects (not selected)
            Good = AllObjects(NotSelected);
            
            % get list of objects to delete (selected)
            Bad = AllObjects(Selected);
            
            % replace object array of image with only the ones we wish to keep (not selected)
            obj.Object = Good;
            
            for i = 1:length(obj.Object)
                % reset the object indices
                obj.Object(i).OriginalIdx = i;
                obj.Object(i).Name = ['Object ',num2str(i)];
            end
            
            % in case current object is greater than the total # of objects
            if obj.CurrentObjectIdx > obj.nObjects
                % select the last object in the list
                obj.CurrentObjectIdx = obj.nObjects;
            end
            
            % delete the bad PODSObject objects
            % set their pixel idxs to 0 in the mask
            for i = 1:length(Bad)
                obj.bw(Bad(i).SubarrayIdx{:}) = 0;
                delete(Bad(i));
            end
            % clear Bad array
            clear Bad
            % compute a new label matrix
            obj.L = bwlabel(full(obj.bw),4);
        end
        
        % apply unique label to selected objects in one PODSImage
        function LabelSelectedObjects(obj,Label)
            % find indices of currently selected objects
            Selected = find([obj.Object.Selected]);
            % apply the new label to those objects
            [obj.Object(Selected).Label] = deal(Label);
        end
        
        % clear selection status of objects in one PODSImage
        function ClearSelection(obj)
            [obj.Object.Selected] = deal(false);
        end
        
        function ObjectDataByLabel = GetObjectDataByLabel(obj,Var2Get)
            nLabels = length(obj.Settings.ObjectLabels);
            ObjectDataByLabel = cell(1,nLabels);
            for i = 1:nLabels
                % find objects with LabelIdx i
                ObjectLabelIdxs = find([obj.Object.LabelIdx]==i);
                % add [Var2Get] from those objects to cell i of ObjectDataByLabel
                ObjectDataByLabel{i} = [obj.Object(ObjectLabelIdxs).(Var2Get)];
            end
        end

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
%                 logmsg = ['Detecting object buffer zone and local BG pixels for ', num2str(N), ' objects...'];
%                 UpdateLog3(source,logmsg,'append');
                
                
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

%                 logmsg = ['Summing signal and BG intensities, computing SB ratio...'];
%                 UpdateLog3(source,logmsg,'append');    

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
                        % however, this is a very rare bug that only causes issues in cases of very low S/N, in which 
                        % DetectObjects() labels most of the BG pixels as objects
                    % update buffer and BG pixel lists
                    obj.Object(i).BufferIdxList = new_buffer;
                    obj.Object(i).BGIdxList = new_BG;

                    % calculate signal and BG levels
                    obj.Object(i).SignalAverage = mean(obj.RawPolAvg(obj.Object(i).PixelIdxList));
                    obj.Object(i).BGAverage = mean(obj.RawPolAvg(obj.Object(i).BGIdxList));
                    obj.Object(i).SBRatio = obj.Object(i).SignalAverage / obj.Object(i).BGAverage;

                    clear new_buffer new_BG

                end
                
                obj.LocalSBDone = true;

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

%% Dependent output values

        function OFAvg = get.OFAvg(obj)
            % average OF of all pixels identified by the mask
            try
                OFAvg = mean(obj.OF_image(obj.bw));
            catch
                OFAvg = NaN;
            end
        end
        
        function OFMax = get.OFMax(obj)
            % max OF of all pixels identified by the mask
            try
                OFMax = max(obj.OF_image(obj.bw));
            catch
                OFMax = NaN;
            end
        end
        
        function OFMin = get.OFMin(obj)
            % min OF of all pixels identified by the mask
            try
                OFMin = min(obj.OF_image(obj.bw));
            catch
                OFMin = NaN;
            end
        end
        
        function OFList = get.OFList(obj)
            % list of OF in all pixels identified by mask
            try
                OFList = obj.OF_image(obj.bw);
            catch
                OFList = NaN;
            end
        end

    end
end