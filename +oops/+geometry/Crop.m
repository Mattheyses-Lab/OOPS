% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef Crop
%CROP Value object describing an integer window in parent-image coordinates.
%
% BoundsRC is [firstRow lastRow; firstColumn lastColumn]. Bounds can extend
% outside the image. OriginRC is the parent coordinate of local pixel [1 1].
% No image arrays are retained here, and the same geometry can extract every
% raw/output plane and transform coordinates consistently.

    properties (SetAccess=private)
        BoundsRC (2,2) double
        ImageSize (1,2) double
    end

    properties (Dependent, SetAccess=private)
        OriginRC
        Size
    end

    methods

        function obj = Crop(bounds,imageSize)
        %CROP Construct a crop descriptor from inclusive integer pixel bounds.

            validateattributes(bounds,{'numeric'},{'size',[2 2],'real','finite','integer'});
            validateattributes(imageSize,{'numeric'},{'size',[1 2],'real','finite','integer','positive'});

            if any(bounds(:,2) < bounds(:,1))
                error('oops:geometry:InvalidBounds','Crop bounds must have nonnegative spans.');
            end

            obj.BoundsRC = double(bounds);
            obj.ImageSize = double(imageSize);
        end

        function v = get.OriginRC(obj)
        %GET.ORIGINRC Parent-image row/column of the first requested pixel.

            v = obj.BoundsRC(:,1)';
        end

        function v = get.Size(obj)
        %GET.SIZE Requested window size, including any out-of-image padding.

            v = (obj.BoundsRC(:,2)-obj.BoundsRC(:,1)+1)';
        end

        function points = toLocal(obj,points)
        %TOLOCAL Convert N-by-2 parent [row column] coordinates to local ones.

            validateattributes(points,{'numeric'},{'2d','ncols',2,'real'});

            % Parent-image [row column] coordinates translated relative to the crop origin.
            points = double(points) - obj.OriginRC + 1;
        end

        function points = toParent(obj,points)
        %TOPARENT Convert N-by-2 local [row column] coordinates to parent ones.

            validateattributes(points,{'numeric'},{'2d','ncols',2,'real'});

            % Local [row column] coordinates translated back to the parent image.
            points = double(points) + obj.OriginRC - 1;
        end

        function mask = validMask(obj)
        %VALIDMASK Mark pixels backed by actual parent-image data.

            % Logical crop pixels that overlap the parent image rather than padding.
            mask = false(obj.Size);

            % Matching parent-image and crop-window row/column ranges.
            [sourceRows,sourceCols,targetRows,targetCols] = obj.overlap();

            if ~isempty(sourceRows) && ~isempty(sourceCols)
                mask(targetRows,targetCols) = true;
            end

        end

        function out = extract(obj,data,opts)
        %EXTRACT Copy the window from an array, preserving class/trailing axes.
        %
        %   OUT = GEOMETRY.extract(DATA,FillValue=0) pads out-of-image pixels.
        %   FillValue must be representable in DATA's class; NaN padding is
        %   supported for floating-point data. Consult validMask for analysis.

            arguments
                obj
                data {mustBeNumericOrLogical}
                opts.FillValue (1,1) double = 0
            end

            if ~isequal([size(data,1),size(data,2)],obj.ImageSize)
                error('oops:geometry:DataSizeMismatch','Data must match the parent image dimensions.');
            end

            % Padding value converted to the numeric/logical class of the input array.
            fill = cast(opts.FillValue,'like',data);

            if (~isfloat(data) && ~isequaln(double(fill),opts.FillValue)) || ...
                    (isfinite(opts.FillValue) && ~isfinite(fill))
                error('oops:geometry:InvalidFillValue','FillValue cannot be represented by %s data.',class(data));
            end

            % Output dimensions with the crop size replacing the first two image axes.
            dimensions = size(data);
            dimensions(1:2) = obj.Size;

            % Padded output array initialized before copying the overlapping image pixels.
            out = repmat(fill,dimensions);

            % Source row/column and target row/column indices of the shared overlap.
            [sr,sc,tr,tc] = obj.overlap();

            if isempty(sr) || isempty(sc)
                return;
            end

            % Subscript cell array selecting the overlap while retaining all trailing axes.
            source = repmat({':'},1,ndims(data));

            % Output subscripts initialized from the source selection, then translated locally.
            target = source;
            source(1:2) = {sr,sc};
            target(1:2) = {tr,tc};
            out(target{:}) = data(source{:});
        end

    end

    methods (Access=private)

        function [sr,sc,tr,tc] = overlap(obj)
        %OVERLAP Resolve matching source and destination row/column indices.

            % Requested inclusive bounds in parent-image row/column coordinates.
            b = obj.BoundsRC;

            % Parent-image rows inside both the image and requested crop window.
            sr = max(1,b(1,1)):min(obj.ImageSize(1),b(1,2));

            % Parent-image columns inside both the image and requested crop window.
            sc = max(1,b(2,1)):min(obj.ImageSize(2),b(2,2));

            % Corresponding local row indices in the output crop.
            tr = sr - b(1,1) + 1;

            % Corresponding local column indices in the output crop.
            tc = sc - b(2,1) + 1;
        end

    end

    methods (Static)

        function obj = aroundBounds(bounds,imageSize,opts)
        %AROUNDBOUNDS Add a margin and optionally make a centered square crop.
        % Odd extra padding goes on the bottom/right for deterministic bounds.

            arguments
                bounds (2,2) double
                imageSize (1,2) double
                opts.Margin (1,1) double {mustBeNonnegative,mustBeInteger,mustBeFinite} = 5
                opts.Square (1,1) logical = true
            end
            % Validate the initial bounds before calculating requested padding.

            % Validated initial crop geometry before applying padding.
            base = oops.geometry.Crop(bounds,imageSize);

            % Requested row/column bounds after adding the margin.
            bounds = base.BoundsRC + [-opts.Margin,opts.Margin];

            if opts.Square

                % Padded height and width used to determine the square extent.
                spans = bounds(:,2)-bounds(:,1)+1;

                % Additional per-axis padding needed to equalize height and width.
                extra = max(spans)-spans;
                bounds(:,1) = bounds(:,1)-floor(extra/2);
                bounds(:,2) = bounds(:,2)+ceil(extra/2);
            end

            % Final crop geometry after optional margin and square padding.
            obj = oops.geometry.Crop(bounds,imageSize);
        end

    end
end
