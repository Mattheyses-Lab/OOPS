function AzimuthAverage = getAzimuthAverage(azimuths)
%%  getAzimuthAverage  returns axial mean (in radians) of a vector of angles (in radians)

% AzimuthAverage = getBiaxialMean(azimuths);

AzimuthAverage = angle(mean(exp(1i*azimuths*2)))/2;

%% step-by-step version shown for clarity

    % % convert to complex vector (multiply by two because we have axial data) and take the mean
    % z = mean(exp(1i*angles*2));
    % 
    % % get real and imaginary components
    % y = imag(z);
    % x = real(z);
    % 
    % % use 4-quadrant inverse tangent function to get the angle 
    % % between the +x axis and a ray from the origin to point (x,y)
    % % (this is accomplished above with the angle() function)
    % rayAngle = atan2(y,x);
    % 
    % % divide by two to return to original scale
    % biaxialMean = rayAngle/2;

end