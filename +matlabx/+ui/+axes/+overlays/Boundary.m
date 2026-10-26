classdef Boundary < matlabx.ui.axes.ImageAxesOverlay
%BOUNDARY Lightweight logical overlay rendered by a BoundaryCollection.
%
%   Boundary participates in the ordinary ImageAxes overlay registry but owns
%   no graphics primitive. Its collection batches many boundary faces into a
%   small fixed set of shared patches.

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

    properties (SetAccess=private)
        Collection matlabx.ui.axes.BoundaryCollection
        Vertices (:,2) double = zeros(0,2)
        Color (1,3) double = [1 1 1]
    end

    properties (SetAccess=private, Dependent)
        Center
        Bounds
    end

    methods
        function obj = Boundary(host, collection, opts)
        %BOUNDARY Create one collection-owned logical boundary.
            arguments
                host (1,1) matlabx.ui.axes.ImageAxes
                collection (1,1) matlabx.ui.axes.BoundaryCollection
                opts.ID (1,1) string
                opts.Vertices (:,2) double
                opts.Color (1,3) double {mustBeBetween(opts.Color,0,1)} = [1 1 1]
                opts.Label (1,1) string = ""
                opts.UserData = []
                opts.C = "all"
                opts.Z = "all"
                opts.T = "all"
                opts.Visible (1,1) matlab.lang.OnOffSwitchState = "on"
            end
            obj@matlabx.ui.axes.ImageAxesOverlay(host, ...
                Type="Boundary", ID=opts.ID, Label=opts.Label, ...
                UserData=opts.UserData, C=opts.C, Z=opts.Z, T=opts.T, ...
                Visible=opts.Visible);
            obj.Collection = collection;
            obj.setGeometry(opts.Vertices, opts.Color);
        end

        function value = get.Center(obj)
        %GET.CENTER Return the boundary bounding-box center.
            if isempty(obj.Vertices)
                value = [NaN NaN];
            else
                value = (min(obj.Vertices,[],1) + max(obj.Vertices,[],1))/2;
            end
        end

        function value = get.Bounds(obj)
        %GET.BOUNDS Return [xmin xmax ymin ymax].
            if isempty(obj.Vertices)
                value = [NaN NaN NaN NaN];
            else
                value = [min(obj.Vertices(:,1)), max(obj.Vertices(:,1)), ...
                    min(obj.Vertices(:,2)), max(obj.Vertices(:,2))];
            end
        end

        function setGeometry(obj, vertices, color)
        %SETGEOMETRY Replace geometry and base color without normalization.
            validateattributes(vertices,{'double'},{'2d','ncols',2,'real','finite'});
            if size(vertices,1) < 3
                error('matlabx:ui:axes:Boundary:InvalidVertices', ...
                    'Boundary vertices must contain at least three [x y] rows.');
            end
            validateattributes(color,{'double'},{'size',[1 3],'>=',0,'<=',1});
            if size(vertices,1) > 1 && isequal(vertices(1,:),vertices(end,:))
                vertices(end,:) = [];
            end
            obj.Vertices = vertices;
            obj.Color = color;
            if ~isempty(obj.Collection) && isvalid(obj.Collection)
                obj.Collection.requestGeometryRefresh();
            end
        end

        function tf = isInsideRectangle(obj, rect)
        %ISINSIDERECTANGLE Select boundaries by their stable center point.
            xy = obj.Center;
            tf = obj.Visible == "on" && obj.ViewVisible == "on" ...
                && obj.Collection.Visible == "on" ...
                && xy(1) >= rect(1) && xy(1) <= rect(2) ...
                && xy(2) >= rect(3) && xy(2) <= rect(4);
        end

        function updateAppearance(obj)
        %UPDATEAPPEARANCE Defer state rendering to the shared collection.
            if ~isempty(obj.Collection) && isvalid(obj.Collection)
                obj.Collection.requestStateRefresh();
            end
        end

    end

    methods (Access=protected)
        function updateVisibility(obj)
        %UPDATEVISIBILITY Defer visibility rendering to the shared collection.
            if ~isempty(obj.Collection) && isvalid(obj.Collection)
                obj.Collection.requestStateRefresh();
            end
        end
    end
end
