% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2023 William Dean
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

classdef Scatter < handle & matlab.mixin.SetGet
%SCATTER One logical dataset backed by owned graphics primitives.

    %% scatter properties

    properties(Dependent = true, AbortSet = true)
        % data
        XData (1,:) double
        YData (1,:) double
        % marker appearance (color, transparency, size, etc.)
        PointsVisible (1,1) matlab.lang.OnOffSwitchState
        MarkerEdgeColor
        MarkerEdgeAlpha (1,1) double {mustBeInRange(MarkerEdgeAlpha,0,1)}
        MarkerSize
        MarkerFaceColor
        MarkerFaceAlpha (1,1) double {mustBeInRange(MarkerFaceAlpha,0,1)}
        Marker (:,1) char {mustBeMember(Marker,{'o','s','^','h','p','d','v','>','<'})}
        CData
        % marker datatip info
        DataTipCell (1,2) cell
        % name (for the central stat marker)
        Name (1,:) char
    end

    %% hull properties

    properties(Dependent = true, AbortSet = true)
        HullVisible (1,1) matlab.lang.OnOffSwitchState
        HullLineWidth (1,1) double
        HullFaceColor (1,3) double
        HullEdgeColor (1,3) double
        HullFaceAlpha (1,1) double {mustBeInRange(HullFaceAlpha,0,1)}
        HullEdgeAlpha (1,1) double {mustBeInRange(HullEdgeAlpha,0,1)}
        HullType (1,:) char {mustBeMember(HullType,{'convex','concave'})}
    end

    properties(Access = private)
        HullType_ (1,:) char {mustBeMember(HullType_,{'convex','concave'})} = 'concave'
    end

    %% graphics objects

    properties(Access = private,Transient,NonCopyable)
        scatterPoints (1,1) matlab.graphics.chart.primitive.Scatter
        Hull (1,1) matlab.graphics.primitive.Patch
    end

    methods

        function obj = Scatter(Parent,NameValuePairs)

            % input argument validation
            arguments
                % parent axes
                Parent (1,1) matlab.ui.control.UIAxes
                % scatter properties
                NameValuePairs.XData (1,:) double = NaN
                NameValuePairs.YData (1,:) double = NaN
                NameValuePairs.DataTipCell (1,2) cell = {{},{}};
                NameValuePairs.MarkerFaceColor = 'flat'
                NameValuePairs.MarkerFaceAlpha (1,1) double {mustBeInRange(NameValuePairs.MarkerFaceAlpha,0,1)} = 0.5
                NameValuePairs.MarkerEdgeColor = [0 0 0]
                NameValuePairs.MarkerEdgeAlpha (1,1) double {mustBeInRange(NameValuePairs.MarkerEdgeAlpha,0,1)} = 1
                NameValuePairs.MarkerSize = 50
                NameValuePairs.Marker (:,1) char {mustBeMember(NameValuePairs.Marker,{'o','s','^','h','p','d','v','>','<'})} = 'o'
                NameValuePairs.CData = [0 0 0]
                NameValuePairs.PointsVisible (1,1) matlab.lang.OnOffSwitchState = "on"
                % data name
                NameValuePairs.Name (1,:) char = 'untitled';
                % hull properties
                NameValuePairs.HullVisible (1,1) matlab.lang.OnOffSwitchState = "on"
                NameValuePairs.HullLineWidth (1,1) double = 1
                NameValuePairs.HullFaceColor (1,3) double = [1 1 1]
                NameValuePairs.HullEdgeColor (1,3) double = [0 0 0]
                NameValuePairs.HullFaceAlpha (1,1) double {mustBeInRange(NameValuePairs.HullFaceAlpha,0,1)} = 0.5
                NameValuePairs.HullEdgeAlpha (1,1) double {mustBeInRange(NameValuePairs.HullEdgeAlpha,0,1)} = 1
                NameValuePairs.HullType (1,:) char {mustBeMember(NameValuePairs.HullType,{'convex','concave'})} = 'concave'
            end

            % primitive patch to form the convex hull
            obj.Hull = patch(Parent,...
                'XData',NaN,...
                'YData',NaN,...
                'HitTest','off',...
                'PickableParts','none');

            % Create both primitives before setters inspect the paired data.
            obj.scatterPoints = matlab.graphics.chart.primitive.Scatter( ...
                'Parent',Parent,'XData',NaN,'YData',NaN);

            % convex hull properties
            obj.HullVisible = NameValuePairs.HullVisible;
            obj.HullLineWidth = NameValuePairs.HullLineWidth;
            obj.HullFaceColor = NameValuePairs.HullFaceColor;
            obj.HullFaceAlpha = NameValuePairs.HullFaceAlpha;
            obj.HullEdgeColor = NameValuePairs.HullEdgeColor;
            obj.HullEdgeAlpha = NameValuePairs.HullEdgeAlpha;


            % scatter properties
            obj.PointsVisible = NameValuePairs.PointsVisible;
            obj.XData = NameValuePairs.XData;
            obj.YData = NameValuePairs.YData;
            obj.MarkerFaceColor = NameValuePairs.MarkerFaceColor;
            obj.MarkerFaceAlpha = NameValuePairs.MarkerFaceAlpha;
            obj.MarkerEdgeColor = NameValuePairs.MarkerEdgeColor;
            obj.MarkerEdgeAlpha = NameValuePairs.MarkerEdgeAlpha;
            obj.MarkerSize = NameValuePairs.MarkerSize;
            obj.Marker = NameValuePairs.Marker;
            obj.CData = NameValuePairs.CData;

            obj.HullType = NameValuePairs.HullType;

            % data tip info
            obj.DataTipCell = NameValuePairs.DataTipCell;

            % name of the dataset plotted
            obj.Name = NameValuePairs.Name;

        end

        function delete(obj)

            delete(obj.scatterPoints);
            delete(obj.Hull);

        end

        function setParent(obj,parent)
        %SETPARENT Move both scatter and hull primitives to another UIAxes.

            % Empty parent parks the primitives outside any figure while detached.
            if ~isempty(parent)
                validateattributes(parent,{'matlab.ui.control.UIAxes'},{'scalar'});
            end

            obj.scatterPoints.Parent = parent;
            obj.Hull.Parent = parent;
        end

    end


    %% Set/Get methods for public properties controlling scatter points appearance

    methods

        %% PointsVisible

        function set.PointsVisible(obj,val)
            obj.scatterPoints.Visible = val;
        end

        function PointsVisible = get.PointsVisible(obj)
            PointsVisible = obj.scatterPoints.Visible;
        end

        %% XData

        function set.XData(obj,val)
            % set XData of the scatterPoints scatter
            obj.scatterPoints.XData = val;

            % update convex hull if possible
            if isequal(size(obj.XData),size(obj.YData)) && obj.HullVisible
                obj.updateHull();
            end
        end

        function XData = get.XData(obj)
            XData = obj.scatterPoints.XData;
        end

        %% YData

        function set.YData(obj,val)
            % set YData of the scatterPoints scatter
            obj.scatterPoints.YData = val;

            % update convex hull if possible
            if isequal(size(obj.XData),size(obj.YData)) && obj.HullVisible
                obj.updateHull();
            end
        end

        function YData = get.YData(obj)
            YData = obj.scatterPoints.YData;
        end

        %% MarkerEdgeColor

        function set.MarkerEdgeColor(obj,val)
            obj.scatterPoints.MarkerEdgeColor = val;
        end

        function MarkerEdgeColor = get.MarkerEdgeColor(obj)
            MarkerEdgeColor = obj.scatterPoints.MarkerEdgeColor;
        end

        %% MarkerSize

        function set.MarkerSize(obj,val)
            obj.scatterPoints.SizeData = val;
        end

        function MarkerSize = get.MarkerSize(obj)
            MarkerSize = obj.scatterPoints.SizeData;
        end

        %% MarkerFaceColorMode

        function set.MarkerFaceColor(obj,val)
            obj.scatterPoints.MarkerFaceColor = val;
        end

        function MarkerFaceColor = get.MarkerFaceColor(obj)
            MarkerFaceColor = obj.scatterPoints.MarkerFaceColor;
        end

        %% MarkerEdgeAlpha

        function set.MarkerEdgeAlpha(obj,val)
            obj.scatterPoints.MarkerEdgeAlpha = val;
        end

        function MarkerEdgeAlpha = get.MarkerEdgeAlpha(obj)
            MarkerEdgeAlpha = obj.scatterPoints.MarkerEdgeAlpha;
        end

        %% MarkerFaceAlpha

        function set.MarkerFaceAlpha(obj,val)
            obj.scatterPoints.MarkerFaceAlpha = val;
        end

        function MarkerFaceAlpha = get.MarkerFaceAlpha(obj)
            MarkerFaceAlpha = obj.scatterPoints.MarkerFaceAlpha;
        end

        %% Marker

        function set.Marker(obj,val)
            obj.scatterPoints.Marker = val;
        end

        function Marker = get.Marker(obj)
            Marker = obj.scatterPoints.Marker;
        end

        %% CData

        function set.CData(obj,val)
            % Data contracts use row vectors; MATLAB scalar color data uses
            % one row per point. A triplet retains its RGB interpretation.
            if isvector(val) && numel(val) ~= 3
                val = val(:);
            end

            obj.scatterPoints.CData = val;
        end

        function CData = get.CData(obj)
            CData = obj.scatterPoints.CData;
        end

        %% DataTipCell

        function set.DataTipCell(obj,val)
            if any(cellfun(@(x) isempty(x),val))
                % number of datatiprows in the plot
                nDataTipRows = numel(obj.scatterPoints.DataTipTemplate.DataTipRows);
                % clear out default datatiprows
                for i = nDataTipRows:-1:2
                    obj.scatterPoints.DataTipTemplate.DataTipRows(i) = [];
                end

                return
            else
                dtNames = val{1};
                dtData = val{2};
                for i = 1:numel(dtNames)
                    obj.scatterPoints.DataTipTemplate.DataTipRows(i) = dataTipTextRow(dtNames{i},dtData{i});
                end
            end
        end

        function DataTipCell = get.DataTipCell(obj)
            % array of datatip rows for this violin
            dtRows = obj.scatterPoints.DataTipTemplate.DataTipRows;
            % names and values for each datatip
            dtNames = arrayfun(@(x) x.Label,dtRows','UniformOutput',false);
            dtData = arrayfun(@(x) x.Value,dtRows','UniformOutput',false);
            % cell array of cell arrays with datatip info in scatterPoints
            DataTipCell = {dtNames,dtData};
        end

        %% Name

        function set.Name(obj,val)
            obj.scatterPoints.DisplayName = val;
        end

        function Name = get.Name(obj)
            Name = obj.scatterPoints.DisplayName;
        end


    end



    %% Set and Get methods for public properties controlling convex hull appearance
    methods

        %% HullType

        function set.HullType(obj,val)
            obj.HullType_ = val;
            obj.updateHull();
        end

        function HullType = get.HullType(obj)
            HullType = obj.HullType_;
        end

        %% HullVisible

        function set.HullVisible(obj,val)
            obj.Hull.Visible = val;
            % update convex hull if possible
            if isequal(size(obj.XData),size(obj.YData)) && obj.HullVisible
                obj.updateHull();
            end
        end

        function HullVisible = get.HullVisible(obj)
            HullVisible = obj.Hull.Visible;
        end

        %% HullLineWidth

        function set.HullLineWidth(obj,val)
            obj.Hull.LineWidth = val;
        end

        function HullLineWidth = get.HullLineWidth(obj)
            HullLineWidth = obj.Hull.LineWidth;
        end

        %% HullFaceColor

        function set.HullFaceColor(obj,val)
            obj.Hull.FaceColor = val;
        end

        function HullFaceColor = get.HullFaceColor(obj)
            HullFaceColor = obj.Hull.FaceColor;
        end

        %% HullFaceAlpha

        function set.HullFaceAlpha(obj,val)
            obj.Hull.FaceAlpha = val;
        end

        function HullFaceAlpha = get.HullFaceAlpha(obj)
            HullFaceAlpha = obj.Hull.FaceAlpha;
        end

        %% HullEdgeColor

        function set.HullEdgeColor(obj,val)
            obj.Hull.EdgeColor = val;
        end

        function HullEdgeColor = get.HullEdgeColor(obj)
            HullEdgeColor = obj.Hull.EdgeColor;
        end

        %% HullEdgeAlpha

        function set.HullEdgeAlpha(obj,val)
            obj.Hull.EdgeAlpha = val;
        end

        function HullEdgeAlpha = get.HullEdgeAlpha(obj)
            HullEdgeAlpha = obj.Hull.EdgeAlpha;
        end

    end


    % private, hidden methods for various internal purposes
    methods (Access = private,Hidden = true)

        function updateHull(obj)

            % Hull algorithms need at least three distinct, noncollinear points.
            points = unique([obj.XData(:),obj.YData(:)],'rows','stable');
            % Check missing values before rank/SVD, which reject Inf and NaN.
            insufficient = size(points,1) < 3 || any(~isfinite(points),'all');

            if ~insufficient
                insufficient = rank(points-points(1,:)) < 2;
            end

            % Missing or degenerate series have no meaningful enclosing hull.
            if insufficient
                % set empty (NaN) coordinates for the Hull patch
                set(obj.Hull,...
                    "XData",NaN,...
                    "YData",NaN);
                return
            end

            switch obj.HullType
                case 'convex'
                    % get idxs for points representing convex hull
                    K = convhull(points(:,1),points(:,2));
                    % get the hull points
                    hullPoints = points(K,:);
                case 'concave'
                    % create alpha shape from the points
                    shp = alphaShape(points(:,1),points(:,2));
                    % determine the best alpha value to enclose points in a single region
                    alpha = criticalAlpha(shp,'one-region');

                    if ~isfinite(alpha) || alpha <= 0
                        set(obj.Hull,"XData",NaN,"YData",NaN);
                        return;
                    end

                    % set the alpha value we just found
                    shp.Alpha = alpha;
                    % make sure there are no holes so lines of the shape do not intersect
                    shp.HoleThreshold = 1;
                    % get the boundary coordinates
                    [~,P] = boundaryFacets(shp);

                    if isempty(P)
                        set(obj.Hull,"XData",NaN,"YData",NaN);
                        return;
                    end
                    % replicate the first point onto the end to form a close curve
                    hullPoints = [P;P(1,:)];
            end

            % update the coordinates of the Hull patch
            set(obj.Hull,...
                "XData",hullPoints(:,1),...
                "YData",hullPoints(:,2));


        end

    end




end
