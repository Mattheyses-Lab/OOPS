function [shape, Icurv] = midlineCurvature(...
    image,...
    boundaryPoint,...
    curvatureThresh,...
    bp_tangent,...
    interp_resolution,...
    loopclose...
    )

%%***********************************************************************%
%*                         Curvature measure                            *%
%*                  Measure shape properties of loops.                  *%
%*                                                                      *%
%* Original author: Dr. Meghan Driscoll                                 *%
%* Modified by: Preetham Manjunatha                                     *%
%* Further modified by: Will Dean                                       *%
%* Github link: https://github.com/preethamam
%* Date: 08/02/2021                                                     *%
%************************************************************************%
%
%************************************************************************%
%
% Usage: [shape, Icurv] = curvature(image, boundaryPoint, curvatureThresh, ...
%                                     bp_tangent, interp_resolution, loopclose)
% Inputs: % Inputs:
%           Image                - input image
%           boundaryPoint        - number of boundary points over which curvature is found 
%           curvatureThresh      - the largest curvature magnitude allowed in the cutoff curvature
%           bp_tangent           - the number of boundary points over which the boundary tangent 
%                                  direction is measured
%           interp_resolution    - interpolation resolution -- the minimum number of pixels seperating 
%                                  boundary points after interpolation
%           loopclose            - 0 - if open boundaries | 1 - if closed boundaries
% 
% Outputs: 
%           shape                
%           .curvature          - the boundary curvature at each boundary point (uses snakeNum) 
%                                 Curvatures above or below a cutoff are given the magnitude of the cutoff
%           .meanNegCurvature   - the mean negative curvature
%           .numIndents         - the number of boundary regions over which the curvature is negative
%           .tangentAngle       - the angle of the tangent to the boundary at each boundary point
%           .tortuosity         - the boundary tortuousity (a measure of how bendy the boundary is)
%           .uncutCurvature     - the uncut boundary curvature at each boundary point (uses snakeNum)

%           Icurv               - Output image (padded image to make 3 channel. This fixes the plot)
%--------------------------------------------------------------------------
% 
%%%%%%%%%%%%%%%% MEASURE SHAPE %%%%%%%%%%%%%%%%
% Original author: Dr. Meghan Driscoll
% Modified and compacted/concised a complicated codebase by: Preetham Manjunatha
% 
% Thanks to Dr. Meghan Driscoll who kindly shared her code for academic purpose.
% If you use this code for visualization and other academic/research/any purposes. 
% 
% Please cite:
% 
% Reference:
% Driscoll MK, McCann C, Kopace R, Homan T, Fourkas JT, Parent C, et al. (2012) 
% Cell Shape Dynamics: From Waves to Migration. 
% PLoS Comput Biol 8(3): e1002392. 
% https://doi.org/10.1371/journal.pcbi.1002392
% 
% Important note: This code uses parfor to speed up the things. If you do not have 
% the Matlab parallel computing toolbox. Please make 'parfor' as 'for' in this
% function.
%
% %%%%%%%% This code is way too slow! (curvature should not be in a for loop) %%%%%%%%%
% If I have time I will try to improve this. If anyone improves it, please
% share the modified version code with me.

% RGB to binarization
if(size(image,3) == 3)
    Igray = rgb2gray(image);
    binaryimage = imbinarize(Igray);
    Icurv = image;
elseif (islogical(image))
    binaryimage = image;      
    Icurv = im2uint8(repmat(image,1,1,3));
else
    binaryimage = imbinarize(image);
    Icurv = im2uint8(repmat(image,1,1,3));
end

% % Find X and Y coordinates of the midline
cc_index = 1;
% boundaries = bwboundaries(binaryimage,8);
% x = boundaries{cc_index}(:, 2);
% y = boundaries{cc_index}(:, 1);


if loopclose
    boundaries = bwboundaries(binaryimage,8);
    x = boundaries{cc_index}(:, 2);
    y = boundaries{cc_index}(:, 1);
    x = x';
    y = y';
