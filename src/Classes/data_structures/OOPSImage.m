classdef OOPSImage < handle
    
    % normal properties
    properties
%% Parent/Child

        % handle to the OOPSGroup to which this OOPSImage belongs
        Parent OOPSGroup

        % array of handles to the objects detected for this OOPSImage
        Object OOPSObject
        
%% Input Image Properties
        
        % file name of the original input image
        rawFPMFileName (1,:) char

        % shortened file name (no path)
        rawFPMShortName (1,:) char

        % full name (path and extension)
        rawFPMFullName (1,:) char

        % width of the image (number of columns in the image matrix)
        Width (1,1) double

        % height of the image (number of the rows in this image)
        Height (1,1) double

        % real-world size of the pixels of the raw input data
        rawFPMPixelSize (1,1) double

        % class/type of the raw input data ('uint8','uint16',etc)
        rawFPMClass (1,:) char

        % intensity range of the raw input data [low high] (based on class)
        rawFPMRange (1,2) double

        % file type (extension) of the raw input data
        rawFPMFileType (1,:) char

        % raw input stack, size = [Height,Width,4] variable types depending on user input
        rawFPMStack (:,:,4)

        % average of the raw input stack, size = [Height,Width] double
        rawFPMAverage (:,:) double

        % flat-field corrected stack, size = [Height,Width,4]
        ffcFPMStack (:,:,4) double

        % average of the flat-field corrected stack, size = [Height,Width]
        ffcFPMAverage (:,:) double

%% Status Tracking    

        FilesLoaded (1,1) logical = false
        FFCDone (1,1) logical = false
        MaskDone (1,1) logical = false
        OFDone (1,1) logical = false
        ObjectDetectionDone (1,1) logical = false
        LocalSBDone (1,1) logical = false
        ReferenceImageLoaded (1,1) logical = false
        
%% Masking      

        % image mask
        bw (:,:) logical
        
        % label matrix that defines the objects
        L (:,:) double

        % whether the mask intensity threshold has been manually adjusted
        ThresholdAdjusted (1,1) logical = false

        % the intensity threshold used to generate the mask (only for certain mask types)
        level (1,1) double
        
        % masking steps
        I (:,:) double
        EnhancedImg (:,:) double

        % the type of mask applied to this image ('Default', 'Custom')
        MaskType (1,:) char = 'Default'

        % the name of the mask applied to this image (various)
        MaskName (1,:) char = 'Legacy'

        % handle to the custom mask scheme (if one was used)
        CustomScheme CustomMask = CustomMask.empty()
        
        % mask threshold adjustment (for display purposes)
        IntensityBinCenters
        IntensityHistPlot
        
%% Object Data        
        % objects
        CurrentObjectIdx (1,1) uint16 % i.e. no more than 65535 objects per group
        
%% Reference Image

        rawReferenceImage (:,:)
        ReferenceImage (:,:) double
        ReferenceImageEnhanced double
        rawReferenceClass (1,:) char
        rawReferenceFileName (1,:) char
        rawReferenceFullName (1,:) char
        rawReferenceShortName (1,:) char
        rawReferenceFileType (1,:) char
        
%% Output Images

        AzimuthImage (:,:) double
        OF_image (:,:) double

%% Output Values        
        
        % output values
        SBAvg double
        
%% Intensity display limits

        PrimaryIntensityDisplayLimits (1,2) double = [0 1];
        ReferenceIntensityDisplayLimits (1,2) double = [0 1];
 
    end
    
    % dependent properties (not stored in memory, calculated each time they are retrieved)
    properties (Dependent = true)
        
        % flat-field corrected intensity stack, normalized to the max in the 3rd dimension
        ffcFPMPixelNorm

        % OF image in RGB format
        OFImageRGB

        % OF image with mask applied | masked pixels = 0
        MaskedOFImage

        % OF image in RGB format with mask applied | masked pixels = [0 0 0] (black)
        MaskedOFImageRGB

        % OF-intensity overlay in RGB format, unscaled OF
        OFIntensityOverlayRGB

        % OF-intensity overlay in RGB format, with OF scaled to image maximum
        ScaledOFIntensityOverlayRGB

        % azimuth image in RGB format
        AzimuthRGB

        % masked azimuth image in RGB format | masked pixels = [0 0 0] (black)
        MaskedAzimuthRGB

        % Azimuth-intensity-OF HSV image in RGB format
        AzimuthOFIntensityHSV

        % RGB format mask for saving
        MaskRGBImage

        % RGB label image showing the mask colored by object label
        ObjectLabelImageRGB

        % struct() of morphological properties returned by regionprops(), see get() method for full list
        ObjectProperties struct

        % 4-connected object boundaries
        ObjectBoundaries4

        % 8-connected object boundaries
        ObjectBoundaries8
        
        % cell array of the names of all of the objects in this OOPSImage
        ObjectNames cell
        
        % flat-field corrected image stack, normalized to the maximum value among all pixels in the stack
        ffcFPMStack_normalizedbystack

        % raw image stack, normalized to the maximum value among all pixels in the stack
        rawFPMStack_normalizedbystack
        
        % number of objects detected in this OOPSImage
        nObjects (1,1) uint16
        
        % currently selected object in this OOPSImage
        CurrentObject (1,1) OOPSObject
        
        % image dimensions as a char array for display purposes: 'dim1xdim2'
        Dimensions (1,:) char
        
        % 2-element vector describing the limits of the image in real-world coordinates
        RealWorldLimits (1,2) double        
        
        % average OF among all objects
        OFAvg (1,1) double

        % maximum OF among all objects
        OFMax (1,1) double

        % minimum OF among all objects
        OFMin (1,1) double

        % list of pixel OFs for all of the pixels in the image mask
        OFList (:,1) double

        % various filtered output
        bw_filt
        FilteredOFAvg

        % index of this image in [obj.Parent.Replicate()]
        SelfIdx (1,1)

        % title of the threshold adjustment panel in the GUI
        ThreshPanelTitle (1,:) char

        % name of the threshold statistic being adjusted, depends on MaskType/MaskName
        ThreshStatisticName (1,:) char

        % whether or not manual image thresholding is enabled, depends on MaskType/MaskName
        ManualThreshEnabled (1,1) logical

        % handle to the OOPSSettings object, shared across the entire data structure
        Settings (1,1) OOPSSettings

        % table used to build the image summary uitable shown in the GUI
        ImageSummaryDisplayTable

        % 1 x nLabels array of the number of objects with each label in this image
        labelCounts (1,:) double
    end
    
    methods
        
        % constructor
        function obj = OOPSImage(Group)
            obj.Parent = Group;
            
            % image name (minus path and file extension)
            obj.rawFPMShortName = '';
            
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
        
        % destructor
        function delete(obj)
            % delete obj.Object first
            obj.deleteObjects();
            % then delete this object
            delete(obj);
        end

        % saveobj() method
        function replicate = saveobj(obj)

            replicate.rawFPMFileName = obj.rawFPMFileName;
            replicate.rawFPMShortName = obj.rawFPMShortName;
            replicate.rawFPMFullName = obj.rawFPMFullName;
            replicate.Width = obj.Width;
            replicate.Height = obj.Height;

            % status tracking
            replicate.FilesLoaded = obj.FilesLoaded;
            replicate.FFCDone = obj.FFCDone;
            replicate.MaskDone = obj.MaskDone;
            replicate.OFDone = obj.OFDone;
            replicate.ObjectDetectionDone = obj.ObjectDetectionDone;
            replicate.LocalSBDone = obj.LocalSBDone;
            replicate.ReferenceImageLoaded = obj.ReferenceImageLoaded;

            % image mask
            replicate.bw = sparse(obj.bw);

            % testing below
            replicate.L = sparse(obj.L);

            replicate.ThresholdAdjusted = obj.ThresholdAdjusted; 
            replicate.level = obj.level;

            replicate.EnhancedImg = obj.EnhancedImg;

            replicate.MaskName = obj.MaskName;

            % testing below
            replicate.MaskType = obj.MaskType;
            % end testing

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

        % get the index of this OOPSImage in [obj.Parent.Replicate(:)]
        function SelfIdx = get.SelfIdx(obj)
            SelfIdx = find(obj.Parent.Replicate==obj);
        end

