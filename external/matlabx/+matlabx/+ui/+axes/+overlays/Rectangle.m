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

classdef Rectangle < matlabx.ui.axes.ImageAxesOverlay
%RECTANGLE Four-edge rectangle overlay for ImageAxes image-space annotations.
%
%   overlays.Rectangle owns an axis-aligned rectangle patch plus an optional
%   handle layer. Geometry is stored as [x y width height], following MATLAB's
%   rectangle-position convention. The tool layer decides what gestures mean;
%   the overlay only owns geometry, graphics, identity, and state appearance.

    properties (SetObservable, AbortSet)
        Position (1,4) double = [NaN NaN NaN NaN]
        ButtonDownFcn = []
    end

    properties (Dependent)
        X
        Y
        Width
        Height
        Center
        Corners
        HandlePoints
    end

    properties (SetObservable, AbortSet)
        EdgeColor = [1 1 1]
        SelectionEdgeColor = [1 1 0]
        HoverEdgeColor = [1 1 1]
        ActiveEdgeColor = [1 1 1]

        EdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(EdgeAlpha,0), mustBeLessThanOrEqual(EdgeAlpha,1)} = 1
        SelectionEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(SelectionEdgeAlpha,0), mustBeLessThanOrEqual(SelectionEdgeAlpha,1)} = 1
        HoverEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(HoverEdgeAlpha,0), mustBeLessThanOrEqual(HoverEdgeAlpha,1)} = 1
        ActiveEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(ActiveEdgeAlpha,0), mustBeLessThanOrEqual(ActiveEdgeAlpha,1)} = 1

        LineWidth (1,1) double {mustBePositive} = 1
        SelectionLineWidth (1,1) double {mustBePositive} = 1
        HoverLineWidth (1,1) double {mustBePositive} = 1
        ActiveLineWidth (1,1) double {mustBePositive} = 1

        LineStyle (1,:) char = '-'
        FaceColor = [1 1 1]
        FaceAlpha (1,1) double {mustBeGreaterThanOrEqual(FaceAlpha,0), mustBeLessThanOrEqual(FaceAlpha,1)} = 0
        HoverFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(HoverFaceAlpha,0), mustBeLessThanOrEqual(HoverFaceAlpha,1)} = 0
        SelectionFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(SelectionFaceAlpha,0), mustBeLessThanOrEqual(SelectionFaceAlpha,1)} = 0
        ActiveFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(ActiveFaceAlpha,0), mustBeLessThanOrEqual(ActiveFaceAlpha,1)} = 0

        MarkerStyle (1,:) char = 's'
        MarkerSize (1,1) double {mustBePositive} = 4
        HoverMarkerSize (1,1) double {mustBePositive} = 5
        MarkerLineWidth (1,1) double {mustBePositive} = 0.5
        MarkerEdgeColor = [0 0 0]
        MarkerFaceColor = [1 1 1]

        MarkersVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        AlwaysShowMarkers (1,1) matlab.lang.OnOffSwitchState = "off"
    end

    properties (Access=private, Transient, NonCopyable)
        RectPatch (1,1) matlab.graphics.primitive.Patch
        MarkerLine (1,1) matlab.graphics.primitive.Line
        L event.listener = event.listener.empty()
        PendingUpdate (1,1) logical = false
    end

    methods
        function obj = Rectangle(host, opts)
        %RECTANGLE Create a rectangle overlay on the host image axes.
            arguments
                host matlabx.ui.axes.ImageAxes
                opts.Position (1,4) double = [NaN NaN NaN NaN]
                opts.ButtonDownFcn = []
                opts.ID (1,1) string = ""
                opts.Label (1,1) string = ""
                opts.EdgeColor = [1 1 1]
                opts.EdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(opts.EdgeAlpha,0), mustBeLessThanOrEqual(opts.EdgeAlpha,1)} = 1
                opts.LineWidth (1,1) double {mustBePositive} = 1
                opts.LineStyle (1,:) char = '-'
                opts.FaceColor = [1 1 1]
                opts.FaceAlpha (1,1) double {mustBeGreaterThanOrEqual(opts.FaceAlpha,0), mustBeLessThanOrEqual(opts.FaceAlpha,1)} = 0
                opts.MarkerStyle (1,:) char = 's'
                opts.MarkerSize (1,1) double {mustBePositive} = 4
                opts.HoverMarkerSize (1,1) double {mustBePositive} = 5
                opts.MarkerEdgeColor = [0 0 0]
                opts.MarkerFaceColor = [1 1 1]
                opts.C = "all"
                opts.Z = "all"
                opts.T = "all"
                opts.UserData = []
                opts.ActivateOnCreate (1,1) logical = false
            end

            obj@matlabx.ui.axes.ImageAxesOverlay(host, ...
                "ID", opts.ID, ...
                "Type", "Rectangle", ...
                "Label", opts.Label, ...
                "C", opts.C, ...
                "Z", opts.Z, ...
                "T", opts.T, ...
                "UserData", opts.UserData, ...
                "ActivateOnCreate", opts.ActivateOnCreate);

            ax = obj.TargetAxes;
            obj.RectPatch = patch(ax, ...
                'XData', [NaN NaN NaN NaN], ...
                'YData', [NaN NaN NaN NaN], ...
                'EdgeColor', obj.rgba(opts.EdgeColor, opts.EdgeAlpha), ...
                'FaceColor', opts.FaceColor, ...
                'FaceAlpha', opts.FaceAlpha, ...
                'LineStyle', opts.LineStyle, ...
                'LineWidth', opts.LineWidth, ...
                'HitTest', 'on', ...
                'PickableParts', 'all', ...
                'Tag', 'OverlayRectangle');

            obj.MarkerLine = line(ax, ...
                'XData', NaN(1,8), ...
                'YData', NaN(1,8), ...
                'Color', obj.rgba(opts.MarkerEdgeColor, 1), ...
                'LineStyle', 'none', ...
                'LineWidth', obj.MarkerLineWidth, ...
                'Marker', opts.MarkerStyle, ...
                'MarkerSize', opts.MarkerSize, ...
                'MarkerFaceColor', opts.MarkerFaceColor, ...
                'HitTest', 'on', ...
                'PickableParts', 'all', ...
                'Tag', 'OverlayRectangleMarkers');

            obj.registerGraphics([obj.RectPatch; obj.MarkerLine]);

            obj.Position = obj.normalizedPosition(opts.Position);
            obj.ButtonDownFcn = opts.ButtonDownFcn;
            obj.EdgeColor = opts.EdgeColor;
            obj.EdgeAlpha = opts.EdgeAlpha;
            obj.LineWidth = opts.LineWidth;
            obj.LineStyle = opts.LineStyle;
            obj.FaceColor = opts.FaceColor;
            obj.FaceAlpha = opts.FaceAlpha;
            obj.MarkerStyle = opts.MarkerStyle;
            obj.MarkerSize = opts.MarkerSize;
            obj.HoverMarkerSize = opts.HoverMarkerSize;
            obj.MarkerEdgeColor = opts.MarkerEdgeColor;
            obj.MarkerFaceColor = opts.MarkerFaceColor;

            geomProps = {'Position', 'ButtonDownFcn'};
            appProps = { ...
                'EdgeColor', ...
                'SelectionEdgeColor', ...
                'HoverEdgeColor', ...
                'ActiveEdgeColor', ...
                'EdgeAlpha', ...
                'SelectionEdgeAlpha', ...
                'HoverEdgeAlpha', ...
                'ActiveEdgeAlpha', ...
                'LineWidth', ...
                'SelectionLineWidth', ...
                'HoverLineWidth', ...
                'ActiveLineWidth', ...
                'LineStyle', ...
                'FaceColor', ...
                'FaceAlpha', ...
                'HoverFaceAlpha', ...
                'SelectionFaceAlpha', ...
                'ActiveFaceAlpha', ...
                'MarkerStyle', ...
                'MarkerSize', ...
                'HoverMarkerSize', ...
                'MarkerLineWidth', ...
                'MarkerEdgeColor', ...
                'MarkerFaceColor', ...
                'MarkersVisible', ...
                'AlwaysShowMarkers'};

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

        function set.Position(obj, value)
        %SET.POSITION Store rectangle position with nonnegative dimensions.
            obj.Position = obj.normalizedPosition(value);
        end

        function value = get.X(obj)
        %GET.X Return left edge coordinate.
            value = obj.Position(1);
        end

        function value = get.Y(obj)
        %GET.Y Return bottom edge coordinate.
            value = obj.Position(2);
        end

        function value = get.Width(obj)
        %GET.WIDTH Return rectangle width.
            value = obj.Position(3);
        end

        function value = get.Height(obj)
        %GET.HEIGHT Return rectangle height.
            value = obj.Position(4);
        end

        function value = get.Center(obj)
        %GET.CENTER Return rectangle center [x y].
            value = [obj.X + obj.Width/2, obj.Y + obj.Height/2];
        end

        function value = get.Corners(obj)
        %GET.CORNERS Return corners [bottom-left; bottom-right; top-right; top-left].
            x1 = obj.X;
            x2 = obj.X + obj.Width;
            y1 = obj.Y;
            y2 = obj.Y + obj.Height;
            value = [x1 y1; x2 y1; x2 y2; x1 y2];
        end

        function value = get.HandlePoints(obj)
        %GET.HANDLEPOINTS Return 8 handles clockwise from bottom-left.
            c = obj.Corners;
            value = [ ...
                c(1,:); ...
                mean(c(1:2,:), 1); ...
                c(2,:); ...
                mean(c(2:3,:), 1); ...
                c(3,:); ...
                mean(c(3:4,:), 1); ...
                c(4,:); ...
                mean(c([4 1],:), 1)];
        end

        function updateGeometry(obj)
        %UPDATEGEOMETRY Update rectangle patch and handle coordinates.
            if isempty(obj.RectPatch) || ~isgraphics(obj.RectPatch)
                return
            end

            c = obj.Corners;
            obj.RectPatch.XData = c(:,1).';
            obj.RectPatch.YData = c(:,2).';

            handles = obj.HandlePoints;
            obj.MarkerLine.XData = handles(:,1).';
            obj.MarkerLine.YData = handles(:,2).';

            if isempty(obj.ButtonDownFcn)
                obj.RectPatch.ButtonDownFcn = [];
                obj.MarkerLine.ButtonDownFcn = [];
            else
                obj.RectPatch.ButtonDownFcn = obj.ButtonDownFcn;
                obj.MarkerLine.ButtonDownFcn = obj.ButtonDownFcn;
            end
        end

        function updateAppearance(obj)
        %UPDATEAPPEARANCE Update rectangle and handle styling from state.
            if isempty(obj.RectPatch) || ~isgraphics(obj.RectPatch)
                return
            end

            [edgeColor, edgeAlpha, lineWidth, faceAlpha] = obj.effectiveAppearance();

            obj.RectPatch.EdgeColor = obj.rgba(edgeColor, edgeAlpha);
            obj.RectPatch.LineWidth = lineWidth;
            obj.RectPatch.LineStyle = obj.LineStyle;
            obj.RectPatch.FaceColor = obj.FaceColor;
            obj.RectPatch.FaceAlpha = faceAlpha;

            obj.MarkerLine.Color = obj.rgba(obj.MarkerEdgeColor, edgeAlpha);
            obj.MarkerLine.Marker = obj.MarkerStyle;
            obj.MarkerLine.MarkerSize = obj.effectiveMarkerSize();
            obj.MarkerLine.LineWidth = obj.MarkerLineWidth;
            obj.MarkerLine.MarkerFaceColor = obj.MarkerFaceColor;

            obj.updateGeometry();
            obj.updateVisibility();
        end

        function tf = isInsideRectangle(obj, rect)
        %ISINSIDERECTANGLE True when rectangle center lies inside rect.
            xy = obj.Center;
            tf = xy(1) >= rect(1) && xy(1) <= rect(2) ...
                && xy(2) >= rect(3) && xy(2) <= rect(4);
        end
    end

    methods (Access=protected)
        function updateVisibility(obj)
        %UPDATEVISIBILITY Apply rectangle and handle visibility policy.
            if isempty(obj.RectPatch) || ~isgraphics(obj.RectPatch)
                return
            end

            effectiveVisible = obj.Visible == "on" && obj.ViewVisible == "on";
            obj.RectPatch.Visible = matlab.lang.OnOffSwitchState(effectiveVisible);
            obj.MarkerLine.Visible = matlab.lang.OnOffSwitchState( ...
                effectiveVisible && obj.markersShouldShow());
        end
    end

    methods (Access=private)
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

        function tf = markersShouldShow(obj)
        %MARKERSSHOULDSHOW True when handle marker layer should be visible.
            tf = obj.MarkersVisible == "on" ...
                && (obj.AlwaysShowMarkers == "on" || obj.Hovered || obj.Active);
        end

        function markerSize = effectiveMarkerSize(obj)
        %EFFECTIVEMARKERSIZE Return marker size implied by overlay state.
            if obj.Hovered
                markerSize = obj.HoverMarkerSize;
            else
                markerSize = obj.MarkerSize;
            end
        end

        function [edgeColor, edgeAlpha, lineWidth, faceAlpha] = effectiveAppearance(obj)
        %EFFECTIVEAPPEARANCE Return style implied by overlay state.
            if obj.Hovered
                edgeColor = obj.HoverEdgeColor;
                edgeAlpha = obj.HoverEdgeAlpha;
                lineWidth = obj.HoverLineWidth;
                faceAlpha = obj.HoverFaceAlpha;
            elseif obj.Active && obj.Selected
                edgeColor = obj.SelectionEdgeColor;
                edgeAlpha = obj.SelectionEdgeAlpha;
                lineWidth = obj.ActiveLineWidth;
                faceAlpha = obj.SelectionFaceAlpha;
            elseif obj.Active
                edgeColor = obj.ActiveEdgeColor;
                edgeAlpha = obj.ActiveEdgeAlpha;
                lineWidth = obj.ActiveLineWidth;
                faceAlpha = obj.ActiveFaceAlpha;
            elseif obj.Selected
                edgeColor = obj.SelectionEdgeColor;
                edgeAlpha = obj.SelectionEdgeAlpha;
                lineWidth = obj.SelectionLineWidth;
                faceAlpha = obj.SelectionFaceAlpha;
            else
                edgeColor = obj.EdgeColor;
                edgeAlpha = obj.EdgeAlpha;
                lineWidth = obj.LineWidth;
                faceAlpha = obj.FaceAlpha;
            end
        end

        function value = normalizedPosition(~, value)
        %NORMALIZEDPOSITION Convert any two-corner position to [xmin ymin w h].
            if any(isnan(value))
                return
            end

            x1 = value(1);
            y1 = value(2);
            x2 = value(1) + value(3);
            y2 = value(2) + value(4);
            value = [min(x1,x2), min(y1,y2), abs(x2-x1), abs(y2-y1)];
        end

        function c = rgba(~, color, alpha)
        %RGBA Return RGB or RGBA color depending on requested alpha.
            c = color;
            if isnumeric(color) && numel(color) == 3 && alpha < 1
                c = [color alpha];
            end
        end
    end
end
