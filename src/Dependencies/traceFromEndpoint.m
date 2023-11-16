function tracedCurve = traceFromEndpoint(point,remainingPoints)
% traceFromEndpoint  Given a list of unsorted points representing an unclosed 
% curve and one endpoint of the curve, recursively reorder the points by finding the 
% shortest path through them.
%
%   INPUTS:
%       point | (1x2) double | (x,y) coordinates of one endpoint of the curve
%       remainingPoints | (mx2) double | (x,y) coordinates of the remaining points in the curve
%
%   OUTPUTS:
%       out | (m+1x2) double | reordered (x,y) coordinates, including the endpoint
%
%   ASSUMPTIONS AND LIMITATIONS:
%       point must be an endpoint of the curve
%       potential to fail if distances between endpoints and all other points is not greater 
%           than or equal to the largest distance between adjacent points
%       potential to fail if the curve has sharp turns, especially near the endpoints
%       will not work properly if the curve intersects itself
%       similarly, will give strange output if the curve has any branches (i.e., > 2 end points)
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


% if only one point left, add it to the end of the list and return
if size(remainingPoints,1)==1
    tracedCurve = [point;remainingPoints];
    return
end
% first find the euclidean distance between point and all remainingPoints
dist = sqrt((remainingPoints(:,1)-point(1)).^2 + (remainingPoints(:,2)-point(2)).^2);
% determine which point in remainingPoints is closest to point
[~, closestIdx] = min(dist);
closestPoint = remainingPoints(closestIdx,:);
% remove that point from remainingPoints
remainingPoints(closestIdx,:) = [];
% call this function again with shortened point list
tracedCurve = [point; traceFromEndpoint(closestPoint,remainingPoints)];
return

end