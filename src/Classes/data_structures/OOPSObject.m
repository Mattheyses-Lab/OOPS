classdef OOPSObject < handle & dynamicprops
    % Object parameters class
    properties
        
        % parent image
        Parent OOPSImage
        
        % morphological properties from regionprops()
        Area (1,1) double = NaN
        BoundingBox (1,4) double
        Centroid (1,2) double
        Circularity (1,1) double = NaN
        ConvexArea (1,1) double = NaN
        ConvexHull (:,2) double = []
        ConvexImage (:,:) logical = []
        Eccentricity (1,1) double = NaN
        EquivDiameter (1,1) double = NaN
        Extent (1,1) double = NaN
        Extrema (8,2) double
        FilledArea (1,1) double = NaN
        Image (:,:) logical = []
        MajorAxisLength (1,1) double = NaN
        MinorAxisLength (1,1) double = NaN
        Perimeter (1,1) double = NaN
        Solidity (1,1) double = NaN
        MaxFeretDiameter (1,1) double = NaN
        MinFeretDiameter (1,1) double = NaN
        
        % linear pixel indices to object pixels parent image
        PixelIdxList (:,1) double = []
        
        % pixel indices [r,c]
        PixelList (:,2) double = []
        
        % index to the subimage such that I(SubarrayIdx{:}) extracts the elements
        % (2x1 cell | each cell is a 1xm or 1xn double for y and x subarray idxs, respectively)
        SubarrayIdx (1,2) cell

        % coordinates of the object boundary (mx2 double | m = number of boundary points)
        Boundary (:,2) double = []

        % coordinates of the object midline
        Midline (:,2) double = [NaN NaN]
        
        % S/B properties
        BGIdxList (:,1) = []
        BufferIdxList (:,1) double = []
        SignalAverage (1,1) double = NaN
        BGAverage (1,1) double = NaN
        SBRatio (1,1) double = NaN
        
        % Selection and labeling
        Label OOPSLabel
        % the selection status of the object
        Selected (1,1) logical = false

        % SubarrayIdx with padding applied
        paddedSubarrayIdx (1,2) cell
        % 2 element vector of the padding applied to the object SubarrayIdx
        paddedSubarrayIdxAdjustment = []
        % the object mask image padded at least 5 px in both directions, plus additional to make square
        paddedSubImage = []
        % 2-element vector to add to image-frame coordinate to retrieve padded object-frame coordinates
        imageToPaddedObjectShift = []
        % pixel idx list for the padded object
        paddedPixelIdxList (:,1) double = []
        % list of tangents for each pixel in the object
        pixelMidlineTangentList (:,1) double = []

    end % end properties
    
    properties(Dependent = true)

        % list of azimuth pixel values
        AzimuthPixelValues
        % name of the group that to which this object belongs
        GroupName
        % idx of the group to which this object belongs
        GroupIdx
        % name of this object's parent image
        ImageName
        % name of this object's parent image, but with some special characters preceeded by '\'
        texFriendlyImageName

        % various object images
        PaddedOrderSubImage
        MaxScaledOrderSubImage
        MaskedOrderSubImage
        PaddedFFCIntensitySubImage
        PaddedMaskSubImage
        PaddedAzimuthSubImage
        MidlineTangentImage
        MidlineRelativeAzimuthImage
        PaddedAverageIntensityImageNorm

        % x coordinate of the centroid
        CentroidX
        % y coordinate of the centroid
        CentroidY

        % Order properties of this object, dependent on Order image of Parent
        OrderAvg
        OrderMin
        OrderMax
        OrderPixelValues
        
        % object label properties, depend on currently applied label (OOPSLabel object)
        LabelIdx
        LabelName
        LabelColor
        LabelColorSquare

        % index of this object in its parent 'Object' array
        SelfIdx

        % object name, based on SelfIdx
        Name

        % simplified boundary (may store in memory if becomes useful)
        SimplifiedBoundary

        % the expanded bounding box of this object (left,bottom,width,height)
        expandedBoundingBox

        % the coordinates to the four vertices in the expanded bounding box
        expandedBoundingBoxCoordinates

        % object boundary with respect to the padded object subimage
        paddedSubImageBoundary

        % list of values for each object pixel representing the direction normal to the closest midline point
        pixelMidlineNormalList

        % azimuth stats
        AzimuthAverage
        AzimuthStd
        AzimuthAngularDeviation
        MidlineRelativeAzimuth
        NormalRelativeAzimuth

        % midline stats
        Tortuosity
        MidlineLength
        TangentAverage

        %% Summaries

        ObjectSummaryDisplayTable

        %% RGB output images 

        % horizontal montage object intensity stack, scaled across the stack to [0 1]
        IntensityStackNormMontageRGB
        % unmasked Order
        OrderImageRGB
        % unmasked Order, scaled to parent image max
        MaxScaledOrderImageRGB
        % label image of signal and BG regions
        SBRegionsRGB
        % average intensity image normalized to max
        PaddedAverageIntensityImageNormRGB
        % padded object mask image in RGB format
        MaskImageRGB
        % padded azimuth subimage in RGB format
        AzimuthImageRGB
        % padded midline tangent image in RGB format
        MidlineTangentImageRGB
        % padded midline relative azimuth in RGB format
        MidlineRelativeAzimuthImageRGB

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

            % add dynamic properties
            obj.addCustomStatistics();

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
            object.paddedSubImage = sparse(obj.paddedSubImage);
            object.imageToPaddedObjectShift = obj.imageToPaddedObjectShift;
            object.paddedPixelIdxList = obj.paddedPixelIdxList;
            object.pixelMidlineTangentList = obj.pixelMidlineTangentList;

            object.Midline = obj.Midline;

        end

