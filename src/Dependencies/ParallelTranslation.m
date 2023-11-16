function [x3,x4,y3,y4] = ParallelTranslation(x1,x2,y1,y2,d)
% performs parallel translation of line segment with points (x1,y1),(x2,y2),
%   where d is the orthogonal distance between the input and output segments
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

    % length of the line segment (distance between points)
    r = sqrt((x2-x1)^2+(y2-y1)^2);
    % determine the value by which to shift x and y coordinates
    deltax = (d/r)*(y1-y2);
    deltay = (d/r)*(x2-x1);
    % get the new coordinates by applying x and y shifts
    x3 = x1+deltax;
    y3 = y1+deltay;
    x4 = x2+deltax;
    y4 = y2+deltay;
end