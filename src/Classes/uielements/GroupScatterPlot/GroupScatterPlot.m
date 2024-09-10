classdef GroupScatterPlot < matlab.ui.componentcontainer.ComponentContainer
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


    %% Plot properties

    properties(AbortSet = true)
        % cell array of X data
        XData (:,1) cell
        % cell array of X data
        YData (:,1) cell
        % title of the chart displayed at the top of the axes
        Title (1,:) char = 'Scatter Plot'
        % color of axes and title text
        FontColor (1,3) double = [0 0 0]
        % name of the axes font for titles and labels, defaul Arial
        FontName (1,:) char = 'Arial'
        % color of axes axis lines
        ForegroundColor (1,3) double = [0 0 0]
        % label of the x-axis
        XLabel (1,:) char = 'X Variable'
        % label of the y-axis
        YLabel (1,:) char = 'Y Variable'
        % size of the various text objects
        FontSize (1,1) double = 12
        % colormap of the axes
        Colormap (:,3) double = turbo
    end

    %% Marker properties

    properties(AbortSet = true)
        % visibility of the individual data points
        PointsVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        % size of the plot markers (scalar value in points)
        MarkerSize (1,1) double = 25
        % alpha data for the plot marker faces (scalar value in the range [0 1])
        MarkerFaceAlpha (1,1) double {mustBeInRange(MarkerFaceAlpha,0,1)} = 0.5
        % alpha data for the plot marker faces (scalar value in the range [0 1])
        MarkerEdgeAlpha (1,1) double {mustBeInRange(MarkerEdgeAlpha,0,1)} = 1
        % mode for marker symbols
        MarkerMode (1,:) {mustBeMember(MarkerMode,{'single','multi','auto'})} = 'auto'
    end

    %% Hull properties

    properties(AbortSet = true)
        % visibility status of the hull
        HullVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        % line width of the hull edges
        HullLineWidth (1,1) double = 1
        % color mode for hull faces
        HullFaceColorMode (1,:) {mustBeMember(HullFaceColorMode,{'single','multi','auto'})} = 'auto'
        % color mode for hull edges
        HullEdgeColorMode (1,:) {mustBeMember(HullEdgeColorMode,{'single','multi','auto'})} = 'single'
        % transparency of hull faces
        HullFaceAlpha (1,1) double {mustBeInRange(HullFaceAlpha,0,1)} = 0.5
        % transparency of hull edges
        HullEdgeAlpha (1,1) double {mustBeInRange(HullEdgeAlpha,0,1)} = 1
        % type of hull – 'concave' (tight) or 'convex' (loose)
        HullType (1,:) char {mustBeMember(HullType,{'convex','concave'})} = 'concave'
    end

    %% Legend properties

    properties(AbortSet = true)
        % visibility of plot legend
        LegendVisible (1,1) matlab.lang.OnOffSwitchState = "off"
        % style of legend ('auto' or 'custom')
        LegendStyle (1,:) {mustBeMember(LegendStyle,{'auto','custom'})} = 'auto'
        % display names to use in legend
        LegendDisplayNames (:,1) cell = {}
        % marker face colors to use in legend
        LegendMarkerFaceColors (:,1) cell = {}
        % marker edge colors to use in legend
        LegendMarkerEdgeColors (:,1) cell = {}
        % marker symbols to use in legend
        LegendMarkers (:,1) cell {mustBeMember(LegendMarkers,{'o','s','^','h','p','d','v','>','<'})} = {}
    end

    %% Density properties

    properties(AbortSet = true)
        % specifies whether plot markers are colored by density
        ColorByDensity (1,1) matlab.lang.OnOffSwitchState = "on"
    end

    %% private properties used internally

    properties(Access = private,Constant)

        MarkerOrder = {'o';'s';'^';'h';'p';'d';'v';'>';'<'}

    end

    %% dependent properties with associated private properties for more extensive input validation

    properties(Access = private, AbortSet = true)
        % x-axis tick labels for each violin plot
        GroupNames_ (:,1) cell = {}
        % color(s) of hull faces - matrix of one or more RGB triplets
        HullFaceColor_ (:,3) double = []
        % color(s) of hull edges - matrix of one or more RGB triplets
        HullEdgeColor_ (:,3) double = [0 0 0]
        % edge color of each plot marker
        MarkerEdgeColor_ {mustBeValidColor(MarkerEdgeColor_)} = {[0 0 0]}
        % face color of each plot marker
        MarkerFaceColor_ {mustBeValidColor(MarkerFaceColor_)} = {'flat'}
        % symbol used for each marker
        Marker_ (:,1) cell {mustBeMember(Marker_,{'o','s','^','h','p','d','v','>','<'})} = {'o'}
        % edge color of each plot marker
        CData_ {mustBeValidCData(CData_)} = {}
        % data tip info
        DataTipCell_ (:,2) cell = {{},{}}
        % color limits of the axes
        CLim_ (1,2) double = [0 1]
    end
    
    properties(Dependent = true, AbortSet = true)
        % x-axis tick labels for each violin plot
        GroupNames (:,1) cell
        % color(s) of hull faces - matrix of one or more RGB triplets
        HullFaceColor (:,3) double = []
        % color(s) of convex hull edges - matrix of one or more RGB triplets
        HullEdgeColor (:,3) double = [0 0 0]
        % edge color of each plot marker
        MarkerEdgeColor {mustBeValidColor(MarkerEdgeColor)} = {[0 0 0]}
        % face color of each plot marker
        MarkerFaceColor {mustBeValidColor(MarkerFaceColor)} = {'flat'}
        % symbol used for each marker
        Marker (:,1) cell {mustBeMember(Marker,{'o','s','^','h','p','d','v','>','<'})} = {'o'}
        % face color of each plot marker, each cell is an RGB triplet or column vector
        CData {mustBeValidCData(CData)}
        % data tip info
        DataTipCell (:,2) cell
        % color limits of the axes
        CLim (1,2) double = [0 1]
    end

    %% Dependent Set/Get methods controlling scatter appearance and behavior

    methods

        function GroupNames = get.GroupNames(obj)
            % check to make sure number of names matches number of scatters
            % if not, create default names to replace missing before returning

            nGiven = numel(obj.GroupNames_);
            nNeeded = obj.nScatters;

            if nGiven == nNeeded
                GroupNames = obj.GroupNames_;
            elseif nGiven >= nNeeded
                GroupNames = obj.GroupNames_(1:nNeeded);
            else % create more default names if necessary
                %nameIdx = obj.scatterIdxs((nGiven+1):end);
                GroupNames = [obj.GroupNames_;...
                    arrayfun(@(x) ['data',num2str(x)],obj.scatterIdxs((nGiven+1):end),'UniformOutput',false)];
            end
            % update GroupNames_ so we don't have to adjust every time
            obj.GroupNames_ = GroupNames;
        end

        function set.GroupNames(obj,val)
            obj.GroupNames_ = val;
        end

        function CData = get.CData(obj)

            nCells = numel(obj.CData_);
            nData = obj.nScatters;

            if nCells < nData
                % if no CData specified, use auto colors for each CData cell
                nextIdx = nCells+1;
                nCDataToAdd = nData-nCells;
                CData = [obj.CData_;mat2cell(obj.nextNColorsFromIdx(nextIdx,nCDataToAdd),ones(1,nCDataToAdd))];
            elseif nCells >= nData
                % if number of CData cells greater than or equal to number of Data cells, return the amount we need
                CData = obj.CData_(1:nData);
            end

        end

        function set.CData(obj,val)
            obj.CData_ = val;
        end

        function MarkerFaceColor = get.MarkerFaceColor(obj)

            nColors = size(obj.MarkerFaceColor_,1);
            nPlots = obj.nScatters;

            if nColors == 1
                MarkerFaceColor = repmat(obj.MarkerFaceColor_,nPlots,1);
            elseif nColors < nPlots
                MarkerFaceColor = [obj.MarkerFaceColor_;repmat({'auto'},nPlots-nColors,1)];
            else
                MarkerFaceColor = obj.MarkerFaceColor_(1:nPlots,:);
            end

            obj.MarkerFaceColor_ = MarkerFaceColor;

            % get automatic color for each plot
            autoColors = obj.nextNColorsFromIdx(1,nPlots);
            for i = 1:numel(MarkerFaceColor)
                % set the automatic color for any plots set to 'auto'
                if isa(MarkerFaceColor{i},'char')
                    if matches(MarkerFaceColor(i),'auto')
                        MarkerFaceColor{i} = autoColors(i,:);
                    end
                end
            end

        end

        function set.MarkerFaceColor(obj,val)

            % if double, convert to cell
            if isa(val,'double')
                val = mat2cell(val,ones(1,size(val,1)),3);
            end

            obj.MarkerFaceColor_ = val;
        end

        function MarkerEdgeColor = get.MarkerEdgeColor(obj)

            nColors = size(obj.MarkerEdgeColor_,1);
            nPlots = obj.nScatters;

            if nColors == 1
                MarkerEdgeColor = repmat(obj.MarkerEdgeColor_,nPlots,1);
            elseif nColors < nPlots
                MarkerEdgeColor = [obj.MarkerEdgeColor_;repmat({'auto'},nPlots-nColors,1)];
            else
                MarkerEdgeColor = obj.MarkerEdgeColor_(1:nPlots,:);
            end

            obj.MarkerEdgeColor_ = MarkerEdgeColor;

            % get automatic color for each plot
            autoColors = obj.nextNColorsFromIdx(1,nPlots);
            for i = 1:numel(MarkerEdgeColor)
                % set the automatic color for any plots set to 'auto'
                if isa(MarkerEdgeColor{i},'char')
                    if matches(MarkerEdgeColor(i),'auto')
                        MarkerEdgeColor{i} = autoColors(i,:);
                    end
                end
            end

        end

        function set.MarkerEdgeColor(obj,val)

            % if double, convert to cell
            if isa(val,'double')
                val = mat2cell(val,ones(1,size(val,1)),3);
            end

            obj.MarkerEdgeColor_ = val;
        end

        function Marker = get.Marker(obj)

            switch obj.MarkerMode
                case 'single'
                    % number of markers supplied
                    nMarkers = size(obj.Marker_,1);
                    % if no markers supplied, take the first default marker
                    if nMarkers == 0
                        obj.Marker_(1,:) = obj.MarkerOrder(1,:);
                    end
                    % if single marker mode, just use the first marker for each plot
                    Marker = repmat(obj.Marker_(1,:),obj.nScatters,1);
                case 'multi'
                    if size(obj.Marker_,1) >= obj.nScatters
                        Marker = obj.Marker_(obj.scatterIdxs,:);
                    else
                        nGiven = size(obj.Marker_,1);
                        nNeeded = obj.nScatters - nGiven;
                        idx = nGiven+1;
                        % add new markers from MarkerOrder to the existing markers
                        Marker = [obj.Marker_;obj.nextNMarkersFromIdx(idx,nNeeded)];
                    end
                case 'auto'
                    Marker = obj.nextNMarkersFromIdx(1,obj.nScatters);
            end
            obj.Marker_ = Marker;
        end

        function set.Marker(obj,val)
            % number of markers given
            nMarkers = size(val,1);
            % adjust marker mode based on number of markers given
            if nMarkers == 0
                obj.MarkerMode = "auto";
            elseif nMarkers > 1
                obj.MarkerMode = "multi";
            elseif nMarkers == 1
                obj.MarkerMode = "single";
            end
            obj.Marker_ = val;
        end

        function DataTipCell = get.DataTipCell(obj)

            % column vector cell of datatip labels
            dtNames = obj.DataTipCell_(:,1);
            % column vector cell of datatip values
            dtData = obj.DataTipCell_(:,2);

            nGiven = min(size(dtNames,1),size(dtData,1));

            nNeeded = obj.nScatters;

            if nNeeded==0
                DataTipCell = {{},{}};
            elseif nGiven==nNeeded
                DataTipCell = obj.DataTipCell_;
            elseif nGiven < nNeeded
                n2Add = nNeeded - nGiven;
                dtNames = [dtNames(1:nGiven); repmat({{}},n2Add,1)];
                dtData = [dtData(1:nGiven); repmat({{}},n2Add,1)];
                DataTipCell = [dtNames, dtData];
            elseif nGiven > nNeeded
                dtNames = dtNames(1:nNeeded);
                dtData = dtData(1:nNeeded);
                DataTipCell = [dtNames, dtData];
            end

            obj.DataTipCell_ = DataTipCell;
        end

        function set.DataTipCell(obj,val)
            obj.DataTipCell_ = val;
        end

        function CLim = get.CLim(obj)
            CLim = obj.CLim_;
        end

        function set.CLim(obj,val)
            obj.CLim_ = val;
        end

    end

    %% Dependent Set/Get methods controlling hull appearance and behavior

    methods

        function HullFaceColor = get.HullFaceColor(obj)
            switch obj.HullFaceColorMode
                case 'single'
                    % number of colors supplied
                    nColors = size(obj.HullFaceColor_,1);
                    % if no colors supplied, take the first default color from the axes
                    if nColors == 0
                        obj.HullFaceColor_(1,:) = obj.MainAxes.ColorOrder(1,:);
                    end
                    % if single color mode, just use the first RGB triplet for each plot
                    HullFaceColor = repmat(obj.HullFaceColor_(1,:),obj.nScatters,1);
                case 'multi'
                    if size(obj.HullFaceColor_,1) >= obj.nScatters
                        HullFaceColor = obj.HullFaceColor_(obj.scatterIdxs,:);
                    else
                        nGiven = size(obj.HullFaceColor_,1);
                        nNeeded = obj.nScatters - nGiven;
                        idx = nGiven+1;
                        % add new colors from ColorOrder to the existing colors
                        HullFaceColor = [obj.HullFaceColor_;obj.nextNColorsFromIdx(idx,nNeeded)];
                    end
                case 'auto'
                    HullFaceColor = obj.nextNColorsFromIdx(1,obj.nScatters);
            end
            obj.HullFaceColor_ = HullFaceColor;
        end

        function set.HullFaceColor(obj,val)
            % number of colors given
            nColors = size(val,1);
            % adjust color mode based on number of colors given
            if nColors == 0
                obj.HullFaceColorMode = "auto";
            elseif nColors > 1
                obj.HullFaceColorMode = "multi";
            elseif nColors == 1
                obj.HullFaceColorMode = "single";
            end
            obj.HullFaceColor_ = val;
        end

        function HullEdgeColor = get.HullEdgeColor(obj)
            switch obj.HullEdgeColorMode
                case 'single'
                    % number of colors supplied
                    nColors = size(obj.HullEdgeColor_,1);
                    % if no colors supplied, take the first default color from the axes
                    if nColors == 0
                        obj.HullEdgeColor_(1,:) = obj.MainAxes.ColorOrder(1,:);
                    end
                    % if single color mode, just use the first RGB triplet for each plot
                    HullEdgeColor = repmat(obj.HullEdgeColor_(1,:),obj.nScatters,1);
                case 'multi'
                    if size(obj.HullEdgeColor_,1) >= obj.nScatters
                        HullEdgeColor = obj.HullEdgeColor_(obj.scatterIdxs,:);
                    else
                        nGiven = size(obj.HullEdgeColor_,1);
                        nNeeded = obj.nScatters - nGiven;
                        idx = nGiven+1;
                        % add new colors from ColorOrder to the existing colors
                        HullEdgeColor = [obj.HullEdgeColor_;obj.nextNColorsFromIdx(idx,nNeeded)];
                    end
                case 'auto'
                    HullEdgeColor = obj.nextNColorsFromIdx(1,obj.nScatters);
            end
            obj.HullEdgeColor_ = HullEdgeColor;
        end

        function set.HullEdgeColor(obj,val)
            % number of colors given
            nColors = size(val,1);
            % adjust color mode based on number of colors given
            if nColors == 0
                obj.HullEdgeColorMode = "auto";
            elseif nColors > 1
                obj.HullEdgeColorMode = "multi";
            elseif nColors == 1
                obj.HullEdgeColorMode = "single";
            end
            obj.HullEdgeColor_ = val;
        end

    end


    %% private helper methods

    methods(Access = private)

        function nextNColors = nextNColorsFromIdx(obj,idx,n)
            % number of RGB triplets in the ColorOrder property of the axes
            nColorsInOrder = size(obj.MainAxes.ColorOrder,1);
            % unwrapped idx to the colors in ColorOrder
            cIdx = idx:(idx+n-1);
            % wrapped idxs to RGB triplets in the ColorOrder (cycled if more scatters than colors)
            newColorIdxs = mod(cIdx,nColorsInOrder);
            newColorIdxs(newColorIdxs==0) = nColorsInOrder;
            % add new colors from ColorOrder to the existing colors
            nextNColors = obj.MainAxes.ColorOrder(newColorIdxs,:);
        end

        function nextNMarkers = nextNMarkersFromIdx(obj,idx,n)
            % default marker list
            nMarkersInOrder = size(obj.MarkerOrder,1);
            % unwrapped idx to the markers in MarkerOrder
            mIdx = idx:(idx+n-1);
            % wrapped idxs to markers in the MarkerOrder (cycled if more scatters than colors)
            newMarkerIdxs = mod(mIdx,nMarkersInOrder);
            newMarkerIdxs(newMarkerIdxs==0) = nMarkersInOrder;
            % add new colors from ColorOrder to the existing colors
            nextNMarkers = obj.MarkerOrder(newMarkerIdxs,:);
        end

        function [legendNames,legendMarkerFaceColors,legendMarkerEdgeColors,legendMarkers] = getLegendData(obj)

            switch obj.LegendStyle
                case 'auto'
                    % one legend entry per group
                    legendNames = obj.GroupNames;
        
                    % marker face/edge colors of each entry match obj.MarkerFaceColor and obj.MarkerEdgeColor
                    legendMarkerFaceColors = obj.MarkerFaceColor;
                    legendMarkerEdgeColors = obj.MarkerEdgeColor;
        
                    % marker styles for each entry
                    legendMarkers = obj.Marker;
        
                    % get CData in case we need it
                    chartCData = obj.CData;
        
                    % for each entry, make sure face/edge colors are not set to flat
                    % if 'flat', use CData if it contains a single RGB triplet only
                    % otherwise, set color to 'none' and add ' (multi-color)' to legend entry name
        
                    for i = 1:numel(legendNames)
                        % tracks whether legend name is changed
                        legendNameChanged = false;
        
                        if isa(legendMarkerFaceColors{i},'char')
                            % if this plot's MarkerFaceColor is 'flat'
                            if matches(legendMarkerFaceColors{i},'flat')

                                % if points colored by density
                                if obj.ColorByDensity
                                    % use white for marker face color
                                    legendMarkerFaceColors{i} = [1 1 1];
                                    % and add ' (density color)' to the entry name
                                    legendNames{i} = [legendNames{i},' (density color)'];
                                    % indicate that legend name changed
                                    legendNameChanged = true;
                                else
                                    % get CData for this plot
                                    plotCData = chartCData{i};
                                    % if CData for this plot is a single RGB triplet
                                    if isequal(size(plotCData),[1,3])
                                        % use it for the legend marker face color
                                        legendMarkerFaceColors{i} = plotCData;
                                    else
                                        % otherwise, use 'none'
                                        legendMarkerFaceColors{i} = 'none';
                                        % adjust legend entry name text
                                        legendNames{i} = [legendNames{i},' (multi-color)'];
                                        % indicate that legend name changed
                                        legendNameChanged = true;
                                    end
                                end
                            end
                        end
        
                        % do the same for marker edge colors
                        if isa(legendMarkerEdgeColors{i},'char')
                            if matches(legendMarkerEdgeColors{i},'flat')

                                % get CData for this plot
                                plotCData = chartCData{i};
                                % if CData for this plot is a single RGB triplet
                                if isequal(size(plotCData),[1,3])
                                    % use it for the legend
                                    legendMarkerEdgeColors{i} = plotCData;
                                else
                                    % otherwise, use 'none'
                                    legendMarkerEdgeColors{i} = 'none';
                                    % if legend name has not been changed already
                                    if ~legendNameChanged
                                        % adjust legend entry name text
                                        legendNames{i} = [legendNames{i},' (multi-color)'];
                                    end
                                end


                            end
                        end

                    end

                case 'custom'

                    % get legend info from user-specified properties
                    legendNames = obj.LegendDisplayNames;
                    legendMarkerFaceColors = obj.LegendMarkerFaceColors;
                    legendMarkerEdgeColors = obj.LegendMarkerEdgeColors;
                    legendMarkers = obj.LegendMarkers;

                    if isempty(legendNames) || ...
                            isempty(legendMarkerFaceColors) || ...
                            isempty(legendMarkerEdgeColors) || ...
                            isempty(legendMarkers)

                        legendNames = {};
                        legendMarkerFaceColors = {};
                        legendMarkerEdgeColors = {};
                        legendMarkers = {};
                    end

            end

        end

    end

    %% public methods to facilitate copy/export

    methods(Access=public)

        function copyplot(obj)
            copygraphics(obj.MainAxes,"ContentType","vector","BackgroundColor",obj.BackgroundColor);
        end

    end

    %% private, dependent properties used internally
    
    properties(Access = private, Dependent = true)
        nScatters
        scatterIdxs
        DensityCData
    end

    methods
    
        function nScatters = get.nScatters(obj)
            nScatters = numel(obj.XData);
        end
    
        function scatterIdxs = get.scatterIdxs(obj)
            if obj.nScatters>0
                scatterIdxs = (1:obj.nScatters).';
            else
                scatterIdxs = [];
            end
        end

        function DensityCData = get.DensityCData(obj)
            
            % cell arrays of XData and YData
            X = obj.XData;
            Y = obj.YData;

            % make sure non-empty
            if isempty(X) || isempty(Y)
                DensityCData = {};
                return
            end

            for i = 1:numel(X)
                if any(isnan(X{i}))
                    DensityCData = {NaN};
                    return
                end
            end

            for i = 1:numel(Y)
                if any(isnan(Y{i}))
                    DensityCData = {NaN};
                    return
                end
            end

            % preallocate object idx cell array
            objIdxsPerPlot = cell(obj.nScatters,1);

            % get cell array of the idx of each object in each plot, w.r.t. the total num of objects in all plots
            for i = 1:obj.nScatters
                if i == 1
                    objIdxsPerPlot{i} = 1:numel(Y{i});
                else
                    objIdxsPerPlot{i} = (1:numel(Y{i})) + objIdxsPerPlot{i-1}(end);
                end
            end

            % concatenate all XData and YData
            allY = cell2mat(Y);
            allX = cell2mat(X);

            % get the density information for each point
            DensityData = ksdensity([allX(:) allY(:)], [allX(:) allY(:)]);

            % normalize to the range [0, 1]
            DensityData = rescale(DensityData);

            % preallocate cell array of density values to use for CData
            DensityCData = cell(obj.nScatters,1);

            % use density data for CData
            for i = 1:obj.nScatters
                DensityCData{i} = DensityData(objIdxsPerPlot{i});
            end

        end

    end

    %% graphics components the GroupScatterPlot is built from
        
    properties(Access = private,Transient,NonCopyable)
        Grid (1,1) matlab.ui.container.GridLayout
        MainAxes (1,1) matlab.ui.control.UIAxes
        Scatters (:,1) ScatterPlot
        PlotLegend (:,1) matlab.graphics.illustration.Legend
        LegendPlots (:,1) matlab.graphics.chart.primitive.Line
    end

    %% protected methods - setup(), update(), etc...
    
    methods(Access = protected)

        function setup(obj)
            % grid layout manager to hold the components
            obj.Grid = uigridlayout(obj,...
                [1,1],...
                "ColumnWidth",{'1x'},...
                "RowHeight",{'1x'},...
                "BackgroundColor",[1 1 1],...
                "Padding",[0 0 0 0]);
            % uiaxes to hold scatter plots
            obj.MainAxes = uiaxes(obj.Grid,...
                "XColor",[0 0 0],...
                "YColor",[0 0 0],...
                "Box","off",...
                "NextPlot","add",...
                "TickDir","in",...
                "FontName",obj.FontName,...
                "LabelFontSizeMultiplier",1,...
                "TitleFontSizeMultiplier",1,...
                "YTickMode","auto",...
                "YTickLabelMode","auto",...
                "YLimMode","auto");
            obj.MainAxes.Layout.Row = 1;
            obj.MainAxes.Layout.Column = 1;
            % set up a title for the axes
            obj.MainAxes.Title.String = obj.Title;
            obj.MainAxes.Title.Units = 'Normalized';
            obj.MainAxes.Title.HorizontalAlignment = 'Center';
            obj.MainAxes.Title.VerticalAlignment = 'Top';
            obj.MainAxes.Title.Color = [0 0 0];
            obj.MainAxes.Title.Position = [0.5,1.0,0];
            obj.MainAxes.Title.HitTest = 'Off';
            obj.MainAxes.Title.PickableParts = 'none';
            % disable default interactions
            obj.MainAxes.Interactions = dataTipInteraction;
            % replace default toolbar with an empty one
            axtoolbar(obj.MainAxes,{});
            % preallocate empty ScatterPlot array
            obj.Scatters = ScatterPlot.empty();
            % set up plot legend
            obj.PlotLegend = matlab.graphics.illustration.Legend.empty();
            % set up empty plots used to construct the legend
            obj.LegendPlots = matlab.graphics.chart.primitive.Line.empty();
            % use normalized units for the component, stretched to fill the container by default
            obj.Units = 'Normalized';
            obj.Position = [0 0 1 1];
        end
        
        function update(obj)
            
            %% update x-axis limits, tick locations, tick labels

            % set x-axis label string and font size
            obj.MainAxes.XLabel.String = obj.XLabel;
            
            %% update the individual plots

            % keep the valid scatters only
            obj.Scatters = obj.Scatters(isvalid(obj.Scatters));
            % the number of valid scatters currently plotted
            nPlots = numel(obj.Scatters);
            % the number of scatters we need
            nPlotsNeeded = obj.nScatters;

            if nPlots < nPlotsNeeded
                for i = nPlots+1:nPlotsNeeded
                    obj.Scatters(i) = ScatterPlot(obj.MainAxes);
                end
            elseif nPlots > nPlotsNeeded
                % delete the excess plots
                delete(obj.Scatters(nPlotsNeeded+1:nPlots))
            end

            % get the datatip info
            dtCell = obj.DataTipCell;

            % get CData for plot markers
            if obj.ColorByDensity
                CData4Plot = obj.DensityCData; % use density values to color markers
            else
                CData4Plot = obj.CData; % use user-specified colors
            end

            for i = 1:nPlotsNeeded
                try
                    set(obj.Scatters(i),...
                        'PointsVisible',obj.PointsVisible,...
                        'XData',obj.XData{i},...
                        'YData',obj.YData{i},...
                        'DataTipCell',dtCell(i,:),...
                        'MarkerEdgeColor',obj.MarkerEdgeColor{i},...
                        'MarkerFaceColor',obj.MarkerFaceColor{i},...
                        'MarkerSize',obj.MarkerSize,...
                        'MarkerFaceAlpha',obj.MarkerFaceAlpha,...
                        'MarkerEdgeAlpha',obj.MarkerEdgeAlpha,...
                        'Marker',obj.Marker{i},...
                        'CData',CData4Plot{i},...
                        'Name',obj.GroupNames{i},...
                        'HullVisible',obj.HullVisible,...
                        'HullLineWidth',obj.HullLineWidth,...
                        'HullFaceColor',obj.HullFaceColor(i,:),...
                        'HullEdgeColor',obj.HullEdgeColor(i,:),...
                        'HullFaceAlpha',obj.HullFaceAlpha,...
                        'HullEdgeAlpha',obj.HullEdgeAlpha,...
                        'HullType',obj.HullType);
                catch ME
                    disp(ME.getReport)
                    disp(ME.message)
                end
            end

            %% update various axes components

            % text displayed in the title
            obj.MainAxes.Title.String = obj.Title;
            % color of the title text
            obj.MainAxes.Title.Color = obj.ForegroundColor;
            % visibility of the title text
            obj.MainAxes.Title.Visible = 'on';
            % axes font name
            obj.MainAxes.FontName = obj.FontName;  
            % grid background color
            obj.Grid.BackgroundColor = obj.BackgroundColor;
            % axes background color
            obj.MainAxes.Color = obj.BackgroundColor;
            % x-axis line color
            obj.MainAxes.XColor = obj.ForegroundColor;
            % y-axis line color
            obj.MainAxes.YColor = obj.ForegroundColor;
            % x-axis label font color
            obj.MainAxes.XLabel.Color = obj.ForegroundColor;
            % y-axis label font color
            obj.MainAxes.YLabel.Color = obj.ForegroundColor;
            % x-axis label text
            obj.MainAxes.XLabel.String = obj.XLabel;
            % y-axis label text
            obj.MainAxes.YLabel.String = obj.YLabel;
            % axes font size
            obj.MainAxes.FontSize = obj.FontSize;
            % axes colormap, used when MarkerFaceColor={'flat'} and CData is a cell array of column vectors
            obj.MainAxes.Colormap = obj.Colormap;
            % axes color limits, used when MarkerFaceColor='flat' and CData is a cell array of column vectors
            obj.MainAxes.CLim = obj.CLim;

            %% update context menu (development)

            if isvalid(obj.ContextMenu)
                obj.MainAxes.ContextMenu = obj.ContextMenu;
            end

            %% update legend

            % delete any legend plots and clear the handles
            delete(obj.LegendPlots)
            obj.LegendPlots = obj.LegendPlots(isvalid(obj.LegendPlots));

            if obj.LegendVisible

                [legendNames,legendMarkerFaceColors,legendMarkerEdgeColors,legendMarkers] = obj.getLegendData();
    
                if ~isempty(legendNames)
                    for i = 1:numel(legendNames)
                        % create an empty plot for each scatter
                        obj.LegendPlots(i) = plot(obj.MainAxes,...
                            NaN,NaN,...
                            'DisplayName',legendNames{i},...
                            'Marker',legendMarkers{i},...
                            'MarkerFaceColor',legendMarkerFaceColors{i},...
                            'MarkerEdgeColor',legendMarkerEdgeColors{i},...
                            'MarkerSize',obj.MarkerSize,...
                            'LineStyle','none');
                    end
                    % create the legend
                    obj.PlotLegend = legend(obj.LegendPlots);
                end

            end

            % update legend visibility, hide if no legend entries
            if isvalid(obj.PlotLegend)
                if isempty(obj.LegendPlots)
                    obj.PlotLegend.Visible = 'off';
                else
                    obj.PlotLegend.Visible = obj.LegendVisible;
                end
            end

            %% update display stacking order in axes

            % if the hull is set to be visible
            if obj.HullVisible
                % reoorder axes children so that hulls are always at the bottom
                obj.MainAxes.Children = [...
                    findobj(obj.MainAxes.Children,'-not','Type','patch');...
                    findobj(obj.MainAxes.Children,'Type','patch')];
            end

            % note: children reordering seems to fail when a datatip is active, need to investigate


        end

    end

