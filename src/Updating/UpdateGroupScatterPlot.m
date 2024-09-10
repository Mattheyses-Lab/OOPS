function UpdateGroupScatterPlot(source)
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

    % get the master data object
    OOPSData = guidata(source);
    % get the variables to plot from settings object
    XVar = OOPSData.Settings.ScatterPlotXVariable;
    YVar = OOPSData.Settings.ScatterPlotYVariable;
    % get the 'expanded' variable names
    XName = OOPSData.Settings.expandVariableName(XVar);
    YName = OOPSData.Settings.expandVariableName(YVar);
    % title of the plot
    PlotTitle = [YName,' vs ',XName];

switch OOPSData.Settings.ScatterPlotGroupingType
    case 'Group'

        % determine how many groups we will be plotting for
        nPlots = OOPSData.nGroups;
    
        % cell array of XData
        ObjectXData = OOPSData.GetObjectDataByGroup(XVar);
        % cell array of YData
        ObjectYData = OOPSData.GetObjectDataByGroup(YVar);
        % get object SelfIdxs for data tips
        ObjectSelfIdxs = OOPSData.GetObjectDataByGroup('SelfIdx');
        % get object GroupNames for data tips
        ObjectGroupNames = OOPSData.GetObjectDataByGroup('GroupName');
        % get object ImageNames for data tips
        ObjectImageNames = OOPSData.GetObjectDataByGroup('texFriendlyImageName');
        % get object LabelNames for data tips
        ObjectLabelNames = OOPSData.GetObjectDataByGroup('LabelName');
        % get object LabelIdxs for plot marker colors
        ObjectLabelIdxs = OOPSData.GetObjectDataByGroup('LabelIdx');
        % get object GroupIdxs for plot marker colors
        ObjectGroupIdxs = OOPSData.GetObjectDataByGroup('GroupIdx');
    
        % cell arrays to hold X and Y data
        Y = cell(nPlots,1);
        X = cell(nPlots,1);
        
        % color data for marker faces
        CData = cell(nPlots,1);
        % datatip info passed to GroupScatterPlot
        dtNames = cell(nPlots,1);
        dtData = cell(nPlots,1);
        % name of datatip entries for each plot marker
        dataTipNames = {'Group','Image','Object','Label',XName,YName};

        % names of each group (for legend and warning/error messages)
        groupNames = OOPSData.GroupNames;

        for i = 1:nPlots
    
            % remove missing YData, save idxs to removed values
            [~,TFY] = rmmissing(ObjectYData{i});
            % number of YData values midding
            nYDataRemoved = numel(find(TFY));
    
            % remove missing XData, save idxs to removed values
            [~,TFX] = rmmissing(ObjectXData{i});
            % number of XData values midding
            nXDataRemoved = numel(find(TFX));
    
            % logical array of missing values, true if x or y are missing
            TF = TFY | TFX;
    
            % get new XData and YData with missing values removed
            Y{i} = ObjectYData{i}(~TF);
            X{i} = ObjectXData{i}(~TF);
            ObjectLabelIdxs{i} = ObjectLabelIdxs{i}(~TF);
            ObjectSelfIdxs{i} = ObjectSelfIdxs{i}(~TF);
            ObjectGroupNames{i} = ObjectGroupNames{i}(~TF);
            ObjectImageNames{i} = ObjectImageNames{i}(~TF);
            ObjectLabelNames{i} = ObjectLabelNames{i}(~TF);
            ObjectGroupIdxs{i} = ObjectGroupIdxs{i}(~TF);

    
            try
                % throw error if no XData found
                if isempty(X{i})
                    error('UpdateGroupScatterPlot:XDataMissing','%s data missing for %s',XName,groupNames{i});
                end
                % throw error if no YData found
                if isempty(Y{i})
                    error('UpdateGroupScatterPlot:YDataMissing','%s data missing for %s',YName,groupNames{i});
                end
                % warn if XData is incomplete
                if nXDataRemoved > 0
                    UpdateLog3(source,sprintf('Warning: %s data incomplete for %d objects in %s',XName,nXDataRemoved,groupNames{i}),'append');
                end
                % warn if YData is incomplete
                if nYDataRemoved > 0
                    UpdateLog3(source,sprintf('Warning: %s data incomplete for %d objects in %s',YName,nYDataRemoved,groupNames{i}),'append');
                end

            catch me
                UpdateLog3(source,['Error building scatterplot: ',me.message],'append');
            end
    
            switch OOPSData.Settings.ScatterPlotColorMode
                case 'Group'
                    CData{i} = OOPSData.Group(i).Color;
                case 'Density'
                    CData = {};
                case 'Label'
                    CData{i} = ObjectLabelIdxs{i};
            end

            % cell array of data tip labels
            dtNames{i} = dataTipNames;
            % add the datatip values for each label to the cell in dtData for this scatter
            dtData{i} = {...
                categorical(ObjectGroupNames{i}),...
                categorical(ObjectImageNames{i}),...
                ObjectSelfIdxs{i},...
                categorical(ObjectLabelNames{i}),...
                X{i},...
                Y{i}...
                };
        end

    case 'Label'

        % determine how many groups we will be plotting for (one per unique object label)
        nPlots = OOPSData.Settings.nLabels;
    
        % cell array of XData
        ObjectXData = OOPSData.GetObjectDataByLabel(XVar);
        % cell array of YData
        ObjectYData = OOPSData.GetObjectDataByLabel(YVar);
        % get object SelfIdxs for data tips
        ObjectSelfIdxs = OOPSData.GetObjectDataByLabel('SelfIdx');
        % get object GroupNames for data tips
        ObjectGroupNames = OOPSData.GetObjectDataByLabel('GroupName');
        % get object ImageNames for data tips
        ObjectImageNames = OOPSData.GetObjectDataByLabel('texFriendlyImageName');
        % get object LabelNames for data tips
        ObjectLabelNames = OOPSData.GetObjectDataByLabel('LabelName');
        % get object LabelIdxs for plot marker colors
        ObjectLabelIdxs = OOPSData.GetObjectDataByLabel('LabelIdx');
        % get object GroupIdxs for plot marker colors
        ObjectGroupIdxs = OOPSData.GetObjectDataByLabel('GroupIdx');
    
        % cell arrays to hold X and Y data
        Y = cell(nPlots,1);
        X = cell(nPlots,1);
        
        % color data for marker faces
        CData = cell(nPlots,1);
        % datatip info passed to GroupScatterPlot
        dtNames = cell(nPlots,1);
        dtData = cell(nPlots,1);
        % name of datatip entries for each plot marker
        dataTipNames = {'Group','Image','Object','Label',XName,YName};

        % names of each group (for legend and warning/error messages)
        groupNames = OOPSData.Settings.LabelNames;

        for i = 1:nPlots
    
            % remove missing YData, save idxs to removed values
            [~,TFY] = rmmissing(ObjectYData{i});
            % number of YData values midding
            nYDataRemoved = numel(find(TFY));
    
            % remove missing XData, save idxs to removed values
            [~,TFX] = rmmissing(ObjectXData{i});
            % number of XData values midding
            nXDataRemoved = numel(find(TFX));
    
            % logical array of missing values, true if x or y are missing
            TF = TFY | TFX;
    
            % get new XData and YData with missing values removed
            Y{i} = ObjectYData{i}(~TF);
            X{i} = ObjectXData{i}(~TF);
            ObjectLabelIdxs{i} = ObjectLabelIdxs{i}(~TF);
            ObjectSelfIdxs{i} = ObjectSelfIdxs{i}(~TF);
            ObjectGroupNames{i} = ObjectGroupNames{i}(~TF);
            ObjectImageNames{i} = ObjectImageNames{i}(~TF);
            ObjectLabelNames{i} = ObjectLabelNames{i}(~TF);
            ObjectGroupIdxs{i} = ObjectGroupIdxs{i}(~TF);
    
            try
                % throw error if no XData found
                if isempty(X{i})
                    error('UpdateGroupScatterPlot:XDataMissing','%s data missing for %s',XName,groupNames{i});
                end
                % throw error if no YData found
                if isempty(Y{i})
                    error('UpdateGroupScatterPlot:YDataMissing','%s data missing for %s',YName,groupNames{i});
                end
                % warn if XData is incomplete
                if nXDataRemoved > 0
                    UpdateLog3(source,sprintf('Warning: %s data missing for %d objects in %s',XName,nXDataRemoved,groupNames{i}),'append');
                end
                % warn if YData is incomplete
                if nYDataRemoved > 0
                    UpdateLog3(source,sprintf('Warning: %s data missing for %d objects in %s',YName,nYDataRemoved,groupNames{i}),'append');
                end
            catch me
                UpdateLog3(source,['Error building scatterplot: ',me.message],'append');
            end
    
            switch OOPSData.Settings.ScatterPlotColorMode
                case 'Group'
                    CData{i} = ObjectGroupIdxs{i};
                case 'Density'
                    CData = {};
                case 'Label'
                    CData{i} = OOPSData.Settings.ObjectLabels(i).Color;
            end

            % cell array of data tip labels
            dtNames{i} = dataTipNames;
            % add the datatip values for each label to the cell in dtData for this scatter
            dtData{i} = {...
                categorical(ObjectGroupNames{i}),...
                categorical(ObjectImageNames{i}),...
                ObjectSelfIdxs{i},...
                categorical(ObjectLabelNames{i}),...
                X{i},...
                Y{i}...
                };
        end

