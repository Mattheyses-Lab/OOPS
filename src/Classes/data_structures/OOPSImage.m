classdef OOPSImage < handle & dynamicprops
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------
    
    properties

        % handle to the OOPSGroup to which this OOPSImage belongs
        Parent OOPSGroup
        % column vector of handles to the OOPSObject objects in this OOPSImage
        Object (:,1) OOPSObject
        
%% FPM stack file properties
        
        % file name of the original input image
        rawFPMFileName (1,:) char
        % shortened file name (no path)
        rawFPMShortName (1,:) char
        % full name (path and extension)
        rawFPMFullName (1,:) char
        % number of columns in the image
        Width (1,1) double
        % number of the rows in this image
        Height (1,1) double
        % real-world size of the pixels of the raw input data
        rawFPMPixelSize (1,1) double
        % class/type of the raw input data ('uint8','uint16',etc)
        rawFPMClass (1,:) char
        % intensity range of the raw input data [low high] (based on class)
        rawFPMRange (1,2) double
        % file type (extension) of the raw input data
        rawFPMFileType (1,:) char

%% FPM stack image data

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
        FPMStatsDone (1,1) logical = false
        ObjectDetectionDone (1,1) logical = false
        LocalSBDone (1,1) logical = false
        ReferenceImageLoaded (1,1) logical = false
        MaskImageLoaded (1,1) logical = false
        
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
        % the type of mask applied to this image ('Default', 'CustomScheme')
        MaskType (1,:) char = 'Default'
        % the name of the mask applied to this image (various)
        MaskName (1,:) char = 'Legacy'
        % handle to the custom mask scheme (if one was used)
        CustomScheme CustomMask = CustomMask.empty()
        % mask threshold adjustment (for display purposes)
        IntensityBinCenters
        IntensityHistPlot
        
%% Object data

        % objects
        CurrentObjectIdx (1,1) uint16 % i.e. no more than 65535 objects per group
        
%% Reference image

        rawReferenceImage (:,:)
        ReferenceImage (:,:) double
        ReferenceImageEnhanced double
        rawReferenceClass (1,:) char
        rawReferenceFileName (1,:) char
        rawReferenceFullName (1,:) char
        rawReferenceShortName (1,:) char
        rawReferenceFileType (1,:) char

%% Uploaded mask image

        rawMaskClass (1,:) char
        rawMaskFileName (1,:) char
        rawMaskFullName (1,:) char
        rawMaskShortName (1,:) char
        rawMaskFileType (1,:) char
        
%% Pixelwise FPM output statistics

        AzimuthImage (:,:) double
        OrderImage (:,:) double
        
