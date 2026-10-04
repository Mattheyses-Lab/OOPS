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

function colorOut = getBWContrastColor(colorIn)
%%GETBWCONTRASTCOLOR  Given an RGB triplet, determine whether it contrasts more with black or white

    if mean(colorIn,"all") < 0.5 % dark color
        colorOut = [1 1 1]; % return white
    else % bright color
        colorOut = [0 0 0]; % return black
    end
    
end