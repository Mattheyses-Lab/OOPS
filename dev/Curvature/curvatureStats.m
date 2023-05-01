function [curvatureList, tangentList, tortuosity] = curvatureStats(curvePoints,closedCurve,flankingPoints)
% this function calculates curvature stats for a closed or open curve
% flankingPoints specifies the spacing between each of the three points used to determine curvature

% number of points in the curve
nPoints = length(curvePoints);
% get the length of the curve
curveLength = getCurveLength(curvePoints);
% wrap the end of the curve onto the beginning and vice verse
wrappedCurve = [curvePoints(end-flankingPoints:end-1,:); curvePoints(1:end,:); curvePoints(2:flankingPoints+1,:)];
% initialize list of curvature values
curvatureList = zeros(nPoints,1);

if closedCurve

    parfor j = flankingPoints+1:nPoints+flankingPoints
        % get the three points to which the circle will be fit (point2 is the point we are calculating curvature for)
        point1 = wrappedCurve(j-flankingPoints,:);
        point2 = wrappedCurve(j,:);
        point3 = wrappedCurve(j+flankingPoints,:);    
    
        slope12 = (point1(1,2)-point2(1,2))/(point1(1,1)-point2(1,1));
        slope23 = (point2(1,2)-point3(1,2))/(point2(1,1)-point3(1,1));
    
        if slope12==Inf || slope12==-Inf || slope12 == 0
            point0 = point2; point2 = point3; point3 = point0;
            slope12 = (point1(1,2)-point2(1,2))/(point1(1,1)-point2(1,1));
            slope23 = (point2(1,2)-point3(1,2))/(point2(1,1)-point3(1,1));    
        end
    
        if slope23==Inf || slope23==-Inf
            point0 = point1; point1 = point2; point2 = point0;
            slope12 = (point1(1,2)-point2(1,2))/(point1(1,1)-point2(1,1));
            slope23 = (point2(1,2)-point3(1,2))/(point2(1,1)-point3(1,1));    
        end
    
        % if the boundary is flat
        if slope12==slope23  
            curvatureList(j-flankingPoints,1) = 0;
    
        % if the boundary is curved
        else
    
            % calculate the curvature
            x_center = (slope12*slope23*(point1(1,2)-point3(1,2))+slope23*(point1(1,1)+point2(1,1))...
                       -slope12*(point2(1,1)+point3(1,1)))/(2*(slope23-slope12));
            midpoint12 = (point1+point2)/2;
            midpoint13 = (point1+point3)/2;
            y_center = (-1/slope12)*(x_center-midpoint12(1,1))+midpoint12(1,2);
            curvatureList(j-flankingPoints,1) = 1/sqrt((point1(1,1)-x_center)^2+(point1(1,2)-y_center)^2);
    
    
            % removing this to see what happens if we ignore 'negative' curvature for the midline
            % determine if the curvature is positive or negative
            [In, On] = inpolygon(midpoint13(1,1),midpoint13(1,2),curvePoints(:,1),curvePoints(:,2)); 

            if ~In              
                curvatureList(j-flankingPoints,1) = -1*curvatureList(j-flankingPoints,1);
            end

            if On || ~isfinite(curvatureList(j-flankingPoints,1))
                curvatureList(j-flankingPoints,1) = 0;
            end
    
            if ~isfinite(curvatureList(j-flankingPoints,1))
                curvatureList(j-flankingPoints,1) = 0;
            end
    
        end 
    
    end

else

    parfor j = flankingPoints+1:nPoints+flankingPoints
    
        % get the three points to which the circle will be fit (point2 is the point we are calculating curvature for)
        point1 = wrappedCurve(j-flankingPoints,:);
        point2 = wrappedCurve(j,:);
        point3 = wrappedCurve(j+flankingPoints,:);    
    
        slope12 = (point1(1,2)-point2(1,2))/(point1(1,1)-point2(1,1));
        slope23 = (point2(1,2)-point3(1,2))/(point2(1,1)-point3(1,1));
    
        if slope12==Inf || slope12==-Inf || slope12 == 0
            % infinite or 0 slope between points 1 and 2, swap points 2 and 3
            point0 = point2; point2 = point3; point3 = point0;
            slope12 = (point1(1,2)-point2(1,2))/(point1(1,1)-point2(1,1));
            slope23 = (point2(1,2)-point3(1,2))/(point2(1,1)-point3(1,1));    
        end
    
        if slope23==Inf || slope23==-Inf
            % infinite or 0 slope between points 2 and 3, swap points 1 and 2
            point0 = point1; point1 = point2; point2 = point0;
            slope12 = (point1(1,2)-point2(1,2))/(point1(1,1)-point2(1,1));
            slope23 = (point2(1,2)-point3(1,2))/(point2(1,1)-point3(1,1));    
        end
    
        % if the region is flat
        if slope12==slope23  
            % then no curvature
            curvatureList(j-flankingPoints,1) = 0;
        % if the region is curved
        else
            % then calculate the curvature by fitting a circle to the three points

            % x coordinate of the circle center
            x_center = (slope12*slope23*(point1(1,2)-point3(1,2))+slope23*(point1(1,1)+point2(1,1))...
                       -slope12*(point2(1,1)+point3(1,1)))/(2*(slope23-slope12));
            
            midpoint12 = (point1+point2)/2;

            % y coordinate of the circle center
            y_center = (-1/slope12)*(x_center-midpoint12(1,1))+midpoint12(1,2);


            curvatureList(j-flankingPoints,1) = 1/sqrt((point1(1,1)-x_center)^2+(point1(1,2)-y_center)^2);
    
            if ~isfinite(curvatureList(j-flankingPoints,1))
                curvatureList(j-flankingPoints,1) = 0;
            end
    
        end

    end

end

% if loop is not closed, we need to adjust curvature at the endpoints
if ~closedCurve
    % adjust start of curve
    curv_val = curvatureList(flankingPoints+1);
    curv_interp = linspace(0,curv_val,flankingPoints+1);
    curvatureList(1:flankingPoints+1) = curv_interp;

    % adjust end of curve
    curv_val = curvatureList(end-flankingPoints);
    curv_interp = linspace(curv_val,0,flankingPoints+1);
    curvatureList(end-flankingPoints:end) = curv_interp;
end

% find the tortuosity (should correct units)
tortuosity = sum(gradient(curvatureList(1:nPoints-1,1)).^2)/curveLength;

% calculate the direction of the tangent to the curve at each point
% initialize list of tangent angles
tangentList = zeros(1,nPoints);
flankingPointsTangent = 1;
wrappedCurveTangent = [curvePoints(end-flankingPointsTangent:end-1,:); curvePoints(1:end,:); curvePoints(2:flankingPointsTangent+1,:)];

for j=flankingPointsTangent+1:nPoints+flankingPointsTangent
    % get the 2 points used to calculate the tangent
    point1 = wrappedCurveTangent(j-flankingPointsTangent,:);
    point2 = wrappedCurveTangent(j+flankingPointsTangent,:);
    % our tangent is measured CCW from the positive x direction
    tangentList(1,j-flankingPointsTangent) = pi - mod(atan2(point1(1,2)-point2(1,2), point1(1,1)-point2(1,1)), pi);
end

if ~closedCurve
    % need to adjust enpoint tangents since this is not a closed curve
    tangentList(1) = tangentList(2);
    tangentList(end) = tangentList(end-1);
end

end