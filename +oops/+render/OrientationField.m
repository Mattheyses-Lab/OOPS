% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef OrientationField < matlabx.ui.axes.ImageAxesOverlayContent
%ORIENTATIONFIELD Passive axial-orientation segments mounted in ImageAxes.
% OOPS supplies already sampled coordinates, angles, and magnitudes. The
% content owns one patch primitive and does not participate in interaction.

    properties (SetAccess=private)
        X (:,1) double = []
        Y (:,1) double = []
        Angle (:,1) double = []
        Magnitude (:,1) double = []
    end

    properties (SetAccess=private)
        ColorMode (1,1) string {mustBeMember(ColorMode,["Direction","Magnitude","Mono"])} = "Direction"
        Colormap (:,3) double {mustBeInRange(Colormap,0,1)} = hsv(256)
        Color (1,3) double {mustBeInRange(Color,0,1)} = [1 1 1]
        LineWidth (1,1) double {mustBePositive,mustBeFinite} = 1
        Alpha (1,1) double {mustBeInRange(Alpha,0,1),mustBeFinite} = 0.6
        Scale (1,1) double {mustBePositive,mustBeFinite} = 25
    end

    properties (SetAccess=private)
        Graphic = []
    end

    methods

        function setData(obj,x,y,angle,magnitude)
        %SETDATA Store sampled axial vectors and update the mounted primitive.

            arguments
                obj
                x (:,1) double {mustBeFinite}
                y (:,1) double {mustBeFinite}
                angle (:,1) double
                magnitude (:,1) double
            end

            % All vectors describe the same ordered set of image locations.
            count = numel(x);

            if numel(y) ~= count || numel(angle) ~= count || numel(magnitude) ~= count
                error('oops:render:OrientationFieldSizeMismatch', ...
                    'Coordinates, angles, and magnitudes must have equal lengths.');
            end

            obj.X = x;
            obj.Y = y;
            obj.Angle = angle;
            obj.Magnitude = magnitude;
            obj.updateGraphic();
        end

        function setStyle(obj,opts)
        %SETSTYLE Apply display-only appearance and repaint existing data.

            arguments
                obj
                opts.ColorMode (1,1) string {mustBeMember(opts.ColorMode,["Direction","Magnitude","Mono"])} = obj.ColorMode
                opts.Colormap (:,3) double {mustBeInRange(opts.Colormap,0,1)} = obj.Colormap
                opts.Color (1,3) double {mustBeInRange(opts.Color,0,1)} = obj.Color
                opts.LineWidth (1,1) double {mustBePositive,mustBeFinite} = obj.LineWidth
                opts.Alpha (1,1) double {mustBeInRange(opts.Alpha,0,1),mustBeFinite} = obj.Alpha
                opts.Scale (1,1) double {mustBePositive,mustBeFinite} = obj.Scale
            end

            obj.ColorMode = opts.ColorMode;
            obj.Colormap = opts.Colormap;
            obj.Color = opts.Color;
            obj.LineWidth = opts.LineWidth;
            obj.Alpha = opts.Alpha;
            obj.Scale = opts.Scale;
            obj.updateGraphic();
        end

        function clear(obj)
        %CLEAR Remove field data while retaining reusable mounted graphics.

            obj.X = [];
            obj.Y = [];
            obj.Angle = [];
            obj.Magnitude = [];
            obj.updateGraphic();
        end

        function attach(obj,parent,~)
        %ATTACH Create or reparent the single passive patch primitive.

            if isempty(obj.Graphic) || ~isgraphics(obj.Graphic)
                obj.Graphic = patch( ...
                    'Parent',parent, ...
                    'Vertices',zeros(0,2), ...
                    'Faces',zeros(0,2), ...
                    'FaceColor','none', ...
                    'EdgeColor','flat', ...
                    'HitTest','off', ...
                    'PickableParts','none', ...
                    'Clipping','on', ...
                    'Tag','oops.OrientationField');
            else
                obj.Graphic.Parent = parent;
            end

            obj.updateGraphic();
        end

        function detach(obj)
        %DETACH Preserve the primitive for reuse outside the deleted mount group.

            if ~isempty(obj.Graphic) && isgraphics(obj.Graphic)
                obj.Graphic.Parent = [];
            end
        end

        function delete(obj)
        %DELETE Dispose of the application-owned reusable primitive.

            if ~isempty(obj.Graphic) && isgraphics(obj.Graphic)
                delete(obj.Graphic);
            end
        end

    end

    methods (Access=private)

        function updateGraphic(obj)
        %UPDATEGRAPHIC Rebuild vertices and colors on the existing patch.

            if isempty(obj.Graphic) || ~isgraphics(obj.Graphic)
                return;
            end

            if isempty(obj.X)
                set(obj.Graphic, ...
                    'Vertices',zeros(0,2), ...
                    'Faces',zeros(0,2), ...
                    'FaceVertexCData',zeros(0,3));
                return;
            end

            % Half-segment displacement scaled by local orientation magnitude.
            halfLength = 0.5*obj.Scale*obj.Magnitude;
            dx = halfLength.*cos(obj.Angle);
            dy = halfLength.*sin(obj.Angle);

            % Image y increases downward, so positive mathematical angles
            % require the opposite sign for their displayed y displacement.
            first = [obj.X+dx,obj.Y-dy];
            second = [obj.X-dx,obj.Y+dy];

            % Interleaved endpoints and one two-vertex face per axial segment.
            vertices = zeros(2*numel(obj.X),2);
            vertices(1:2:end,:) = first;
            vertices(2:2:end,:) = second;
            faces = reshape(1:2*numel(obj.X),2,[])';

            % One RGB color per segment, repeated for its two vertices.
            colors = obj.segmentColors();
            vertexColors = repelem(colors,2,1);

            set(obj.Graphic, ...
                'Vertices',vertices, ...
                'Faces',faces, ...
                'FaceVertexCData',vertexColors, ...
                'LineWidth',obj.LineWidth, ...
                'EdgeAlpha',obj.Alpha);
        end

        function colors = segmentColors(obj)
        %SEGMENTCOLORS Map direction or magnitude to direct RGB values.

            % Number of available direct RGB entries in the selected map.
            count = size(obj.Colormap,1);

            switch obj.ColorMode
                case "Direction"
                    % Axial angles repeat every pi and map to the cyclic azimuth LUT.
                    normalized = mod(obj.Angle,pi)/pi;
                    indices = round(normalized*(count-1))+1;
                    colors = obj.Colormap(indices,:);

                case "Magnitude"
                    % Order-like magnitudes outside [0,1] saturate at map endpoints.
                    normalized = min(1,max(0,obj.Magnitude));
                    indices = round(normalized*(count-1))+1;
                    colors = obj.Colormap(indices,:);

                otherwise
                    colors = repmat(obj.Color,numel(obj.X),1);
            end
        end

    end

end
