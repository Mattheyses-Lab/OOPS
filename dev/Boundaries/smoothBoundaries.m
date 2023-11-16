function boundariesSmooth = smoothBoundaries(boundaries)
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

boundariesX = boundaries(:,2);
boundariesY = boundaries(:,1);


% degree of the polynomial and window width for Savitzky-Golay smoothing filter
polynomialOrder = 2;

% get the perimeter of the boundary
%perimeter = getCurveLength(boundaries);

nPoints = numel(boundariesX(:,1));

% windowWidth must be odd and greater than polynomialOrder
boundarySmoothWidth = max(round(nPoints/10),7);

if ~mod(boundarySmoothWidth,2) % if even
    boundarySmoothWidth = boundarySmoothWidth+1; % make odd
end

% smooth out the boundaries so that the majority of vertices within the mask are at the approximate centerline
[boundariesSmoothX,boundariesSmoothY] = sgolayfilt_closedcurve(boundariesX,boundariesY,polynomialOrder,boundarySmoothWidth);

% we want the respaced boundary to have the same number of points
nPointsDesired = numel(boundariesX);

% now re-interpolate
newPoints = interparc(nPointsDesired,boundariesSmoothX,boundariesSmoothY,'linear');

boundariesSmooth = [newPoints(:,2) newPoints(:,1)];

end