%% dynamic properties

        % add user-defined custom outputs
        function addCustomStatistics(obj)
            
            % get the vector of custom statistic objects
            customStatistics = obj.Parent.Settings.CustomStatistics;

            for i = 1:numel(customStatistics)
                thisStatistic = customStatistics(i);
                % add a custom prop with name specified by the custom statistic object
                prop = obj.addprop(thisStatistic.StatisticName);
                % make the property dependent
                prop.Dependent = true;
                % set the Get method for this property, pass in the property name so we know how to calculate it
                prop.GetMethod = @(o) getCustomObjectStatistic(o,thisStatistic.StatisticName);
            end

        end

        function value = getCustomObjectStatistic(obj,statisticName)

            parentData = obj.Parent.([statisticName,'Image']);

            % average value across all object pixels
            try
                value = mean(parentData(obj.PixelIdxList));
            catch
                value = NaN;
            end

        end

%% object identifiers (idxs, labels, etc)

        function SelfIdx = get.SelfIdx(obj)
            SelfIdx = find(obj.Parent.Object==obj);
        end

        function Name = get.Name(obj)
            Name = ['Object ',num2str(obj.SelfIdx)];
        end

        function LabelIdx = get.LabelIdx(obj)
            LabelIdx = obj.Label.SelfIdx;
        end
        
        function LabelName = get.LabelName(obj)
            % convert the name of this object's label to a string
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

        function GroupIdx = get.GroupIdx(obj)
            % get the idx of the parent group
            GroupIdx = obj.Parent.Parent.SelfIdx;
        end

        function ImageName = get.ImageName(obj)
            ImageName = categorical({obj.Parent.rawFPMShortName});
        end

        function texFriendlyImageName = get.texFriendlyImageName(obj)
            % testing below
            nameSplit = strsplit(obj.Parent.rawFPMShortName,'_');
            texFriendlyImageName = convertCharsToStrings(strjoin(nameSplit,"\_"));
        end

