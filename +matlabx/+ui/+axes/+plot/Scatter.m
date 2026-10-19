classdef Scatter < handle & matlab.mixin.SetGet
%SCATTER One logical dataset backed by owned graphics primitives.
%
% Scatter combines a MATLAB scatter primitive with an optional convex or
% concave hull patch. ScatterRenderer normally owns these objects, although
% they may also be created directly in a UIAxes:
%
%   group = matlabx.ui.axes.plot.Scatter(ax, ...
%       XData=[1 2 3], YData=[2 1 4], CData=[0.2 0.5 0.8]);
%
% Use setData to update XData, YData, and CData together. Assign Parent to
% move the owned primitives without recreating them; Parent=[] detaches them.
% Replace the complete point data-tip template with a two-cell value:
%
%   group.DataTipCell = {{"Label","Value"},{labels,values}, ...
%       {"","%.2f"}};
%
% The optional third cell supplies one format per row; empty formats use
% DataTipFormat. Each value may be scalar or contain one entry per point.
% Assign {{},{}} to
% restore the low-level X/Y template. Numeric rows use DataTipFormat, which
% defaults to two decimal places and may be changed independently:
%
%   group.DataTipFormat = "%.3g";
%
% See also matlabx.ui.axes.plot.ScatterRenderer,
% matlabx.ui.axes.plot.ScatterData, matlabx.ui.axes.plot.ScatterStyle

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

    %% Scatter properties

    % Point data, marker appearance, data tips, and series identity.
    properties(Dependent = true, AbortSet = true)
        % UIAxes containing the owned graphics, or empty while detached.
        Parent
        % X coordinates of the scatter points.
        XData (1,:) double
        % Y coordinates aligned with XData.
        YData (1,:) double
        % Whether the scatter points are visible.
        PointsVisible (1,1) matlab.lang.OnOffSwitchState
        % Marker edge color accepted by the MATLAB scatter primitive.
        MarkerEdgeColor
        % Marker edge opacity.
        MarkerEdgeAlpha (1,1) double {mustBeBetween(MarkerEdgeAlpha,0,1)}
        % Marker edge line width.
        MarkerLineWidth (1,1) double {mustBePositive}
        % Marker area in points squared.
        MarkerSize
        % Marker face color or MATLAB color mode such as "flat".
        MarkerFaceColor
        % Marker face opacity.
        MarkerFaceAlpha (1,1) double {mustBeBetween(MarkerFaceAlpha,0,1)}
        % Marker symbol used for this series.
        Marker (:,1) char {mustBeMember(Marker,{'o','s','^','h','p','d','v','>','<'})}
        % Scalar or RGB color data associated with the scatter points.
        CData
        % Two-cell {labels,values} replacement for all point data-tip rows.
        % Labels and values must have equal counts. Values may be scalar or
        % contain one entry per point. Assign {{},{}} to restore X and Y.
        DataTipCell (1,:) cell
        % sprintf-style format applied to numeric data-tip rows.
        DataTipFormat (1,1) string
        % Series name stored in the scatter DisplayName.
        Name (1,:) char
    end

    %% Hull properties

    % Appearance and construction mode for the optional group hull.
    properties(Dependent = true, AbortSet = true)
        % Whether the hull patch is visible.
        HullVisible (1,1) matlab.lang.OnOffSwitchState
        % Hull edge line width.
        HullLineWidth (1,1) double
        % Hull patch face color.
        HullFaceColor (1,3) double
        % Hull patch edge color.
        HullEdgeColor (1,3) double
        % Hull face opacity.
        HullFaceAlpha (1,1) double {mustBeBetween(HullFaceAlpha,0,1)}
        % Hull edge opacity.
        HullEdgeAlpha (1,1) double {mustBeBetween(HullEdgeAlpha,0,1)}
        % Convex or concave boundary algorithm used for the hull.
        HullType (1,:) char {mustBeMember(HullType,{'convex','concave'})}
    end

    % Backing state for hull properties not stored directly by the patch.
    properties(Access = private)
        % Backing value for HullType.
        HullType_ (1,:) char {mustBeMember(HullType_,{'convex','concave'})} = 'concave'
        % Backing value for the numeric data-tip format.
        DataTipFormat_ (1,1) string = "%.2f"
        % Original two- or three-entry point template, including row formats.
        DataTipCell_ (1,:) cell = cell(1,0)
    end

    %% Graphics objects

    % MATLAB graphics primitives owned and transferred as one logical group.
    properties(Access = private,Transient,NonCopyable)
        % Scatter primitive containing the point graphics.
        scatterPoints (1,1) matlab.graphics.chart.primitive.Scatter
        % Patch primitive containing the optional hull.
        Hull (1,1) matlab.graphics.primitive.Patch
        % Temporary data tip shown only while the pointer hovers over a point.
        HoverDataTip = []
    end

    methods

        function obj = Scatter(Parent,NameValuePairs)
        %SCATTER Create one scatter graphics group in the supplied axes.

            % input argument validation
            arguments
                % parent axes
                Parent (1,1) matlab.ui.control.UIAxes
                % scatter properties
                NameValuePairs.XData (1,:) double = NaN
                NameValuePairs.YData (1,:) double = NaN
                NameValuePairs.DataTipCell (1,:) cell = {{},{}};
                NameValuePairs.DataTipFormat (1,1) string = "%.2f"
                NameValuePairs.MarkerFaceColor = 'flat'
                NameValuePairs.MarkerFaceAlpha (1,1) double {mustBeBetween(NameValuePairs.MarkerFaceAlpha,0,1)} = 0.5
                NameValuePairs.MarkerEdgeColor = [0 0 0]
                NameValuePairs.MarkerEdgeAlpha (1,1) double {mustBeBetween(NameValuePairs.MarkerEdgeAlpha,0,1)} = 1
                NameValuePairs.MarkerLineWidth (1,1) double {mustBePositive} = 0.5
                NameValuePairs.MarkerSize = 50
                NameValuePairs.Marker (:,1) char {mustBeMember(NameValuePairs.Marker,{'o','s','^','h','p','d','v','>','<'})} = 'o'
                NameValuePairs.CData = [0 0 0]
                NameValuePairs.PointsVisible (1,1) matlab.lang.OnOffSwitchState = "on"
                % data name
                NameValuePairs.Name (1,:) char = 'untitled';
                % hull properties
                NameValuePairs.HullVisible (1,1) matlab.lang.OnOffSwitchState = "on"
                NameValuePairs.HullLineWidth (1,1) double = 1
                NameValuePairs.HullFaceColor (1,3) double = [1 1 1]
                NameValuePairs.HullEdgeColor (1,3) double = [0 0 0]
                NameValuePairs.HullFaceAlpha (1,1) double {mustBeBetween(NameValuePairs.HullFaceAlpha,0,1)} = 0.5
                NameValuePairs.HullEdgeAlpha (1,1) double {mustBeBetween(NameValuePairs.HullEdgeAlpha,0,1)} = 1
                NameValuePairs.HullType (1,:) char {mustBeMember(NameValuePairs.HullType,{'convex','concave'})} = 'concave'
            end

            % primitive patch to form the convex hull
            obj.Hull = patch(Parent,...
                'XData',NaN,...
                'YData',NaN,...
                'HitTest','off',...
                'PickableParts','none');

            % Create both primitives before setters inspect the paired data.
            obj.scatterPoints = matlab.graphics.chart.primitive.Scatter( ...
                'Parent',Parent,'XData',NaN,'YData',NaN);

            % convex hull properties
            obj.HullVisible = NameValuePairs.HullVisible;
            obj.HullLineWidth = NameValuePairs.HullLineWidth;
            obj.HullFaceColor = NameValuePairs.HullFaceColor;
            obj.HullFaceAlpha = NameValuePairs.HullFaceAlpha;
            obj.HullEdgeColor = NameValuePairs.HullEdgeColor;
            obj.HullEdgeAlpha = NameValuePairs.HullEdgeAlpha;


            % scatter properties
            obj.PointsVisible = NameValuePairs.PointsVisible;
            obj.MarkerFaceColor = NameValuePairs.MarkerFaceColor;
            obj.MarkerFaceAlpha = NameValuePairs.MarkerFaceAlpha;
            obj.MarkerEdgeColor = NameValuePairs.MarkerEdgeColor;
            obj.MarkerEdgeAlpha = NameValuePairs.MarkerEdgeAlpha;
            obj.MarkerLineWidth = NameValuePairs.MarkerLineWidth;
            obj.MarkerSize = NameValuePairs.MarkerSize;
            obj.Marker = NameValuePairs.Marker;
            obj.setData(NameValuePairs.XData,NameValuePairs.YData,NameValuePairs.CData);

            obj.HullType = NameValuePairs.HullType;

            % data tip info
            obj.DataTipFormat = NameValuePairs.DataTipFormat;
            obj.DataTipCell = NameValuePairs.DataTipCell;

            % name of the dataset plotted
            obj.Name = NameValuePairs.Name;

        end

        function delete(obj)
        %DELETE Delete every graphics primitive owned by this plot group.

            delete(obj.scatterPoints);
            delete(obj.Hull);

        end

        function setData(obj,xData,yData,cData)
        %SETDATA Apply coupled point coordinates and colors in one graphics update.
            if isvector(cData) && numel(cData) ~= 3
                cData = cData(:);
            end

            set(obj.scatterPoints, ...
                'XData',xData, ...
                'YData',yData, ...
                'CData',cData);

            if obj.HullVisible
                obj.updateHull();
            end
        end

        function handled = handleEvent(obj,event)
        %HANDLEEVENT Preview data tips on hover and retain one on click.
            handled = false;
            targetMatches = isequal(event.Target,obj.scatterPoints) && ...
                ~isempty(obj.Parent);

            switch event.Kind
                case "Move"
                    if targetMatches
                        obj.updateHoverDataTip();
                        handled = true;
                    else
                        obj.clearHoverDataTip();
                    end

                case "Leave"
                    obj.clearHoverDataTip();

                case "Down"
                    % A clicked tip is retained by MATLAB and deliberately not
                    % stored as HoverDataTip, so later movement cannot remove it.
                    obj.clearHoverDataTip();
                    if event.MouseAction == "click" && targetMatches
                        point = obj.Parent.CurrentPoint;
                        datatip(obj.scatterPoints,point(1,1),point(1,2));
                        event.markHandled();
                        handled = true;
                    end
            end
        end

    end

    methods (Access=private)

        function updateHoverDataTip(obj)
        %UPDATEHOVERDATATIP Keep the existing preview while its point is unchanged.
            point = obj.Parent.CurrentPoint;
            candidate = datatip(obj.scatterPoints,point(1,1),point(1,2));

            if obj.sameDataIndex(candidate,obj.HoverDataTip)
                delete(candidate);
                return;
            end

            previous = obj.HoverDataTip;
            obj.HoverDataTip = candidate;
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
        end

        function disableHoverTipHitTesting(obj)
        %DISABLEHOVERTIPHITTESTING Keep the tip from obscuring its data point.
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

        function row = createDataTipRow(obj,label,value,format)
        %CREATEDATATIPROW Format numeric values and preserve text defaults.
            if nargin >= 4 && strlength(string(format)) > 0
                row = dataTipTextRow(label,value,format);
            elseif isnumeric(value)
                row = dataTipTextRow(label,value,obj.DataTipFormat_);
            else
                row = dataTipTextRow(label,value);
            end
        end

        function replaceDataTipRows(obj,val)
        %REPLACEDATATIPROWS Rebuild all point rows with the current format.
            dtNames = val{1};
            dtData = val{2};
            if numel(val) == 3
                dtFormats = val{3};
            else
                dtFormats = repmat({""},size(dtNames));
            end
            if numel(dtNames) ~= numel(dtData) || isempty(dtNames)
                error('matlabx:ui:axes:plot:InvalidDataTipCell', ...
                    'DataTipCell labels and values must have equal, nonzero counts.');
            end

            rows = obj.scatterPoints.DataTipTemplate.DataTipRows;
            for i = 1:numel(dtNames)
                rows(i) = obj.createDataTipRow( ...
                    dtNames{i},dtData{i},dtFormats{i});
            end
            for i = numel(rows):-1:numel(dtNames)+1
                rows(i) = [];
            end
            obj.scatterPoints.DataTipTemplate.DataTipRows = rows;
        end

        function validateDataTipCell(~,val)
        %VALIDATEDATATIPCELL Require {labels,values[,formats]} row metadata.
            if ~any(numel(val) == [2 3]) || ~iscell(val{1}) || ...
                    ~iscell(val{2}) || isempty(val{1}) || ...
                    numel(val{1}) ~= numel(val{2})
                error('matlabx:ui:axes:plot:InvalidDataTipCell', ...
                    'DataTipCell must contain {labels,values[,formats]} with equal row counts.');
            end
            if numel(val) == 3
                if ~iscell(val{3}) || numel(val{3}) ~= numel(val{1}) || ...
                        ~all(cellfun(@(x) (ischar(x) || (isstring(x) && isscalar(x))),val{3}))
                    error('matlabx:ui:axes:plot:InvalidDataTipCell', ...
                        'DataTipCell formats must contain one text scalar per row.');
                end
            end
        end

    end


    %% Set/Get methods for public properties controlling scatter points appearance

    methods

        %% Parent

        function set.Parent(obj,parent)
        %SET.PARENT Move both scatter and hull primitives to another UIAxes.

            if ~isempty(parent)
                validateattributes(parent,{'matlab.ui.control.UIAxes'},{'scalar'});
            end

            obj.scatterPoints.Parent = parent;
            obj.Hull.Parent = parent;
        end

        function parent = get.Parent(obj)
        %GET.PARENT Return the UIAxes containing the owned graphics.

            parent = obj.scatterPoints.Parent;
        end

        %% PointsVisible

        function set.PointsVisible(obj,val)
        %SET.POINTSVISIBLE Set the PointsVisible value on the owned graphics.
            obj.scatterPoints.Visible = val;
        end

        function PointsVisible = get.PointsVisible(obj)
        %GET.POINTSVISIBLE Return the current PointsVisible value from the owned graphics.
            PointsVisible = obj.scatterPoints.Visible;
        end

        %% XData

        function set.XData(obj,val)
        %SET.XDATA Set the XData value on the owned graphics.
            % set XData of the scatterPoints scatter
            obj.scatterPoints.XData = val;

            % update convex hull if possible
            if isequal(size(obj.XData),size(obj.YData)) && obj.HullVisible
                obj.updateHull();
            end
        end

        function XData = get.XData(obj)
        %GET.XDATA Return the current XData value from the owned graphics.
            XData = obj.scatterPoints.XData;
        end

        %% YData

        function set.YData(obj,val)
        %SET.YDATA Set the YData value on the owned graphics.
            % set YData of the scatterPoints scatter
            obj.scatterPoints.YData = val;

            % update convex hull if possible
            if isequal(size(obj.XData),size(obj.YData)) && obj.HullVisible
                obj.updateHull();
            end
        end

        function YData = get.YData(obj)
        %GET.YDATA Return the current YData value from the owned graphics.
            YData = obj.scatterPoints.YData;
        end

        %% MarkerEdgeColor

        function set.MarkerEdgeColor(obj,val)
        %SET.MARKEREDGECOLOR Set the MarkerEdgeColor value on the owned graphics.
            obj.scatterPoints.MarkerEdgeColor = val;
        end

        function MarkerEdgeColor = get.MarkerEdgeColor(obj)
        %GET.MARKEREDGECOLOR Return the current MarkerEdgeColor value from the owned graphics.
            MarkerEdgeColor = obj.scatterPoints.MarkerEdgeColor;
        end

        %% MarkerSize

        function set.MarkerSize(obj,val)
        %SET.MARKERSIZE Set the MarkerSize value on the owned graphics.
            obj.scatterPoints.SizeData = val;
        end

        function MarkerSize = get.MarkerSize(obj)
        %GET.MARKERSIZE Return the current MarkerSize value from the owned graphics.
            MarkerSize = obj.scatterPoints.SizeData;
        end

        %% MarkerFaceColorMode

        function set.MarkerFaceColor(obj,val)
        %SET.MARKERFACECOLOR Set the MarkerFaceColor value on the owned graphics.
            obj.scatterPoints.MarkerFaceColor = val;
        end

        function MarkerFaceColor = get.MarkerFaceColor(obj)
        %GET.MARKERFACECOLOR Return the current MarkerFaceColor value from the owned graphics.
            MarkerFaceColor = obj.scatterPoints.MarkerFaceColor;
        end

        %% MarkerEdgeAlpha

        function set.MarkerEdgeAlpha(obj,val)
        %SET.MARKEREDGEALPHA Set the MarkerEdgeAlpha value on the owned graphics.
            obj.scatterPoints.MarkerEdgeAlpha = val;
        end

        function MarkerEdgeAlpha = get.MarkerEdgeAlpha(obj)
        %GET.MARKEREDGEALPHA Return the current MarkerEdgeAlpha value from the owned graphics.
            MarkerEdgeAlpha = obj.scatterPoints.MarkerEdgeAlpha;
        end

        %% MarkerLineWidth

        function set.MarkerLineWidth(obj,val)
        %SET.MARKERLINEWIDTH Set the marker edge line width.
            obj.scatterPoints.LineWidth = val;
        end

        function val = get.MarkerLineWidth(obj)
        %GET.MARKERLINEWIDTH Return the marker edge line width.
            val = obj.scatterPoints.LineWidth;
        end

        %% MarkerFaceAlpha

        function set.MarkerFaceAlpha(obj,val)
        %SET.MARKERFACEALPHA Set the MarkerFaceAlpha value on the owned graphics.
            obj.scatterPoints.MarkerFaceAlpha = val;
        end

        function MarkerFaceAlpha = get.MarkerFaceAlpha(obj)
        %GET.MARKERFACEALPHA Return the current MarkerFaceAlpha value from the owned graphics.
            MarkerFaceAlpha = obj.scatterPoints.MarkerFaceAlpha;
        end

        %% Marker

        function set.Marker(obj,val)
        %SET.MARKER Set the Marker value on the owned graphics.
            obj.scatterPoints.Marker = val;
        end

        function Marker = get.Marker(obj)
        %GET.MARKER Return the current Marker value from the owned graphics.
            Marker = obj.scatterPoints.Marker;
        end

        %% CData

        function set.CData(obj,val)
        %SET.CDATA Set the CData value on the owned graphics.
            % Data contracts use row vectors; MATLAB scalar color data uses
            % one row per point. A triplet retains its RGB interpretation.
            if isvector(val) && numel(val) ~= 3
                val = val(:);
            end

            obj.scatterPoints.CData = val;
        end

        function CData = get.CData(obj)
        %GET.CDATA Return the current CData value from the owned graphics.
            CData = obj.scatterPoints.CData;
        end

        %% DataTipCell

        function set.DataTipCell(obj,val)
        %SET.DATATIPCELL Replace every point data-tip row, or restore X/Y.
            if numel(val) < 2 || isempty(val{1}) || isempty(val{2})
                val = {{"X","Y"},{obj.XData,obj.YData}};
            end

            obj.validateDataTipCell(val);
            obj.DataTipCell_ = val;
            obj.replaceDataTipRows(val);
        end

        function DataTipCell = get.DataTipCell(obj)
        %GET.DATATIPCELL Return the current DataTipCell value from the owned graphics.
            DataTipCell = obj.DataTipCell_;
        end

        %% DataTipFormat

        function set.DataTipFormat(obj,val)
        %SET.DATATIPFORMAT Apply one format to every numeric point row.
            obj.DataTipFormat_ = val;
            obj.replaceDataTipRows(obj.DataTipCell_);
        end

        function val = get.DataTipFormat(obj)
        %GET.DATATIPFORMAT Return the numeric point-row format.
            val = obj.DataTipFormat_;
        end

        %% Name

        function set.Name(obj,val)
        %SET.NAME Set the Name value on the owned graphics.
            obj.scatterPoints.DisplayName = val;
        end

        function Name = get.Name(obj)
        %GET.NAME Return the current Name value from the owned graphics.
            Name = obj.scatterPoints.DisplayName;
        end


    end



    %% Set and Get methods for public properties controlling convex hull appearance
    methods

        %% HullType

        function set.HullType(obj,val)
        %SET.HULLTYPE Set the HullType value on the owned graphics.
            obj.HullType_ = val;
            obj.updateHull();
        end

        function HullType = get.HullType(obj)
        %GET.HULLTYPE Return the current HullType value from the owned graphics.
            HullType = obj.HullType_;
        end

        %% HullVisible

        function set.HullVisible(obj,val)
        %SET.HULLVISIBLE Set the HullVisible value on the owned graphics.
            obj.Hull.Visible = val;
            % update convex hull if possible
            if isequal(size(obj.XData),size(obj.YData)) && obj.HullVisible
                obj.updateHull();
            end
        end

        function HullVisible = get.HullVisible(obj)
        %GET.HULLVISIBLE Return the current HullVisible value from the owned graphics.
            HullVisible = obj.Hull.Visible;
        end

        %% HullLineWidth

        function set.HullLineWidth(obj,val)
        %SET.HULLLINEWIDTH Set the HullLineWidth value on the owned graphics.
            obj.Hull.LineWidth = val;
        end

        function HullLineWidth = get.HullLineWidth(obj)
        %GET.HULLLINEWIDTH Return the current HullLineWidth value from the owned graphics.
            HullLineWidth = obj.Hull.LineWidth;
        end

        %% HullFaceColor

        function set.HullFaceColor(obj,val)
        %SET.HULLFACECOLOR Set the HullFaceColor value on the owned graphics.
            obj.Hull.FaceColor = val;
        end

        function HullFaceColor = get.HullFaceColor(obj)
        %GET.HULLFACECOLOR Return the current HullFaceColor value from the owned graphics.
            HullFaceColor = obj.Hull.FaceColor;
        end

        %% HullFaceAlpha

        function set.HullFaceAlpha(obj,val)
        %SET.HULLFACEALPHA Set the HullFaceAlpha value on the owned graphics.
            obj.Hull.FaceAlpha = val;
        end

        function HullFaceAlpha = get.HullFaceAlpha(obj)
        %GET.HULLFACEALPHA Return the current HullFaceAlpha value from the owned graphics.
            HullFaceAlpha = obj.Hull.FaceAlpha;
        end

        %% HullEdgeColor

        function set.HullEdgeColor(obj,val)
        %SET.HULLEDGECOLOR Set the HullEdgeColor value on the owned graphics.
            obj.Hull.EdgeColor = val;
        end

        function HullEdgeColor = get.HullEdgeColor(obj)
        %GET.HULLEDGECOLOR Return the current HullEdgeColor value from the owned graphics.
            HullEdgeColor = obj.Hull.EdgeColor;
        end

        %% HullEdgeAlpha

        function set.HullEdgeAlpha(obj,val)
        %SET.HULLEDGEALPHA Set the HullEdgeAlpha value on the owned graphics.
            obj.Hull.EdgeAlpha = val;
        end

        function HullEdgeAlpha = get.HullEdgeAlpha(obj)
        %GET.HULLEDGEALPHA Return the current HullEdgeAlpha value from the owned graphics.
            HullEdgeAlpha = obj.Hull.EdgeAlpha;
        end

    end


    % private, hidden methods for various internal purposes
    methods (Access = private,Hidden = true)

        function updateHull(obj)
        %UPDATEHULL Recompute the hull patch from the current point coordinates.

            % Hull algorithms need at least three distinct, noncollinear points.
            points = unique([obj.XData(:),obj.YData(:)],'rows','stable');
            % Check missing values before rank/SVD, which reject Inf and NaN.
            insufficient = size(points,1) < 3 || any(~isfinite(points),'all');

            if ~insufficient
                insufficient = rank(points-points(1,:)) < 2;
            end

            % Missing or degenerate series have no meaningful enclosing hull.
            if insufficient
                % set empty (NaN) coordinates for the Hull patch
                set(obj.Hull,...
                    "XData",NaN,...
                    "YData",NaN);
                return
            end

            switch obj.HullType
                case 'convex'
                    % get idxs for points representing convex hull
                    K = convhull(points(:,1),points(:,2));
                    % get the hull points
                    hullPoints = points(K,:);
                case 'concave'
                    % create alpha shape from the points
                    shp = alphaShape(points(:,1),points(:,2));
                    % determine the best alpha value to enclose points in a single region
                    alpha = criticalAlpha(shp,'one-region');

                    if ~isfinite(alpha) || alpha <= 0
                        set(obj.Hull,"XData",NaN,"YData",NaN);
                        return;
                    end

                    % set the alpha value we just found
                    shp.Alpha = alpha;
                    % make sure there are no holes so lines of the shape do not intersect
                    shp.HoleThreshold = 1;
                    % get the boundary coordinates
                    [~,P] = boundaryFacets(shp);

                    if isempty(P)
                        set(obj.Hull,"XData",NaN,"YData",NaN);
                        return;
                    end
                    % replicate the first point onto the end to form a close curve
                    hullPoints = [P;P(1,:)];
            end

            % update the coordinates of the Hull patch
            set(obj.Hull,...
                "XData",hullPoints(:,1),...
                "YData",hullPoints(:,2));


        end

    end




end
