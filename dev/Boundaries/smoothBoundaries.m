function boundariesSmooth = smoothBoundaries(boundaries)

boundariesX = boundaries(:,2);
boundariesY = boundaries(:,1);


% degree of the polynomial and window width for Savitzky-Golay smoothing filter
polynomialOrder = 2;

% get the perimeter of the boundary
%perimeter = getCurveLength(boundaries);

nPoints = numel(boundariesX(:,1));

% windowWidth must be odd and greater than polynomialOrder
boundarySmoothWidth = max(round(nPoints/10),7);

if ~mod(boundarySmoothWidth,2) % if even
    boundarySmoothWidth = boundarySmoothWidth+1; % make odd
end

% smooth out the boundaries so that the majority of vertices within the mask are at the approximate centerline
[boundariesSmoothX,boundariesSmoothY] = sgolayfilt_closedcurve(boundariesX,boundariesY,polynomialOrder,boundarySmoothWidth);

% we want the respaced boundary to have the same number of points
nPointsDesired = numel(boundariesX);

% now re-interpolate
newPoints = interparc(nPointsDesired,boundariesSmoothX,boundariesSmoothY,'linear');

boundariesSmooth = [newPoints(:,2) newPoints(:,1)];

end