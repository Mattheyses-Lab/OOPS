function PlotGroupScatterPlotMatrix(source,~)
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

    markerSize = 10;

    % get the main data structure
    OOPSData = guidata(source);

    % get settings for the scatterplot matrix
    ScatterPlotMatrixSettings = getScatterPlotMatrixSettings(...
        OOPSData.Settings.ObjectPlotVariables,OOPSData.Settings.ObjectPlotVariablesLong);

    % make sure the settings are valid (will be empty if invalid)
    if isempty(ScatterPlotMatrixSettings)
        uialert(OOPSData.Handles.fH,'Invalid selection','Error');
        return
    else
        variableList = ScatterPlotMatrixSettings.variableList;
        ColorMode = ScatterPlotMatrixSettings.ColorMode;
        DiagonalDisplay = ScatterPlotMatrixSettings.DiagonalDisplay;

        nVariables = numel(variableList);

        variableListLong = cellfun(@(varname) OOPSData.Settings.expandVariableName(varname),variableList,'UniformOutput',0);

    end

    % get object data for the selected variables
    objectData = OOPSData.getConcatenatedObjectData(variableList);

    % create the main figure
    fH_GroupScatterPlotMatrix = uifigure(...
            'Name','Group scatter plot matrix',...
            'HandleVisibility','on',...
            'WindowStyle','alwaysontop',...
            'Visible','off',...
            'AutoResizeChildren','Off',...
            'Color',[1 1 1]);

    % get colors for each object based on ColorMode
    switch ColorMode
        case 'Group'
            objectGroupIdxs = OOPSData.getConcatenatedObjectData({'GroupIdx'});
            objectGroupColors = OOPSData.GroupColors;
        case 'Label'
            objectGroupIdxs = OOPSData.getConcatenatedObjectData({'LabelIdx'});
            objectGroupColors = OOPSData.Settings.LabelColors;
    end

    % usage: gplotmatrix(X,[],group,clr,sym,siz,doleg,dispopt,xnam)
    % [h,ax] = gplotmatrix(objectData,[],objectGroupIdxs,objectGroupColors,[],markerSize,[],DiagonalDisplay,variableListLong);
    [h,ax,bigAx] = gplotmatrix(objectData,[],objectGroupIdxs,objectGroupColors,[],markerSize,false,DiagonalDisplay,variableListLong);


    for i = 1:nVariables
        ax(i,1).YLabel.String = strsplit(ax(i,1).YLabel.String);
        ax(nVariables,i).XLabel.String = strsplit(ax(nVariables,i).XLabel.String);
    end

    % set up context menu for copying the plot
    cm = uicontextmenu(fH_GroupScatterPlotMatrix);
    % individual context menu choices
    uimenu(cm,"Text","Copy image to clipboard","MenuSelectedFcn",@copyPlotAsImage);

    % add context menu to figure
    fH_GroupScatterPlotMatrix.ContextMenu = cm;

    % make main figure visible
    fH_GroupScatterPlotMatrix.Visible = "on";

    function copyPlotAsImage(o,~)
        copygraphics(ancestor(o,'figure'),"ContentType","image","Resolution",600);
    end

end