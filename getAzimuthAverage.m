function AzimuthAverage = getAzimuthAverage(azimuths)
% expects input and return output in radians

%% new method

AzimuthAverage = getBiaxialMean(azimuths);

%% the old method
    % % we use 4 reference angles to estimate the average azimuth
    % refAngles = repmat([0 pi/4 pi/2 (3*pi)/4],numel(azimuths),1);
    % 
    % % taking the average of the squared cosine of the differences between each measurement and ref angle
    % Itotal = cos(refAngles-azimuths).^2;
    % Iavg = mean(Itotal,1);
    % 
    % % finally, use the 2-argument atan to find the average
    % AzimuthAverage = atan2((Iavg(2)-Iavg(4)),(Iavg(1)-Iavg(3)))*0.5;
end