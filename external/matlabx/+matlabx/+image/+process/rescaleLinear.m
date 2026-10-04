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

function Iscaled = rescaleLinear(I, inRange)
%RESCALELINEAR  Linearly rescale values in I such that inRange maps to [0 1]
%   Maps values in I from inRange = [inLow inHigh] to [0 1] 
%   using linear scaling. Values outside inRange are clipped to [0 1]
%
%   SYNTAX:
%       Iscaled = utils.rescaleLinear(I, inRange)
%
%   INPUTS:
%       I        - numeric array (any shape)
%       inRange  - [low high] in input units
%
%   OUTPUT:
%       Iscaled  - double array, same size as I
%
%   See also: clip

    Iscaled = clip((double(I) - inRange(1)) / (inRange(2) - inRange(1)), 0, 1);
    
end