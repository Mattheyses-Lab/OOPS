% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

classdef ObjectMidline < matlabx.ui.axes.ImageAxesOverlayContent
%OBJECTMIDLINE Passive active-object midline mounted in an ImageAxes.
% One non-pickable line displays the ordered model coordinates without
% introducing selectable overlay state.

    properties (SetAccess=private)
        Points (:,2) double = zeros(0,2)
        Color (1,3) double {mustBeInRange(Color,0,1)} = [1 1 1]
        LineWidth (1,1) double {mustBePositive,mustBeFinite} = 1
    end

    properties (SetAccess=private)
        Graphic = []
    end

    methods

        function setData(obj,points)
        %SETDATA Store ordered local [x y] coordinates and update the line.

            validateattributes(points,{'numeric'},{'2d','ncols',2,'real','finite'});

            obj.Points = double(points);
            obj.updateGraphic();
        end

        function setStyle(obj,color,lineWidth)
        %SETSTYLE Apply the viewer-specific midline appearance.

            validateattributes(color,{'numeric'},{'size',[1 3],'real','finite','>=',0,'<=',1});
            validateattributes(lineWidth,{'numeric'},{'scalar','real','finite','positive'});

            obj.Color = double(color);
            obj.LineWidth = double(lineWidth);
            obj.updateGraphic();
        end

        function clear(obj)
        %CLEAR Remove midline data while retaining the reusable primitive.

            obj.Points = zeros(0,2);
            obj.updateGraphic();
        end

        function attach(obj,parent,~)
        %ATTACH Create or reparent the single passive line primitive.

            if isempty(obj.Graphic) || ~isgraphics(obj.Graphic)
                obj.Graphic = line(parent,NaN,NaN, ...
                    'HitTest','off', ...
                    'PickableParts','none', ...
                    'Clipping','on', ...
                    'Tag','oops.ObjectMidline');
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
        %DELETE Dispose of the application-owned line primitive.

            if ~isempty(obj.Graphic) && isgraphics(obj.Graphic)
                delete(obj.Graphic);
            end
        end

    end

    methods (Access=private)

        function updateGraphic(obj)
        %UPDATEGRAPHIC Apply current coordinates and appearance to the line.

            if isempty(obj.Graphic) || ~isgraphics(obj.Graphic)
                return;
            end

            if isempty(obj.Points)
                x = NaN;
                y = NaN;
            else
                x = obj.Points(:,1);
                y = obj.Points(:,2);
            end

            set(obj.Graphic, ...
                'XData',x, ...
                'YData',y, ...
                'Color',obj.Color, ...
                'LineWidth',obj.LineWidth);
        end

    end

end
