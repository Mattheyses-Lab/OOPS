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

classdef PointClusters < matlabx.ui.axes.ImageAxesOverlay
%POINTCLUSTERS Display PointClusters analysis results on ImageAxes.
%
%   overlays.PointClusters is a display-only overlay for visualizing
%   matlabx.analysis.cluster.PointClusters results. It can render the live
%   current state of a PointClusters object or one of its recorded stage
%   snapshots.
%
%   Syntax:
%
%       ov = ax.Overlays.add("PointClusters", "ClusterData", C);
%       ov.StageName = "Initial";
%
%   Layers:
%       Original points
%           All input detections from C.OriginalPoints.
%       Clustered points
%           Points owned by each cluster, colored by cluster.
%       Hulls
%           Cluster hull patches.
%       Centroids
%           Cluster centroid markers.
%       Labels
%           Text labels using cluster index.
%       Noise/unclustered points
%           Points not assigned to live clusters in the selected stage.
%       Removed points
%           Points removed by point-refinement stages.
%       Removed cluster hulls
%           Hulls of clusters removed by cluster-filtering stages.
%
%   This overlay intentionally has minimal interaction behavior. It turns off
%   hit testing for all graphics so analysis visualization does not interfere
%   with image tools such as zoom, box, or line overlays.

    properties (SetObservable, AbortSet)
        ClusterData matlabx.analysis.cluster.PointClusters = matlabx.analysis.cluster.PointClusters.empty()
        Snapshot struct = struct()
        StageName (1,1) string = ""
    end

    properties (SetObservable, AbortSet)
        ShowOriginalPoints (1,1) matlab.lang.OnOffSwitchState = "on"
        ShowClusteredPoints (1,1) matlab.lang.OnOffSwitchState = "on"
        ShowHulls (1,1) matlab.lang.OnOffSwitchState = "on"
        ShowCentroids (1,1) matlab.lang.OnOffSwitchState = "on"
        ShowLabels (1,1) matlab.lang.OnOffSwitchState = "off"
        ShowNoisePoints (1,1) matlab.lang.OnOffSwitchState = "on"
        ShowRemovedPoints (1,1) matlab.lang.OnOffSwitchState = "on"
        ShowRemovedClusters (1,1) matlab.lang.OnOffSwitchState = "on"
    end

    properties (SetObservable, AbortSet)
        OriginalPointColor = [0.75 0.75 0.75]
        NoisePointColor = [1 1 1]
        RemovedPointColor = [1 0.25 0.25]
        RemovedClusterColor = [1 0.25 0.25]
        CentroidColor = [0 0 0]
        LabelColor = [1 1 1]
        LabelBackgroundColor = [0 0 0]

        OriginalPointMarker (1,:) char = 'x'
        ClusterPointMarker (1,:) char = 'o'
        NoisePointMarker (1,:) char = '.'
        RemovedPointMarker (1,:) char = '+'
        CentroidMarker (1,:) char = 'x'

        OriginalPointSize (1,1) double {mustBePositive} = 4
        ClusterPointSize (1,1) double {mustBePositive} = 4
        NoisePointSize (1,1) double {mustBePositive} = 8
        RemovedPointSize (1,1) double {mustBePositive} = 7
        CentroidSize (1,1) double {mustBePositive} = 8
        LabelFontSize (1,1) double {mustBePositive} = 9

        HullFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(HullFaceAlpha,0), mustBeLessThanOrEqual(HullFaceAlpha,1)} = 0.18
        HullEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(HullEdgeAlpha,0), mustBeLessThanOrEqual(HullEdgeAlpha,1)} = 0.85
        RemovedClusterFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(RemovedClusterFaceAlpha,0), mustBeLessThanOrEqual(RemovedClusterFaceAlpha,1)} = 0.06
        RemovedClusterEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(RemovedClusterEdgeAlpha,0), mustBeLessThanOrEqual(RemovedClusterEdgeAlpha,1)} = 0.8
        HullLineWidth (1,1) double {mustBePositive} = 1
    end

    properties (Access=private, Transient, NonCopyable)
        L event.listener = event.listener.empty()
        DrawnGraphics matlab.graphics.Graphics = matlab.graphics.Graphics.empty()
        PendingUpdate (1,1) logical = false
    end

    methods
        function obj = PointClusters(host, opts)
        %POINTCLUSTERS Create a cluster-results overlay.
            arguments
                host matlabx.ui.axes.ImageAxes
                opts.ClusterData matlabx.analysis.cluster.PointClusters = matlabx.analysis.cluster.PointClusters.empty()
                opts.Snapshot struct = struct()
                opts.StageName (1,1) string = ""
                opts.ID (1,1) string = ""
                opts.Label (1,1) string = ""
                opts.C = "all"
                opts.Z = "all"
                opts.T = "all"
                opts.UserData = []
                opts.ShowOriginalPoints (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.ShowClusteredPoints (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.ShowHulls (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.ShowCentroids (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.ShowLabels (1,1) matlab.lang.OnOffSwitchState = "off"
                opts.ShowNoisePoints (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.ShowRemovedPoints (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.ShowRemovedClusters (1,1) matlab.lang.OnOffSwitchState = "on"
                opts.OriginalPointColor = [0.75 0.75 0.75]
                opts.NoisePointColor = [1 1 1]
                opts.RemovedPointColor = [1 0.25 0.25]
                opts.RemovedClusterColor = [1 0.25 0.25]
                opts.CentroidColor = [0 0 0]
                opts.LabelColor = [1 1 1]
                opts.LabelBackgroundColor = [0 0 0]
                opts.OriginalPointSize (1,1) double {mustBePositive} = 4
                opts.ClusterPointSize (1,1) double {mustBePositive} = 4
                opts.NoisePointSize (1,1) double {mustBePositive} = 8
                opts.RemovedPointSize (1,1) double {mustBePositive} = 7
                opts.CentroidSize (1,1) double {mustBePositive} = 8
                opts.LabelFontSize (1,1) double {mustBePositive} = 9
                opts.HullFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(opts.HullFaceAlpha,0), mustBeLessThanOrEqual(opts.HullFaceAlpha,1)} = 0.18
                opts.HullEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(opts.HullEdgeAlpha,0), mustBeLessThanOrEqual(opts.HullEdgeAlpha,1)} = 0.85
                opts.RemovedClusterFaceAlpha (1,1) double {mustBeGreaterThanOrEqual(opts.RemovedClusterFaceAlpha,0), mustBeLessThanOrEqual(opts.RemovedClusterFaceAlpha,1)} = 0.06
                opts.RemovedClusterEdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(opts.RemovedClusterEdgeAlpha,0), mustBeLessThanOrEqual(opts.RemovedClusterEdgeAlpha,1)} = 0.8
                opts.HullLineWidth (1,1) double {mustBePositive} = 1
            end

            obj@matlabx.ui.axes.ImageAxesOverlay(host, ...
                "ID", opts.ID, ...
                "Type", "PointClusters", ...
                "Label", opts.Label, ...
                "C", opts.C, ...
                "Z", opts.Z, ...
                "T", opts.T, ...
                "UserData", opts.UserData);

            obj.ClusterData = opts.ClusterData;
            obj.Snapshot = opts.Snapshot;
            obj.StageName = opts.StageName;
            obj.ShowOriginalPoints = opts.ShowOriginalPoints;
            obj.ShowClusteredPoints = opts.ShowClusteredPoints;
            obj.ShowHulls = opts.ShowHulls;
            obj.ShowCentroids = opts.ShowCentroids;
            obj.ShowLabels = opts.ShowLabels;
            obj.ShowNoisePoints = opts.ShowNoisePoints;
            obj.ShowRemovedPoints = opts.ShowRemovedPoints;
            obj.ShowRemovedClusters = opts.ShowRemovedClusters;
            obj.OriginalPointColor = opts.OriginalPointColor;
            obj.NoisePointColor = opts.NoisePointColor;
            obj.RemovedPointColor = opts.RemovedPointColor;
            obj.RemovedClusterColor = opts.RemovedClusterColor;
            obj.CentroidColor = opts.CentroidColor;
            obj.LabelColor = opts.LabelColor;
            obj.LabelBackgroundColor = opts.LabelBackgroundColor;
            obj.OriginalPointSize = opts.OriginalPointSize;
            obj.ClusterPointSize = opts.ClusterPointSize;
            obj.NoisePointSize = opts.NoisePointSize;
            obj.RemovedPointSize = opts.RemovedPointSize;
            obj.CentroidSize = opts.CentroidSize;
            obj.LabelFontSize = opts.LabelFontSize;
            obj.HullFaceAlpha = opts.HullFaceAlpha;
            obj.HullEdgeAlpha = opts.HullEdgeAlpha;
            obj.RemovedClusterFaceAlpha = opts.RemovedClusterFaceAlpha;
            obj.RemovedClusterEdgeAlpha = opts.RemovedClusterEdgeAlpha;
            obj.HullLineWidth = opts.HullLineWidth;

            dataProps = {'ClusterData', 'Snapshot', 'StageName'};
            layerProps = { ...
                'ShowOriginalPoints', ...
                'ShowClusteredPoints', ...
                'ShowHulls', ...
                'ShowCentroids', ...
                'ShowLabels', ...
                'ShowNoisePoints', ...
                'ShowRemovedPoints', ...
                'ShowRemovedClusters', ...
                'OriginalPointColor', ...
                'NoisePointColor', ...
                'RemovedPointColor', ...
                'RemovedClusterColor', ...
                'CentroidColor', ...
                'LabelColor', ...
                'LabelBackgroundColor', ...
                'OriginalPointMarker', ...
                'ClusterPointMarker', ...
                'NoisePointMarker', ...
                'RemovedPointMarker', ...
                'CentroidMarker', ...
                'OriginalPointSize', ...
                'ClusterPointSize', ...
                'NoisePointSize', ...
                'RemovedPointSize', ...
                'CentroidSize', ...
                'LabelFontSize', ...
                'HullFaceAlpha', ...
                'HullEdgeAlpha', ...
                'RemovedClusterFaceAlpha', ...
                'RemovedClusterEdgeAlpha', ...
                'HullLineWidth'};

            obj.L(1) = addlistener(obj, dataProps, 'PostSet', @(~,~) obj.queueRebuild());
            obj.L(2) = addlistener(obj, layerProps, 'PostSet', @(~,~) obj.queueRebuild());

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
        %UPDATEGEOMETRY Rebuild all cluster visualization graphics.
            obj.deleteDrawnGraphics();
            S = obj.currentSnapshot();
            if isempty(fieldnames(S))
                obj.updateVisibility();
                return
            end

            ax = obj.TargetAxes;
            holdState = ishold(ax);
            hold(ax, "on");

            colors = obj.clusterColors(S);
            handles = matlab.graphics.Graphics.empty();

            handles = [handles; obj.drawRemovedClusterHulls(ax, S)];
            handles = [handles; obj.drawHulls(ax, S, colors)];
            handles = [handles; obj.drawOriginalPoints(ax, S)];
            handles = [handles; obj.drawNoisePoints(ax, S)];
            handles = [handles; obj.drawRemovedPoints(ax, S)];
            handles = [handles; obj.drawClusteredPoints(ax, S, colors)];
            handles = [handles; obj.drawCentroids(ax, S)];
            handles = [handles; obj.drawLabels(ax, S)];

            if ~holdState
                hold(ax, "off");
            end

            obj.DrawnGraphics = handles(isgraphics(handles));
            obj.registerGraphics(obj.DrawnGraphics);
            obj.updateVisibility();
        end

        function updateAppearance(obj)
        %UPDATEAPPEARANCE Rebuild graphics after state or appearance changes.
            obj.updateGeometry();
        end
    end

    methods (Access=protected)
        function updateVisibility(obj)
        %UPDATEVISIBILITY Apply overlay visibility to current drawn graphics.
            if isempty(obj.DrawnGraphics)
                return
            end

            h = obj.DrawnGraphics(isgraphics(obj.DrawnGraphics));
            if isempty(h)
                return
            end

            effectiveVisible = obj.Visible == "on" && obj.ViewVisible == "on";
            set(h, "Visible", matlab.lang.OnOffSwitchState(effectiveVisible));
        end
    end

    methods (Access=private)
        function queueRebuild(obj)
        %QUEUEREBUILD Coalesce repeated property-driven redraws.
            if obj.PendingUpdate
                return
            end

            obj.PendingUpdate = true;
            drawnow limitrate nocallbacks
            obj.updateGeometry();
            obj.PendingUpdate = false;
        end

        function deleteDrawnGraphics(obj)
        %DELETEDRAWNGRAPHICS Delete graphics from the previous redraw.
            if isempty(obj.DrawnGraphics)
                return
            end

            h = obj.DrawnGraphics(isgraphics(obj.DrawnGraphics));
            if ~isempty(h)
                delete(h);
            end

            obj.DrawnGraphics = matlab.graphics.Graphics.empty();
        end

        function S = currentSnapshot(obj)
        %CURRENTSNAPSHOT Return selected stage snapshot or live cluster state.
            if ~isempty(fieldnames(obj.Snapshot))
                S = obj.Snapshot;
                return
            end

            if isempty(obj.ClusterData) || ~isvalid(obj.ClusterData)
                S = struct();
                return
            end

            if strlength(obj.StageName) > 0
                S = obj.ClusterData.getStageSnapshot(obj.StageName);
                return
            end

            S = obj.liveSnapshot(obj.ClusterData);
        end

        function S = liveSnapshot(~, C)
        %LIVESNAPSHOT Convert a live PointClusters object into snapshot shape.
            S = struct( ...
                "Stage", C.CurrentStage, ...
                "OriginalPoints", C.OriginalPoints, ...
                "NoisePoints", C.NoisePoints, ...
                "Points", C.Points, ...
                "ClusterIdxs", C.ClusterIdxs, ...
                "Centroids", C.Centroids, ...
                "UnclusteredPoints", C.UnclusteredPoints, ...
                "Summary", C.Summary, ...
                "ClusterPoints", {arrayfun(@(ck) ck.Points, C.Clusters(:), 'UniformOutput', false)}, ...
                "ClusterHulls", {arrayfun(@(ck) ck.Hull, C.Clusters(:), 'UniformOutput', false)}, ...
                "RemovedPointLog", C.RemovedPointLog, ...
                "RemovedClusterLog", C.RemovedClusterLog);
        end

        function colors = clusterColors(~, S)
        %CLUSTERCOLORS Return one RGB row per cluster in snapshot S.
            n = 0;
            if isfield(S, "ClusterPoints")
                n = numel(S.ClusterPoints);
            elseif isfield(S, "Centroids")
                n = size(S.Centroids,1);
            end

            if n == 0
                colors = zeros(0,3);
            else
                colors = lines(n);
            end
        end

        function h = drawOriginalPoints(obj, ax, S)
        %DRAWORIGINALPOINTS Draw all input detections.
            h = matlab.graphics.Graphics.empty();
            if obj.ShowOriginalPoints == "off" || ~isfield(S,"OriginalPoints")
                return
            end

            pts = S.OriginalPoints;
            if isempty(pts), return; end

            h = plot(ax, pts(:,1), pts(:,2), ...
                "LineStyle", "none", ...
                "Marker", obj.OriginalPointMarker, ...
                "MarkerEdgeColor", obj.OriginalPointColor, ...
                "MarkerSize", obj.OriginalPointSize, ...
                "HitTest", "off", ...
                "PickableParts", "none", ...
                "Tag", "OverlayPointClustersOriginalPoints");
        end

        function h = drawClusteredPoints(obj, ax, S, colors)
        %DRAWCLUSTEREDPOINTS Draw cluster-owned points, colored per cluster.
            h = matlab.graphics.Graphics.empty();
            if obj.ShowClusteredPoints == "off" || ~isfield(S,"ClusterPoints")
                return
            end

            for i = 1:numel(S.ClusterPoints)
                pts = S.ClusterPoints{i};
                if isempty(pts), continue; end

                h(end+1,1) = plot(ax, pts(:,1), pts(:,2), ...
                    "LineStyle", "none", ...
                    "Marker", obj.ClusterPointMarker, ...
                    "MarkerFaceColor", colors(i,:), ...
                    "MarkerEdgeColor", [1 1 1], ...
                    "MarkerSize", obj.ClusterPointSize, ...
                    "HitTest", "off", ...
                    "PickableParts", "none", ...
                    "Tag", "OverlayPointClustersClusterPoints"); %#ok<AGROW>
            end
        end

        function h = drawHulls(obj, ax, S, colors)
        %DRAWHULLS Draw cluster hull patches.
            h = matlab.graphics.Graphics.empty();
            if obj.ShowHulls == "off" || ~isfield(S,"ClusterHulls")
                return
            end

            for i = 1:numel(S.ClusterHulls)
                hull = S.ClusterHulls{i};
                if isempty(hull), continue; end

                h(end+1,1) = patch(ax, ...
                    "XData", hull(:,1), ...
                    "YData", hull(:,2), ...
                    "FaceColor", colors(i,:), ...
                    "EdgeColor", colors(i,:), ...
                    "EdgeAlpha", obj.HullEdgeAlpha, ...
                    "FaceAlpha", obj.HullFaceAlpha, ...
                    "LineWidth", obj.HullLineWidth, ...
                    "HitTest", "off", ...
                    "PickableParts", "none", ...
                    "Tag", "OverlayPointClustersHull"); %#ok<AGROW>
            end
        end

        function h = drawCentroids(obj, ax, S)
        %DRAWCENTROIDS Draw cluster centroid markers.
            h = matlab.graphics.Graphics.empty();
            if obj.ShowCentroids == "off" || ~isfield(S,"Centroids")
                return
            end

            pts = S.Centroids;
            if isempty(pts), return; end

            h = plot(ax, pts(:,1), pts(:,2), ...
                "LineStyle", "none", ...
                "Marker", obj.CentroidMarker, ...
                "MarkerEdgeColor", obj.CentroidColor, ...
                "MarkerSize", obj.CentroidSize, ...
                "LineWidth", 1.5, ...
                "HitTest", "off", ...
                "PickableParts", "none", ...
                "Tag", "OverlayPointClustersCentroids");
        end

        function h = drawLabels(obj, ax, S)
        %DRAWLABELS Draw cluster ID labels at centroids.
            h = matlab.graphics.Graphics.empty();
            if obj.ShowLabels == "off" || ~isfield(S,"Centroids")
                return
            end

            pts = S.Centroids;
            for i = 1:size(pts,1)
                h(end+1,1) = text(ax, pts(i,1), pts(i,2), string(i), ...
                    "Color", obj.LabelColor, ...
                    "BackgroundColor", obj.LabelBackgroundColor, ...
                    "FontSize", obj.LabelFontSize, ...
                    "HorizontalAlignment", "center", ...
                    "VerticalAlignment", "middle", ...
                    "Margin", 2, ...
                    "HitTest", "off", ...
                    "PickableParts", "none", ...
                    "Tag", "OverlayPointClustersLabel"); %#ok<AGROW>
            end
        end

        function h = drawNoisePoints(obj, ax, S)
        %DRAWNOISEPOINTS Draw unclustered/noise points.
            h = matlab.graphics.Graphics.empty();
            if obj.ShowNoisePoints == "off"
                return
            end

            pts = zeros(0,2);
            if isfield(S,"UnclusteredPoints")
                pts = S.UnclusteredPoints;
            elseif isfield(S,"NoisePoints")
                pts = S.NoisePoints;
            end

            if isempty(pts), return; end

            h = plot(ax, pts(:,1), pts(:,2), ...
                "LineStyle", "none", ...
                "Marker", obj.NoisePointMarker, ...
                "MarkerEdgeColor", obj.NoisePointColor, ...
                "MarkerSize", obj.NoisePointSize, ...
                "HitTest", "off", ...
                "PickableParts", "none", ...
                "Tag", "OverlayPointClustersNoisePoints");
        end

        function h = drawRemovedPoints(obj, ax, S)
        %DRAWREMOVEDPOINTS Draw points removed during refinement.
            h = matlab.graphics.Graphics.empty();
            if obj.ShowRemovedPoints == "off" || ~isfield(S,"RemovedPointLog")
                return
            end

            T = S.RemovedPointLog;
            if isempty(T) || height(T) == 0, return; end

            h = plot(ax, T.X, T.Y, ...
                "LineStyle", "none", ...
                "Marker", obj.RemovedPointMarker, ...
                "MarkerEdgeColor", obj.RemovedPointColor, ...
                "MarkerSize", obj.RemovedPointSize, ...
                "LineWidth", 1, ...
                "HitTest", "off", ...
                "PickableParts", "none", ...
                "Tag", "OverlayPointClustersRemovedPoints");
        end

        function h = drawRemovedClusterHulls(obj, ax, S)
        %DRAWREMOVEDCLUSTERHULLS Draw outlines for filtered/deleted clusters.
            h = matlab.graphics.Graphics.empty();
            if obj.ShowRemovedClusters == "off" || ~isfield(S,"RemovedClusterLog")
                return
            end

            T = S.RemovedClusterLog;
            if isempty(T) || height(T) == 0 || ~ismember("ClusterHull", string(T.Properties.VariableNames))
                return
            end

            for i = 1:height(T)
                hull = T.ClusterHull{i};
                if isempty(hull), continue; end

                h(end+1,1) = patch(ax, ...
                    "XData", hull(:,1), ...
                    "YData", hull(:,2), ...
                    "FaceColor", obj.RemovedClusterColor, ...
                    "EdgeColor", obj.RemovedClusterColor, ...
                    "EdgeAlpha", obj.RemovedClusterEdgeAlpha, ...
                    "FaceAlpha", obj.RemovedClusterFaceAlpha, ...
                    "LineStyle", "--", ...
                    "LineWidth", obj.HullLineWidth, ...
                    "HitTest", "off", ...
                    "PickableParts", "none", ...
                    "Tag", "OverlayPointClustersRemovedClusterHull"); %#ok<AGROW>
            end
        end
    end
end
