function PlotFullAzimuthQuiver(source,~)
% in a new window, plot the full azimuth quiver plot

% get the data structure
OOPSData = guidata(source);

% get the current image
cImage = OOPSData.CurrentImage(1);


fH = uifigure("WindowStyle","alwaysontop",...
    "Name","Azimuth stick plot",...
    "Position",[100 100 500 500],...
    "Visible","off");

grid = uigridlayout(fH,[1,1]);

ax = uiaxes(grid,...
    "XLim",[0.5 cImage.Width+0.5],...
    "YLim",[0.5 cImage.Height+0.5],...
    "XTick",[],...
    "YTick",[],...
    'YDir','reverse');

pbar = ax.PlotBoxAspectRatio;
dar = ax.DataAspectRatio;

img = imshow(cImage.I,'Parent',ax);

ax.PlotBoxAspectRatio = pbar;
ax.DataAspectRatio = dar;


LineMask = true(size(cImage.AzimuthImage));

LineScaleDown = OOPSData.Settings.AzimuthScaleDownFactor;

if LineScaleDown > 1
    ScaleDownMask = makeSpacedCheckerboard(size(LineMask),LineScaleDown);
    LineMask = LineMask & logical(ScaleDownMask);
end

[Y,X] = find(LineMask);

theta = cImage.AzimuthImage(LineMask);
rho = cImage.OrderImage(LineMask);

ColorMode = OOPSData.Settings.AzimuthColorMode;
LineWidth = OOPSData.Settings.AzimuthLineWidth;
LineAlpha = OOPSData.Settings.AzimuthLineAlpha;
LineScale = OOPSData.Settings.AzimuthLineScale;

switch ColorMode
    case 'Magnitude'
        Colormap = OOPSData.Settings.OrderColormap;
    case 'Direction'
        Colormap = repmat(OOPSData.Settings.AzimuthColormap,2,1);
    case 'Mono'
        Colormap = [1 1 1];
end

OOPSData.Handles.AzimuthLines = QuiverPatch2(ax,...
    X,...
    Y,...
    theta,...
    rho,...
    ColorMode,...
    Colormap,...
    LineWidth,...
    LineAlpha,...
    LineScale);

movegui(fH,'center')

fH.Visible = 'On';

end