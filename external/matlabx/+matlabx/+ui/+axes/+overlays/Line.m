classdef Line < matlabx.ui.axes.ImageAxesOverlay
%LINE Two-endpoint line overlay for ImageAxes image-space annotations.
%
%   overlays.Line owns a line segment plus an optional handle layer. Geometry is
%   stored as two endpoints. Marker geometry is normalized as
%   endpoint1 -> midpoint -> endpoint2 so tools can use the same overlay for
%   endpoint handles, midpoint dragging, hover feedback, and active-state
%   editing.

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
        Endpoints (2,2) double = [NaN NaN; NaN NaN]
        ButtonDownFcn = []
    end

    properties (Dependent)
        Endpoint1
        Endpoint2
        Midpoint
        Length
        AngleDegrees
    end

    properties (SetObservable, AbortSet)
        % Normal line appearance.
        LineColor = [1 1 1]
        LineAlpha (1,1) double {mustBeGreaterThanOrEqual(LineAlpha,0), mustBeLessThanOrEqual(LineAlpha,1)} = 1
        LineWidth (1,1) double {mustBePositive} = 1
        LineStyle (1,:) char = '-'

        % Hover appearance.
        HoverLineColor = [1 1 1]
        HoverLineAlpha (1,1) double {mustBeGreaterThanOrEqual(HoverLineAlpha,0), mustBeLessThanOrEqual(HoverLineAlpha,1)} = 1
        HoverLineWidth (1,1) double {mustBePositive} = 1

        % Selection appearance.
        SelectionLineColor = [1 1 0]
        SelectionLineAlpha (1,1) double {mustBeGreaterThanOrEqual(SelectionLineAlpha,0), mustBeLessThanOrEqual(SelectionLineAlpha,1)} = 1
        SelectionLineWidth (1,1) double {mustBePositive} = 1

        % Active appearance.
        ActiveLineColor = [1 1 1]
        ActiveLineAlpha (1,1) double {mustBeGreaterThanOrEqual(ActiveLineAlpha,0), mustBeLessThanOrEqual(ActiveLineAlpha,1)} = 1
        ActiveLineWidth (1,1) double {mustBePositive} = 1

        % Endpoint and midpoint-marker appearance.
        HandleMarkerStyle (1,:) char = 's'
        HandleMarkerSize (1,1) double {mustBePositive} = 4
        HoverHandleMarkerSize (1,1) double {mustBePositive} = 5
        HandleMarkerLineWidth (1,1) double {mustBePositive} = 0.5
        HandleMarkerEdgeColor = [0 0 0]
        HandleMarkerFaceColor = [1 1 1]
        HitAreaWidth (1,1) double {mustBePositive} = 10

        HandlesVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        % Internal drawing override used before a new overlay becomes active.
        AlwaysShowHandles (1,1) matlab.lang.OnOffSwitchState = "off"
        Endpoint1MarkerVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        MidpointMarkerVisible (1,1) matlab.lang.OnOffSwitchState = "on"
        Endpoint2MarkerVisible (1,1) matlab.lang.OnOffSwitchState = "on"
    end

    properties (Access=private, Transient, NonCopyable)
        HitPatch (1,1) matlab.graphics.primitive.Patch
        SegmentLine (1,1) matlab.graphics.primitive.Line
        HandleMarkerLine (1,1) matlab.graphics.primitive.Line
        L event.listener = event.listener.empty()
        PendingUpdate (1,1) logical = false
    end

    methods
        function obj = Line(host, opts)
        %LINE Create a line overlay on the host image axes.
            arguments
                host matlabx.ui.axes.ImageAxes
                opts.Endpoints (2,2) double = [NaN NaN; NaN NaN]
                opts.Endpoint1 (1,2) double = [NaN NaN]
                opts.Endpoint2 (1,2) double = [NaN NaN]
                opts.ButtonDownFcn = []
                opts.ID (1,1) string = ""
                opts.Label (1,1) string = ""
                opts.LineColor = [1 1 1]
                opts.LineAlpha (1,1) double {mustBeGreaterThanOrEqual(opts.LineAlpha,0), mustBeLessThanOrEqual(opts.LineAlpha,1)} = 1
                opts.LineWidth (1,1) double {mustBePositive} = 1
                opts.LineStyle (1,:) char = '-'
                opts.HoverLineColor = [1 1 1]
                opts.HoverLineAlpha (1,1) double {mustBeBetween(opts.HoverLineAlpha,0,1)} = 1
                opts.HoverLineWidth (1,1) double {mustBePositive} = 1
                opts.SelectionLineColor = [1 1 0]
                opts.SelectionLineAlpha (1,1) double {mustBeBetween(opts.SelectionLineAlpha,0,1)} = 1
                opts.SelectionLineWidth (1,1) double {mustBePositive} = 1
                opts.ActiveLineColor = [1 1 1]
                opts.ActiveLineAlpha (1,1) double {mustBeBetween(opts.ActiveLineAlpha,0,1)} = 1
                opts.ActiveLineWidth (1,1) double {mustBePositive} = 1
                opts.HandleMarkerStyle (1,:) char = 's'
                opts.HandleMarkerSize (1,1) double {mustBePositive} = 4
                opts.HoverHandleMarkerSize (1,1) double {mustBePositive} = 5
                opts.HandleMarkerLineWidth (1,1) double {mustBePositive} = 0.5
                opts.HandleMarkerEdgeColor = [0 0 0]
                opts.HandleMarkerFaceColor = [1 1 1]
                opts.HitAreaWidth (1,1) double {mustBePositive} = 10
                opts.C = "all"
                opts.Z = "all"
                opts.T = "all"
                opts.UserData = []
                opts.ActivateOnCreate (1,1) logical = false
            end

            obj@matlabx.ui.axes.ImageAxesOverlay(host, ...
                "ID", opts.ID, ...
                "Type", "Line", ...
                "Label", opts.Label, ...
                "C", opts.C, ...
                "Z", opts.Z, ...
                "T", opts.T, ...
                "UserData", opts.UserData, ...
                "ActivateOnCreate", opts.ActivateOnCreate);

            ax = obj.TargetAxes;

            obj.HitPatch = patch(ax, ...
                'XData', [NaN NaN NaN NaN], ...
                'YData', [NaN NaN NaN NaN], ...
                'FaceColor', [1 1 1], ...
                'FaceAlpha', 0.001, ...
                'EdgeColor', 'none', ...
                'HitTest', 'on', ...
                'PickableParts', 'all', ...
                'Tag', 'OverlayLineHitArea');

            obj.SegmentLine = line(ax, ...
                'XData', [NaN NaN], ...
                'YData', [NaN NaN], ...
                'Color', obj.rgba(opts.LineColor, opts.LineAlpha), ...
                'LineStyle', opts.LineStyle, ...
                'LineWidth', opts.LineWidth, ...
                'Marker', 'none', ...
                'HitTest', 'on', ...
                'PickableParts', 'all', ...
                'Tag', 'OverlayLine');

            obj.HandleMarkerLine = line(ax, ...
                'XData', [NaN NaN NaN], ...
                'YData', [NaN NaN NaN], ...
                'Color', obj.rgba(opts.HandleMarkerEdgeColor, 1), ...
                'LineStyle', 'none', ...
                'LineWidth', obj.HandleMarkerLineWidth, ...
                'Marker', opts.HandleMarkerStyle, ...
                'MarkerSize', opts.HandleMarkerSize, ...
                'MarkerFaceColor', opts.HandleMarkerFaceColor, ...
                'HitTest', 'on', ...
                'PickableParts', 'all', ...
                'Tag', 'OverlayLineHandles');

            obj.registerGraphics([obj.HitPatch; obj.SegmentLine; obj.HandleMarkerLine]);

            obj.Endpoints = opts.Endpoints;
            if ~any(isnan(opts.Endpoint1)) || ~any(isnan(opts.Endpoint2))
                obj.Endpoints = [opts.Endpoint1; opts.Endpoint2];
            end

            obj.ButtonDownFcn = opts.ButtonDownFcn;
            obj.LineColor = opts.LineColor;
            obj.LineAlpha = opts.LineAlpha;
            obj.LineWidth = opts.LineWidth;
            obj.LineStyle = opts.LineStyle;
            obj.HoverLineColor = opts.HoverLineColor;
            obj.HoverLineAlpha = opts.HoverLineAlpha;
            obj.HoverLineWidth = opts.HoverLineWidth;
            obj.SelectionLineColor = opts.SelectionLineColor;
            obj.SelectionLineAlpha = opts.SelectionLineAlpha;
            obj.SelectionLineWidth = opts.SelectionLineWidth;
            obj.ActiveLineColor = opts.ActiveLineColor;
            obj.ActiveLineAlpha = opts.ActiveLineAlpha;
            obj.ActiveLineWidth = opts.ActiveLineWidth;
            obj.HandleMarkerStyle = opts.HandleMarkerStyle;
            obj.HandleMarkerSize = opts.HandleMarkerSize;
            obj.HoverHandleMarkerSize = opts.HoverHandleMarkerSize;
            obj.HandleMarkerLineWidth = opts.HandleMarkerLineWidth;
            obj.HandleMarkerEdgeColor = opts.HandleMarkerEdgeColor;
            obj.HandleMarkerFaceColor = opts.HandleMarkerFaceColor;
            obj.HitAreaWidth = opts.HitAreaWidth;

            geomProps = {'Endpoints', 'ButtonDownFcn'};
            appProps = { ...
                'LineColor', ...
                'SelectionLineColor', ...
                'HoverLineColor', ...
                'ActiveLineColor', ...
                'LineAlpha', ...
                'SelectionLineAlpha', ...
                'HoverLineAlpha', ...
                'ActiveLineAlpha', ...
                'LineWidth', ...
                'SelectionLineWidth', ...
                'HoverLineWidth', ...
                'ActiveLineWidth', ...
                'LineStyle', ...
                'HandleMarkerStyle', ...
                'HandleMarkerSize', ...
                'HoverHandleMarkerSize', ...
                'HandleMarkerLineWidth', ...
                'HandleMarkerEdgeColor', ...
                'HandleMarkerFaceColor', ...
                'HitAreaWidth', ...
                'HandlesVisible', ...
                'AlwaysShowHandles', ...
                'Endpoint1MarkerVisible', ...
                'MidpointMarkerVisible', ...
                'Endpoint2MarkerVisible'};

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

        function value = get.Endpoint1(obj)
        %GET.ENDPOINT1 Return the first endpoint [x y].
            value = obj.Endpoints(1,:);
        end

        function set.Endpoint1(obj, value)
        %SET.ENDPOINT1 Set the first endpoint [x y].
            obj.Endpoints(1,:) = value;
        end

        function value = get.Endpoint2(obj)
        %GET.ENDPOINT2 Return the second endpoint [x y].
            value = obj.Endpoints(2,:);
        end

        function set.Endpoint2(obj, value)
        %SET.ENDPOINT2 Set the second endpoint [x y].
            obj.Endpoints(2,:) = value;
        end

        function value = get.Midpoint(obj)
        %GET.MIDPOINT Return the midpoint [x y].
            value = mean(obj.Endpoints, 1);
        end

        function value = get.Length(obj)
        %GET.LENGTH Return Euclidean line length.
            d = diff(obj.Endpoints, 1, 1);
            value = hypot(d(1), d(2));
        end

        function value = get.AngleDegrees(obj)
        %GET.ANGLEDEGREES Return line angle in degrees from endpoint1 to endpoint2.
            d = diff(obj.Endpoints, 1, 1);
            value = atan2d(d(2), d(1));
        end

        function updateGeometry(obj)
        %UPDATEGEOMETRY Update segment and marker coordinates.
            if isempty(obj.SegmentLine) || ~isgraphics(obj.SegmentLine)
                return
            end

            p1 = obj.Endpoint1;
            p2 = obj.Endpoint2;
            pm = obj.Midpoint;

            obj.SegmentLine.XData = [p1(1), p2(1)];
            obj.SegmentLine.YData = [p1(2), p2(2)];
            [xHit,yHit] = obj.hitPatchCoordinates(p1,p2);
            obj.HitPatch.XData = xHit;
            obj.HitPatch.YData = yHit;

            markerXY = [p1; pm; p2];
            markerMask = obj.markerMask();
            markerXY(~markerMask,:) = NaN;
            obj.HandleMarkerLine.XData = markerXY(:,1).';
            obj.HandleMarkerLine.YData = markerXY(:,2).';

            if isempty(obj.ButtonDownFcn)
                obj.SegmentLine.ButtonDownFcn = [];
                obj.HandleMarkerLine.ButtonDownFcn = [];
                obj.HitPatch.ButtonDownFcn = [];
            else
                obj.SegmentLine.ButtonDownFcn = obj.ButtonDownFcn;
                obj.HandleMarkerLine.ButtonDownFcn = obj.ButtonDownFcn;
                obj.HitPatch.ButtonDownFcn = obj.ButtonDownFcn;
            end
        end

        function updateAppearance(obj)
        %UPDATEAPPEARANCE Update line/marker styling from overlay state.
            if isempty(obj.SegmentLine) || ~isgraphics(obj.SegmentLine)
                return
            end

            [lineColor, lineAlpha, lineWidth] = obj.effectiveLineAppearance();

            obj.SegmentLine.Color = obj.rgba(lineColor, lineAlpha);
            obj.SegmentLine.LineWidth = lineWidth;
            obj.SegmentLine.LineStyle = obj.LineStyle;

            obj.HandleMarkerLine.Color = obj.rgba(obj.HandleMarkerEdgeColor, lineAlpha);
            obj.HandleMarkerLine.Marker = obj.HandleMarkerStyle;
            obj.HandleMarkerLine.MarkerSize = obj.effectiveHandleMarkerSize();
            obj.HandleMarkerLine.LineWidth = obj.HandleMarkerLineWidth;
            obj.HandleMarkerLine.MarkerFaceColor = obj.HandleMarkerFaceColor;

            obj.updateGeometry();
            obj.updateVisibility();
        end

        function tf = isInsideRectangle(obj, rect)
        %ISINSIDERECTANGLE True when line midpoint lies inside rect.
            xy = obj.Midpoint;
            tf = xy(1) >= rect(1) && xy(1) <= rect(2) ...
                && xy(2) >= rect(3) && xy(2) <= rect(4);
        end
    end

    methods (Access=protected)
        function updateVisibility(obj)
        %UPDATEVISIBILITY Apply line and handle visibility policy.
            if isempty(obj.SegmentLine) || ~isgraphics(obj.SegmentLine)
                return
            end

            effectiveVisible = obj.Visible == "on" && obj.ViewVisible == "on";
            obj.HitPatch.Visible = matlab.lang.OnOffSwitchState(effectiveVisible);
            obj.SegmentLine.Visible = matlab.lang.OnOffSwitchState(effectiveVisible);
            obj.HandleMarkerLine.Visible = matlab.lang.OnOffSwitchState( ...
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

        function mask = markerMask(obj)
        %MARKERMASK Return visible marker slots [endpoint1 midpoint endpoint2].
            mask = [ ...
                obj.Endpoint1MarkerVisible == "on", ...
                obj.MidpointMarkerVisible == "on", ...
                obj.Endpoint2MarkerVisible == "on"];
        end

        function tf = handlesShouldShow(obj)
        %HANDLESSHOULDSHOW True when handle layer should be visible.
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

        function [lineColor, lineAlpha, lineWidth] = effectiveLineAppearance(obj)
        %EFFECTIVELINEAPPEARANCE Return style implied by overlay state.
            if obj.Hovered
                lineColor = obj.HoverLineColor;
                lineAlpha = obj.HoverLineAlpha;
                lineWidth = obj.HoverLineWidth;
            elseif obj.Active && obj.Selected
                lineColor = obj.SelectionLineColor;
                lineAlpha = obj.SelectionLineAlpha;
                lineWidth = obj.ActiveLineWidth;
            elseif obj.Active
                lineColor = obj.ActiveLineColor;
                lineAlpha = obj.ActiveLineAlpha;
                lineWidth = obj.ActiveLineWidth;
            elseif obj.Selected
                lineColor = obj.SelectionLineColor;
                lineAlpha = obj.SelectionLineAlpha;
                lineWidth = obj.SelectionLineWidth;
            else
                lineColor = obj.LineColor;
                lineAlpha = obj.LineAlpha;
                lineWidth = obj.LineWidth;
            end
        end

        function [x,y] = hitPatchCoordinates(obj, p1, p2)
        %HITPATCHCOORDINATES Return a transparent pickable strip around the line.
            d = p2 - p1;
            len = hypot(d(1), d(2));

            if len <= eps || any(isnan([p1,p2]))
                x = [NaN NaN NaN NaN];
                y = [NaN NaN NaN NaN];
                return
            end

            n = [-d(2), d(1)] ./ len;
            offset = n .* (obj.HitAreaWidth / 2);
            xy = [p1 + offset; p2 + offset; p2 - offset; p1 - offset];

            x = xy(:,1).';
            y = xy(:,2).';
        end
    end

    methods (Static, Access=private)
        function color = rgba(rgb, alpha)
        %RGBA Return an RGB/RGBA color with requested alpha.
            color = double(rgb);
            color = color(:).';

            if numel(color) >= 4
                color = color(1:4);
                color(4) = alpha;
            else
                color = [color(1:3), alpha];
            end
        end

    end
end
