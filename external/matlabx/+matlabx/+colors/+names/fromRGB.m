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

function [name, matchedRGB] = fromRGB(rgb, options)
%FROMRGB  Converts an RGB triplet to the closest color name
%
%   name = FROMRGB(rgb) returns the closest matching color name from the
%   CSS color palette for the specified 1x3 RGB vector.
%
%   [name, matchedRGB] = FROMRGB(rgb) also returns the RGB triplet
%   associated with the matched color name.
%
%   [...] = FROMRGB(rgb, Palette=palette) specifies the color-name palette
%   used for matching. The default palette is "CSS".
%
%   Input
%     rgb         : 1x3 numeric RGB triplet with values in [0,1]
%
%   Name-Value Input
%     Palette     : String scalar specifying a palette supported by
%                   COLORNAMES. The default is "CSS".
%
%   Output
%     name        : String scalar containing the closest color name
%     matchedRGB  : 1x3 RGB triplet associated with the matched color name
%
%   Example
%     [name, matchedRGB] = fromRGB([0.25 0.48 0.72])
%
%     [name, matchedRGB] = fromRGB([1 0 1], Palette="MATLAB")
%
%   See also COLORNAMES, TORGB

    arguments
        rgb (1,3) {mustBeNumeric, mustBeReal, mustBeFinite, ...
            mustBeGreaterThanOrEqual(rgb,0), ...
            mustBeLessThanOrEqual(rgb,1)}
        options.Palette (1,1) string = "CSS"
    end

    rgb = double(rgb);

    try
        [name, matchedRGB] = colornames(options.Palette, rgb);
    catch ME
        cause = MException( ...
            "matlabx:colors:names:fromRGB:ColorLookupFailed", ...
            'Unable to match RGB triplet %s using the "%s" palette.', ...
            mat2str(rgb), options.Palette);

        cause = addCause(cause, ME);
        throwAsCaller(cause);
    end

end