end

    
% concatenate the datatip names and data to form datatip info cell which we will pass to ViolinChart
dtCell = [dtNames, dtData];
% default value for ColorByDensity
ColorByDensity = false;
% default MarkerFaceColor ('flat' – color points using CData)
MarkerFaceColor = {'flat'};
% default colormap for the plot (can be any mx3 array of RGB triplets)
cmap = gray;
% default CLim value
CLim = [0 1];

% get CLim and colormap for plot marker colors
switch OOPSData.Settings.ScatterPlotColorMode
    case 'Group'
        switch OOPSData.Settings.ScatterPlotGroupingType
            case 'Group'
                % MarkerFaceColor is an nGroupsx3 array of RGB triplets (one color per group)
                MarkerFaceColor = OOPSData.GroupColors;
            case 'Label'
                % color the points according to the color of the group
                cmap = OOPSData.GroupColors;
                % set the color limits
                if OOPSData.nGroups > 1
                    CLim = [1 OOPSData.nGroups];
                else
                    CLim = [0 1];
                end
        end
    case 'Label'
        switch OOPSData.Settings.ScatterPlotGroupingType
            case 'Group'
                % color the points according to the color of the label of each object
                cmap = OOPSData.Settings.LabelColors;
                % set the color limits
                if OOPSData.Settings.nLabels > 1
                    CLim = [1 OOPSData.Settings.nLabels];
                else
                    CLim = [0 1];
                end
            case 'Label'
                % MarkerFaceColor is an nLabelsx3 array of RGB triplets (one color per group)
                MarkerFaceColor = OOPSData.Settings.LabelColors;
        end
    case 'Density'
        cmap = turbo;
        CLim = [0 1];
        ColorByDensity = true;
