function pAx = plotBiaxialPolarHistogram(azimuths,Options)

% argument validation
arguments
    azimuths (1,:) double
    Options.FaceColor (1,3) double = [1 1 1]
    Options.BarLineWidth (1,1) {mustBeNumeric} = 1

    Options.ThetaAxisLineWidth (1,1) {mustBeNumeric} = 2
    Options.ThetaColor (1,3) double = [0 0 0]
    Options.ThetaAxisColor (1,3) double = [0 0 0]
    
end



    fH = uifigure('HandleVisibility','on',...
        'Visible','off',...
        'InnerPosition',[0 0 900 900],...
        'AutoResizeChildren','off',...
        'Color',[1 1 1]);

    pAx = polaraxes(fH,'Units','Normalized','OuterPosition',[0 0 1 1]);

    pHist1 = polarhistogram(pAx,azimuths,...
        'FaceColor',Options.FaceColor,...
        'LineWidth',Options.BarLineWidth,...
        'FaceAlpha',1);
    hold on
    pHist2 = polarhistogram(pAx,azimuths+pi,...
        'FaceColor',Options.FaceColor,...
        'LineWidth',Options.BarLineWidth,...
        'FaceAlpha',1);
    hold off

    pAx.ThetaColorMode = 'manual';
    pAx.RColorMode = 'manual';

    pAx.GridAlphaMode = 'manual';
    pAx.GridColorMode = 'manual';

    pAx.MinorGridColorMode = 'manual';
    pAx.MinorGridAlphaMode = 'manual';

    pAx.Color = [1 1 1];
    pAx.LineWidth = 1;


    % adjust grid lines
    pAx.GridAlpha = 1;
    pAx.GridColor = [0.9 0.9 0.9];    
    
    pAx.ThetaMinorGrid = 'on';
    pAx.MinorGridColor = [0.95 0.95 0.95];
    pAx.MinorGridAlpha = 1;

    % adjust theta axis
    pAx.ThetaAxis.LineWidth = Options.ThetaAxisLineWidth;
    pAx.ThetaAxis.Color = Options.ThetaAxisColor;
    pAx.ThetaColor = Options.ThetaColor;
    pAx.ThetaAxis.FontSize = 12;

    movegui(fH,'center');
    fH.Visible = 'on';

end