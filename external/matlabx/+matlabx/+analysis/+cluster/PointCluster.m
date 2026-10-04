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

classdef PointCluster < handle
%POINTCLUSTER Metrics and geometry for one 2-D point cluster.
%
%   CK = matlabx.analysis.cluster.PointCluster(MASTER,POINTS,IDX) represents
%   one cluster of 2-D points. PointCluster is usually created by
%   matlabx.analysis.cluster.PointClusters, but it can also be used directly
%   to compute geometry and point-spacing statistics for a point cloud.
%
%   Example:
%
%       pts = randn(100,2);
%       ck = matlabx.analysis.cluster.PointCluster([],pts,1);
%       centroid = ck.Centroid;
%       hullArea = ck.HullArea;
%       eccentricity = ck.Eccentricity;
%
%   Core geometry:
%       Points
%           N-by-2 point coordinates owned by this cluster.
%       Centroid
%           Mean [x y] coordinate of Points.
%       Distances
%           Distance from each point to the cluster centroid.
%       Hull
%           Boundary coordinates from an alphaShape with alpha=Inf, equivalent
%           to a convex hull when enough unique points are present.
%       HullArea, HullPerimeter
%           Area and perimeter of the hull.
%
%   Shape/statistical metrics:
%       Cov2, EigVals, EigVecs
%           2-D covariance matrix of centered points and its eigensystem.
%       Anisotropy
%           Larger covariance eigenvalue divided by smaller eigenvalue.
%       Eccentricity
%           Ellipse-like eccentricity derived from covariance eigenvalues.
%       PointDensity
%           nPoints / HullArea.
%       Compactness
%           4*pi*HullArea / HullPerimeter^2.
%       DistanceMedian, DistanceP90, DistanceSD, DistTailRatio
%           Radial spread metrics around the centroid.
%       NearestNeighborDistances, NNMedian, NNDispersion
%           Local point-spacing metrics based on pairwise nearest neighbors.
%
%   Refinement helpers:
%       removeOutliersDBSCAN
%           Re-clusters points inside this cluster and removes DBSCAN noise.
%       removeOutliersNNDistance
%           Removes points with unusually large nearest-neighbor distance.
%       removeIsolatedPointsNNSupport
%           Removes points lacking enough neighbors within a local radius.
%
%   The refinement helpers mutate Points and return the removed point
%   coordinates so PointClusters can build stage/history logs.

    properties
        Master (:,1) matlabx.analysis.cluster.PointClusters = matlabx.analysis.cluster.PointClusters.empty()
        Index (1,1) double = NaN
        Centroid (1,2) double = [NaN NaN]
        Distances (:,1) double = zeros(0,1)
        Shape = []
    end

    properties (Access=private)
        Points_ (:,2) double = zeros(0,2)
        PairwiseDistances_ double = []
    end

    properties (Dependent)
        Points (:,2) double
        nPoints (1,1) double
        DistanceSD (1,1) double
        HullArea (1,1) double
        HullPerimeter (1,1) double
        Hull (:,2) double

        Cov2 (2,2) double
        EigVals (1,2) double
        EigVecs (2,2) double
        Anisotropy (1,1) double
        Eccentricity (1,1) double

        DistTailRatio (1,1) double

        NearestNeighborDistances (:,1) double
        NNMedian (1,1) double
        NNDispersion (1,1) double
        Compactness (1,1) double
        DistanceMedian (1,1) double
        DistanceP90 (1,1) double

        PointDensity (1,1) double
    end

    methods
        function obj = PointCluster(master,points,idx)
        %POINTCLUSTER Construct one point-cluster model.
            if nargin >= 1, obj.Master = master; end
            if nargin >= 2, obj.Points = points; end
            if nargin >= 3, obj.Index = idx; end
        end

        function pts = get.Points(obj)
        %GET.POINTS Return current point coordinates.
            pts = obj.Points_;
        end

        function set.Points(obj,pts)
        %SET.POINTS Replace points and refresh derived geometry.
            obj.Points_ = pts;
            % Any point mutation invalidates cached pairwise distances and all
            % geometry derived from the point set.
            obj.PairwiseDistances_ = [];
            obj.update();
        end

        function update(obj)
        %UPDATE Refresh centroid, centroid distances, and hull shape.
            if isempty(obj.Points)
                obj.Centroid = [NaN NaN];
                obj.Distances = zeros(0,1);
                obj.Shape = [];
                return
            end

            % Centroid-distance metrics are used heavily for filtering and are
            % cheap enough to update eagerly when Points changes.
            obj.Centroid = mean(obj.Points,1);
            obj.Distances = sqrt(sum((obj.Points - obj.Centroid).^2,2));
            obj.updateShape();
        end

        function updateShape(obj)
        %UPDATESHAPE Refresh alphaShape hull for current points.
            if obj.nPoints < 3 || size(unique(obj.Points,'rows'),1) < 3
                obj.Shape = [];
                return
            end

            % alpha=Inf gives the convex alpha shape. Keep the alphaShape object
            % so area, perimeter, and boundary can be queried lazily.
            obj.Shape = alphaShape(obj.Points,Inf,"HoleThreshold",1);
        end

        function setIndex(obj,idx)
        %SETINDEX Update cluster index assigned by the owning PointClusters.
            obj.Index = idx;
        end
    end

    methods
        function val = get.nPoints(obj)
        %GET.NPOINTS Return number of points in this cluster.
            val = size(obj.Points,1);
        end

        function val = get.DistanceSD(obj)
        %GET.DISTANCESD Return standard deviation of centroid distances.
            val = std(obj.Distances);
        end

        function val = get.HullArea(obj)
        %GET.HULLAREA Return cluster hull area.
            if isempty(obj.Shape), val = NaN; return; end
            val = obj.Shape.area();
        end

        function val = get.HullPerimeter(obj)
        %GET.HULLPERIMETER Return cluster hull perimeter.
            if isempty(obj.Shape), val = NaN; return; end
            val = obj.Shape.perimeter();
        end

        function val = get.Hull(obj)
        %GET.HULL Return hull boundary coordinates.
            if isempty(obj.Shape), val = zeros(0,2); return; end
            [~,val] = obj.Shape.boundaryFacets();
        end

        function C = get.Cov2(obj)
        %GET.COV2 Return 2-D covariance matrix of centered points.
            if obj.nPoints < 2
                C = nan(2,2);
                return
            end
            % Use the unbiased sample covariance denominator n-1.
            X = obj.Points - mean(obj.Points,1);
            C = (X.'*X) / max(obj.nPoints-1,1);
        end

        function val = get.EigVals(obj)
        %GET.EIGVALS Return sorted covariance eigenvalues.
            if any(isnan(obj.Cov2(:)))
                val = [NaN NaN];
                return
            end
            val = sort(eig(obj.Cov2),'descend').';
        end

        function V = get.EigVecs(obj)
        %GET.EIGVECS Return covariance eigenvectors sorted by eigenvalue.
            if any(isnan(obj.Cov2(:)))
                V = nan(2,2);
                return
            end
            [V,D] = eig(obj.Cov2);
            [~,idx] = sort(diag(D),'descend');
            V = V(:,idx);
        end

        function val = get.Anisotropy(obj)
        %GET.ANISOTROPY Return major/minor covariance eigenvalue ratio.
            l = obj.EigVals;
            if any(isnan(l)) || l(2) <= 0
                val = NaN;
                return
            end
            val = l(1) / l(2);
        end

        function val = get.Eccentricity(obj)
        %GET.ECCENTRICITY Return ellipse-like eccentricity from covariance.
            l = obj.EigVals;
            if any(isnan(l)) || l(1) <= 0 || l(2) < 0
                val = NaN;
                return
            end
            val = sqrt(1 - max(min(l(2)/l(1),1),0));
        end

        function val = get.DistTailRatio(obj)
        %GET.DISTTAILRATIO Return P90/median centroid-distance ratio.
            if isempty(obj.Distances)
                val = NaN;
                return
            end
            q50 = prctile(obj.Distances,50);
            q90 = prctile(obj.Distances,90);
            if q50 <= 0
                val = NaN;
            else
                val = q90 / q50;
            end
        end

        function dnn = get.NearestNeighborDistances(obj)
        %GET.NEARESTNEIGHBORDISTANCES Return nearest-neighbor distance per point.
            n = obj.nPoints;
            if n < 2
                dnn = zeros(0,1);
                return
            end
            % Ignore self-distance before taking each row minimum.
            D = obj.pairwiseDistances();
            D(1:n+1:end) = inf;
            dnn = min(D,[],2);
        end

        function val = get.NNMedian(obj)
        %GET.NNMEDIAN Return median nearest-neighbor distance.
            dnn = obj.NearestNeighborDistances;
            if isempty(dnn) || all(isnan(dnn))
                val = NaN;
            else
                val = median(dnn,'omitnan');
            end
        end

        function val = get.NNDispersion(obj)
        %GET.NNDISPERSION Return MAD-normalized nearest-neighbor spread.
            dnn = obj.NearestNeighborDistances;
            if isempty(dnn) || all(isnan(dnn))
                val = NaN;
                return
            end
            m = median(dnn,'omitnan');
            if m <= 0 || isnan(m)
                val = NaN;
                return
            end
            val = mad(dnn,1) / m;
        end

        function val = get.Compactness(obj)
        %GET.COMPACTNESS Return 4*pi*A/P^2 hull compactness.
            A = obj.HullArea;
            P = obj.HullPerimeter;
            if isempty(A) || isempty(P) || isnan(A) || isnan(P) || P <= 0
                val = NaN;
                return
            end
            val = (4*pi*A) / (P^2);
        end

        function val = get.DistanceMedian(obj)
        %GET.DISTANCEMEDIAN Return median distance from centroid.
            if isempty(obj.Distances)
                val = NaN;
            else
                val = median(obj.Distances,'omitnan');
            end
        end

        function val = get.DistanceP90(obj)
        %GET.DISTANCEP90 Return 90th percentile distance from centroid.
            if isempty(obj.Distances)
                val = NaN;
            else
                val = prctile(obj.Distances,90);
            end
        end

        function val = get.PointDensity(obj)
        %GET.POINTDENSITY Return nPoints divided by hull area.
            A = obj.HullArea;
            if isempty(A) || isnan(A) || A <= 0
                val = NaN;
                return
            end
            val = obj.nPoints / A;
        end
    end

    methods
        function removed = removeOutliersNNDistance(obj, opts)
        %REMOVEOUTLIERSNNDISTANCE Remove points with unusually large nearest-neighbor distance.
            arguments
                obj
                opts.SigmaFactor (1,1) double {mustBePositive} = 2.5
            end

            removed = zeros(0,2);
            n = obj.nPoints;
            if n < 3, return; end

            % Use nearest-neighbor distance as a simple isolation score. Points
            % beyond median + SigmaFactor*SD are treated as local outliers.
            D = obj.pairwiseDistances();
            D(1:n+1:end) = NaN;
            dnn = min(D,[],2,"omitmissing");
            dnnMed = median(dnn,"omitmissing");
            badIdx = dnn > (dnnMed + opts.SigmaFactor*std(dnn));
            removed = obj.Points(badIdx,:);
            obj.Points(badIdx,:) = [];
        end

        function removed = removeIsolatedPointsNNSupport(obj,minSupport,rFactor)
        %REMOVEISOLATEDPOINTSNNSUPPORT Remove points with sparse local support.
            arguments
                obj
                minSupport (1,1) double {mustBeGreaterThanOrEqual(minSupport,1)} = 4
                rFactor (1,1) double {mustBeGreaterThanOrEqual(rFactor,1)} = 4
            end

            removed = zeros(0,2);
            if ~isvalid(obj) || obj.nPoints < 3, return; end

            % Estimate a local radius from the median first-neighbor distance,
            % then require each point to have enough neighbors inside it.
            n = obj.nPoints;
            D = obj.pairwiseDistances();
            D(1:n+1:end) = NaN;
            d1 = min(D,[],2,"omitmissing");
            r = rFactor * median(d1,"omitmissing");
            support = sum(D <= r,2);
            badIdx = support < minSupport;
            removed = obj.Points(badIdx,:);
            obj.Points(badIdx,:) = [];
        end

        function removed = removeOutliersDBSCAN(obj,minPts)
        %REMOVEOUTLIERSDBSCAN Remove within-cluster DBSCAN noise points.
            arguments
                obj
                minPts (1,1) double {mustBeGreaterThanOrEqual(minPts,3)} = 3
            end

            removed = zeros(0,2);
            pts = obj.Points;
            if size(pts,1) < minPts + 1, return; end

            % Reuse the same knee-based epsilon policy as PointClusters.dbscan,
            % but scoped to this cluster's current points.
            epsilon = matlabx.analysis.cluster.chooseDbscanEpsilonKnee(pts,minPts,"SmoothFrac",0.01);
            if isnan(epsilon) || epsilon <= 0, return; end

            D = obj.pairwiseDistances();
            labels = dbscan(D,epsilon,minPts,"Distance","precomputed");
            removed = obj.Points(labels == -1,:);
            obj.Points(labels == -1,:) = [];
        end
    end

    methods (Access=private)
        function D = pairwiseDistances(obj)
        %PAIRWISEDISTANCES Return cached pairwise distances for current points.
            % Pairwise distance matrices are used by several metrics/removers.
            % Cache them until Points changes to avoid repeated pdist2 calls.
            if isempty(obj.PairwiseDistances_) || ...
                    ~isequal(size(obj.PairwiseDistances_), [obj.nPoints obj.nPoints])
                obj.PairwiseDistances_ = pdist2(obj.Points,obj.Points);
            end

            D = obj.PairwiseDistances_;
        end
    end

end
