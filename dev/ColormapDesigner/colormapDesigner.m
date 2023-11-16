function cmap_out = colormapDesigner(I)
%%  colormapDesigner Opens a GUI to interactively create a custom colormap
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

    % default output colormap
    cmap_out = gray;

    % if no image provided, use "rice.png"
    if isempty(I)
        I = im2double(imread("rice.png"));
    end

    % size of the image (rows,cols)
    Isz = size(I);

    % main figure
    fH = uifigure("HandleVisibility","on",...
        "WindowStyle","alwaysontop",...
        "Name","Colormap Designer",...
        "Position",[0 0 500 200],...
        "Visible","off",...
        "CloseRequestFcn",@closeAndReturnColormap);

    % gridlayout manager to hold the colorbarWidget and example image
    mainGrid = uigridlayout(fH,[2,1],...
        "ColumnWidth",{'1x'},...
        "RowHeight",{'fit','1x'},...
        "Padding",[5 5 5 5],...
        "RowSpacing",5);

    % create a colorbarWidget object and place it in the grid
    colorbarWidget = colormapSliderWidget(mainGrid);
    colorbarWidget.Layout.Row = 1;

    % uiaxes to hold the example image
    hAx = uiaxes(mainGrid,...
        "XTick",[],...
        "YTick",[],...
        "XLim",[0.5 Isz(2)],...
        "YLim",[0.5 Isz(1)]);

    % store plotbox and data aspect ratios so we can restore dimensions after imshow()
    oldPBAR = hAx.PlotBoxAspectRatio;
    oldDAR = hAx.DataAspectRatio;

    % plot the image
    hImg = imshow(I,'Parent',hAx);

    % restore dimensions, show box around image
    set(hAx,...
        'PlotBoxAspectRatio',oldPBAR,...
        'DataAspectRatio',oldDAR,...
        'Visible','On',...
        'LineWidth',2,...
        'Box','On');

    % set callback function - called when colormap changes
    colorbarWidget.ColormapChangedFcn = @updateColormap;

    % get new width and height to roughly match figure inner dimensions to image dimensions + padding
    newWidth = Isz(2)+10+10;
    newHeight = Isz(1)+15+10+30;
    
    % adjust size if height larger than 750
    scaleFactor = 750/newHeight;
    newHeight = newHeight*scaleFactor;
    newWidth = newWidth*scaleFactor;

    % set the new figure width and height
    fH.InnerPosition(3) = newWidth;
    fH.InnerPosition(4) = newHeight;

    % move gui to the center and make it visible
    movegui(fH,'center');
    fH.Visible = 'On';

    % wait until figure is closed to exit
    waitfor(fH)

    %% nested callbacks

    % called when colormap changes
    function updateColormap(source,~)
        hAx.Colormap = source.cmap;
    end

    % called when user closes figure
    function closeAndReturnColormap(~,~)
        cmap_out = colorbarWidget.cmap;
        delete(fH);
        return
    end

end