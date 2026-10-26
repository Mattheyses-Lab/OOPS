classdef Polygon < matlabx.ui.axes.ImageAxesOverlay
%POLYGON One closed loop drawn directly from application-supplied coordinates.
%
%   Vertices is a finite N-by-2 [x y] array in boundary order. The patch closes
%   the loop automatically; repeating the first vertex at the end is also OK.
%   Coordinates are stored unchanged. The app owns geometry correctness; this
%   overlay does not simplify, normalize, or repair contours or support holes.

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

    properties (Dependent, SetObservable, AbortSet)
        Vertices
    end

    properties (SetObservable, AbortSet)
        % Normal polygon appearance.
        EdgeColor (1,3) double {mustBeBetween(EdgeColor,0,1)} = [1 1 1]
        EdgeAlpha (1,1) double {mustBeBetween(EdgeAlpha,0,1)} = 1
        FaceColor (1,3) double {mustBeBetween(FaceColor,0,1)} = [1 1 1]
        FaceAlpha (1,1) double {mustBeBetween(FaceAlpha,0,1)} = 0
        LineWidth (1,1) double {mustBePositive} = 1

        % Hover appearance.
        HoverEdgeColor = []
        HoverEdgeAlpha (1,1) double {mustBeBetween(HoverEdgeAlpha,0,1)} = 1
        HoverFaceColor = []
        HoverFaceAlpha (1,1) double {mustBeBetween(HoverFaceAlpha,0,1)} = 0
        HoverLineWidth (1,1) double {mustBePositive} = 1

        % Selection appearance.
        SelectionEdgeColor = [1 1 0]
        SelectionEdgeAlpha (1,1) double {mustBeBetween(SelectionEdgeAlpha,0,1)} = 1
        SelectionFaceColor = []
        SelectionFaceAlpha (1,1) double {mustBeBetween(SelectionFaceAlpha,0,1)} = 0
        SelectionLineWidth (1,1) double {mustBePositive} = 1

        % Active appearance.
        ActiveEdgeColor = []
        ActiveEdgeAlpha (1,1) double {mustBeBetween(ActiveEdgeAlpha,0,1)} = 1
        ActiveFaceColor = []
        ActiveFaceAlpha (1,1) double {mustBeBetween(ActiveFaceAlpha,0,1)} = 0
        ActiveLineWidth (1,1) double {mustBePositive} = 1

        % Vertex-handle appearance.
        HandleMarkerStyle (1,:) char = 's'
        HandleMarkerSize (1,1) double {mustBePositive} = 4
        HoverHandleMarkerSize (1,1) double {mustBePositive} = 5
        HandleMarkerLineWidth (1,1) double {mustBePositive} = 0.5
        HandleMarkerEdgeColor (1,3) double {mustBeBetween(HandleMarkerEdgeColor,0,1)} = [0 0 0]
        HandleMarkerFaceColor (1,3) double {mustBeBetween(HandleMarkerFaceColor,0,1)} = [1 1 1]
    end

    properties (SetAccess=private, Dependent)
        Center
    end

    properties (Access=private)
        Vertices_ (:,2) double = zeros(0,2)
    end

    properties (Access=private, Transient, NonCopyable)
        PolygonPatch = []
        HandleMarkerLine = []
        L event.listener = event.listener.empty()
    end

    methods
        function obj = Polygon(host, opts)
        %POLYGON Create one selectable closed loop.
            arguments
                host matlabx.ui.axes.ImageAxes
                opts.Vertices (:,2) double = zeros(0,2)
                opts.ID (1,1) string = ""
                opts.Label (1,1) string = ""
                opts.UserData = []
                opts.C = "all"
                opts.Z = "all"
                opts.T = "all"
                opts.Visible (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.ActivateOnCreate (1,1) logical = false
                opts.EdgeColor (1,3) double {mustBeBetween(opts.EdgeColor,0,1)} = [1 1 1]
                opts.EdgeAlpha (1,1) double {mustBeBetween(opts.EdgeAlpha,0,1)} = 1
                opts.FaceColor (1,3) double {mustBeBetween(opts.FaceColor,0,1)} = [1 1 1]
                opts.FaceAlpha (1,1) double {mustBeBetween(opts.FaceAlpha,0,1)} = 0
                opts.LineWidth (1,1) double {mustBePositive} = 1
                opts.HoverEdgeColor = []
                opts.HoverEdgeAlpha (1,1) double {mustBeBetween(opts.HoverEdgeAlpha,0,1)} = 1
                opts.HoverFaceColor = []
                opts.HoverFaceAlpha (1,1) double {mustBeBetween(opts.HoverFaceAlpha,0,1)} = 0
                opts.HoverLineWidth (1,1) double {mustBePositive} = 1
                opts.SelectionEdgeColor = [1 1 0]
                opts.SelectionEdgeAlpha (1,1) double {mustBeBetween(opts.SelectionEdgeAlpha,0,1)} = 1
                opts.SelectionFaceColor = []
                opts.SelectionFaceAlpha (1,1) double {mustBeBetween(opts.SelectionFaceAlpha,0,1)} = 0
                opts.SelectionLineWidth (1,1) double {mustBePositive} = 1
                opts.ActiveEdgeColor = []
                opts.ActiveEdgeAlpha (1,1) double {mustBeBetween(opts.ActiveEdgeAlpha,0,1)} = 1
                opts.ActiveFaceColor = []
                opts.ActiveFaceAlpha (1,1) double {mustBeBetween(opts.ActiveFaceAlpha,0,1)} = 0
                opts.ActiveLineWidth (1,1) double {mustBePositive} = 1
                opts.HandleMarkerStyle (1,:) char = 's'
                opts.HandleMarkerSize (1,1) double {mustBePositive} = 4
                opts.HoverHandleMarkerSize (1,1) double {mustBePositive} = 5
                opts.HandleMarkerLineWidth (1,1) double {mustBePositive} = 0.5
                opts.HandleMarkerEdgeColor (1,3) double {mustBeBetween(opts.HandleMarkerEdgeColor,0,1)} = [0 0 0]
                opts.HandleMarkerFaceColor (1,3) double {mustBeBetween(opts.HandleMarkerFaceColor,0,1)} = [1 1 1]
            end

            obj@matlabx.ui.axes.ImageAxesOverlay(host, ...
                "Type", "Polygon", "ID", opts.ID, "Label", opts.Label, ...
                "UserData", opts.UserData, "C", opts.C, "Z", opts.Z, "T", opts.T, ...
                "Visible", opts.Visible, "ActivateOnCreate", opts.ActivateOnCreate);

            % A single face supplies both fill and closed boundary. Keep the
            % interior pickable even when the default fill is transparent.
            obj.PolygonPatch = patch(obj.TargetAxes, ...
                'Faces', [], 'Vertices', zeros(0,2), ...
                'FaceColor', opts.FaceColor, 'FaceAlpha', opts.FaceAlpha, ...
                'EdgeColor', obj.rgba(opts.EdgeColor, opts.EdgeAlpha), ...
                'HitTest', 'on', 'PickableParts', 'all', ...
                'Tag', 'OverlayPolygon');

            % Draw every vertex with one marker primitive. The Polygon tool
            % resolves the nearest marker after this shared primitive is hit,
            % avoiding one graphics object per editable vertex.
            obj.HandleMarkerLine = line(obj.TargetAxes, ...
                'XData', NaN, 'YData', NaN, 'LineStyle', 'none', ...
                'Marker', opts.HandleMarkerStyle, 'MarkerSize', opts.HandleMarkerSize, ...
                'MarkerEdgeColor', opts.HandleMarkerEdgeColor, ...
                'MarkerFaceColor', opts.HandleMarkerFaceColor, ...
                'LineWidth', opts.HandleMarkerLineWidth, ...
                'HitTest', 'on', 'PickableParts', 'visible', ...
                'Visible', 'off', 'Tag', 'OverlayPolygonHandle');

            obj.registerGraphics([obj.PolygonPatch; obj.HandleMarkerLine]);
            obj.FaceColor = opts.FaceColor;
            obj.EdgeColor = opts.EdgeColor;
            obj.EdgeAlpha = opts.EdgeAlpha;
            obj.FaceAlpha = opts.FaceAlpha;
            obj.LineWidth = opts.LineWidth;
            obj.HoverFaceColor = opts.HoverFaceColor;
            obj.HoverEdgeColor = opts.HoverEdgeColor;
            obj.HoverEdgeAlpha = opts.HoverEdgeAlpha;
            obj.HoverFaceAlpha = opts.HoverFaceAlpha;
            obj.HoverLineWidth = opts.HoverLineWidth;
            obj.SelectionFaceColor = opts.SelectionFaceColor;
            obj.SelectionEdgeColor = opts.SelectionEdgeColor;
            obj.SelectionEdgeAlpha = opts.SelectionEdgeAlpha;
            obj.SelectionFaceAlpha = opts.SelectionFaceAlpha;
            obj.SelectionLineWidth = opts.SelectionLineWidth;
            obj.ActiveFaceColor = opts.ActiveFaceColor;
            obj.ActiveEdgeColor = opts.ActiveEdgeColor;
            obj.ActiveEdgeAlpha = opts.ActiveEdgeAlpha;
            obj.ActiveFaceAlpha = opts.ActiveFaceAlpha;
            obj.ActiveLineWidth = opts.ActiveLineWidth;
            obj.HandleMarkerStyle = opts.HandleMarkerStyle;
            obj.HandleMarkerSize = opts.HandleMarkerSize;
            obj.HoverHandleMarkerSize = opts.HoverHandleMarkerSize;
            obj.HandleMarkerLineWidth = opts.HandleMarkerLineWidth;
            obj.HandleMarkerEdgeColor = opts.HandleMarkerEdgeColor;
            obj.HandleMarkerFaceColor = opts.HandleMarkerFaceColor;
            obj.Vertices = opts.Vertices;
            obj.L = addlistener(obj, ...
                {'EdgeColor','EdgeAlpha','FaceColor','FaceAlpha','LineWidth', ...
                'HoverEdgeColor','HoverEdgeAlpha','HoverFaceColor','HoverFaceAlpha','HoverLineWidth', ...
                'SelectionEdgeColor','SelectionEdgeAlpha','SelectionFaceColor','SelectionFaceAlpha','SelectionLineWidth', ...
                'ActiveEdgeColor','ActiveEdgeAlpha','ActiveFaceColor','ActiveFaceAlpha','ActiveLineWidth', ...
                'HandleMarkerStyle','HandleMarkerSize','HoverHandleMarkerSize','HandleMarkerLineWidth', ...
                'HandleMarkerEdgeColor','HandleMarkerFaceColor'}, ...
                'PostSet', @(~,~) obj.updateAppearance());
            obj.refresh();
        end

        function delete(obj)
            for k = 1:numel(obj)
                delete(obj(k).L(isvalid(obj(k).L)));
                obj(k).deleteGraphics();
            end
        end

        function value = get.Vertices(obj), value = obj.Vertices_; end

        function set.Vertices(obj, value)
            validateattributes(value, {'double'}, {'2d','ncols',2,'real','finite'});
            if ~isempty(value) && size(value,1) < 3
                error('matlabx:ui:axes:Polygon:InvalidVertices', ...
                    'Vertices must be empty or contain at least three [x y] rows.');
            end
            obj.Vertices_ = value;
            obj.updateGeometry();
        end

        function value = get.Center(obj)
        %GET.CENTER Signed-area centroid, independent of winding direction.
            vertices = obj.Vertices_;
            if isempty(vertices)
                value = [NaN NaN];
                return
            end

            % Translate before the shoelace calculation to avoid cancellation
            % from a large coordinate offset. This does not alter stored data.
            origin = vertices(1,:);
            v = vertices - origin;
            next = v([2:end 1],:);
            cross = v(:,1).*next(:,2) - next(:,1).*v(:,2);
            twiceArea = sum(cross);
            if abs(twiceArea) <= eps(sum(abs(cross)))
                % A collapsed/zero-area loop has no area centroid. Use its
                % bounding-box center so selection still has a stable anchor.
                value = origin + (min(v,[],1) + max(v,[],1))/2;
            else
                value = origin + sum((v + next).*cross,1)/(3*twiceArea);
            end
        end

        function updateGeometry(obj)
        %UPDATEGEOMETRY Pass through vertices without normalization or repair.
            if isempty(obj.PolygonPatch) || ~isgraphics(obj.PolygonPatch), return; end
            faces = 1:size(obj.Vertices_,1);
            set(obj.PolygonPatch, 'Faces', faces, 'Vertices', obj.Vertices_);
            vertices = obj.Vertices_;
            if size(vertices,1) > 1 && isequal(vertices(1,:), vertices(end,:))
                vertices(end,:) = [];
            end
            if isempty(vertices)
                set(obj.HandleMarkerLine, 'XData', NaN, 'YData', NaN);
            else
                set(obj.HandleMarkerLine, ...
                    'XData', vertices(:,1), 'YData', vertices(:,2));
            end
        end

        function updateAppearance(obj)
            if isempty(obj.PolygonPatch) || ~isgraphics(obj.PolygonPatch), return; end
            if obj.Hovered
                width = obj.HoverLineWidth;
                alpha = obj.HoverFaceAlpha;
                edgeAlpha = obj.HoverEdgeAlpha;
            elseif obj.Active && obj.Selected
                width = obj.ActiveLineWidth;
                alpha = obj.SelectionFaceAlpha;
                edgeAlpha = obj.SelectionEdgeAlpha;
            elseif obj.Active
                width = obj.ActiveLineWidth;
                alpha = obj.ActiveFaceAlpha;
                edgeAlpha = obj.ActiveEdgeAlpha;
            elseif obj.Selected
                width = obj.SelectionLineWidth;
                alpha = obj.SelectionFaceAlpha;
                edgeAlpha = obj.SelectionEdgeAlpha;
            else
                width = obj.LineWidth;
                alpha = obj.FaceAlpha;
                edgeAlpha = obj.EdgeAlpha;
            end
            edgeColor = obj.resolveStateColor(obj.EdgeColor, obj.SelectionEdgeColor, ...
                obj.ActiveEdgeColor, obj.HoverEdgeColor, obj.Selected, obj.Active, obj.Hovered);
            faceColor = obj.resolveStateColor(obj.FaceColor, obj.SelectionFaceColor, ...
                obj.ActiveFaceColor, obj.HoverFaceColor, obj.Selected, obj.Active, obj.Hovered);
            set(obj.PolygonPatch, 'FaceColor', faceColor, 'FaceAlpha', alpha, ...
                'EdgeColor', obj.rgba(edgeColor, edgeAlpha), 'LineWidth', width);

            if obj.Hovered
                markerSize = obj.HoverHandleMarkerSize;
            else
                markerSize = obj.HandleMarkerSize;
            end
            set(obj.HandleMarkerLine, 'Marker', obj.HandleMarkerStyle, 'MarkerSize', markerSize, ...
                'MarkerEdgeColor', obj.HandleMarkerEdgeColor, ...
                'MarkerFaceColor', obj.HandleMarkerFaceColor, ...
                'LineWidth', obj.HandleMarkerLineWidth);
            obj.updateVisibility();
        end

        function tf = isInsideRectangle(obj, rect)
        %ISINSIDERECTANGLE Use the region centroid, like other centered overlays.
            xy = obj.Center;
            tf = obj.Visible == "on" && obj.ViewVisible == "on" ...
                && xy(1) >= rect(1) && xy(1) <= rect(2) ...
                && xy(2) >= rect(3) && xy(2) <= rect(4);
        end
    end

    methods (Access=protected)
        function updateVisibility(obj)
        %UPDATEVISIBILITY Apply polygon and vertex-handle visibility policy.
            if isempty(obj.PolygonPatch) || ~isgraphics(obj.PolygonPatch)
                return
            end

            effectiveVisible = obj.Visible == "on" && obj.ViewVisible == "on";
            obj.PolygonPatch.Visible = matlab.lang.OnOffSwitchState(effectiveVisible);
            obj.HandleMarkerLine.Visible = matlab.lang.OnOffSwitchState( ...
                effectiveVisible && (obj.Hovered || obj.Active));
        end
    end

    methods (Static, Access=private)
        function color = resolveStateColor(baseColor, selectionColor, activeColor, ...
                hoverColor, selected, active, hovered)
        %RESOLVESTATECOLOR Apply each defined color in state-precedence order.
            color = baseColor;
            if selected && ~isempty(selectionColor), color = selectionColor; end
            if active && ~isempty(activeColor), color = activeColor; end
            if hovered && ~isempty(hoverColor), color = hoverColor; end
        end

        function color = rgba(rgb, alpha)
        %RGBA Return an RGB/RGBA color with requested alpha.
            color = double(rgb);
            color = color(:).';
            if numel(color) >= 4
                color = color(1:4);
                color(4) = alpha;
            elseif alpha < 1
                color = [color(1:3), alpha];
            end
        end
    end
end
