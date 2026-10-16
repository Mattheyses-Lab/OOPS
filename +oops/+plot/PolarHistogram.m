% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef PolarHistogram < handle
%POLARHISTOGRAM Own the Cartesian primitives for one polar histogram.

    properties (Dependent)
        Parent
    end

    properties (Access=private)
        Parent_ matlab.graphics.axis.AbstractAxes = matlab.graphics.axis.AbstractAxes.empty()
        Circle
        RadialGrid
        AngularGrid
        Wedges
        Labels = matlab.graphics.primitive.Text.empty(0,1)
    end

    methods
        function obj = PolarHistogram(parent)
        %POLARHISTOGRAM Create the reusable primitive set on a Cartesian axes.
            if nargin > 0, obj.Parent = parent; end
        end

        function set.Parent(obj,parent)
        %SET.PARENT Create or transfer every renderer-owned graphics primitive.

            if isempty(parent)
                handles = [obj.Circle,obj.RadialGrid,obj.AngularGrid,obj.Wedges,obj.Labels(:).'];
                set(handles(isvalid(handles)),'Parent',[]);
                obj.Parent_ = matlab.graphics.axis.AbstractAxes.empty();
                return;
            end

            validateattributes(parent,{'matlab.ui.control.UIAxes'},{'scalar'});
            obj.Parent_ = parent;

            if isempty(obj.Circle) || ~isvalid(obj.Circle)
                obj.Circle = patch(parent,NaN,NaN,[1 1 1], ...
                    'HitTest','off','PickableParts','none');
                obj.RadialGrid = line(parent,NaN,NaN, ...
                    'HitTest','off','PickableParts','none');
                obj.AngularGrid = line(parent,NaN,NaN, ...
                    'HitTest','off','PickableParts','none');
                obj.Wedges = patch(parent,'Vertices',zeros(0,2),'Faces',zeros(0,3), ...
                    'FaceColor','flat','HitTest','off','PickableParts','none');
            else
                handles = [obj.Circle,obj.RadialGrid,obj.AngularGrid,obj.Wedges,obj.Labels(:).'];
                set(handles(isvalid(handles)),'Parent',parent);
            end
        end

        function parent = get.Parent(obj)
        %GET.PARENT Return the axes that currently own the plot primitives.

            parent = obj.Parent_;
        end

        function render(obj,data,style)
        %RENDER Rebuild geometry and appearance from normalized data and style.
            arguments
                obj
                data (1,1) oops.plot.PolarHistogramData
                style (1,1) oops.plot.PolarHistogramStyle
            end

            if isempty(obj.Parent), return; end

            % Axial measurements are mirrored by 180 degrees for the full-circle view.
            angles = [data.Angles,data.Angles + pi];
            edges = linspace(0,2*pi,style.BinCount + 1);
            counts = histcounts(angles,edges);
            [radialLimit,radialSpacing] = obj.radialScale(counts);
            buffer = .15 * radialLimit;

            % Configure the host Cartesian axes as an undistorted polar canvas.
            axes = obj.Parent;
            axes.XLim = [-radialLimit-buffer,radialLimit+buffer];
            axes.YLim = axes.XLim;
            axes.DataAspectRatio = [1 1 1];
            axes.XTick = [];
            axes.YTick = [];
            axes.XColor = 'none';
            axes.YColor = 'none';
            axes.XAxis.Visible = 'off';
            axes.YAxis.Visible = 'off';
            axes.Box = 'off';
            axes.Title.String = char(style.Title);
            axes.Title.Color = style.LabelsColor;

            % Draw the circular background and its radial reference rings.
            circleAngles = linspace(0,2*pi,400);
            obj.Circle.XData = radialLimit .* cos(circleAngles);
            obj.Circle.YData = radialLimit .* sin(circleAngles);
            obj.Circle.FaceColor = style.CircleBackgroundColor;
            obj.Circle.EdgeColor = style.CircleColor;
            obj.Circle.LineWidth = style.CircleLineWidth;

            radii = radialSpacing:radialSpacing:(radialLimit-radialSpacing);
            [gridX,gridY] = obj.circleLines(radii,circleAngles);
            obj.RadialGrid.XData = gridX;
            obj.RadialGrid.YData = gridY;
            obj.RadialGrid.Color = style.GridlinesColor;
            obj.RadialGrid.LineWidth = style.GridlinesLineWidth;

            % Draw one diameter every 30 degrees and label each direction.
            labelAngles = (0:pi/6:(2*pi-pi/6)).';
            diameterAngles = labelAngles(1:6);
            gridX = [radialLimit*cos(diameterAngles), ...
                -radialLimit*cos(diameterAngles),nan(6,1)].';
            gridY = [radialLimit*sin(diameterAngles), ...
                -radialLimit*sin(diameterAngles),nan(6,1)].';
            obj.AngularGrid.XData = gridX(:);
            obj.AngularGrid.YData = gridY(:);
            obj.AngularGrid.Color = style.GridlinesColor;
            obj.AngularGrid.LineWidth = style.GridlinesLineWidth;
            obj.refreshLabels(labelAngles,radialLimit + .1*buffer,style.LabelsColor);

            % Build triangular wedge faces using the legacy straight outer edges.
            [vertices,faces,colors] = obj.wedgeGeometry(counts,edges,style.Colormap, ...
                style.WedgeFaceColorMode);
            obj.Wedges.Vertices = vertices;
            obj.Wedges.Faces = faces;
            obj.Wedges.FaceVertexCData = colors;
            obj.Wedges.FaceColor = char(style.WedgeFaceColorMode);
            obj.Wedges.FaceAlpha = style.WedgeFaceAlpha;
            obj.Wedges.LineWidth = style.WedgeLineWidth;

            if style.WedgeEdgeColorMode == "interp"
                obj.Wedges.EdgeColor = 'interp';
            else
                obj.Wedges.EdgeColor = style.WedgeEdgeColor;
            end

            obj.setVisible(true);
        end

        function setVisible(obj,value)
        %SETVISIBLE Show or hide all primitives as one plot-content unit.
            state = matlab.lang.OnOffSwitchState(value);
            handles = [obj.Circle,obj.RadialGrid,obj.AngularGrid,obj.Wedges,obj.Labels(:).'];
            set(handles(isvalid(handles)),'Visible',state);
        end

        function delete(obj)
        %DELETE Release every graphics primitive owned by this plot.
            handles = [obj.Circle,obj.RadialGrid,obj.AngularGrid,obj.Wedges,obj.Labels(:).'];
            delete(handles(isvalid(handles)));
        end
    end

    methods (Access=private)
        function [limit,spacing] = radialScale(~,counts)
        %RADIALSCALE Reproduce the legacy rounded automatic radial range.
            maximum = max([counts,1]);
            magnitude = 10^(ceil(log10(maximum)));
            spacing = magnitude / 10;
            candidates = 0:spacing:(magnitude + spacing);
            limit = min(candidates(candidates > maximum));

            while numel(0:spacing:limit) > 7, spacing = spacing * 2; end
            while numel(0:spacing:limit) < 7, spacing = spacing / 2; end
        end

        function [x,y] = circleLines(~,radii,angles)
        %CIRCLELINES Join independent circular rings with NaN separators.
            x = double.empty(0,1);
            y = double.empty(0,1);

            for radius = radii
                x = [x;radius*cos(angles(:));NaN]; %#ok<AGROW>
                y = [y;radius*sin(angles(:));NaN]; %#ok<AGROW>
            end
        end

        function refreshLabels(obj,angles,distance,color)
        %REFRESHLABELS Recreate direction labels at their Cartesian positions.
            delete(obj.Labels(isvalid(obj.Labels)));
            obj.Labels = matlab.graphics.primitive.Text.empty(0,1);

            for k = 1:numel(angles)
                x = round(distance*cos(angles(k)),4);
                y = round(distance*sin(angles(k)),4);
                [horizontal,vertical] = obj.labelAlignment(x,y);
                obj.Labels(k,1) = text(obj.Parent,x,y,string(rad2deg(angles(k))) + "°", ...
                    'HorizontalAlignment',horizontal,'VerticalAlignment',vertical, ...
                    'Color',color,'HitTest','off','PickableParts','none');
            end
        end

        function [vertices,faces,colors] = wedgeGeometry(~,counts,edges,map,mode)
        %WEDGEGEOMETRY Construct legacy triangular bins and circular colors.

            % The input map describes one 180-degree axial period. Repeating it
            % makes the same ordered colors cover both halves of the full circle.
            map = repmat(map,2,1);

            count = numel(counts);
            vertices = zeros(3*count,2);
            faces = reshape(1:3*count,3,[]).';
            vertexColors = zeros(3*count,3);
            colorCount = size(map,1);

            for k = 1:count
                first = edges(k);
                second = edges(k+1);
                middle = (first + second) / 2;
                rows = (1:3) + 3*(k-1);
                radius = counts(k);
                vertices(rows,:) = [radius*cos(first),radius*sin(first); ...
                    radius*cos(second),radius*sin(second);0 0];

                % Nearest-sample indexing keeps angles separated by exactly pi
                % on corresponding samples in the two repeated map periods.
                firstIndex = mod(round(first/(2*pi)*colorCount),colorCount)+1;
                secondIndex = mod(round(second/(2*pi)*colorCount),colorCount)+1;
                middleIndex = mod(round(middle/(2*pi)*colorCount),colorCount)+1;

                if mode == "interp"
                    vertexColors(rows,:) = map([firstIndex;secondIndex;middleIndex],:);
                else
                    % Flat and interpolated modes both retain one RGB row per
                    % vertex. This avoids invalid transient CData shapes when
                    % MATLAB validates the patch while switching modes.
                    faceColor = map(middleIndex,:);
                    vertexColors(rows,:) = repmat(faceColor,3,1);
                end
            end

            colors = vertexColors;
        end

        function [horizontal,vertical] = labelAlignment(~,x,y)
        %LABELALIGNMENT Place labels outside the circle in each quadrant.
            horizontal = 'center';
            vertical = 'middle';
            if x > 0, horizontal = 'left'; elseif x < 0, horizontal = 'right'; end
            if y > 0, vertical = 'bottom'; elseif y < 0, vertical = 'top'; end
        end
    end
end
