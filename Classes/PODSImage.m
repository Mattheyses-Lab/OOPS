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
        
%% Raw data stack and various normalized/averaged versions
        % raw image stack - pol_rawdata(y/row,x/col,PolIdx)
        %   PolIdx: 1 = 0 deg | 2 = 45 deg | 3 = 90 deg | 4 = 135 deg
        pol_rawdata
        % average intensity of the raw data
        RawPolAvg
        % flat-field corrected image stack - same indexing as raw
        pol_ffc
        % average image stack - Pol_ImAvg(y/row,x/col)
        Pol_ImAvg
        % pixel-normalized image stack - same indexing as raw
        norm
        % logical array of the pixels with intensity > 0 (should be true for all)
        r1
        
%% Status Tracking        
        % status parameters - false by default as we haven't started yet
        FilesLoaded = false
        FFCDone = false
        MaskDone = false
        OFDone = false
        ObjectDetectionDone = false
        LocalSBDone = false
        ObjectAzimuthDone = false
        ReferenceImageLoaded = false
        
%% Masking            
        % masks
        bw logical
        
        % label matrices
        L

        % threshhold
        ThresholdAdjusted logical
        level double
        
        % masking steps
        I double
        EnhancedImg double

        MaskType = 'Default'
        MaskName = 'Legacy'
        
        % mask threshold adjustment (for display purposes)
        IntensityBinCenters
        IntensityHistPlot
        
%% Object Data        
        % objects
        CurrentObjectIdx uint16 % i.e. no more than 65535 objects per group
        
%% Reference Image

        ReferenceImage double
        ReferenceImageEnhanced double
        
%%
        AzimuthLineData double
        
%% Output Images

        AzimuthImage double
        OF_image double
        a double
        b double
        
%% Output Values        
        
        % output values
        SBAvg double
        
%%
        PrimaryIntensityDisplayLimits = [0 1];
        ReferenceIntensityDisplayLimits = [0 1];
        
