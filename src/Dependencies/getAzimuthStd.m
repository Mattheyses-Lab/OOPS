function azimuthStd = getAzimuthStd(azimuths)
    %% mean resultant vector length (r)
    % first convert azimuths to complex unit vectors, multiplying by two to convert to unimodal scale
    % the take the norm (abs()) of the mean of exponential function of those vectors
    r = abs(mean(exp(1i*azimuths*2)));

    %% circular standard deviation
    azimuthStd = rad2deg(sqrt(-2*log(r))*0.5);

    %% angular deviation
    %azimuthAngularDeviation = sqrt(2*(1-r))*0.5;

end