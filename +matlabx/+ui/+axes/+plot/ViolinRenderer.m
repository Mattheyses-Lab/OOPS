classdef ViolinRenderer < matlabx.ui.axes.PlotContent
%VIOLINRENDERER Render grouped swarm/violin series into a PlotAxes host.
%
%   renderer = matlabx.ui.axes.plot.ViolinRenderer;
%   renderer.update(data,style);
%   host.mount(renderer);
%
% Data and style remain stored while detached. setData and setStyle update
% one half of the renderer state; update replaces both with one refresh.
%
% See also matlabx.ui.axes.PlotAxes, matlabx.ui.axes.PlotContent,
% matlabx.ui.axes.plot.ViolinData, matlabx.ui.axes.plot.ViolinStyle,
% matlabx.ui.axes.plot.Violin

% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

    % Publicly readable renderer inputs retained across host transfers.
    properties (SetAccess=private)
        % Normalized grouped observations currently stored by the renderer.
        Data (1,1) matlabx.ui.axes.plot.ViolinData = matlabx.ui.axes.plot.ViolinData()
        % Appearance currently applied when the renderer is attached.
        Style (1,1) matlabx.ui.axes.plot.ViolinStyle = matlabx.ui.axes.plot.ViolinStyle()
    end

    % Renderer-owned primitives retained across host transfers.
    properties (Access=private)
        % One low-level violin group per logical data series.
        Plots (:,1) matlabx.ui.axes.plot.Violin = matlabx.ui.axes.plot.Violin.empty(0,1)
    end

    methods

        function update(obj,data,style)
        %UPDATE Store normalized data and style, then perform one refresh.

            arguments
                obj
                data (1,1) matlabx.ui.axes.plot.ViolinData
                style (1,1) matlabx.ui.axes.plot.ViolinStyle
            end

            obj.Data = data;
            obj.Style = style;
            obj.refresh();
        end

        function setData(obj,data)
        %SETDATA Replace normalized plot data while preserving current style.

            obj.Data = data;
            obj.refresh();
        end

        function setStyle(obj,style)
        %SETSTYLE Replace renderer appearance while preserving current data.

            obj.Style = style;
            obj.refresh();
        end

        function refresh(obj)
        %REFRESH Apply stored series and appearance to the current PlotAxes.

            if isempty(obj.Host)
                return;
            end

            axes = obj.Host.Axes;
            data = obj.Data;
            style = obj.Style;
            count = numel(data.Values);
            obj.ensurePlots(axes,count);
            ticks = 1:count;
            automatic = obj.seriesColors(axes,count);

            for k = 1:count
                plot = obj.Plots(k);
                plot.Parent = axes;
                plot.PointsVisible = 'off';
                plot.ViolinOutlinesVisible = 'off';
                plot.ErrorBarsVisible = 'off';
                plot.XJitter = 'density';
                plot.XJitterWidth = style.XJitterWidth;
                plot.CentralStatistic = style.CentralStatistic;
                plot.ErrorStatistic = style.ErrorStatistic;
                plot.setData(ones(size(data.Values{k}))*ticks(k), ...
                    data.Values{k},data.CData{k});
                plot.Name = char(data.SeriesNames(k));
                if isempty(data.DataTipCells{k})
                    group = categorical(repmat(data.SeriesNames(k), ...
                        numel(data.Values{k}),1));
                    plot.DataTipCell = {{"Series","Value"}, ...
                        {group,data.Values{k}}};
                else
                    plot.DataTipCell = data.DataTipCells{k};
                end
                plot.DataTipFormat = style.DataTipFormat;
                if isempty(data.SummaryDataTipCells{k})
                    plot.SummaryDataTipCell = {{},{}};
                else
                    plot.SummaryDataTipCell = data.SummaryDataTipCells{k};
                end
                plot.MarkerSize = style.MarkerSize;
                plot.MarkerLineWidth = style.MarkerLineWidth;
                if style.MarkerFaceColorMode == "CData"
                    plot.MarkerFaceColorMode = 'flat';
                else
                    plot.MarkerFaceColorMode = obj.resolveColor( ...
                        style.MarkerFaceColorMode,style.MarkerFaceColor,automatic(k,:));
                end
                plot.MarkerFaceAlpha = style.MarkerFaceAlpha;
                plot.MarkerEdgeAlpha = style.MarkerEdgeAlpha;
                if style.MarkerEdgeColorMode == "CData"
                    plot.MarkerEdgeColor = 'flat';
                else
                    plot.MarkerEdgeColor = obj.resolveColor( ...
                        style.MarkerEdgeColorMode,style.MarkerEdgeColor,automatic(k,:));
                end
                plot.ViolinFaceColor = obj.resolveColor( ...
                    style.ViolinFaceColorMode,style.ViolinFaceColor,automatic(k,:));
                plot.ViolinLineWidth = style.ViolinLineWidth;
                plot.ViolinEdgeColor = obj.resolveColor( ...
                    style.ViolinEdgeColorMode,style.ViolinEdgeColor,automatic(k,:));
                plot.ViolinEdgeAlpha = style.ViolinEdgeAlpha;
                plot.ErrorBarsColor = obj.resolveColor( ...
                    style.ErrorBarsColorMode,style.ErrorBarsColor,automatic(k,:));
                plot.ErrorBarsLineWidth = style.ErrorBarsLineWidth;
                plot.CentralStatLineWidth = style.CentralStatLineWidth;
                plot.PointsVisible = matlab.lang.OnOffSwitchState(style.PointsVisible);
                plot.ViolinOutlinesVisible = matlab.lang.OnOffSwitchState(style.ViolinOutlinesVisible);
                plot.ErrorBarsVisible = matlab.lang.OnOffSwitchState(style.ErrorBarsVisible);
            end

            axes.XTick = ticks;
            axes.XTickLabel = cellstr(data.SeriesNames);
            axes.XLim = [0,count+1];
            axes.XScale = 'linear';
            axes.YScale = 'linear';
            axes.YLimMode = 'auto';
            axes.YTickMode = 'auto';
            axes.YTickLabelMode = 'auto';
            axes.XLabel.String = char(style.XLabel);
            axes.YLabel.String = char(style.YLabel);
            axes.Title.String = char(style.Title);
            axes.Colormap = style.Colormap;
            axes.CLim = style.CLim;
            obj.Host.BackgroundColor = style.BackgroundColor;
            obj.Host.ForegroundColor = style.ForegroundColor;
        end

        function handleEvent(obj,kind,event)
        %HANDLEEVENT Delegate routed data-tip gestures to all violin groups.
            if ~any(string(kind) == ["Down","Move","Leave"])
                return;
            end
            for k = 1:numel(obj.Plots)
                obj.Plots(k).handleEvent(event);
            end
        end

        function delete(obj)
        %DELETE Release renderer-owned violin primitives.

            obj.detach();
            delete(obj.Plots(isvalid(obj.Plots)));
        end

    end

    methods (Access=protected)

        function attachGraphics(obj,axes)
        %ATTACHGRAPHICS Move all existing violin primitives to a new UIAxes.

            for k = 1:numel(obj.Plots)
                obj.Plots(k).Parent = axes;
            end
        end

        function hideGraphics(obj)
        %HIDEGRAPHICS Hide all primitives while this renderer has no host.

            for k = 1:numel(obj.Plots)
                obj.Plots(k).PointsVisible = 'off';
                obj.Plots(k).ViolinOutlinesVisible = 'off';
                obj.Plots(k).ErrorBarsVisible = 'off';
            end
        end

    end

    methods (Access=private)

        function ensurePlots(obj,axes,count)
        %ENSUREPLOTS Match renderer-owned violin primitives to series count.

            obj.Plots = obj.Plots(isvalid(obj.Plots));

            for k = numel(obj.Plots)+1:count
                obj.Plots(k,1) = matlabx.ui.axes.plot.Violin(axes);
            end

            if numel(obj.Plots) > count
                delete(obj.Plots(count+1:end));
                obj.Plots = obj.Plots(1:count);
            end
        end

        function colors = seriesColors(~,axes,count)
        %SERIESCOLORS Repeat the axes color order for every rendered series.

            order = axes.ColorOrder;
            indices = mod(0:count-1,size(order,1))+1;
            colors = order(indices,:);
        end

        function color = resolveColor(~,mode,custom,automatic)
        %RESOLVECOLOR Choose a custom color or its series-specific automatic value.

            if string(mode) == "Custom"
                color = custom;
            else
                color = automatic;
            end
        end

    end

end
