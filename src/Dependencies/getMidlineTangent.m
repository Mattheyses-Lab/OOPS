function midlineTangent = getMidlineTangent(Midline)
% given an mx2 array of (x,y) coordinates representing an unclosed curve, 
% return an mx1 array of estimated curve tangent angles in radians [-pi/2 pi/2]
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

%% new method

    if any(isnan(Midline))
        midlineTangent = [];
        return
    end

    nPoints = size(Midline,1);

    % the distance (in idx) to the points on either side of the measurement point
    flankingPointsTangent = 1;
    % extend and wrap the curve onto itself to handle the endpoints
    wrappedCurveTangent = [Midline(end-flankingPointsTangent:end-1,:); Midline(1:end,:); Midline(2:flankingPointsTangent+1,:)];
    % idxs of flanking points to the left of our measurement points
    point1Idx = 1:nPoints;
    % idxs of flanking points to the right of our measurement points
    point3Idx = point1Idx+2*flankingPointsTangent;
    % (x,y) coordinates of the flanking points themselves
    point1 = wrappedCurveTangent(point1Idx,:);
    point3 = wrappedCurveTangent(point3Idx,:);

    %% estimate the tangent at each point (in the range [0 pi] measured CCW from the positive x-axis)

    % ***VERY IMPORTANT*** 
    % the following line assumes the origin (x,y) = (0,0) is in the upper-left corner
    % (i.e. the positive y-axis is pointed down, and NOT up as in a normal cartesian coordinate system)
    % this is because for an image with m rows and n columns, the upper left corner would be (1,1) and the
    % lower right corner would be (m,n); y increases as you move down the image, x increases as you 
    % move to the right in the image
    % therefore, we subtract what would be the true tangent in a normal coordinate system from pi
    % to simulate a reflection across the x-axis
    % this is akin to multiplying all the y-coordinates by -1

    midlineTangent = pi - mod(atan2(point1(:,2)-point3(:,2), point1(:,1)-point3(:,1)), pi);

    %% adjust endpoints

    % need to adjust enpoint tangents since this is not a closed curve
    % we do this by setting each endpoint tangent = tangent of the curve at the nearest point
    midlineTangent(1) = midlineTangent(2);
    midlineTangent(end) = midlineTangent(end-1);

    % wrap values to fall in the range [-pi/2, pi/2]
    midlineTangent(midlineTangent>(pi/2)) = midlineTangent(midlineTangent>(pi/2))-pi;

end