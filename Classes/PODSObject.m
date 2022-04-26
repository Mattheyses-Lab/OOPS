classdef PODSObject < handle
    % Object parameters class
    properties
        
        % parent object
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
        
        % linear pixel indices
        PixelIdxList
        
        % pixel indices
        PixelList
        
        % index to the subimage such that L(idx{:}) extracts the elements
        SubarrayIdx
        
        MaxFFCAvgIntensity
        MeanFFCAvgIntensity
        MinFFCAvgIntensity
        
        % linear indices for local BG region
        BGPixelIdxList
        
        % object px values for various outputs
        RawPixelValues
        OFPixelValues
        AzimuthPixelValues
        AnisotropyPixelValues
        
        % object OF values
        OFAvg
        OFMin
        OFMax
        
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
        
        % S:B properrties
        BGIdxList
        BufferIdxList
        SignalAverage
        BGAverage
        SBRatio
        
        % Colocalization properties
        AvgColocIntensity
        ROIPearsons
        

    end % end properties
    
    properties(Dependent = true)
        
        OFSubImage 
        
        PaddedOFSubImage
        
        MaskedOFSubImage
        
        PaddedFFCIntensitySubImage
        
        PaddedMaskSubImage
        
        PaddedAnalysisChannelSubImage
        
        PaddedColocNorm2MaxSubImage
        
        CentroidX
        
        CentroidY
    end

    methods
        
        function obj = PODSObject(ObjectProps,hPODSImage)
            
            if length(ObjectProps) == 0
                return
            end
            
            % properties from ObjectProps struct
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
            
            % Parent of PODSObject obj is the PODSImage obj that detected it
            obj.Parent = hPODSImage;
            
        end % end constructor method
        

        function OFSubImage = get.OFSubImage(obj)
            OFImage = obj.Parent.OF_image;
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            dim = length(PaddedSubarrayIdx{1,1});
            OFSubImage = zeros(dim);
            OFSubImage(:) = OFImage(PaddedSubarrayIdx{:});
        end
        
        function PaddedOFSubImage = get.PaddedOFSubImage(obj)
            OFImage = obj.Parent.OF_image;
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            dim = length(PaddedSubarrayIdx{1,1});
            PaddedOFSubImage = zeros(dim);
            PaddedOFSubImage(:) = OFImage(PaddedSubarrayIdx{:});
        end        

        function MaskedOFSubImage = get.MaskedOFSubImage(obj)
            OFImage = obj.Parent.OF_image;
            MaskedOFSubImage = zeros(size(obj.Image));
            % masked
            MaskedOFSubImage(obj.Image) = OFImage(obj.PixelIdxList);
        end
        
        function PaddedFFCIntensitySubImage = get.PaddedFFCIntensitySubImage(obj)
            % get FFCIntensity image
            FFCIntensityImage = obj.Parent.I;
            % pad subarray and make square
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            % get length of X Idxs
            dim = length(PaddedSubarrayIdx{1,1});
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
            % get length of X Idxs (same as Ys)
            dim = length(PaddedSubarrayIdx{1,1});
            % initialize new subimage
            PaddedMaskSubImage = zeros(dim);
            % extract elements from main image into subimage
            PaddedMaskSubImage(:) = MaskImg(PaddedSubarrayIdx{:});
        end        
        
        function PaddedAnalysisChannelSubImage = get.PaddedAnalysisChannelSubImage(obj)
            AnalysisChannelImage = obj.Parent.ColocImage;
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            dim = length(PaddedSubarrayIdx{1,1});
            PaddedAnalysisChannelSubImage = zeros(dim);
            PaddedAnalysisChannelSubImage(:) = AnalysisChannelImage(PaddedSubarrayIdx{:});
        end
            
        function PaddedColocNorm2MaxSubImage = get.PaddedColocNorm2MaxSubImage(obj)
            ColocNorm2MaxImage = obj.Parent.ColocNormToMax;
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            dim = length(PaddedSubarrayIdx{1,1});
            PaddedColocNorm2MaxSubImage = zeros(dim);
            PaddedColocNorm2MaxSubImage(:) = ColocNorm2MaxImage(PaddedSubarrayIdx{:});
        end
    end % end methods
    

end % end classdef