classdef ScatterRenderer < matlabx.ui.axes.PlotContent
%SCATTERRENDERER Render grouped scatter series into a transferable PlotAxes.
%
%   renderer = matlabx.ui.axes.plot.ScatterRenderer;
%   renderer.update(data,style);
%   host.mount(renderer);
%
% Data and style remain stored while detached. setData and setStyle update
% one half of the renderer state; update replaces both with one refresh.
%
% See also matlabx.ui.axes.PlotAxes, matlabx.ui.axes.PlotContent,
% matlabx.ui.axes.plot.ScatterData, matlabx.ui.axes.plot.ScatterStyle,
% matlabx.ui.axes.plot.Scatter

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
        % Normalized grouped scatter data currently stored by the renderer.
        Data (1,1) matlabx.ui.axes.plot.ScatterData = matlabx.ui.axes.plot.ScatterData()
        % Appearance currently applied when the renderer is attached.
        Style (1,1) matlabx.ui.axes.plot.ScatterStyle = matlabx.ui.axes.plot.ScatterStyle()
    end

    % Renderer-owned primitives and legend graphics.
    properties (Access=private)
        % One low-level scatter group per logical data series.
        Plots (:,1) matlabx.ui.axes.plot.Scatter = matlabx.ui.axes.plot.Scatter.empty(0,1)
        % Legend associated with the current host axes.
        Legend matlab.graphics.illustration.Legend = matlab.graphics.illustration.Legend.empty()
        % Invisible proxy lines used to represent series in the legend.
        LegendPlots (:,1) matlab.graphics.chart.primitive.Line = matlab.graphics.chart.primitive.Line.empty()
        % Content-owned properties window, when currently open.
        PropertiesDialog = []
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
                plot.Parent = axes;
                plot.HullVisible = 'off';
                plot.setData(data.XData{k},data.YData{k},data.CData{k});
                plot.Name = char(data.SeriesNames(k));
                if isempty(data.DataTipCells{k})
                    series = categorical(repmat(data.SeriesNames(k), ...
                        numel(data.XData{k}),1));
                    plot.DataTipCell = {{"Series","X","Y"}, ...
                        {series,data.XData{k},data.YData{k}}};
                else
                    plot.DataTipCell = data.DataTipCells{k};
                end
                plot.DataTipFormat = style.DataTipFormat;
                plot.MarkerSize = style.MarkerSize;
                plot.MarkerLineWidth = style.MarkerLineWidth;
                if style.MarkerFaceColorMode == "CData"
                    plot.MarkerFaceColor = 'flat';
                else
                    plot.MarkerFaceColor = obj.resolveColor( ...
                        style.MarkerFaceColorMode,style.MarkerFaceColor,automatic(k,:));
                end
                plot.MarkerFaceAlpha = style.MarkerFaceAlpha;
                plot.MarkerEdgeAlpha = style.MarkerEdgeAlpha;
                if style.MarkerMode == "single"
                    plot.Marker = 'o';
                else
                    plot.Marker = markers{mod(k-1,numel(markers))+1};
                end

                if style.MarkerEdgeColorMode == "CData"
                    plot.MarkerEdgeColor = 'flat';
                else
                    plot.MarkerEdgeColor = obj.resolveColor( ...
                        style.MarkerEdgeColorMode,style.MarkerEdgeColor,automatic(k,:));
                end

                plot.HullLineWidth = style.HullLineWidth;
                plot.HullFaceAlpha = style.HullFaceAlpha;
                plot.HullEdgeAlpha = style.HullEdgeAlpha;

                plot.HullFaceColor = obj.resolveColor( ...
                    style.HullFaceColorMode,style.HullFaceColor,automatic(k,:));
                plot.HullEdgeColor = obj.resolveColor( ...
                    style.HullEdgeColorMode,style.HullEdgeColor,automatic(k,:));

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
            if style.XLimMode == "manual"
                axes.XLim = style.XLim;
            else
                axes.XLimMode = 'auto';
            end
            if style.YLimMode == "manual"
                axes.YLim = style.YLim;
            else
                axes.YLimMode = 'auto';
            end
            axes.XTickMode = 'auto';
            axes.YTickMode = 'auto';
            axes.XTickLabelMode = 'auto';
            axes.YTickLabelMode = 'auto';
            obj.Host.BackgroundColor = style.BackgroundColor;
            obj.Host.Color = style.BackgroundColor;
            obj.Host.ForegroundColor = style.ForegroundColor;
            obj.refreshLegend(axes,automatic);

            % Hull patches remain behind points and legend proxy graphics.
            if style.HullVisible
                axes.Children = [findobj(axes.Children,'-not','Type','patch'); ...
                    findobj(axes.Children,'Type','patch')];
            end
        end

        function handleEvent(obj,kind,event)
        %HANDLEEVENT Delegate routed data-tip gestures to all scatter groups.
            if ~any(string(kind) == ["Down","Move","Leave"])
                return;
            end
            for k = 1:numel(obj.Plots)
                obj.Plots(k).handleEvent(event);
            end
        end

        function contributeContextMenu(obj,menu)
        %CONTRIBUTECONTEXTMENU Add the mounted scatter plot's Properties command.

            menu.addItem("Scatter.Properties","Properties...", ...
                @(~,~) obj.openProperties(),Owner=obj,Separator="on");
        end

        function openProperties(obj)
        %OPENPROPERTIES Open the scatter-specific axes-limits dialog.
        %
        % Auto mode disables its numeric fields. Editing either field switches
        % that axis to Manual so future scatter-specific settings can be added
        % here without introducing a general style-reflection framework.

            if isgraphics(obj.PropertiesDialog)
                figure(obj.PropertiesDialog);
                return;
            end

            style = obj.Style;
            xLimits = obj.dialogLimits(style.XLim,"X");
            yLimits = obj.dialogLimits(style.YLim,"Y");
            background = [.12 .12 .12];
            paneColor = [.18 .18 .18];
            controlColor = [.3 .3 .3];
            fontColor = [.85 .85 .85];
            controlFontColor = [.9 .9 .9];

            fig = uifigure(Visible="off",Name="Scatter Properties", ...
                InnerPosition=[0 0 410 315],Resize="off",WindowStyle="modal", ...
                Color=background);
            obj.PropertiesDialog = fig;
            fig.CloseRequestFcn = @(~,~) closeDialog();

            root = uigridlayout(fig,[2 1],Padding=[10 10 10 10], ...
                RowSpacing=10,ColumnSpacing=0,BackgroundColor=background, ...
                RowHeight={'1x','fit'},ColumnWidth={'1x'});
            accordionHost = uigridlayout(root,[1 1],Padding=0, ...
                RowSpacing=0,ColumnSpacing=0,BackgroundColor=background, ...
                RowHeight={'fit'},ColumnWidth={'1x'},Scrollable="on");
            accordionHost.Layout.Row = 1;
            accordion = matlabx.ui.container.Accordion(accordionHost, ...
                ItemSpacing=5,BorderWidth=0,BorderColor=paneColor, ...
                Padding=0,BackgroundColor=background);

            [xMode,xMinimum,xMaximum] = makeAxisItem("X Axis", ...
                style.XLimMode,xLimits);
            [yMode,yMinimum,yMaximum] = makeAxisItem("Y Axis", ...
                style.YLimMode,yLimits);

            buttons = uigridlayout(root,[1 4],Padding=0,RowSpacing=0, ...
                ColumnSpacing=5,ColumnWidth={110,'1x',80,80},RowHeight={'fit'}, ...
                BackgroundColor=background);
            buttons.Layout.Row = 2;
            restore = uibutton(buttons,Text="Restore Defaults", ...
                BackgroundColor=controlColor,FontColor=controlFontColor, ...
                ButtonPushedFcn=@(~,~) restoreDefaults());
            restore.Layout.Column = 1;
            cancel = uibutton(buttons,Text="Cancel", ...
                BackgroundColor=controlColor,FontColor=controlFontColor, ...
                ButtonPushedFcn=@(~,~) closeDialog());
            cancel.Layout.Column = 3;
            apply = uibutton(buttons,Text="Apply", ...
                BackgroundColor=[.18 .42 .68],FontColor=[1 1 1], ...
                ButtonPushedFcn=@(~,~) applyChanges());
            apply.Layout.Column = 4;

            movegui(fig,"center");
            fig.Visible = "on";

            function [mode,minimum,maximum] = makeAxisItem(title,initialMode,limits)
                accordion.addItem(Title=title,BorderColor=[.49 .49 .49], ...
                    TitleBackgroundColor=background, ...
                    HoverTitleBackgroundColor=controlColor, ...
                    PaneBackgroundColor=paneColor,FontColor=fontColor, ...
                    BorderWidth=1,ExpandedBorderWidth=1,TitlePadding=1);
                item = accordion.getItem(title);
                item.expand();
                grid = item.Pane;
                set(grid,ColumnWidth={'fit','1x'}, ...
                    RowHeight={'fit','fit','fit'},Padding=[5 5 5 5], ...
                    ColumnSpacing=5,RowSpacing=5,BackgroundColor=paneColor);

                modeLabel = uilabel(grid,Text="Mode",FontColor=fontColor);
                modeLabel.Layout.Row = 1;
                modeLabel.Layout.Column = 1;
                mode = uidropdown(grid,Items={'Auto','Manual'}, ...
                    Value=obj.displayMode(initialMode), ...
                    BackgroundColor=controlColor,FontColor=controlFontColor);
                mode.Layout.Row = 1;
                mode.Layout.Column = 2;

                minimumLabel = uilabel(grid,Text="Minimum",FontColor=fontColor);
                minimumLabel.Layout.Row = 2;
                minimumLabel.Layout.Column = 1;
                minimum = uieditfield(grid,"numeric",Value=limits(1), ...
                    BackgroundColor=controlColor,FontColor=controlFontColor);
                minimum.Layout.Row = 2;
                minimum.Layout.Column = 2;
                maximumLabel = uilabel(grid,Text="Maximum",FontColor=fontColor);
                maximumLabel.Layout.Row = 3;
                maximumLabel.Layout.Column = 1;
                maximum = uieditfield(grid,"numeric",Value=limits(2), ...
                    BackgroundColor=controlColor,FontColor=controlFontColor);
                maximum.Layout.Row = 3;
                maximum.Layout.Column = 2;

                mode.ValueChangedFcn = @(~,~) updateLimitControls(mode,minimum,maximum);
                minimum.ValueChangedFcn = @(~,~) makeManual(mode,minimum,maximum);
                maximum.ValueChangedFcn = @(~,~) makeManual(mode,minimum,maximum);
                updateLimitControls(mode,minimum,maximum);
            end

            function updateLimitControls(mode,minimum,maximum)
                enabled = matlab.lang.OnOffSwitchState(string(mode.Value) == "Manual");
                minimum.Enable = enabled;
                maximum.Enable = enabled;
            end

            function makeManual(mode,minimum,maximum)
                mode.Value = 'Manual';
                updateLimitControls(mode,minimum,maximum);
            end

            function restoreDefaults()
                xMode.Value = 'Auto';
                yMode.Value = 'Auto';
                updateLimitControls(xMode,xMinimum,xMaximum);
                updateLimitControls(yMode,yMinimum,yMaximum);
            end

            function applyChanges()
                if string(xMode.Value) == "Manual" && xMinimum.Value >= xMaximum.Value
                    uialert(fig,"X maximum must be greater than X minimum.", ...
                        "Invalid X Limits");
                    return;
                end
                if string(yMode.Value) == "Manual" && yMinimum.Value >= yMaximum.Value
                    uialert(fig,"Y maximum must be greater than Y minimum.", ...
                        "Invalid Y Limits");
                    return;
                end

                updated = obj.Style;
                if string(xMode.Value) == "Auto"
                    updated.XLimMode = "auto";
                else
                    updated.XLim = [xMinimum.Value xMaximum.Value];
                end
                if string(yMode.Value) == "Auto"
                    updated.YLimMode = "auto";
                else
                    updated.YLim = [yMinimum.Value yMaximum.Value];
                end
                obj.setStyle(updated);
                closeDialog();
            end

            function closeDialog()
                if isgraphics(fig), delete(fig); end
                if isvalid(obj), obj.PropertiesDialog = []; end
            end
        end

        function delete(obj)
        %DELETE Release renderer-owned plot primitives and legend proxies.

            delete(obj.LegendPlots(isvalid(obj.LegendPlots)));
            delete(obj.Legend(isvalid(obj.Legend)));
            obj.detach();
            if isgraphics(obj.PropertiesDialog), delete(obj.PropertiesDialog); end
            delete(obj.Plots(isvalid(obj.Plots)));
        end

    end

    methods (Access=protected)

        function attachGraphics(obj,axes)
        %ATTACHGRAPHICS Move existing scatter primitives to the new stable axes.

            for k = 1:numel(obj.Plots)
                obj.Plots(k).Parent = axes;
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

        function limits = dialogLimits(obj,stored,dimension)
        %DIALOGLIMITS Return stored or currently rendered limits for editing.

            if ~isempty(stored)
                limits = stored;
            elseif ~isempty(obj.Host) && isvalid(obj.Host)
                limits = obj.Host.Axes.(dimension + "Lim");
            else
                limits = [0 1];
            end
        end

        function mode = displayMode(~,mode)
        %DISPLAYMODE Convert the style's lowercase mode to a dialog label.

            mode = upper(extractBefore(string(mode),2)) + ...
                extractAfter(string(mode),1);
        end

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

        function color = resolveColor(~,mode,custom,automatic)
        %RESOLVECOLOR Select a custom color or the series color-order value.
            if mode == "Custom"
                color = custom;
            else
                color = automatic;
            end
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
