function [amplitude,azimuth] = fitToSquaredCosine(I)
% given an mxnx3 intensity stack, fits to a squared cosine and returns the normalized peak-to-peak amplitude and phase (in radians)
phiEx = [0,pi/4,pi/2,3*pi/4];

Isz = size(I,1:2);

amplitude = zeros(Isz);
azimuth = zeros(Isz);

% linearly spaced vector (in radians) of phi angles (x values)
phiFit = linspace(0,pi,181);

for i = 1:numel(amplitude)

    % get row and col indx for this pixel
    [y,x] = ind2sub(Isz,i);
    % get intensity stack for this pixel
    I_phi = zeros(1,4);
    I_phi(1:4) = I(y,x,:);

%% Estimate initial values
    I_max = max(I_phi);
    I_min = min(I_phi);
    I_range = (I_max-I_min);
    % estimate offset
    I_mean = mean(I_phi);

%% Anonymous fitting functions
    % Function to fit
    fit = @(b,phiEx)  b(1).*cos(2.*(phiEx - b(2))) + b(3);
    % Least-Squares cost function
    leastSquares = @(b) sum((fit(b,phiEx) - I_phi).^2);
    % Minimise Least-Squares
    s = fminsearch(leastSquares, [I_range; 1;  I_mean]);

    if s(1)>0.1
        blah = 0;
    end

    %% Get values of curve fit for current pixel
    CurveFit = fit(s,phiFit);

    %% estimate amplitude and phase
    [maxCurveFit,maxIdx] = max(CurveFit);
    minCurveFit = min(CurveFit);

    % M = modulation depth
    %M = (maxCurveFit-minCurveFit)/(maxCurveFit+minCurveFit);

    amplitude(i) = (maxCurveFit-minCurveFit)/(maxCurveFit+minCurveFit);

    % below works for pre-normalized values (I think)
    % amplitude(i) = (maxCurveFit-minCurveFit);


    azimuth(i) = phiFit(maxIdx);

end




end