classdef ImageMetadata
    %IMAGEMETADATA Normalized descriptive and calibration metadata for Image5D.
    %
    %   MD = matlabx.image.ImageMetadata() creates empty metadata. Structural
    %   image facts such as dimensions, pixel class, component names, and
    %   component colors remain authoritative on Image5D and ImageComponent.
    %
    %   MD = matlabx.image.ImageMetadata(Name=Value) specifies portable
    %   metadata that can be shared by memory-backed and file-backed images.
    %   Unknown source metadata remains available through Image5D properties
    %   such as OriginalMetadata and OMEMetadata.

% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

    properties
        % ImageName is the portable display name for the image or series.
        ImageName (1,1) string = ""

        % Description is free-form descriptive text for the image.
        Description (1,1) string = ""

        % PhysicalSizeX is the physical width of one pixel, or NaN if unknown.
        PhysicalSizeX (1,1) double {mustBePositiveOrNaN_} = NaN

        % PhysicalSizeY is the physical height of one pixel, or NaN if unknown.
        PhysicalSizeY (1,1) double {mustBePositiveOrNaN_} = NaN

        % PhysicalSizeZ is the physical distance between Z planes, or NaN.
        PhysicalSizeZ (1,1) double {mustBePositiveOrNaN_} = NaN

        % PhysicalSizeXUnit is the unit associated with PhysicalSizeX.
        PhysicalSizeXUnit (1,1) string = ""

        % PhysicalSizeYUnit is the unit associated with PhysicalSizeY.
        PhysicalSizeYUnit (1,1) string = ""

        % PhysicalSizeZUnit is the unit associated with PhysicalSizeZ.
        PhysicalSizeZUnit (1,1) string = ""

        % TimeIncrement is the interval between T positions, or NaN.
        TimeIncrement (1,1) double {mustBeNonnegativeOrNaN_} = NaN

        % TimeIncrementUnit is the unit associated with TimeIncrement.
        TimeIncrementUnit (1,1) string = ""
    end

    methods
        function obj = ImageMetadata(opts)
            %IMAGEMETADATA Construct normalized image metadata.
            arguments
                opts.ImageName (1,1) string = ""
                opts.Description (1,1) string = ""
                opts.PhysicalSizeX (1,1) double = NaN
                opts.PhysicalSizeY (1,1) double = NaN
                opts.PhysicalSizeZ (1,1) double = NaN
                opts.PhysicalSizeUnit (1,1) string = ""
                opts.PhysicalSizeXUnit (1,1) string = ""
                opts.PhysicalSizeYUnit (1,1) string = ""
                opts.PhysicalSizeZUnit (1,1) string = ""
                opts.TimeIncrement (1,1) double = NaN
                opts.TimeIncrementUnit (1,1) string = ""
            end

            obj.ImageName = opts.ImageName;
            obj.Description = opts.Description;
            obj.PhysicalSizeX = opts.PhysicalSizeX;
            obj.PhysicalSizeY = opts.PhysicalSizeY;
            obj.PhysicalSizeZ = opts.PhysicalSizeZ;
            obj.TimeIncrement = opts.TimeIncrement;
            obj.TimeIncrementUnit = opts.TimeIncrementUnit;

            commonUnit = opts.PhysicalSizeUnit;
            obj.PhysicalSizeXUnit = chooseUnit_(opts.PhysicalSizeXUnit, commonUnit);
            obj.PhysicalSizeYUnit = chooseUnit_(opts.PhysicalSizeYUnit, commonUnit);
            obj.PhysicalSizeZUnit = chooseUnit_(opts.PhysicalSizeZUnit, commonUnit);
        end
    end
end

function mustBePositiveOrNaN_(value)
    if ~(isnan(value) || (isfinite(value) && value > 0))
        error('matlabx:image:ImageMetadata:InvalidPhysicalSize', ...
            'Physical sizes must be positive finite values or NaN.');
    end
end

function mustBeNonnegativeOrNaN_(value)
    if ~(isnan(value) || (isfinite(value) && value >= 0))
        error('matlabx:image:ImageMetadata:InvalidTimeIncrement', ...
            'TimeIncrement must be a nonnegative finite value or NaN.');
    end
end

function unit = chooseUnit_(axisUnit, commonUnit)
    if strlength(axisUnit) > 0
        unit = axisUnit;
    else
        unit = commonUnit;
    end
end
