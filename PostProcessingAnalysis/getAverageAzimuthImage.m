function averageAzimuthImage = getAverageAzimuthImage(AzimuthImage)
% still testing, not for use!

%fun = @(x) getLocalAverage(x);

%averageAzimuthImage = nlfilter(AzimuthImage,[3 3],fun);

% size of the input
Isz = size(AzimuthImage);

% 3 by 3 filter
filterSize = 3;
% how much do we need to buffer around the edges of the image
filterBuffer = (filterSize-1)/2;
% the loop mask (the indices we will slide the window across)
loopMask = true(Isz);
loopMask = ClearImageBorder(loopMask,filterBuffer);
% initialize output
averageAzimuthImage = zeros(Isz);


parfor Idx = 1:numel(AzimuthImage)
    if loopMask(Idx)
        % [row,col] = ...
        [i,j] = ind2sub(Isz,Idx);
        % the frame we will be working with
        frame = AzimuthImage(i-filterBuffer:i+filterBuffer,j-filterBuffer:j+filterBuffer);
        % get the average
        averageAzimuthImage(Idx) = getLocalAverage(frame);
    end
end


end

function localAverage = getLocalAverage(I)

    % azimuths = I(:);
    % localAverage = getBiaxialMean(azimuths);

    localAverage = getBiaxialMean(I(:));

    % another method below - slower
    % % we use 4 reference angles to estimate the average azimuth
    % refAngles = repmat([0 pi/4 pi/2 (3*pi)/4],numel(azimuths),1);
    % 
    % % taking the average of the squared cosine of the differences between each measurement and ref angle
    % Itotal = cos(refAngles-azimuths).^2;
    % Iavg = mean(Itotal,1);
    % 
    % % finally, use the 2-argument atan to find the average
    % localAverage = atan2((Iavg(2)-Iavg(4)),(Iavg(1)-Iavg(3)))*0.5;

end