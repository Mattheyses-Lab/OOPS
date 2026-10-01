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

classdef PointClusters < handle
%POINTCLUSTERS Cluster and summarize 2-D point detections.
%
%   C = matlabx.analysis.cluster.PointClusters(POINTS) clusters an N-by-2
%   array of 2-D point coordinates. The class is designed for workflows where
%   point detections are first grouped into candidate objects, then refined by
%   removing suspect points and filtering whole clusters by geometric or
%   distance-based statistics.
%
%   C = matlabx.analysis.cluster.PointClusters(POINTS,Name,Value) configures
%   the initial clustering method and initial clustering parameters.
%
%   Typical workflow:
%
%       C = matlabx.analysis.cluster.PointClusters(points, ...
%           "MinPointsPerCluster", 5);
%
%       removedPoints = C.refinePoints("Method","nnDistance");
%       C.recluster();
%       removedClusters = C.filterByProperty("Eccentricity",[0 0.9]);
%       metrics = C.exportClusterMetrics();
%
%   Inputs and clustering:
%       OriginalPoints
%           Original N-by-2 input point coordinates. This is retained even as
%           clusters are refined or deleted.
%       ClusterMethod
%           "dbscan" or "kmeans". DBSCAN chooses epsilon with
%           chooseDbscanEpsilonKnee; k-means uses the k property.
%       MinPointsPerCluster
%           Minimum number of points required for DBSCAN core support and for
%           cluster-count filtering.
%
%   Point refinement methods:
%       "dbscan"
%           Runs DBSCAN inside each cluster and removes within-cluster noise.
%       "nnDistance"
%           Removes points whose nearest-neighbor distance is unusually large.
%       "nnSupport"
%           Removes points with insufficient local neighbor support.
%
%   Cluster filtering properties:
%       nPoints
%           Number of points in a cluster.
%       HullArea, HullPerimeter
%           Area and perimeter of the convex alphaShape hull.
%       PointDensity
%           nPoints divided by HullArea.
%       DistanceSD, DistanceMedian, DistanceP90
%           Summary statistics of point distances from the cluster centroid.
%       DistTailRatio
%           90th percentile centroid distance divided by median centroid
%           distance; large values suggest tail-like outliers.
%       Anisotropy
%           Ratio of larger to smaller covariance eigenvalue.
%       Eccentricity
%           Ellipse-like eccentricity computed from covariance eigenvalues.
%       Compactness
%           4*pi*HullArea / HullPerimeter^2. Values closer to 1 are more
%           circular/compact.
%       NNMedian, NNDispersion
%           Median nearest-neighbor distance and robust nearest-neighbor spread.
%
%   Stage and audit outputs:
%       StageSnapshots
%           Struct of value snapshots such as Original, Initial, RefinedPoints,
%           Reclustered, FilteredClusters, or custom stage names.
%       History
%           Struct log of pipeline actions, parameter structs, and before/after
%           counts. Use getHistoryTable() for a tabular view.
%       RemovedPointLog
%           Table of points removed during point refinement.
%       RemovedClusterLog
%           Table of clusters removed by filtering/deletion, including points,
%           hulls, and removal reasons.
%
%   PointClusters intentionally remains a computational/model class. UI classes
%   can visualize live state or stage snapshots without owning the clustering
%   rules.

    properties
        OriginalPoints (:,2) double = zeros(0,2)
        Labels (:,1) double = zeros(0,1)
        NoisePoints (:,2) double = zeros(0,2)
        Epsilon (1,1) double = NaN
        Verbose (1,1) logical = false
        InitialLabels (:,1) double = zeros(0,1)
        InitialNoisePoints (:,2) double = zeros(0,2)
        CurrentStage (1,1) string = "empty"
    end

    properties
        MinPointsPerCluster (1,1) double = 3
        MaxClusterConvexHullArea (1,1) double = Inf
        MaxEccentricity (1,1) double = 0.98
        MinPointDensity (1,1) double = 0.001

        k (1,1) double = 2
    end

    properties
        Clusters (:,1) matlabx.analysis.cluster.PointCluster = matlabx.analysis.cluster.PointCluster.empty()
        StageSnapshots (1,1) struct = struct()
        History (:,1) struct = matlabx.analysis.cluster.PointClusters.emptyHistory()
        RemovedPointLog table = table()
        RemovedClusterLog table = table()
    end

    properties (Dependent)
        nPoints (1,1) double
        nClusters (1,1) double
        Points (:,2) double
        ClusterIdxs (:,1) double
        Centroids (:,2) double
        Distances (:,1) double
        UnclusteredPoints (:,2) double
        Summary table
        StageNames (1,:) string
    end

    methods
        function obj = PointClusters(coords,opts)
        %POINTCLUSTERS Construct and run initial clustering only.
            arguments
                coords (:,2) double = zeros(0,2)

                opts.ClusterMethod (1,:) char {mustBeMember(opts.ClusterMethod,{'dbscan','kmeans'})} = 'dbscan'
                opts.Verbose (1,1) logical = false

                opts.MinPointsPerCluster (1,1) double = 3
                opts.MaxClusterConvexHullArea (1,1) double = Inf
                opts.MaxEccentricity (1,1) double = 1
                opts.MinPointDensity (1,1) double = 0.001

                opts.k (1,1) double {mustBeGreaterThanOrEqual(opts.k,2)} = 2
            end

            % Store policy options so later explicit method calls can reuse the
            % same defaults chosen at construction time.
            obj.Verbose = opts.Verbose;
            obj.MinPointsPerCluster = opts.MinPointsPerCluster;
            obj.MaxClusterConvexHullArea = opts.MaxClusterConvexHullArea;
            obj.MaxEccentricity = opts.MaxEccentricity;
            obj.MinPointDensity = opts.MinPointDensity;
            obj.k = opts.k;

            if isempty(coords)
                return
            end

            % Preserve the raw input as an immutable reference point for stage
            % snapshots and "unclustered" point accounting.
            obj.OriginalPoints = coords;
            obj.recordSnapshot("Original");
            obj.cluster("ClusterMethod",opts.ClusterMethod);
        end
    end

    methods
        function cluster(obj,opts)
        %CLUSTER Build initial clusters from OriginalPoints.
            arguments
                obj (1,1) matlabx.analysis.cluster.PointClusters
                opts.ClusterMethod (1,:) char {mustBeMember(opts.ClusterMethod,{'dbscan','kmeans'})} = 'dbscan'
            end

            before = obj.statusStruct();
            obj.log("Building initial clusters...");
            switch opts.ClusterMethod
                case 'dbscan'
                    obj.dbscan(obj.OriginalPoints,obj.MinPointsPerCluster);
                case 'kmeans'
                    obj.kmeans(obj.OriginalPoints,obj.k);
            end

            % Initial labels/noise are kept even when later stages mutate the
            % live cluster set; this is useful for visual comparison overlays.
            obj.InitialLabels = obj.Labels;
            obj.InitialNoisePoints = obj.NoisePoints;
            obj.CurrentStage = "Initial";
            obj.recordSnapshot("Initial");
            obj.recordHistory("cluster", opts, before, obj.statusStruct(), ...
                "Built initial point clusters.");
        end

        function dbscan(obj,pts,minPts)
        %DBSCAN Cluster points using automatically estimated DBSCAN epsilon.
            arguments
                obj (1,1) matlabx.analysis.cluster.PointClusters
                pts (:,2) double
                minPts (1,1) double {mustBeGreaterThanOrEqual(minPts,3)} = 5
            end

            obj.clearClusters();
            obj.Labels = -1*ones(size(pts,1),1);
            obj.NoisePoints = pts;
            obj.Epsilon = NaN;

            % DBSCAN requires enough points to form at least one nontrivial
            % neighborhood. If not, every input point remains noise.
            if size(pts,1) < minPts + 1
                obj.log("DBSCAN skipped: not enough points.");
                return
            end

            % Estimate epsilon from the k-distance knee, then run MATLAB DBSCAN
            % on a precomputed distance matrix for deterministic distance reuse.
            epsilon = matlabx.analysis.cluster.chooseDbscanEpsilonKnee(pts,minPts,"SmoothFrac",0.01);
            if isnan(epsilon) || epsilon <= 0
                obj.log("DBSCAN skipped: invalid epsilon.");
                return
            end

            D = pdist2(pts,pts);
            labels = dbscan(D,epsilon,minPts,"Distance","precomputed");
            obj.Epsilon = epsilon;
            obj.createClustersFromLabels(pts,labels);

            obj.log(sprintf( ...
                "DBSCAN: %d points grouped into %d cluster(s), %d noise point(s), epsilon %.4g.", ...
                size(pts,1),obj.nClusters,size(obj.NoisePoints,1),obj.Epsilon));
        end

        function kmeans(obj,pts,k)
        %KMEANS Cluster points using MATLAB k-means.
            arguments
                obj (1,1) matlabx.analysis.cluster.PointClusters
                pts (:,2) double
                k (1,1) double {mustBeGreaterThanOrEqual(k,2)} = 2
            end

            obj.clearClusters();
            obj.Labels = -1*ones(size(pts,1),1);
            obj.NoisePoints = zeros(0,2);
            obj.Epsilon = NaN;

            % If k exceeds the number of points, keep points as noise rather
            % than forcing MATLAB kmeans to error.
            if size(pts,1) < k
                obj.NoisePoints = pts;
                obj.log("KMEANS skipped: not enough points.");
                return
            end

            labels = kmeans(pts,k,"Replicates",5);
            obj.createClustersFromLabels(pts,labels);
            obj.log(sprintf("KMEANS: %d points grouped into %d cluster(s).",size(pts,1),obj.nClusters));
        end

        function removed = refinePoints(obj,opts)
        %REFINEPOINTS Remove suspect points from each existing cluster.
            arguments
                obj (1,1) matlabx.analysis.cluster.PointClusters
                opts.Method (1,:) char {mustBeMember(opts.Method,{'dbscan','nnDistance','nnSupport'})} = 'dbscan'
                opts.MinPoints (1,1) double {mustBeGreaterThanOrEqual(opts.MinPoints,3)} = 3
                opts.SigmaFactor (1,1) double {mustBePositive} = 2.5
                opts.MinSupport (1,1) double {mustBeGreaterThanOrEqual(opts.MinSupport,1)} = 4
                opts.RadiusFactor (1,1) double {mustBeGreaterThanOrEqual(opts.RadiusFactor,1)} = 4
                opts.StageName (1,1) string = "RefinedPoints"
            end

            before = obj.statusStruct();
            obj.log("Refining points in each cluster...");
            removedPoints = zeros(0,2);
            removedClusterIDs = zeros(0,1);

            % Each PointCluster mutates itself and returns removed coordinates.
            % We collect those coordinates here so the full set can be logged
            % with the stage name and original cluster ID.
            for i = 1:obj.nClusters
                switch opts.Method
                    case 'dbscan'
                        pts = obj.Clusters(i).removeOutliersDBSCAN(opts.MinPoints);
                    case 'nnDistance'
                        pts = obj.Clusters(i).removeOutliersNNDistance( ...
                            "SigmaFactor", opts.SigmaFactor);
                    case 'nnSupport'
                        pts = obj.Clusters(i).removeIsolatedPointsNNSupport( ...
                            opts.MinSupport, opts.RadiusFactor);
                end

                if ~isempty(pts)
                    removedPoints = [removedPoints; pts]; %#ok<AGROW>
                    removedClusterIDs = [removedClusterIDs; repmat(i,size(pts,1),1)]; %#ok<AGROW>
                end
            end

            % Removing points can leave empty clusters; normalize cluster IDs
            % before recording the new stage snapshot.
            obj.removeEmptyClusters();
            obj.resetNumbering();
            removed = obj.makeRemovedPointTable( ...
                removedPoints, removedClusterIDs, opts.StageName, opts.Method);
            obj.appendRemovedPoints(removed);
            obj.CurrentStage = opts.StageName;
            obj.recordSnapshot(opts.StageName);
            obj.recordHistory("refinePoints", opts, before, obj.statusStruct(), ...
                sprintf("Removed %d point(s) from clusters.", height(removed)));
        end

        function removed = refineClusters(obj,opts)
        %REFINECLUSTERS Apply configured whole-cluster quality filters.
            arguments
                obj (1,1) matlabx.analysis.cluster.PointClusters
                opts.StageName (1,1) string = "FilteredClusters"
            end

            before = obj.statusStruct();
            removed = table();
            % Compose the configured filters without recording a separate stage
            % for each one. The combined result is easier to compare visually.
            removed = [removed; obj.filterByProperty('nPoints',[obj.MinPointsPerCluster Inf], ...
                StageName=opts.StageName, Reason="MinPointsPerCluster", RecordSnapshot=false)];
            removed = [removed; obj.filterByProperty('HullArea',[-Inf obj.MaxClusterConvexHullArea], ...
                StageName=opts.StageName, Reason="MaxClusterConvexHullArea", RecordSnapshot=false)];
            removed = [removed; obj.filterByProperty('Eccentricity',[-Inf obj.MaxEccentricity], ...
                StageName=opts.StageName, Reason="MaxEccentricity", RecordSnapshot=false)];
            removed = [removed; obj.filterByProperty('PointDensity',[obj.MinPointDensity Inf], ...
                StageName=opts.StageName, Reason="MinPointDensity", RecordSnapshot=false)];

            obj.CurrentStage = opts.StageName;
            obj.recordSnapshot(opts.StageName);
            obj.recordHistory("refineClusters", opts, before, obj.statusStruct(), ...
                sprintf("Removed %d cluster(s) using cluster-property filters.", height(removed)));
        end

        function recluster(obj,opts)
        %RECLUSTER Re-run clustering on currently clustered points only.
            arguments
                obj (1,1) matlabx.analysis.cluster.PointClusters
                opts.ClusterMethod (1,:) char {mustBeMember(opts.ClusterMethod,{'dbscan','kmeans'})} = 'dbscan'
            end

            before = obj.statusStruct();
            pts = obj.Points;
            if isempty(pts)
                obj.clearClusters();
                obj.CurrentStage = "Reclustered";
                obj.recordSnapshot("Reclustered");
                obj.recordHistory("recluster", opts, before, obj.statusStruct(), ...
                    "Cleared clusters because there were no clustered points.");
                return
            end

            obj.log("Reclustering clustered points...");
            % Shuffle point order to avoid preserving accidental cluster order
            % from earlier stages as an input-order artifact.
            pts = pts(randperm(size(pts,1)),:);

            switch opts.ClusterMethod
                case 'dbscan'
                    obj.dbscan(pts,obj.MinPointsPerCluster);
                case 'kmeans'
                    obj.kmeans(pts,obj.k);
            end

            obj.CurrentStage = "Reclustered";
            obj.recordSnapshot("Reclustered");
            obj.recordHistory("recluster", opts, before, obj.statusStruct(), ...
                "Reclustered currently clustered points.");
        end

        function mergeCount = mergeClustersByDistance(obj,dist)
        %MERGECLUSTERSBYDISTANCE Merge nearest cluster pairs within a distance.
            arguments
                obj (1,1) matlabx.analysis.cluster.PointClusters
                dist (1,1) double {mustBeNonnegative}
            end

            before = obj.statusStruct();
            mergeCount = 0;
            % Greedily merge the closest pair until every centroid pair is at
            % least dist apart.
            while obj.nClusters > 1
                centroids = obj.Centroids;
                D = pdist2(centroids,centroids);
                D(1:obj.nClusters+1:end) = NaN;
                [minVal,idx] = min(D,[],"all","omitnan");
                if isempty(minVal) || isnan(minVal) || minVal >= dist
                    break
                end

                [r,c] = ind2sub(size(D),idx);
                obj.mergeClustersByIdx([r c]);
                mergeCount = mergeCount + 1;
            end

            obj.CurrentStage = "MergedClusters";
            obj.recordSnapshot("MergedClusters");
            obj.recordHistory("mergeClustersByDistance", struct("Distance",dist), ...
                before, obj.statusStruct(), sprintf("Merged %d cluster pair(s).", mergeCount));
        end

        function removed = filterByProperty(obj,prop,thresh,opts)
        %FILTERBYPROPERTY Delete clusters whose metric falls outside a range.
            arguments
                obj (1,1) matlabx.analysis.cluster.PointClusters
                prop (1,:) char {mustBeMember(prop,{'Eccentricity','nPoints','PointDensity','HullArea','Compactness','NNMedian','NNDispersion','DistanceSD','DistTailRatio','Anisotropy'})}
                thresh (1,2) double = [-Inf Inf]
                opts.StageName (1,1) string = "FilteredClusters"
                opts.Reason (1,1) string = string(prop)
                opts.RecordSnapshot (1,1) logical = true
            end

            before = obj.statusStruct();
            removed = table();
            if obj.nClusters == 0, return; end

            % Treat NaN values as failing the filter because they usually mean
            % the metric is undefined for too few or degenerate points.
            vals = [obj.Clusters(:).(prop)];
            badIdx = find(vals < thresh(1) | vals > thresh(2) | isnan(vals));
            removed = obj.deleteClustersByIdx(badIdx, ...
                StageName=opts.StageName, ...
                Reason=opts.Reason, ...
                Property=string(prop), ...
                PropertyValue=vals(badIdx).');

            if opts.RecordSnapshot
                obj.CurrentStage = opts.StageName;
                obj.recordSnapshot(opts.StageName);
                obj.recordHistory("filterByProperty", ...
                    struct("Property",string(prop),"Threshold",thresh,"Reason",opts.Reason), ...
                    before, obj.statusStruct(), ...
                    sprintf("Removed %d cluster(s) using %s.", height(removed), prop));
            end
        end
    end

    methods
        function createClustersFromLabels(obj,pts,labels)
        %CREATECLUSTERSFROMLABELS Rebuild PointCluster objects from labels.
            obj.clearClusters();
            obj.Labels = labels(:);
            obj.NoisePoints = pts(obj.Labels == -1,:);

            % MATLAB DBSCAN uses -1 for noise. Positive label values become
            % live PointCluster objects with compact 1-based indices.
            clusterIDs = unique(obj.Labels(obj.Labels > 0),'stable');
            for i = 1:numel(clusterIDs)
                obj.Clusters(i,1) = matlabx.analysis.cluster.PointCluster( ...
                    obj, ...
                    pts(obj.Labels == clusterIDs(i),:), ...
                    i);
            end
        end

        function clearClusters(obj)
        %CLEARCLUSTERS Delete all live PointCluster objects.
            if ~isempty(obj.Clusters)
                delete(obj.Clusters(isvalid(obj.Clusters)));
            end
            obj.Clusters = matlabx.analysis.cluster.PointCluster.empty();
        end

        function removed = deleteClustersByIdx(obj,idx,opts)
        %DELETECLUSTERSBYIDX Delete clusters by index and return removal log rows.
            arguments
                obj
                idx
                opts.StageName (1,1) string = obj.CurrentStage
                opts.Reason (1,1) string = "deleteClustersByIdx"
                opts.Property (1,1) string = ""
                opts.PropertyValue (:,1) double = zeros(0,1)
            end

            idx = obj.normalizeClusterIndex(idx);
            removed = table();
            if isempty(idx), return; end

            % Capture summary information before deleting handles so the app can
            % later visualize or audit removed clusters.
            dying = obj.Clusters(idx);
            removed = obj.makeRemovedClusterTable( ...
                dying, idx, opts.StageName, opts.Reason, opts.Property, opts.PropertyValue);
            obj.Clusters(idx) = [];
            delete(dying(isvalid(dying)));
            obj.resetNumbering();
            obj.appendRemovedClusters(removed);
        end

        function mergeClustersByIdx(obj,idx)
        %MERGECLUSTERSBYIDX Merge selected clusters into the first index.
            idx = obj.normalizeClusterIndex(idx);
            if numel(idx) <= 1, return; end

            % Preserve the lowest requested index and append all selected points
            % into that cluster; all other selected handles are deleted.
            idx = sort(idx);
            mergedPoints = vertcat(obj.Clusters(idx).Points);
            dying = obj.Clusters(idx(2:end));
            obj.Clusters(idx(1)).Points = mergedPoints;
            obj.Clusters(idx(2:end)) = [];
            delete(dying(isvalid(dying)));
            obj.resetNumbering();
        end

        function resetNumbering(obj)
        %RESETNUMBERING Compact live cluster indices after deletion/merge.
            obj.removeInvalidClusters();
            for i = 1:obj.nClusters
                obj.Clusters(i).setIndex(i);
            end
        end

        function removeEmptyClusters(obj)
        %REMOVEEMPTYCLUSTERS Delete clusters with zero remaining points.
            if isempty(obj.Clusters), return; end
            obj.deleteClustersByIdx(find([obj.Clusters(:).nPoints] == 0));
        end

        function removeInvalidClusters(obj)
        %REMOVEINVALIDCLUSTERS Drop invalid cluster handles from the live array.
            if isempty(obj.Clusters), return; end
            obj.Clusters = obj.Clusters(isvalid(obj.Clusters));
        end
    end

    methods
        function val = get.nPoints(obj)
        %GET.NPOINTS Return total number of live clustered points.
            if isempty(obj.Clusters), val = 0; return; end
            val = sum([obj.Clusters(:).nPoints]);
        end

        function val = get.nClusters(obj)
        %GET.NCLUSTERS Return number of valid live clusters.
            if isempty(obj.Clusters)
                val = 0;
            else
                val = numel(obj.Clusters(isvalid(obj.Clusters)));
            end
        end

        function val = get.Points(obj)
        %GET.POINTS Concatenate points from all live clusters.
            if isempty(obj.Clusters), val = zeros(0,2); return; end
            val = vertcat(obj.Clusters(:).Points);
        end

        function val = get.ClusterIdxs(obj)
        %GET.CLUSTERIDXS Return live cluster index for each row of Points.
            if isempty(obj.Clusters), val = zeros(0,1); return; end

            % Build a row-aligned vector for the vertically concatenated Points
            % dependent property.
            val = zeros(obj.nPoints,1);
            ctr = 0;
            for i = 1:obj.nClusters
                nPts = obj.Clusters(i).nPoints;
                val(ctr+1:ctr+nPts) = i;
                ctr = ctr + nPts;
            end
        end

        function val = get.Centroids(obj)
        %GET.CENTROIDS Return one centroid row per live cluster.
            if isempty(obj.Clusters), val = zeros(0,2); return; end
            val = vertcat(obj.Clusters(:).Centroid);
        end

        function val = get.Distances(obj)
        %GET.DISTANCES Concatenate centroid distances from all live clusters.
            if isempty(obj.Clusters), val = zeros(0,1); return; end
            val = vertcat(obj.Clusters(:).Distances);
        end

        function pts = get.UnclusteredPoints(obj)
        %GET.UNCLUSTEREDPOINTS Return original points not owned by live clusters.
            if isempty(obj.OriginalPoints)
                pts = zeros(0,2);
                return
            end

            clusteredPts = obj.Points;
            if isempty(clusteredPts)
                pts = obj.OriginalPoints;
                return
            end

            % "Unclustered" is the model-level ownership state: any original
            % detection point that is not currently owned by a live cluster.
            % This includes DBSCAN noise as well as points orphaned by cluster
            % deletion/refinement/reclustering.
            pts = setdiff(obj.OriginalPoints,clusteredPts,"rows","stable");
        end

        function T = get.Summary(obj)
        %GET.SUMMARY Return current cluster metrics table.
            T = obj.exportClusterMetrics();
        end

        function names = get.StageNames(obj)
        %GET.STAGENAMES Return names of recorded processing snapshots.
            names = string(fieldnames(obj.StageSnapshots)).';
        end
    end

    methods
        function S = getStageSnapshot(obj, stageName)
        %GETSTAGESNAPSHOT Return a recorded value snapshot by name.
            arguments
                obj
                stageName (1,1) string
            end

            fieldName = matlab.lang.makeValidName(stageName);
            if isfield(obj.StageSnapshots, fieldName)
                S = obj.StageSnapshots.(fieldName);
            else
                S = struct();
            end
        end

        function T = getHistoryTable(obj)
        %GETHISTORYTABLE Return processing history as a table.
            if isempty(obj.History)
                T = table();
            else
                T = struct2table(obj.History);
            end
        end

        function plot(obj,ax)
        %PLOT Plot original points, clusters, hulls, labels, and noise.
            hold(ax,"on")

            % Original detections provide context for cluster ownership.
            if ~isempty(obj.OriginalPoints)
                plot(ax,obj.OriginalPoints(:,1),obj.OriginalPoints(:,2), ...
                    "LineStyle","none", ...
                    "Marker","x", ...
                    "MarkerEdgeColor",[1 1 1], ...
                    "MarkerSize",3);
            end

            % Use a stable per-cluster color map for clustered points and hulls.
            if obj.nClusters > 0
                colors = lines(obj.nClusters);
            else
                colors = zeros(0,3);
            end

            for i = 1:obj.nClusters
                XData = obj.Clusters(i).Points(:,1);
                YData = obj.Clusters(i).Points(:,2);
                hullPoints = obj.Clusters(i).Hull;

                if ~isempty(hullPoints)
                    patch(ax, ...
                        "XData",hullPoints(:,1), ...
                        "YData",hullPoints(:,2), ...
                        "FaceColor",colors(i,:), ...
                        "HitTest","off", ...
                        "PickableParts","none", ...
                        "FaceAlpha",0.25);
                end

                plot(ax,XData,YData, ...
                    "LineStyle","none", ...
                    "MarkerFaceColor",colors(i,:), ...
                    "Marker","o", ...
                    "MarkerEdgeColor",[1 1 1], ...
                    "MarkerSize",3);

                text("Parent",ax, ...
                    "Position",obj.Clusters(i).Centroid, ...
                    "String",sprintf('%i',i), ...
                    "BackgroundColor",[0 0 0 0.5], ...
                    "HorizontalAlignment","center", ...
                    "VerticalAlignment","middle");
            end

            if ~isempty(obj.NoisePoints)
                plot(ax,obj.NoisePoints(:,1),obj.NoisePoints(:,2), ...
                    "LineStyle","none", ...
                    "Marker",".", ...
                    "MarkerEdgeColor",[0.8 0.8 0.8], ...
                    "MarkerSize",8);
            end

            hold(ax,"off")
        end

        function T = exportClusterMetrics(obj)
        %EXPORTCLUSTERMETRICS Return one-row-per-cluster metric table.
            C = obj.Clusters;
            n = numel(C);

            % Preallocate every metric column so empty cluster sets still return
            % a table with the expected schema.
            ClusterID = (1:n).';
            N = nan(n,1);
            HullArea = nan(n,1);
            HullPerimeter = nan(n,1);
            PointDensity = nan(n,1);
            DistanceSD = nan(n,1);
            DistanceMedian = nan(n,1);
            DistanceP90 = nan(n,1);
            DistTailRatio = nan(n,1);
            Anisotropy = nan(n,1);
            Eccentricity = nan(n,1);
            Compactness = nan(n,1);
            NNMedian = nan(n,1);
            NNDispersion = nan(n,1);

            for i = 1:n
                ck = C(i);
                N(i) = ck.nPoints;
                HullArea(i) = ck.HullArea;
                HullPerimeter(i) = ck.HullPerimeter;
                PointDensity(i) = ck.PointDensity;
                DistanceSD(i) = ck.DistanceSD;
                DistanceMedian(i) = ck.DistanceMedian;
                DistanceP90(i) = ck.DistanceP90;
                DistTailRatio(i) = ck.DistTailRatio;
                Anisotropy(i) = ck.Anisotropy;
                Eccentricity(i) = ck.Eccentricity;
                Compactness(i) = ck.Compactness;
                NNMedian(i) = ck.NNMedian;
                NNDispersion(i) = ck.NNDispersion;
            end

            T = table( ...
                ClusterID, ...
                N, ...
                HullArea, ...
                HullPerimeter, ...
                PointDensity, ...
                DistanceSD, ...
                DistanceMedian, ...
                DistanceP90, ...
                DistTailRatio, ...
                Anisotropy, ...
                Eccentricity, ...
                Compactness, ...
                NNMedian, ...
                NNDispersion);
        end
    end

    methods (Access=private)
        function S = statusStruct(obj)
        %STATUSSTRUCT Return compact counts for history bookkeeping.
            % These small structs are stored in History.Before/After so the
            % caller can quickly inspect how many points/clusters changed.
            S = struct( ...
                "Stage", obj.CurrentStage, ...
                "nOriginalPoints", size(obj.OriginalPoints,1), ...
                "nClusteredPoints", obj.nPoints, ...
                "nClusters", obj.nClusters, ...
                "nNoisePoints", size(obj.NoisePoints,1), ...
                "nUnclusteredPoints", size(obj.UnclusteredPoints,1));
        end

        function recordSnapshot(obj, stageName)
        %RECORDSNAPSHOT Store a value snapshot of the current clustering state.
            stageName = string(stageName);
            fieldName = matlab.lang.makeValidName(stageName);

            % Snapshots store values, not cluster handles. This keeps earlier
            % stages stable even when the live Clusters array changes later.
            S = struct( ...
                "Stage", stageName, ...
                "OriginalPoints", obj.OriginalPoints, ...
                "Labels", obj.Labels, ...
                "NoisePoints", obj.NoisePoints, ...
                "InitialLabels", obj.InitialLabels, ...
                "InitialNoisePoints", obj.InitialNoisePoints, ...
                "Points", obj.Points, ...
                "ClusterIdxs", obj.ClusterIdxs, ...
                "Centroids", obj.Centroids, ...
                "UnclusteredPoints", obj.UnclusteredPoints, ...
                "Summary", obj.Summary, ...
                "ClusterPoints", {obj.clusterPointsCell()}, ...
                "ClusterHulls", {obj.clusterHullsCell()}, ...
                "RemovedPointLog", obj.RemovedPointLog, ...
                "RemovedClusterLog", obj.RemovedClusterLog);

            obj.StageSnapshots.(fieldName) = S;
        end

        function C = clusterPointsCell(obj)
        %CLUSTERPOINTSCELL Return one point matrix per live cluster.
            C = cell(obj.nClusters,1);
            for i = 1:obj.nClusters
                C{i} = obj.Clusters(i).Points;
            end
        end

        function C = clusterHullsCell(obj)
        %CLUSTERHULLSCELL Return one hull matrix per live cluster.
            C = cell(obj.nClusters,1);
            for i = 1:obj.nClusters
                C{i} = obj.Clusters(i).Hull;
            end
        end

        function recordHistory(obj, action, params, before, after, message)
        %RECORDHISTORY Append one processing-history entry.
            % Parameters may be an arguments-block struct or a plain struct. Keep
            % it as-is so future UI code can display method-specific settings.
            entry = struct( ...
                "Stage", obj.CurrentStage, ...
                "Action", string(action), ...
                "Parameters", params, ...
                "Before", before, ...
                "After", after, ...
                "Message", string(message));
            obj.History(end+1,1) = entry;
        end

        function appendRemovedPoints(obj, T)
        %APPENDREMOVEDPOINTS Append removed point records.
            if isempty(T), return; end
            if isempty(obj.RemovedPointLog) || width(obj.RemovedPointLog) == 0
                obj.RemovedPointLog = T;
            else
                obj.RemovedPointLog = [obj.RemovedPointLog; T];
            end
        end

        function appendRemovedClusters(obj, T)
        %APPENDREMOVEDCLUSTERS Append removed cluster records.
            if isempty(T), return; end
            if isempty(obj.RemovedClusterLog) || width(obj.RemovedClusterLog) == 0
                obj.RemovedClusterLog = T;
            else
                obj.RemovedClusterLog = [obj.RemovedClusterLog; T];
            end
        end

        function T = makeRemovedPointTable(~, points, clusterIDs, stageName, reason)
        %MAKEREMOVEDPOINTTABLE Format removed point coordinates as a table.
            n = size(points,1);
            Stage = repmat(string(stageName),n,1);
            Reason = repmat(string(reason),n,1);
            ClusterID = clusterIDs(:);
            X = points(:,1);
            Y = points(:,2);
            T = table(Stage,Reason,ClusterID,X,Y);
        end

        function T = makeRemovedClusterTable(~, clusters, clusterIDs, stageName, reason, prop, propValue)
        %MAKEREMOVEDCLUSTERTABLE Format removed cluster summaries as a table.
            n = numel(clusters);
            if isempty(propValue)
                propValue = nan(n,1);
            end

            Stage = repmat(string(stageName),n,1);
            Reason = repmat(string(reason),n,1);
            ClusterID = clusterIDs(:);
            Property = repmat(string(prop),n,1);
            PropertyValue = propValue(:);
            N = nan(n,1);
            HullArea = nan(n,1);
            PointDensity = nan(n,1);
            Eccentricity = nan(n,1);
            Compactness = nan(n,1);
            ClusterPoints = cell(n,1);
            ClusterHull = cell(n,1);

            for i = 1:n
                ck = clusters(i);
                N(i) = ck.nPoints;
                HullArea(i) = ck.HullArea;
                PointDensity(i) = ck.PointDensity;
                Eccentricity(i) = ck.Eccentricity;
                Compactness(i) = ck.Compactness;
                ClusterPoints{i} = ck.Points;
                ClusterHull{i} = ck.Hull;
            end

            T = table( ...
                Stage, ...
                Reason, ...
                ClusterID, ...
                Property, ...
                PropertyValue, ...
                N, ...
                HullArea, ...
                PointDensity, ...
                Eccentricity, ...
                Compactness, ...
                ClusterPoints, ...
                ClusterHull);
        end

        function idx = normalizeClusterIndex(obj,idx)
        %NORMALIZECLUSTERINDEX Convert logical/scalar/vector input to valid indices.
            if isempty(idx), idx = []; return; end

            if islogical(idx)
                idx = find(idx);
            end

            idx = unique(idx(:).');
            idx = idx(idx >= 1 & idx <= obj.nClusters);
        end

        function log(obj,msg)
        %LOG Emit debug messages when Verbose is true.
            if obj.Verbose
                matlabx.Log.DEBUG(msg);
            end
        end
    end

    methods (Static)
        function H = emptyHistory()
        %EMPTYHISTORY Return an empty processing-history struct array.
            H = struct( ...
                "Stage", {}, ...
                "Action", {}, ...
                "Parameters", {}, ...
                "Before", {}, ...
                "After", {}, ...
                "Message", {});
        end
    end

    methods
        function delete(obj)
        %DELETE Release live PointCluster handles.
            obj.clearClusters();
        end
    end

end
