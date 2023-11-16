function PlotFullAzimuthQuiver(source,~)
% in a new window, plot the full azimuth quiver plot
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

% get the data structure
OOPSData = guidata(source);

% currently selected image(s)
cImage = OOPSData.CurrentImage;

%% error checking

% no image found
if isempty(cImage)
    uialert(OOPSData.Handles.fH,'No image found','Error')
    return
else
    cImage = cImage(1);
end

% FPM stats not done
if ~cImage.FPMStatsDone
    uialert(OOPSData.Handles.fH,'Compute FPM statistics first','Error')
    return
end

%% create the figure, axes, etc.

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

%% gather settings

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

%% get data for the plot

LineMask = true(size(cImage.AzimuthImage));

LineScaleDown = OOPSData.Settings.AzimuthScaleDownFactor;

if LineScaleDown > 1
    ScaleDownMask = makeSpacedCheckerboard(size(LineMask),LineScaleDown);
    LineMask = LineMask & logical(ScaleDownMask);
end

[Y,X] = find(LineMask);

theta = cImage.AzimuthImage(LineMask);
rho = cImage.OrderImage(LineMask);

%% plot the patch object

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

%% center the figure and make the window visible

movegui(fH,'center')

fH.Visible = 'On';

end