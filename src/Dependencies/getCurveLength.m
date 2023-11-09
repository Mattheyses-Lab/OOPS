function curveLength = getCurveLength(Curve)
%%  getCurveLength Given a list of (x,y) coordinates representing a curve, return the length
%
%   INPUT:
%       Curve - (mx2 double) (x,y) coordinates (in order) of the curve
%
%   OUTPUT:
%       curveLength - (double) length of the curve
%
%   ASSUMPTIONS AND LIMITATIONS:
%       no interpolation or smoothing is performed to measure distance, we are simply 
%       calculating the sum of the euclidean distances between Curve(2:n,:) and Curve(1:n-1,:)
%   
%       Curve(:,1) = x coordinates, Curve(:,2) = y coordinates
%
%       If the curve is meant to be closed, then the first and last points should be identical
%
%----------------------------------------------------------------------------------------------------------------------------

% return NaN if Curve contains any NaNs
if any(isnan(Curve(:)))
    curveLength = NaN;
    return
end
% split into vectors of x and y coordinates
curveX = Curve(:,1);
curveY = Curve(:,2);
% compute distances between neighboring points
dx = curveX(2:end) - curveX(1:end-1);
dy = curveY(2:end) - curveY(1:end-1);
d = sqrt(dx.*dx+dy.*dy);
% now sum the distances
curveLength = sum(d);
end