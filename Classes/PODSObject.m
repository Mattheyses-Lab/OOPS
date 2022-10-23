classdef PODSObject < handle
    % Object parameters class
    properties
        
        % parent image
        Parent PODSImage
        
        Area
        BoundingBox
        Centroid
        Circularity
        ConvexArea
        ConvexHull
        ConvexImage
        Eccentricity
        Extrema
        FilledArea
        Image
        MajorAxisLength
        MinorAxisLength
        Orientation
        Perimeter
        MaxFeretDiameter
        MinFeretDiameter
        
        % linear pixel indices to object pixels in full-sized image
        PixelIdxList
        
        % pixel indices
        PixelList
        
        % index to the subimage such that L(idx{:}) extracts the elements
        SubarrayIdx

        % coordinates to trace object boundary
        Boundary
        
        MaxFFCAvgIntensity
        MeanFFCAvgIntensity
        MinFFCAvgIntensity
        
        % linear indices for local BG region
        BGPixelIdxList
        
        % object px values for various outputs
        RawPixelValues
        AnisotropyPixelValues
        
        % Object 1, Object 2, etc...
        Name
        
        % Idx at time of generation
        OriginalIdx
        
        % name of parent group
        GroupName
        
        % perimeters
        Perimeter8Conn
        XAdjust
        YAdjust
        LineGroup
        
        % S:B properties
        BGIdxList
        BufferIdxList
        SignalAverage
        BGAverage
        SBRatio
        
        % Colocalization properties
        AvgColocIntensity
        ROIPearsons
        
        % Selection and labeling
        Label PODSLabel
        Selected = false

    end % end properties
    
    properties(Dependent = true)
        % various output values, object properties, and object images that
        % are too costly to store in memory, but quick to calculate if needed

        % list of values, average, and standard dev. of object azimuths
        AzimuthPixelValues
        AzimuthAverage
        AzimuthStd

        % various object images
        OFSubImage 
        PaddedOFSubImage
        MaskedOFSubImage
        PaddedFFCIntensitySubImage
        PaddedMaskSubImage
        RestrictedPaddedMaskSubImage        
        PaddedAnalysisChannelSubImage
        PaddedColocNorm2MaxSubImage
        PaddedAzimuthSubImage
        
        CentroidX
        CentroidY

        % depends on selection status
        SelectionBoxLineWidth
        
        % OF properties of this object, dependent on OF image of Parent
        OFAvg
        OFMin
        OFMax
        OFPixelValues
        
        % need to make some dependent properties for object labels so
        % we can search for objects by the properties of their labels
        LabelIdx
        LabelName
        
        % Reference channel properties
        AvgReferenceChannelIntensity
        IntegratedReferenceChannelIntensity
        
    end

    methods
        
        % constructor method
        function obj = PODSObject(ObjectProps,ParentImage,Name,Idx,Label)
            
            if isempty(ObjectProps)
                return
            end

            % Parent of PODSObject obj is the PODSImage obj that detected it
            obj.Parent = ParentImage;

            % properties from ObjectProps struct (from regionprops() using image mask)
            obj.Area = ObjectProps.Area;
            obj.BoundingBox = ObjectProps.BoundingBox;
            obj.Centroid = ObjectProps.Centroid;
            obj.Circularity = ObjectProps.Circularity;
            obj.ConvexArea = ObjectProps.ConvexArea;
            obj.ConvexHull = ObjectProps.ConvexHull;
            obj.ConvexImage = ObjectProps.ConvexImage;
            obj.Eccentricity = ObjectProps.Eccentricity;
            obj.Extrema = ObjectProps.Extrema;
            obj.FilledArea = ObjectProps.FilledArea;
            obj.Image = ObjectProps.Image;
            obj.MajorAxisLength = ObjectProps.MajorAxisLength;
            obj.MinorAxisLength = ObjectProps.MinorAxisLength;
            obj.Orientation = ObjectProps.Orientation;
            obj.Perimeter = ObjectProps.Perimeter;
            obj.PixelIdxList = ObjectProps.PixelIdxList;
            obj.PixelList = ObjectProps.PixelList;
            obj.SubarrayIdx = ObjectProps.SubarrayIdx;
            obj.MaxFeretDiameter = ObjectProps.MaxFeretDiameter;
            obj.MinFeretDiameter = ObjectProps.MinFeretDiameter;

            % calculated 8-connected boundary coordinates for ObjectBoxes
            obj.Boundary = ObjectProps.BWBoundary;

            % Name of object is "Object (Idx)"
            obj.Name = Name;
            
            % original idx at time of creation
            obj.OriginalIdx = Idx;
            
            % set default object label
            obj.Label = Label;
            
        end % end constructor method

        % class destructor – simple, any reindexing will be handled by higher level classes (PODSImage, PODSGroup)
        function delete(obj)
            delete(obj);
        end

        function InvertSelection(obj)
            
            NewSelectionStatus = ~[obj(:).Selected];
            NewSelectionStatus = num2cell(NewSelectionStatus.');
            [obj(:).Selected] = deal(NewSelectionStatus{:});

        end

        %% Dependent 'get' methods

        function OFAvg = get.OFAvg(obj)
            % average OF of all pixels identified by the mask
            try
                OFAvg = mean(obj.Parent.OF_image(obj.PixelIdxList));
            catch
                OFAvg = NaN;
            end
        end
        
        function OFMax = get.OFMax(obj)
            % max OF of all pixels identified by the mask
            try
                OFMax = max(obj.Parent.OF_image(obj.PixelIdxList));
            catch
                OFMax = NaN;
            end
        end
        
        function OFMin = get.OFMin(obj)
            % min OF of all object pixels
            try
                OFMin = min(obj.Parent.OF_image(obj.PixelIdxList));
            catch
                OFMin = NaN;
            end
        end
        
        function AvgReferenceChannelIntensity = get.AvgReferenceChannelIntensity(obj)
            try
                AvgReferenceChannelIntensity = mean(obj.Parent.ReferenceImage(obj.PixelIdxList));
            catch
                AvgReferenceChannelIntensity = NaN;
            end
        end
        
        function IntegratedReferenceChannelIntensity = get.IntegratedReferenceChannelIntensity(obj)
            try
                IntegratedReferenceChannelIntensity = sum(obj.Parent.ReferenceImage(obj.PixelIdxList));
            catch
                IntegratedReferenceChannelIntensity = NaN;
            end
        end        
        
        function LabelIdx = get.LabelIdx(obj)
            LabelIdx = str2double(obj.Label.LabelNumber);
        end
        
        function LabelName = get.LabelName(obj)
            LabelName = obj.Label.Name;
        end
        
        function OFPixelValues = get.OFPixelValues(obj)
            % list of OF in all object pixels
            try
                OFPixelValues = obj.Parent.OF_image(obj.PixelIdxList);
            catch
                OFPixelValues = NaN;
            end
        end        

        function AzimuthPixelValues = get.AzimuthPixelValues(obj)
            % list of Azimuth values for each object pixel
            try
                AzimuthPixelValues = obj.Parent.AzimuthImage(obj.PixelIdxList);
            catch
                AzimuthPixelValues = NaN;
            end
        end

        function AzimuthAverage = get.AzimuthAverage(obj)
            % list of Azimuth values for each object pixel
            try
                [~,AzimuthAverage] = getAzimuthAverageUsingDipoles(rad2deg(obj.AzimuthPixelValues));
            catch
                AzimuthAverage = NaN;
            end
        end

        function AzimuthStd = get.AzimuthStd(obj)
            % list of Azimuth values for each object pixel
            try
                AzimuthStd = getAzimuthStd(rad2deg(obj.AzimuthPixelValues));
            catch
                AzimuthStd = NaN;
            end
        end        

        function OFSubImage = get.OFSubImage(obj)
            OFImage = obj.Parent.OF_image;
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            dim = [length(PaddedSubarrayIdx{1,1}) length(PaddedSubarrayIdx{1,2})];
            OFSubImage = zeros(dim);
            OFSubImage(:) = OFImage(PaddedSubarrayIdx{:});
        end
        
        function PaddedOFSubImage = get.PaddedOFSubImage(obj)
            OFImage = obj.Parent.OF_image;
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            dim = [length(PaddedSubarrayIdx{1,1}) length(PaddedSubarrayIdx{1,2})];
            PaddedOFSubImage = zeros(dim);
            PaddedOFSubImage(:) = OFImage(PaddedSubarrayIdx{:});
        end        

        function MaskedOFSubImage = get.MaskedOFSubImage(obj)
            OFImage = obj.Parent.OF_image;
            MaskedOFSubImage = zeros(size(obj.Image));
            % masked
            MaskedOFSubImage(obj.Image) = OFImage(obj.PixelIdxList);
        end

        function PaddedAzimuthSubImage = get.PaddedAzimuthSubImage(obj)
            % get Azimuth image
            AzimuthImage = obj.Parent.AzimuthImage;
            % pad subarray and make square
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            % get size of subarray idx
            dim = [length(PaddedSubarrayIdx{1,1}) length(PaddedSubarrayIdx{1,2})];
            % initialize new subimage
            PaddedAzimuthSubImage = zeros(dim);
            % extract elements from main image into subimage
            PaddedAzimuthSubImage(:) = AzimuthImage(PaddedSubarrayIdx{:});
        end
        
        function PaddedFFCIntensitySubImage = get.PaddedFFCIntensitySubImage(obj)
            % get FFCIntensity image
            FFCIntensityImage = obj.Parent.I;
            % pad subarray and make square
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            % get size of subarray idx
            dim = [length(PaddedSubarrayIdx{1,1}) length(PaddedSubarrayIdx{1,2})];
            % initialize new subimage
            PaddedFFCIntensitySubImage = zeros(dim);
            % extract elements from main image into subimage
            PaddedFFCIntensitySubImage(:) = FFCIntensityImage(PaddedSubarrayIdx{:});
        end
        
        function PaddedMaskSubImage = get.PaddedMaskSubImage(obj)
            % get FFCIntensity image
            MaskImg = obj.Parent.bw;
            % pad subarray and make square
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            % get size of subarray idx
            dim = [length(PaddedSubarrayIdx{1,1}) length(PaddedSubarrayIdx{1,2})];
            % initialize new subimage
            PaddedMaskSubImage = false(dim);
            % extract elements from main image into subimage
            PaddedMaskSubImage(:) = MaskImg(PaddedSubarrayIdx{:});
        end
        
        function RestrictedPaddedMaskSubImage = get.RestrictedPaddedMaskSubImage(obj)
            % get full mask image
            FullSizedMaskImg = false(size(obj.Parent.bw));
            % set this object's pixels to on
            FullSizedMaskImg(obj.PixelIdxList) = true;
            % pad subarray and make square (if possible)
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            % get size of subarray idx
            dim = [length(PaddedSubarrayIdx{1,1}) length(PaddedSubarrayIdx{1,2})];
            % initialize new subimage
            RestrictedPaddedMaskSubImage = false(dim);
            % extract elements from main image into subimage
            RestrictedPaddedMaskSubImage(:) = FullSizedMaskImg(PaddedSubarrayIdx{:});
        end        

        function PaddedAnalysisChannelSubImage = get.PaddedAnalysisChannelSubImage(obj)
            AnalysisChannelImage = obj.Parent.ColocImage;
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            dim = [length(PaddedSubarrayIdx{1,1}) length(PaddedSubarrayIdx{1,2})];
            PaddedAnalysisChannelSubImage = zeros(dim);
            PaddedAnalysisChannelSubImage(:) = AnalysisChannelImage(PaddedSubarrayIdx{:});
        end
            
        function PaddedColocNorm2MaxSubImage = get.PaddedColocNorm2MaxSubImage(obj)
            ColocNorm2MaxImage = obj.Parent.ColocNormToMax;
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            dim = [length(PaddedSubarrayIdx{1,1}) length(PaddedSubarrayIdx{1,2})];
            PaddedColocNorm2MaxSubImage = zeros(dim);
            PaddedColocNorm2MaxSubImage(:) = ColocNorm2MaxImage(PaddedSubarrayIdx{:});
        end
        
        function SelectionBoxLineWidth = get.SelectionBoxLineWidth(obj)
            % set value of selection box linewidth depedning on object selection status
            switch obj.Selected
                case false
                    SelectionBoxLineWidth = 1;
                case true
                    SelectionBoxLineWidth = 2;
            end
        end
        
        function CentroidX = get.CentroidX(obj)
            CentroidX = obj.Centroid(1);
        end

        function CentroidY = get.CentroidY(obj)
            CentroidY = obj.Centroid(2);
        end        

    end % end methods
    

end % end classdef