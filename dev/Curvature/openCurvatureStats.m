function [curvatureList, tangentList, tortuosity] = openCurvatureStats(curvePoints,flankingPoints)
% this function calculates curvature stats for a closed or open curve
% flankingPoints specifies the spacing between each of the three points used to determine curvature
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

% number of points in the curve
nPoints = length(curvePoints);
% get the length of the curve
curveLength = getCurveLength(curvePoints);
% extend and then wrap the ends of the curve over one another
wrappedCurve = [curvePoints(end-flankingPoints:end-1,:); curvePoints(1:end,:); curvePoints(2:flankingPoints+1,:)];

%% gather the measurement points and flanking points, calculate the slopes needed to build the osculating circles

% the idxs to each set of 3 points in wrappedCurve used to fit the osculating circle
point1Idx = 1:nPoints;
point2Idx = point1Idx+flankingPoints;
point3Idx = point1Idx+flankingPoints*2;
% the (x,y) coordinates to the points themselves
point1 = wrappedCurve(point1Idx,:);
point2 = wrappedCurve(point2Idx,:);
point3 = wrappedCurve(point3Idx,:);
% slopes between points 1 and 2; slopes between points 2 and 3
slope12 = (point1(:,2)-point2(:,2))./(point1(:,1)-point2(:,1));
slope23 = (point2(:,2)-point3(:,2))./(point2(:,1)-point3(:,1));
% account for infinite or 0 slopes between points 1 and 2
bad12 = find(~isfinite(slope12) | slope12==0);
% recalculate the bad 1-2 slopes with points 2 and 3 swapped
slope12(bad12) = (point1(bad12,2)-point3(bad12,2))./(point1(bad12,1)-point3(bad12,1));
% account for infinite slopes between points 2 and 3
bad23 = find(~isfinite(slope23));
% recalculate the bad slopes with points 1 and 2 swapped
slope23(bad23) = (point1(bad23,2)-point3(bad23,2))./(point1(bad23,1)-point3(bad23,1));

%% calculate (x,y) coordinates and radii of a series of osculating circles

% x coordinates of the circle centers
x_centers = (slope12.*slope23.*(point1(:,2)-point3(:,2))...
    + slope23.*(point1(:,1) + point2(:,1))...
    - slope12.*(point2(:,1) + point3(:,1)))...
    ./(2.*(slope23-slope12));
% find midpoints between points 1 and 2
midpoint12 = (point1+point2)./2;
% y coordinates of the circle centers
y_centers = (-1./slope12).*(x_centers-midpoint12(:,1)) + midpoint12(:,2);
% radii of the circles
circleRadii = sqrt((point1(:,1) - x_centers).^2 + (point1(:,2) - y_centers).^2);

%% now calculate the curvature as the inverse radius of each osculating circle

% curvature (1/radius)
curvatureList = 1./circleRadii;
% set any infinite curvatures to 0
curvatureList(~isfinite(curvatureList)) = 0;

%% if loop is not closed, we need to adjust curvature at the endpoints
% we do this by taking the last "real" curvature value and linearly 
% interpolating to 0 on each end
% adjust start of curve
curv_val = curvatureList(flankingPoints+1);
curv_interp = linspace(0,curv_val,flankingPoints+1);
curvatureList(1:flankingPoints+1) = curv_interp;
% adjust end of curve
curv_val = curvatureList(end-flankingPoints);
curv_interp = linspace(curv_val,0,flankingPoints+1);
curvatureList(end-flankingPoints:end) = curv_interp;

%% find tortuosity

% find the tortuosity (should correct units)
tortuosity = sum(gradient(curvatureList(1:nPoints-1,1)).^2)/curveLength;

%% estimate the direction of the tangent at each point using the slope between 2 flanking points

% the distance (in idx) to the points on either side of the measurement point
flankingPointsTangent = 1;
% extend and wrap the curve onto itself to handle the endpoints
wrappedCurveTangent = [curvePoints(end-flankingPointsTangent:end-1,:); curvePoints(1:end,:); curvePoints(2:flankingPointsTangent+1,:)];
% idxs of flanking points to the left of our measurement points
point1Idx = 1:nPoints;
% idxs of flanking points to the right of our measurement points
point3Idx = point1Idx+2*flankingPointsTangent;
% (x,y) coordinates of the flanking points themselves
point1 = wrappedCurveTangent(point1Idx,:);
point3 = wrappedCurveTangent(point3Idx,:);
% estimate the tangent at each point (in the range [0 pi] measured CCW from the positive x-axis)
tangentList = pi - mod(atan2(point1(:,2)-point3(:,2), point1(:,1)-point3(:,1)), pi);

% need to adjust enpoint tangents since this is not a closed curve
% we do this by setting each endpoint tangent = tangent of the curve at the nearest point
tangentList(1) = tangentList(2);
tangentList(end) = tangentList(end-1);


end