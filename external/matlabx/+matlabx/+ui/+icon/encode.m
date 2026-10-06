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

function name = encode(options)
%ENCODE Describe an icon as a versioned basename, without accessing files.
%   name = matlabx.ui.icon.encode(Color=rgb,Size=16) returns a name such as
%   "v1-circle-0072BD-16.svg". RGB values are rounded to eight-bit channels.
%   Decode returns those quantized values, not the original precision.
%   The version identifies rendering semantics as well as filename syntax.

    arguments
        options.Shape (1,1) string {mustBeMember(options.Shape,"circle")} = "circle"
        options.Color (1,3) double {mustBeReal,mustBeFinite,mustBeInRange(options.Color,0,1)} = [0 0.4470 0.7410]
        options.Size (1,1) double {mustBeReal,mustBeFinite,mustBeInteger,mustBePositive} = 16
    end

    hex = upper(string(sprintf('%02X%02X%02X',round(255*options.Color))));
    name = "v1-" + options.Shape + "-" + hex + "-" + ...
        string(sprintf('%.0f',options.Size)) + ".svg";
end
