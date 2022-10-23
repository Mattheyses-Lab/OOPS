function AzimuthStd = getAzimuthStd(azimuths)

    % find the average azimuth, accounting for the 0°==180° degeneracy
    [~,AzimuthAverage] = getAzimuthAverageUsingDipoles(azimuths);

    % total number of azimuths
    nAzimuths = length(azimuths);

    % vector to hold each azimuth's deviation from the mean
    AzimuthDiff = zeros(size(AzimuthAverage));

    for i = 1:length(azimuths)
        % deviation is the smallest angle between each azimuth and the mean
        % there are 3 cases to consider:
        % case 1 is where the azimuth and mean azimuth are BOTH positive or negative
        if (azimuths(i)<0 && AzimuthAverage<0)||(azimuths(i)>0 && AzimuthAverage>0)
            AzimuthDiff(i) = azimuths(i)-AzimuthAverage;
        elseif azimuths(i)<0
            % cases 2 and 3 are where one is positive and the other is negative
            % add 180 to the negative value then calculate deviation
            AzimuthDiff(i) = min(abs((azimuths(i)+180)-AzimuthAverage),abs(azimuths(i)-AzimuthAverage));
        elseif AzimuthAverage<0
            AzimuthDiff(i) = min(abs(azimuths(i)-(AzimuthAverage+180)),abs(azimuths(i)-AzimuthAverage));
        end
    end

    % square the differences
    AzimuthDiffSquared = AzimuthDiff.^2;

    % compute the (uncorrected) standard deviation from the mean
    AzimuthStd = sqrt(sum(AzimuthDiffSquared)/nAzimuths);

end