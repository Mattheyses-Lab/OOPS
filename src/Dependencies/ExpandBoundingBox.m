function BoundingBox = ExpandBoundingBox(BoundingBox,Padding)
%%  ExpandBoundingBox  Expands bounding box on all sides by a specified amount
%
%   Inputs:
%       BoundingBox: coordinates of a bounding box [x,y,width,height]
%       Padding: number of pixels to add to each side of the bounding box
%
%   Outputs:
%       BoundingBox: padded coordinates of the bounding box
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

    BoundingBox(1) = BoundingBox(1)-Padding;
    BoundingBox(2) = BoundingBox(2)-Padding;
    BoundingBox(3) = BoundingBox(3)+2*Padding;
    BoundingBox(4) = BoundingBox(4)+2*Padding;

end