%% settings

        function updateMaskSchemes(obj)
            if strcmp(obj.MaskType,'CustomScheme')
                % store a handle to the custom mask scheme, indicated by obj.MaskName
                obj.CustomScheme = obj.Settings.CustomSchemes(ismember(obj.Settings.SchemeNames,obj.MaskName));
                % make sure the scheme is not storing any image data
                obj.CustomScheme.ClearImageData();
            end
        end

        % dependent 'get' method for project settings so we do not store multiple copies
        function Settings = get.Settings(obj)
            try
                Settings = obj.Parent.Settings;
            catch
                Settings = OOPSSettings.empty();
            end
        end

%% processing methods (corrections, FPM stats, local S/B)

        % performs flat field correction for 1 OOPSImage
        function FlatFieldCorrection(obj)

            rawFPMStackDouble = im2double(obj.rawFPMStack) .* obj.rawFPMRange(2);

            % preallocate matrix
            obj.ffcFPMStack = zeros(obj.Height,obj.Width,4);
            % divide each raw data image by the corresponding flatfield image
            for i = 1:4
                obj.ffcFPMStack(:,:,i) = rawFPMStackDouble(:,:,i)./obj.Parent.FFC_cal_norm(:,:,i);
            end
            % average FFC intensity
            obj.ffcFPMAverage = mean(obj.ffcFPMStack,3);
            % normalized average FFC intensity (normalized to max)
            obj.I = obj.ffcFPMAverage./max(max(obj.ffcFPMAverage));
            % done with FFC
            obj.FFCDone = true;
        end

        function BuildMask(obj)

            switch obj.Settings.MaskType

                case 'Default'

                    switch obj.Settings.MaskName

                        case 'Legacy'
                            minimumArea = 10;

                            % use disk-shaped structuring element to calculate BG
                            BGImg = imopen(obj.I,strel('disk',obj.Settings.SESize,obj.Settings.SELines));
                            % subtract BG
                            BGSubtractedImg = obj.I - BGImg;
                            % median filter BG-subtracted image
                            obj.EnhancedImg = medfilt2(BGSubtractedImg);
                            % scale so that max intensity is 1
                            obj.EnhancedImg = obj.EnhancedImg./max(max(obj.EnhancedImg));
                            % initial threshold guess using graythresh() (Otsu's method)
                            [obj.level,~] = graythresh(obj.EnhancedImg);
                            %% Build mask
                            tempObjects = 500;
                            notfirst = false;
                            % Set the max nObjects to 500 by increasing the threshold until nObjects <= 500
                            while tempObjects >= 500
                                % on loop iterations 2:n, double the threshold until nObjects < 500
                                if notfirst
                                    obj.level = obj.level*2;
                                    %UpdateLog3(source,[chartab,chartab,'Too many objects, adjusting thresh and trying again...'],'append');
                                end
                                notfirst = true;
                                % binarize median-filtered image at level determined above
                                obj.bw = sparse(imbinarize(obj.EnhancedImg,obj.level));
                                % set 10 border px on all sides to 0, this is to speed up local BG
                                % detection later on
                                obj.bw = ClearImageBorder(obj.bw,10);
                                % remove small objects
                                CC = bwconncomp(full(obj.bw),4);
                                S = regionprops(CC, 'Area');
                                labelMatrix = labelmatrix(CC);
                                obj.bw = sparse(ismember(labelMatrix, find([S.Area] >= minimumArea)));
                                clear CC S L
                                % generate new label matrix
                                obj.L = sparse(bwlabel(full(obj.bw),4));
                                % get nObjects from label matrix
                                tempObjects = max(max(full(obj.L)));
                            end
                            % detect objects from the mask
                            obj.DetectObjects();
                            % indicates mask was generated automatically
                            obj.ThresholdAdjusted = false;
                            % a mask exists for this replicate
                            obj.MaskDone = true;
                            % store the type/name of the mask used
                            obj.MaskName = obj.Settings.MaskName;
                            obj.MaskType = obj.Settings.MaskType;

                        case 'Filament'

                            % enhance the contrast of fibrous structures
                            C = maxhessiannorm(obj.I,4);
                            Ifiber = fibermetric(obj.I,4,'StructureSensitivity',0.5*C);

                            % preallocate superopen images
                            I_superopen = zeros([size(Ifiber), 12],'like',Ifiber);
                            % create array of phi values
                            phiValues = reshape(1:180,15,12);
                            % do 12 independent super openings in a parallel loop
                            parfor phiIdx = 1:12
                                % get the phi values
                                phis = phiValues(:,phiIdx);
                                % compute the super opening for each set of phi
                                for idx = 1:15
                                    I_superopen(:,:,phiIdx) = max(I_superopen(:,:,phiIdx),imopen(Ifiber,strel('line',40,phis(idx))))
                                end
                            end
                            % get the overall max
                            I_superopen = max(I_superopen,[],3);

                            obj.EnhancedImg = I_superopen;

                            % clear a 10 px wide region around the image border
                            temp = ClearImageBorder(I_superopen,10);

                            %% Detect edges
                            IEdges = edge(temp,'zerocross',0);
                            % mask is the edge pixels
                            obj.bw = sparse(IEdges);

                            % build 8-connected label matrix
                            obj.L = sparse(bwlabel(full(obj.bw),8));

                            % fill in outlines and recreate mask
                            bwtemp = zeros(size(obj.bw));
                            bwempty = zeros(size(obj.bw));
                            props = regionprops(full(obj.L),full(obj.bw),...
                                {'FilledImage',...
                                'SubarrayIdx'});
                            for obj_idx = 1:max(max(full(obj.L)))
                                bwempty(props(obj_idx).SubarrayIdx{:}) = props(obj_idx).FilledImage;
                                bwtemp = bwtemp | bwempty;
                                bwempty(:) = 0;
                            end

                            obj.bw = sparse(bwtemp);
                            %% end fill

                            % remove any "nearly" h-connected pixels (and the h-connected ones)
                            obj.bw = sparse(quasihbreak(full(obj.bw)));

                            % NOTE: connectivity changed from 8 to 4, make sure it didn't mess anything up
                            % remove small or rounded objects
                            CC = bwconncomp(full(obj.bw),4);
                            S = regionprops(CC, 'Area','Eccentricity','Circularity');
                            labelMatrix = labelmatrix(CC);
                            obj.bw = sparse(ismember(labelMatrix, find([S.Area] >= 5 & ...
                                [S.Eccentricity] > 0.5 & ...
                                [S.Circularity] < 0.5)));

                            % testing below
                            % remove any pixels that have a diagonal 8-connection
                            % this is very useful and not built into matlab, consider writing separate function
                            % fill in gaps to remove diagonally connected pixels, keep only the pixels we added
                            diagFill = bwmorph(full(obj.bw),'diag',1)-full(obj.bw);
                            % now get an image with just the pixels that were originally connected
                            diagFill = bwmorph(diagFill,'diag',1)-diagFill;
                            % set those pixels to 0
                            obj.bw(diagFill==1) = 0;
                            % end testing

                            % label individual branches (this has to be the last step if we want individually labeled branches)
                            [~,obj.L] = labelBranches(full(obj.bw));

                            %% BUILD NEW OBJECTS
                            % detect objects from the mask
                            obj.DetectObjects();
                            % indicates mask was generated automatically
                            obj.ThresholdAdjusted = false;
                            % a mask exists for this replicate
                            obj.MaskDone = true;
                            % store the name of the mask used
                            obj.MaskName = obj.Settings.MaskName;
                            obj.MaskType = obj.Settings.MaskType;
                        case 'Adaptive'
                            % use disk-shaped structuring element to calculate BG
                            BGImg = imopen(obj.I,strel('disk',obj.Settings.SESize,obj.Settings.SELines));
                            % subtract BG
                            BGSubtractedImg = obj.I - BGImg;
                            % median filter BG-subtracted image
                            obj.EnhancedImg = medfilt2(BGSubtractedImg);
                            % normalize to max
                            obj.EnhancedImg = obj.EnhancedImg./max(max(obj.EnhancedImg));

                            % GUESS THRESHOLD WITH OTSU'S METHOD
                            [obj.level,~] = graythresh(obj.I);

                            %% Build mask
                            obj.bw = sparse(imbinarize(obj.I,adaptthresh(obj.I,obj.level,'Statistic','Gaussian','NeighborhoodSize',3)));

                            % CLEAR 10 PX BORDER
                            obj.bw = ClearImageBorder(obj.bw,10);

                            % FILTER OBJECTS WITH AREA < 10 PX
                            CC = bwconncomp(full(obj.bw),4);
                            S = regionprops(CC, 'Area');
                            labelMatrix = labelmatrix(CC);
                            obj.bw = sparse(ismember(labelMatrix, find([S.Area] >=10)));
                            clear CC S L

                            % BUILD 4-CONNECTED LABEL MATRIX
                            obj.L = sparse(bwlabel(full(obj.bw),4));

                            %% BUILD NEW OBJECTS
                            % ...so we can detect the new ones (requires bw and L to be computed previously)
                            obj.DetectObjects();
                            % indicates mask was generated automatically
                            obj.ThresholdAdjusted = 0;
                            % a mask exists for this replicate
                            obj.MaskDone = 1;
                            % store the name of the mask used
                            obj.MaskName = obj.Settings.MaskName;
                            obj.MaskType = obj.Settings.MaskType;
                    end

                case 'CustomScheme'

                    % get the active custom scheme
                    customScheme = obj.Settings.ActiveCustomScheme;
                    % make sure no residual image data stored in scheme (CustomMask object)
                    customScheme.ClearImageData();
                    % set obj.I as the starting image of the scheme
                    customScheme.StartingImage = obj.I;
                    % execute the scheme
                    customScheme.Execute();
                    % get the final output image (should be a logical mask image)
                    obj.bw = sparse(customScheme.Images(end).ImageData);



                    if ismember(customScheme.ThreshType,{'Otsu','Adaptive'})
                        % store the enhanced grayscale image (from which the mask is built)
                        obj.EnhancedImg = customScheme.EnhancedImg;

                        switch customScheme.ThreshType
                            case 'Otsu'
                                obj.level = graythresh(obj.EnhancedImg);
                            case 'Adaptive'
                                obj.level = customScheme.Operations(customScheme.ThreshStepIdx).ParamsMap('Sensitivity');
                        end

                    end

                    % testing below, various adjustments to the custom mask
                    % fill in gaps to remove diagonally connected pixels, keep only the pixels we added
                    diagFill = bwmorph(full(obj.bw),'diag',1)-full(obj.bw);
                    % now get an image with just the pixels that were originally connected
                    diagFill = bwmorph(diagFill,'diag',1)-diagFill;
                    % set those pixels to 0
                    obj.bw(diagFill==1) = 0;


                    obj.bw = sparse(ClearImageBorder(full(obj.bw),10));
                    % end testing


                    % % use the mask to build the label matrix
                    % cImage.L = sparse(bwlabel(full(cImage.bw),4));


                    % label individual branches
                    [~,obj.L] = labelBranches(full(obj.bw));

                    %% BUILD NEW OBJECTS
                    % ...so we can detect the new ones (requires bw and L to be computed previously)
                    obj.DetectObjects();
                    % indicates mask was generated automatically
                    obj.ThresholdAdjusted = 0;
                    % a mask exists for this replicate
                    obj.MaskDone = 1;
                    % store the name of the mask used
                    obj.MaskName = obj.Settings.MaskName;
                    obj.MaskType = obj.Settings.MaskType;

                    % clear the data once more
                    customScheme.ClearImageData();
                    % store a handle to the custom scheme
                    obj.CustomScheme = customScheme;
            end

        end

        % calculate pixel-by-pixel OF and azimuth for this image
        function FindOrderFactor(obj)
            % remember to remove comment below!
            % get the pixel-normalized, flat-field corrected intensity stack
            pixelNorm = obj.ffcFPMPixelNorm;

            %% testing only below!
            % anisotropy instead of OF
            % a = obj.ffcFPMStack(:,:,1) - obj.ffcFPMStack(:,:,3);
            % b = obj.ffcFPMStack(:,:,2) - obj.ffcFPMStack(:,:,4);
            % c = sum(obj.ffcFPMStack,3);
            % obj.OF_image = hypot(a,b)./c;
            %% testing only above!

            % orthogonal polarization difference components
            a = pixelNorm(:,:,1) - pixelNorm(:,:,3);
            b = pixelNorm(:,:,2) - pixelNorm(:,:,4);
            % find Order Factor
            obj.OF_image = zeros(size(pixelNorm(:,:,1)));
            obj.OF_image(:) = sqrt(a(:).^2+b(:).^2);
            % find azimuth image
            obj.AzimuthImage = zeros(size(pixelNorm(:,:,1)));
            % WARNING: Output is in radians! Counterclockwise with respect to the horizontal direction in the image
            obj.AzimuthImage(:) = (1/2).*atan2(b(:),a(:));
            % update completion status
            obj.OFDone = true;
        end

        % detect local S/B ratio for each object in this OOPSImage
        function obj = FindLocalSB(obj)

            % subfunction that returns linear idxs (w.r.t. full image) to buffer and BG regions for an object
            function [bufferIdxs, BGIdxs] = getBufferAndBGLists(I,BBox,adjustment,fullSize)
                % dilate to form the buffer
                objectBuffer = imdilate(I,ones(7));
                % dilate further to form the BG
                objectBG = imdilate(objectBuffer,ones(5));
                % remove non-BG pixels
                objectBG(objectBuffer) = 0;
                % remove non-buffer pixels
                objectBuffer(I) = 0;
                % get row and column coordinates of the buffer pixels
                [bufferR,bufferC] = find(objectBuffer);
                bufferCoords = [bufferR,bufferC] + BBox([2 1]) - 0.5 - adjustment;
                % get linear idxs of those pixels
                bufferIdxs = sub2ind(fullSize,bufferCoords(:,1),bufferCoords(:,2));
                % get row and column coordinates of the BG pixels
                [BGR,BGC] = find(objectBG);
                BGCoords = [BGR,BGC] + BBox([2 1]) - 0.5 - adjustment;
                % get linear idxs of those pixels
                BGIdxs = sub2ind(fullSize,BGCoords(:,1),BGCoords(:,2));
            end

            % can't detect local S/B until we detect the objects!
            if obj.ObjectDetectionDone

                % get nObjects x 1 cell array of padded object subimages
                paddedObjectImages = {obj.Object(:).RestrictedPaddedMaskSubImage}';

                % get nObjects x 1 cell of object bounding boxes
                objectBBoxes = {obj.Object(:).BoundingBox}';

                % get nObjects x 1 cell of object padded subarray idx coordinate adjustments
                objectSubIdxAdjusts = {obj.Object(:).paddedSubarrayIdxAdjustment}';

                % get cell array of object buffer and BG coordinates
                [bufferIdxs,BGIdxs] = cellfun(@(I,BBox,adjustment,fullSize) getBufferAndBGLists(I,BBox,adjustment,fullSize),...
                    paddedObjectImages,objectBBoxes,objectSubIdxAdjusts,repmat({[obj.Height obj.Width]},numel(paddedObjectImages),1),'UniformOutput',0);


                [obj.Object(:).BufferIdxList] = deal(bufferIdxs{:});
                [obj.Object(:).BGIdxList] = deal(BGIdxs{:});

                all_object_pixels = obj.bw;
                all_buffer_pixels = cell2mat(bufferIdxs);
                %all_BG_pixels = cell2mat(BGIdxs);

                %% now filter the pixels found above
                % for each object
                for i = 1:obj.nObjects
                    %% first, we remove any buffer pixels that overlap with any object pixels

                    % object pixels are linear idxs from the mask (from all objects)
                    allObjectPixels = find(all_object_pixels);

                    % get the buffer pixels of this object
                    objectBufferPixels = obj.Object(i).BufferIdxList;

                    % keep only the elements in bufferPixels that are not in allObjectPixels
                    newObjectBufferPixels = setdiff(objectBufferPixels,allObjectPixels);

                    %% next, we remove any BG pixels that overlap with any object or buffer pixels

                    % get linear idxs of all buffer pixels
                    allBufferPixels = all_buffer_pixels;

                    % get the BG pixels of this object
                    objBGPixels = obj.Object(i).BGIdxList;

                    % keep only the elements in BGPixels that are not in allBufferPixels
                    newObjectBGPixels = setdiff(objBGPixels,allBufferPixels);

                    % now keep only the elements in newObjectPixels that are not in allObjectPixels
                    newObjectBGPixels2 = setdiff(newObjectBGPixels,allObjectPixels);


                    %% "BUG" IDENTIFIED HERE: If there are too many objects within a small region, code may fail to identify
                    % any BG or buffer pixels. In that case new_buffer and/or new_BG will be empty. Still need to
                    % implement a fix for this... (maybe delete the object then re-index if no BG pxs found?)
                    % however, this is a very rare bug that only causes issues in cases of very low S/N, in which
                    % DetectObjects() labels most of the BG pixels as objects
                    % update buffer and BG pixel lists
                    obj.Object(i).BufferIdxList = newObjectBufferPixels;

                    try
                        obj.Object(i).BGIdxList = newObjectBGPixels2;
                        obj.Object(i).BGAverage = mean(obj.rawFPMAverage(obj.Object(i).BGIdxList));
                    catch
                        obj.Object(i).BGIdxList = [];
                        obj.Object(i).BGAverage = NaN;
                    end

                    % calculate signal and BG levels
                    obj.Object(i).SignalAverage = mean(obj.rawFPMAverage(obj.Object(i).PixelIdxList));
                    obj.Object(i).SBRatio = obj.Object(i).SignalAverage / obj.Object(i).BGAverage;

                end
                % indicate that Local S/B calculation has been one for this image
                obj.LocalSBDone = true;
            else
                error('Cannot calculate local S/B until objects are detected');
            end

        end




%% segmentation, object construction, and basic object feature extraction

        % detects objects in this OOPSImage
        function DetectObjects(obj)
            % start by deleting any currently existing objects
            obj.deleteObjects();

            % get object properties struct
            props = obj.ObjectProperties;

            if isempty(props) % if no objects
                return % then stop here
            else
                % get default label from settings object
                DefaultLabel = obj.Settings.ObjectLabels(1);

                for i = 1:length(props) % for each detected object
                   % create an instance of OOPSObject
                   obj.Object(i) = OOPSObject(props(i,1),...
                       obj,...
                       DefaultLabel);
                end
            end
            
            % update some status tracking variables
            obj.ObjectDetectionDone = true;
            obj.CurrentObjectIdx = 1;
            obj.LocalSBDone = false;
            
        end % end of DetectObjects
        







        % delete all objects in this OOPSImage
        function deleteObjects(obj)
            % collect and delete the objects in this image
            Objects = obj.Object;
            delete(Objects);
            % clear the placeholders
            clear Objects
            % reinitialize the obj.Object vector
            obj.Object = OOPSObject.empty();
            % % delete again? CHECK THIS
            % delete(obj.Object);
        end

        % delete seleted objects from one OOPSImage
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
            
            % delete the bad OOPSObject objects
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

        end

        % delete objects with a specific label
        function DeleteObjectsByLabel(obj,Label)
            
            % get handles to all objects in this image
            AllObjects = obj.Object;
            % just the bad objects
            Bad = AllObjects([AllObjects.Label]==Label);
            % just the good objects
            Good = AllObjects([AllObjects.Label]~=Label);
            % replace the Object array of this image with only the ones we are keeping
            obj.Object = Good;
            % in case current object is greater than the total # of objects
            if obj.CurrentObjectIdx > obj.nObjects
                % select the last object in the list
                obj.CurrentObjectIdx = obj.nObjects;
            end
            % delete the bad OOPSObject objects
            % set their pixel idxs to 0 in the mask
            for i = 1:length(Bad)
                obj.bw(Bad(i).PixelIdxList) = 0;
                delete(Bad(i));
            end
            % clear Bad array
            clear Bad

            % make new label matrix
            obj.L(:) = 0;
            for i = 1:numel(obj.Object)
                obj.L(obj.Object(i).PixelIdxList) = obj.Object(i).SelfIdx;
            end


        end
        
        % apply OOPSLabel:Label to all selected objects in this OOPSImage
        function LabelSelectedObjects(obj,Label)
            % find indices of currently selected objects
            Selected = find([obj.Object.Selected]);
            % apply the new label to those objects
            [obj.Object(Selected).Label] = deal(Label);
        end
        
        % clear selection status of all objects in this image
        function ClearSelection(obj)
            [obj.Object.Selected] = deal(false);
        end
        
        % return all objects in this OOPSImage with the OOPSLabel:Label
        function Objects = getObjectsByLabel(obj,Label)
            % preallocate empty array of objects
            Objects = OOPSObject.empty();
            % as long as we have at least one object
            if obj.nObjects >= 1
                ObjIdxs = find([obj.Object.Label]==Label);
                Objects = obj.Object(ObjIdxs);
            else
                return
            end

        end

        % return object data grouped by the object labels
        function ObjectDataByLabel = GetObjectDataByLabel(obj,Var2Get)
            nLabels = length(obj.Settings.ObjectLabels);
            ObjectDataByLabel = cell(1,nLabels);
            % for each label
            for i = 1:nLabels
                % find idx to all object with that label
                ObjectLabelIdxs = find([obj.Object.Label]==obj.Settings.ObjectLabels(i));
                % add [Var2Get] from those objects to cell i of ObjectDataByLabel
                ObjectDataByLabel{i} = [obj.Object(ObjectLabelIdxs).(Var2Get)];
            end
        end

        % dependent get methods for image size, resolution
        function Dimensions = get.Dimensions(obj)
            Dimensions = [num2str(obj.Height),'x',num2str(obj.Width)];
        end
        
        function RealWorldLimits = get.RealWorldLimits(obj)
            RealWorldLimits = [0 obj.rawFPMPixelSize*obj.Width];
        end

%% dependent get methods for various display/processing options specific to this image

        function ThreshPanelTitle = get.ThreshPanelTitle(obj)
            switch obj.MaskType
                case 'Default'
                    switch obj.MaskName
                        case 'Legacy'
                            ThreshPanelTitle = 'Adjust threshold';
                        case 'Adaptive'
                            ThreshPanelTitle = 'Adjust adaptive threshold sensitivity';
                        otherwise
                            ThreshPanelTitle = 'Manual thresholding unavailable for this masking scheme';
                    end
                case 'CustomScheme'
                    customScheme = obj.CustomScheme;
                    switch customScheme.ThreshType
                        case 'Otsu'
                            ThreshPanelTitle = 'Adjust threshold';
                        case 'Adaptive'
                            ThreshPanelTitle = 'Adjust adaptive threshold sensitivity';
                        otherwise
                            ThreshPanelTitle = 'Manual thresholding unavailable for this masking scheme';
                    end
            end
        end

        function ThreshStatisticName = get.ThreshStatisticName(obj)
            switch obj.MaskType
                case 'Default'
                    switch obj.MaskName
                        case 'Legacy'
                            ThreshStatisticName = 'Threshold';
                        case 'Adaptive'
                            ThreshStatisticName = 'Adaptive threshold sensitivity';
                        otherwise
                            ThreshStatisticName = false;
                    end
                case 'CustomScheme'
                    customScheme = obj.CustomScheme;
                    switch customScheme.ThreshType
                        case 'Otsu'
                            ThreshStatisticName = 'Threshold';
                        case 'Adaptive'
                            ThreshStatisticName = 'Adaptive threshold sensitivity';
                        otherwise
                            ThreshStatisticName = false;
                    end
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
                        otherwise
                            ManualThreshEnabled = false;
                    end
                case 'CustomScheme'
                    customScheme = obj.CustomScheme;
                    switch customScheme.ThreshType
                        case 'Otsu'
                            ManualThreshEnabled = true;
                        case 'Adaptive'
                            ManualThreshEnabled = true;
                        otherwise
                            ManualThreshEnabled = false;
                    end
            end
        end

        function ImageSummaryDisplayTable = get.ImageSummaryDisplayTable(obj)

            varNames = [...
                "Name",...
                "Dimensions",...
                "Input image class",...
                "Pixel size",...
                "Mask threshold",...
                "Threshold adjusted",...
                "Number of objects",...
                "Mask name",...
                "Mean pixel OF",...
                "Mean pixel OF (filtered)",...
                "Files loaded",...
                "FFC performed",...
                "Mask generated",...
                "OF/azimuth calculated",...
                "Objects detected",...
                "Local S/B calculated"];

            ImageSummaryDisplayTable = table(...
                {obj.rawFPMShortName},...
                {obj.Dimensions},...
                {obj.rawFPMClass},...
                {obj.rawFPMPixelSize},...
                {obj.level},...
                {Logical2String(obj.ThresholdAdjusted)},...
                {obj.nObjects},...
                {obj.MaskName},...
                {obj.OFAvg},...
                {obj.FilteredOFAvg},...
                {Logical2String(obj.FilesLoaded)},...
                {Logical2String(obj.FFCDone)},...
                {Logical2String(obj.MaskDone)},...
                {Logical2String(obj.OFDone)},...
                {Logical2String(obj.ObjectDetectionDone)},...
                {Logical2String(obj.LocalSBDone)},...
                'VariableNames',varNames,...
                'RowNames',"Image");

            ImageSummaryDisplayTable = rows2vars(ImageSummaryDisplayTable,"VariableNamingRule","preserve");

            ImageSummaryDisplayTable.Properties.RowNames = varNames;

        end

%% RGB output images

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
            AzimuthData = obj.AzimuthImage;
            % values originally in [-pi/2 pi/2], adjust to fall in [0 pi]
            AzimuthData(AzimuthData<0) = AzimuthData(AzimuthData<0)+pi;
            % scale values to [0 1]
            AzimuthData = AzimuthData./pi;
            % convert to uint8 then to RGB
            AzimuthRGB = ind2rgb(im2uint8(AzimuthData),obj.Settings.AzimuthColormap);
        end

        function MaskedAzimuthRGB = get.MaskedAzimuthRGB(obj)
            MaskedAzimuthRGB = MaskRGB(obj.AzimuthRGB,obj.bw);
        end

        function AzimuthOFIntensityHSV = get.AzimuthOFIntensityHSV(obj)
            % get 'V' data (intensity image)
            OverlayIntensity = obj.I;

            % get 'H' data (azimuth image)
            AzimuthData = obj.AzimuthImage;
            % values originally in [-pi/2 pi/2], adjust to fall in [0 pi]
            AzimuthData(AzimuthData<0) = AzimuthData(AzimuthData<0)+pi;
            % scale values to [0 1]
            AzimuthData = AzimuthData./pi;

            % get 'S' data (scaled order factor image)
            OF = obj.OF_image;
            OF = OF./max(max(OF));

            % combine to make HSV image (in RGB format)
            AzimuthOFIntensityHSV = makeHSVSpecial(AzimuthData,OF,OverlayIntensity);
        end

        function ScaledOFIntensityOverlayRGB = get.ScaledOFIntensityOverlayRGB(obj)
            % get the average intensity image to use as an opacity mask
            OverlayIntensity = obj.I;
            % get the raw OF image
            OF = obj.OF_image;
            % get the maximum OF in the image
            maxOF = max(max(OF));
            % now get the scaled OF-intensity RGB overlay
            ScaledOFIntensityOverlayRGB = ...
                MaskRGB(ind2rgb(im2uint8(OF./maxOF),obj.Settings.OrderFactorColormap),OverlayIntensity);
        end

        function OFIntensityOverlayRGB = get.OFIntensityOverlayRGB(obj)
            % get the average intensity image to use as an opacity mask
            OverlayIntensity = obj.I;
            % get the raw OF image
            OF = obj.OF_image;
            % now get the scaled OF-intensity RGB overlay
            OFIntensityOverlayRGB = ...
                MaskRGB(ind2rgb(im2uint8(OF),obj.Settings.OrderFactorColormap),OverlayIntensity);
        end

        function MaskRGBImage = get.MaskRGBImage(obj)
            MaskRGBImage = ind2rgb(im2uint8(full(obj.bw)),gray);
        end

        function ObjectLabelImageRGB = get.ObjectLabelImageRGB(obj)
            % preallocate 2D label idx image
            ObjectLabelImage = zeros(size(obj.bw));

            % for each object in the image, set its pixels = the idx of its label
            for objIdx = 1:obj.nObjects
                ObjectLabelImage(obj.Object(objIdx).PixelIdxList) = obj.Object(objIdx).LabelIdx;
            end
            % the BG color
            zeroColor = [0 0 0];
            % convert the label matrix to an RGB image using the existing label colors
            ObjectLabelImageRGB = label2rgb(ObjectLabelImage,obj.Settings.LabelColors,zeroColor);
        end


%% other dependent 'get' methods

        % get current Object (OOPSObject)
        function CurrentObject = get.CurrentObject(obj)
            try
                CurrentObject = obj.Object(obj.CurrentObjectIdx);
            catch
                CurrentObject = OOPSObject.empty();
            end
        end

        % get ObjectProperties
        function ObjectProperties = get.ObjectProperties(obj)

            % if no objects identified by the label matrix, return empty
            if max(max(obj.L))==0
                ObjectProperties = [];
                return
            end

            % get morphological properties from regionprops()
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

            %% get cell arrays of some properties (which we will use to calculate more properties)

            % get fieldnames of the ObjectProperties struct
            fnames = fieldnames(ObjectProperties);
            % convert ObjectProperties struct to cell array
            C = struct2cell(ObjectProperties).';
            % get object images (using struct fieldnames to find idx to 'Image' column in cell array)
            ObjectImages = C(:,ismember(fnames,'Image'));
            % get object bounding boxes (using fieldnames to find idx to 'BoundingBox' column in cell array)
            ObjectBBox = C(:,ismember(fnames,'BoundingBox'));
            % get object subarray idxs (using fieldnames to find idx to 'SubarrayIdx' column in cell array)
            ObjectSubarrayIdx = C(:,ismember(fnames,'SubarrayIdx'));
            % get object pixel idx list (using fieldnames to find idx to 'PixelIdxList' column in cell array)
            ObjectPixelIdxList = C(:,ismember(fnames,'PixelIdxList'));


            %% object padded subarray idxs

            % get cell array of padded subarray idxs (padding=5)
            paddedSubarrayIdx = cellfun(@(subidx) padSubarrayIdx(subidx,5),ObjectSubarrayIdx,'UniformOutput',0);
            % deal into ObjectProperties struct
            ObjectProperties(end).paddedSubarrayIdx = [];
            [ObjectProperties(:).paddedSubarrayIdx] = deal(paddedSubarrayIdx{:});

            %% object coordinate padding

            % get cell array of object coordinate adjustments [yShift xShift]
            paddedSubarrayIdxAdjustment = cellfun(@(subidx,paddedsubidx) ...
                [subidx{1,1}(1)-paddedsubidx{1,1}(1) subidx{1,2}(1)-paddedsubidx{1,2}(1)],...
                ObjectSubarrayIdx,paddedSubarrayIdx,'UniformOutput',0);
            % deal into ObjectProperties struct
            ObjectProperties(end).paddedSubarrayIdxAdjustment = [];
            [ObjectProperties(:).paddedSubarrayIdxAdjustment] = deal(paddedSubarrayIdxAdjustment{:});

            %% image to padded object coordinate shifts [yShift xShift]

            imageToPaddedObjectShift = cellfun(@(box,padadjust) -1.*box([2 1]) + 0.5 + padadjust, ObjectBBox, paddedSubarrayIdxAdjustment, 'UniformOutput',0);
            % deal into ObjectProperties struct
            ObjectProperties(end).imageToPaddedObjectShift = [];
            [ObjectProperties(:).imageToPaddedObjectShift] = deal(imageToPaddedObjectShift{:});

            %% object padded pixel idx list

            Isz = size(obj.bw);

            paddedPixelIdxList = cellfun(@(pixelidxlist,coordshift,paddedsubidx) getPaddedPixelIdxList(pixelidxlist,coordshift,paddedsubidx),...
                ObjectPixelIdxList,imageToPaddedObjectShift,paddedSubarrayIdx,...
                'UniformOutput',0);

            function paddedpixelidxlist = getPaddedPixelIdxList(pixelidxlist,coordshift,paddedsubidx)
                [r,c] = ind2sub(Isz,pixelidxlist);
                outSize = [length(paddedsubidx{1,1}) length(paddedsubidx{1,2})];
                paddedpixelidxlist = sub2ind(outSize,r + coordshift(1),c + coordshift(2));
            end

            % deal into ObjectProperties struct
            ObjectProperties(end).paddedPixelIdxList = [];
            [ObjectProperties(:).paddedPixelIdxList] = deal(paddedPixelIdxList{:});


            %% object padded mask images

            paddedSubImage = cellfun(@(paddedsubidx,paddedpixelidxlist) ...
                getPaddedSubImage(paddedsubidx,paddedpixelidxlist),...
                paddedSubarrayIdx,paddedPixelIdxList,'UniformOutput',0);
            % subfuntion to get the padded object subimages
            function paddedsubimage = getPaddedSubImage(paddedsubidx,paddedpixelidxlist)
                paddedsubimage = false([length(paddedsubidx{1,1}) length(paddedsubidx{1,2})]);
                paddedsubimage(paddedpixelidxlist) = true;
            end
            % deal into ObjectProperties struct
            ObjectProperties(end).paddedSubImage = [];
            [ObjectProperties(:).paddedSubImage] = deal(paddedSubImage{:});

            %% object boundaries

            % get boundaries from ObjectImages
            B = cellfun(@(obj_img)bwboundaries(obj_img,8,'noholes','TraceStyle','pixeledge'),ObjectImages,'UniformOutput',0);
            % add bounding box offsets to boundary coordinates from ObjectImages
            % box([2 1]) gives the (y,x) coordinates of the top-left corner of the box
            B = cellfun(@(b,box) bsxfun(@plus,b{1},box([2 1]) - 0.5),B,ObjectBBox,'UniformOutput',0);
            % add object boundaries cell to props struct
            ObjectProperties(end).BWBoundary = [];
            [ObjectProperties(:).BWBoundary] = deal(B{:});


            %% object midlines

            % get the object midline coordinates w.r.t. the padded object subimage
            M = parcellfun(@(obj_img) getObjectMidline(obj_img),paddedSubImage,'UniformOutput',0);
            % add object midline coordinates cell to props struct
            ObjectProperties(end).Midline = [];
            [ObjectProperties(:).Midline] = deal(M{:});

            %% object midline and pixel tangents

            % get a list of tangents for each object midline (one tangent per point in the midline)
            MidlineTangent = cellfun(@(midline) getMidlineTangent(midline), M, 'UniformOutput',0);
            % get a list of tangents for each pixel in the padded object mask image
            pixelMidlineTangentList = parcellfun_multi(@(midline,midlinetangent,paddedsubimage) ...
                getPixelValuesFromCurveValues(midline,midlinetangent,paddedsubimage), ...
                {M,MidlineTangent,paddedSubImage}, ...
                'UniformOutput',0);
            % add object pixelTangentList cell to props struct
            ObjectProperties(end).pixelMidlineTangentList = [];
            [ObjectProperties(:).pixelMidlineTangentList] = deal(pixelMidlineTangentList{:});

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
                AllVertices,...
                AllCData,...
                SelectedFaces,...
                UnselectedFaces...
                ] = getObjectPatchData(obj)

            % get handles to all objects in this image
            AllObjects = obj.Object;

            % get list of unselected objects
            Unselected = AllObjects(~[obj.Object.Selected]);
            % get list of selected objects
            Selected = AllObjects([obj.Object.Selected]);

            totalnObjects = numel(Unselected)+numel(Selected);

            % highest number of boundary vertices among all objects
            AllVerticesMax = 0;

            % total number of boundary vertices among all objects
            AllVerticesSum = 0;

            % for each object
            for cObject = obj.Object
                % % get the number of vertices in the simplified boundary
                % nVertices = size(cObject.SimplifiedBoundary,1);
                
                % get the number of vertices in the boundary
                nVertices = size(cObject.Boundary,1);       
                % determine the total and max number of vertices
                AllVerticesSum = AllVerticesSum + nVertices;
                AllVerticesMax = max(AllVerticesMax,nVertices);
            end

            % initialize unselected faces matrix (each row is a vector of vertex idxs)
            UnselectedFaces = nan(totalnObjects,AllVerticesMax);
            % initialize selected faces matrix (each row is a vector of vertex idxs)
            SelectedFaces = nan(totalnObjects,AllVerticesMax);
            % list of boundary coordinates for all objects
            AllVertices = zeros(AllVerticesSum+totalnObjects,2);
            % object/face counter
            Counter = 0;
            % list of FaceVertexCData for the patch objects we are going to draw
            AllCData = zeros(AllVerticesSum+totalnObjects,3);
            % total number of vertices we have created faces for
            TotalVertices = 0;

            for cObject = obj.Object
                % increment the object/face counter
                Counter = Counter + 1;
                % % get the simplified boundary
                % thisObjectBoundary = cObject.SimplifiedBoundary;
                % get the boundary
                thisObjectBoundary = cObject.Boundary;
                % determine number of vertices
                nvertices = size(thisObjectBoundary,1);
                % obtain vertices idx
                AllVerticesIdx = (TotalVertices+1):(TotalVertices+nvertices);
                % add boundary coordinates to list of vertices
                AllVertices(AllVerticesIdx,:) = [thisObjectBoundary(:,2) thisObjectBoundary(:,1)];
                % add CData for each vertex
                AllCData(AllVerticesIdx,:) = zeros(numel(AllVerticesIdx),3)+cObject.LabelColor;
                % set object faces depending on their selection status
                switch cObject.Selected
                    case true
                        % add vertex idxs to selected faces list
                        SelectedFaces(Counter,1:nvertices) = AllVerticesIdx;
                    case false
                        % add vertex idxs to unselected faces list
                        UnselectedFaces(Counter,1:nvertices) = AllVerticesIdx;
                end
                % increment the total number of vertices
                TotalVertices = TotalVertices + nvertices;
            end
        end

        function [...
                AllVertices,...
                AllCData,...
                SelectedFaces,...
                UnselectedFaces...
                ] = getObjectRectanglePatchData(obj)

            % get handles to all objects in this image
            AllObjects = obj.Object;

            % get list of unselected objects
            Unselected = AllObjects(~[obj.Object.Selected]);
            % get list of selected objects
            Selected = AllObjects([obj.Object.Selected]);

            totalnObjects = numel(Unselected)+numel(Selected);

            % highest number of boundary vertices among all objects
            AllVerticesMax = 0;

            % total number of boundary vertices among all objects
            AllVerticesSum = 0;

            % for each object
            for cObject = obj.Object
                % % get the number of vertices in the simplified boundary
                % nVertices = size(cObject.SimplifiedBoundary,1);
                
                % get the number of vertices in the boundary
                nVertices = 4;       
                % determine the total and max number of vertices
                AllVerticesSum = AllVerticesSum + nVertices;
                AllVerticesMax = max(AllVerticesMax,nVertices);
            end

            % initialize unselected faces matrix (each row is a vector of vertex idxs)
            UnselectedFaces = nan(totalnObjects,AllVerticesMax);
            % initialize selected faces matrix (each row is a vector of vertex idxs)
            SelectedFaces = nan(totalnObjects,AllVerticesMax);
            % list of boundary coordinates for all objects
            AllVertices = zeros(AllVerticesSum+totalnObjects,2);
            % object/face counter
            Counter = 0;
            % list of FaceVertexCData for the patch objects we are going to draw
            AllCData = zeros(AllVerticesSum+totalnObjects,3);
            % total number of vertices we have created faces for
            TotalVertices = 0;

            for cObject = obj.Object
                % increment the object/face counter
                Counter = Counter + 1;
                % % get the simplified boundary
                % thisObjectBoundary = cObject.SimplifiedBoundary;
                % get the boundary
                thisObjectBoundary = cObject.expandedBoundingBoxCoordinates;
                % determine number of vertices
                nvertices = size(thisObjectBoundary,1);
                % obtain vertices idx
                AllVerticesIdx = (TotalVertices+1):(TotalVertices+nvertices);
                % add boundary coordinates to list of vertices
                AllVertices(AllVerticesIdx,:) = thisObjectBoundary;
                % add CData for each vertex
                AllCData(AllVerticesIdx,:) = zeros(numel(AllVerticesIdx),3)+cObject.LabelColor;
                % set object faces depending on their selection status
                switch cObject.Selected
                    case true
                        % add vertex idxs to selected faces list
                        SelectedFaces(Counter,1:nvertices) = AllVerticesIdx;
                    case false
                        % add vertex idxs to unselected faces list
                        UnselectedFaces(Counter,1:nvertices) = AllVerticesIdx;
                end
                % increment the total number of vertices
                TotalVertices = TotalVertices + nvertices;
            end
        end

        % return the number of objects in this OOPSImage
        function nObjects = get.nObjects(obj)
            if isvalid(obj.Object)
                nObjects = length(obj.Object);
            else
                nObjects = 0;
            end
        end

        function labelCounts = get.labelCounts(obj)
            % preallocate our array of label counts, one column per unique label
            labelCounts = zeros(1,obj.Settings.nLabels);
            % for each unique label
            for labelIdx = 1:obj.Settings.nLabels
                % find the number of objects with that label
                labelCounts(1,labelIdx) = numel(find([obj.Object.Label]==obj.Settings.ObjectLabels(labelIdx,1)));
            end
        end
        
