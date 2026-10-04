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

classdef Point < matlabx.ui.axes.ImageAxesOverlay
%POINT Single point overlay for ImageAxes image-space annotations.
%
%   overlays.Point owns one marker at one [x y] image coordinate. It is the
%   interactive counterpart to overlays.PointSet: PointSet is useful for
%   passive detection previews, while Point is useful when tools need
%   per-point identity, hover, active, and selection state.

    properties (SetObservable, AbortSet)
        Position (1,2) double = [NaN NaN]
        ButtonDownFcn = []
    end

    properties (SetObservable, AbortSet)
        Marker (1,:) char = '+'
        MarkerSize (1,1) double {mustBePositive} = 8
        HoverMarkerSize (1,1) double {mustBePositive} = 11
        SelectionMarkerSize (1,1) double {mustBePositive} = 8
        ActiveMarkerSize (1,1) double {mustBePositive} = 4
        HoverActiveMarkerSize (1,1) double {mustBePositive} = 5

        MarkerEdgeColor = [1 1 1]
        MarkerFaceColor = [0 0 0]
        LineWidth (1,1) double {mustBePositive} = 1
        HoverLineWidth (1,1) double {mustBePositive} = 1.5
        SelectionLineWidth (1,1) double {mustBePositive} = 1.5
        ActiveLineWidth (1,1) double {mustBePositive} = 2
        ActiveMarkerLineWidth (1,1) double {mustBePositive} = 0.5

        HoverMarkerEdgeColor = [1 1 1]
        HoverMarkerFaceColor = [0 0 0]
        SelectionMarkerEdgeColor = [1 1 0]
        SelectionMarkerFaceColor = [0.15 0.15 0]
        ActiveMarkerEdgeColor = [0 0 0]
        ActiveMarkerFaceColor = [1 1 1]
    end

    properties (Access=private, Transient, NonCopyable)
        PointLine (1,1) matlab.graphics.primitive.Line
        ActiveMarkerLine (1,1) matlab.graphics.primitive.Line
        L event.listener = event.listener.empty()
        PendingUpdate (1,1) logical = false
    end

    methods
        function obj = Point(host, opts)
        %POINT Create a point overlay on the host image axes.
            arguments
                host matlabx.ui.axes.ImageAxes
                opts.Position (1,2) double = [NaN NaN]
                opts.ButtonDownFcn = []
                opts.ID (1,1) string = ""
                opts.Label (1,1) string = ""
                opts.C = "all"
                opts.Z = "all"
                opts.T = "all"
                opts.UserData = []
                opts.ActivateOnCreate (1,1) logical = false
                opts.Marker (1,:) char = '+'
                opts.MarkerSize (1,1) double {mustBePositive} = 8
                opts.HoverMarkerSize (1,1) double {mustBePositive} = 11
                opts.SelectionMarkerSize (1,1) double {mustBePositive} = 8
                opts.ActiveMarkerSize (1,1) double {mustBePositive} = 4
                opts.HoverActiveMarkerSize (1,1) double {mustBePositive} = 5
                opts.MarkerEdgeColor = [1 1 1]
                opts.MarkerFaceColor = [0 0 0]
                opts.LineWidth (1,1) double {mustBePositive} = 1
                opts.HoverLineWidth (1,1) double {mustBePositive} = 1.5
                opts.SelectionLineWidth (1,1) double {mustBePositive} = 1.5
                opts.ActiveLineWidth (1,1) double {mustBePositive} = 2
                opts.ActiveMarkerLineWidth (1,1) double {mustBePositive} = 0.5
                opts.HoverMarkerEdgeColor = [1 1 1]
                opts.HoverMarkerFaceColor = [0 0 0]
                opts.SelectionMarkerEdgeColor = [1 1 0]
                opts.SelectionMarkerFaceColor = [0.15 0.15 0]
                opts.ActiveMarkerEdgeColor = [0 0 0]
                opts.ActiveMarkerFaceColor = [1 1 1]
            end

            obj@matlabx.ui.axes.ImageAxesOverlay(host, ...
                "ID", opts.ID, ...
                "Type", "Point", ...
                "Label", opts.Label, ...
                "C", opts.C, ...
                "Z", opts.Z, ...
                "T", opts.T, ...
                "UserData", opts.UserData, ...
                "ActivateOnCreate", opts.ActivateOnCreate);

            obj.PointLine = line(obj.TargetAxes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "LineStyle", "none", ...
                "Marker", opts.Marker, ...
                "MarkerSize", opts.MarkerSize, ...
                "MarkerEdgeColor", opts.MarkerEdgeColor, ...
                "MarkerFaceColor", opts.MarkerFaceColor, ...
                "LineWidth", opts.LineWidth, ...
                "HitTest", "on", ...
                "PickableParts", "all", ...
                "Tag", "OverlayPoint");

            obj.ActiveMarkerLine = line(obj.TargetAxes, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "LineStyle", "none", ...
                "Marker", "s", ...
                "MarkerSize", opts.ActiveMarkerSize, ...
                "MarkerEdgeColor", opts.ActiveMarkerEdgeColor, ...
                "MarkerFaceColor", opts.ActiveMarkerFaceColor, ...
                "LineWidth", opts.ActiveMarkerLineWidth, ...
                "HitTest", "off", ...
                "PickableParts", "none", ...
                "Visible", "off", ...
                "Tag", "OverlayPointActiveMarker");

            obj.registerGraphics([obj.PointLine; obj.ActiveMarkerLine]);

            obj.Position = opts.Position;
            obj.ButtonDownFcn = opts.ButtonDownFcn;
            obj.Marker = opts.Marker;
            obj.MarkerSize = opts.MarkerSize;
            obj.HoverMarkerSize = opts.HoverMarkerSize;
            obj.SelectionMarkerSize = opts.SelectionMarkerSize;
            obj.ActiveMarkerSize = opts.ActiveMarkerSize;
            obj.HoverActiveMarkerSize = opts.HoverActiveMarkerSize;
            obj.MarkerEdgeColor = opts.MarkerEdgeColor;
            obj.MarkerFaceColor = opts.MarkerFaceColor;
            obj.LineWidth = opts.LineWidth;
            obj.HoverLineWidth = opts.HoverLineWidth;
            obj.SelectionLineWidth = opts.SelectionLineWidth;
            obj.ActiveLineWidth = opts.ActiveLineWidth;
            obj.ActiveMarkerLineWidth = opts.ActiveMarkerLineWidth;
            obj.HoverMarkerEdgeColor = opts.HoverMarkerEdgeColor;
            obj.HoverMarkerFaceColor = opts.HoverMarkerFaceColor;
            obj.SelectionMarkerEdgeColor = opts.SelectionMarkerEdgeColor;
            obj.SelectionMarkerFaceColor = opts.SelectionMarkerFaceColor;
            obj.ActiveMarkerEdgeColor = opts.ActiveMarkerEdgeColor;
            obj.ActiveMarkerFaceColor = opts.ActiveMarkerFaceColor;

            geomProps = {'Position', 'ButtonDownFcn'};
            appProps = { ...
                'Marker', ...
                'MarkerSize', ...
                'HoverMarkerSize', ...
                'SelectionMarkerSize', ...
                'ActiveMarkerSize', ...
                'HoverActiveMarkerSize', ...
                'MarkerEdgeColor', ...
                'MarkerFaceColor', ...
                'LineWidth', ...
                'HoverLineWidth', ...
                'SelectionLineWidth', ...
                'ActiveLineWidth', ...
                'ActiveMarkerLineWidth', ...
                'HoverMarkerEdgeColor', ...
                'HoverMarkerFaceColor', ...
                'SelectionMarkerEdgeColor', ...
                'SelectionMarkerFaceColor', ...
                'ActiveMarkerEdgeColor', ...
                'ActiveMarkerFaceColor'};

            obj.L(1) = addlistener(obj, geomProps, 'PostSet', @(~,~) obj.queueGeometryUpdate());
            obj.L(2) = addlistener(obj, appProps, 'PostSet', @(~,~) obj.updateAppearance());

            obj.refresh();
        end

        function delete(obj)
        %DELETE Delete listeners and graphics.
            for k = 1:numel(obj)
                if ~isempty(obj(k).L)
                    delete(obj(k).L(isvalid(obj(k).L)));
                end
                obj(k).deleteGraphics();
            end
        end

        function updateGeometry(obj)
        %UPDATEGEOMETRY Update marker coordinate and button callback.
            if isempty(obj.PointLine) || ~isgraphics(obj.PointLine)
                return
            end

            obj.PointLine.XData = obj.Position(1);
            obj.PointLine.YData = obj.Position(2);
            obj.PointLine.ButtonDownFcn = obj.ButtonDownFcn;
            obj.ActiveMarkerLine.XData = obj.Position(1);
            obj.ActiveMarkerLine.YData = obj.Position(2);
        end

        function updateAppearance(obj)
        %UPDATEAPPEARANCE Update marker appearance from overlay state.
            if isempty(obj.PointLine) || ~isgraphics(obj.PointLine)
                return
            end

            obj.PointLine.Marker = obj.Marker;

            [markerSize, edgeColor, faceColor, lineWidth] = obj.effectivePointAppearance();
            obj.PointLine.MarkerSize = markerSize;
            obj.PointLine.MarkerEdgeColor = edgeColor;
            obj.PointLine.MarkerFaceColor = faceColor;
            obj.PointLine.LineWidth = lineWidth;

            obj.ActiveMarkerLine.Marker = "s";
            if obj.Hovered
                obj.ActiveMarkerLine.MarkerSize = obj.HoverActiveMarkerSize;
            else
                obj.ActiveMarkerLine.MarkerSize = obj.ActiveMarkerSize;
            end
            obj.ActiveMarkerLine.MarkerEdgeColor = obj.ActiveMarkerEdgeColor;
            obj.ActiveMarkerLine.MarkerFaceColor = obj.ActiveMarkerFaceColor;
            obj.ActiveMarkerLine.LineWidth = obj.ActiveMarkerLineWidth;
            obj.updateVisibility();
        end

        function tf = isInsideRectangle(obj, rect)
        %ISINSIDERECTANGLE True when point position lies inside rect.
            xy = obj.Position;
            tf = xy(1) >= rect(1) && xy(1) <= rect(2) ...
                && xy(2) >= rect(3) && xy(2) <= rect(4);
        end
    end

    methods (Access=protected)
        function updateVisibility(obj)
        %UPDATEVISIBILITY Apply point visibility and active-marker policy.
            if isempty(obj.PointLine) || ~isgraphics(obj.PointLine)
                return
            end

            effectiveVisible = obj.Visible == "on" && obj.ViewVisible == "on";
            obj.PointLine.Visible = matlab.lang.OnOffSwitchState(effectiveVisible);
            obj.ActiveMarkerLine.Visible = matlab.lang.OnOffSwitchState(effectiveVisible && obj.Active);
        end
    end

    methods (Access=private)
        function [markerSize, edgeColor, faceColor, lineWidth] = effectivePointAppearance(obj)
        %EFFECTIVEPOINTAPPEARANCE Return marker style excluding active marker.
            if obj.Hovered
                markerSize = obj.HoverMarkerSize;
                edgeColor = obj.HoverMarkerEdgeColor;
                faceColor = obj.HoverMarkerFaceColor;
                lineWidth = obj.HoverLineWidth;
            elseif obj.Selected
                markerSize = obj.SelectionMarkerSize;
                edgeColor = obj.SelectionMarkerEdgeColor;
                faceColor = obj.SelectionMarkerFaceColor;
                lineWidth = obj.SelectionLineWidth;
            else
                markerSize = obj.MarkerSize;
                edgeColor = obj.MarkerEdgeColor;
                faceColor = obj.MarkerFaceColor;
                lineWidth = obj.LineWidth;
            end
        end

        function queueGeometryUpdate(obj)
        %QUEUEGEOMETRYUPDATE Coalesce geometry updates during property sets.
            if obj.PendingUpdate
                return
            end

            obj.PendingUpdate = true;
            drawnow limitrate nocallbacks
            obj.updateGeometry();
            obj.PendingUpdate = false;
        end
    end
end
