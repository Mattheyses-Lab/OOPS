function PlotGroupScatterPlotMatrix(source,~)

    markerSize = 10;

    % get the main data structure
    OOPSData = guidata(source);

    % get settings for the scatterplot matrix
    ScatterPlotMatrixSettings = getScatterPlotMatrixSettings(OOPSData.Settings.ObjectPlotVariables);

    % make sure the settings are valid (will be empty if invalid)
    if isempty(ScatterPlotMatrixSettings)
        uialert(OOPSData.Handles.fH,'Invalid selection','Error');
        return
    else
        variableList = ScatterPlotMatrixSettings.variableList;
        ColorMode = ScatterPlotMatrixSettings.ColorMode;
        DiagonalDisplay = ScatterPlotMatrixSettings.DiagonalDisplay;

        nVariables = numel(variableList);

        variableListLong = cellfun(@(varname) ExpandVariableName(varname),variableList,'UniformOutput',0);

    end

    % get object data for the selected variables
    objectData = OOPSData.getAllObjectData(variableList);

    % create the main figure
    fH_GroupScatterPlotMatrix = uifigure(...
            'Name','Group scatter plot matrix',...
            'HandleVisibility','on',...
            'WindowStyle','alwaysontop',...
            'Visible','off',...
            'AutoResizeChildren','Off');

    % get colors for each object based on ColorMode
    switch ColorMode
        case 'Group'
            objectGroupIdxs = OOPSData.getAllObjectData({'GroupIdx'});
            objectGroupColors = OOPSData.GroupColors;
        case 'Label'
            objectGroupIdxs = OOPSData.getAllObjectData({'LabelIdx'});
            objectGroupColors = OOPSData.Settings.LabelColors;
    end

    % usage: gplotmatrix(X,[],group,clr,sym,siz,doleg,dispopt,xnam)
    % [h,ax] = gplotmatrix(objectData,[],objectGroupIdxs,objectGroupColors,[],markerSize,[],DiagonalDisplay,variableListLong);
    [h,ax] = gplotmatrix(objectData,[],objectGroupIdxs,objectGroupColors,[],[],[],DiagonalDisplay,variableListLong);


    for i = 1:nVariables
        ax(i,1).YLabel.String = strsplit(ax(i,1).YLabel.String);
        ax(nVariables,i).XLabel.String = strsplit(ax(nVariables,i).XLabel.String);
    end


    % make main figure visible
    fH_GroupScatterPlotMatrix.Visible = "on";

end