end


%% get 'auto' hull face/edge, and plot marker edge colors

switch OOPSData.Settings.ScatterPlotHullEdgeColorMode
    case 'auto'
        switch OOPSData.Settings.ScatterPlotGroupingType
            case 'Group'
                HullEdgeColor = OOPSData.GroupColors;
            case 'Label'
                HullEdgeColor = OOPSData.Settings.LabelColors;
        end
    case 'Custom'
        HullEdgeColor = OOPSData.Settings.ScatterPlotHullEdgeColor;
end

switch OOPSData.Settings.ScatterPlotHullFaceColorMode
    case 'auto'
        switch OOPSData.Settings.ScatterPlotGroupingType
            case 'Group'
                HullFaceColor = OOPSData.GroupColors;
            case 'Label'
                HullFaceColor = OOPSData.Settings.LabelColors;
        end
    case 'Custom'
        HullFaceColor = OOPSData.Settings.ScatterPlotHullFaceColor;
end

switch OOPSData.Settings.ScatterPlotMarkerEdgeColorMode
    case 'auto'
        MarkerEdgeColor = MarkerFaceColor;
    case 'Custom'
        MarkerEdgeColor = OOPSData.Settings.ScatterPlotMarkerEdgeColor;
end

BackgroundColor = OOPSData.Settings.ScatterPlotBackgroundColor;
ForegroundColor = OOPSData.Settings.ScatterPlotForegroundColor;
MarkerSize = OOPSData.Settings.ScatterPlotMarkerSize;
MarkerFaceAlpha = OOPSData.Settings.ScatterPlotMarkerFaceAlpha;
MarkerEdgeAlpha = OOPSData.Settings.ScatterPlotMarkerEdgeAlpha;
HullLineWidth = OOPSData.Settings.ScatterPlotHullLineWidth;
HullEdgeAlpha = OOPSData.Settings.ScatterPlotHullEdgeAlpha;
HullType = OOPSData.Settings.ScatterPlotHullType;
FontName = OOPSData.Settings.DefaultPlotFont;
MarkerMode = OOPSData.Settings.ScatterPlotMarkerMode;

% set the properties
set(OOPSData.Handles.GroupScatterPlot,...
    "XData",X,...
    "YData",Y,...
    "GroupNames",groupNames,...
    "Title",PlotTitle,...
    "BackgroundColor",BackgroundColor,...
    "ForegroundColor",ForegroundColor,...
    "FontColor",ForegroundColor,...
    "FontName",FontName,...
    "Position",[0 0 1 1],...
    "DataTipCell",dtCell,...
    "XLabel",XName,...
    "YLabel",YName,...
    "MarkerFaceColor",MarkerFaceColor,...
    "MarkerEdgeColor",MarkerEdgeColor,...
    "MarkerEdgeAlpha",MarkerEdgeAlpha,...
    "MarkerSize",MarkerSize,...
    "MarkerMode",MarkerMode,...
    "MarkerFaceAlpha",MarkerFaceAlpha,...
    "ColorByDensity",ColorByDensity,...
    "CData",CData,...
    "HullLineWidth",HullLineWidth,...
    "HullFaceColor",HullFaceColor,...
    "HullEdgeColor",HullEdgeColor,...
    "HullType",HullType,...
    "HullEdgeAlpha",HullEdgeAlpha,...
    "GroupNames",groupNames,...
    "Colormap",cmap,...
    "CLim",CLim);


end