%% Settings
        % store handle to settings object to speed up retrieval of various settings
        Settings PODSSettings
 
    end
    
    % dependent properties
    properties (Dependent = true)
        
        % other output images that we don't need in memory
        OFImageRGB        
        MaskedOFImage
        MaskedOFImageRGB
        AzimuthRGB
        MaskedAzimuthRGB

        % no need to keep this in memory, calculating is pretty fast and it will change frequently
        ObjectProperties struct


        ObjectBoundaries4
        ObjectBoundaries8
        
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
        
        % 2-element vector describing the limits of the image in real-world coordinates
        RealWorldLimits double        
        
        % depend on objects
        OFAvg double
        OFMax double
        OFMin double
        OFList double

        % index of this image in [obj.Parent.Replicate()]
        SelfIdx

        % some display properties specific to this image
        ThreshPanelTitle char
        ThreshStatisticName char
        ManualThreshEnabled logical
    end
    
    methods
        
        % class constructor
        function obj = PODSImage(Group)
            obj.Parent = Group;

            if ~isempty(obj.Parent)
                obj.Settings = Group.Settings;
            else
                obj.Settings = PODSSettings.empty();
            end
            
            % image name (minus path and file extension)
            obj.pol_shortname = '';
            
            % default threshold level (used to set binary mask)
            obj.level = 0;
            
            % default image dimensions
            obj.Width = 0;
            obj.Height = 0;
            
            % status tracking (false by default)
            obj.ThresholdAdjusted = false;
            obj.MaskDone = false;
            obj.OFDone = false;

            obj.CurrentObjectIdx = 0;
        end
        
        % destructor method
        function delete(obj)
            % delete obj.Object first
            obj.deleteObjects();
            % then delete this object
            delete(obj);
        end

        % saveobj method
        function replicate = saveobj(obj)

            replicate.filename = obj.filename;
            replicate.pol_shortname = obj.pol_shortname;
            replicate.pol_fullname = obj.pol_fullname;
            replicate.Width = obj.Width;
            replicate.Height = obj.Height;

            replicate.FilesLoaded = obj.FilesLoaded;
            replicate.FFCDone = obj.FFCDone;
            replicate.MaskDone = obj.MaskDone;
            replicate.OFDone = obj.OFDone;
            replicate.ObjectDetectionDone = obj.ObjectDetectionDone;
            replicate.LocalSBDone = obj.LocalSBDone;
            replicate.ObjectAzimuthDone = obj.ObjectAzimuthDone;
            replicate.ReferenceImageLoaded = obj.ReferenceImageLoaded;

            replicate.bw = obj.bw;

            replicate.ThresholdAdjusted = obj.ThresholdAdjusted; 
            replicate.level = obj.level;

            replicate.EnhancedImg = obj.EnhancedImg;

            replicate.MaskName = obj.MaskName;

            replicate.IntensityBinCenters = obj.IntensityBinCenters;
            replicate.IntensityHistPlot = obj.IntensityHistPlot;

            replicate.SBAvg = obj.SBAvg;

            replicate.PrimaryIntensityDisplayLimits = obj.PrimaryIntensityDisplayLimits;
            replicate.ReferenceIntensityDisplayLimits = obj.ReferenceIntensityDisplayLimits;

            replicate.nObjects = obj.nObjects;

            replicate.CurrentObjectIdx = obj.CurrentObjectIdx;

            for i = 1:obj.nObjects
                replicate.Object(i) = obj.Object(i).saveobj();
            end

        end

        % get the index of this PODSImage in [obj.Parent.Replicate(:)]
        function SelfIdx = get.SelfIdx(obj)
            SelfIdx = find(obj.Parent.Replicate==obj);
        end

        % performs flat field correction for 1 PODSImage
        function FlatFieldCorrection(obj)
            % divide each raw data image by the corresponding flatfield image
            for i = 1:4
                obj.pol_ffc(:,:,i) = obj.pol_rawdata(:,:,i)./obj.Parent.FFC_cal_norm(:,:,i);
            end
            % average FFC intensity
            obj.Pol_ImAvg = mean(obj.pol_ffc,3);
            % normalized average FFC intensity (normalized to max)
            obj.I = obj.Pol_ImAvg./max(max(obj.Pol_ImAvg));
            % done with FFC
            obj.FFCDone = true;
        end

        % detects objects in this PODSImage
        function DetectObjects(obj)
            % start by deleting any currently existing objects
            obj.deleteObjects();

            % call dependent 'get' method
            props = obj.ObjectProperties;

            if isempty(props) % if no objects
                return % then stop here
            else
                % get default label from settings object
                DefaultLabel = obj.Settings.ObjectLabels(1);

                for i = 1:length(props) % for each detected object
                   % create an instance of PODSObject
                   obj.Object(i) = PODSObject(props(i,1),...
                       obj,...
                       DefaultLabel);
                end
            end
            
            % update some status tracking variables
            obj.ObjectDetectionDone = true;
            obj.CurrentObjectIdx = 1;
            obj.LocalSBDone = false;
            obj.ObjectAzimuthDone = false;
            
        end % end of DetectObjects
        
        % delete seleted objects from one PODSImage
        function DeleteSelectedObjects(obj)
            
            % get handles to all objects in this image
            AllObjects = obj.Object;
            
            % get list of 'good' objects (not selected)
            Good = AllObjects(~[obj.Object.Selected]);
            
            % get list of objects to delete (selected)
            Bad = AllObjects([obj.Object.Selected]);
            
            % replace object array of image with only the ones we wish to keep (not selected)
            obj.Object = Good;
            
            % in case current object is greater than the total # of objects
            if obj.CurrentObjectIdx > obj.nObjects
                % select the last object in the list
                obj.CurrentObjectIdx = obj.nObjects;
            end
            
            % delete the bad PODSObject objects
            % set their pixel idxs to 0 in the mask
            for i = 1:length(Bad)
