function [MidlineRelativeAzimuth,NormalRelativeAzimuth] = getRelativeAzimuth(I,Az,Midline)
% calculate the relative direction of azimuths with respect to the tangents and normals of a midline traced through a binary object

    Isz = size(I);

    %% compute the midline tangent
    midlineTangent = getMidlineTangent(Midline);

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
            [~,minIdx] = min(dist);
            % add the value to the tangent image
            IT(Idx) = midlineTangent(minIdx);
        end
    end
    
    % list of midline tangent angles
    TangentValues = IT(I);

    % list of midline normal values (90° angle to midline)
    NormalValues = TangentValues+pi/2;
    NormalValues(NormalValues>(pi/2)) = NormalValues(NormalValues>(pi/2))-pi;


    % get the angular differences between azimuth and tangent angles
    tangentDiff = angle(exp(2i*AzValues)./exp(2i*TangentValues))*0.5;
    % average the differences
    MidlineRelativeAzimuth = rad2deg(getAzimuthAverage(tangentDiff));

    normalDiff = angle(exp(2i*AzValues)./exp(2i*NormalValues))*0.5;
    NormalRelativeAzimuth = rad2deg(getAzimuthAverage(normalDiff));



end