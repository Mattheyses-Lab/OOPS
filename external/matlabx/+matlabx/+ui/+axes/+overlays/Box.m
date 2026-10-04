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

classdef Box < matlabx.ui.axes.ImageAxesOverlay
%BOX Square box overlay for ImageAxes image-space annotations.
%
%   overlays.Box owns a patch and optional text label. It knows its own
%   center, size, ID, C/Z/T applicability, and visual state. Tools decide
%   what user interactions mean.

    properties (SetObservable, AbortSet)
        Center (1,2) double = [NaN NaN]
        BoxSize (1,1) double {mustBePositive} = 50
        ButtonDownFcn = []
        FontSize (1,1) double = 10
    end

    properties (SetObservable, AbortSet)
        FaceColor = [1 1 1]
        EdgeColor = [1 1 1]

        LineWidth = 0.5
        HoverLineWidth = 2
        SelectionLineWidth = 1
        ActiveLineWidth = 2

        FaceAlpha = 0
        HoverFaceAlpha = 0.5
        SelectionFaceAlpha = 0.1
        ActiveFaceAlpha = 0
    end

    properties (Access=private, Transient, NonCopyable)
        BoxPatch (1,1) matlab.graphics.primitive.Patch
        BoxLabel (1,1) matlab.graphics.primitive.Text
        L event.listener = event.listener.empty()
        PendingUpdate (1,1) logical = false
    end

    methods
        function obj = Box(host, opts)
        %BOX Create a box overlay on the host image axes.
            arguments
                host matlabx.ui.axes.ImageAxes
                opts.Center (1,2) double = [NaN NaN]
                opts.BoxSize (1,1) double {mustBePositive} = 50
                opts.ButtonDownFcn = []
                opts.ID (1,1) string = ""
                opts.Label (1,1) string = ""
                opts.EdgeColor = [1 1 1]
                opts.FaceColor = [1 1 1]
                opts.FontSize (1,1) double = 10
                opts.C = "all"
                opts.Z = "all"
                opts.T = "all"
                opts.UserData = []
                opts.ActivateOnCreate (1,1) logical = false
            end

            obj@matlabx.ui.axes.ImageAxesOverlay(host, ...
                "ID", opts.ID, ...
                "Type", "Box", ...
                "Label", opts.Label, ...
                "C", opts.C, ...
                "Z", opts.Z, ...
                "T", opts.T, ...
                "UserData", opts.UserData, ...
                "ActivateOnCreate", opts.ActivateOnCreate);

            ax = obj.TargetAxes;
            obj.BoxPatch = patch(ax, ...
                'XData', NaN, ...
                'YData', NaN, ...
                'EdgeColor', obj.EdgeColor, ...
                'FaceColor', obj.FaceColor, ...
                'FaceAlpha', obj.FaceAlpha, ...
                'HitTest', 'on', ...
                'PickableParts', 'all', ...
                'LineWidth', obj.LineWidth, ...
                'Tag', 'OverlayBox');

            obj.BoxLabel = text('Parent', ax, ...
                'Units', 'data', ...
                'Position', [NaN NaN], ...
                'Color', [1 1 1], ...
                'BackgroundColor', 'none', ...
                'String', '', ...
                'FontSize', obj.FontSize, ...
                'Clipping', 'off', ...
                'Margin', 3, ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'top', ...
                'HitTest', 'off', ...
                'Tag', 'OverlayBoxLabel');

            obj.registerGraphics([obj.BoxPatch; obj.BoxLabel]);

            obj.Center = opts.Center;
            obj.BoxSize = opts.BoxSize;
            obj.ButtonDownFcn = opts.ButtonDownFcn;
            obj.EdgeColor = opts.EdgeColor;
            obj.FaceColor = opts.FaceColor;
            obj.FontSize = opts.FontSize;

            geomProps = {'Center', 'BoxSize', 'ButtonDownFcn'};
            appProps = { ...
                'Label', ...
                'FontSize', ...
                'FaceColor', ...
                'EdgeColor', ...
                'FaceAlpha', ...
                'HoverFaceAlpha', ...
                'SelectionFaceAlpha', ...
                'ActiveFaceAlpha', ...
                'LineWidth', ...
                'HoverLineWidth', ...
                'SelectionLineWidth', ...
                'ActiveLineWidth'};

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
        %UPDATEGEOMETRY Update patch and label coordinates from Center/BoxSize.
            if isempty(obj.BoxPatch) || ~isgraphics(obj.BoxPatch)
                return
            end

            c = obj.Center;
            s = obj.BoxSize/2;
            X = [c(1)-s c(1)+s c(1)+s c(1)-s];
            Y = [c(2)-s c(2)-s c(2)+s c(2)+s];

            set(obj.BoxPatch, 'XData', X, 'YData', Y);
            set(obj.BoxLabel, 'Position', [X(1) Y(1)]);

            if isempty(obj.ButtonDownFcn)
                obj.BoxPatch.ButtonDownFcn = [];
            else
                obj.BoxPatch.ButtonDownFcn = obj.ButtonDownFcn;
            end
        end

        function updateAppearance(obj)
        %UPDATEAPPEARANCE Update colors, label, and state highlighting.
            if isempty(obj.BoxPatch) || ~isgraphics(obj.BoxPatch)
                return
            end

            obj.BoxPatch.EdgeColor = obj.EdgeColor;
            obj.BoxPatch.FaceColor = obj.FaceColor;

            obj.BoxLabel.String = obj.Label;
            obj.BoxLabel.FontSize = obj.FontSize;

            if obj.Hovered
                obj.BoxPatch.LineWidth = obj.HoverLineWidth;
                obj.BoxPatch.FaceAlpha = obj.HoverFaceAlpha;
            elseif obj.Active && obj.Selected
                obj.BoxPatch.LineWidth = obj.ActiveLineWidth;
                obj.BoxPatch.FaceAlpha = obj.SelectionFaceAlpha;
            elseif obj.Active
                obj.BoxPatch.LineWidth = obj.ActiveLineWidth;
                obj.BoxPatch.FaceAlpha = obj.ActiveFaceAlpha;
            elseif obj.Selected
                obj.BoxPatch.LineWidth = obj.SelectionLineWidth;
                obj.BoxPatch.FaceAlpha = obj.SelectionFaceAlpha;
            else
                obj.BoxPatch.LineWidth = obj.LineWidth;
                obj.BoxPatch.FaceAlpha = obj.FaceAlpha;
            end
        end

        function tf = isInsideRectangle(obj, rect)
        %ISINSIDERECTANGLE True when box center lies inside rect.
            xy = obj.Center;
            tf = xy(1) >= rect(1) && xy(1) <= rect(2) ...
                && xy(2) >= rect(3) && xy(2) <= rect(4);
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
    end
end
