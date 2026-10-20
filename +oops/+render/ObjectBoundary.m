% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ObjectBoundary < matlabx.ui.axes.ImageAxesOverlayContent
%OBJECTBOUNDARY Passive active-object outline mounted in an ImageAxes.
% The content owns one non-pickable patch. It does not participate in the
% selectable polygon registry used by the two main image viewers.

    properties (SetAccess=private)
        Vertices (:,2) double = zeros(0,2)
        Color (1,3) double {mustBeInRange(Color,0,1)} = [1 1 1]
        LineWidth (1,1) double {mustBePositive,mustBeFinite} = 1
    end

    properties (SetAccess=private)
        Graphic = []
    end

    methods

        function setData(obj,vertices)
        %SETDATA Store ordered local [x y] vertices and update the outline.

            validateattributes(vertices,{'numeric'},{'2d','ncols',2,'real','finite'});

            obj.Vertices = double(vertices);
            obj.updateGraphic();
        end

        function setStyle(obj,color,lineWidth)
        %SETSTYLE Apply the configured object-boundary color and base width.

            validateattributes(color,{'numeric'},{'size',[1 3],'real','finite','>=',0,'<=',1});
            validateattributes(lineWidth,{'numeric'},{'scalar','real','finite','positive'});

            obj.Color = double(color);
            obj.LineWidth = double(lineWidth);
            obj.updateGraphic();
        end

        function clear(obj)
        %CLEAR Remove boundary data while retaining the reusable primitive.

            obj.Vertices = zeros(0,2);
            obj.updateGraphic();
        end

        function attach(obj,parent,~)
        %ATTACH Create or reparent the passive closed patch outline.

            if isempty(obj.Graphic) || ~isgraphics(obj.Graphic)
                obj.Graphic = patch( ...
                    'Parent',parent, ...
                    'XData',NaN, ...
                    'YData',NaN, ...
                    'FaceColor','none', ...
                    'HitTest','off', ...
                    'PickableParts','none', ...
                    'Clipping','on', ...
                    'Tag','oops.ObjectBoundary');
            else
                obj.Graphic.Parent = parent;
            end

            obj.updateGraphic();
        end

        function detach(obj)
        %DETACH Preserve the primitive outside the deleted mount group.

            if ~isempty(obj.Graphic) && isgraphics(obj.Graphic)
                obj.Graphic.Parent = [];
            end
        end

        function delete(obj)
        %DELETE Dispose of the application-owned patch primitive.

            if ~isempty(obj.Graphic) && isgraphics(obj.Graphic)
                delete(obj.Graphic);
            end
        end

    end

    methods (Access=private)

        function updateGraphic(obj)
        %UPDATEGRAPHIC Apply current vertices and appearance to the patch.

            if isempty(obj.Graphic) || ~isgraphics(obj.Graphic)
                return;
            end

            if isempty(obj.Vertices)
                x = NaN;
                y = NaN;
            else
                x = obj.Vertices(:,1);
                y = obj.Vertices(:,2);
            end

            set(obj.Graphic, ...
                'XData',x, ...
                'YData',y, ...
                'EdgeColor',obj.Color, ...
                'LineWidth',obj.LineWidth);
        end

    end

end
