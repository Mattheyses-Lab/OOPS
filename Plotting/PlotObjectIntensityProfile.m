function axH = PlotObjectIntensityProfile(x,Y,Mask,axH)

    %axes(axH)

    % get unmasked row,col indices
    [RowIndices,ColIndices] = find(Mask==1);
    
    nPixels = length(RowIndices);
    
    CurveFit = {};
    
    DefaultAxColor = axH.Color;
    
    
    for i = 1:nPixels
        
        y = zeros(1,4);
        y(1:4) = Y(RowIndices(i),ColIndices(i),:);
        
%% Estimate initial values
        yu = max(y);
        yl = min(y);
        yr = (yu-yl);                               % Range of ‘y’
        yz = y-yu+(yr/2);
        zx = x(yz .* circshift(yz,[0 1]) <= 0);     % Find zero-crossings

        % Estimate offset
        ym = mean(y);

%% Anonymous fitting functions        
        % Function to fit
        fit = @(b,x)  b(1).*cos(2.*(x - b(2))) + b(3);
        % Least-Squares cost function
        fcn = @(b) sum((fit(b,x) - y).^2);
        % Minimise Least-Squares
        s = fminsearch(fcn, [yr; 1;  ym]);
%% Get x and y values of curve fit for current pixel       
        % x values to plot
        %xp = linspace(min(x),pi);
        xp = [0:pi/1000:pi];
        
        
        % y values to plot - found with the fitting function
        CurveFit{i} = fit(s,xp);

    end

%% Add or subtract an offset from each curve so glabal max = 1    
    CurveFitsNormalized = CurveFit;
    MaxY = max(cell2mat(CurveFitsNormalized));
    if MaxY>1
        Offset = MaxY-1;
        disp(['Max y fit value > 1, subtracting ',num2str(Offset),' offset from each pixel fit...'])
        for i = 1:nPixels
            CurveFitsNormalized{i} = CurveFitsNormalized{i}-Offset;
        end
    else
        Offset = 1-MaxY;
        disp(['Max y fit value < 1, adding ',num2str(Offset),' offset to each pixel fit...'])
        for i = 1:nPixels
            CurveFitsNormalized{i} = CurveFitsNormalized{i}+Offset;
        end
    end
    
    % initialize vector to sum up fits
    CurveFitSum = zeros(size(CurveFit{1}));
    
    RandomColors = MakeRandomColorSet(nPixels);
    
    for i = 1:nPixels
        CurveFitSum = CurveFitSum+CurveFitsNormalized{i};
        % plot the fit line
        plot(axH,xp,CurveFitsNormalized{i},'Color','#A9A9A9','LineWidth',2)
        axH.NextPlot = 'Add';
        hold on
        % find the max of each curve and draw a vertical line at x where f(x) = YMax
        % to show the phase
        MaxVal = max(CurveFitsNormalized{i});
        % 2nd argument of find() set to 1 just in case MaxIdx is exactly
        % 0, which would make make MaxIdx also = pi
        MaxIdx = find(CurveFitsNormalized{i} == MaxVal,1);
        line(axH,[xp(MaxIdx),xp(MaxIdx)],[0,MaxVal],'LineStyle','-','LineWidth',1);
    end
    CurveFitAvg = CurveFitSum./nPixels;
%%

    MaxY = max(cell2mat(CurveFitsNormalized));
    MinY = min(cell2mat(CurveFitsNormalized));
    YRange = MaxY-MinY;
    
    % calculate the space below the minimum value as 5% of the range of y-values
    BottomSpace = 0.05*YRange;
    YLowerLim = MinY-BottomSpace;


    % plot the average fit
    plot(axH,xp,CurveFitAvg,'LineWidth',4,'Color','Yellow');
    
    hold off
    axH.NextPlot = 'Replace';
    
    %set(gcf,'Position',[1,1,1792,400]);
    set(axH,'XLim',[0 pi]);
    set(axH,'YLim',[YLowerLim 1]);
    set(axH,'Color','Black');
    set(axH,'XColor','Yellow');
    set(axH,'YColor','Yellow');
    set(axH,'Box','on');
    set(axH,'BoxStyle','back');
    axH.Title.Color = 'Yellow';
    axH.Title.Visible = 'On';
    
    OrderFactorFit = max(CurveFitAvg) - min(CurveFitAvg)
    MaxIndex = find(CurveFitAvg==max(CurveFitAvg))
    AzimuthRadians = xp(MaxIndex)


end