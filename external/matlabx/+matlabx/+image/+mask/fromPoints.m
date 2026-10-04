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

function mask = fromPoints(points,sz)
%FROMPOINTS Generate binary mask with size, sz, using the coordinates in points
%
% mask = matlabx.image.mask.fromPoints(points, sz)
%
% Inputs
%   points  : Nx2 array of (x,y) coordinates
%   sz      : size of the output
%
% Output
%   mask    : logical mask containing pixels closest to pts

% preallocate mask
mask = false(sz);
% convert points to linear px idxs
idx = sub2ind(sz, round(points(:,2)), round(points(:,1)));
% add to mask
mask(idx) = true;

end