%% selection status

        function InvertSelection(obj)
            NewSelectionStatus = ~[obj(:).Selected];
            NewSelectionStatus = num2cell(NewSelectionStatus.');
            [obj(:).Selected] = deal(NewSelectionStatus{:});
        end

%% position coordinates, bounding boxes, subarray idxs

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

        function CentroidX = get.CentroidX(obj)
            CentroidX = obj.Centroid(1);
        end

        function CentroidY = get.CentroidY(obj)
            CentroidY = obj.Centroid(2);
        end    

        function expandedBoundingBox = get.expandedBoundingBox(obj)
            expandedBoundingBox = ExpandBoundingBox(obj.BoundingBox,4);
        end

        function expandedBoundingBoxCoordinates = get.expandedBoundingBoxCoordinates(obj)
            BB = obj.expandedBoundingBox;

            x = BB(1);
            y = BB(2);
            width = BB(3);
            height = BB(4);

            expandedBoundingBoxCoordinates = [ ...
                x y; ...
                x+width y; ...
                x+width y+height; ...
                x y+height ...
                ];
        end

%% value lists (same order as pixel idx list)

        function OrderPixelValues = get.OrderPixelValues(obj)
            % list of Order in all object pixels
            try
                OrderPixelValues = obj.Parent.OrderImage(obj.PixelIdxList);
            catch
                OrderPixelValues = NaN;
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

        function pixelMidlineNormalList = get.pixelMidlineNormalList(obj)
            if isempty(obj.pixelMidlineTangentList)
                pixelMidlineNormalList = [];
                return
            end
            pixelMidlineNormalList = obj.pixelMidlineTangentList+pi/2;
            pixelMidlineNormalList(pixelMidlineNormalList>(pi/2)) = pixelMidlineNormalList(pixelMidlineNormalList>(pi/2))-pi;
        end
        
%% scalar output values

        function OrderAvg = get.OrderAvg(obj)
            % average Order of all pixels identified by the mask
            try
                OrderAvg = mean(obj.Parent.OrderImage(obj.PixelIdxList));
            catch
                OrderAvg = NaN;
            end
        end
        
        function OrderMax = get.OrderMax(obj)
            % max Order of all pixels in the object mask
            try
                OrderMax = max(obj.Parent.OrderImage(obj.PixelIdxList));
            catch
                OrderMax = NaN;
            end
        end
        
        function OrderMin = get.OrderMin(obj)
            % min Order of all pixels in the object mask
            try
                OrderMin = min(obj.Parent.OrderImage(obj.PixelIdxList));
            catch
                OrderMin = NaN;
            end
        end

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
        
%% summaries

        function ObjectSummaryDisplayTable = get.ObjectSummaryDisplayTable(obj)

            varNames = [...
                "Name",...
                "Label",...
                "Mean order",...
                "Mean azimuth",...
                "Mean azimuth (midline)",...
                "Mean azimuth (normal)",...
                "Azimuth circular SD",...
                "Local S/B",...
                "Area",...
                "Convex area",...
                "Perimeter",...
                "Circularity",...
                "Eccentricity",...
                "Extent",...
                "Solidity",...
                "Mean signal intensity",...
                "Mean BG intensity",...
                "Index",...
                "Tortuosity",...
                "Midline length",...
                "Mean midline tangent"];

            ObjectSummaryDisplayTable = table(...
                {obj.Name},...
                {obj.Label.Name},...
                {sprintf('%.2f',obj.OrderAvg)},...
                {sprintf('%.2f°',obj.AzimuthAverage)},...
                {sprintf('%.2f°',obj.MidlineRelativeAzimuth)},...
                {sprintf('%.2f°',obj.NormalRelativeAzimuth)},...
                {sprintf('%.2f°',obj.AzimuthStd)},...
                {sprintf('%.2f',obj.SBRatio)},...
                {sprintf('%d px',obj.Area)},...
                {sprintf('%d px',obj.ConvexArea)},...
                {sprintf('%.2f px',obj.Perimeter)},...
                {sprintf('%.2f',obj.Circularity)},...
                {sprintf('%.2f',obj.Eccentricity)},...
                {sprintf('%.2f',obj.Extent)},...
                {sprintf('%.2f',obj.Solidity)},...
                {sprintf('%d A.U.',round(obj.SignalAverage))},...
                {sprintf('%d A.U.',round(obj.BGAverage))},...
                {sprintf('%d',obj.SelfIdx)},...
                {sprintf('%.2f',obj.Tortuosity)},...
                {sprintf('%.2f px',obj.MidlineLength)},...
                {sprintf('%.2f°',obj.TangentAverage)},...
                'VariableNames',varNames,...
                'RowNames',"Object");

            % ObjectSummaryDisplayTable = table(...
            %     {obj.Name},...
            %     {obj.Label.Name},...
            %     {obj.OrderAvg},...
            %     {obj.AzimuthAverage},...
            %     {obj.MidlineRelativeAzimuth},...
            %     {obj.NormalRelativeAzimuth},...
            %     {obj.AzimuthStd},...
            %     {obj.SBRatio},...
            %     {obj.Area},...
            %     {obj.ConvexArea},...
            %     {obj.Perimeter},...
            %     {obj.Circularity},...
            %     {obj.Eccentricity},...
            %     {obj.Extent},...
            %     {obj.Solidity},...
            %     {obj.SignalAverage},...
            %     {obj.BGAverage},...
            %     {obj.SelfIdx},...
            %     {obj.Tortuosity},...
            %     {obj.MidlineLength},...
            %     {obj.TangentAverage},...
            %     'VariableNames',varNames,...
            %     'RowNames',"Object");


            ObjectSummaryDisplayTable = rows2vars(ObjectSummaryDisplayTable,"VariableNamingRule","preserve");

            ObjectSummaryDisplayTable.Properties.RowNames = varNames;

        end

%% object subimages

        function PaddedOrderSubImage = get.PaddedOrderSubImage(obj)
            PaddedOrderSubImage = obj.Parent.OrderImage(obj.paddedSubarrayIdx{:});
        end        

        function MaxScaledOrderSubImage = get.MaxScaledOrderSubImage(obj)
            MaxScaledOrderSubImage = obj.Parent.MaxScaledOrderImage(obj.paddedSubarrayIdx{:});
        end

        function MaskedOrderSubImage = get.MaskedOrderSubImage(obj)
            % OrderImage = obj.Parent.OrderImage;
            MaskedOrderSubImage = zeros(size(obj.Image));
            % masked
            MaskedOrderSubImage(obj.Image) = obj.Parent.OrderImage(obj.PixelIdxList);
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

        function MidlineTangentImage = get.MidlineTangentImage(obj)
            MidlineTangentImage = zeros(size(obj.paddedSubImage));
            MidlineTangentImage(obj.paddedPixelIdxList) = obj.pixelMidlineTangentList;
        end

        function MidlineRelativeAzimuthImage = get.MidlineRelativeAzimuthImage(obj)
            azimuthValues = obj.AzimuthPixelValues;
            tangentValues = obj.pixelMidlineTangentList;

            if isempty(azimuthValues)
                error(['Azimuth data missing for Object ',num2str(obj.SelfIdx)]);
            elseif isempty(tangentValues)
                error(['Midline tangent missing for Object ',num2str(obj.SelfIdx)]);
            end

            MidlineRelativeAzimuthImage = zeros(size(obj.paddedSubImage));
            MidlineRelativeAzimuthImage(obj.paddedPixelIdxList) = angle(exp(2i*azimuthValues)./exp(2i*tangentValues))*0.5;
        end

%% RGB output images

        function IntensityStackNormMontageRGB = get.IntensityStackNormMontageRGB(obj)
            % get the padded mask image
            paddedMask = obj.paddedSubImage;
            % initialize stack-normalized intensity stack for display
            PaddedObjNormIntensity = zeros([size(paddedMask),4]);
            % get stack-normalized intensity stack for display
            PaddedObjNormIntensity(:) = obj.Parent.ffcFPMStack(obj.paddedSubarrayIdx{:},:);
            % rescale the object intensity stack to the range [0 1]
            PaddedObjNormIntensity = Scale0To1(PaddedObjNormIntensity);
            % show stack-normalized object intensity stack
            IntensityStackNormMontage = [...
                PaddedObjNormIntensity(:,:,1),...
                PaddedObjNormIntensity(:,:,2),...
                PaddedObjNormIntensity(:,:,3),...
                PaddedObjNormIntensity(:,:,4)];
            % convert to RGB
            IntensityStackNormMontageRGB = ind2rgb(im2uint8(IntensityStackNormMontage),obj.Parent.Settings.IntensityColormap);
        end

        function OrderImageRGB = get.OrderImageRGB(obj)
            OrderImageRGB = ind2rgb(im2uint8(obj.PaddedOrderSubImage),obj.Parent.Settings.OrderColormap);
        end

        function MaxScaledOrderImageRGB = get.MaxScaledOrderImageRGB(obj)
            MaxScaledOrderImageRGB = ind2rgb(im2uint8(obj.MaxScaledOrderSubImage),obj.Parent.Settings.OrderColormap);
        end

        function SBRegionsRGB = get.SBRegionsRGB(obj)

            parentSize = size(obj.Parent.bw);
            objSize = size(obj.paddedSubImage);
            SBRegions = zeros(objSize);

            [signalR,signalC] = ind2sub(parentSize,obj.PixelIdxList);
            signalR = signalR + obj.imageToPaddedObjectShift(1);
            signalC = signalC + obj.imageToPaddedObjectShift(2);

            [bgR,bgC] = ind2sub(parentSize,obj.BGIdxList);
            bgR = bgR + obj.imageToPaddedObjectShift(1);
            bgC = bgC + obj.imageToPaddedObjectShift(2);

            signalIdx = sub2ind(objSize,signalR,signalC);
            bgIdx = sub2ind(objSize,bgR,bgC);

            SBRegions(signalIdx) = 1;
            SBRegions(bgIdx) = 2;

            % for red and green signal and BG on black background
            %SBRegionsRGB = label2rgb(SBRegions,[1 0 0;0 1 0],[0 0 0]);
            SBRegionsRGB = label2rgb(SBRegions);
        end

        function PaddedAverageIntensityImageNorm = get.PaddedAverageIntensityImageNorm(obj)
            % flatfield-corrected intensity subimage, scaled to the range [0 1]
            PaddedAverageIntensityImageNorm = obj.Parent.I(obj.paddedSubarrayIdx{:});
            PaddedAverageIntensityImageNorm = Scale0To1(PaddedAverageIntensityImageNorm);
        end

        function PaddedAverageIntensityImageNormRGB = get.PaddedAverageIntensityImageNormRGB(obj)
            PaddedAverageIntensityImageNormRGB = ...
                ind2rgb(im2uint8(obj.PaddedAverageIntensityImageNorm),obj.Parent.Settings.IntensityColormap);
        end

        function MaskImageRGB = get.MaskImageRGB(obj)
            MaskImageRGB = ind2rgb(im2uint8(obj.paddedSubImage),gray);
        end

        function AzimuthImageRGB = get.AzimuthImageRGB(obj)
            AzimuthData = obj.PaddedAzimuthSubImage;
            % values originally in [-pi/2 pi/2], adjust to fall in [0 pi]
            AzimuthData(AzimuthData<0) = AzimuthData(AzimuthData<0)+pi;
            % scale values to [0 1]
            AzimuthData = AzimuthData./pi;
            % convert to uint8 then to RGB
            AzimuthImageRGB = ind2rgb(im2uint8(AzimuthData),obj.Parent.Settings.AzimuthColormap);
        end

        function MidlineTangentImageRGB = get.MidlineTangentImageRGB(obj)
            % get the midline tangent image
            midlineTangentImage = obj.MidlineTangentImage;
            % values originally in [-pi/2 pi/2], adjust to fall in [0 pi]
            midlineTangentImage(midlineTangentImage<0) = midlineTangentImage(midlineTangentImage<0)+pi;
            % scale values to [0 1]
            midlineTangentImage = midlineTangentImage./pi;
            % convert to uint8 then to RGB
            MidlineTangentImageRGB = ind2rgb(im2uint8(midlineTangentImage),obj.Parent.Settings.AzimuthColormap);
            % now apply object mask (values outside the mask are always 0 and have no meaning)
            MidlineTangentImageRGB = MaskRGB(MidlineTangentImageRGB,obj.paddedSubImage);
        end

        function MidlineRelativeAzimuthImageRGB = get.MidlineRelativeAzimuthImageRGB(obj)
            midlineRelativeAzimuthImage = obj.MidlineRelativeAzimuthImage;
            % values originally in [-pi/2 pi/2], adjust to fall in [0 pi]
            midlineRelativeAzimuthImage(midlineRelativeAzimuthImage<0) = midlineRelativeAzimuthImage(midlineRelativeAzimuthImage<0)+pi;
            % scale values to [0 1]
            midlineRelativeAzimuthImage = midlineRelativeAzimuthImage./pi;
            % convert to uint8 then to RGB
            MidlineRelativeAzimuthImageRGB = ind2rgb(im2uint8(midlineRelativeAzimuthImage),obj.Parent.Settings.AzimuthColormap);
            % now apply object mask (values outside the mask are always 0 and have no meaning)
            MidlineRelativeAzimuthImageRGB = MaskRGB(MidlineRelativeAzimuthImageRGB,obj.paddedSubImage);
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
            ObjectProps.paddedSubImage = full(object.paddedSubImage);
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
            obj = OOPSObject(ObjectProps,object.Parent,ObjectLabel);

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