else
    % IMPORTANT: will only trace the midline correctly if object has no 
    % branchpoints and is not circularly symmetric
    % works better for larger objects
    [~,~,Midline] = getObjectMidline(image);
    x = Midline(:,1);
    y = Midline(:,2);
end

%% WD: let's try skipping the interpolation step (relies on a large coordinate list)

% Interpolate for more points

% first we add points, then remove points?? (1:boundaryPoint:end) why?
switch loopclose
    case true
        % make sure we pass snakeinterp1 an UNCLOSED curve
        [xi,yi] = snakeinterp1(x(1:end-1),y(1:end-1),interp_resolution,loopclose);
    case false
        [xi,yi] = snakeinterp1(x(1:end),y(1:end),interp_resolution,loopclose);
end

%% end interpolation steps

x = xi;
y = yi;

% WD: smooth out the boundary coordinates (works better so far, but need to play with sgolayfilt params a bit)
% code below from ImageAnalyst
% Now smooth with a Savitzky-Golay sliding polynomial filter
% use window width the same size as boundaryPoint
windowWidth = round((boundaryPoint)/interp_resolution)+1;
% make sure the window size is odd
if ~mod(windowWidth,2)
    windowWidth = windowWidth+1;
end
polynomialOrder = 2;
% end code by ImageAnalyst (similar strategy)
% use a function that returns the sgolay smoothed curve, but closed
switch loopclose
    case true
        x = x';
        y = y';
        [smoothX,smoothY] = sgolayfilt_closedcurve(x,y,polynomialOrder, windowWidth);
        smoothX = smoothX';
        smoothY = smoothY';
    case false
        [smoothX,smoothY] = sgolayfilt_opencurve(x,y,polynomialOrder, windowWidth);
end

x = smoothX;
y = smoothY;
% end edits by WD


% Perimeter of the binary component
stats = regionprops(binaryimage,'perimeter');
perimeter = cat(1,stats(cc_index).Perimeter);

xn = x;
yn = y;

shape_XY = [xn;yn]';
M = numel(xn);

% initialize variables    
shape_curvature         = NaN(1,M);
shape_uncutCurvature    = NaN(1,M);
shape_meanNegCurvature  = NaN(1,1);
shape_numIndents = NaN(1,1);
shape_tortuosity = NaN(1,1);
shape_tangentAngle = NaN(1,M);
shape_tangentAngle2 = NaN(1,M);

% calculate the curvature (by finding the radius of the osculating circle using three neaby boundary points)

bp_positions = [shape_XY(end-boundaryPoint:end-1,:); shape_XY(1:end,:); shape_XY(2:boundaryPoint+1,:)];

parfor j = boundaryPoint+1:M+boundaryPoint

    % assign the three points that the circle will be fit to such that the slopes are not infinite 
%     point1 = bp_positions(j,:);
%     point2 = bp_positions(j+boundaryPoint,:);
%     point3 = bp_positions(j+2*boundaryPoint,:); 

    % try to use one point on either side instead of next 2 points
    point1 = bp_positions(j-boundaryPoint,:);
    point2 = bp_positions(j,:);
    point3 = bp_positions(j+boundaryPoint,:);    

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
        shape_curvature(1,j-boundaryPoint) = 0;

    % if the boundary is curved
    else

        % calculate the curvature
        x_center = (slope12*slope23*(point1(1,2)-point3(1,2))+slope23*(point1(1,1)+point2(1,1))...
                   -slope12*(point2(1,1)+point3(1,1)))/(2*(slope23-slope12));
        midpoint12 = (point1+point2)/2;
        midpoint13 = (point1+point3)/2;
        y_center = (-1/slope12)*(x_center-midpoint12(1,1))+midpoint12(1,2);
        shape_uncutCurvature(1,j-boundaryPoint) = 1/sqrt((point1(1,1)-x_center)^2+(point1(1,2)-y_center)^2);

        % cutoff the curvature (for visualization)
        shape_curvature(1,j-boundaryPoint) = shape_uncutCurvature(1,j-boundaryPoint);
        if shape_curvature(1,j-boundaryPoint) > curvatureThresh
            shape_curvature(1,j-boundaryPoint) = curvatureThresh;
        end

        % removing this to see what happens if we ignore 'negative' curvature for the midline
