function [smoothX,smoothY] = sgolayfilt_closedcurve(x,y,polynomialOrder, windowWidth)
% Author: Will Dean
% applies Savitsky-Golay filter to x,y coordinates of a closed curve
% x and y must be mx1 column vectors

    % original number of points
    n = length(x);

    wrappedX = [x(end-windowWidth:end); x(2:end-1) ; x(1:windowWidth)];
    wrappedY = [y(end-windowWidth:end); y(2:end-1) ; y(1:windowWidth)];

    smoothX = sgolayfilt(wrappedX, polynomialOrder, windowWidth);
    smoothY = sgolayfilt(wrappedY, polynomialOrder, windowWidth);
    
    smoothX = smoothX(windowWidth+1:windowWidth+n);
    smoothY = smoothY(windowWidth+1:windowWidth+n);

end