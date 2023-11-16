function circlePixels = makeLogicalFilledCircleImage(centerX,centerY,radius,height,width)
%%  MAKELOGICALFILLEDCIRCLEIMAGE return a logical image of user-specified size containing 
%   a circle of True pixels with user-specified center position and radius
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

% use meshgrid to create column and row indices
[columnsInImage,rowsInImage] = meshgrid(1:width, 1:height);

% create 2D logical array containing a circle at the specified location
circlePixels = (rowsInImage-centerY).^2 + (columnsInImage-centerX).^2 <= radius.^2;

end