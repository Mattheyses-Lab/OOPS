function azimuthStd = getAzimuthStd(azimuths)
% input in radians

    % % find the average azimuth, accounting for the 0°==180° degeneracy
    % [~,AzimuthAverage] = getAzimuthAverageUsingDipoles(azimuths);

    % get azimuth average in radians
    AzimuthAverage = getAzimuthAverage(azimuths);

    % total number of azimuths
    nAzimuths = length(azimuths);

    % vector to hold each azimuth's deviation from the mean
    %AzimuthDiff = zeros(size(AzimuthAverage));


    %% the following code to find differences from the mean should be replaced with a more elegant approach

    % old method below
    % for i = 1:length(azimuths)
    %     % deviation is the smallest angle between each azimuth and the mean
    %     % there are 3 cases to consider:
    %     % case 1 is where the azimuth and mean azimuth are BOTH positive or negative
    %     if (azimuths(i)<0 && AzimuthAverage<0)||(azimuths(i)>0 && AzimuthAverage>0)
    %         AzimuthDiff(i) = azimuths(i)-AzimuthAverage;
    %     elseif azimuths(i)<0
    %         % cases 2 and 3 are where one is positive and the other is negative
    %         % add 180 to the negative value then calculate deviation
    %         AzimuthDiff(i) = min(abs((azimuths(i)+180)-AzimuthAverage),abs(azimuths(i)-AzimuthAverage));
    %     elseif AzimuthAverage<0
    %         AzimuthDiff(i) = min(abs(azimuths(i)-(AzimuthAverage+180)),abs(azimuths(i)-AzimuthAverage));
    %     end
    % end

    %% trying new method - input in radians, output in degrees

    % % %don't need to take abs() of the output since we are squaring later
    % AzimuthDiff = getAzimuthDiff(AzimuthAverage,azimuths);
    % 
    % % square the differences
    % AzimuthDiffSquared = AzimuthDiff.^2;
    % 
    % % compute the (uncorrected) standard deviation from the mean
    % azimuthStd = sqrt(sum(AzimuthDiffSquared)/nAzimuths);

    %% yet another new method to calculate the actual circular standard deviation

    % axial correction
    %azimuths = mod(azimuths*2,2*pi);

    % mean resultant vector length
    r = abs(mean(exp(1i*azimuths*2)));

    % get the circular standard deviation
    azimuthStd = rad2deg(sqrt(-2*log(r))*0.5);

    % get the angular deviation
    %azimuthAngularDeviation = sqrt(2*(1-r));


end