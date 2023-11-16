function [smoothX,smoothY] = sgolayfilt_closedcurve(x,y,polynomialOrder, windowWidth)
% Author: Will Dean
% applies Savitsky-Golay filter to x,y coordinates of a closed curve
% x and y must be mx1 column vectors
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

% original number of points
n = length(x);

wrappedX = [x(end-windowWidth:end); x(2:end-1) ; x(1:windowWidth)];
wrappedY = [y(end-windowWidth:end); y(2:end-1) ; y(1:windowWidth)];

smoothX = sgolayfilt(wrappedX, polynomialOrder, windowWidth);
smoothY = sgolayfilt(wrappedY, polynomialOrder, windowWidth);

smoothX = smoothX(windowWidth+1:windowWidth+n);
smoothY = smoothY(windowWidth+1:windowWidth+n);

end