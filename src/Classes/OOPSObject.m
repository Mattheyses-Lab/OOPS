classdef OOPSObject < handle
    % Object parameters class
    properties
        
        % parent image
        Parent OOPSImage
        
        % morphological properties from regionprops()
        Area = NaN
        BoundingBox = NaN
        Centroid = NaN
        Circularity = NaN
        ConvexArea = NaN
        ConvexHull = NaN
        ConvexImage = NaN
        Eccentricity = NaN
        EquivDiameter = NaN
        Extent = NaN
        Extrema = NaN
        FilledArea = NaN
        Image
        MajorAxisLength = NaN
        MinorAxisLength = NaN
        Orientation = NaN
        Perimeter = NaN
        Solidity = NaN
        MaxFeretDiameter = NaN
        MinFeretDiameter = NaN
        
        % linear pixel indices to object pixels in full-sized image
        PixelIdxList
        
        % pixel indices
        PixelList
        
        % index to the subimage such that L(idx{:}) extracts the elements
        % (2x1 cell | each cell is a 1xm or 1xn double for y and x subarray idxs, respectively)
        SubarrayIdx

        % coordinates of the object boundary (mx2 double | m = number of boundary points)
        Boundary

        % coordinates of the object midline
        Midline
        
        % S/B properties
        BGIdxList
        BufferIdxList
        SignalAverage = NaN
        BGAverage = NaN
        SBRatio = NaN
        
        % Selection and labeling
        Label OOPSLabel
        Selected = false

        % stats in development
        paddedSubarrayIdx = NaN
        paddedSubarrayIdxAdjustment = []
        paddedSubImage = []
        imageToPaddedObjectShift = []
        paddedPixelIdxList = []
        pixelMidlineTangentList = []

    end % end properties
    
    properties(Dependent = true)
        % various output values, object properties, and object images that are too costly 
        % to constantly store in memory, but quick to calculate if needed

        % list of azimuth pixel values
        AzimuthPixelValues

        % name of the group that to which this object's image belongs
        GroupName

        % name of this object's parent image
        ImageName

        % name of this object's parent image, but with some special characters preceeded by '\'
        InterpreterFriendlyImageName

        % various object images
        PaddedOFSubImage
        MaskedOFSubImage
        PaddedFFCIntensitySubImage
        PaddedMaskSubImage
        RestrictedPaddedMaskSubImage
        PaddedAzimuthSubImage
        
        % we store the centroid as a 2-element vector, no need to store these too
        CentroidX
        CentroidY

        % depends on selection status
        SelectionBoxLineWidth
        
        % OF properties of this object, dependent on OF image of Parent
        OFAvg
        OFMin
        OFMax
        OFPixelValues
        
        % object label properties, depend on currently applied label (OOPSLabel object)
        LabelIdx
        LabelName
        LabelColor
        LabelColorSquare
        
        % Reference channel properties
        AvgReferenceChannelIntensity
        IntegratedReferenceChannelIntensity

        % index of this object in its parent 'Object' property
        SelfIdx

        % object name, based on SelfIdx
        Name

        % simplified boundary (may store in memory if becomes useful)
        SimplifiedBoundary
        
        % other stats !IN DEVELOPMENT!

        paddedSubImageBoundary

        % list of values for each object pixel representing the normal direction to the closest midline point
        pixelMidlineNormalList

        AzimuthAverage
        AzimuthStd
        AzimuthAngularDeviation
        MidlineRelativeAzimuth
        NormalRelativeAzimuth

        Tortuosity
        MidlineLength
        
        TangentAverage

        ObjectSummaryDisplayTable

    end

    methods
        
        % constructor method
        function obj = OOPSObject(ObjectProps,ParentImage,Label)
            
            if isempty(ObjectProps)
                return
            end

            if ~isempty(ParentImage)
                % Parent of OOPSObject obj is the OOPSImage obj that detected it
                obj.Parent = ParentImage;
            else
                obj.Parent = OOPSImage.empty();
            end

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
            obj.EquivDiameter = ObjectProps.EquivDiameter;
            obj.Extent = ObjectProps.Extent;
            obj.FilledArea = ObjectProps.FilledArea;
            obj.Image = ObjectProps.Image;
            obj.MajorAxisLength = ObjectProps.MajorAxisLength;
            obj.MinorAxisLength = ObjectProps.MinorAxisLength;
            obj.Orientation = ObjectProps.Orientation;
            obj.Perimeter = ObjectProps.Perimeter;
            obj.PixelIdxList = ObjectProps.PixelIdxList;
            obj.PixelList = ObjectProps.PixelList;
            obj.SubarrayIdx = ObjectProps.SubarrayIdx;
            obj.Solidity = ObjectProps.Solidity;
            obj.MaxFeretDiameter = ObjectProps.MaxFeretDiameter;
            obj.MinFeretDiameter = ObjectProps.MinFeretDiameter;

            % calculated 8-connected boundary coordinates for ObjectBoxes
            obj.Boundary = ObjectProps.BWBoundary;

            % detected midline coordinates
            obj.Midline = ObjectProps.Midline;

            % stats in development
            obj.paddedSubarrayIdx = ObjectProps.paddedSubarrayIdx;
            obj.paddedSubarrayIdxAdjustment = ObjectProps.paddedSubarrayIdxAdjustment;
            obj.paddedSubImage = ObjectProps.paddedSubImage;
            obj.imageToPaddedObjectShift = ObjectProps.imageToPaddedObjectShift;
            obj.paddedPixelIdxList = ObjectProps.paddedPixelIdxList;
            obj.pixelMidlineTangentList = ObjectProps.pixelMidlineTangentList;

            % set default object label
            obj.Label = Label;

        end % end constructor method

        % class destructor – simple, any reindexing will be handled by higher level classes (OOPSImage, OOPSGroup)
        function delete(obj)
            delete(obj);
        end

        % saveobj function
        function object = saveobj(obj)

            object.Area = obj.Area;
            object.BoundingBox = obj.BoundingBox;
            object.Centroid = obj.Centroid;
            object.Circularity = obj.Circularity;
            object.ConvexArea = obj.ConvexArea;
            object.ConvexHull = obj.ConvexHull;
            object.ConvexImage = obj.ConvexImage;
            object.Eccentricity = obj.Eccentricity;
            object.EquivDiameter = obj.EquivDiameter;
            object.Extent = obj.Extent;
            object.Extrema = obj.Extrema;
            object.FilledArea = obj.FilledArea;
            object.Image = sparse(obj.Image);
            object.MajorAxisLength = obj.MajorAxisLength;
            object.MinorAxisLength = obj.MinorAxisLength;
            object.Orientation = obj.Orientation;
            object.Perimeter = obj.Perimeter;
            object.Solidity = obj.Solidity;
            object.MaxFeretDiameter = obj.MaxFeretDiameter;
            object.MinFeretDiameter = obj.MinFeretDiameter;

            % linear pixel indices to object pixels in full-sized image
            object.PixelIdxList = obj.PixelIdxList;

            % pixel indices
            object.PixelList = obj.PixelList;

            % index to the subimage such that L(idx{:}) extracts the elements
            object.SubarrayIdx = obj.SubarrayIdx;

            % coordinates to trace object boundary
            object.Boundary = obj.Boundary;

            % S:B properties
            object.BGIdxList = obj.BGIdxList;
            object.BufferIdxList = obj.BufferIdxList;
            object.SignalAverage = obj.SignalAverage;
            object.BGAverage = obj.BGAverage;
            object.SBRatio = obj.SBRatio;

            % Selection and labeling
            object.Label = obj.Label;
            object.Selected = obj.Selected;


            object.paddedSubarrayIdx = obj.paddedSubarrayIdx;
            object.paddedSubarrayIdxAdjustment = obj.paddedSubarrayIdxAdjustment;
            object.paddedSubImage = obj.paddedSubImage;
            object.imageToPaddedObjectShift = obj.imageToPaddedObjectShift;
            object.paddedPixelIdxList = obj.paddedPixelIdxList;
            object.pixelMidlineTangentList = obj.pixelMidlineTangentList;

            object.Midline = obj.Midline;

        end

        function InvertSelection(obj)
            NewSelectionStatus = ~[obj(:).Selected];
            NewSelectionStatus = num2cell(NewSelectionStatus.');
            [obj(:).Selected] = deal(NewSelectionStatus{:});
        end

        %% Dependent get() methods

        function SelfIdx = get.SelfIdx(obj)
            SelfIdx = find(obj.Parent.Object==obj);
        end

        function Name = get.Name(obj)
            Name = ['Object ',num2str(obj.SelfIdx)];
        end

        function SimplifiedBoundary = get.SimplifiedBoundary(obj)
            % get x and y coordinates of the object boundary
            x = obj.Boundary(:,2);
            y = obj.Boundary(:,1);

            try
                % create polygon from boundary coordinates
                temp_poly = polyshape(x,y,"Simplify",false,"KeepCollinearPoints",false);
                % simplify it
                %temp_poly = simplify(temp_poly);
                % extract the simplified coordinates (with duplicated endpoint)
                newX = [temp_poly.Vertices(:,1);temp_poly.Vertices(1,1)];
                newY = [temp_poly.Vertices(:,2);temp_poly.Vertices(1,2)];
            catch
                newX = x;
                newY = y;
            end

            SimplifiedBoundary = [newY newX];
        end

        function paddedSubImageBoundary = get.paddedSubImageBoundary(obj)
            paddedSubImageBoundary = obj.Boundary + obj.imageToPaddedObjectShift;
        end

        function OFAvg = get.OFAvg(obj)
            % average OF of all pixels identified by the mask
            try
                OFAvg = mean(obj.Parent.OF_image(obj.PixelIdxList));
            catch
                OFAvg = NaN;
            end
        end
        
        function OFMax = get.OFMax(obj)
            % max OF of all pixels in the object mask
            try
                OFMax = max(obj.Parent.OF_image(obj.PixelIdxList));
            catch
                OFMax = NaN;
            end
        end
        
        function OFMin = get.OFMin(obj)
            % min OF of all pixels in the object mask
            try
                OFMin = min(obj.Parent.OF_image(obj.PixelIdxList));
            catch
                OFMin = NaN;
            end
        end
        
        function AvgReferenceChannelIntensity = get.AvgReferenceChannelIntensity(obj)
            
            % if no reference image loaded, return NaN
            if isempty(obj.Parent.ReferenceImage)
                AvgReferenceChannelIntensity = NaN;
                return
            end

            try
                AvgReferenceChannelIntensity = mean(obj.Parent.ReferenceImage(obj.PixelIdxList));
            catch
                AvgReferenceChannelIntensity = NaN;
            end
        end
        
        function IntegratedReferenceChannelIntensity = get.IntegratedReferenceChannelIntensity(obj)

            % if no reference image loaded, return NaN
            if isempty(obj.Parent.ReferenceImage)
                IntegratedReferenceChannelIntensity = NaN;
                return
            end

            try
                IntegratedReferenceChannelIntensity = sum(obj.Parent.ReferenceImage(obj.PixelIdxList));
            catch
                IntegratedReferenceChannelIntensity = NaN;
            end
        end        
        
        function LabelIdx = get.LabelIdx(obj)
            LabelIdx = obj.Label.SelfIdx;
        end
        
        function LabelName = get.LabelName(obj)
            % convert the name of this object's label to a string, return
            LabelName = convertCharsToStrings(obj.Label.Name);
        end
        
        function LabelColor = get.LabelColor(obj)
            LabelColor = obj.Label.Color;
        end

        function LabelColorSquare = get.LabelColorSquare(obj)
            LabelColorSquare = makeRGBColorSquare(obj.LabelColor,5);
        end

        function GroupName = get.GroupName(obj)
            % convert the name of this object's group to a string, return
            GroupName = convertCharsToStrings(obj.Parent.Parent.GroupName);
        end

        function ImageName = get.ImageName(obj)
            ImageName = categorical({obj.Parent.pol_shortname});
        end

        function InterpreterFriendlyImageName = get.InterpreterFriendlyImageName(obj)
            % nameSplit = strsplit(obj.Parent.pol_shortname,'_');
            % InterpreterFriendlyImageName = categorical({strjoin(nameSplit,"\_")});

            % testing below
            nameSplit = strsplit(obj.Parent.pol_shortname,'_');
            InterpreterFriendlyImageName = convertCharsToStrings(strjoin(nameSplit,"\_"));
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
        
        function PaddedOFSubImage = get.PaddedOFSubImage(obj)
            PaddedOFSubImage = obj.Parent.OF_image(obj.paddedSubarrayIdx{:});
        end        

        function MaskedOFSubImage = get.MaskedOFSubImage(obj)
            % OFImage = obj.Parent.OF_image;
            MaskedOFSubImage = zeros(size(obj.Image));
            % masked
            MaskedOFSubImage(obj.Image) = obj.Parent.OF_image(obj.PixelIdxList);
        end

        function PaddedAzimuthSubImage = get.PaddedAzimuthSubImage(obj)
            PaddedAzimuthSubImage = obj.Parent.AzimuthImage(obj.paddedSubarrayIdx{:});
        end
        
        function PaddedFFCIntensitySubImage = get.PaddedFFCIntensitySubImage(obj)
            PaddedFFCIntensitySubImage = obj.Parent.I(obj.paddedSubarrayIdx{:});
        end
        
        function PaddedMaskSubImage = get.PaddedMaskSubImage(obj)
            PaddedMaskSubImage = obj.Parent.bw(obj.paddedSubarrayIdx);
        end
        
        function RestrictedPaddedMaskSubImage = get.RestrictedPaddedMaskSubImage(obj)
            RestrictedPaddedMaskSubImage = obj.paddedSubImage;
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

% GET METHODS STILL IN DEVELOPMENT

        function AzimuthAngularDeviation = get.AzimuthAngularDeviation(obj)
            try
                r = abs(mean(exp(1i*obj.AzimuthPixelValues*2)));
                AzimuthAngularDeviation = rad2deg(sqrt(2*(1-r))*0.5);
            catch
                AzimuthAngularDeviation = NaN;
            end
        end

        function AzimuthAverage = get.AzimuthAverage(obj)
            try
                AzimuthAverage = rad2deg(getAzimuthAverage(obj.AzimuthPixelValues));
            catch
                AzimuthAverage = NaN;
            end
        end

        function TangentAverage = get.TangentAverage(obj)
            try
                TangentAverage = rad2deg(getAzimuthAverage(getMidlineTangent(obj.Midline)));
            catch
                TangentAverage = NaN;
            end
        end

        function pixelMidlineNormalList = get.pixelMidlineNormalList(obj)
            if isempty(obj.pixelMidlineTangentList)
                pixelMidlineNormalList = [];
                return
            end
            pixelMidlineNormalList = obj.pixelMidlineTangentList+pi/2;
            pixelMidlineNormalList(pixelMidlineNormalList>(pi/2)) = pixelMidlineNormalList(pixelMidlineNormalList>(pi/2))-pi;
        end

        function AzimuthStd = get.AzimuthStd(obj)
            try
                AzimuthStd = getAzimuthStd(obj.AzimuthPixelValues);
            catch
                AzimuthStd = NaN;
            end
        end

        function MidlineRelativeAzimuth = get.MidlineRelativeAzimuth(obj)
            try
                % get the angular differences between azimuth and tangent angles
                tangentDiff = angle(exp(2i*obj.AzimuthPixelValues)./exp(2i*obj.pixelMidlineTangentList))*0.5;
                % average the differences
                MidlineRelativeAzimuth = rad2deg(getAzimuthAverage(tangentDiff));
            catch
                MidlineRelativeAzimuth = NaN;
            end
        end

        function NormalRelativeAzimuth = get.NormalRelativeAzimuth(obj)
            try
                % get the angular differences between azimuth and midline normal
                normalDiff = angle(exp(2i*obj.AzimuthPixelValues)./exp(2i*obj.pixelMidlineNormalList))*0.5;
                % average the differences
                NormalRelativeAzimuth = rad2deg(getAzimuthAverage(normalDiff));
            catch
                NormalRelativeAzimuth = NaN;
            end
        end

        function MidlineLength = get.MidlineLength(obj)
            try
                MidlineLength = getCurveLength(obj.Midline);
            catch
                MidlineLength = NaN;
            end
        end

        function Tortuosity = get.Tortuosity(obj)

            if isempty(obj.Midline)
                Tortuosity = NaN;
                return
            end

            try
                midline = obj.Midline;
                Tortuosity = obj.MidlineLength/(getCurveLength([midline(1,:);midline(end,:)]));
            catch
                Tortuosity = NaN;
            end
        end

% end methods in development

        function ObjectSummaryDisplayTable = get.ObjectSummaryDisplayTable(obj)

            varNames = [...
                "Name",...
                "Label",...
                "Mean OF",...
                "Pixel area",...
                "Convex area",...
                "Perimeter",...
                "Circularity",...
                "Eccentricity",...
                "Orientation",...
                "Extent",...
                "Solidity",...
                "Average signal intensity",...
                "Average BG intensity",...
                "Local S/B ratio",...
                "Original index",...
                "Azimuth average",...
                "Azimuth standard deviation",...
                "Azimuth w.r.t. midline",...
                "Azimuth w.r.t. normal",...
                "Tortuosity",...
                "Midline length",...
                "Midline tangent average"];

            ObjectSummaryDisplayTable = table(...
                {obj.Name},...
                {obj.Label.Name},...
                {obj.OFAvg},...
                {obj.Area},...
                {obj.ConvexArea},...
                {obj.Perimeter},...
                {obj.Circularity},...
                {obj.Eccentricity},...
                {obj.Orientation},...
                {obj.Extent},...
                {obj.Solidity},...
                {obj.SignalAverage},...
                {obj.BGAverage},...
                {obj.SBRatio},...
                {obj.SelfIdx},...
                {obj.AzimuthAverage},...
                {obj.AzimuthStd},...
                {obj.MidlineRelativeAzimuth},...
                {obj.NormalRelativeAzimuth},...
                {obj.Tortuosity},...
                {obj.MidlineLength},...
                {obj.TangentAverage},...
                'VariableNames',varNames,...
                'RowNames',"Object");

            ObjectSummaryDisplayTable = rows2vars(ObjectSummaryDisplayTable,"VariableNamingRule","preserve");

            ObjectSummaryDisplayTable.Properties.RowNames = varNames;

        end



    end % end methods
    
    methods (Static)
        function obj = loadobj(object)

            % build ObjectProps struct to call OOPSObject constructor
            ObjectProps.Area = object.Area;
            ObjectProps.BoundingBox = object.BoundingBox;
            ObjectProps.Centroid = object.Centroid;
            ObjectProps.Circularity = object.Circularity;
            ObjectProps.ConvexArea = object.ConvexArea;
            ObjectProps.ConvexHull = object.ConvexHull;
            ObjectProps.ConvexImage = object.ConvexImage;
            ObjectProps.Eccentricity = object.Eccentricity;
            ObjectProps.Extrema = object.Extrema;
            ObjectProps.EquivDiameter = object.EquivDiameter;
            ObjectProps.Extent = object.Extent;
            ObjectProps.FilledArea = object.FilledArea;
            ObjectProps.Image = full(object.Image);
            ObjectProps.MajorAxisLength = object.MajorAxisLength;
            ObjectProps.MinorAxisLength = object.MinorAxisLength;
            ObjectProps.Orientation = object.Orientation;
            ObjectProps.Perimeter = object.Perimeter;
            ObjectProps.MaxFeretDiameter = object.MaxFeretDiameter;
            ObjectProps.MinFeretDiameter = object.MinFeretDiameter;

            ObjectProps.Solidity = object.Solidity;

            ObjectProps.BWBoundary = object.Boundary;

            % idxs returned by regionprops
            ObjectProps.PixelIdxList = object.PixelIdxList;
            ObjectProps.PixelList = object.PixelList;
            ObjectProps.SubarrayIdx = object.SubarrayIdx;

            % other idxs and pixel idx lists calculated upon masking
            ObjectProps.paddedSubarrayIdx = object.paddedSubarrayIdx;
            ObjectProps.paddedSubarrayIdxAdjustment = object.paddedSubarrayIdxAdjustment;
            ObjectProps.paddedSubImage = object.paddedSubImage;
            ObjectProps.imageToPaddedObjectShift = object.imageToPaddedObjectShift;
            ObjectProps.paddedPixelIdxList = object.paddedPixelIdxList;
            ObjectProps.pixelMidlineTangentList = object.pixelMidlineTangentList;

            % the object midline
            try 
                Midline = object.Midline; 
            catch
                Midline = [NaN NaN];
            end
            ObjectProps.Midline = Midline;

            % get the object label (OOPSLabel)
            ObjectLabel = object.Label;

            % create new instance of OOPSObject
            obj = OOPSObject(ObjectProps,OOPSImage.empty(),ObjectLabel);

            obj.BGIdxList = object.BGIdxList;
            obj.BufferIdxList = object.BufferIdxList;
            obj.SignalAverage = object.SignalAverage;
            obj.BGAverage = object.BGAverage;
            obj.SBRatio = object.SBRatio;

            % selection status
            obj.Selected = object.Selected;

        end
    end

end % end classdef