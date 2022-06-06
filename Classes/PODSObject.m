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
        
        
        MaxFFCAvgIntensity
        MeanFFCAvgIntensity
        MinFFCAvgIntensity
        
        % linear indices for local BG region
        BGPixelIdxList
        
        % object px values for various outputs
        RawPixelValues
%        OFPixelValues
        AzimuthPixelValues
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
        
        OFSubImage 
        
        PaddedOFSubImage
        
        MaskedOFSubImage
        
        PaddedFFCIntensitySubImage
        
        PaddedMaskSubImage
        RestrictedPaddedMaskSubImage        
        
        PaddedAnalysisChannelSubImage
        
        PaddedColocNorm2MaxSubImage
        
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
            obj.MaxFeretDiameter = ObjectProps.MaxFeretDiameter;
            obj.MinFeretDiameter = ObjectProps.MinFeretDiameter;
            
            % Parent of PODSObject obj is the PODSImage obj that detected it
            obj.Parent = ParentImage;
            
            % Name of object is "Object (Idx)"
            obj.Name = Name;
            
            % original idx at time of creation
            obj.OriginalIdx = Idx;
            
            % set default object label
            obj.Label = Label;
            
        end % end constructor method

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
%             Img = obj.Parent.ReferenceImage./max(max(obj.Parent.ReferenceImage));
%             try
%                 AvgReferenceChannelIntensity = mean(Img(obj.PixelIdxList));
%             catch
%                 AvgReferenceChannelIntensity = NaN;
%             end

        end
        
        function IntegratedReferenceChannelIntensity = get.IntegratedReferenceChannelIntensity(obj)
            try
                IntegratedReferenceChannelIntensity = sum(obj.Parent.ReferenceImage(obj.PixelIdxList));
            catch
                IntegratedReferenceChannelIntensity = NaN;
            end
%             Img = obj.Parent.ReferenceImage./max(max(obj.Parent.ReferenceImage));
%             try
%                 IntegratedReferenceChannelIntensity = sum(Img(obj.PixelIdxList));
%             catch
%                 IntegratedReferenceChannelIntensity = NaN;
%             end
        end        
        
        function LabelIdx = get.LabelIdx(obj)
            LabelIdx = str2num(obj.Label.LabelNumber);
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
        
        function RestrictedPaddedMaskSubImage = get.RestrictedPaddedMaskSubImage(obj)
            % get full mask image
            FullSizedMaskImg = logical(zeros(size(obj.Parent.bw)));
            % set this object's pixels to on
            FullSizedMaskImg(obj.PixelIdxList) = true;
            % pad subarray and make square
            PaddedSubarrayIdx = padSubarrayIdx(obj.SubarrayIdx,5);
            % get length of X Idxs (same as Ys)
            dim = length(PaddedSubarrayIdx{1,1});
            % initialize new subimage
            RestrictedPaddedMaskSubImage = zeros(dim);
            % extract elements from main image into subimage
            RestrictedPaddedMaskSubImage(:) = FullSizedMaskImg(PaddedSubarrayIdx{:});
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
        
        function SelectionBoxLineWidth = get.SelectionBoxLineWidth(obj)
            % set value of selection box linewidth depedning on object selection status
            switch obj.Selected
                case false
                    SelectionBoxLineWidth = 1;
                case true
                    SelectionBoxLineWidth = 2;
            end
        end
        
    end % end methods
    

end % end classdef