%% Intensity display limits

        PrimaryIntensityDisplayLimits (1,2) double = [0 1];
        ReferenceIntensityDisplayLimits (1,2) double = [0 1];
        OrderDisplayLimits (1,2) double = [0 1];
 
    end
    
    % dependent properties (not stored in memory, calculated each time they are retrieved)
    properties (Dependent = true)
        
        % min and max average intensity in the same scale as the original input data
        averageIntensityRealLimits

        % flat-field corrected intensity stack, normalized to the max in the 3rd dimension
        ffcFPMPixelNorm

        % Average intensity image scaled to user-defined display limits
        UserScaledAverageIntensityImage
        % Average intensity image scaled to user-defined display limits, RGB format
        UserScaledAverageIntensityImageRGB
        MaxScaledAverageIntensityImageRGB

        ReferenceImageRGB
        UserScaledReferenceImage
        UserScaledReferenceImageRGB
        UserScaledAverageIntensityReferenceCompositeRGB

        % Order image in RGB format
        OrderImageRGB

        % Order image scaled to user-defined display limits
        UserScaledOrderImage
        % Order image scaled to user-defined display limits, RGB format
        UserScaledOrderImageRGB

        % Order image with mask applied | masked pixels = 0
        MaskedOrderImage
        % Order image in RGB format with mask applied | masked pixels = [0 0 0] (black)
        MaskedOrderImageRGB

        % Order image normalized to image maximum
        MaxScaledOrderImage
        % Order image in RGB format, with Order scaled to image maximum
        MaxScaledOrderImageRGB

        % Order-intensity overlay in RGB format, unscaled Order
        OrderIntensityOverlayRGB
        % Order-intensity overlay in RGB format, with Order scaled to image maximum
        MaxScaledOrderIntensityOverlayRGB
        % Order-intensity overlay in RGB format, with Order and intensity scaled according to user
        UserScaledOrderIntensityOverlayRGB


        % azimuth image in RGB format
        AzimuthRGB
        % masked azimuth image in RGB format | masked pixels = [0 0 0] (black)
        MaskedAzimuthRGB
        % Azimuth-intensity-Order HSV image in RGB format
        AzimuthOrderIntensityHSV
        % Azimuth-intensity-Order HSV image in RGB format, with Order and intensity scaled according to user
        UserScaledAzimuthOrderIntensityHSV
        % Azimuth-intensity overlay in RGB format
        AzimuthIntensityOverlayRGB
        % Azimuth-intensity overlay in RGB format, with intensity scaled according to user
        UserScaledAzimuthIntensityOverlayRGB




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
        
        % average Order among all objects
        OrderAvg (1,1) double

        % maximum Order among all objects
        OrderMax (1,1) double

        % minimum Order among all objects
        OrderMin (1,1) double

        % list of pixel Orders for all of the pixels in the image mask
        OrderList (:,1) double

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
            
            
            obj.CurrentObjectIdx = 0;

            % add custom properties
            obj.addCustomStatistics();

        end
        
        % destructor
        function delete(obj)
            % delete obj.Object first
            obj.deleteObjects();
            % then delete this object
            delete(obj);
        end

        % saveobj method
        function replicate = saveobj(obj)

            % status tracking
            replicate.FilesLoaded = obj.FilesLoaded;
            replicate.FFCDone = obj.FFCDone;
            replicate.MaskDone = obj.MaskDone;
            replicate.FPMStatsDone = obj.FPMStatsDone;
            replicate.ObjectDetectionDone = obj.ObjectDetectionDone;
            replicate.LocalSBDone = obj.LocalSBDone;
            replicate.ReferenceImageLoaded = obj.ReferenceImageLoaded;            

            % FPM stack info
            replicate.rawFPMFileName = obj.rawFPMFileName;
            replicate.rawFPMShortName = obj.rawFPMShortName;
            replicate.rawFPMFullName = obj.rawFPMFullName;
            replicate.Width = obj.Width;
            replicate.Height = obj.Height;

            % reference image info
            replicate.rawReferenceFileName = obj.rawReferenceFileName;
            replicate.rawReferenceShortName = obj.rawReferenceShortName;
            replicate.rawReferenceFullName = obj.rawReferenceFullName;

            % image mask
            replicate.bw = sparse(obj.bw);

            % label matrix
            replicate.L = sparse(obj.L);

            % threshold adjusted flag
            replicate.ThresholdAdjusted = obj.ThresholdAdjusted;

            % threshold level
            replicate.level = obj.level;

            replicate.EnhancedImg = obj.EnhancedImg;

            replicate.MaskName = obj.MaskName;

            % testing below
            replicate.MaskType = obj.MaskType;
            % end testing

            replicate.IntensityBinCenters = obj.IntensityBinCenters;
            replicate.IntensityHistPlot = obj.IntensityHistPlot;

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

        % add user-defined custom outputs
        function addCustomStatistics(obj)
            % get the vector of custom statistic objects
            customStatistics = obj.Settings.CustomStatistics;
            % for each custom statistic
            for i = 1:numel(customStatistics)
                % get the statistic
                thisStatistic = customStatistics(i);
                statName = thisStatistic.StatisticName;
                statRange = thisStatistic.StatisticRange;

                % add a dynamic property to obj to hold the image data
                prop = obj.addprop([statName,'Image']);

                % add a dynamic property to obj to hold the display limits
                displayLimitsProp = obj.addprop([statName,'DisplayLimits']);
                % set the default value
                obj.([statName,'DisplayLimits']) = statRange;

                % add a dynamic property to obj to hold the display range
                displayRangeProp = obj.addprop([statName,'DisplayRange']);
                % set the default value
                obj.([statName,'DisplayRange']) = statRange;


                % add a dynamic property to obj to hold the user scaled image
                userScaledImageProp = obj.addprop(['UserScaled',statName,'Image']);
                userScaledImageProp.Dependent = true;
                % set the Get method for this property, pass in the property name so we know how to calculate it
                userScaledImageProp.GetMethod = @(o) getCustomUserScaledImage(o,statName);

                % add a dynamic property to obj to hold the user scaled image
                userScaledIntensityOverlayRGBProp = obj.addprop(['UserScaled',statName,'IntensityOverlayRGB']);
                userScaledIntensityOverlayRGBProp.Dependent = true;
                % set the Get method for this property, pass in the property name so we know how to calculate it
                userScaledIntensityOverlayRGBProp.GetMethod = @(o) getCustomUserScaledIntensityOverlayRGB(o,statName);
            end
        end

        function value = getCustomUserScaledImage(obj,statName)
            % normalize the image data so that values [obj.xDisplayRange(1) obj.xDisplayRange(2)] maps to [0 1]
            % where "x" is the name of the custom statistic
            normalizedImageData = normalizeFromRange(obj.([statName,'Image']),obj.([statName,'DisplayRange']));
            % do the same with the display limits
            normalizedDisplayLimits = normalizeFromRange(obj.([statName,'DisplayLimits']),obj.([statName,'DisplayRange']));
            % adjust the image data (values cannot be interpreted directly unless the display range is [0 1]
            value = imadjust(normalizedImageData,normalizedDisplayLimits,[0 1]);
        end

        function value = getCustomUserScaledIntensityOverlayRGB(obj,statName)
            % get the normalized, user-scaled image data
            imageData = obj.(['UserScaled',statName,'Image']);
            % convert to uint8, then to RGB
            value = MaskRGB(vecind2rgb(im2uint8(imageData),obj.Settings.OrderColormap),obj.UserScaledAverageIntensityImage);
        end


%% retrieve image data

        function averageIntensityRealLimits = get.averageIntensityRealLimits(obj)
            averageIntensityRealLimits = [min(min(obj.ffcFPMAverage)) max(max(obj.ffcFPMAverage))];
        end

        % dependent get methods for image size, resolution
        function Dimensions = get.Dimensions(obj)
            Dimensions = [num2str(obj.Height),'x',num2str(obj.Width)];
        end
        
        function RealWorldLimits = get.RealWorldLimits(obj)
            RealWorldLimits = [0 obj.rawFPMPixelSize*obj.Width];
        end

        % get normalized FFC stack
        function ffcFPMStack_normalizedbystack = get.ffcFPMStack_normalizedbystack(obj)
            ffcFPMStack_normalizedbystack = obj.ffcFPMStack./(max(max(max(obj.ffcFPMStack))));
        end
         
        % get normalized raw emission images stack
        function rawFPMStack_normalizedbystack = get.rawFPMStack_normalizedbystack(obj)
            rawDataDouble = im2double(obj.rawFPMStack);
            rawFPMStack_normalizedbystack = rawDataDouble./(max(max(max(rawDataDouble))));
        end

        function ffcFPMPixelNorm = get.ffcFPMPixelNorm(obj)
            % normalize to total intensity
            ffcFPMPixelNorm = obj.ffcFPMStack./(sum(obj.ffcFPMStack,3)./2);
        end

        function OrderAvg = get.OrderAvg(obj)
            % average Order of all pixels identified by the mask
            try
                OrderAvg = mean(obj.OrderImage(obj.bw));
            catch
                OrderAvg = NaN;
            end
        end
        
        function OrderMax = get.OrderMax(obj)
            % max Order of all pixels identified by the mask
            try
                OrderMax = max(obj.OrderImage(obj.bw));
            catch
                OrderMax = NaN;
            end
        end
        
        function OrderMin = get.OrderMin(obj)
            % min Order of all pixels identified by the mask
            try
                OrderMin = min(obj.OrderImage(obj.bw));
            catch
                OrderMin = NaN;
            end
        end
        
        function OrderList = get.OrderList(obj)
            % list of Order in all pixels identified by mask
            try
                OrderList = obj.OrderImage(obj.bw);
            catch
                OrderList = NaN;
            end
        end
%% processing methods (corrections, FPM stats, local S/B)

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
                            BGImg = imopen(obj.I,strel('disk',3,0));
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
                            BGImg = imopen(obj.I,strel('disk',3,0));
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

        function FindFPMStatistics(obj)

            % default order parameter and azimuth

            % edit the lines below if you want to change how the built-in
            % order (obj.OrderImage) and orientation (obj.AzimuthImage) 
            % statistics are calculated. 
            % 
            % Note that the stack "obj.ffcFPMPixelNorm" has already been
            % flat-field corrected and normalized to the total intensity.
            %
            % To perform calculations with the raw FPM stack,
            % use "obj.rawFPMStack" instead. Use im2double to convert
            % pixel values to double before doing any calculations.
            %
            % To perform calculations with the unnormalized,
            % flat-field corrected stack, use "obj.ffcFPMStack".
            %
            % OOPS will always assume the values in obj.AzimuthImage 
            % are measured counterclockwise with respect to the 
            % positive x-axis. Therefore, if your excitation 
            % polarizations are defined in a counterclockwise order, 
            % make sure to adjust how b is calculated accordingly. 

            % pixel-normalized, flat-field corrected intensity stack
            pixelNorm = obj.ffcFPMPixelNorm;
            % orthogonal polarization difference components
            a = pixelNorm(:,:,1) - pixelNorm(:,:,3);
            b = pixelNorm(:,:,2) - pixelNorm(:,:,4);
            % preallocate order and azimuth images
            obj.OrderImage = zeros(size(pixelNorm(:,:,1)));
            obj.AzimuthImage = obj.OrderImage;
            % calculate order | clip output to the range [0,1]
            obj.OrderImage(:) = min(max(hypot(a(:),b(:)),0),1);
            % calculate azimuth | output in radians! CCW w.r.t. the horizontal direction in the image
            obj.AzimuthImage(:) = (0.5).*atan2(b(:),a(:));
            % end built-in statistics

            % custom order statistics
            % get the vector of custom statistic objects
            customStatistics = obj.Settings.CustomStatistics;
            % one or more custom statistics exist
            if ~(isempty(customStatistics))
                % for each custom statistic
                for i = 1:numel(customStatistics)
                    % get the next statistic
                    thisStatistic = customStatistics(i);
                    % get the allowed range of the statistic
                    statRange = thisStatistic.StatisticRange;
                    % call the function handle specified by the custom statistic object,
                    % store the value in the associated dynamic property,
                    % and clip the output to the user-defined range
                    obj.([thisStatistic.StatisticName,'Image']) = ...
                        min(max(thisStatistic.StatisticFun(obj.ffcFPMStack),statRange(1)),statRange(2));
                end
            end
            % update the status flag to indicate built-in and custom FPM stats were calculated
            obj.FPMStatsDone = true;
        end

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
                paddedObjectImages = {obj.Object(:).paddedSubImage}';

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
            % if no objects
            if isempty(props)
                return % then stop here
            else
                % get the default label
                DefaultLabel = obj.Settings.DefaultLabel;
                % no default label found
                if isempty(DefaultLabel)
                    % restore default label
                    obj.Settings.restoreDefaultLabel();
                    DefaultLabel = obj.Settings.DefaultLabel;
                end
                % for each detected object
                for i = 1:length(props)
                   % create an instance of OOPSObject
                   obj.Object(i) = OOPSObject(props(i,1),...
                       obj,...
                       DefaultLabel);
                end
            end
            % update status flags and CurrentObjectIdx
            obj.ObjectDetectionDone = true;
            obj.CurrentObjectIdx = 1;
            obj.LocalSBDone = false;
            % find the local S/B for each object
            obj.FindLocalSB();
        end
        
%% object manipulation (gather, select, delete, etc.)

        % delete all objects in this OOPSImage
        function deleteObjects(obj)
            % collect and delete the objects in this image
            Objects = obj.Object;
            delete(Objects);
            % clear the placeholders
            clear Objects
            % reinitialize the obj.Object vector
            obj.Object = OOPSObject.empty();
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

%% retrieve object data

        function CurrentObject = get.CurrentObject(obj)
            try
                CurrentObject = obj.Object(obj.CurrentObjectIdx);
            catch
                CurrentObject = OOPSObject.empty();
            end
        end

        function VariableObjectData = GetAllObjectData(obj,Var2Get)
            % if the variable is a custom property
            if obj.Settings.isCustomStatistic(Var2Get)
                % we have to retrieve it differently
                VariableObjectData = obj.GetAllCustomObjectData(Var2Get);
                return
            end

            VariableObjectData = [obj.Object.(Var2Get)];
        end

        function VariableObjectData = GetAllCustomObjectData(obj,Var2Get)
            VariableObjectData = nan(obj.nObjects,1);
            for i = 1:obj.nObjects
                VariableObjectData(i,1) = obj.Object(i).(Var2Get);
            end
        end

        % return object data grouped by the object labels
        function ObjectDataByLabel = GetObjectDataByLabel(obj,Var2Get)
            % if the variable is a custom property
            if obj.Settings.isCustomStatistic(Var2Get)
                % we have to retrieve it differently
                ObjectDataByLabel = obj.GetCustomObjectDataByLabel(Var2Get);
                return
            end

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

        % return object data grouped by the object labels
        function ObjectDataByLabel = GetCustomObjectDataByLabel(obj,Var2Get)

            nLabels = length(obj.Settings.ObjectLabels);
            ObjectDataByLabel = cell(1,nLabels);
            % for each label
            for i = 1:nLabels
                % find idx to all object with that label
                ObjectLabelIdxs = find([obj.Object.Label]==obj.Settings.ObjectLabels(i));
                % the number of objects for which we will retrieve data
                nIdxs = numel(ObjectLabelIdxs);


                % % preallocate array of nans before looping
                % ObjectDataByLabel{i} = nan(1,nIdxs);
                % for ii = 1:nIdxs
                %     % add Var2Get from each object with the label to cell i of ObjectDataByLabel
                %     ObjectDataByLabel{i}(1,ii) = obj.Object(ObjectLabelIdxs(ii)).(Var2Get);
                % end


                % preallocate array of nans before looping
                ObjectDataByLabel{i} = nan(nIdxs,1);
                for ii = 1:nIdxs
                    % add Var2Get from each object with the label to cell i of ObjectDataByLabel
                    ObjectDataByLabel{i}(ii,1) = obj.Object(ObjectLabelIdxs(ii)).(Var2Get);
                end



            end

        end

        % return the number of objects in this OOPSImage
        function nObjects = get.nObjects(obj)
            if isvalid(obj.Object)
                nObjects = numel(obj.Object);
            else
                nObjects = 0;
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
            for cObject = obj.Object'
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

            for cObject = obj.Object'
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
                switch obj.Settings.ObjectSelectionColorMode
                    case 'Label'
                        AllCData(AllVerticesIdx,:) = zeros(numel(AllVerticesIdx),3)+cObject.LabelColor;
                    case 'Custom'
                        AllCData(AllVerticesIdx,:) = zeros(numel(AllVerticesIdx),3)+obj.Settings.ObjectSelectionColor;
                end
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
            for cObject = obj.Object'
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

            for cObject = obj.Object'
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
                switch obj.Settings.ObjectSelectionColorMode
                    case 'Label'
                        AllCData(AllVerticesIdx,:) = zeros(numel(AllVerticesIdx),3)+cObject.LabelColor;
                    case 'Custom'
                        AllCData(AllVerticesIdx,:) = zeros(numel(AllVerticesIdx),3)+obj.Settings.ObjectSelectionColor;
                end
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

        % returns a 1xn array of the number of objects with each label in this image (n = number of labels)
        function labelCounts = get.labelCounts(obj)
            % preallocate our array of label counts, one column per unique label
            labelCounts = zeros(1,obj.Settings.nLabels);
            % for each unique label
            for labelIdx = 1:obj.Settings.nLabels
                % find the number of objects with that label
                labelCounts(1,labelIdx) = numel(find([obj.Object.Label]==obj.Settings.ObjectLabels(labelIdx,1)));
            end
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

%% dependent Get methods for various display/processing options specific to this image

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
                case 'CustomUpload'
                    ThreshPanelTitle = 'Manual thresholding unavailable for uploaded masks';
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
                case 'CustomUpload'
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
                case 'CustomUpload'
                    ManualThreshEnabled = false;
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
                "Mean pixel Order",...
                "FPM stack loaded",...
                "FFC performed",...
                "Mask generated",...
                "FPM stats calculated",...
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
                {obj.OrderAvg},...
                {Logical2String(obj.FilesLoaded)},...
                {Logical2String(obj.FFCDone)},...
                {Logical2String(obj.MaskDone)},...
                {Logical2String(obj.FPMStatsDone)},...
                {Logical2String(obj.ObjectDetectionDone)},...
                {Logical2String(obj.LocalSBDone)},...
                'VariableNames',varNames,...
                'RowNames',"Image");

            ImageSummaryDisplayTable = rows2vars(ImageSummaryDisplayTable,"VariableNamingRule","preserve");

            ImageSummaryDisplayTable.Properties.RowNames = varNames;

        end

