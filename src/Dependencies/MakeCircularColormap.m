function MapOut = MakeCircularColormap(MapIn)
%%  MAKECIRCULARCOLORMAP attempts to create a "circular" colormap from the input map, MapIn
%
%   NOTES:
%       The approach taken here is rather rudimentary and should be used with caution. Based on the input colormap,
%       there is a chance that colors will be repeated in the output map, or that the colors between the stitched
%       regions of the map will not be perceptually uniform when compared to the rest of the map.
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

C1 = MapIn(32,:);
C2 = MapIn(224,:);

Rbar = linspace(C2(1),C1(1),64)';
Gbar = linspace(C2(2),C1(2),64)';
Bbar = linspace(C2(3),C1(3),64)';

RGBbar = [Rbar,Gbar,Bbar];

Segment1 = RGBbar(33:end,:);
MidSegment = MapIn(33:224,:);
Segment2 = RGBbar(1:32,:);

MapOut = vertcat(Segment1,MidSegment);
MapOut = vertcat(MapOut,Segment2);

end