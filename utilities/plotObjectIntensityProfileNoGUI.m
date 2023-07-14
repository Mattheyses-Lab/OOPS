function axH = plotObjectIntensityProfileNoGUI(Object)

% the object mask
Mask = Object.RestrictedPaddedMaskSubImage;

PaddedSubarrayIdx = padSubarrayIdx(Object.SubarrayIdx,5);
% initialize pixel-normalized intensity stack for curve fitting
PaddedObjPixelNormIntensity = zeros([size(Mask),4]);
% get pixel-normalized intensity stack for curve fitting
PaddedObjPixelNormIntensity(:) = Object.Parent.ffcFPMPixelNorm(PaddedSubarrayIdx{:},:);
% x and y values to fit to the sinusoid
x = [0,pi/4,pi/2,3*(pi/4)];
% y values to fit to the sinusoid
Y = PaddedObjPixelNormIntensity;




figH = uifigure("HandleVisibility","on","Color",[1 1 1]);

figH.Position = [50 50 600 200];

axH = uiaxes(figH);
axH.Units = 'normalized';
axH.OuterPosition = [0 0 1 1];

axH.XTick = (0:pi/4:pi);
axH.XTickLabel = {'0°','45°','90°','135°','180°'};

labelColor = [0 0 0];


    % get unmasked row,col indices
    [RowIndices,ColIndices] = find(Mask==1);
    
    nPixels = length(RowIndices);
    
    DefaultAxColor = axH.Color;
    
    %xp = 0:pi/1000:pi;
    xp = linspace(0,pi,181);

    CurveFit = cell(1,nPixels);

    parfor i = 1:nPixels
        
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
%% Get y values of curve fit for current pixel       

        % y values to plot - found with the fitting function
        CurveFit{i} = fit(s,xp);

    end

%% Add or subtract an offset from each curve so glabal max = 1    
    CurveFitsNormalized = CurveFit;
    MaxY = max(cell2mat(CurveFitsNormalized));
    if MaxY>1
        Offset = MaxY-1;
        %disp(['Max y fit value > 1, subtracting ',num2str(Offset),' offset from each pixel fit...']);
        for i = 1:nPixels
            CurveFitsNormalized{i} = CurveFitsNormalized{i}-Offset;
        end
    else
        Offset = 1-MaxY;
        %disp(['Max y fit value < 1, adding ',num2str(Offset),' offset to each pixel fit...']);
        for i = 1:nPixels
            CurveFitsNormalized{i} = CurveFitsNormalized{i}+Offset;
        end
    end
    
    % initialize vector to sum up fits
    CurveFitSum = zeros(size(CurveFit{1}));

    % set the current axes
    set(figH,'CurrentAxes',axH);
    
    polX_combined = [];
    polY_combined = [];

    azX_combined = [];
    azY_combined = [];

    for i = 1:nPixels
        CurveFitSum = CurveFitSum+CurveFitsNormalized{i};
        % plot the fit line
        polX_combined = [polX_combined,NaN,xp];
        polY_combined = [polY_combined,NaN,CurveFitsNormalized{i}];

        %plot(axH,xp,CurveFitsNormalized{i},'Color','#A9A9A9','LineWidth',1,'HitTest','Off','LineStyle',':')
        %axH.NextPlot = 'Add';
        hold on
        % find the max of each curve and draw a vertical line at x where f(x) = YMax
        % to show the phase
        MaxVal = max(CurveFitsNormalized{i});
        % 2nd argument of find() set to 1 just in case MaxIdx is exactly
        % 0, which would make make MaxIdx also = pi
        MaxIdx = find(CurveFitsNormalized{i} == MaxVal,1);
        azX_combined = [azX_combined,NaN,xp(MaxIdx),xp(MaxIdx)];
        azY_combined = [azY_combined,NaN,0,MaxVal];
        %line(axH,[xp(MaxIdx),xp(MaxIdx)],[0,MaxVal],'LineStyle',':','LineWidth',1,'HitTest','Off');
    end
    line(axH,azX_combined,azY_combined,'LineStyle','-','LineWidth',1,'HitTest','Off');
    plot(axH,polX_combined,polY_combined,'Color','#A9A9A9','LineWidth',1,'HitTest','Off','LineStyle','-')

    CurveFitAvg = CurveFitSum./nPixels;
%%

    MaxY = max(cell2mat(CurveFitsNormalized));
    MinY = min(cell2mat(CurveFitsNormalized));
    
    PctBuffer = 0.1;
    
    YLowerLim = MinY-PctBuffer;
    YUpperLim = MaxY+PctBuffer;

    % plot the average fit
    plot(axH,xp,CurveFitAvg,'LineWidth',4,'Color',labelColor);
    
    MaxVal = max(CurveFitAvg);
    MaxIdx = find(CurveFitAvg==MaxVal,1);
    
    MinVal = min(CurveFitAvg);
    MinIdx = find(CurveFitAvg==MinVal,1);
    
    OrderFactorFit = MaxVal-MinVal;
    AzimuthRadians = xp(MaxIdx);
    
    % dotted vert line showing azimuth
    line(axH,[xp(MaxIdx),xp(MaxIdx)],[0,MaxVal],'LineStyle','--','LineWidth',2,'HitTest','Off','Color',labelColor);
    
    % dashed line showing max value
    line(axH,[xp(MaxIdx),xp(MinIdx)],[MaxVal,MaxVal],'LineStyle','--','LineWidth',2,'HitTest','Off','Color',labelColor);
    
    % vert line and text object showing OF fit
    line(axH,[xp(MinIdx),xp(MinIdx)],[MaxVal,MinVal],'LineStyle','-','LineWidth',2,'HitTest','Off','Color',labelColor);
    txtOF = [' OF Fit: ',num2str(round(OrderFactorFit,2)),' '];
    txtAzimuth = [' Azimuth Fit: ',num2str(round(rad2deg(AzimuthRadians))),'° '];
    
    % if xp(MaxIdx) > pi/2
    %     text(axH,...
    %         xp(MinIdx),MaxVal-OrderFactorFit/2,...
    %         txtOF,...
    %         'Units','data',...
    %         'HorizontalAlignment','Left',...
    %         'Color',labelColor,...
    %         'FontWeight','bold');
    %     text(axH,...
    %         xp(MaxIdx),MaxVal-(MaxVal-YLowerLim)/2,...
    %         txtAzimuth,...
    %         'Units','data',...            
    %         'HorizontalAlignment','Right',...
    %         'Color',labelColor,...
    %         'FontWeight','bold');
    % else
    %     text(axH,...
    %         xp(MinIdx),MaxVal-OrderFactorFit/2,...
    %         txtOF,...
    %         'Units','data',...            
    %         'HorizontalAlignment','Right',...
    %         'Color',labelColor,...
    %         'FontWeight','bold');
    %     text(axH,...
    %         xp(MaxIdx),MaxVal-(MaxVal-YLowerLim)/2,...
    %         txtAzimuth,...
    %         'Units','data',...            
    %         'HorizontalAlignment','Left',...
    %         'Color',labelColor,...
    %         'FontWeight','bold');
    % end
    
    hold off
    
    %set(gcf,'Position',[1,1,1792,400]);
    set(axH,'XLim',[0 pi]);
    set(axH,'YLim',[YLowerLim YUpperLim]);

end