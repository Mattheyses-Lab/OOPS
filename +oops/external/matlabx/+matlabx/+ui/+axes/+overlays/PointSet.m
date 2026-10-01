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

classdef PointSet < matlabx.ui.axes.ImageAxesOverlay
%POINTSET Display a set of point coordinates on ImageAxes.
%
%   overlays.PointSet is a lightweight, display-oriented overlay for
%   rendering arbitrary N-by-2 [x y] point coordinates. It is intended for
%   stages such as puncta detection previews, where the user mostly needs to
%   see candidate points over an image without adding interaction behavior.
%
%   Syntax:
%
%       points = matlabx.image.measure.detectPoints(I);
%       ov = ax.Overlays.add("PointSet", "Points", points);
%
%       ov.Marker = "o";
%       ov.MarkerFaceColor = "none";
%       ov.MarkerEdgeColor = [1 1 0];
%       ov.MarkerSize = 5;
%
%   The point markers are drawn with one matlab.graphics.primitive.Line
%   object whose LineStyle is "none". Optional labels are drawn as separate
%   text objects. All graphics have HitTest off by default so this overlay
%   does not interfere with ImageAxes tools.

    properties (SetObservable, AbortSet)
        % N-by-2 [x y] point coordinates in image data units.
        Points (:,2) double = zeros(0,2)

        % Optional one label per point. Empty means no per-point label text.
        PointLabels (1,:) string = string.empty(1,0)

        % Function assigned to marker ButtonDownFcn when HitTest is enabled.
        ButtonDownFcn = []
    end

    properties (SetObservable, AbortSet)
        % Point marker appearance.
        Marker (1,:) char = 'o'
        MarkerSize (1,1) double {mustBePositive} = 5
        MarkerEdgeColor = [1 1 0]
        MarkerFaceColor = 'none'

        % Optional text label appearance.
        ShowLabels (1,1) matlab.lang.OnOffSwitchState = "off"
        LabelColor = [1 1 1]
        LabelBackgroundColor = [0 0 0]
        LabelFontSize (1,1) double {mustBePositive} = 9

        % Keep detection previews passive by default.
        HitTest (1,1) matlab.lang.OnOffSwitchState = "off"
        PickableParts (1,:) char {mustBeMember(PickableParts,{'visible','all','none'})} = 'none'
    end

    properties (Access=private, Transient, NonCopyable)
        PointLine (1,1) matlab.graphics.primitive.Line
        TextLabels matlab.graphics.primitive.Text = matlab.graphics.primitive.Text.empty()
        L event.listener = event.listener.empty()
        PendingGeometryUpdate (1,1) logical = false
        PendingLabelUpdate (1,1) logical = false
    end

    methods
        function obj = PointSet(host, opts)
        %POINTSET Create a point-set overlay on the host image axes.
            arguments
                host matlabx.ui.axes.ImageAxes
                opts.Points (:,2) double = zeros(0,2)
                opts.PointLabels (1,:) string = string.empty(1,0)
                opts.ButtonDownFcn = []
                opts.ID (1,1) string = ""
                opts.Label (1,1) string = ""
                opts.C = "all"
                opts.Z = "all"
                opts.T = "all"
                opts.UserData = []
                opts.Visible (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.Marker (1,:) char = 'o'
                opts.MarkerSize (1,1) double {mustBePositive} = 5
                opts.MarkerEdgeColor = [1 1 0]
                opts.MarkerFaceColor = 'none'
                opts.ShowLabels (1,1) matlab.lang.OnOffSwitchState = "off"
                opts.LabelColor = [1 1 1]
                opts.LabelBackgroundColor = [0 0 0]
                opts.LabelFontSize (1,1) double {mustBePositive} = 9
                opts.HitTest (1,1) matlab.lang.OnOffSwitchState = "off"
                opts.PickableParts (1,:) char {mustBeMember(opts.PickableParts,{'visible','all','none'})} = 'none'
            end

            obj@matlabx.ui.axes.ImageAxesOverlay(host, ...
                "ID", opts.ID, ...
                "Type", "PointSet", ...
                "Label", opts.Label, ...
                "C", opts.C, ...
                "Z", opts.Z, ...
                "T", opts.T, ...
                "UserData", opts.UserData, ...
                "Visible", opts.Visible);

            ax = obj.TargetAxes;
            obj.PointLine = line(ax, ...
                "XData", NaN, ...
                "YData", NaN, ...
                "LineStyle", "none", ...
                "Marker", opts.Marker, ...
                "MarkerSize", opts.MarkerSize, ...
                "MarkerEdgeColor", opts.MarkerEdgeColor, ...
                "MarkerFaceColor", opts.MarkerFaceColor, ...
                "HitTest", opts.HitTest, ...
                "PickableParts", opts.PickableParts, ...
                "Tag", "OverlayPointSet");

            obj.registerGraphics(obj.PointLine);

            obj.Points = opts.Points;
            obj.PointLabels = opts.PointLabels;
            obj.ButtonDownFcn = opts.ButtonDownFcn;
            obj.Marker = opts.Marker;
            obj.MarkerSize = opts.MarkerSize;
            obj.MarkerEdgeColor = opts.MarkerEdgeColor;
            obj.MarkerFaceColor = opts.MarkerFaceColor;
            obj.ShowLabels = opts.ShowLabels;
            obj.LabelColor = opts.LabelColor;
            obj.LabelBackgroundColor = opts.LabelBackgroundColor;
            obj.LabelFontSize = opts.LabelFontSize;
            obj.HitTest = opts.HitTest;
            obj.PickableParts = opts.PickableParts;

            geomProps = {'Points', 'ButtonDownFcn', 'HitTest', 'PickableParts'};
            labelProps = {'Points', 'PointLabels', 'ShowLabels', ...
                'LabelColor', 'LabelBackgroundColor', 'LabelFontSize'};
            appProps = {'Marker', 'MarkerSize', 'MarkerEdgeColor', 'MarkerFaceColor'};

            obj.L(1) = addlistener(obj, geomProps, 'PostSet', @(~,~) obj.queueGeometryUpdate());
            obj.L(2) = addlistener(obj, labelProps, 'PostSet', @(~,~) obj.queueLabelUpdate());
            obj.L(3) = addlistener(obj, appProps, 'PostSet', @(~,~) obj.updateAppearance());

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
        %UPDATEGEOMETRY Update marker coordinates and basic hit behavior.
            if isempty(obj.PointLine) || ~isgraphics(obj.PointLine)
                return
            end

            if isempty(obj.Points)
                set(obj.PointLine, "XData", NaN, "YData", NaN);
            else
                set(obj.PointLine, ...
                    "XData", obj.Points(:,1), ...
                    "YData", obj.Points(:,2));
            end

            obj.PointLine.HitTest = obj.HitTest;
            obj.PointLine.PickableParts = obj.PickableParts;
            obj.PointLine.ButtonDownFcn = obj.ButtonDownFcn;
        end

        function updateAppearance(obj)
        %UPDATEAPPEARANCE Apply marker appearance properties.
            if isempty(obj.PointLine) || ~isgraphics(obj.PointLine)
                return
            end

            obj.PointLine.LineStyle = "none";
            obj.PointLine.Marker = obj.Marker;
            obj.PointLine.MarkerSize = obj.MarkerSize;
            obj.PointLine.MarkerEdgeColor = obj.MarkerEdgeColor;
            obj.PointLine.MarkerFaceColor = obj.MarkerFaceColor;
        end

        function refresh(obj)
        %REFRESH Update point graphics, label graphics, and visibility.
            refresh@matlabx.ui.axes.ImageAxesOverlay(obj);
            obj.updateLabels();
        end
    end

    methods (Access=private)
        function queueGeometryUpdate(obj)
        %QUEUEGEOMETRYUPDATE Coalesce marker coordinate updates.
            if obj.PendingGeometryUpdate
                return
            end

            obj.PendingGeometryUpdate = true;
            drawnow limitrate nocallbacks
            obj.updateGeometry();
            obj.PendingGeometryUpdate = false;
        end

        function queueLabelUpdate(obj)
        %QUEUELABELUPDATE Coalesce label rebuilds during property changes.
            if obj.PendingLabelUpdate
                return
            end

            obj.PendingLabelUpdate = true;
            drawnow limitrate nocallbacks
            obj.updateLabels();
            obj.PendingLabelUpdate = false;
        end

        function updateLabels(obj)
        %UPDATELABELS Rebuild optional per-point text labels.
            obj.deleteLabelGraphics();

            if obj.ShowLabels == "off" || isempty(obj.Points)
                return
            end

            labels = obj.normalizedPointLabels();
            if isempty(labels)
                return
            end

            obj.TextLabels = matlab.graphics.primitive.Text.empty();
            for i = 1:size(obj.Points,1)
                obj.TextLabels(i,1) = text("Parent", obj.TargetAxes, ...
                    "Units", "data", ...
                    "Position", [obj.Points(i,1) obj.Points(i,2)], ...
                    "String", labels(i), ...
                    "Color", obj.LabelColor, ...
                    "BackgroundColor", obj.LabelBackgroundColor, ...
                    "FontSize", obj.LabelFontSize, ...
                    "Margin", 2, ...
                    "HorizontalAlignment", "left", ...
                    "VerticalAlignment", "bottom", ...
                    "HitTest", "off", ...
                    "PickableParts", "none", ...
                    "Tag", "OverlayPointSetLabel");
            end

            obj.registerGraphics(obj.TextLabels);
            obj.updateVisibility();
        end

        function deleteLabelGraphics(obj)
        %DELETELABELGRAPHICS Delete existing text labels only.
            if isempty(obj.TextLabels)
                return
            end

            h = obj.TextLabels(isgraphics(obj.TextLabels));
            if ~isempty(h)
                delete(h);
            end
            obj.TextLabels = matlab.graphics.primitive.Text.empty();
        end

        function labels = normalizedPointLabels(obj)
        %NORMALIZEDPOINTLABELS Return one text label per point.
            labels = string(obj.PointLabels);

            if isempty(labels)
                labels = string.empty(1,0);
                return
            end

            labels = labels(:);
            if numel(labels) ~= size(obj.Points,1)
                error("matlabx:ui:axes:overlays:PointSet:InvalidPointLabels", ...
                    "PointLabels must be empty or contain one label per point.");
            end
        end
    end
end
