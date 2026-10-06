% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Object < handle
%OBJECT An immutable pixel region with stored scalar analysis results.
% PixelIdxList is authoritative. Bounds are a small derived geometry cache.
% Measurements are populated explicitly by analysis, never by display getters.
    %% Identity and membership

    properties (SetAccess=private)
        ID (1,1) string = ""
        Parent (:,1) oops.model.Image = oops.model.Image.empty(0,1)
        PixelIdxList (:,1) double
        TightBoundsRC (2,2) double % Inclusive [rowMin rowMax; colMin colMax].
        LabelID (1,1) string = "unlabeled"
    end

    %% Scalar analysis results (NaN means not yet measured)
    properties (SetAccess=private)
        Area (1,1) double = NaN % Object area, in pixels.
        Circularity (1,1) double = NaN % Dimensionless circularity.
        ConvexArea (1,1) double = NaN % Convex hull area, in pixels.
        Eccentricity (1,1) double = NaN % Dimensionless ellipse eccentricity.
        EquivDiameter (1,1) double = NaN % Equivalent circular diameter, in pixels.
        Extent (1,1) double = NaN % Fraction of bounding box occupied.
        FilledArea (1,1) double = NaN % Hole-filled area, in pixels.
        MajorAxisLength (1,1) double = NaN % Fitted major axis length, in pixels.
        MinorAxisLength (1,1) double = NaN % Fitted minor axis length, in pixels.
        Perimeter (1,1) double = NaN % Perimeter, in pixels.
        Solidity (1,1) double = NaN % Area divided by convex area.
        MaxFeretDiameter (1,1) double = NaN % Maximum caliper diameter, in pixels.
        MinFeretDiameter (1,1) double = NaN % Minimum caliper diameter, in pixels.
        CentroidX (1,1) double = NaN % Centroid column in parent-image coordinates.
        CentroidY (1,1) double = NaN % Centroid row in parent-image coordinates.
        SignalAverage (1,1) double = NaN % Mean signal intensity in the analysis input units.
        BGAverage (1,1) double = NaN % Mean local background intensity.
        SBRatio (1,1) double = NaN % Mean signal divided by mean background.
        OrderAvg (1,1) double = NaN % Mean orientational order.
        OrderStd (1,1) double = NaN % Standard deviation of order.
        OrderMin (1,1) double = NaN % Minimum orientational order.
        OrderMax (1,1) double = NaN % Maximum orientational order.
        AzimuthAverage (1,1) double = NaN % Axial mean azimuth, in degrees.
        AzimuthStd (1,1) double = NaN % Axial circular standard deviation, in degrees.
        AzimuthAngularDeviation (1,1) double = NaN % Axial angular deviation, in degrees.
        MidlineRelativeAzimuth (1,1) double = NaN % Axial mean relative to the midline, in degrees.
        NormalRelativeAzimuth (1,1) double = NaN % Axial mean relative to the midline normal, in degrees.
        MidlineLength (1,1) double = NaN % Midline length, in pixels.
        Tortuosity (1,1) double = NaN % Midline length divided by endpoint distance.
        Orientation (1,1) double = NaN % Axial mean midline tangent direction, in degrees.
    end

    properties (Dependent, SetAccess=private)
        SummaryTable (:,:) table
        BoundingBox % [x y width height], pixel-edge coordinates.
        SelfIdx
        GroupIdx
        GroupName
        ImageName
        Name
        Label
    end

    properties (Dependent)
        Selected
    end

    %% Model events
    events
        DataChanged
    end

    %% Construction
    methods (Access=?oops.model.Image)

        function obj = Object(parent,pixels)
        %OBJECT Create one region from a validated parent-mask partition.

            obj.ID = matlabx.utils.text.uniqueID();
            obj.Parent = parent;
            obj.PixelIdxList = double(pixels(:));

            % Parent-image row and column coordinates used to derive tight bounds.
            [r,c] = ind2sub([parent.Input.SizeY,parent.Input.SizeX],obj.PixelIdxList);
            obj.TightBoundsRC = [min(r),max(r);min(c),max(c)];
        end

    end

    %% Identity and parent metadata
    methods

        function idx = get.SelfIdx(obj)
        %GET.SELFIDX Return this object's current position within its parent.

            % Index of this member in its owning collection; empty if not found.
            idx = find(obj.Parent.Objects == obj,1);
        end

        function idx = get.GroupIdx(obj)
        %GET.GROUPIDX Return the parent group's position, or [] if detached.

            % Group index, initially empty for an object with no attached project.
            idx = [];

            % Parent group reached through this object's owning image.
            group = obj.Parent.Parent;

            if ~isempty(group) && ~isempty(group.Parent)
                idx = find(group.Parent.Groups == group,1);
            end

        end

        function value = get.GroupName(obj)
        %GET.GROUPNAME Return the owning group's name, or empty if detached.

            value = "";

            if ~isempty(obj.Parent.Parent)
                value = obj.Parent.Parent.Name;
            end

        end

        function value = get.ImageName(obj)
        %GET.IMAGENAME Return the owning image's name.

            value = obj.Parent.Name;
        end

        function value = get.Name(obj)
        %GET.NAME Return a presentation name from the current object index.

            value = "Object " + string(obj.SelfIdx);
        end

    end

    %% Selection metadata
    methods

        function value = get.Selected(obj)
        %GET.SELECTED Return selection metadata without owning UI components.

            value = ismember(obj.ID,obj.Parent.SelectedObjectIDs);
        end

        function set.Selected(obj,value)
        %SET.SELECTED Store selection metadata and notify model listeners.

            try
                validateattributes(value,{'logical'},{'scalar'});

                % This object's selection state before updating the parent ID set.
                old = obj.Selected;

                % Copy of the parent image's selected IDs, edited to include/exclude this object.
                ids = obj.Parent.SelectedObjectIDs;
                ids(ids == obj.ID) = [];

                if value
                    ids(end+1,1) = obj.ID;
                end

                % The parent owns the canonical selected-ID set.
                obj.Parent.setSelectedObjects(ids);

                if old ~= obj.Selected
                    obj.changed("ObjectSelection");
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Object labeling
    methods

        function label = get.Label(obj)
        %GET.LABEL Resolve the stored label ID through the owning project registry.

            label = oops.model.ObjectLabel.empty(0,1);

            if isempty(obj.Parent) || isempty(obj.Parent.Parent) || ...
                    isempty(obj.Parent.Parent.Parent)
                return;
            end

            label = obj.Parent.Parent.Parent.Labels.getByID(obj.LabelID);
        end

        function setLabel(obj,label)
        %SETLABEL Delegate label assignment to the parent for a batched model update.

            obj.Parent.setObjectLabels(obj,label);
        end

    end

    %% Stored scalar measurements
    methods

        function setMeasurements(obj,values)
        %SETMEASUREMENTS Store a partial scalar result struct after validation.
        %
        % Validate every supplied field before modifying any result. A bad
        % field cannot leave the object with a partially updated measurement set.

            try
                validateattributes(values,{'struct'},{'scalar'});

                % Names of the scalar measurement fields to read or update.
                names = fieldnames(values);

                % Scalar measurement fields accepted by this object.
                allowed = obj.measurementNames();

                % Validate each supplied field name and scalar value before updating anything.
                for k = 1:numel(names)

                    if ~ismember(string(names{k}),allowed)
                        error('oops:model:UnknownMeasurement','Unknown scalar measurement: %s',names{k});
                    end

                    validateattributes(values.(names{k}),{'numeric'},{'scalar','real'});
                end

                % All fields passed validation; now commit them as one update.

                % Copy the validated measurement values into the object's stored properties.
                for k = 1:numel(names)
                    obj.(names{k}) = double(values.(names{k}));
                end

                if ~isempty(names)
                    obj.changed("ObjectMeasurements");
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function values = getMeasurements(obj)
        %GETMEASUREMENTS Return stored scalar results without running analysis.

            % Struct collecting this object's stored scalar measurement fields.
            values = struct();

            % Copy each stored measurement field into the output struct.
            for name = obj.measurementNames()
                values.(name) = obj.(name);
            end

        end

        function resetMeasurements(obj,names)
        %RESETMEASUREMENTS Mark all or specified stored results as unavailable.

            if nargin < 2

                % Names of the scalar measurement fields to read or update.
                names = obj.measurementNames();
            end

            try
                names = reshape(string(names),1,[]);

                if any(~ismember(names,obj.measurementNames()))
                    error('oops:model:UnknownMeasurement','Unknown scalar measurement in reset request.');
                end

                % Set each requested measurement field to NaN to mark it unavailable.
                for name = names
                    obj.(name) = NaN;
                end

                if ~isempty(names)
                    obj.changed("ObjectMeasurements");
                end

            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Geometry and transient crops
    methods

        function box = get.BoundingBox(obj)
        %GET.BOUNDINGBOX Convert inclusive pixel bounds to pixel-edge geometry.

            % Inclusive row/column bounds cached from this object's pixel membership.
            b = obj.TightBoundsRC;

            % Pixel-edge rectangle expressed as [x y width height].
            box = [b(2,1)-0.5,b(1,1)-0.5,b(2,2)-b(2,1)+1,b(1,2)-b(1,1)+1];
        end

        function geometry = getCropGeometry(obj,opts)
        %GETCROPGEOMETRY Describe a padded crop independently of image contents.

            arguments
                obj
                opts.Margin (1,1) double {mustBeNonnegative,mustBeInteger,mustBeFinite} = 5
                opts.Square (1,1) logical = true
            end

            % Padded crop window, optionally squared, in parent-image coordinates.
            geometry = oops.geometry.Crop.aroundBounds(obj.TightBoundsRC, ...
                [obj.Parent.Input.SizeY,obj.Parent.Input.SizeX], ...
                Margin=opts.Margin,Square=opts.Square);
        end

        function [mask,geometry,validMask] = getMask(obj,opts)
        %GETMASK Construct an object-only local mask without reading image data.

            arguments
                obj
                opts.Margin (1,1) double {mustBeNonnegative,mustBeInteger,mustBeFinite} = 0
                opts.Square (1,1) logical = false
            end

            % Crop window used to reconstruct this object's local membership.
            geometry = obj.getCropGeometry(Margin=opts.Margin,Square=opts.Square);

            % Local logical mask containing this object's pixels only.
            mask = obj.maskForGeometry(geometry);

            % Logical crop pixels that fall within the parent image rather than padding.
            validMask = geometry.validMask();
        end

        function [data,geometry,objectMask,validMask] = getCrop(obj,data,opts)
        %GETCROP Extract a numeric parent-image array using shared crop geometry.
        %
        %   [DATA, GEOMETRY, MASK, VALID] = object.getCrop(parentArray)
        %   preserves all trailing array axes and defaults to a square crop
        %   with five pixels of margin. MASK contains only this object.

            arguments
                obj
                data
                opts.Margin (1,1) double {mustBeNonnegative,mustBeInteger,mustBeFinite} = 5
                opts.Square (1,1) logical = true
                opts.FillValue (1,1) double = 0
            end

            try

                % Crop window shared by the numeric data and returned membership masks.
                geometry = obj.getCropGeometry(Margin=opts.Margin,Square=opts.Square);
                data = geometry.extract(data,FillValue=opts.FillValue);

                % Membership and valid image extent are separate: padding is
                % outside the image, while nearby objects are not this object.

                % Local logical membership mask excluding neighboring objects.
                objectMask = obj.maskForGeometry(geometry);

                % Logical crop pixels within the parent image's valid extent.
                validMask = geometry.validMask();
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

        function [input,geometry,objectMask,validMask] = getInputCrop(obj,opts)
        %GETINPUTCROP Build a transient Image5D from selected polarization crops.
        % Reads parent input planes as needed; no crop arrays are stored on Object.

            arguments
                obj
                opts.Frames (1,:) double {mustBeInteger,mustBeInRange(opts.Frames,1,4)} = 1:4
                opts.Margin (1,1) double {mustBeNonnegative,mustBeInteger,mustBeFinite} = 5
                opts.Square (1,1) logical = true
                opts.FillValue (1,1) double = 0
            end

            try

                if isempty(opts.Frames)
                    error('oops:model:EmptyFrameSelection','Select at least one polarization frame.');
                end

                % Crop window shared by every requested polarization plane.
                geometry = obj.getCropGeometry(Margin=opts.Margin,Square=opts.Square);

                % Cell array collecting numeric crops for the requested input angles.
                frames = cell(1,numel(opts.Frames));

                % Read and crop each requested polarization plane into the component array.
                for k = 1:numel(frames)

                    % One parent input plane before extracting its object crop.
                    plane = obj.Parent.getFrame(opts.Frames(k));
                    frames{k} = geometry.extract(plane,FillValue=opts.FillValue);
                end

                % Component names identifying the polarization angle of each cropped plane.
                names = string(obj.Parent.PolarizationAngles(opts.Frames)) + " deg";

                % Transient Image5D wrapping the extracted polarization crops.
                input = matlabx.image.Image5D.fromComponents(frames,Names=names);

                % Membership and valid image extent are separate: padding is
                % outside the image, while nearby objects are not this object.

                % Local logical membership mask excluding neighboring objects.
                objectMask = obj.maskForGeometry(geometry);

                % Logical crop pixels within the parent image's valid extent.
                validMask = geometry.validMask();
            catch ME
                oops.Log.EXCEPTION(ME);
                rethrow(ME);
            end
        end

    end

    %% Derived summaries
    methods

        function T = get.SummaryTable(obj)
        %GET.SUMMARYTABLE Format stored scalar measurements without recomputing them.
        % Midline and reference-image fields remain deferred until their pipelines
        % exist. NaN remains visible for measurements not yet available.

            % Row labels for the scalar object measurements currently supported.
            names = ["Name","Label","Mean order","Mean azimuth","Azimuth circular SD", ...
                "Local S/B","Area","Convex area","Perimeter","Circularity", ...
                "Eccentricity","Extent","Solidity","Mean signal intensity", ...
                "Mean BG intensity","Index"];

            % Formatted identity, morphology, intensity, and polarization values.
            label = obj.Label;

            if isempty(label)
                labelName = obj.LabelID;
            else
                labelName = label.Name;
            end

            values = {obj.Name,labelName,sprintf('%.2f',obj.OrderAvg), ...
                sprintf('%.2f°',obj.AzimuthAverage),sprintf('%.2f°',obj.AzimuthStd), ...
                sprintf('%.2f',obj.SBRatio),sprintf('%g px²',obj.Area), ...
                sprintf('%g px²',obj.ConvexArea),sprintf('%.2f px',obj.Perimeter), ...
                sprintf('%.2f',obj.Circularity),sprintf('%.2f',obj.Eccentricity), ...
                sprintf('%.2f',obj.Extent),sprintf('%.2f',obj.Solidity), ...
                sprintf('%.2f A.U.',obj.SignalAverage),sprintf('%.2f A.U.',obj.BGAverage),obj.SelfIdx};

            % Single-column summary with statistic names supplied as table row names.
            T = oops.model.internal.summaryTable(names,values);
        end

    end

    %% Membership geometry and notifications
    methods (Access=private)

        function mask = maskForGeometry(obj,geometry)
        %MASKFORGEOMETRY Reconstruct membership, excluding neighboring objects.

            % Parent-image coordinates of this object's pixels, excluding neighbors
            % even if they share the requested crop window.
            [r,c] = ind2sub(geometry.ImageSize,obj.PixelIdxList);

            % Those pixel coordinates translated into the requested crop window.
            points = geometry.toLocal([r,c]);

            % Empty local mask to populate from this object's pixel membership.
            mask = false(geometry.Size);
            mask(sub2ind(geometry.Size,points(:,1),points(:,2))) = true;
        end

        function changed(obj,name)
        %CHANGED Notify with both parent image and object identity.

            notify(obj,'DataChanged',oops.model.events.DataChanged(obj.Parent.ID,name,obj.ID));
        end

    end

    methods (Access=?oops.model.Image)

        function assignLabelID(obj,id)
        %ASSIGNLABELID Store a registry-validated label ID without per-object events.

            obj.LabelID = id;
        end

    end

    %% Measurement field catalogs
    methods (Static)

        function names = imageMeasurementNames()
        %IMAGEMEASUREMENTNAMES Scalars invalidated when parent image outputs change.
        % Morphology and midline-only geometry remain valid for immutable pixels.

            % Measurement fields that depend on the parent's intensity or FPM outputs.
            names = ["SignalAverage","BGAverage","SBRatio", ...
                "OrderAvg","OrderStd","OrderMin","OrderMax", ...
                "AzimuthAverage","AzimuthStd","AzimuthAngularDeviation", ...
                "MidlineRelativeAzimuth","NormalRelativeAzimuth"];
        end

        function names = measurementNames()
        %MEASUREMENTNAMES Enumerate scalar results accepted from analysis.

            % Complete list of stored scalar measurements accepted by the model.
            names = ["Area" ...
                "Circularity" ...
                "ConvexArea" ...
                "Eccentricity" ...
                "EquivDiameter" ...
                "Extent" ...
                "FilledArea" ...
                "MajorAxisLength" ...
                "MinorAxisLength" ...
                "Perimeter" ...
                "Solidity" ...
                "MaxFeretDiameter" ...
                "MinFeretDiameter" ...
                "CentroidX" ...
                "CentroidY" ...
                "SignalAverage" ...
                "BGAverage" ...
                "SBRatio" ...
                "OrderAvg" ...
                "OrderStd" ...
                "OrderMin" ...
                "OrderMax" ...
                "AzimuthAverage" ...
                "AzimuthStd" ...
                "AzimuthAngularDeviation" ...
                "MidlineRelativeAzimuth" ...
                "NormalRelativeAzimuth" ...
                "MidlineLength" ...
                "Tortuosity" ...
                "Orientation"];
        end

    end

end
