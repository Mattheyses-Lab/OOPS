function [MidlineRelativeAzimuth,NormalRelativeAzimuth] = getRelativeAzimuth(I,Az,Midline)

    Isz = size(I);
%     [~,~,Midline] = getObjectMidline(I);


    nMidline = size(Midline,1);
    midlineTangent = zeros(nMidline,1);
    % calculate the tangent angle at each point along the midline
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
    
    % get the list of pixel azimuth values
    AzValues = Az(I);
    
    % initialize tangent image
    IT = zeros(Isz);
    % for each pixel
    for Idx = 1:numel(I)
        % if the pixel is in the object
        if I(Idx)
            % get y and x coordinates from the linear idx
            [y,x] = ind2sub(Isz,Idx);
            % get Euclidean distances between this pixel and all midline points
            dist = sqrt((x-Midline(:,1)).^2+(y-Midline(:,2)).^2);
            % find the shortest distance, that will be the point we need
            [minDist,minIdx] = min(dist);
            % add the value to the tangent image
            IT(Idx) = midlineTangent(minIdx);
        end
    end
    
    % list of midline tangent angles
    TangentValues = IT(I);
    % list of midline normal values (90° angle to midline)
    NormalValues = TangentValues+pi/2;
    NormalValues(NormalValues>(pi/2)) = NormalValues(NormalValues>(pi/2))-pi;
    
    % find difference between each azimuth value and its associatedd midline/midline normal values
    MidlineRelativeAzimuths = getAzimuthDiff(TangentValues,AzValues);
    NormalRelativeAzimuths = getAzimuthDiff(NormalValues,AzValues);

    % find the average of all differences (VERY IMPORTANT TO TAKE THE MEAN OF THE ABSOLUTE VALUE)
%     MidlineRelativeAzimuth = mean(abs(MidlineRelativeAzimuths));
%     NormalRelativeAzimuth = mean(abs(NormalRelativeAzimuths));

    MidlineRelativeAzimuth = mean(MidlineRelativeAzimuths);
    NormalRelativeAzimuth = mean(NormalRelativeAzimuths);

end