%                 obj.bw(Bad(i).SubarrayIdx{:}) = 0;
                obj.bw(Bad(i).PixelIdxList) = 0;
                delete(Bad(i));
            end
            % clear Bad array
            clear Bad

            obj.L(:) = 0;
            for i = 1:numel(obj.Object)
                obj.L(obj.Object(i).PixelIdxList) = obj.Object(i).SelfIdx;
            end

            % % compute a new label matrix
            % obj.L = bwlabel(full(obj.bw),4);
        end

        % delete objects with a specific label
        function DeleteObjectsByLabel(obj,Label)
            
            % get handles to all objects in this image
            AllObjects = obj.Object;
            % idxs to the bad objects
            BadIdxs = find([AllObjects.Label]==Label);
            % and the bad objects
            Bad = AllObjects(BadIdxs);
            % idxs to the good objects
            GoodIdxs = find([AllObjects.Label]~=Label);
            % and the good objects
            Good = AllObjects(GoodIdxs);
            % replace the Object array of this image with only the ones we are keeping
            obj.Object = Good;
            % in case current object is greater than the total # of objects
            if obj.CurrentObjectIdx > obj.nObjects
                % select the last object in the list
                obj.CurrentObjectIdx = obj.nObjects;
            end
            % delete the bad PODSObject objects
            % set their pixel idxs to 0 in the mask
            for i = 1:length(Bad)
                obj.bw(Bad(i).PixelIdxList) = 0;
                delete(Bad(i));
            end
            % clear Bad array
            clear Bad

            obj.L(:) = 0;
            for i = 1:numel(obj.Object)
                obj.L(obj.Object(i).PixelIdxList) = obj.Object(i).SelfIdx;
            end
            % 
            % 
            % % compute a new label matrix
            % obj.L = bwlabel(full(obj.bw),4);

        end
        
        % apply PODSLabel:Label to all selected objects in this PODSImage
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
        
        % return object data grouped by the object labels
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

        % return all objects in this PODSImage with the PODSLabel:Label
        function Objects = getObjectsByLabel(obj,Label)

            Objects = PODSObject.empty();

            if obj.nObjects >= 1
                ObjIdxs = find([obj.Object.Label]==Label);
                Objects = obj.Object(ObjIdxs);
            else
                Objects = [];
            end

        end

        function FindOrderFactor(obj)
            % normalize each pixel in polarization stack to the maximum in dim 3
            maximum = max(obj.pol_ffc,[],3);
            obj.r1 = obj.pol_ffc(:,:,1) > 0;
            obj.norm = obj.pol_ffc./maximum;
            % orthogonal polarization difference components
            obj.a = obj.norm(:,:,1) - obj.norm(:,:,3);
            obj.b = obj.norm(:,:,2) - obj.norm(:,:,4);
            % find Order Factor
            obj.OF_image = zeros(size(obj.norm(:,:,1)));
            obj.OF_image(obj.r1) = sqrt(obj.a(obj.r1).^2+obj.b(obj.r1).^2);
            % find azimuth image
            obj.AzimuthImage = zeros(size(obj.norm(:,:,1)));
            % WARNING: Output is in radians! Counterclockwise with respect to the horizontal direction in the image
            obj.AzimuthImage(obj.r1) = (1/2).*atan2(obj.b(obj.r1),obj.a(obj.r1));
            % update completion status
            obj.OFDone = true;
        end

        % detect local S/B ratio for each object in this PODSImage
        function obj = FindLocalSB(obj)
            
            % can't detect local S/B until we detect the objects!
            if obj.ObjectDetectionDone
                
                % square structuring element for object dilation
                se = ones(3,3);
                all_object_pixels = obj.bw;
                all_buffer_pixels = false(size(all_object_pixels));
                all_BG_pixels = false(size(all_object_pixels));
                
                N = obj.nObjects;
                
                
                %% First Step: Treat each object individually, ignoring others.
                %   for each object:
                %       find buffer and BG pixels and store in
                %       SBObjectProperties struct
                for i = 1:N
                    % empty logical matrix
                    object_bw = false(size(obj.bw));
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
                        if ~(all_object_pixels(obj.Object(i).BGIdxList(j)) == 1 || all_buffer_pixels(obj.Object(i).BGIdxList(j)) == 1)
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

                    try
                        obj.Object(i).BGIdxList = new_BG;
                        obj.Object(i).BGAverage = mean(obj.RawPolAvg(obj.Object(i).BGIdxList));
                    catch
                        obj.Object(i).BGIdxList = [];
                        obj.Object(i).BGAverage = NaN;
                    end

                    % calculate signal and BG levels
                    obj.Object(i).SignalAverage = mean(obj.RawPolAvg(obj.Object(i).PixelIdxList));
