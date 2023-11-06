function axH = PlotObjectIntensityProfile(...
    xReal,...
    yReal,...
    Mask,...
    axH,...
    FitLineColor,...
    PixelLinesColor,...
    AnnotationsColor,...
    AzimuthLinesColor)

    % locations in the stack that we are considering
    [RowIndices,ColIndices] = find(Mask==1);
    % number of pixels in the image stack (nRows*nCols)
    nPixels = length(RowIndices);
    % vector of x values to pass into the function obtained by fitting
    xFit = linspace(0,pi,181);
    % prealocate cell array of sinusoidal fits for each pixel
    CurveFit = cell(nPixels,1);

    parfor i = 1:nPixels
        %% each vector in the third dimension is a set of y values for one round of fitting (one pixel)
        yFit = zeros(1,4);
        yFit(1:4) = yReal(RowIndices(i),ColIndices(i),:);
        %% Estimate initial values
        % maximum y value
        yMax = max(yFit);
        % minimum y value
        yMin = min(yFit);
        % peak-to-peak amplitude
        yRange = yMax-yMin;
        %% Fit experimental values to a generic squared cosine: Y = A * ((1+cos(2(X-B))/2) + C
        % anonymous fit function
        fit = @(b,x)  b(1) .* ((1 + cos(2.*(x-b(2))))./2) + b(3);
        % least-squares cost function to minimize
        fcn = @(b) sum((fit(b,xReal) - yFit).^2);
        % minimize least-squares
        s = fminsearch(fcn, [yRange; 1;  yMin]);
        %% Generate full curves using the parameters obtained above
        % y values to plot - found with the fitting function
        CurveFit{i} = fit(s,xFit);
    end

%% concatenate fit curves and phase lines for all pixels (new method without loop)

    % convert CurveFit cell array to nPixels x 181 matrix
    CurveFitMat = cell2mat(CurveFit);
    % get the average of all fits
    CurveFitAvg = mean(CurveFitMat,1);
    % create a cell array of NaNs, same size as CurveFit
    nanCell = arrayfun(@(x) x,nan(nPixels,1),'UniformOutput',false);
    % cell array with nPixels copies of xFit vectors
    xFitCell = repmat({xFit},nPixels,1);
    % combined x and y data for all fit lines (excluding average fit)
    xFitCombined = cell2mat(Interleave2DArrays(xFitCell,nanCell,'row')');
    yFitCombined = cell2mat(Interleave2DArrays(CurveFit,nanCell,'row')');
    % get max values and idx to the max values for each fit
    [maxVal,maxIdx] = max(CurveFitMat,[],2);
    % combined x and y data for all vertical phase lines
    xMaxCombined = cell2mat(Interleave2DArrays(arrayfun(@(x) [x x],xFit(maxIdx)','UniformOutput',false),nanCell,'row')');
    yMaxCombined = cell2mat(Interleave2DArrays(arrayfun(@(x) [0 x],maxVal,'UniformOutput',false),nanCell,'row')');
    % get max and minimum values for all curve fits
    MaxY = max(CurveFitMat,[],"all");
    MinY = min(CurveFitMat,[],"all");
    % plot each fit curve along with vertical lines to show phase
    line(axH,xMaxCombined,yMaxCombined,'Color',AzimuthLinesColor,'LineStyle',':','LineWidth',1,'HitTest','Off');
    line(axH,xFitCombined,yFitCombined,'Color',PixelLinesColor,'LineWidth',1,'HitTest','Off','LineStyle',':');
    
%% plot average fit line and amplitude/phase annotiations, set axes properties

    % amount of buffer on either side of the fit lines (in y)
    PctBuffer = 0.1;
    
    % upper and lower y-axes limits
    YLowerLim = MinY-PctBuffer;
    YUpperLim = MaxY+PctBuffer;

    % plot the average fit line
    line(axH,xFit,CurveFitAvg,'LineWidth',4,'Color',FitLineColor);
    
    % get max and min values (and idxs) for the average of all fits
    [MaxVal,MaxIdx] = max(CurveFitAvg);
    [MinVal,MinIdx] = min(CurveFitAvg);

    % measure amplitude (Order) and phase (azimuth) from the average fit
    OrderFit = MaxVal-MinVal;
    AzimuthFit = xFit(MaxIdx);
    
    % dotted vertical line showing azimuth
    line(axH,[xFit(MaxIdx),xFit(MaxIdx)],[0,MaxVal],'LineStyle','--','LineWidth',1,'HitTest','Off','Color',AnnotationsColor);
    % dashed horizontal line showing max value
    line(axH,[xFit(MaxIdx),xFit(MinIdx)],[MaxVal,MaxVal],'LineStyle','--','LineWidth',1,'HitTest','Off','Color',AnnotationsColor);
    % vertical line at minimum shwoing peak-to-peak amplitude
    line(axH,[xFit(MinIdx),xFit(MinIdx)],[MaxVal,MinVal],'LineStyle','-','LineWidth',1,'HitTest','Off','Color',AnnotationsColor);

    % text for amplitude and phase labels
    txtOrder = [' Order (fit): ',num2str(round(OrderFit,2)),' '];
    txtAzimuth = [' Azimuth (fit): ',num2str(round(rad2deg(AzimuthFit))),'° '];
    
    % determine whether to align text left or right
    if xFit(MaxIdx) > pi/2
        orderTextAlignment = 'Left';
        azimuthTextAlignment = 'Right';
    else
        orderTextAlignment = 'Right';
        azimuthTextAlignment = 'Left'; 
    end

    % create primitive text object to label amplitude and phase lines
    text(axH,...
        xFit(MinIdx),MaxVal-OrderFit/2,...
        txtOrder,...
        'Units','data',...
        'HorizontalAlignment',orderTextAlignment,...
        'Color',AnnotationsColor);
    text(axH,...
        xFit(MaxIdx),MaxVal-(MaxVal-YLowerLim)/2,...
        txtAzimuth,...
        'Units','data',...
        'HorizontalAlignment',azimuthTextAlignment,...
        'Color',AnnotationsColor);

    % set axes limits
    set(axH,'XLim',[0 pi],'YLim',[YLowerLim YUpperLim]);

end