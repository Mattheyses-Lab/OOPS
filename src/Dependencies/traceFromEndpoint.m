function tracedCurve = traceFromEndpoint(point,remainingPoints)
% traceFromEndpoint  Given a list of unsorted points representing an unclosed 
% curve and one endpoint of the curve, recursively reorder the points by finding the 
% shortest path through them.
%
%   INPUTS:
%       point (1x2 double) - (x,y) coordinates of one endpoint of the curve
%       remainingPoints (mx2 double) - (x,y) coordinates of the remaining points in the curve
%
%   OUTPUTS:
%       out (m+1x2 double) - reordered (x,y) coordinates, including the endpoint, point
%
%   ASSUMPTIONS AND LIMITATIONS:
%       point must be an endpoint of the curve
%       potential to fail if distances between endpoints and all other points is not greater 
%           than or equal to the largest distance between adjacent points
%       potential to fail if the curve has sharp turns, especially near the endpoints
%       will not work properly if the curve intersects itself
%       similarly, will give strange output if the curve has any branches (i.e., > 2 end points)


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