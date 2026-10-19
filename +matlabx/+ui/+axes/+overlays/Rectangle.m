classdef Rectangle < matlabx.ui.axes.ImageAxesOverlay
%RECTANGLE Four-edge rectangle overlay for ImageAxes image-space annotations.
%
%   overlays.Rectangle owns an axis-aligned rectangle patch plus an optional
%   handle layer. Geometry is stored as [x y width height], following MATLAB's
%   rectangle-position convention. The tool layer decides what gestures mean;
%   the overlay only owns geometry, graphics, identity, and state appearance.

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
        % Normal rectangle appearance.
        EdgeColor = [1 1 1]
        EdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(EdgeAlpha,0), mustBeLessThanOrEqual(EdgeAlpha,1)} = 1
        FaceColor = [1 1 1]
        FaceAlpha (1,1) double {mustBeGreaterThanOrEqual(FaceAlpha,0), mustBeLessThanOrEqual(FaceAlpha,1)} = 0
        LineWidth (1,1) double {mustBePositive} = 1
        LineStyle (1,:) char = '-'

        % Hover appearance.
        HoverEdgeColor = [1 1 1]
        HoverEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(HoverEdgeAlpha,0), mustBeLessThanOrEqual(HoverEdgeAlpha,1)} = 1
        HoverFaceColor = [1 1 1]
        HoverFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(HoverFaceAlpha,0), mustBeLessThanOrEqual(HoverFaceAlpha,1)} = 0
        HoverLineWidth (1,1) double {mustBePositive} = 1

        % Selection appearance.
        SelectionEdgeColor = [1 1 0]
        SelectionEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(SelectionEdgeAlpha,0), mustBeLessThanOrEqual(SelectionEdgeAlpha,1)} = 1
        SelectionFaceColor = [1 1 1]
        SelectionFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(SelectionFaceAlpha,0), mustBeLessThanOrEqual(SelectionFaceAlpha,1)} = 0
        SelectionLineWidth (1,1) double {mustBePositive} = 1

        % Active appearance.
        ActiveEdgeColor = [1 1 1]
        ActiveEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(ActiveEdgeAlpha,0), mustBeLessThanOrEqual(ActiveEdgeAlpha,1)} = 1
        ActiveFaceColor = [1 1 1]
        ActiveFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(ActiveFaceAlpha,0), mustBeLessThanOrEqual(ActiveFaceAlpha,1)} = 0
        ActiveLineWidth (1,1) double {mustBePositive} = 1

        % Handle and center-marker appearance.
        HandleMarkerStyle (1,:) char = 's'
        HandleMarkerSize (1,1) double {mustBePositive} = 4
        HoverHandleMarkerSize (1,1) double {mustBePositive} = 5
        HandleMarkerLineWidth (1,1) double {mustBePositive} = 0.5
        HandleMarkerEdgeColor = [0 0 0]
        HandleMarkerFaceColor = [1 1 1]

        HandlesVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        % Internal drawing override used before a new overlay becomes active.
        AlwaysShowHandles (1,1) matlab.lang.OnOffSwitchState = "off"
    end

    properties (Access=private, Transient, NonCopyable)
        RectPatch (1,1) matlab.graphics.primitive.Patch
        HandleMarkerLine (1,1) matlab.graphics.primitive.Line
        CenterHandleMarkerLine (1,1) matlab.graphics.primitive.Line
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
                opts.HoverEdgeColor = [1 1 1]
                opts.HoverEdgeAlpha (1,1) double {mustBeBetween(opts.HoverEdgeAlpha,0,1)} = 1
                opts.HoverFaceColor = [1 1 1]
                opts.HoverFaceAlpha (1,1) double {mustBeBetween(opts.HoverFaceAlpha,0,1)} = 0
                opts.HoverLineWidth (1,1) double {mustBePositive} = 1
                opts.SelectionEdgeColor = [1 1 0]
                opts.SelectionEdgeAlpha (1,1) double {mustBeBetween(opts.SelectionEdgeAlpha,0,1)} = 1
                opts.SelectionFaceColor = [1 1 1]
                opts.SelectionFaceAlpha (1,1) double {mustBeBetween(opts.SelectionFaceAlpha,0,1)} = 0
                opts.SelectionLineWidth (1,1) double {mustBePositive} = 1
                opts.ActiveEdgeColor = [1 1 1]
                opts.ActiveEdgeAlpha (1,1) double {mustBeBetween(opts.ActiveEdgeAlpha,0,1)} = 1
                opts.ActiveFaceColor = [1 1 1]
                opts.ActiveFaceAlpha (1,1) double {mustBeBetween(opts.ActiveFaceAlpha,0,1)} = 0
                opts.ActiveLineWidth (1,1) double {mustBePositive} = 1
                opts.HandleMarkerStyle (1,:) char = 's'
                opts.HandleMarkerSize (1,1) double {mustBePositive} = 4
                opts.HoverHandleMarkerSize (1,1) double {mustBePositive} = 5
                opts.HandleMarkerLineWidth (1,1) double {mustBePositive} = 0.5
                opts.HandleMarkerEdgeColor = [0 0 0]
                opts.HandleMarkerFaceColor = [1 1 1]
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

            obj.HandleMarkerLine = line(ax, ...
                'XData', NaN(1,8), ...
                'YData', NaN(1,8), ...
                'Color', obj.rgba(opts.HandleMarkerEdgeColor, 1), ...
                'LineStyle', 'none', ...
                'LineWidth', opts.HandleMarkerLineWidth, ...
                'Marker', opts.HandleMarkerStyle, ...
                'MarkerSize', opts.HandleMarkerSize, ...
                'MarkerFaceColor', opts.HandleMarkerFaceColor, ...
                'HitTest', 'on', ...
                'PickableParts', 'all', ...
                'Tag', 'OverlayRectangleHandles');

            % The center marker is display-only. Keeping it separate from
            % HandlePoints preserves the tool's existing eight resize handles.
            obj.CenterHandleMarkerLine = line(ax, ...
                'XData', NaN, 'YData', NaN, 'LineStyle', 'none', ...
                'LineWidth', opts.HandleMarkerLineWidth, 'Marker', opts.HandleMarkerStyle, ...
                'MarkerSize', opts.HandleMarkerSize, ...
                'MarkerEdgeColor', opts.HandleMarkerEdgeColor, ...
                'MarkerFaceColor', opts.HandleMarkerFaceColor, ...
                'HitTest', 'off', 'PickableParts', 'none', ...
                'Tag', 'OverlayRectangleCenterHandle');

            obj.registerGraphics([obj.RectPatch; obj.HandleMarkerLine; obj.CenterHandleMarkerLine]);

            obj.Position = obj.normalizedPosition(opts.Position);
            obj.ButtonDownFcn = opts.ButtonDownFcn;
            obj.EdgeColor = opts.EdgeColor;
            obj.EdgeAlpha = opts.EdgeAlpha;
            obj.LineWidth = opts.LineWidth;
            obj.LineStyle = opts.LineStyle;
            obj.FaceColor = opts.FaceColor;
            obj.FaceAlpha = opts.FaceAlpha;
            obj.HoverEdgeColor = opts.HoverEdgeColor;
            obj.HoverEdgeAlpha = opts.HoverEdgeAlpha;
            obj.HoverFaceColor = opts.HoverFaceColor;
            obj.HoverFaceAlpha = opts.HoverFaceAlpha;
            obj.HoverLineWidth = opts.HoverLineWidth;
            obj.SelectionEdgeColor = opts.SelectionEdgeColor;
            obj.SelectionEdgeAlpha = opts.SelectionEdgeAlpha;
            obj.SelectionFaceColor = opts.SelectionFaceColor;
            obj.SelectionFaceAlpha = opts.SelectionFaceAlpha;
            obj.SelectionLineWidth = opts.SelectionLineWidth;
            obj.ActiveEdgeColor = opts.ActiveEdgeColor;
            obj.ActiveEdgeAlpha = opts.ActiveEdgeAlpha;
            obj.ActiveFaceColor = opts.ActiveFaceColor;
            obj.ActiveFaceAlpha = opts.ActiveFaceAlpha;
            obj.ActiveLineWidth = opts.ActiveLineWidth;
            obj.HandleMarkerStyle = opts.HandleMarkerStyle;
            obj.HandleMarkerSize = opts.HandleMarkerSize;
            obj.HoverHandleMarkerSize = opts.HoverHandleMarkerSize;
            obj.HandleMarkerLineWidth = opts.HandleMarkerLineWidth;
            obj.HandleMarkerEdgeColor = opts.HandleMarkerEdgeColor;
            obj.HandleMarkerFaceColor = opts.HandleMarkerFaceColor;

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
                'HoverFaceColor', ...
                'SelectionFaceColor', ...
                'ActiveFaceColor', ...
                'FaceAlpha', ...
                'HoverFaceAlpha', ...
                'SelectionFaceAlpha', ...
                'ActiveFaceAlpha', ...
                'HandleMarkerStyle', ...
                'HandleMarkerSize', ...
                'HoverHandleMarkerSize', ...
                'HandleMarkerLineWidth', ...
                'HandleMarkerEdgeColor', ...
                'HandleMarkerFaceColor', ...
                'HandlesVisible', ...
                'AlwaysShowHandles'};

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
            obj.HandleMarkerLine.XData = handles(:,1).';
            obj.HandleMarkerLine.YData = handles(:,2).';
            obj.CenterHandleMarkerLine.XData = obj.Center(1);
            obj.CenterHandleMarkerLine.YData = obj.Center(2);

            if isempty(obj.ButtonDownFcn)
                obj.RectPatch.ButtonDownFcn = [];
                obj.HandleMarkerLine.ButtonDownFcn = [];
            else
                obj.RectPatch.ButtonDownFcn = obj.ButtonDownFcn;
                obj.HandleMarkerLine.ButtonDownFcn = obj.ButtonDownFcn;
            end
        end

        function updateAppearance(obj)
        %UPDATEAPPEARANCE Update rectangle and handle styling from state.
            if isempty(obj.RectPatch) || ~isgraphics(obj.RectPatch)
                return
            end

            [edgeColor, edgeAlpha, faceColor, faceAlpha, lineWidth] = ...
                obj.effectiveAppearance();

            obj.RectPatch.EdgeColor = obj.rgba(edgeColor, edgeAlpha);
            obj.RectPatch.LineWidth = lineWidth;
            obj.RectPatch.LineStyle = obj.LineStyle;
            obj.RectPatch.FaceColor = faceColor;
            obj.RectPatch.FaceAlpha = faceAlpha;

            obj.HandleMarkerLine.Color = obj.HandleMarkerEdgeColor;
            obj.HandleMarkerLine.Marker = obj.HandleMarkerStyle;
            obj.HandleMarkerLine.MarkerSize = obj.effectiveHandleMarkerSize();
            obj.HandleMarkerLine.LineWidth = obj.HandleMarkerLineWidth;
            obj.HandleMarkerLine.MarkerFaceColor = obj.HandleMarkerFaceColor;
            obj.CenterHandleMarkerLine.MarkerEdgeColor = obj.HandleMarkerEdgeColor;
            obj.CenterHandleMarkerLine.Marker = obj.HandleMarkerStyle;
            obj.CenterHandleMarkerLine.MarkerSize = obj.effectiveHandleMarkerSize();
            obj.CenterHandleMarkerLine.LineWidth = obj.HandleMarkerLineWidth;
            obj.CenterHandleMarkerLine.MarkerFaceColor = obj.HandleMarkerFaceColor;

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
            obj.HandleMarkerLine.Visible = matlab.lang.OnOffSwitchState( ...
                effectiveVisible && obj.handlesShouldShow());
            obj.CenterHandleMarkerLine.Visible = matlab.lang.OnOffSwitchState( ...
                effectiveVisible && obj.handlesShouldShow());
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

        function tf = handlesShouldShow(obj)
        %HANDLESSHOULDSHOW True when handle handle layer should be visible.
            tf = obj.HandlesVisible == "on" ...
                && (obj.AlwaysShowHandles == "on" || obj.Hovered || obj.Active);
        end

        function markerSize = effectiveHandleMarkerSize(obj)
        %EFFECTIVEHANDLEMARKERSIZE Return marker size implied by overlay state.
            if obj.Hovered
                markerSize = obj.HoverHandleMarkerSize;
            else
                markerSize = obj.HandleMarkerSize;
            end
        end

        function [edgeColor, edgeAlpha, faceColor, faceAlpha, lineWidth] = effectiveAppearance(obj)
        %EFFECTIVEAPPEARANCE Return style implied by overlay state.
            if obj.Hovered
                edgeColor = obj.HoverEdgeColor;
                edgeAlpha = obj.HoverEdgeAlpha;
                faceColor = obj.HoverFaceColor;
                faceAlpha = obj.HoverFaceAlpha;
                lineWidth = obj.HoverLineWidth;
            elseif obj.Active && obj.Selected
                edgeColor = obj.SelectionEdgeColor;
                edgeAlpha = obj.SelectionEdgeAlpha;
                faceColor = obj.SelectionFaceColor;
                faceAlpha = obj.SelectionFaceAlpha;
                lineWidth = obj.ActiveLineWidth;
            elseif obj.Active
                edgeColor = obj.ActiveEdgeColor;
                edgeAlpha = obj.ActiveEdgeAlpha;
                faceColor = obj.ActiveFaceColor;
                faceAlpha = obj.ActiveFaceAlpha;
                lineWidth = obj.ActiveLineWidth;
            elseif obj.Selected
                edgeColor = obj.SelectionEdgeColor;
                edgeAlpha = obj.SelectionEdgeAlpha;
                faceColor = obj.SelectionFaceColor;
                faceAlpha = obj.SelectionFaceAlpha;
                lineWidth = obj.SelectionLineWidth;
            else
                edgeColor = obj.EdgeColor;
                edgeAlpha = obj.EdgeAlpha;
                faceColor = obj.FaceColor;
                faceAlpha = obj.FaceAlpha;
                lineWidth = obj.LineWidth;
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