%% Normalize Image Stacks

        % get normalized FFC stack
        function ffcFPMStack_normalizedbystack = get.ffcFPMStack_normalizedbystack(obj)
            ffcFPMStack_normalizedbystack = obj.ffcFPMStack./(max(max(max(obj.ffcFPMStack))));
        end
         
        % get normalized raw emission images stack
        function rawFPMStack_normalizedbystack = get.rawFPMStack_normalizedbystack(obj)
            rawDataDouble = im2double(obj.rawFPMStack);
            rawFPMStack_normalizedbystack = rawDataDouble./(max(max(max(rawDataDouble))));
        end

%% dependent 'get' methods for object output values

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

%% dependent 'get' methods for filtered object output values


        function bw_filt = get.bw_filt(obj)
        % returns a mask only containing objects with S/B >= 3
        % this will be expanded to include more customization 
        % of the filters and their values

        % this could be done with a class, 'CutsomFilter', for example
        %   myFilt = CustomFilt('Name','SBRatio','Relationship','>=','Value','3')
        %   filtExpression = ['[obj.Object.',myFilt.Name,']',myFilt.Relationship,myFilt.Value,')'];
        %   FilteredObjects = obj.Object(eval(filtExpression));

            FilteredObjects = obj.Object([obj.Object.SBRatio]>=3);
            PixelIdxList = vertcat(FilteredObjects(:).PixelIdxList);
            bw_filt = false(size(obj.bw));
            bw_filt(PixelIdxList) = true;

        end

        function FilteredOFAvg = get.FilteredOFAvg(obj)
            % average OF of all pixels identified by the mask
            try
                FilteredOFAvg = mean(obj.OF_image(obj.bw_filt));
            catch
                FilteredOFAvg = NaN;
            end
        end

