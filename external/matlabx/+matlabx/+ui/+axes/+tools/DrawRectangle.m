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

classdef DrawRectangle < matlabx.ui.axes.AxesTool
% matlabx.ui.axes.tools.DrawRectangle - draw a rectangle in the Host axes using images.roi.Rectangle



    %% Private UI/Graphics
    properties (Access = private, Transient, NonCopyable)
        RectROI (:,1) images.roi.Rectangle
        % listeners for ROI events
        ROIListeners event.listener
        % context menu options for ROI
        ROIContextMenu matlab.ui.container.ContextMenu
        ROIContextMenu_Delete matlab.ui.container.Menu
        % line through center from left edge midpoint to right edge midpoint
        WidthMidline matlab.graphics.primitive.Line
        % horizontal ray from center to closest edge of rectangle in +x direction
        XRay matlab.graphics.primitive.Line
        % arc between WidthMidline and XRay to show angle
        ArcPolyline matlab.graphics.primitive.Line
        % label to display RotationAngle
        AngleLabel matlab.graphics.primitive.Text
    end

    %% Appearance
    properties (Dependent)
        ROIColor (1,3) double
        ROILineWidth (1,1) double
        ROIFaceAlpha (1,1) double
        ROIMarkerSize (1,1) double

        AnnotationLineColor (1,3) double
        AnnotationLineWidth (1,1) double
        RotationAngleVisible (1,1) matlab.lang.OnOffSwitchState

        FontSize (1,1) double
        FontColor (1,3) double
    end

    properties (Access=private)
        ROIColor_ (1,3) double = [1 1 1]
        ROILineWidth_ (1,1) double = 1
        ROIFaceAlpha_ (1,1) double = 0.1
        ROIMarkerSize_ (1,1) double = 8

        AnnotationLineColor_ (1,3) double = [1 1 1]
        AnnotationLineWidth_ (1,1) double = 0.5
        RotationAngleVisible_ (1,1) matlab.lang.OnOffSwitchState = 'on'

        FontSize_ (1,1) double = 12
        FontColor_ (1,3) double = [1 1 1]
    end

    %% Behavior
    properties (Dependent)
        % RotationAngleMode - controls how RotationAngle output values and annotations behave
        % 'full-circle'
        %   Use default value from images.roi.Rectangle — in range [0,360), CCW from +x-axis for x -> right, y -> down
        % 'half-circle'
        %   Wrap angles to fall in range [-90,90), CCW from +x-axis for x -> right, y -> down
        RotationAngleMode (1,:) char
    end

    properties (Access=private)
        RotationAngleMode_ (1,:) char {mustBeMember(RotationAngleMode_,{'full-circle','half-circle'})} = 'full-circle'
    end

    %% Internal helpers
    properties (Access=private, Dependent=true)
        RotationAngleOut % the full or wrapped RotationAngle that is passed as output and used in annotations
        RotationAngleDisplay % formatted text output used to display the angle
    end

    %% Callbacks
    properties
        % Callback fcn name:    event data struct
        % ROIPreviewMovedFcn:   data.ROI
        % ROIMoveCommittedFcn:  data.ROI
        % ROIDeletedFcn:
        ROIPreviewMovedFcn
        ROIMoveCommittedFcn
        ROIDeletedFcn
    end

    %% Helpers (read-only)
    properties (SetAccess=private)
        ROIExists (1,1) logical = false
    end


    methods

        function obj = DrawRectangle(host)
            obj@matlabx.ui.axes.AxesTool(host, "DrawRectangle",...
                'Tooltip','Draw scan area',...
                'AxesType',"image",...
                'Icon',matlabx.internal.Paths.icons('RectangleROIIcon.png'),...
                'Priority',10,...
                'Style','push',...
                'IsExclusive',true,...
                'PassivelyInterceptsMove',true,...
                'PassivelyInterceptsDown',true,...
                'PassivelyInterceptsUp',true);
            % rectangular ROI
            obj.RectROI = images.roi.Rectangle.empty();
            % annotation lines
            obj.WidthMidline = matlab.graphics.primitive.Line.empty();
            obj.ArcPolyline = matlab.graphics.primitive.Line.empty();
            obj.XRay = matlab.graphics.primitive.Line.empty();
            % annotation labels
            obj.AngleLabel = matlab.graphics.primitive.Text.empty();
            % set up context menu
            obj.ROIContextMenu = uicontextmenu(obj.Host.ParentFig);
            % set up context menu items
            obj.ROIContextMenu_Delete = uimenu(obj.ROIContextMenu,"Text","Delete","MenuSelectedFcn",@(~,~) obj.deleteROI());
        end

        % Toolbar push arms drawing for the next background click.
        function onPush(obj)
            obj.setMode('PrimedToDraw', true);
        end

        % Called AFTER installed from Host, use for any extra required startup actions
        function onInstall(obj)
            obj.addMode('PrimedToDraw'); % next background click starts drawing
            obj.addMode('DrawingRectangle'); % rectangle is currently being drawn
            obj.addMode('HoverRectangle'); % cursor is hovering on obj.RectROI
        end

        % Called AFTER uninstalled from Host, use for any extra required cleanup actions
        function onUninstall(obj)
            obj.removeMode('PrimedToDraw');
            obj.removeMode('DrawingRectangle');
            obj.removeMode('HoverRectangle');
        end

    end

    %% Internal update helpers
    methods (Access=private)

        function updateAnnotations(obj)
            if ~obj.graphicsReady()
                return
            end

            % get coordinates for annotations
            [WidthMidlineXY,XRayXY,ArcPolylineXY,LabelXY] = obj.getAnnotationData();
            % set XData and YData of annotation lines
            set(obj.WidthMidline,"XData",WidthMidlineXY(1,:),"YData",WidthMidlineXY(2,:));
            set(obj.XRay,"XData",XRayXY(1,:),"YData",XRayXY(2,:));
            set(obj.ArcPolyline,"XData",ArcPolylineXY(1,:),"YData",ArcPolylineXY(2,:));
            % set Position and String of annotation labels
            set(obj.AngleLabel,"Position",LabelXY,"String",obj.RotationAngleDisplay,"FontSize",obj.FontSize_);
            obj.applyAppearance();
            
        end

        function applyAppearance(obj)
            if ~isempty(obj.RectROI) && isvalid(obj.RectROI)
                set(obj.RectROI, ...
                    'Color',obj.ROIColor_, ...
                    'LineWidth',obj.ROILineWidth_, ...
                    'FaceAlpha',obj.ROIFaceAlpha_, ...
                    'MarkerSize',obj.ROIMarkerSize_);
            end

            if ~isempty(obj.WidthMidline) && isvalid(obj.WidthMidline)
                set(obj.WidthMidline, ...
                    "Color",obj.AnnotationLineColor_, ...
                    "LineWidth",obj.AnnotationLineWidth_, ...
                    "Visible",'on');
            end

            rotationVisible = obj.RotationAngleVisible_;

            if ~isempty(obj.XRay) && isvalid(obj.XRay)
                set(obj.XRay, ...
                    "Color",obj.AnnotationLineColor_, ...
                    "LineWidth",obj.AnnotationLineWidth_, ...
                    "Visible",rotationVisible);
            end

            if ~isempty(obj.ArcPolyline) && isvalid(obj.ArcPolyline)
                set(obj.ArcPolyline, ...
                    "Color",obj.AnnotationLineColor_, ...
                    "LineWidth",obj.AnnotationLineWidth_, ...
                    "Visible",rotationVisible);
            end

            if ~isempty(obj.AngleLabel) && isvalid(obj.AngleLabel)
                set(obj.AngleLabel, ...
                    "FontSize",obj.FontSize_, ...
                    "Color",obj.FontColor_, ...
                    "Visible",rotationVisible);
            end
        end

        function TF = graphicsReady(obj)
            TF = ~isempty(obj.RectROI) && isvalid(obj.RectROI) ...
                && ~isempty(obj.WidthMidline) && isvalid(obj.WidthMidline) ...
                && ~isempty(obj.XRay) && isvalid(obj.XRay) ...
                && ~isempty(obj.ArcPolyline) && isvalid(obj.ArcPolyline) ...
                && ~isempty(obj.AngleLabel) && isvalid(obj.AngleLabel);
        end

        function beginDrawingFromEvent(obj, E)
            % skip toolbar buttons
            if ~isempty(ancestor(E.Target,'matlab.ui.container.Toolbar')) || isa(E.Target,'matlab.graphics.shape.internal.Button')
                return
            end

            % Existing ROI manipulation wins over a newly armed draw.
            if obj.Mode.HoverRectangle
                E.stop(); % clicks on existing ROI should not open host context menu
                return
            end

            XY = obj.Host.cursorPosition;
            if isempty(XY), return; end

            % Replace the old ROI immediately so stale annotations do not flash
            % while images.roi.Rectangle enters its interactive draw state.
            if obj.ROIExists
                obj.deleteROI('Emit',false);
            end

            obj.createROI();
            obj.setMode('DrawingRectangle',true);
            obj.RectROI.beginDrawingFromPoint(XY);
            E.stop();
        end

        function finishDrawing(obj)
            if obj.Mode.DrawingRectangle
                obj.setMode('DrawingRectangle',false);
                obj.setMode('PrimedToDraw',false);
            end
        end

    end

    %% Active event hooks (only when Enabled==true && IsInterceptor==true)
    methods

        function onDown(obj, E)
            obj.beginDrawingFromEvent(E);
        end


        function onUp(obj, ~)
            obj.finishDrawing();
        end

    end

    %% Passive event hooks (only when Installed==true && IsPassiveInterceptor==true)
    methods

        function onPassiveMove(obj,E)

            % cursor target (parent) is our obj.RectROI
            if isa(E.Target.Parent,'images.roi.Rectangle') && strcmp(E.Target.Parent.Tag,'RectROI')
                obj.setMode('HoverRectangle',true);
            else % cursor target is anything else
                obj.setMode('HoverRectangle',false);
            end

        end

        function onPassiveDown(obj,E)
            % if hovering on existing ROI -> stop propagation and return
            if obj.Mode.HoverRectangle
                E.stop(); % clicks on existing ROI should not open host context menu
                return
            end

            if obj.Mode.PrimedToDraw && E.MouseChord == "click"
                obj.beginDrawingFromEvent(E);
            end
        end

        function onPassiveUp(obj,~)
            obj.finishDrawing();
        end

    end

    %% Host-facing helpers
    methods

        function setROIPosition(obj,data)
            % Host calls to set ROI position
            % build position vector
            pos = [...
                data.CenterX-data.Width/2,...
                data.CenterY-data.Height/2,...
                data.Width,...
                data.Height];
            % return if invalid position/angle, delete ROI first if it exists
            if any(isnan([pos,data.RotationAngle])), if obj.ROIExists, obj.deleteROI(); end; return; end
            % if ROI does not exist, create it
            if ~obj.ROIExists, obj.createROI(); end
            % update ROI
            set(obj.RectROI,'Position',pos,'RotationAngle',data.RotationAngle);
            % refresh annotations
            obj.updateAnnotations();
        end

        function pointer = getPreferredPointer(obj)
            % Host calls to get desired pointer
            if obj.Mode.HoverRectangle
                pointer = 'default';
            elseif obj.Mode.PrimedToDraw
                pointer = 'crosshair';
            else
                pointer = '';
            end
        end


    end

    %% Private helpers (listener callbacks, ROI/annotations lifecycle)
    methods (Access=private)

        function onROIMoving(obj,roi)
            % update annotations
            obj.updateAnnotations();
            if ~isempty(obj.ROIPreviewMovedFcn)
                % get the event data
                data = obj.getROIDataStruct(roi);
                % fire callback
                obj.ROIPreviewMovedFcn(obj,data)
            end
        end

        function onROIMoved(obj,roi)
            % 1) snap width/height to integer pixels (optional but ok)
            matlabx.image.roi.snapRectangleROISize(roi, 1);
            % 2) clamp rotated ROI to full image bounds (region-local image size)
            sz = obj.Host.ImageSize();
            matlabx.image.roi.clampRectangleROIToImage(roi, sz(1:2));
            % 3) refresh overlay / derived graphics
            obj.updateAnnotations();
            % 4) push to model
            if ~isempty(obj.ROIMoveCommittedFcn)
                data = obj.getROIDataStruct(roi);  % get event data
                obj.ROIMoveCommittedFcn(obj, data); % fire callback
            end
        end

        function createROI(obj)
            if isempty(obj.RectROI) || ~isvalid(obj.RectROI)
                ax = obj.Host.getAxes();
                % create the rectangle ROI
                obj.RectROI = images.roi.Rectangle(...
                    'Parent',ax,...
                    'Tag','RectROI',...
                    'Rotatable',true,...
                    'ContextMenu',obj.ROIContextMenu,...
                    'Color',obj.ROIColor,...
                    'LineWidth',obj.ROILineWidth,...
                    'FaceAlpha',obj.ROIFaceAlpha,...
                    'MarkerSize',obj.ROIMarkerSize);
                % line segment from left edge midpoint to right edge midpoint
                obj.WidthMidline = line(...
                    "Parent",ax,...
                    "XData",NaN,"YData",NaN,...
                    "Color",obj.AnnotationLineColor,...
                    "LineWidth",obj.AnnotationLineWidth,...
                    "HitTest","off",...
                    "PickableParts","none");
                % ray from ROI center to first rectangle edge intercept in the +x (right) direction
                obj.XRay = line(...
                    "Parent",ax,...
                    "XData",NaN,"YData",NaN,...
                    "Color",obj.AnnotationLineColor,...
                    "LineWidth",obj.AnnotationLineWidth,...
                    "HitTest","off",...
                    "PickableParts","none",...
                    "LineStyle","--");
                % arc polyline to show angle between WidthMidline and XRay
                obj.ArcPolyline = line(...
                    "Parent",ax,...
                    "XData",NaN,"YData",NaN,...
                    "Color",obj.AnnotationLineColor,...
                    "LineWidth",obj.AnnotationLineWidth,...
                    "HitTest","off",...
                    "PickableParts","none");
                % annotation labels
                obj.AngleLabel = text("Parent",ax,...
                    "Position",[NaN NaN],...
                    "String","",...
                    "VerticalAlignment","middle",...
                    "HorizontalAlignment","center",...
                    "HitTest","off",...
                    "PickableParts","none",...
                    "FontSize",obj.FontSize_);

                % attach listeners
                obj.ROIListeners(1) = addlistener(obj.RectROI, 'MovingROI', @(~, ~) obj.onROIMoving(obj.RectROI));
                obj.ROIListeners(2) = addlistener(obj.RectROI, 'ROIMoved', @(~, ~) obj.onROIMoved(obj.RectROI));
                % indicate that the ROI exists
                obj.ROIExists = true;
                obj.applyAppearance();
            end
        end

        function deleteROI(obj, opts)
            arguments
                obj
                opts.Emit (1,1) logical = true
            end

            % detach listeners and replace with empty array of event.listener
            if ~isempty(obj.ROIListeners)
                delete(obj.ROIListeners(isvalid(obj.ROIListeners)));
            end
            obj.ROIListeners = event.listener.empty;
            % delete the ROI and replace with empty array of images.roi.Rectangle
            if ~isempty(obj.RectROI)
                delete(obj.RectROI(isvalid(obj.RectROI)));
            end
            obj.RectROI = images.roi.Rectangle.empty();
            % delete the annotation lines and replace with empty array of matlab.graphics.primitive.Line
            if ~isempty(obj.WidthMidline)
                delete(obj.WidthMidline(isvalid(obj.WidthMidline)));
            end
            obj.WidthMidline = matlab.graphics.primitive.Line.empty();
            if ~isempty(obj.XRay)
                delete(obj.XRay(isvalid(obj.XRay)));
            end
            obj.XRay = matlab.graphics.primitive.Line.empty();            
            if ~isempty(obj.ArcPolyline)
                delete(obj.ArcPolyline(isvalid(obj.ArcPolyline)));
            end
            obj.ArcPolyline = matlab.graphics.primitive.Line.empty();
            % delete the annotation labels and replace with empty array of matlab.graphics.primitive.Text
            if ~isempty(obj.AngleLabel)
                delete(obj.AngleLabel(isvalid(obj.AngleLabel)));
            end
            obj.AngleLabel = matlab.graphics.primitive.Text.empty();
            % indicate the ROI does not exist
            obj.ROIExists = false;
            % fire ROIDeletedFcn callback if it exists
            if opts.Emit && ~isempty(obj.ROIDeletedFcn)
                obj.ROIDeletedFcn();
            end
        end

    end

    %% Private helpers (geometry)
    methods (Access=private)

        function [WidthMidline,XRay,ArcPolyline,LabelPosition] = getAnnotationData(obj)
            % get ROI vertices (start top-left, then CCW with x right, y down axes)
            V = obj.RectROI.Vertices;

            % get center point
            C = mean(V, 1);        % [cx, cy]
            cx = C(1);
            cy = C(2);

            % left segment midpoint between vertices 1 and 2 -> [x1, y1]
            ML  = matlabx.utils.math.getMidpoint(V(1,:),V(2,:));
            % right segment midpoint between vertices 3 and 4 -> [x2, y2]
            MR = matlabx.utils.math.getMidpoint(V(3,:),V(4,:));
            % full midline segment along width, concatenate and transpose -> [x1 x2; y1 y2]
            WidthMidline = [ML;MR].';

            % RotationAngle used to draw angle arc
            theta = obj.RotationAngleOut;

            % right half: from center to the right edge
            P_width = MR;                      % endpoint
            r_width = norm(P_width - C);       % distance from center


            hitPts = [];

            for i = 1:4
                p1 = V(i,:);
                p2 = V(mod(i,4) + 1,:);      % wrap 4->1

                dy = p2(2) - p1(2);
                if abs(dy) < eps
                    continue;                % edge is horizontal, may be parallel to the ray
                end

                % Solve for s where edge crosses y = cy
                s = (cy - p1(2)) / dy;       % p = p1 + s*(p2 - p1)
                if s < 0 || s > 1
                    continue;                % outside the segment
                end

                % Intersection point on the edge
                x_int = p1(1) + s*(p2(1) - p1(1));
                y_int = cy;

                % Now solve for t on the ray: cx + t = x_int  ->  t = x_int - cx
                t = x_int - cx;
                if t >= 0
                    hitPts(end+1,:) = [x_int, y_int];
                end
            end

            if isempty(hitPts)
                WidthMidline = [NaN;NaN];
                XRay = [NaN;NaN];
                ArcPolyline = [NaN;NaN];
                LabelPosition = [NaN;NaN];
                return
            end

            % Choose the closest intersection along +x from the center
            [~, k] = min( (hitPts(:,1) - cx).^2 );
            P_axis = hitPts(k,:);                % endpoint of internal x-axis line
            r_axis = norm(P_axis - C);           % distance from center

            XRay = [C;P_axis].';

            % set the arc radius, set based on RotationAngleMode
            switch obj.RotationAngleMode
                case 'full-circle'
                    r_arc = 0.5 * min(r_width, r_axis);   % must be < 1 to keep arc inside ROI
                case 'half-circle'
                    r_arc = 0.8*min(r_width, r_axis);
            end

            % number of points to form the arc polyline
            N = 64;
            % theta values for each point
            thetaArc = linspace(0, theta, N);   % degrees

            % arc coordinates in ROI frame
            dxArc = r_arc * cosd(thetaArc);
            dyArc = -r_arc * sind(thetaArc);           % minus because y is down

            % add center coordinates to get real-world coordinates
            xArc = cx + dxArc;
            yArc = cy + dyArc;

            ArcPolyline = [xArc;yArc];

            % get position for the RotationAngle label (positioned in approximate 'radial center' of arc)
            r_label    = 0.65 * r_arc;
            thetaLabel = theta / 2;
            
            dxLab = r_label * cosd(thetaLabel);
            dyLab = -r_label * sind(thetaLabel);
            
            % label position (x,y)
            LabelPosition = [cx + dxLab, cy + dyLab];

        end



    end

    %% Derived getters
    methods

        function theta = get.RotationAngleOut(obj)
            switch obj.RotationAngleMode_
                case 'full-circle'
                    theta = obj.RectROI.RotationAngle;
                case 'half-circle'
                    theta = mod(obj.RectROI.RotationAngle + 90, 180) - 90;
            end
        end

        function str = get.RotationAngleDisplay(obj)
            str = sprintf('%.3g°', obj.RotationAngleOut);
        end

    end

    %% Set/Get for public props with private backing
    methods

        function val = get.ROIColor(obj)
            val = obj.ROIColor_;
        end

        function set.ROIColor(obj,val)
            obj.ROIColor_ = val;
            obj.applyAppearance();
        end

        function val = get.ROILineWidth(obj)
            val = obj.ROILineWidth_;
        end

        function set.ROILineWidth(obj,val)
            obj.ROILineWidth_ = val;
            obj.applyAppearance();
        end

        function val = get.ROIFaceAlpha(obj)
            val = obj.ROIFaceAlpha_;
        end

        function set.ROIFaceAlpha(obj,val)
            obj.ROIFaceAlpha_ = val;
            obj.applyAppearance();
        end

        function val = get.ROIMarkerSize(obj)
            val = obj.ROIMarkerSize_;
        end

        function set.ROIMarkerSize(obj,val)
            obj.ROIMarkerSize_ = val;
            obj.applyAppearance();
        end

        function val = get.AnnotationLineColor(obj)
            val = obj.AnnotationLineColor_;
        end

        function set.AnnotationLineColor(obj,val)
            obj.AnnotationLineColor_ = val;
            obj.applyAppearance();
        end

        function val = get.AnnotationLineWidth(obj)
            val = obj.AnnotationLineWidth_;
        end

        function set.AnnotationLineWidth(obj,val)
            obj.AnnotationLineWidth_ = val;
            obj.applyAppearance();
        end

        function val = get.RotationAngleVisible(obj)
            val = obj.RotationAngleVisible_;
        end

        function set.RotationAngleVisible(obj,val)
            obj.RotationAngleVisible_ = val;
            obj.applyAppearance();
        end

        function val = get.RotationAngleMode(obj)
            val = obj.RotationAngleMode_;
        end

        function set.RotationAngleMode(obj,val)
            mustBeMember(val,{'full-circle','half-circle'});
            obj.RotationAngleMode_ = val;
            obj.updateAnnotations();
        end

        function val = get.FontSize(obj)
            val = obj.FontSize_;
        end

        function set.FontSize(obj,val)
            obj.FontSize_ = val;
            obj.applyAppearance();
        end

        function val = get.FontColor(obj)
            val = obj.FontColor_;
        end

        function set.FontColor(obj,val)
            obj.FontColor_ = val;
            obj.applyAppearance();
        end

    end

    %% Helpers
    methods

        function data = getROIDataStruct(obj,roi)
            % Get cx, cy, w, and h from roi Position property
            pos = roi.Position; % Get the current position of the ROI
            cx = pos(1) + pos(3) / 2; % Calculate center x
            cy = pos(2) + pos(4) / 2; % Calculate center y
            w = pos(3); % Width of the ROI
            h = pos(4); % Height of the ROI

            % % get output RotationAngle
            theta = obj.RotationAngleOut;

            % build the struct
            data = struct(...
                'CenterX',cx,...
                'CenterY',cy,...
                'Width',w,...
                'Height',h,...
                'RotationAngle',theta);
        end


    end

    %% Teardown
    methods (Access=protected)

        % called at the beginning of superclass delete()
        function teardown(obj)
            % detach listeners
            if ~isempty(obj.ROIListeners)
                delete(obj.ROIListeners(isvalid(obj.ROIListeners)));
            end
            % replace listener property with empty array of event.listener
            obj.ROIListeners = event.listener.empty;
            % delete annotation lines and replace with empty array of matlab.graphics.primitive.Line
            if ~isempty(obj.WidthMidline)
                delete(obj.WidthMidline(isvalid(obj.WidthMidline)));
                obj.WidthMidline = matlab.graphics.primitive.Line.empty();
            end
            if ~isempty(obj.XRay)
                delete(obj.XRay(isvalid(obj.XRay)));
                obj.XRay = matlab.graphics.primitive.Line.empty();
            end
            if ~isempty(obj.ArcPolyline)
                delete(obj.ArcPolyline(isvalid(obj.ArcPolyline)));
                obj.ArcPolyline = matlab.graphics.primitive.Line.empty();
            end
            % delete annotation labels and replace with empty array of matlab.graphics.primitive.Text
            if ~isempty(obj.AngleLabel)
                delete(obj.AngleLabel(isvalid(obj.AngleLabel)))
                obj.AngleLabel = matlab.graphics.primitive.Text.empty();
            end
            % Delete RectROI if it exists
            if ~isempty(obj.RectROI)
                if isvalid(obj.RectROI)
                    delete(obj.RectROI);
                end
            end
        end

    end


end
