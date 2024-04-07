classdef ViolinChart < matlab.ui.componentcontainer.ComponentContainer
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

    properties(AbortSet = true)
        % cell array of data
        Data (:,1) cell
        % title of the chart displayed at the top of the axes
        Title (1,:) char = 'Violin Chart'
        % color of axes and title text
        FontColor (1,3) double = [0 0 0]
        % name of the axes font for titles and labels, defaul Arial
        FontName (1,:) char = 'Arial'
        % color of axes axis lines
        ForegroundColor (1,3) double = [0 0 0]
        % spacing of violin plots
        PlotSpacing (1,1) double = 1
        % jitter width of each plot
        XJitterWidth (1,1) double = 0.9
        % type of jitter
        XJitter (1,:) char {mustBeMember(XJitter,{'density','none'})} = 'density'
        % label of the x-axis
        XLabel (1,:) char = 'Group'
        % label of the y-axis
        YLabel (1,:) char = 'Data'
        % size of the various text objects
        FontSize (1,1) double = 12

        % visibility of the individual data points
        PointsVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        % size of the plot markers (scalar value in points)
        MarkerSize (1,1) double = 25
        % alpha data for the plot marker faces (scalar value in the range [0 1])
        MarkerFaceAlpha (1,1) double {mustBeInRange(MarkerFaceAlpha,0,1)} = 0.5
        % color mode for marker edges
        MarkerEdgeColorMode (1,:) {mustBeMember(MarkerEdgeColorMode,{'single','multi','auto'})} = 'single'
        % color mode for marker faces
        MarkerFaceColorMode (1,:) {mustBeMember(MarkerFaceColorMode,{'single','multi','auto'})} = 'auto'

        % visibility status of the violin outlines
        ViolinOutlinesVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        % line width of the violin edges
        ViolinLineWidth (1,1) double = 1
        % color mode for violin faces
        ViolinFaceColorMode (1,:) {mustBeMember(ViolinFaceColorMode,{'single','multi','auto'})} = 'auto'
        % color mode for violin edges
        ViolinEdgeColorMode (1,:) {mustBeMember(ViolinEdgeColorMode,{'single','multi','auto'})} = 'single'
        % transparency of violin faces
        ViolinFaceAlpha (1,1) double {mustBeInRange(ViolinFaceAlpha,0,1)} = 0.5

        % visibility of the error bars
        ErrorBarsVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        % line width of the error bars
        ErrorBarsLineWidth (1,1) double = 2
        % color mode for error bars
        ErrorBarsColorMode (1,:) {mustBeMember(ErrorBarsColorMode,{'single','multi','auto'})} = 'auto'

        % colormap of the axes
        Colormap (:,3) double = turbo
    end


    %% dependent properties with associated private properties for more extensive input validation, 
    % along with their Set/Get methods

    properties(Access = private, AbortSet = true)
        % x-axis tick labels for each violin plot
        user_GroupNames (:,1) cell = {}
        % color(s) of violin faces - matrix of one or more RGB triplets
        user_ViolinFaceColor (:,3) double = []
        % color(s) of violin edges - matrix of one or more RGB triplets
        user_ViolinEdgeColor (:,3) double = [0 0 0]
        % edge color of each plot marker
        user_MarkerEdgeColor (:,3) double = [0 0 0]
        % face color of each plot marker
        user_MarkerFaceColor (:,3) double = []
        % color of the error bar lines
        user_ErrorBarsColor (:,3) double = []
        % edge color of each plot marker
        user_CData {mustBeValidCData(user_CData)} = {}
        % color limits of the axes
        user_CLim (1,2) double = [0 1]
        % how CLim is set | 'auto' - CLim set to data range | 'manual' - CLim set by user
        user_CLimMode (1,:) {mustBeMember(user_CLimMode,{'auto','manual'})} = 'auto'
        % data tip info
        user_DataTipCell (:,2) cell = {{},{}}
    end
    
    properties(Dependent = true, AbortSet = true)
        % x-axis tick labels for each violin plot
        GroupNames (:,1) cell
        % color(s) of violin faces - matrix of one or more RGB triplets
        ViolinFaceColor (:,3) double
        % color(s) of violin edges - matrix of one or more RGB triplets
        ViolinEdgeColor (:,3) double
        % edge color of each plot marker
        MarkerEdgeColor (:,3) double
        % face color of each plot marker
        MarkerFaceColor (:,3) double
        % color of the error bar lines
        ErrorBarsColor (:,3) double
        % face color of each plot marker, each cell is an RGB triplet or column vector
        CData {mustBeValidCData(CData)}
        % color limits of the axes, used when a cell of CData is a vector
        CLim (1,2) double
        % how CLim is set | 'auto' - CLim set to data range | 'manual' - CLim set by user
        CLimMode (1,:) {mustBeMember(CLimMode,{'auto','manual'})}
        % data tip info
        DataTipCell (:,2) cell
    end

    methods

        function GroupNames = get.GroupNames(obj)
            % check to make sure number of names matches number of violins
            % if not, create default names to replace missing before returning

            nGiven = numel(obj.user_GroupNames);
            nNeeded = obj.nViolins;

            if nGiven == nNeeded
                GroupNames = obj.user_GroupNames;
            elseif nGiven >= nNeeded
                GroupNames = obj.user_GroupNames(1:nNeeded);
            else % create more default names if necessary
                %nameIdx = obj.violinIdxs((nGiven+1):end);
                GroupNames = [obj.user_GroupNames;...
                    arrayfun(@(x) ['data',num2str(x)],obj.violinIdxs((nGiven+1):end),'UniformOutput',false)];
            end
            % update user_GroupNames so we don't have to adjust every time
            obj.user_GroupNames = GroupNames;
        end

        function set.GroupNames(obj,val)
            obj.user_GroupNames = val;
        end

        function CData = get.CData(obj)

            nCells = numel(obj.user_CData);
            nData = obj.nViolins;

            if nCells == 0
                % if no CData specified, just return MarkerFaceColor converted to cell
                CData = mat2cell(obj.MarkerFaceColor,ones(1,nData));
            elseif nCells >= nData
                % if number of CData cells greater than or equal to number of Data cells, return the amount we need
                CData = obj.user_CData(1:nData);
            else
                % otherwise, return the CData cells we have, plus the remaining MarkerFaceColor rows converted to cell
                CData = [obj.user_CData(1:nCells);mat2cell(obj.MarkerFaceColor(nCells+1:end,:),ones(1,nData-nCells))];
            end

        end

        function set.CData(obj,val)
            obj.user_CData = val;
        end

        function MarkerFaceColor = get.MarkerFaceColor(obj)
            switch obj.MarkerFaceColorMode
                case 'single'
                    % number of colors supplied
                    nColors = size(obj.user_MarkerFaceColor,1);
                    % if no colors supplied, take the first default color from the axes
                    if nColors == 0
                        obj.user_MarkerFaceColor(1,:) = obj.MainAxes.ColorOrder(1,:);
                    end
                    % if single color mode, just use the first RGB triplet for each plot
                    MarkerFaceColor = repmat(obj.user_MarkerFaceColor(1,:),obj.nViolins,1);
                case 'multi'
                    if size(obj.user_MarkerFaceColor,1) >= obj.nViolins
                        MarkerFaceColor = obj.user_MarkerFaceColor(obj.violinIdxs,:);
                    else
                        nGiven = size(obj.user_MarkerFaceColor,1);
                        nNeeded = obj.nViolins - nGiven;
                        idx = nGiven+1;
                        % add new colors from ColorOrder to the existing colors
                        MarkerFaceColor = [obj.user_MarkerFaceColor;obj.nextNColorsFromIdx(idx,nNeeded)];
                    end
                case 'auto'
                    MarkerFaceColor = obj.nextNColorsFromIdx(1,obj.nViolins);
            end
            obj.user_MarkerFaceColor = MarkerFaceColor;
        end

        function set.MarkerFaceColor(obj,val)
            % number of colors given
            nColors = size(val,1);
            % adjust color mode based on number of colors given
            if nColors == 0
                obj.MarkerFaceColorMode = "auto";
            elseif nColors > 1
                obj.MarkerFaceColorMode = "multi";
            elseif nColors == 1
                obj.MarkerFaceColorMode = "single";
            end
            obj.user_MarkerFaceColor = val;
        end

        function ViolinFaceColor = get.ViolinFaceColor(obj)
            switch obj.ViolinFaceColorMode
                case 'single'
                    % number of colors supplied
                    nColors = size(obj.user_ViolinFaceColor,1);
                    % if no colors supplied, take the first default color from the axes
                    if nColors == 0
                        obj.user_ViolinFaceColor(1,:) = obj.MainAxes.ColorOrder(1,:);
                    end
                    % if single color mode, just use the first RGB triplet for each plot
                    ViolinFaceColor = repmat(obj.user_ViolinFaceColor(1,:),obj.nViolins,1);
                case 'multi'
                    if size(obj.user_ViolinFaceColor,1) >= obj.nViolins
                        ViolinFaceColor = obj.user_ViolinFaceColor(obj.violinIdxs,:);
                    else
                        nGiven = size(obj.user_ViolinFaceColor,1);
                        nNeeded = obj.nViolins - nGiven;
                        idx = nGiven+1;
                        % add new colors from ColorOrder to the existing colors
                        ViolinFaceColor = [obj.user_ViolinFaceColor;obj.nextNColorsFromIdx(idx,nNeeded)];
                    end
                case 'auto'
                    ViolinFaceColor = obj.nextNColorsFromIdx(1,obj.nViolins);
            end
            obj.user_ViolinFaceColor = ViolinFaceColor;
        end

        function set.ViolinFaceColor(obj,val)
            % number of colors given
            nColors = size(val,1);
            % adjust color mode based on number of colors given
            if nColors == 0
                obj.ViolinFaceColorMode = "auto";
            elseif nColors > 1
                obj.ViolinFaceColorMode = "multi";
            elseif nColors == 1
                obj.ViolinFaceColorMode = "single";
            end
            obj.user_ViolinFaceColor = val;
        end

        function ViolinEdgeColor = get.ViolinEdgeColor(obj)
            switch obj.ViolinEdgeColorMode
                case 'single'
                    % number of colors supplied
                    nColors = size(obj.user_ViolinEdgeColor,1);
                    % if no colors supplied, take the first default color from the axes
                    if nColors == 0
                        obj.user_ViolinEdgeColor(1,:) = obj.MainAxes.ColorOrder(1,:);
                    end
                    % if single color mode, just use the first RGB triplet for each plot
                    ViolinEdgeColor = repmat(obj.user_ViolinEdgeColor(1,:),obj.nViolins,1);
                case 'multi'
                    if size(obj.user_ViolinEdgeColor,1) >= obj.nViolins
                        ViolinEdgeColor = obj.user_ViolinEdgeColor(obj.violinIdxs,:);
                    else
                        nGiven = size(obj.user_ViolinEdgeColor,1);
                        nNeeded = obj.nViolins - nGiven;
                        idx = nGiven+1;
                        % add new colors from ColorOrder to the existing colors
                        ViolinEdgeColor = [obj.user_ViolinEdgeColor;obj.nextNColorsFromIdx(idx,nNeeded)];
                    end
                case 'auto'
                    ViolinEdgeColor = obj.nextNColorsFromIdx(1,obj.nViolins);
            end
            obj.user_ViolinEdgeColor = ViolinEdgeColor;
        end

        function set.ViolinEdgeColor(obj,val)
            % number of colors given
            nColors = size(val,1);
            % adjust color mode based on number of colors given
            if nColors == 0
                obj.ViolinEdgeColorMode = "auto";
            elseif nColors > 1
                obj.ViolinEdgeColorMode = "multi";
            elseif nColors == 1
                obj.ViolinEdgeColorMode = "single";
            end
            obj.user_ViolinEdgeColor = val;
        end

        function ErrorBarsColor = get.ErrorBarsColor(obj)
            switch obj.ErrorBarsColorMode
                case 'single'
                    % number of colors supplied
                    nColors = size(obj.user_ErrorBarsColor,1);
                    % if no colors supplied, take the first default color from the axes
                    if nColors == 0
                        obj.user_ErrorBarsColor(1,:) = obj.MainAxes.ColorOrder(1,:);
                    end
                    % if single color mode, just use the first RGB triplet for each plot
                    ErrorBarsColor = repmat(obj.user_ErrorBarsColor(1,:),obj.nViolins,1);
                case 'multi'
                    if size(obj.user_ErrorBarsColor,1) >= obj.nViolins
                        ErrorBarsColor = obj.user_ErrorBarsColor(obj.violinIdxs,:);
                    else
                        nGiven = size(obj.user_ErrorBarsColor,1);
                        nNeeded = obj.nViolins - nGiven;
                        idx = nGiven+1;
                        % add new colors from ColorOrder to the existing colors
                        ErrorBarsColor = [obj.user_ErrorBarsColor;obj.nextNColorsFromIdx(idx,nNeeded)];
                    end
                case 'auto'
                    ErrorBarsColor = obj.nextNColorsFromIdx(1,obj.nViolins);
            end
            obj.user_ErrorBarsColor = ErrorBarsColor;
        end

        function set.ErrorBarsColor(obj,val)
            % number of colors given
            nColors = size(val,1);
            % adjust color mode based on number of colors given
            if nColors == 0
                obj.ErrorBarsColorMode = "auto";
            elseif nColors > 1
                obj.ErrorBarsColorMode = "multi";
            elseif nColors == 1
                obj.ErrorBarsColorMode = "single";
            end
            obj.user_ErrorBarsColor = val;
        end

        function MarkerEdgeColor = get.MarkerEdgeColor(obj)
            switch obj.MarkerEdgeColorMode
                case 'single'
                    % number of colors supplied
                    nColors = size(obj.user_MarkerEdgeColor,1);
                    % if no colors supplied, take the first default color from the axes
                    if nColors == 0
                        obj.user_MarkerEdgeColor(1,:) = obj.MainAxes.ColorOrder(1,:);
                    end
                    % if single color mode, just use the first RGB triplet for each plot
                    MarkerEdgeColor = repmat(obj.user_MarkerEdgeColor(1,:),obj.nViolins,1);
                    % % if single color mode, just use the first RGB triplet for each plot
                    % MarkerEdgeColor = repmat(obj.user_MarkerEdgeColor(1,:),obj.nViolins,1);
                case 'multi'
                    if size(obj.user_MarkerEdgeColor,1) >= obj.nViolins
                        MarkerEdgeColor = obj.user_MarkerEdgeColor(obj.violinIdxs,:);
                    else
                        nGiven = size(obj.user_MarkerEdgeColor,1);
                        nNeeded = obj.nViolins - nGiven;
                        idx = nGiven+1;
                        % add new colors from ColorOrder to the existing colors
                        MarkerEdgeColor = [obj.user_MarkerEdgeColor;obj.nextNColorsFromIdx(idx,nNeeded)];
                    end

                    % if size(obj.user_MarkerEdgeColor,1) >= obj.nViolins
                    %     MarkerEdgeColor = obj.user_MarkerEdgeColor(obj.violinIdxs,:);
                    % else
                    %     % number of RGB triplets in the ColorOrder property of the axes
                    %     nColorsInOrder = size(obj.MainAxes.ColorOrder,1);
                    %     % idxs to RGB triplets in the ColorOrder (cycled if more violins than colors)
                    %     newColorIdxs = mod(obj.violinIdxs(size(obj.user_MarkerEdgeColor,1)+1:end),nColorsInOrder);
                    %     newColorIdxs(newColorIdxs==0) = nColorsInOrder;
                    %     % add new colors from ColorOrder to the existing colors
                    %     MarkerEdgeColor = [obj.user_MarkerEdgeColor;obj.MainAxes.ColorOrder(newColorIdxs,:)];
                    % end
                case 'auto'
                    MarkerEdgeColor = obj.nextNColorsFromIdx(1,obj.nViolins);
            end
            obj.user_MarkerEdgeColor = MarkerEdgeColor;
        end

        function set.MarkerEdgeColor(obj,val)
            % number of colors given
            nColors = size(val,1);
            % adjust color mode based on number of colors given
            if nColors == 0
                obj.MarkerEdgeColorMode = "auto";
            elseif nColors > 1
                obj.MarkerEdgeColorMode = "multi";
            elseif nColors == 1
                obj.MarkerEdgeColorMode = "single";
            end
            obj.user_MarkerEdgeColor = val;
        end

        function CLimMode = get.CLimMode(obj)
            CLimMode = obj.user_CLimMode;
        end

        function set.CLimMode(obj,val)
            obj.user_CLimMode = val;
            obj.user_CLim = obj.CLim;
        end

        function CLim = get.CLim(obj)
            % if CLimMode is 'auto', set user_CLim to data range
            if strcmp(obj.user_CLimMode,'auto')
                CLim = [min(cellfun(@(x) min(x),obj.Data,'UniformOutput',true)) max(cellfun(@(x) max(x),obj.Data,'UniformOutput',true))];
                if any(isnan(CLim))
                    CLim = [0 1];
                end

                if isempty(CLim)
                    CLim = [0 1];
                end

                obj.user_CLim = CLim;
            else
                CLim = obj.user_CLim;
            end
        end

        function set.CLim(obj,val)
            obj.user_CLim = val;
            obj.CLimMode = "manual";
        end

        function DataTipCell = get.DataTipCell(obj)

            % column vector cell of datatip labels
            dtNames = obj.user_DataTipCell(:,1);
            % column vector cell of datatip values
            dtData = obj.user_DataTipCell(:,2);

            nGiven = min(size(dtNames,1),size(dtData,1));

            nNeeded = obj.nViolins;

            if nNeeded==0
                DataTipCell = {{},{}};
            elseif nGiven==nNeeded
                DataTipCell = obj.user_DataTipCell;
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

            obj.user_DataTipCell = DataTipCell;
        end

        function set.DataTipCell(obj,val)
            obj.user_DataTipCell = val;
        end

    end


    %% private helper methods

    methods(Access = private)

        function nextNColors = nextNColorsFromIdx(obj,idx,n)
            % number of RGB triplets in the ColorOrder property of the axes
            nColorsInOrder = size(obj.MainAxes.ColorOrder,1);
            % unwrapped idx to the colors in ColorOrder
            cIdx = idx:(idx+n-1);
            % wrapped idxs to RGB triplets in the ColorOrder (cycled if more violins than colors)
            newColorIdxs = mod(cIdx,nColorsInOrder);
            newColorIdxs(newColorIdxs==0) = nColorsInOrder;
            % add new colors from ColorOrder to the existing colors
            nextNColors = obj.MainAxes.ColorOrder(newColorIdxs,:);
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
        nViolins
        violinIdxs
        XTick
    end

    methods
    
        function nViolins = get.nViolins(obj)
            nViolins = numel(obj.Data);
        end
    
        function violinIdxs = get.violinIdxs(obj)
            if obj.nViolins>0
                violinIdxs = (1:obj.nViolins).';
            else
                violinIdxs = [];
            end
        end

        function XTick = get.XTick(obj)
            if obj.nViolins==0
                XTick = cumsum(repmat(obj.PlotSpacing,1,1));
                return
            end
            XTick = cumsum(repmat(obj.PlotSpacing,1,obj.nViolins));
        end

    end

    %% graphics components the ViolinChart is built from
        
    properties(Access = private,Transient,NonCopyable)
        Grid (1,1) matlab.ui.container.GridLayout
        MainAxes (1,1) matlab.ui.control.UIAxes
        Violins (:,1) ViolinPlot
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
            % uiaxes to hold our wedge patch objects
            obj.MainAxes = uiaxes(obj.Grid,...
                "XColor",[0 0 0],...
                "YColor",[0 0 0],...
                "Box","off",...
                "NextPlot","add",...
                "TickDir","in",...
                "FontName",obj.FontName);
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
    
            obj.MainAxes.Interactions = dataTipInteraction;
            axtoolbar(obj.MainAxes,{});
            
            % preallocate empty ViolinPlot array
            obj.Violins = ViolinPlot.empty();
            
            % use normalized units for the component, stretched to fill the container
            obj.Units = 'Normalized';
            obj.Position = [0 0 1 1];
        end
        
        function update(obj)
            
            %% update x-axis limits, tick locations, tick labels, and font sizes

            % set ticks at locations specified by number of plots and plot spacing
            obj.MainAxes.XTick = obj.XTick;
            % set XLim to have user-specified spacing on either side of the plots
            obj.MainAxes.XLim = [0 obj.MainAxes.XTick(end)+obj.PlotSpacing];  

            % set label text for each tick
            obj.MainAxes.XTickLabel = obj.GroupNames;

            % set x-axis label string and font size
            obj.MainAxes.XLabel.String = obj.XLabel;
            obj.MainAxes.XLabel.FontSize = obj.FontSize;
            
            %% update the plots

            % keep the valid violins only
            obj.Violins = obj.Violins(isvalid(obj.Violins));
            % the number of valid violins currently plotted
            nPlots = numel(obj.Violins);
            % the number of violins we need
            nPlotsNeeded = obj.nViolins;


            if nPlots < nPlotsNeeded
                for i = nPlots+1:nPlotsNeeded
                    obj.Violins(i) = ViolinPlot(obj.MainAxes);
                end
            elseif nPlots > nPlotsNeeded
                % delete the excess plots
                delete(obj.Violins(nPlotsNeeded+1:nPlots))
            end

            % get the datatip info
            dtCell = obj.DataTipCell;

            CData4Plot = obj.CData;


            for i = 1:nPlotsNeeded
                try
                    obj.Violins(i).PointsVisible = obj.PointsVisible;
                    obj.Violins(i).XData = ones(size(obj.Data{i})).*obj.MainAxes.XTick(i);
                    obj.Violins(i).YData = obj.Data{i};
                    obj.Violins(i).XJitterWidth = obj.XJitterWidth;
                    obj.Violins(i).XJitter = obj.XJitter;
                    obj.Violins(i).DataTipCell = dtCell(i,:);
                    obj.Violins(i).MarkerEdgeColor = obj.MarkerEdgeColor(i,:);
                    obj.Violins(i).MarkerSize = obj.MarkerSize;
                    obj.Violins(i).MarkerFaceColorMode = 'flat';
                    obj.Violins(i).MarkerFaceAlpha = obj.MarkerFaceAlpha;
                    obj.Violins(i).CData = CData4Plot{i};

                    obj.Violins(i).ViolinOutlinesVisible = obj.ViolinOutlinesVisible;
                    obj.Violins(i).ViolinLineWidth = obj.ViolinLineWidth;
                    obj.Violins(i).ViolinFaceColor = obj.ViolinFaceColor(i,:);
                    obj.Violins(i).ViolinEdgeColor = obj.ViolinEdgeColor(i,:);
                    obj.Violins(i).ViolinFaceAlpha = obj.ViolinFaceAlpha;

                    obj.Violins(i).ErrorBarsVisible = obj.ErrorBarsVisible;
                    obj.Violins(i).ErrorBarsLineWidth = obj.ErrorBarsLineWidth;
                    obj.Violins(i).ErrorBarsColor = obj.ErrorBarsColor(i,:);
                catch ME
                    disp(ME.getReport)
                    disp(ME.message)
                end
            end

            %% update axis title

            obj.MainAxes.Title.String = obj.Title;
            obj.MainAxes.Title.Color = obj.FontColor;
            obj.MainAxes.Title.FontSize = obj.FontSize;
            obj.MainAxes.Title.Visible = 'on';

            %% update font name

            obj.MainAxes.FontName = obj.FontName;
    
            %% update background and foreground colors
            
            % grid background color
            obj.Grid.BackgroundColor = obj.BackgroundColor;
            % axes background color
            obj.MainAxes.Color = obj.BackgroundColor;
            % axes axis lines color
            obj.MainAxes.XColor = obj.ForegroundColor;
            obj.MainAxes.YColor = obj.ForegroundColor;

            %% update x-axis and y-axis label font colors

            obj.MainAxes.XLabel.Color = obj.FontColor;
            obj.MainAxes.YLabel.Color = obj.FontColor;

            %% update y-axis

            obj.MainAxes.YTickMode = 'Auto';
            obj.MainAxes.YTickLabelMode = 'Auto';
            obj.MainAxes.YLimMode = 'Auto';
            obj.MainAxes.YLabel.String = obj.YLabel;
            obj.MainAxes.YLabel.FontSize = obj.FontSize;
            obj.MainAxes.FontSize = obj.FontSize;

            %% update axes colormap and color limits

            obj.MainAxes.Colormap = obj.Colormap;
            obj.MainAxes.CLim = obj.CLim;

            %% update context menu (development)

            if isvalid(obj.ContextMenu)
                obj.MainAxes.ContextMenu = obj.ContextMenu;
            end
    
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


