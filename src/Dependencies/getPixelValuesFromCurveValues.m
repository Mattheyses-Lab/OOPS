function pixelValues = getPixelValuesFromCurveValues(Curve,curveValues,I)
% given a curve (x,y), a list of values for each point on the curve, and a binary image...
% return a list of pixel values (ordered by their linear idxs) where the value of each pixel
% is based on the value of the closest curve point

    % check for invalid input
    if any(isnan(Curve(:))) || isempty(curveValues)
        pixelValues = [];
        return
    end
    % the size of the input image
    Isz = size(I);
    % initialize values image
    valuesI = zeros(Isz);
    % linear indices in this binary image
    objIdxs = find(I);
    % convert to row and column coordinates
    [objR,objC] = ind2sub(Isz,objIdxs);
    % get the distance between each object pixel and all curve coordinates | hypot(A,B) = sqrt(A^2+B^2)
    dist = hypot(objC' - Curve(:,1),objR' - Curve(:,2));
    % for each object pixel, get the index to the closest curve coordinate
    [~,minIdxs] = min(dist,[],1);
    % use the closest indices to set the appropriate value of each object pixel in the values image
    valuesI(objIdxs) = curveValues(minIdxs);
    % list of pixel values from the values image, ordered by their linear idxs
    pixelValues = valuesI(I);
    
end