%% RGB output images

        function OrderImageRGB = get.OrderImageRGB(obj)
            %OrderImageRGB = ind2rgb(im2uint8(obj.OrderImage),obj.Settings.OrderColormap);
            % testing below
            OrderImageRGB = vecind2rgb(im2uint8(obj.OrderImage),obj.Settings.OrderColormap);
        end

        function MaxScaledOrderImage = get.MaxScaledOrderImage(obj)
            % scale the Order image to the image maximum
            MaxScaledOrderImage = obj.OrderImage./max(max(obj.OrderImage));
        end

        function MaxScaledOrderImageRGB = get.MaxScaledOrderImageRGB(obj)
            % get scaled Order image, convert to RGB
            MaxScaledOrderImageRGB = ind2rgb(im2uint8(obj.MaxScaledOrderImage),obj.Settings.OrderColormap);
        end

        function MaskedOrderImage = get.MaskedOrderImage(obj)
            % get the full Order image
            MaskedOrderImage = obj.OrderImage;
            % set any pixels outside the mask to 0
            MaskedOrderImage(~obj.bw) = 0;
        end

        function MaskedOrderImageRGB = get.MaskedOrderImageRGB(obj)
            MaskedOrderImageRGB = MaskRGB(obj.OrderImageRGB,obj.bw);
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

        function AzimuthOrderIntensityHSV = get.AzimuthOrderIntensityHSV(obj)
            % get 'V' data (intensity image)
            OverlayIntensity = obj.I;
            % get 'H' data (azimuth image)
            AzimuthData = obj.AzimuthImage;
            % values originally in [-pi/2 pi/2], adjust to fall in [0 pi]
            AzimuthData(AzimuthData<0) = AzimuthData(AzimuthData<0)+pi;
            % scale values to [0 1]
            AzimuthData = AzimuthData./pi;
            % get 'S' data (unscaled order factor image)
            Order = obj.OrderImage;
            % combine to make HSV image (in RGB format)
            AzimuthOrderIntensityHSV = hsv2rgb(cat(3,AzimuthData,Order,OverlayIntensity));
        end

        function UserScaledAzimuthOrderIntensityHSV = get.UserScaledAzimuthOrderIntensityHSV(obj)
            % get 'V' data (intensity image)
            OverlayIntensity = obj.UserScaledAverageIntensityImage;
            % get 'H' data (azimuth image)
            AzimuthData = obj.AzimuthImage;
            % values originally in [-pi/2 pi/2], adjust to fall in [0 pi]
            AzimuthData(AzimuthData<0) = AzimuthData(AzimuthData<0)+pi;
            % scale values to [0 1]
            AzimuthData = AzimuthData./pi;
            % get 'S' data (scaled order factor image)
            Order = obj.UserScaledOrderImage;
            % combine to make HSV image (in RGB format)
            UserScaledAzimuthOrderIntensityHSV = hsv2rgb(cat(3,AzimuthData,Order,OverlayIntensity));
        end

        function AzimuthIntensityOverlayRGB = get.AzimuthIntensityOverlayRGB(obj)
            AzimuthIntensityOverlayRGB = MaskRGB(obj.AzimuthRGB,obj.I);
        end

        function UserScaledAzimuthIntensityOverlayRGB = get.UserScaledAzimuthIntensityOverlayRGB(obj)
            UserScaledAzimuthIntensityOverlayRGB = MaskRGB(obj.AzimuthRGB,obj.UserScaledAverageIntensityImage);
        end

        function MaxScaledOrderIntensityOverlayRGB = get.MaxScaledOrderIntensityOverlayRGB(obj)
            % get the average intensity image to use as an opacity mask
            OverlayIntensity = obj.I;
            % get the raw Order image
            Order = obj.OrderImage;
            % get the maximum Order in the image
            maxOrder = max(max(Order));
            % now get the scaled Order-intensity RGB overlay
            MaxScaledOrderIntensityOverlayRGB = ...
                MaskRGB(ind2rgb(im2uint8(Order./maxOrder),obj.Settings.OrderColormap),OverlayIntensity);
        end

        function UserScaledOrderImage = get.UserScaledOrderImage(obj)
            UserScaledOrderImage = imadjust(obj.OrderImage,obj.OrderDisplayLimits,[0 1]);
        end

        function UserScaledOrderImageRGB = get.UserScaledOrderImageRGB(obj)
            %UserScaledOrderImageRGB = ind2rgb(im2uint8(obj.UserScaledOrderImage),obj.Settings.OrderColormap);

            % testing below - in early testing this is ~twice as fast as built-in ind2rgb()
            UserScaledOrderImageRGB = vecind2rgb(im2uint8(obj.UserScaledOrderImage),obj.Settings.OrderColormap);
        end

        function UserScaledOrderIntensityOverlayRGB = get.UserScaledOrderIntensityOverlayRGB(obj)
            % get the user-scaled average intensity image to use as an opacity mask
            OverlayIntensity = obj.UserScaledAverageIntensityImage;
            % get the user-scaled Order image in RGB format
            Order = obj.UserScaledOrderImageRGB;
            % now get the user-scaled Order-intensity overlay in RGB format
            UserScaledOrderIntensityOverlayRGB = MaskRGB(Order,OverlayIntensity);
        end

        function OrderIntensityOverlayRGB = get.OrderIntensityOverlayRGB(obj)
            % get the average intensity image to use as an opacity mask
            OverlayIntensity = obj.I;
            % get the raw Order image
            Order = obj.OrderImage;
            % now get the Order-intensity RGB overlay
            OrderIntensityOverlayRGB = ...
                MaskRGB(ind2rgb(im2uint8(Order),obj.Settings.OrderColormap),OverlayIntensity);
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

        function MaxScaledAverageIntensityImageRGB = get.MaxScaledAverageIntensityImageRGB(obj)
            MaxScaledAverageIntensityImageRGB = ...
                vecind2rgb(im2uint8(obj.I),obj.Settings.IntensityColormap);
        end

        function UserScaledAverageIntensityImage = get.UserScaledAverageIntensityImage(obj)
            UserScaledAverageIntensityImage = imadjust(obj.I,obj.PrimaryIntensityDisplayLimits,[0 1]);
        end

        function UserScaledAverageIntensityImageRGB = get.UserScaledAverageIntensityImageRGB(obj)
            UserScaledAverageIntensityImageRGB = ...
                vecind2rgb(im2uint8(obj.UserScaledAverageIntensityImage),obj.Settings.IntensityColormap);
        end

        function UserScaledReferenceImage = get.UserScaledReferenceImage(obj)
            UserScaledReferenceImage = ...
                imadjust(obj.ReferenceImage,obj.ReferenceIntensityDisplayLimits,[0 1]);
        end

        function UserScaledReferenceImageRGB = get.UserScaledReferenceImageRGB(obj)
            UserScaledReferenceImageRGB = vecind2rgb(im2uint8(obj.UserScaledReferenceImage),obj.Settings.ReferenceColormap);
        end

        function ReferenceImageRGB = get.ReferenceImageRGB(obj)
            ReferenceImageRGB = vecind2rgb(im2uint8(obj.ReferenceImage),obj.Settings.ReferenceColormap);
        end

        function UserScaledAverageIntensityReferenceCompositeRGB = get.UserScaledAverageIntensityReferenceCompositeRGB(obj)
            % combine user-scaled average intensity RGB and user-scaled reference intensity RGB
            UserScaledAverageIntensityReferenceCompositeRGB = ...
                obj.UserScaledAverageIntensityImageRGB + obj.UserScaledReferenceImageRGB;
        end

    end

    methods (Static)
        function obj = loadobj(replicate)

            % create an instance of OOPSImage by passing the Parent property of replicate
            obj = OOPSImage(replicate.Parent);

    %% load status flags

            % status tracking variables
            obj.FilesLoaded = replicate.FilesLoaded;
            obj.FFCDone = replicate.FFCDone;
            obj.MaskDone = replicate.MaskDone;

            % testing below
            try
                obj.FPMStatsDone = replicate.FPMStatsDone;
            catch
                obj.FPMStatsDone = replicate.OFDone;
            end
            % end testing

            obj.ObjectDetectionDone = replicate.ObjectDetectionDone;
            obj.LocalSBDone = replicate.LocalSBDone;
            obj.ReferenceImageLoaded = replicate.ReferenceImageLoaded;

    %% load FPM stacks

            % info about the image path and rawFPMFileName
            obj.rawFPMFileName = replicate.rawFPMFileName;
            obj.rawFPMShortName = replicate.rawFPMShortName;
            obj.rawFPMFullName = replicate.rawFPMFullName;
            % split on the '.'
            filenameSplit = strsplit(obj.rawFPMFileName,'.');
            % get the file extension
            obj.rawFPMFileType = filenameSplit{2};
            % update command window with status
            disp(['Loading FPM stack:',obj.rawFPMFullName,'...']);
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
            % average the raw data (polarization stack)
            obj.rawFPMAverage = mean(im2double(obj.rawFPMStack),3);

    %% load reference images

            if obj.ReferenceImageLoaded
                % reference image info
                obj.rawReferenceFileName = replicate.rawReferenceFileName;
                obj.rawReferenceShortName = replicate.rawReferenceShortName;
                obj.rawReferenceFullName = replicate.rawReferenceFullName;
                % split on the '.'
                filenameSplit = strsplit(obj.rawReferenceFileName,'.');
                % get the file extension
                obj.rawReferenceFileType = filenameSplit{2};
                % open the image with bioformats
                bfData = bfopen(char(obj.rawReferenceFullName));
                % get the image info (pixel values and filename) from the first element of the bf cell array
                imageInfo = bfData{1,1};
                % get the image data
                obj.rawReferenceImage = imageInfo{1,1};
                % get the class of the input
                obj.rawReferenceClass = class(obj.rawReferenceImage);
                % rescaled, double Reference image
                obj.ReferenceImage = Scale0To1(im2double(obj.rawReferenceImage));
            end

    %% load mask and label matrix

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

            obj.PrimaryIntensityDisplayLimits = replicate.PrimaryIntensityDisplayLimits;
            obj.ReferenceIntensityDisplayLimits = replicate.ReferenceIntensityDisplayLimits;

            obj.CurrentObjectIdx = replicate.CurrentObjectIdx;

            for i = 1:length(replicate.Object)
                % add image handle to the object struct
                replicate.Object(i).Parent = obj;
                % create an instance of OOPSObject
                obj.Object(i) = OOPSObject.loadobj(replicate.Object(i));
            end
        end
    end
end