%% dependent 'get' methods for intermediates that do not need to constantly be in memory

        function ffcFPMPixelNorm = get.ffcFPMPixelNorm(obj)
            ffcFPMPixelNorm = obj.ffcFPMStack./max(obj.ffcFPMStack,[],3);
        end


    end

    methods (Static)
        function obj = loadobj(replicate)

            obj = OOPSImage(OOPSGroup.empty());

            % info about the image path and rawFPMFileName
            obj.rawFPMFileName = replicate.rawFPMFileName;
            obj.rawFPMShortName = replicate.rawFPMShortName;
            obj.rawFPMFullName = replicate.rawFPMFullName;

            % split on the '.'
            filenameSplit = strsplit(obj.rawFPMFileName,'.');
            % get the file extension
            obj.rawFPMFileType = filenameSplit{2};

            %% attempt to load the raw data using the saved rawFPMFileName

            disp(['Loading ',obj.rawFPMFullName,'...']);
            % get file data structure
            bfData = bfopen(char(replicate.rawFPMFullName));
            % get the image info (pixel values and filename) from the first element of the bf cell array
            imageInfo = bfData{1,1};
            % get the metadata structure from the fourth element of the bf cell array
            omeMeta = bfData{1,4};
            % try and get the pixel dimensions from the metadata
            try
                obj.rawFPMPixelSize = omeMeta.getPixelsPhysicalSizeX(0).value();
            catch
                warning('Unable to detect pixel size.')
            end
            % get the actual image matrix
            imageData = cell2mat(reshape(imageInfo(1:4,1),1,1,4));
            % determine the class of the input data
            obj.rawFPMClass = class(imageData);
            % get the range of values in the input stack using its class
            obj.rawFPMRange = getrangefromclass(imageData);
            % get image dimensions
            obj.Height = size(imageData,1);
            obj.Width = size(imageData,2);
            % pre-allocate raw data array
            obj.rawFPMStack = zeros(obj.Height,obj.Width,4);
            % add the raw image data to this OOPSImage
            obj.rawFPMStack = imageData;

            %% end raw data loading

            % average the raw data (polarization stack)
            obj.rawFPMAverage = mean(im2double(obj.rawFPMStack),3);

            % status tracking variables
            obj.FilesLoaded = replicate.FilesLoaded;
            obj.FFCDone = replicate.FFCDone;
            obj.MaskDone = replicate.MaskDone;
            obj.OFDone = replicate.OFDone;
            obj.ObjectDetectionDone = replicate.ObjectDetectionDone;
            obj.LocalSBDone = replicate.LocalSBDone;
            obj.ReferenceImageLoaded = replicate.ReferenceImageLoaded;

            obj.bw = replicate.bw;

            try
                obj.L = replicate.L;
            catch
                obj.L = sparse(bwlabel(full(obj.bw),4));
            end

            obj.ThresholdAdjusted = replicate.ThresholdAdjusted; 
            obj.level = replicate.level;

            obj.EnhancedImg = replicate.EnhancedImg;

            obj.MaskName = replicate.MaskName;

            % testing below
            try
                obj.MaskType = replicate.MaskType;
            catch

            end
            % end testing

            obj.IntensityBinCenters = replicate.IntensityBinCenters;
            obj.IntensityHistPlot = replicate.IntensityHistPlot;

            obj.SBAvg = replicate.SBAvg;

            obj.PrimaryIntensityDisplayLimits = replicate.PrimaryIntensityDisplayLimits;
            obj.ReferenceIntensityDisplayLimits = replicate.ReferenceIntensityDisplayLimits;

            obj.CurrentObjectIdx = replicate.CurrentObjectIdx;

            for i = 1:length(replicate.Object) % for each detected object
                % create an instance of OOPSObject
                obj.Object(i) = OOPSObject.loadobj(replicate.Object(i));
                obj.Object(i).Parent = obj;
            end
        end
    end
end