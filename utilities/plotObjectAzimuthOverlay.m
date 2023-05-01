function ObjectAzimuthLines = plotObjectAzimuthOverlay(Object,cmap)
% plots the average object intensity image with azimuth lines overlaid when given a OOPSObject as input
% returns a handle to the azimuth plot

I = Object.PaddedFFCIntensitySubImage;

if ~isempty(cmap)
    intensityColormap = cmap;
else
    intensityColormap = gray;
end

% create 'circular' colormap by vertically concatenating 2 hsv maps
tempmap = hsv;
circmap = vertcat(tempmap,tempmap);

LineMask = Object.RestrictedPaddedMaskSubImage;

[y,x] = find(LineMask==1);
theta = Object.PaddedAzimuthSubImage(LineMask);
rho = Object.PaddedOFSubImage(LineMask);

ColorMode = 'Mono';
LineWidth = 3;
LineAlpha = 1;
LineScale = 10;

% set colormap depending on color mode
switch ColorMode
    case 'Direction'
        Colormap = circmap;
    case 'Mono'
        Colormap = [1 1 1];
end

% plot intensity image with imshow(), return the handle
[hImg,hAx] = imshow3(I);

% set the colormap
hAx.Colormap = intensityColormap;

% plot pixel azimuth sticks for the object
ObjectAzimuthLines = QuiverPatch2(hAx,...
    x,...
    y,...
    theta,...
    rho,...
    ColorMode,...
    Colormap,...
    LineWidth,...
    LineAlpha,...
    LineScale);

objectPaddedSize = size(Object.RestrictedPaddedMaskSubImage);

hAx.YLim = [0.5 objectPaddedSize(1)+0.5];
hAx.XLim = [0.5 objectPaddedSize(2)+0.5];

end