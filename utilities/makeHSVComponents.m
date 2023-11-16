function [h,s,v] = makeHSVComponents(sz)
%%  MAKEHSVCOMPONENTS returns H, S, and V components of an image 
%   showing a square version of the HSV color wheel with a period
%   of 360°
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

%% period of 180°, starts at 0° and increases CCW

% rows = sz;
% columns = sz;
% midX = ceil(columns / 2);
% midY = ceil(rows / 2);
% % Construct v image as uniform matrix of ones
% v = ones(rows, columns);
% s = zeros(size(v));
% h = zeros(size(v));
% % Construct the h image as going from 0 to 1 as the angle goes from 0 to 360.
% % Construct the S image going from 0 at the center to 1 at the edge.
% for c = 1:columns
%     for r = 1:rows
% 	    % Radius goes from 0 to 1 at edge (greater than one in the corners)
% 	    radius = sqrt((r - midY)^2 + (c - midX)^2) / min([midX, midY]);
%         % limit radius to be <= 1
% 	    s(r, c) = min(1, radius);
%         % period of 180°, starts at 0° and increases CCW from positive x axis
%         h(r, c) = atand(-(c-midX)/(midY-r));
%     end
% end
% 
% % rescale values to fall in range [0,1]
% h = mat2gray(h);


%% period of 360°, starts at 0° and increases CCW

rows = sz;
columns = sz;
midX = ceil(columns/2);
midY = ceil(rows/2);
% Construct v image as uniform matrix of ones
v = ones(rows, columns);
s = zeros(size(v));
h = zeros(size(v));
% Construct the h image as going from 0 to 1 as the angle goes from 0 to 360.
% Construct the S image going from 0 at the center to 1 at the edge.
for c = 1:columns
    for r = 1:rows
	    % Radius goes from 0 to 1 at edge (greater than one in the corners)
	    radius = sqrt((r-midY)^2 + (c-midX)^2) / min([midX,midY]);
        % limit radius to be <= 1
	    s(r, c) = min(1, radius);
        % period of 360°, starts at 0° and increases CCW from positive x axis
        h(r, c) = atan2d(-(midY-r),(midX-c));
    end
end

% rescale values to fall in range [0,1]
h = mat2gray(h);

end