end


%% custom property validation functions

function mustBeValidCData(colorInput)
    switch class(colorInput)
        case 'cell'
            % if empty, don't check sizes
            if ~isempty(colorInput)
                % validate that input is a cell array with one column
                if size(colorInput,2) ~= 1
                    eid = 'Size:doesNotMatchData';
                    msg = 'CData must be a cell array with one column';
                    throwAsCaller(MException(eid,msg))
                end
        
                for i = 1:numel(colorInput)
                    if ~isempty(colorInput{i})
                        % each cell must be an RGB triplet(s) matrix, or a column vector
                        if size(colorInput{i},2) ~= 3 && size(colorInput{i},2) ~= 1 && size(colorInput{i},1) ~= 1
                            eid = 'Size:doesNotMatchData';
                            msg = 'Each cell in CData must be a matrix of RGB triplets or a vector';
                            throwAsCaller(MException(eid,msg))
                        end
                    end
                end
            end
        otherwise
            % invalid class
            eid = 'Class:notCell';
            msg = 'CData must be a cell array with one column';
            throwAsCaller(MException(eid,msg))
    end

end


function mustBeValidColor(colorInput)
    switch class(colorInput)
        case 'cell'
            % if empty, don't check sizes
            if ~isempty(colorInput)
                for i = 1:numel(colorInput)
                    switch class(colorInput{i})
                        case 'double'
                            % if not in range, [0,1]
                            if any(colorInput{i} < 0) || any(colorInput{i} > 1) || ~isequal(size(colorInput{i}),[1,3])
                                % invalid range
                                eid = 'Color:invalidRGBTriplet';
                                msg = 'Must be 3x1 double in the range [0,1]';
                                throwAsCaller(MException(eid,msg))
                            end
                        case 'char'
                            if ~ismember(colorInput{i},{'none','auto','flat'})
                                % invalid option
                                eid = 'Option:notValidColorOption';
                                msg = "Must be one of the allowed values: 'flat', 'auto', or 'none'";
                                throwAsCaller(MException(eid,msg))
                            end
                    end
                end
            end

        case 'double'
            % if empty, don't check sizes
            if ~isempty(colorInput)
                % for each RGB triplet
                for i = 1:(size(colorInput,1))
                    % if not in range, [0,1]
                    if any(colorInput(i,:) < 0) || any(colorInput(i,:) > 1) || ~isequal(size(colorInput(i,:)),[1,3])
                        % invalid range
                        eid = 'Color:invalidRGBTriplet';
                        msg = 'Must be 3x1 double in the range [0,1]';
                        throwAsCaller(MException(eid,msg))
                    end
                end
            end

        otherwise
            % invalid class
            eid = 'Class:invalidClass';
            msg = 'CData must be an nx1 cell array or nx3 double array of RGB triplets.';
            throwAsCaller(MException(eid,msg))
    end

end