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

classdef Polygon < matlabx.ui.axes.ImageAxesOverlay
%POLYGON One closed loop drawn directly from application-supplied coordinates.
%
%   Vertices is a finite N-by-2 [x y] array in boundary order. The patch closes
%   the loop automatically; repeating the first vertex at the end is also OK.
%   Coordinates are stored unchanged. The app owns geometry correctness; this
%   overlay does not simplify, normalize, or repair contours or support holes.

    properties (Dependent, SetObservable, AbortSet)
        Vertices
    end

    properties (SetObservable, AbortSet)
        FaceColor = [1 1 1]
        EdgeColor = [1 1 1]
        FaceAlpha = 0
        HoverFaceAlpha = 0.15
        SelectionFaceAlpha = 0.1
        ActiveFaceAlpha = 0
        LineWidth = 0.5
        HoverLineWidth = 2
        SelectionLineWidth = 1
        ActiveLineWidth = 2
    end

    properties (SetAccess=private, Dependent)
        Center
    end

    properties (Access=private)
        Vertices_ (:,2) double = zeros(0,2)
    end

    properties (Access=private, Transient, NonCopyable)
        PolygonPatch = []
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
                opts.EdgeColor = [1 1 1]
                opts.FaceColor = [1 1 1]
                opts.FaceAlpha (1,1) double {mustBeInRange(opts.FaceAlpha,0,1)} = 0
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
                'EdgeColor', opts.EdgeColor, 'HitTest', 'on', 'PickableParts', 'all', ...
                'Tag', 'OverlayPolygon');
            obj.registerGraphics(obj.PolygonPatch);
            obj.FaceColor = opts.FaceColor;
            obj.EdgeColor = opts.EdgeColor;
            obj.FaceAlpha = opts.FaceAlpha;
            obj.Vertices = opts.Vertices;
            obj.L = addlistener(obj, ...
                {'FaceColor','EdgeColor','FaceAlpha','HoverFaceAlpha', ...
                'SelectionFaceAlpha','ActiveFaceAlpha','LineWidth', ...
                'HoverLineWidth','SelectionLineWidth','ActiveLineWidth'}, ...
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
        end

        function updateAppearance(obj)
            if isempty(obj.PolygonPatch) || ~isgraphics(obj.PolygonPatch), return; end
            if obj.Hovered
                width = obj.HoverLineWidth;
                alpha = obj.HoverFaceAlpha;
            elseif obj.Active && obj.Selected
                width = obj.ActiveLineWidth;
                alpha = obj.SelectionFaceAlpha;
            elseif obj.Active
                width = obj.ActiveLineWidth;
                alpha = obj.ActiveFaceAlpha;
            elseif obj.Selected
                width = obj.SelectionLineWidth;
                alpha = obj.SelectionFaceAlpha;
            else
                width = obj.LineWidth;
                alpha = obj.FaceAlpha;
            end
            set(obj.PolygonPatch, 'FaceColor', obj.FaceColor, 'FaceAlpha', alpha, ...
                'EdgeColor', obj.EdgeColor, 'LineWidth', width);
        end

        function tf = isInsideRectangle(obj, rect)
        %ISINSIDERECTANGLE Use the region centroid, like other centered overlays.
            xy = obj.Center;
            tf = obj.Visible == "on" && obj.ViewVisible == "on" ...
                && xy(1) >= rect(1) && xy(1) <= rect(2) ...
                && xy(2) >= rect(3) && xy(2) <= rect(4);
        end
    end
end
