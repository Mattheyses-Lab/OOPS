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
%POLYGON Polygon region with optional holes in image coordinates.
%
%   Vertices is an N-by-2 [x y] array. Separate boundary loops with [NaN NaN]
%   rows to represent holes or disconnected parts of the same selectable region.
%   Geometry is normalized by polyshape. Tools own interaction policy.

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
        Shape (1,1) polyshape = polyshape()
    end

    properties (Access=private, Transient, NonCopyable)
        FillPatch = []
        BoundaryLine = []
        L event.listener = event.listener.empty()
    end

    methods
        function obj = Polygon(host, opts)
        %POLYGON Create one selectable region, including all its boundary loops.
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

            % Triangulate only the fill; a separate line avoids internal edges.
            % PickableParts=all keeps unfilled interiors clickable, excluding holes.
            obj.FillPatch = patch(obj.TargetAxes, ...
                'Faces', [], 'Vertices', zeros(0,2), ...
                'FaceColor', opts.FaceColor, 'FaceAlpha', opts.FaceAlpha, ...
                'EdgeColor', 'none', 'HitTest', 'on', 'PickableParts', 'all', ...
                'Tag', 'OverlayPolygonFill');
            obj.BoundaryLine = line(obj.TargetAxes, NaN, NaN, ...
                'Color', opts.EdgeColor, 'HitTest', 'on', 'PickableParts', 'all', ...
                'Tag', 'OverlayPolygonBoundary');
            obj.registerGraphics([obj.FillPatch; obj.BoundaryLine]);
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

        function value = get.Vertices(obj), value = obj.Shape.Vertices; end

        function set.Vertices(obj, value)
            validateattributes(value, {'double'}, {'2d','ncols',2,'real'});
            if any(isinf(value(:))) || any(xor(isnan(value(:,1)), isnan(value(:,2))))
                error('matlabx:ui:axes:Polygon:InvalidVertices', ...
                    'Vertices must contain finite coordinates or NaN separator rows.');
            end
            shape = polyshape(value);
            obj.Shape = shape;
            obj.updateGeometry();
        end

        function value = get.Center(obj)
            [x,y] = centroid(obj.Shape);
            value = [x y];
        end

        function updateGeometry(obj)
            if isempty(obj.FillPatch) || ~isgraphics(obj.FillPatch), return; end
            if isempty(obj.Shape.Vertices)
                set(obj.FillPatch, 'Faces', [], 'Vertices', zeros(0,2));
                set(obj.BoundaryLine, 'XData', NaN, 'YData', NaN);
                return
            end
            mesh = triangulation(obj.Shape);
            set(obj.FillPatch, 'Faces', mesh.ConnectivityList, 'Vertices', mesh.Points);
            [x,y] = boundary(obj.Shape);
            set(obj.BoundaryLine, 'XData', x, 'YData', y);
        end

        function updateAppearance(obj)
            if isempty(obj.FillPatch) || ~isgraphics(obj.FillPatch), return; end
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
            set(obj.FillPatch, 'FaceColor', obj.FaceColor, 'FaceAlpha', alpha);
            set(obj.BoundaryLine, 'Color', obj.EdgeColor, 'LineWidth', width);
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
