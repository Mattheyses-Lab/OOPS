classdef PODSObject
    % Object parameters class
    properties
        
        % parent object
        Parent PODSImage
        
        
        Area = 0;
        BoundingBox = [];
        Centroid = [];
        Circularity = 0;
        ConvexArea = 0;
        ConvexHull = [];
        ConvexImage = [];
        Eccentricity = 0;
        Extrema = [];
        FilledArea = 0;
        Image = [];
        MajorAxisLength = 0;
        MinorAxisLength = 0;
        Orientation = 0;
        Perimeter = 0;
        
        % linear pixel indices
        PixelIdxList = [];
        
        % pixel indices
        PixelList = [];
        
        
        MaxFFCAvgIntensity = 0;
        MeanFFCAvgIntensity = 0;
        MinFFCAvgIntensity = 0;
        
        % linear indices for local BG region
        BGPixelIdxList = [];
        
        % object px values for various outputs
        RawPixelValues = [];
        OFPixelValues = [];
        AzimuthPixelValues = [];
        AnisotropyPixelValues = [];
        
        % object OF values
        OFAvg = 0;
        OFMin = 0;
        OFMax = 0;
        
        % Object 1, Object 2, etc...
        Name = '';
        
        % Idx at time of generation
        OriginalIdx = 0;
        
        % name of parent group
        GroupName = '';
        
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

    end % end properties
    
    methods
        
        function obj = PODSObject(ObjectProps)
            
            if length(ObjectProps) == 0
                return
            end
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
            
            obj.XAdjust = floor(obj.BoundingBox(1));
            obj.YAdjust = floor(obj.BoundingBox(2));
            temp = bwboundaries(obj.Image,8);
            obj.Perimeter8Conn = temp{1};
            clear temp
            obj.LineGroup = hggroup;
        end % end constructor method

    end % end methods
    

end % end classdef