function cmap_out = colormapDesigner2(I)
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

    arguments
        I (:,:) double = im2double(imread("rice.png"))
    end

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
        "Position",[0 0 1000 500],...
        "Visible","off",...
        "CloseRequestFcn",@closeAndReturnColormap);

    % gridlayout manager to hold the colorbarWidget and example image
    mainGrid = uigridlayout(fH,[1,1],...
        "ColumnWidth",{'1x'},...
        "RowHeight",{'1x'},...
        "Padding",[0 0 0 0],...
        "RowSpacing",5);

    
    hcolormapDesignerWidget = colormapDesignerWidget(mainGrid);

    % move gui to the center and make it visible
    movegui(fH,'center');
    fH.Visible = 'On';

    % wait until figure is closed to exit
    waitfor(fH)

    %% nested callbacks

    % called when user closes figure
    function closeAndReturnColormap(~,~)
        cmap_out = hcolormapDesignerWidget.cmap;
        delete(fH);
        return
    end

end