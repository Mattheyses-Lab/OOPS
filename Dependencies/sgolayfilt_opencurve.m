function [smoothX,smoothY] = sgolayfilt_opencurve(x,y,polynomialOrder, windowWidth)
% Author: Will Dean
% applies Savitsky-Golay filter to x,y coordinates of an open curve

    smoothX = sgolayfilt(x, polynomialOrder, windowWidth);
    smoothY = sgolayfilt(y, polynomialOrder, windowWidth);

end