%                     obj.Object(i).BGAverage = mean(obj.RawPolAvg(obj.Object(i).BGIdxList));
                    obj.Object(i).SBRatio = obj.Object(i).SignalAverage / obj.Object(i).BGAverage;

                    clear new_buffer new_BG

                end
                
                obj.LocalSBDone = true;

            else
                error('Cannot calculate local S:B until objects are detected');
            end
            
        end
        
        function ComputeObjectAzimuthStats(obj)
            % only run if OF calculated and objects detected
            if obj.ObjectDetectionDone && obj.OFDone
                for i = 1:obj.nObjects
                    cObject = obj.Object(i);
                    % get object azimuth avg values
                    try
                        [~,cObject.AzimuthAverage] = getAzimuthAverageUsingDipoles(rad2deg(cObject.AzimuthPixelValues));
                    catch
                        cObject.AzimuthAverage = NaN;
                    end

                    % get object azimuth std values
                    try
                        cObject.AzimuthStd = getAzimuthStd(rad2deg(cObject.AzimuthPixelValues));
                    catch
                        cObject.AzimuthStd = NaN;
                    end

                    try

                        % construct the object midline (this function still needs optimization)
                        [~,~,cObject.Midline] = getObjectMidline(cObject.RestrictedPaddedMaskSubImage,"DisplayResults",false);

                        [cObject.MidlineRelativeAzimuth,cObject.NormalRelativeAzimuth] = getRelativeAzimuth(...
                            cObject.RestrictedPaddedMaskSubImage,...
                            cObject.PaddedAzimuthSubImage,...
                            cObject.Midline...
                            );
                    catch
                        warning(['Warning: Failed to calculate relative azimuth for object: ',num2str(cObject.SelfIdx)])
                        cObject.MidlineRelativeAzimuth = NaN;
                        cObject.NormalRelativeAzimuth = NaN;
                    end

                end
                obj.ObjectAzimuthDone = true;
            end
        end

        % dependent get methods for image size, resolution
        function Dimensions = get.Dimensions(obj)
            Dimensions = [num2str(obj.Height),'x',num2str(obj.Width)];
        end
        
        function RealWorldLimits = get.RealWorldLimits(obj)
            RealWorldLimits = [0 obj.Settings.PixelSize*obj.Width];
        end

%% dependent get methods for various display options specific to this image

        function ThreshPanelTitle = get.ThreshPanelTitle(obj)
            switch obj.MaskType
                case 'Default'
                    switch obj.MaskName
                        case 'Legacy'
                            ThreshPanelTitle = 'Adjust Otsu threshold';
                        case 'Adaptive'
                            ThreshPanelTitle = 'Adjust adaptive mask sensitivity';
                        case 'Intensity'
                            ThreshPanelTitle = 'Adjust intensity threshold';
                        otherwise
                            ThreshPanelTitle = 'Manual thresholding unavailable for this masking scheme';
                    end
                case 'CustomScheme'
                    ThreshPanelTitle = 'Manual thresholding unavailable for this masking scheme';
            end
        end

        function ThreshStatisticName = get.ThreshStatisticName(obj)
            switch obj.MaskType
                case 'Default'
                    switch obj.MaskName
                        case 'Legacy'
                            ThreshStatisticName = 'Threshold';
                        case 'Adaptive'
                            ThreshStatisticName = 'Adaptive mask sensitivity';
                        case 'Intensity'
                            ThreshStatisticName = 'Threshold';
                        otherwise
                            ThreshStatisticName = false;
                    end
                case 'CustomScheme'
                    ThreshStatisticName = false;
            end
            % when set to false, will throw an error that we will catch when updating display
        end

        function ManualThreshEnabled = get.ManualThreshEnabled(obj)
            switch obj.MaskType
                case 'Default'
                    switch obj.MaskName
                        case 'Legacy'
                            ManualThreshEnabled = true;
                        case 'Adaptive'
                            ManualThreshEnabled = true;
                        case 'Intensity'
                            ManualThreshEnabled = true;
                        otherwise
                            ManualThreshEnabled = false;
                    end
                case 'CustomScheme'
                    ManualThreshEnabled = false;
            end
        end

