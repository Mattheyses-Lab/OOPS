classdef Violin < handle
%VIOLIN One logical dataset backed by owned graphics primitives.
%
% Violin combines density-jittered points, a violin outline, and configurable
% summary graphics. ViolinRenderer normally owns these objects, although they may be
% created directly in a UIAxes:
%
%   group = matlabx.ui.axes.plot.Violin(ax, ...
%       XData=ones(1,100), YData=randn(1,100), CData=[0.2 0.5 0.8]);
%
% Use setData to update XData, YData, and CData together. Assign Parent to
% move the owned primitives without recreating them; Parent=[] detaches them.
% Replace the complete point data-tip template with a two-cell value:
%
%   group.DataTipCell = {{"Label","Value"},{labels,values}};
%
% Each value may be scalar or contain one entry per point. Assign {{},{}} to
% restore the low-level X/Y template. This does not change the separate
% central-statistic line template. Numeric point and summary rows share
% DataTipFormat, which defaults to two decimal places:
%
%   group.DataTipFormat = "%.3g";
%
% Replace the central-statistic line template independently:
%
%   group.SummaryDataTipCell = { ...
%       {"Group","Score"},{"Control",0.92}};
%
% Custom summary values are caller-owned and persist when plot data changes.
% Assign group.SummaryDataTipCell={{},{}} to restore the automatically
% generated group, sample count, center, interval, minimum, and maximum rows.
%
% See also matlabx.ui.axes.plot.ViolinRenderer,
% matlabx.ui.axes.plot.ViolinData, matlabx.ui.axes.plot.ViolinStyle

% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2023 William Dean
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

    % Point data, marker appearance, violin appearance, and summary graphics.
    properties(Dependent = true, AbortSet = true)
        % UIAxes containing the owned graphics, or empty while detached.
        Parent
        % X coordinates locating the group and its individual points.
        XData (1,:) double
        % Numeric observations aligned with XData.
        YData (1,:) double

        % Whether individual observation points are visible.
        PointsVisible (1,1) matlab.lang.OnOffSwitchState
        % Horizontal density-jitter width.
        XJitterWidth (1,1) double {mustBeInRange(XJitterWidth,0,1,"exclude-lower")}
        % MATLAB scatter jitter mode.
        XJitter (1,:) char {mustBeMember(XJitter,{'density','none'})}
        % Marker edge color accepted by the MATLAB scatter primitive.
        MarkerEdgeColor
        % Marker edge opacity.
        MarkerEdgeAlpha (1,1) double {mustBeInRange(MarkerEdgeAlpha,0,1)}
        % Marker edge line width.
        MarkerLineWidth (1,1) double {mustBePositive}
        % Marker area in points squared.
        MarkerSize
        % Marker face color mode accepted by the MATLAB scatter primitive.
        MarkerFaceColorMode
        % Marker face opacity.
        MarkerFaceAlpha (1,1) double {mustBeInRange(MarkerFaceAlpha,0,1)}
        % Scalar or RGB color data associated with the observations.
        CData

        % Two-cell {labels,values} replacement for all point data-tip rows.
        % Labels and values must have equal counts. Values may be scalar or
        % contain one entry per point. Assign {{},{}} to restore X and Y.
        DataTipCell (1,2) cell
        % Two-cell {labels,values} replacement for central-line summary rows.
        % Custom values persist across data changes and must be refreshed by
        % the caller. Assign {{},{}} to restore the generated statistics.
        SummaryDataTipCell (1,2) cell
        % sprintf-style format applied to numeric point and summary rows.
        DataTipFormat (1,1) string

        % Whether the violin density patch is visible.
        ViolinOutlinesVisible (1,1) matlab.lang.OnOffSwitchState
        % Violin patch edge line width.
        ViolinLineWidth (1,1) double
        % Violin patch face color.
        ViolinFaceColor (1,3) double
        % Violin patch edge color.
        ViolinEdgeColor (1,3) double
        % Violin patch edge opacity.
        ViolinEdgeAlpha (1,1) double {mustBeInRange(ViolinEdgeAlpha,0,1)}
        % Violin patch face opacity.
        ViolinFaceAlpha (1,1) double {mustBeInRange(ViolinFaceAlpha,0,1)}

        % Whether the central statistic and interval graphics are visible.
        ErrorBarsVisible (1,1) matlab.lang.OnOffSwitchState
        % Statistic shown by the central marker and middle bar.
        CentralStatistic (1,1) string
        % Spread or interval represented by the outer error bars.
        ErrorStatistic (1,1) string
        % Summary graphic line width.
        ErrorBarsLineWidth (1,1) double
        % Width of the interactive central-statistic line.
        CentralStatLineWidth (1,1) double
        % Central statistic and interval graphic color.
        ErrorBarsColor (1,3) double

        % Series name used by the central-statistic line data tip.
        Name (1,:) char

    end

    % Backing state not stored directly by one owned primitive.
    properties(Access=private,AbortSet=true)
        % Backing value for Name.
        user_Name (1,:) char = ''
        % Backing value for CentralStatistic.
        CentralStatistic_ (1,1) string = "mean"
        % Backing value for ErrorStatistic.
        ErrorStatistic_ (1,1) string = "std"
        % Caller-supplied summary data-tip template retained across refreshes.
        SummaryDataTipCell_ (1,2) cell = {{},{}}
        % Whether the caller-supplied summary template overrides generated rows.
        HasCustomSummaryDataTip (1,1) logical = false
        % Backing value for the numeric data-tip format.
        DataTipFormat_ (1,1) string = "%.2f"
    end

    % Derived geometry calculated from the current observations.
    properties(Access = private,Dependent = true)
        % Two-row X/Y coordinates forming the violin density outline.
        DensityData (2,:) double
    end

    % MATLAB graphics primitives owned and transferred as one logical group.
    properties(Access = private,Transient,NonCopyable)
        % Patch containing the violin density outline.
        violinOutlines (1,1) matlab.graphics.primitive.Patch
        % Scatter primitive containing individual observations.
        violinPoints (1,1) matlab.graphics.chart.primitive.Scatter
        % Patch containing the central and interval bars.
        errorBars (1,1) matlab.graphics.primitive.Patch
        % Pickable horizontal line identifying the selected central statistic.
        centralStatLine (1,1) matlab.graphics.chart.primitive.Line
        % Temporary point or summary data tip shown under the pointer.
        HoverDataTip = []
        % Primitive currently represented by HoverDataTip.
        HoverDataTipTarget = []
        % Normal central-line width saved while hover emphasis is active.
        CentralStatLineWidthBeforeHover = []
    end

    methods

        function obj = Violin(Parent,NameValuePairs)
        %VIOLIN Create one violin graphics group in the supplied axes.

            % input argument validation
            arguments
                Parent (1,1) matlab.ui.control.UIAxes
                NameValuePairs.XData (1,:) double = NaN
                NameValuePairs.YData (1,:) double = NaN
                NameValuePairs.XJitter (1,:) char {mustBeMember(NameValuePairs.XJitter,{'none','density'})} = 'density'
                NameValuePairs.XJitterWidth (1,1) double {mustBeInRange(NameValuePairs.XJitterWidth,0,1,"exclude-lower")} = 0.9
                NameValuePairs.DataTipCell (1,2) cell = {{},{}};
                NameValuePairs.DataTipFormat (1,1) string = "%.2f"

                NameValuePairs.MarkerEdgeColor = [0 0 0]
                NameValuePairs.MarkerEdgeAlpha (1,1) double {mustBeInRange(NameValuePairs.MarkerEdgeAlpha,0,1)} = 1
                NameValuePairs.MarkerLineWidth (1,1) double {mustBePositive} = 0.5
                NameValuePairs.MarkerSize = 50
                NameValuePairs.MarkerFaceColorMode = 'flat'
                NameValuePairs.CData = [0 0 0]
                NameValuePairs.PointsVisible (1,1) matlab.lang.OnOffSwitchState = "on"
                NameValuePairs.MarkerFaceAlpha (1,1) double {mustBeInRange(NameValuePairs.MarkerFaceAlpha,0,1)} = 0.5

                NameValuePairs.ViolinOutlinesVisible (1,1) matlab.lang.OnOffSwitchState = "on"
                NameValuePairs.ViolinLineWidth (1,1) double = 1
                NameValuePairs.ViolinFaceColor (1,3) double = [1 1 1]
                NameValuePairs.ViolinEdgeColor (1,3) double = [0 0 0]
                NameValuePairs.ViolinEdgeAlpha (1,1) double {mustBeInRange(NameValuePairs.ViolinEdgeAlpha,0,1)} = 1
                NameValuePairs.ViolinFaceAlpha (1,1) double {mustBeInRange(NameValuePairs.ViolinFaceAlpha,0,1)} = 0.5

                NameValuePairs.ErrorBarsVisible (1,1) matlab.lang.OnOffSwitchState = "on"
                NameValuePairs.CentralStatistic (1,1) string {mustBeMember(NameValuePairs.CentralStatistic,["mean","median"])} = "mean"
                NameValuePairs.ErrorStatistic (1,1) string {mustBeMember(NameValuePairs.ErrorStatistic,["std","sem","iqr"])} = "std"
                NameValuePairs.ErrorBarsLineWidth (1,1) double = 1
                NameValuePairs.CentralStatLineWidth (1,1) double = 1
                NameValuePairs.ErrorBarsColor (1,3) double = [0 0 0]

                NameValuePairs.Name (1,:) char = 'untitled';
            end

            % primitive patch to form the violin outlines
            obj.violinOutlines  = patch(Parent,...
                'XData',NaN,...
                'YData',NaN,...
                'HitTest','off',...
                'PickableParts','none');
            % Data setters update all four primitives. Construct them before
            % applying finite constructor data, not only the NaN placeholder.
            obj.violinPoints = matlab.graphics.chart.primitive.Scatter( ...
                'Parent',Parent,'XData',NaN,'YData',NaN);
            obj.errorBars = patch(Parent,'XData',NaN,'YData',NaN, ...
                'HitTest','off','PickableParts','none','Tag','ViolinErrorBars');
            obj.centralStatLine = matlab.graphics.chart.primitive.Line( ...
                'Parent',Parent,'XData',NaN,'YData',NaN, ...
                'HitTest','on','PickableParts','visible', ...
                'Tag','ViolinCentralStatistic');

            obj.ViolinOutlinesVisible = NameValuePairs.ViolinOutlinesVisible;
            obj.ViolinLineWidth = NameValuePairs.ViolinLineWidth;
            obj.ViolinFaceColor = NameValuePairs.ViolinFaceColor;
            obj.ViolinEdgeColor = NameValuePairs.ViolinEdgeColor;
            obj.ViolinEdgeAlpha = NameValuePairs.ViolinEdgeAlpha;
            obj.ViolinFaceAlpha = NameValuePairs.ViolinFaceAlpha;

            obj.PointsVisible = NameValuePairs.PointsVisible;
            obj.XJitter = NameValuePairs.XJitter;
            obj.XJitterWidth = NameValuePairs.XJitterWidth;

            obj.MarkerEdgeColor = NameValuePairs.MarkerEdgeColor;
            obj.MarkerEdgeAlpha = NameValuePairs.MarkerEdgeAlpha;
            obj.MarkerLineWidth = NameValuePairs.MarkerLineWidth;
            obj.MarkerSize = NameValuePairs.MarkerSize;
            obj.MarkerFaceColorMode = NameValuePairs.MarkerFaceColorMode;
            obj.MarkerFaceAlpha = NameValuePairs.MarkerFaceAlpha;
            obj.CentralStatistic = NameValuePairs.CentralStatistic;
            obj.ErrorStatistic = NameValuePairs.ErrorStatistic;
            obj.setData(NameValuePairs.XData,NameValuePairs.YData,NameValuePairs.CData);

            obj.DataTipFormat = NameValuePairs.DataTipFormat;
            obj.DataTipCell = NameValuePairs.DataTipCell;

            obj.ErrorBarsLineWidth = NameValuePairs.ErrorBarsLineWidth;
            obj.CentralStatLineWidth = NameValuePairs.CentralStatLineWidth;
            obj.ErrorBarsColor = NameValuePairs.ErrorBarsColor;

            % The error bars and their central statistic form one visual unit.
            % Apply visibility after both underlying primitives exist.
            obj.ErrorBarsVisible = NameValuePairs.ErrorBarsVisible;
            obj.Name = NameValuePairs.Name;
        end

        function delete(obj)
        %DELETE Delete every graphics primitive owned by this plot group.

            delete(obj.violinPoints);
            delete(obj.violinOutlines);
            delete(obj.errorBars);
            delete(obj.centralStatLine);

        end

        function setData(obj,xData,yData,cData)
        %SETDATA Apply coupled point coordinates and colors in one graphics update.
            if isvector(cData) && numel(cData) ~= 3
                cData = cData(:);
            end

            set(obj.violinPoints, ...
                'XData',xData, ...
                'YData',yData, ...
                'CData',cData);
            obj.updateViolinOutlines();
            obj.updateErrorBars();
        end

        function handled = handleEvent(obj,event)
        %HANDLEEVENT Preview data tips on hover and retain one on click.
            handled = false;
            pointsMatch = isequal(event.Target,obj.violinPoints) && ...
                ~isempty(obj.Parent);
            summaryMatches = isequal(event.Target,obj.centralStatLine);

            switch event.Kind
                case "Move"
                    if pointsMatch
                        obj.updatePointHoverDataTip();
                    elseif summaryMatches
                        obj.updateSummaryHoverDataTip();
                    else
                        obj.clearHoverDataTip();
                        return;
                    end
                    handled = true;

                case "Leave"
                    obj.clearHoverDataTip();

                case "Down"
                    obj.clearHoverDataTip();
                    if event.MouseAction ~= "click"
                        return;
                    elseif pointsMatch
                        point = obj.Parent.CurrentPoint;
                        datatip(obj.violinPoints,point(1,1),point(1,2));
                    elseif summaryMatches
                        datatip(obj.centralStatLine,DataIndex=2);
                    else
                        return;
                    end
                    event.markHandled();
                    handled = true;
            end
        end

    end

    methods (Access=private)

        function updatePointHoverDataTip(obj)
        %UPDATEPOINTHOVERDATATIP Replace the preview only when its point changes.
            point = obj.Parent.CurrentPoint;
            candidate = datatip(obj.violinPoints,point(1,1),point(1,2));

            if isequal(obj.HoverDataTipTarget,obj.violinPoints) && ...
                    obj.sameDataIndex(candidate,obj.HoverDataTip)
                delete(candidate);
                return;
            end

            obj.replaceHoverDataTip(candidate,obj.violinPoints);
        end

        function updateSummaryHoverDataTip(obj)
        %UPDATESUMMARYHOVERDATATIP Keep one preview for the same summary marker.
            obj.emphasizeCentralStatLine();
            if isequal(obj.HoverDataTipTarget,obj.centralStatLine) && ...
                    ~isempty(obj.HoverDataTip) && isgraphics(obj.HoverDataTip)
                return;
            end
            candidate = datatip(obj.centralStatLine,DataIndex=2);
            obj.replaceHoverDataTip(candidate,obj.centralStatLine);
        end

        function replaceHoverDataTip(obj,candidate,target)
        %REPLACEHOVERDATATIP Install a new preview before removing the old one.
            previous = obj.HoverDataTip;
            obj.HoverDataTip = candidate;
            obj.HoverDataTipTarget = target;
            obj.disableHoverTipHitTesting();
            if ~isempty(previous) && isgraphics(previous)
                delete(previous);
            end
        end

        function clearHoverDataTip(obj)
        %CLEARHOVERDATATIP Delete only the temporary pointer-following tip.
            if ~isempty(obj.HoverDataTip) && isgraphics(obj.HoverDataTip)
                delete(obj.HoverDataTip);
            end
            obj.HoverDataTip = [];
            obj.HoverDataTipTarget = [];
            obj.restoreCentralStatLineWidth();
        end

        function disableHoverTipHitTesting(obj)
        %DISABLEHOVERTIPHITTESTING Keep the tip from obscuring its plot target.
            % Data-tip implementation details vary by MATLAB release, so these
            % presentation-only assignments remain guarded.
            try
                obj.HoverDataTip.HitTest = "off";
            catch
            end
            try
                obj.HoverDataTip.PickableParts = "none";
            catch
            end
        end

        function tf = sameDataIndex(~,first,second)
        %SAMEDATAINDEX Compare two valid data tips without assuming internals.
            tf = false;
            if isempty(first) || isempty(second) || ...
                    ~isgraphics(first) || ~isgraphics(second)
                return;
            end
            try
                tf = isequal(first.DataIndex,second.DataIndex);
            catch
            end
        end

        function row = createDataTipRow(obj,label,value)
        %CREATEDATATIPROW Format numeric values and preserve text defaults.
            if isnumeric(value)
                row = dataTipTextRow(label,value,obj.DataTipFormat_);
            else
                row = dataTipTextRow(label,value);
            end
        end

        function row = createSummaryDataTipRow(obj,label,value)
        %CREATESUMMARYDATATIPROW Align values with left, center, and right vertices.
            if ischar(value)
                value = repmat(string(value),1,3);
            elseif isscalar(value) && (isnumeric(value) || islogical(value) || ...
                    isstring(value) || iscell(value) || ...
                    iscategorical(value) || isdatetime(value) || isduration(value))
                value = repmat(value,1,3);
            end
            row = obj.createDataTipRow(label,value);
        end

        function emphasizeCentralStatLine(obj)
        %EMPHASIZECENTRALSTATLINE Thicken the summary line during hover.
            if isempty(obj.CentralStatLineWidthBeforeHover)
                obj.CentralStatLineWidthBeforeHover = obj.centralStatLine.LineWidth;
                obj.centralStatLine.LineWidth = ...
                    obj.CentralStatLineWidthBeforeHover + 1;
            end
        end

        function restoreCentralStatLineWidth(obj)
        %RESTORECENTRALSTATLINEWIDTH Restore the line width saved on entry.
            if isempty(obj.CentralStatLineWidthBeforeHover)
                return;
            end
            if isgraphics(obj.centralStatLine)
                obj.centralStatLine.LineWidth = ...
                    obj.CentralStatLineWidthBeforeHover;
            end
            obj.CentralStatLineWidthBeforeHover = [];
        end

        function replacePointDataTipRows(obj,val)
        %REPLACEPOINTDATATIPROWS Rebuild point rows with the current format.
            dtNames = val{1};
            dtData = val{2};
            obj.validateDataTipCell(val,"DataTipCell");

            rows = obj.violinPoints.DataTipTemplate.DataTipRows;
            for i = 1:numel(dtNames)
                rows(i) = obj.createDataTipRow(dtNames{i},dtData{i});
            end
            for i = numel(rows):-1:numel(dtNames)+1
                rows(i) = [];
            end
            obj.violinPoints.DataTipTemplate.DataTipRows = rows;
        end

    end


    %% Set and Get methods for public properties controlling violin points appearance
    methods
        %% Parent

        function set.Parent(obj,parent)
        %SET.PARENT Move all violin primitives to another UIAxes.

            if ~isempty(parent)
                validateattributes(parent,{'matlab.ui.control.UIAxes'},{'scalar'});
            end

            obj.violinOutlines.Parent = parent;
            obj.violinPoints.Parent = parent;
            obj.errorBars.Parent = parent;
            obj.centralStatLine.Parent = parent;
        end

        function parent = get.Parent(obj)
        %GET.PARENT Return the UIAxes containing the owned graphics.

            parent = obj.violinPoints.Parent;
        end

        %% PointsVisible

        function set.PointsVisible(obj,val)
        %SET.POINTSVISIBLE Set the PointsVisible value on the owned graphics.
            obj.violinPoints.Visible = val;
        end

        function PointsVisible = get.PointsVisible(obj)
        %GET.POINTSVISIBLE Return the current PointsVisible value from the owned graphics.
            PointsVisible = obj.violinPoints.Visible;
        end

        %% XData

        function set.XData(obj,val)
        %SET.XDATA Set the XData value on the owned graphics.
            % set XData of the violinPoints scatter
            obj.violinPoints.XData = val;
            % update violinOutlines patch
            obj.updateViolinOutlines();
            % update error bars line
            obj.updateErrorBars();
        end

        function XData = get.XData(obj)
        %GET.XDATA Return the current XData value from the owned graphics.
            XData = obj.violinPoints.XData;
        end

        %% YData

        function set.YData(obj,val)
        %SET.YDATA Set the YData value on the owned graphics.
            % set YData of the violinPoints scatter
            obj.violinPoints.YData = val;
            % update violinOutlines patch
            obj.updateViolinOutlines();
            % update error bars line
            obj.updateErrorBars();
        end

        function YData = get.YData(obj)
        %GET.YDATA Return the current YData value from the owned graphics.
            YData = obj.violinPoints.YData;
        end

        %% XJitter

        function set.XJitter(obj,val)
        %SET.XJITTER Set the XJitter value on the owned graphics.
            obj.violinPoints.XJitter = val;
        end

        function XJitter = get.XJitter(obj)
        %GET.XJITTER Return the current XJitter value from the owned graphics.
            XJitter = obj.violinPoints.XJitter;
        end

        %% XJitterWidth

        function set.XJitterWidth(obj,val)
        %SET.XJITTERWIDTH Set the XJitterWidth value on the owned graphics.
            % set XJitterWidth of the violinPoints scatter
            obj.violinPoints.XJitterWidth = val;
            % update violinOutlines patch
            obj.updateViolinOutlines();
            % update error bars line
            obj.updateErrorBars();
        end

        function XJitterWidth = get.XJitterWidth(obj)
        %GET.XJITTERWIDTH Return the current XJitterWidth value from the owned graphics.
            XJitterWidth = obj.violinPoints.XJitterWidth;
        end

        %% MarkerEdgeColor

        function set.MarkerEdgeColor(obj,val)
        %SET.MARKEREDGECOLOR Set the MarkerEdgeColor value on the owned graphics.
            obj.violinPoints.MarkerEdgeColor = val;
        end

        function MarkerEdgeColor = get.MarkerEdgeColor(obj)
        %GET.MARKEREDGECOLOR Return the current MarkerEdgeColor value from the owned graphics.
            MarkerEdgeColor = obj.violinPoints.MarkerEdgeColor;
        end

        %% MarkerEdgeAlpha

        function set.MarkerEdgeAlpha(obj,val)
        %SET.MARKEREDGEALPHA Set the marker edge opacity.
            obj.violinPoints.MarkerEdgeAlpha = val;
        end

        function val = get.MarkerEdgeAlpha(obj)
        %GET.MARKEREDGEALPHA Return the marker edge opacity.
            val = obj.violinPoints.MarkerEdgeAlpha;
        end

        %% MarkerLineWidth

        function set.MarkerLineWidth(obj,val)
        %SET.MARKERLINEWIDTH Set the marker edge line width.
            obj.violinPoints.LineWidth = val;
        end

        function val = get.MarkerLineWidth(obj)
        %GET.MARKERLINEWIDTH Return the marker edge line width.
            val = obj.violinPoints.LineWidth;
        end

        %% MarkerSize

        function set.MarkerSize(obj,val)
        %SET.MARKERSIZE Set the MarkerSize value on the owned graphics.
            obj.violinPoints.SizeData = val;
        end

        function MarkerSize = get.MarkerSize(obj)
        %GET.MARKERSIZE Return the current MarkerSize value from the owned graphics.
            MarkerSize = obj.violinPoints.SizeData;
        end

        %% MarkerFaceColorMode

        function set.MarkerFaceColorMode(obj,val)
        %SET.MARKERFACECOLORMODE Set the MarkerFaceColorMode value on the owned graphics.
            obj.violinPoints.MarkerFaceColor = val;
        end

        function MarkerFaceColorMode = get.MarkerFaceColorMode(obj)
        %GET.MARKERFACECOLORMODE Return the current MarkerFaceColorMode value from the owned graphics.
            MarkerFaceColorMode = obj.violinPoints.MarkerFaceColor;
        end

        %% MarkerFaceAlpha

        function set.MarkerFaceAlpha(obj,val)
        %SET.MARKERFACEALPHA Set the MarkerFaceAlpha value on the owned graphics.
            obj.violinPoints.MarkerFaceAlpha = val;
        end

        function MarkerFaceAlpha = get.MarkerFaceAlpha(obj)
        %GET.MARKERFACEALPHA Return the current MarkerFaceAlpha value from the owned graphics.
            MarkerFaceAlpha = obj.violinPoints.MarkerFaceAlpha;
        end

        %% CData

        function set.CData(obj,val)
        %SET.CDATA Set the CData value on the owned graphics.
            % Data contracts use row vectors; MATLAB scalar color data uses
            % one row per point. A triplet retains its RGB interpretation.
            if isvector(val) && numel(val) ~= 3
                val = val(:);
            end

            obj.violinPoints.CData = val;
        end

        function CData = get.CData(obj)
        %GET.CDATA Return the current CData value from the owned graphics.
            CData = obj.violinPoints.CData;
        end

        %% DataTipCell

        function set.DataTipCell(obj,val)
        %SET.DATATIPCELL Replace every point data-tip row, or restore X/Y.
            if any(cellfun(@(x) isempty(x),val))
                val = {{"X","Y"},{obj.XData,obj.YData}};
            end

            obj.replacePointDataTipRows(val);
        end

        function DataTipCell = get.DataTipCell(obj)
        %GET.DATATIPCELL Return the current DataTipCell value from the owned graphics.
            % array of datatip rows for this violin
            dtRows = obj.violinPoints.DataTipTemplate.DataTipRows;
            % names and values for each datatip
            dtNames = arrayfun(@(x) x.Label,dtRows','UniformOutput',false);
            dtData = arrayfun(@(x) x.Value,dtRows','UniformOutput',false);
            % cell array of cell arrays with datatip info in violinPoints
            DataTipCell = {dtNames,dtData};
        end

        %% DataTipFormat

        function set.DataTipFormat(obj,val)
        %SET.DATATIPFORMAT Apply one format to numeric point and summary rows.
            obj.DataTipFormat_ = val;
            obj.replacePointDataTipRows(obj.DataTipCell);
            obj.updateErrorBars();
        end

        function val = get.DataTipFormat(obj)
        %GET.DATATIPFORMAT Return the numeric data-tip format.
            val = obj.DataTipFormat_;
        end

        %% SummaryDataTipCell

        function set.SummaryDataTipCell(obj,val)
        %SET.SUMMARYDATATIPCELL Replace summary rows, or restore generated statistics.
        %   Values in a custom template are caller-owned and are not
        %   recalculated when XData, YData, or summary modes change.
            if any(cellfun(@(x) isempty(x),val))
                obj.SummaryDataTipCell_ = {{},{}};
                obj.HasCustomSummaryDataTip = false;
                obj.updateErrorBars();
                return;
            end

            obj.validateDataTipCell(val,"SummaryDataTipCell");
            obj.SummaryDataTipCell_ = val;
            obj.HasCustomSummaryDataTip = true;
            obj.replaceSummaryDataTipRows(val);
        end

        function val = get.SummaryDataTipCell(obj)
        %GET.SUMMARYDATATIPCELL Return the active summary-marker template.
            rows = obj.centralStatLine.DataTipTemplate.DataTipRows;
            names = arrayfun(@(row) row.Label,rows','UniformOutput',false);
            values = arrayfun(@(row) row.Value,rows','UniformOutput',false);
            val = {names,values};
        end

        %% name

        function set.Name(obj,val)
        %SET.NAME Set the Name value on the owned graphics.
            obj.user_Name = val;
            % update error bars
            obj.updateErrorBars();
        end

        function Name = get.Name(obj)
        %GET.NAME Return the current Name value from the owned graphics.
            Name = obj.user_Name;
        end

    end

    %% Set and Get methods for public properties controlling violin outlines appearance
    methods
        %% ViolinOutlinesVisible

        function set.ViolinOutlinesVisible(obj,val)
        %SET.VIOLINOUTLINESVISIBLE Set the ViolinOutlinesVisible value on the owned graphics.
            obj.violinOutlines.Visible = val;
        end

        function ViolinOutlinesVisible = get.ViolinOutlinesVisible(obj)
        %GET.VIOLINOUTLINESVISIBLE Return the current ViolinOutlinesVisible value from the owned graphics.
            ViolinOutlinesVisible = obj.violinOutlines.Visible;
        end

        %% ViolinLineWidth

        function set.ViolinLineWidth(obj,val)
        %SET.VIOLINLINEWIDTH Set the ViolinLineWidth value on the owned graphics.
            obj.violinOutlines.LineWidth = val;
        end

        function ViolinLineWidth = get.ViolinLineWidth(obj)
        %GET.VIOLINLINEWIDTH Return the current ViolinLineWidth value from the owned graphics.
            ViolinLineWidth = obj.violinOutlines.LineWidth;
        end

        %% ViolinFaceColor

        function set.ViolinFaceColor(obj,val)
        %SET.VIOLINFACECOLOR Set the ViolinFaceColor value on the owned graphics.
            obj.violinOutlines.FaceColor = val;
        end

        function ViolinFaceColor = get.ViolinFaceColor(obj)
        %GET.VIOLINFACECOLOR Return the current ViolinFaceColor value from the owned graphics.
            ViolinFaceColor = obj.violinOutlines.FaceColor;
        end

        %% ViolinEdgeColor

        function set.ViolinEdgeColor(obj,val)
        %SET.VIOLINEDGECOLOR Set the ViolinEdgeColor value on the owned graphics.
            obj.violinOutlines.EdgeColor = val;
        end

        function ViolinEdgeColor = get.ViolinEdgeColor(obj)
        %GET.VIOLINEDGECOLOR Return the current ViolinEdgeColor value from the owned graphics.
            ViolinEdgeColor = obj.violinOutlines.EdgeColor;
        end

        %% ViolinEdgeAlpha

        function set.ViolinEdgeAlpha(obj,val)
        %SET.VIOLINEDGEALPHA Set the violin edge opacity.
            obj.violinOutlines.EdgeAlpha = val;
        end

        function val = get.ViolinEdgeAlpha(obj)
        %GET.VIOLINEDGEALPHA Return the violin edge opacity.
            val = obj.violinOutlines.EdgeAlpha;
        end

        %% ViolinFaceAlpha

        function set.ViolinFaceAlpha(obj,val)
        %SET.VIOLINFACEALPHA Set the ViolinFaceAlpha value on the owned graphics.
            obj.violinOutlines.FaceAlpha = val;
        end

        function ViolinFaceAlpha = get.ViolinFaceAlpha(obj)
        %GET.VIOLINFACEALPHA Return the current ViolinFaceAlpha value from the owned graphics.
            ViolinFaceAlpha = obj.violinOutlines.FaceAlpha;
        end

    end

    %% Set and Get methods for public properties controlling violin error bars appearance
    methods
        %% CentralStatistic

        function set.CentralStatistic(obj,val)
        %SET.CENTRALSTATISTIC Select the statistic shown at the distribution center.
            mustBeMember(val,["mean","median"]);
            obj.CentralStatistic_ = val;
            obj.updateErrorBars();
        end

        function val = get.CentralStatistic(obj)
        %GET.CENTRALSTATISTIC Return the selected central statistic.
            val = obj.CentralStatistic_;
        end

        %% ErrorStatistic

        function set.ErrorStatistic(obj,val)
        %SET.ERRORSTATISTIC Select the spread or interval shown by the error bars.
            mustBeMember(val,["std","sem","iqr"]);
            obj.ErrorStatistic_ = val;
            obj.updateErrorBars();
        end

        function val = get.ErrorStatistic(obj)
        %GET.ERRORSTATISTIC Return the selected error statistic.
            val = obj.ErrorStatistic_;
        end

        %% ErrorBarsVisible

        function set.ErrorBarsVisible(obj,val)
        %SET.ERRORBARSVISIBLE Set the ErrorBarsVisible value on the owned graphics.
            obj.errorBars.Visible = val;
            obj.centralStatLine.Visible = val;
        end

        function ErrorBarsVisible = get.ErrorBarsVisible(obj)
        %GET.ERRORBARSVISIBLE Return the current ErrorBarsVisible value from the owned graphics.
            ErrorBarsVisible = obj.errorBars.Visible;
        end

        %% ErrorBarsLineWidth

        function set.ErrorBarsLineWidth(obj,val)
        %SET.ERRORBARSLINEWIDTH Set the ErrorBarsLineWidth value on the owned graphics.
            obj.errorBars.LineWidth = val;
        end

        function ErrorBarsLineWidth = get.ErrorBarsLineWidth(obj)
        %GET.ERRORBARSLINEWIDTH Return the ErrorBarsLineWidth value from the owned graphics.
            ErrorBarsLineWidth = obj.errorBars.LineWidth;
        end

        %% CentralStatLineWidth

        function set.CentralStatLineWidth(obj,val)
        %SET.CENTRALSTATLINEWIDTH Set the normal central-statistic line width.
            if isempty(obj.CentralStatLineWidthBeforeHover)
                obj.centralStatLine.LineWidth = val;
            else
                obj.CentralStatLineWidthBeforeHover = val;
                obj.centralStatLine.LineWidth = val + 1;
            end
        end

        function val = get.CentralStatLineWidth(obj)
        %GET.CENTRALSTATLINEWIDTH Return the normal central-statistic width.
            if isempty(obj.CentralStatLineWidthBeforeHover)
                val = obj.centralStatLine.LineWidth;
            else
                val = obj.CentralStatLineWidthBeforeHover;
            end
        end

        %% ErrorBarsColor

        function set.ErrorBarsColor(obj,val)
        %SET.ERRORBARSCOLOR Set the ErrorBarsColor value on the owned graphics.
            obj.errorBars.EdgeColor = val;
            obj.centralStatLine.Color = val;
        end

        function ErrorBarsColor = get.ErrorBarsColor(obj)
        %GET.ERRORBARSCOLOR Return the current ErrorBarsColor value from the owned graphics.
            ErrorBarsColor = obj.errorBars.EdgeColor;
        end


    end

    % density methods
    methods

        function DensityData = get.DensityData(obj)
        %GET.DENSITYDATA Return the current DensityData value from the owned graphics.

            if isempty(obj.XData) || any(~isfinite(obj.YData)) || numel(obj.YData) < 2
                DensityData = [NaN;NaN];
                return
            end

            % get the density data with ksdensity, xDensity = horizontal spread, yDensity = y locations to evaluate xDensity
            [xDensity,yDensity] = ksdensity(obj.YData);

            densityIdxsInDataRange = yDensity >= min(obj.YData) & yDensity <= max(obj.YData);

            xDensity = xDensity(densityIdxsInDataRange);
            yDensity = yDensity(densityIdxsInDataRange);

            % check if empty (happens when all data points have the same value)
            if isempty(xDensity) || isempty(yDensity)
                DensityData = [NaN;NaN];
                return
            end

            % make sure first and last values are min and max, respectively
            yDensity(1) = min(obj.YData);
            yDensity(end) = max(obj.YData);

            % add flanking points in case we only have one data point
            yDensity = [yDensity(1)*(1-1E-5), yDensity, yDensity(end)*(1+1E-5)];
            xDensity = [0, xDensity, 0];

            % rescale the density data to match the x jitter width of the scatter points
            xDensity = rescale(xDensity,min(xDensity),obj.XJitterWidth/2);
            % get the x position of the violin on its axes
            xPosition = obj.XData(1);
            % concatenate with flipped copy to form both sides of the violin
            xDensity = [xPosition+xDensity,xPosition-fliplr(xDensity)];
            yDensity = [yDensity,fliplr(yDensity)];

            % % concatenate along first dimension to form the final output
            DensityData = [xDensity;yDensity];

        end

    end

    % private, hidden methods for various internal purposes
    methods (Access = private,Hidden = true)

        function updateViolinOutlines(obj)
        %UPDATEVIOLINOUTLINES Recompute the violin outline from the current distribution.
            % set X and YData of the violinOutlines patch
            densityData = obj.DensityData;
            set(obj.violinOutlines,'XData',densityData(1,:),'YData',densityData(2,:));
        end

        function updateErrorBars(obj)
        %UPDATEERRORBARS Recompute the selected center and interval graphics.

            % get the data for this group
            groupData = obj.YData;

            if isempty(groupData) || isempty(obj.XData)
                % An emptied group must not retain the previous summary graphics.
                set(obj.errorBars,'XData',NaN,'YData',NaN);
                set(obj.centralStatLine,'XData',NaN,'YData',NaN);
                return
            end

            % get the x position of the violin on its axes
            xPosition = obj.XData(1);
            % get the halved jitter width
            xJitter = 0.5*obj.XJitterWidth;
            % width of the major (middle) bar
            majorWidth = 0.75*xJitter;
            % width of the minor (upper and lower) bars
            minorWidth = 0.25*xJitter;

            % the name of this violin
            groupName = obj.Name;

            % Calculate the selected center and interval. Standard deviation
            % and SEM are symmetric around the selected center; IQR uses the
            % distribution's first and third quartiles directly.
            groupN = numel(groupData);
            groupMax = max(groupData);
            groupMin = min(groupData);

            switch obj.CentralStatistic
                case "mean"
                    center = mean(groupData);
                    centerLabel = "Mean";
                case "median"
                    center = median(groupData);
                    centerLabel = "Median";
            end

            switch obj.ErrorStatistic
                case "std"
                    errorValue = std(groupData);
                    lower = center-errorValue;
                    upper = center+errorValue;
                    intervalRows = obj.createSummaryDataTipRow("SD",errorValue);
                case "sem"
                    errorValue = std(groupData)/sqrt(groupN);
                    lower = center-errorValue;
                    upper = center+errorValue;
                    intervalRows = obj.createSummaryDataTipRow("SEM",errorValue);
                case "iqr"
                    bounds = prctile(groupData,[25 75]);
                    lower = bounds(1);
                    upper = bounds(2);
                    intervalRows = [obj.createSummaryDataTipRow("Q1",lower); ...
                        obj.createSummaryDataTipRow("Q3",upper)];
            end

            % calculate X and YData for each line of the error bar, separate by NaNs
            errorXData = [...
                xPosition-minorWidth, xPosition+minorWidth;...
                NaN, NaN;...
                xPosition-minorWidth, xPosition+minorWidth;...
                NaN, NaN;...
                xPosition, xPosition];

            errorYData = [...
                upper, upper;...
                NaN, NaN;...
                lower, lower;...
                NaN, NaN;...
                upper, lower];

            % set X and YData of the error bar line object
            set(obj.errorBars,'XData',errorXData','YData',errorYData');

            % The center bar is its own pickable line and owns summary tips.
            set(obj.centralStatLine,...
                'XData',[xPosition-majorWidth,xPosition,xPosition+majorWidth],...
                'YData',[center,center,center], ...
                'HitTest','on', ...
                'PickableParts','visible');

            % Add summary rows to the pickable central-statistic line.
            obj.centralStatLine.DataTipTemplate.DataTipRows = [ ...
                obj.createSummaryDataTipRow("Series",categorical({groupName})); ...
                dataTipTextRow("n",repmat(groupN,1,3),"%d"); ...
                obj.createSummaryDataTipRow(centerLabel,center); ...
                intervalRows; ...
                obj.createSummaryDataTipRow("Max",groupMax); ...
                obj.createSummaryDataTipRow("Min",groupMin)];

            if obj.HasCustomSummaryDataTip
                obj.replaceSummaryDataTipRows(obj.SummaryDataTipCell_);
            end

        end

        function replaceSummaryDataTipRows(obj,val)
        %REPLACESUMMARYDATATIPROWS Replace every central-line data-tip row.
            obj.validateDataTipCell(val,"SummaryDataTipCell");
            names = val{1};
            values = val{2};
            rows = obj.centralStatLine.DataTipTemplate.DataTipRows;
            for i = 1:numel(names)
                rows(i) = obj.createSummaryDataTipRow(names{i},values{i});
            end
            for i = numel(rows):-1:numel(names)+1
                rows(i) = [];
            end
            obj.centralStatLine.DataTipTemplate.DataTipRows = rows;
        end

        function validateDataTipCell(~,val,propertyName)
        %VALIDATEDATATIPCELL Require paired, nonempty row labels and values.
            if numel(val{1}) ~= numel(val{2}) || isempty(val{1})
                error('matlabx:ui:axes:plot:InvalidDataTipCell', ...
                    '%s labels and values must have equal, nonzero counts.', ...
                    propertyName);
            end
        end

    end

end
