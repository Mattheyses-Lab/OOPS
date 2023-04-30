function biaxialMean = getBiaxialMean(angles)
% returns the average direction of a vector of biaxial angles
% input and output in radians

    % angle() is equivalent to the mathematical Arg function
    biaxialMean = angle(mean(exp(1i*angles*2)))/2;

%% step-by-step version shown commented for understanding


    % % convert to complex vector (multiply by two because we have biaxial data) and take the mean
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