%% dependent get methods for output images

        function OFImageRGB = get.OFImageRGB(obj)
            OFImageRGB = ind2rgb(im2uint8(obj.OF_image),obj.Settings.OrderFactorColormap);
        end

        function MaskedOFImage = get.MaskedOFImage(obj)
            % get the full OF image
            MaskedOFImage = obj.OF_image;
            % set any pixels outside the mask to 0
            MaskedOFImage(~obj.bw) = 0;
        end

        function MaskedOFImageRGB = get.MaskedOFImageRGB(obj)
            MaskedOFImageRGB = MaskRGB(obj.OFImageRGB,obj.bw);
        end

        function AzimuthRGB = get.AzimuthRGB(obj)
            AzimuthImage = obj.AzimuthImage;
            % values originally in [-pi/2 pi/2], adjust to fall in [0 pi]
            AzimuthImage(AzimuthImage<0) = AzimuthImage(AzimuthImage<0)+pi;
            % scale values to [0 1]
            AzimuthImage = AzimuthImage./pi;
            % convert to uint8 then to RGB
            AzimuthRGB = ind2rgb(im2uint8(AzimuthImage),obj.Settings.AzimuthColormap);
        end

        function MaskedAzimuthRGB = get.MaskedAzimuthRGB(obj)
            MaskedAzimuthRGB = MaskRGB(obj.AzimuthRGB,obj.bw);
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
            %ObjectProperties = regionprops(full(obj.L),full(obj.bw),'all');
            % properties from ObjectProps struct
            ObjectProperties = regionprops(full(obj.L),full(obj.bw),...
                {'Area',...
                'BoundingBox',...
                'Centroid',...
                'Circularity',...
                'ConvexArea',...
                'ConvexHull',...
                'ConvexImage',...
                'Eccentricity',...
                'Extent',...
                'Extrema',...
                'EquivDiameter',...
                'FilledArea',...
                'Image',...
                'MajorAxisLength',...
                'MinorAxisLength',...
                'Orientation',...
                'Perimeter',...
                'PixelIdxList',...
                'PixelList',...
                'Solidity',...
                'SubarrayIdx',...
                'MaxFeretProperties',...
                'MinFeretProperties'});

            % get idxs to 'Image' and 'BoundingBox' fields
            fnames = fieldnames(ObjectProperties);
            % conver ObjectProperties struct to cell array
            C = struct2cell(ObjectProperties).';
            % get object images (using struct fieldnames to find idx to 'Image' column in cell array)
            ObjectImages = C(:,ismember(fnames,'Image'));
            % get object bounding boxes (using fieldnames to find idx to 'BoundingBox' column in cell array)
            ObjectBBox = C(:,ismember(fnames,'BoundingBox'));
            % get boundaries from ObjectImages
            B = cellfun(@(obj_img)bwboundaries(obj_img,8,'noholes'),ObjectImages,'UniformOutput',0);
            % add bounding box offsets to boundary coordinates from ObjectImages
            % box([2 1]) gives the (y,x) coordinates of the top-left corner of the box
            B = cellfun(@(b,box) bsxfun(@plus,b{1},box([2 1]) - 0.5),B,ObjectBBox,'UniformOutput',0);
            % add object boundaries cell to props struct
            ObjectProperties(end).BWBoundary = [];
            [ObjectProperties(:).BWBoundary] = deal(B{:});

        end

        % get 4-connected object boundaries
        function ObjectBoundaries4 = get.ObjectBoundaries4(obj)
            ObjectBoundaries4 = bwboundaries(full(obj.bw),4,'noholes');
        end

        % get 8-connected object boundaries
        function ObjectBoundaries8 = get.ObjectBoundaries8(obj)
            ObjectBoundaries8 = bwboundaries(full(obj.bw),8,'noholes');
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
        
        function [...
                SelectedFaces,...
                SelectedVertices,...
                SelectedCData,...
                UnselectedFaces,...
                UnselectedVertices,...
                UnselectedCData...
                ] = getObjectPatchData(obj)

            % get handles to all objects in this image
            AllObjects = obj.Object;

            % get list of unselected objects
            Unselected = AllObjects(~[obj.Object.Selected]);
            UnselectedVerticesMax = 0;
            UnselectedVerticesSum = 0;

            % get list of selected objects
            Selected = AllObjects([obj.Object.Selected]);
            SelectedVerticesMax = 0;
            SelectedVerticesSum = 0;

            for cObject = obj.Object
                nVertices = size(cObject.SimplifiedBoundary,1);
                switch cObject.Selected
                    case true
                        SelectedVerticesSum = SelectedVerticesSum + nVertices;
                        SelectedVerticesMax = max(SelectedVerticesMax,nVertices);
                    case false
                        UnselectedVerticesSum = UnselectedVerticesSum + nVertices;
                        UnselectedVerticesMax = max(UnselectedVerticesMax,nVertices);
                end
            end

            UnselectedFaces = nan(numel(Unselected),UnselectedVerticesMax);
            UnselectedVertices = zeros(UnselectedVerticesSum+numel(Unselected),2);
            UnselectedCData = zeros(UnselectedVerticesSum+numel(Unselected),3);
            TotalUnselectedVertices = 0;
            UnselectedCounter = 0;

            SelectedFaces = nan(numel(Selected),SelectedVerticesMax);
            SelectedVertices = zeros(SelectedVerticesSum+numel(Selected),2);
            SelectedCData = zeros(SelectedVerticesSum+numel(Selected),3);
            TotalSelectedVertices = 0;
            SelectedCounter = 0;

            for cObject = obj.Object
                % get the boundary
                thisObjectBoundary = cObject.SimplifiedBoundary;
                % determine number of vertices
                nvertices = size(thisObjectBoundary,1);
                switch cObject.Selected
                    case true
                        % increment SelectedCounter
                        SelectedCounter = SelectedCounter + 1;
                        % obtain vertices idx
                        SelectedVerticesIdx = (TotalSelectedVertices+1):(TotalSelectedVertices+nvertices);
                        % add boundary coords to list of vertices
                        SelectedVertices(SelectedVerticesIdx,:) = [thisObjectBoundary(:,2) thisObjectBoundary(:,1)];
                        % add CData for each vertex
                        SelectedCData(SelectedVerticesIdx,:) = zeros(numel(SelectedVerticesIdx),3)+cObject.Label.Color;
                        % add vertex idxs to faces list
                        SelectedFaces(SelectedCounter,1:nvertices) = SelectedVerticesIdx;
                        % update total number of vertices
                        TotalSelectedVertices = TotalSelectedVertices+nvertices;
                    case false
                        % increment UnselectedCounter
                        UnselectedCounter = UnselectedCounter + 1;
                        % obtain vertices idx
                        UnselectedVerticesIdx = (TotalUnselectedVertices+1):(TotalUnselectedVertices+nvertices);
                        % add boundary coords to list of vertices
                        UnselectedVertices(UnselectedVerticesIdx,:) = [thisObjectBoundary(:,2) thisObjectBoundary(:,1)];
                        % add CData for each vertex
                        UnselectedCData(UnselectedVerticesIdx,:) = zeros(numel(UnselectedVerticesIdx),3)+cObject.Label.Color;
                        % add vertex idxs to faces list
                        UnselectedFaces(UnselectedCounter,1:nvertices) = UnselectedVerticesIdx;
                        % update total number of vertices
                        TotalUnselectedVertices = TotalUnselectedVertices+nvertices;
                end
            end
        end

        % return the number of objects in this PODSImage
        function nObjects = get.nObjects(obj)
            if isvalid(obj.Object)
                nObjects = length(obj.Object);
            else
                nObjects = 0;
            end
        end

        function deleteObjects(obj)
            % collect and delete the objects in this image
            Objects = obj.Object;
            delete(Objects);
            % clear the placeholders
            clear Objects
            % reinitialize the obj.Object vector
            obj.Object = PODSObject.empty();
            % % delete again? CHECK THIS
            % delete(obj.Object);
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

    methods (Static)
        function obj = loadobj(replicate)

            obj = PODSImage(PODSGroup.empty());

            % info about the image path and filename
            obj.filename = replicate.filename;
            obj.pol_shortname = replicate.pol_shortname;
            obj.pol_fullname = replicate.pol_fullname;

            %% attempt to load the raw data using the saved filename

            % find file extension
            fnameSplit = strsplit(obj.filename,'.');
            fileType = fnameSplit{end};

            % load the image data
            switch fileType
                case 'nd2'
                    disp(['Loading ',obj.pol_fullname,'...']);
                    % get file data structure
                    temp = bfopen(char(replicate.pol_fullname));
                    temp2 = temp{1,1};
                    % get image dimensions
                    obj.Height = size(temp2{1,1},1);
                    obj.Width = size(temp2{1,1},2);
                    % pre-allocate raw data array
                    obj.pol_rawdata = zeros(obj.Height,obj.Width,4);
                    % add each pol slice to 3D image matrix
                    for j=1:4
                        obj.pol_rawdata(:,:,j) = im2double(temp2{j,1})*65535;
                    end
                case 'tif'
                    disp(['Loading ',obj.pol_fullname,'...']);
                    % get file data structure
                    info = imfinfo(char(obj.pol_fullname));
                    % get image dimensions
                    obj.Height = info.Height;
                    obj.Width = info.Width;
                    % pre-allocate raw data array
                    obj.pol_rawdata = zeros(obj.Height,obj.Width,4);
                    % add the image data to pol_rawdata
                    for j=1:4
                        obj.pol_rawdata(:,:,j) = im2double(imread(char(obj.pol_fullname),j))*65535;
                    end
            end

            %% end raw data loading

            % average the raw data (polarization stack)
            obj.RawPolAvg = mean(obj.pol_rawdata,3);

            obj.FilesLoaded = replicate.FilesLoaded;
            obj.FFCDone = replicate.FFCDone;
            obj.MaskDone = replicate.MaskDone;
            obj.OFDone = replicate.OFDone;
            obj.ObjectDetectionDone = replicate.ObjectDetectionDone;
            obj.LocalSBDone = replicate.LocalSBDone;
            obj.ObjectAzimuthDone = replicate.ObjectAzimuthDone;
            obj.ReferenceImageLoaded = replicate.ReferenceImageLoaded;

            obj.bw = replicate.bw;

            obj.L = sparse(bwlabel(full(obj.bw),4));

            obj.ThresholdAdjusted = replicate.ThresholdAdjusted; 
            obj.level = replicate.level;

            obj.EnhancedImg = replicate.EnhancedImg;

            obj.MaskName = replicate.MaskName;

            obj.IntensityBinCenters = replicate.IntensityBinCenters;
            obj.IntensityHistPlot = replicate.IntensityHistPlot;

            obj.SBAvg = replicate.SBAvg;

            obj.PrimaryIntensityDisplayLimits = replicate.PrimaryIntensityDisplayLimits;
            obj.ReferenceIntensityDisplayLimits = replicate.ReferenceIntensityDisplayLimits;

            obj.CurrentObjectIdx = replicate.CurrentObjectIdx;

            for i = 1:length(replicate.Object) % for each detected object
                % create an instance of PODSObject
                obj.Object(i) = PODSObject.loadobj(replicate.Object(i));
                obj.Object(i).Parent = obj;
            end
        end
    end
end