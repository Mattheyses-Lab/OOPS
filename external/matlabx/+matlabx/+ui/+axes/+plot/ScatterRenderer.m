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

classdef ScatterRenderer < matlabx.ui.axes.PlotContent
%SCATTERRENDERER Render grouped scatter series into a transferable PlotAxes.

    properties (SetAccess=private)
        Data (1,1) matlabx.ui.axes.plot.ScatterData = matlabx.ui.axes.plot.ScatterData()
        Style (1,1) matlabx.ui.axes.plot.ScatterStyle = matlabx.ui.axes.plot.ScatterStyle()
    end

    properties (Access=private)
        Plots (:,1) matlabx.ui.axes.plot.Scatter = matlabx.ui.axes.plot.Scatter.empty(0,1)
        Legend matlab.graphics.illustration.Legend = matlab.graphics.illustration.Legend.empty()
        LegendPlots (:,1) matlab.graphics.chart.primitive.Line = matlab.graphics.chart.primitive.Line.empty()
    end

    methods

        function update(obj,data,style)
        %UPDATE Store normalized data and style, then perform one refresh.

            arguments
                obj
                data (1,1) matlabx.ui.axes.plot.ScatterData
                style (1,1) matlabx.ui.axes.plot.ScatterStyle
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
        %REFRESH Apply stored series, settings, and host-owned axes presentation.

            if isempty(obj.Host)
                return;
            end

            axes = obj.Host.Axes;
            data = obj.Data;
            style = obj.Style;
            obj.ensurePlots(axes,numel(data.XData));

            % Series colors supplied by the axes order when a setting uses auto mode.
            automatic = obj.seriesColors(axes,numel(obj.Plots));
            markers = {'o','s','^','h','p','d','v','>','<'};

            for k = 1:numel(obj.Plots)
                plot = obj.Plots(k);
                plot.setParent(axes);
                plot.HullVisible = 'off';
                plot.XData = data.XData{k};
                plot.YData = data.YData{k};
                plot.DataTipCell = {{},{}};
                plot.MarkerSize = style.MarkerSize;
                plot.MarkerFaceColor = 'flat';
                plot.MarkerFaceAlpha = style.MarkerFaceAlpha;
                plot.MarkerEdgeAlpha = style.MarkerEdgeAlpha;
                plot.CData = data.CData{k};
                plot.Name = char(data.SeriesNames(k));

                if style.MarkerMode == "single"
                    plot.Marker = 'o';
                else
                    plot.Marker = markers{mod(k-1,numel(markers))+1};
                end

                if style.MarkerEdgeColorMode == "Custom"
                    plot.MarkerEdgeColor = style.MarkerEdgeColor;
                else
                    plot.MarkerEdgeColor = automatic(k,:);
                end

                plot.HullLineWidth = style.HullLineWidth;
                plot.HullFaceAlpha = style.HullFaceAlpha;
                plot.HullEdgeAlpha = style.HullEdgeAlpha;

                if style.HullFaceColorMode == "Custom"
                    plot.HullFaceColor = style.HullFaceColor;
                else
                    plot.HullFaceColor = automatic(k,:);
                end

                if style.HullEdgeColorMode == "Custom"
                    plot.HullEdgeColor = style.HullEdgeColor;
                else
                    plot.HullEdgeColor = automatic(k,:);
                end

                plot.HullType = char(style.HullType);
                plot.HullVisible = matlab.lang.OnOffSwitchState(style.HullVisible);
                plot.PointsVisible = 'on';
            end

            axes.Title.String = char(style.Title);
            axes.XLabel.String = char(style.XLabel);
            axes.YLabel.String = char(style.YLabel);
            axes.Colormap = style.Colormap;
            axes.CLim = style.CLim;
            axes.XScale = 'linear';
            axes.YScale = 'linear';
            axes.XLimMode = 'auto';
            axes.YLimMode = 'auto';
            axes.XTickMode = 'auto';
            axes.YTickMode = 'auto';
            axes.XTickLabelMode = 'auto';
            axes.YTickLabelMode = 'auto';
            obj.Host.BackgroundColor = style.BackgroundColor;
            obj.Host.ForegroundColor = style.ForegroundColor;
            obj.refreshLegend(axes,automatic);

            % Hull patches remain behind points and legend proxy graphics.
            if style.HullVisible
                axes.Children = [findobj(axes.Children,'-not','Type','patch'); ...
                    findobj(axes.Children,'Type','patch')];
            end
        end

        function delete(obj)
        %DELETE Release renderer-owned plot primitives and legend proxies.

            delete(obj.LegendPlots(isvalid(obj.LegendPlots)));
            delete(obj.Legend(isvalid(obj.Legend)));
            obj.detach();
            delete(obj.Plots(isvalid(obj.Plots)));
        end

    end

    methods (Access=protected)

        function attachGraphics(obj,axes)
        %ATTACHGRAPHICS Move existing scatter primitives to the new stable axes.

            for k = 1:numel(obj.Plots)
                obj.Plots(k).setParent(axes);
            end
        end

        function hideGraphics(obj)
        %HIDEGRAPHICS Hide renderer primitives while no PlotAxes owns them.

            for k = 1:numel(obj.Plots)
                obj.Plots(k).PointsVisible = 'off';
                obj.Plots(k).HullVisible = 'off';
            end

            delete(obj.LegendPlots(isvalid(obj.LegendPlots)));
            obj.LegendPlots = matlab.graphics.chart.primitive.Line.empty();
            delete(obj.Legend(isvalid(obj.Legend)));
            obj.Legend = matlab.graphics.illustration.Legend.empty();
        end

    end

    methods (Access=private)

        function ensurePlots(obj,axes,count)
        %ENSUREPLOTS Match renderer-owned primitive sets to normalized series count.

            obj.Plots = obj.Plots(isvalid(obj.Plots));

            for k = numel(obj.Plots)+1:count
                obj.Plots(k,1) = matlabx.ui.axes.plot.Scatter(axes);
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

        function refreshLegend(obj,axes,colors)
        %REFRESHLEGEND Recreate axes-specific proxy graphics after host transfer.

            delete(obj.LegendPlots(isvalid(obj.LegendPlots)));
            obj.LegendPlots = matlab.graphics.chart.primitive.Line.empty();
            delete(obj.Legend(isvalid(obj.Legend)));
            obj.Legend = matlab.graphics.illustration.Legend.empty();

            if ~obj.Style.LegendVisible
                return;
            end

            for k = 1:numel(obj.Data.SeriesNames)
                obj.LegendPlots(k,1) = plot(axes,NaN,NaN, ...
                    'LineStyle','none','Marker','o','MarkerSize',6, ...
                    'MarkerFaceColor',colors(k,:),'MarkerEdgeColor',colors(k,:), ...
                    'DisplayName',char(obj.Data.SeriesNames(k)));
            end

            obj.Legend = legend(axes,obj.LegendPlots,'Location','best');
        end

    end

end