%         % determine if the curvature is positive or negative
%         [In, On] = inpolygon(midpoint13(1,1),midpoint13(1,2),shape_XY(:,1),shape_XY(:,2)); 
% 
%         if ~In              
%             shape_curvature(1,j-boundaryPoint) = -1*shape_curvature(1,j-boundaryPoint);
%             shape_uncutCurvature(1,j-boundaryPoint) = -1*shape_uncutCurvature(1,j-boundaryPoint);
%         end

%         if On || ~isfinite(shape_uncutCurvature(1,j-boundaryPoint))
%             shape_curvature(1,j-boundaryPoint) = 0;
%             shape_uncutCurvature(1,j-boundaryPoint) = 0;
%         end

        if ~isfinite(shape_uncutCurvature(1,j-boundaryPoint))
            shape_curvature(1,j-boundaryPoint) = 0;
            shape_uncutCurvature(1,j-boundaryPoint) = 0;
        end

    end 

end

% if loop is not closed, we need to adjust curvature at the endpoints
if ~loopclose
    % adjust start of curve
    curv_val = shape_curvature(boundaryPoint+1);
    curv_interp = linspace(0,curv_val,boundaryPoint);
    shape_curvature(1:boundaryPoint) = curv_interp;

    % adjust end of curve
    curv_val = shape_curvature(end-boundaryPoint);
    curv_interp = linspace(curv_val,0,boundaryPoint);
    shape_curvature(end-boundaryPoint+1:end) = curv_interp;
end



% find the mean negative curvature (really this should use a constant dist snake)
listCurve = shape_uncutCurvature(1,1:M-1);
listNegCurve = abs(listCurve(listCurve < 0));
if ~isempty(listNegCurve) 
    shape_meanNegCurvature(1,1) = sum(listNegCurve)/(M-1);
else
    shape_meanNegCurvature(1,1) = 0;
end

% find the number of negative boundary curvature regions
curveMask = (listCurve < 0);
curveMaskLabeled = bwlabel(curveMask);
numIndents = max(curveMaskLabeled);
if curveMask(1) && curveMask(end)
    numIndents  = numIndents-1;
end
shape_numIndents(1,1) = numIndents;

% find the tortuosity (should correct units)
shape_tortuosity(1,1) = sum(gradient(shape_uncutCurvature(1,1:M-1)).^2)/perimeter;

% calculate the direction of the tangent to the midline 
% bp_positions_tangent=[shape_XY(M-1-bp_tangent:M-1,:); shape_XY(1:M-1,:); shape_XY(1:bp_tangent+1,:)];
bp_positions_tangent = [shape_XY(end-bp_tangent:end-1,:); shape_XY(1:end,:); shape_XY(2:bp_tangent+1,:)];
for j=bp_tangent+1:M+bp_tangent
%     point1 = bp_positions_tangent(j,:);
%     point2 = bp_positions_tangent(j+2*bp_tangent,:);
% WD: trying a new method to fix the apparent offset of tangents
    point1 = bp_positions_tangent(j-bp_tangent,:);
    point2 = bp_positions_tangent(j+bp_tangent,:);
    %shape_tangentAngle(1,j-bp_tangent) = mod(atan2(point1(1,2)-point2(1,2), point1(1,1)-point2(1,1)), pi);
    % slightly different calculation so our tangent is measured CCW from the positive x direction
    shape_tangentAngle(1,j-bp_tangent) = pi - mod(atan2(point1(1,2)-point2(1,2), point1(1,1)-point2(1,1)), pi);
end

