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

function rgb = getColor(name)
%GETCOLOR  Converts a color name to an RGB triplet
%
%   rgb = GETCOLOR(name) returns the 1x3 RGB vector (values in [0,1])
%   corresponding to the specified color name. The lookup is case-
%   insensitive.
%
%   Supported colors:
%     'red', 'green', 'blue', 'cyan', 'magenta', 'yellow', 'white', 'black'
%
%   Input
%     name : character vector or string scalar specifying the color name
%
%   Output
%     rgb  : 1x3 RGB triplet in [0,1]
%
%   Example
%     rgb = getColor('magenta');   % returns [1 0 1]
%
%   See also COLORGRADIENT

    name = lower(string(name));

    switch name
        case "red"
            rgb = [1 0 0];
        case "green"
            rgb = [0 1 0];
        case "blue"
            rgb = [0 0 1];
        case "cyan"
            rgb = [0 1 1];
        case "magenta"
            rgb = [1 0 1];
        case "yellow"
            rgb = [1 1 0];
        case "white"
            rgb = [1 1 1];
        case "black"
            rgb = [0 0 0];
        otherwise
            error('getColor:UnknownColor', ...
                  'Unknown color "%s". Supported colors: red, green, blue, cyan, magenta, yellow, white, black.', name);
    end
end