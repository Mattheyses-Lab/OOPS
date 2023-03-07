function midlineTangent = getMidlineTangent(Midline)

    nMidline = size(Midline,1);
    midlineTangent = zeros(nMidline,1);
    % calculate the tangent angle at each point along the midline (add 2 flanking points at the end temporarily)
    midlineEx = [Midline(end-1,:); Midline(1:end,:); Midline(2,:)];
    for j=2:nMidline+1
        % get two points on either side of this point to find the tangent
        point1 = midlineEx(j-1,:);
        point2 = midlineEx(j+1,:);
        % our tangent is measured in radians, CCW from the positive x direction
        midlineTangent(j-1) = pi - mod(atan2(point1(1,2)-point2(1,2), point1(1,1)-point2(1,1)), pi);
    end
    % need to adjust enpoint tangents since this is not a closed curve
    midlineTangent(1) = midlineTangent(2);
    midlineTangent(end) = midlineTangent(end-1);
    
    % wrap values to fall in the range [-pi/2, pi/2]
    midlineTangent(midlineTangent>(pi/2)) = midlineTangent(midlineTangent>(pi/2))-pi;

end