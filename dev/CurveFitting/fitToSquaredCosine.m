function [amplitude,phase,XFit,YFit] = fitToSquaredCosine(Y)
% given an mxnx4 intensity stack, fits to a squared cosine and returns the normalized peak-to-peak amplitude and phase (in radians)
X = [0,pi/4,pi/2,3*pi/4];

Ysz = size(Y,1:2);

amplitude = zeros(Ysz);
phase = zeros(Ysz);

% linearly spaced vector (in radians) of phi angles (x values)
XFit = linspace(0,pi,181);

for i = 1:numel(amplitude)

    % get row and col idx for pixel i
    [r,c] = ind2sub(Ysz,i);
    % get stack of y values for pixel i
    pixelY = zeros(1,4);
    pixelY(1:4) = Y(r,c,:);

%% Estimate initial values

    Ymax = max(pixelY);
    Ymin = min(pixelY);
    Yrange = (Ymax-Ymin);
    % estimate offset
    Ymean = mean(pixelY);

%% Fit values to cos^2 function

    % fit function 1 : Y = A * cos(2 * (X - B)) + C

    % anonymous fitting function
    % fit = @(b,XFit)  b(1).*cos(2.*(XFit - b(2))) + b(3);


    % fit function 2 : Y = (A * (1 + cos(2 * (X - B))) + C) / 2

    %fit = @(b,XFit)  (b(1).*(1 + cos(2.*(XFit - b(2)))) + b(3))./2;


    % fit function 3 : Y = A * ((1 + cos(2 * (X - B))) / 2) + C

    fit = @(b,XFit)  b(1) .*  (1 + cos(2.* (XFit - b(2)) ) )./2 + b(3);



    % anonymous least squares cost function
    leastSquares = @(b) sum((fit(b,X) - pixelY).^2);
    % minimize least squares
    s = fminsearch(leastSquares, [Yrange; 1;  Ymean]);

    % store retrieved parameters
    A = s(1);
    B = s(2);
    C = s(3);

    %% Use the fit parameters to calculate Y values for X in [0 pi]

    YFit = fit(s,XFit);

    %% estimate amplitude and phase
    [maxVal,maxIdx] = max(YFit);

    minVal = min(YFit);

    disp('FITTING PARAMETERS')
    disp(['A = ',num2str(A)]);
    disp(['B = ',num2str(B)]);
    disp(['C = ',num2str(C)]);

    fprintf('\n')

    disp('CURVE VALUES')
    disp(['max = ',num2str(maxVal)]);
    disp(['min = ',num2str(minVal)]);
    disp(['max - min = ',num2str(maxVal - minVal)])

    % calculate amplitude and phase directly from the curve
    %amplitude(i) = (maxVal-minVal)/(maxVal+minVal);

    amplitude(i) = (maxVal-minVal)/(maxVal+minVal);


    phase(i) = XFit(maxIdx);


    % M = modulation depth
    %M = (maxCurveFit-minCurveFit)/(maxCurveFit+minCurveFit);

end




end