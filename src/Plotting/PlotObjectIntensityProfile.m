function axH = PlotObjectIntensityProfile(...
    xReal,...
    yReal,...
    Mask,...
    axH,...
    FitLineColor,...
    PixelLinesColor,...
    AnnotationsColor,...
    AzimuthLinesColor)

    % get unmasked row,col indices
    [RowIndices,ColIndices] = find(Mask==1);
    
    nPixels = length(RowIndices);
    
    xFit = linspace(0,pi,181);

    % prealocate cell array of sinusoidal fits for each pixel
    CurveFit = cell(nPixels,1);

    parfor i = 1:nPixels
        
        yFit = zeros(1,4);
        yFit(1:4) = yReal(RowIndices(i),ColIndices(i),:);
        
%% Estimate initial values
        yMax = max(yFit);
        yMin = min(yFit);
        yRange = (yMax-yMin);

        % Estimate offset
        yMean = mean(yFit);

%% Anonymous fitting functions        
        % Function to fit
        %fit = @(b,x)  b(1).*cos(2.*(x - b(2))) + b(3);

        % testing below
        %fit = @(b,x)  (b(1).*(1 + cos(2.*(x - b(2)))) + b(3))./2;

        % THIS IS THE MOST CORRECT FORM OF THE FIT FUNCTION
        %   Y = A * ((1+cos(2(X-B))/2) + C
        % above functions give identical results (in terms of y values), 
        % but the fit parameters do not match those from a generic cos^2 
        fit = @(b,x)  b(1) .* ((1 + cos(2.*(x-b(2))))./2) + b(3);

        % Least-Squares cost function to minimize
        fcn = @(b) sum((fit(b,xReal) - yFit).^2);

        % Minimise Least-Squares
        s = fminsearch(fcn, [yRange; 1;  yMin]);

%% Get y values of curve fit for current pixel       

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
    
    % amount of buffer on either side of the fit lines (in y)
    PctBuffer = 0.1;
    
    % upper and lower y-axes limits
    YLowerLim = MinY-PctBuffer;
    YUpperLim = MaxY+PctBuffer;

    % plot the average fit line
    line(axH,xFit,CurveFitAvg,'LineWidth',4,'Color',FitLineColor);
    
    MaxVal = max(CurveFitAvg);
    MaxIdx = find(CurveFitAvg==MaxVal,1);
    
    MinVal = min(CurveFitAvg);
    MinIdx = find(CurveFitAvg==MinVal,1);
    
    OrderFit = MaxVal-MinVal;
    AzimuthRadians = xFit(MaxIdx);
    
    % dotted vertical line showing azimuth
    line(axH,[xFit(MaxIdx),xFit(MaxIdx)],[0,MaxVal],'LineStyle','--','LineWidth',1,'HitTest','Off','Color',AnnotationsColor);
    % dashed horizontal line showing max value
    line(axH,[xFit(MaxIdx),xFit(MinIdx)],[MaxVal,MaxVal],'LineStyle','--','LineWidth',1,'HitTest','Off','Color',AnnotationsColor);
    % vertical line at minimum shwoing peak-to-peak amplitude
    line(axH,[xFit(MinIdx),xFit(MinIdx)],[MaxVal,MinVal],'LineStyle','-','LineWidth',1,'HitTest','Off','Color',AnnotationsColor);

    % text for amplitude and phase labels
    txtOrder = [' Order (fit): ',num2str(round(OrderFit,2)),' '];
    txtAzimuth = [' Azimuth (fit): ',num2str(round(rad2deg(AzimuthRadians))),'° '];
    
    % determine whether to align text left or right
    if xFit(MaxIdx) > pi/2
        orderTextAlignment = 'Left';
        azimuthTextAlignment = 'Right';
    else
        orderTextAlignment = 'Right';
        azimuthTextAlignment = 'Left'; 
    end

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