if ~loopclose
    % need to adjust enpoint tangents since this is not a closed curve
    shape_tangentAngle(1) = shape_tangentAngle(2);
    shape_tangentAngle(end) = shape_tangentAngle(end-1);
end


shape.XY = shape_XY;
shape.curvature         = shape_curvature;
shape.uncutCurvature    = shape_uncutCurvature;
shape.meanNegCurvature  = shape_meanNegCurvature;
shape.numIndents = shape_numIndents;
shape.tortuosity = shape_tortuosity;
shape.tangentAngle = shape_tangentAngle;

% WD: add the tangent angle in degrees also
shape.tangentAngleDegrees = rad2deg(shape_tangentAngle);

end


%% Auxillary fucntions
%--------------------------------------------------------------------------
function [xi,yi] = snakeinterp1(x,y,RES,loopclose)
% Will Dean: made edits to account for the possibility of an unclosed loop
% made other assorted edits for my own readability

% x and y should always represnt an unclosed curve (startpoint ~= endpoint)
% however, if loopclose is true, function will return a closed loop
% if false, will return a curve with original start and end points

% SNAKEINTERP1  Interpolate the snake to have equal distance RES
%     [xi,yi] = snakeinterp(x,y,RES)
%
%     RES: resolution desired

%     update on snakeinterp after finding a bug

%      Chenyang Xu and Jerry L. Prince, 3/8/96, 6/17/97
%      Copyright (c) 1996-97 by Chenyang Xu and Jerry L. Prince
%      image Analysis and Communications Lab, Johns Hopkins University

    % convert to column vector
    x = x(:); y = y(:);

    if loopclose
        % make it a circular list since we are dealing with closed contour
        x = [x;x(1)];
        y = [y;y(1)];

        % compute the distance from previous node for point 2:N+1
        dx = x(2:end)- x(1:end-1);
        dy = y(2:end)- y(1:end-1);
        d = sqrt(dx.*dx+dy.*dy);  
    
        % point 1 to point 1 is 0
        d = [0;d];
    
        % now compute the arc length of all the points to point 1
        % we use matrix multiply to achieve summing
        M = length(d);
        d = (d'*uppertri(M,M))';
    
        % now ready to reparametrize the closed curve in terms of arc length
        maxd = d(M);
    
        if (maxd/RES<3)
            error('RES too big compare to the length of original curve');
        end
    
        di = 0:RES:maxd;
    
        xi = interp1(d,x,di);
        yi = interp1(d,y,di);
    
        if (maxd - di(end) < RES/2)  % deal with end boundary condition
            xi = xi(1:end-1);
            yi = yi(1:end-1);
        end

        % close the curve
        xi = [xi,xi(1)];
        yi = [yi,yi(1)];
    
    else
        
        % compute the distance from previous node for point 2:N+1
        dx = x([2:end])- x(1:end-1);
        dy = y([2:end])- y(1:end-1);
        d = sqrt(dx.*dx+dy.*dy);  
    
        % point 1 to point 1 is 0
        d = [0;d];   
    
        % now compute the arc length of all the points to point 1
        % we use matrix multiply to achieve summing
        M = length(d);
        d = (d'*uppertri(M,M))';
    
        % now ready to reparametrize the closed curve in terms of arc length
        maxd = d(M);
    
        if (maxd/RES < 3)
            error('RES too big compare to the length of original curve');
        end
    
        di = 0:RES:maxd;
    
        xi = interp1(d,x,di);
        yi = interp1(d,y,di);
        
        % deal with end boundary condition
        if (maxd - di(end) < RES/2)  
            xi = xi(1:end-1);
            yi = yi(1:end-1);
        end
    
        % add the last point of the original curve to the end
        xi = [xi,x(end)];
        yi = [yi,y(end)];

    end

end


function q = uppertri(M,N)                      %added by Ilya
% UPPERTRI   Upper triagonal matrix 
%            UPPER(M,N) is a M-by-N triagonal matrix

[J,I] = meshgrid(1:M,1:N);
q = (J>=I);
end