function curveOut = approximateRespaceCurve(curveIn, newSpacing)

    % length of the curve
    curveLength = getCurveLength(curveIn);

    % desired number of edges in the respaced curve
    nEdgesDesired = curveLength/newSpacing;

    % adjust interpolation resolution to ensure even spacing between all points
    length1 = nEdgesDesired*newSpacing;
    length2 = curveLength;
    spacingScale = length1/length2;
    newSpacing = newSpacing/spacingScale;

    % determine how many points in the final interpolated curve
    nPointsDesired = round(curveLength/newSpacing)+1;

    % now interpolate the curve
    curveOut = interparc(nPointsDesired,curveIn(:,1),curveIn(:,2),'linear');

end