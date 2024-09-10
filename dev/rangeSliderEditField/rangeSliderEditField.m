classdef rangeSliderEditField < matlab.ui.componentcontainer.ComponentContainer
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

    properties
        % min and max of the slider track
        Limits double = [0,1]
        % height of the track
        TrackHeight (1,1) double = 4
        % height of the range
        RangeHeight (1,1) double = 7
        % overall height of the slider component (excluding labels)
        Height (1,1) double = 25
        % flag to determine whether fractional values are rounded
        RoundFractionalValues (1,1) matlab.lang.OnOffSwitchState = 'off'
        % color of the thumb faces
        ThumbFaceColor (1,3) double {mustBeInRange(ThumbFaceColor,0,1)} = [1 1 1]
        % color of the thumb edges
        ThumbEdgeColor (1,3) double {mustBeInRange(ThumbEdgeColor,0,1)} = [0 0 0]
        % track colormap
        Colormap (256,3) double = gray

        % text displayed above the slider
        Title (1,:) char = "Untitled slider"
        % size of the font
        FontSize (1,1) double = 12
        % color of the font
        FontColor (1,3) double = [0 0 0]

    end

    properties(SetAccess=private)
        % true if the slider is currently moving
        isSliding (1,1) logical = false
        % index of the active thumb
        activeThumbIdx (1,1) = NaN
    end

    properties(SetObservable=true,Dependent=true)
        Value (1,2) double = [0,1]
    end

    properties(Access=private,Dependent=true)
        % ancestor figure of the component
        parentFig
    end

    properties(Access = private,Transient,NonCopyable)
        % outermost grid for the entire component
        containerGrid (1,1) matlab.ui.container.GridLayout

        % uilabel for the Title
        titleLabel (1,1) matlab.ui.control.Label
        % uilabel for the minimum value editfield
        minLabel (1,1) matlab.ui.control.Label
        % uilabel for the maximum value editfield
        maxLabel (1,1) matlab.ui.control.Label

        % axes to hold slider thumb
        sliderThumbAxes (1,1) matlab.ui.control.UIAxes
        % patch object for slider track
        trackPatch (1,1) matlab.graphics.primitive.Patch
        % patch object for slider range
        rangePatch (1,1) matlab.graphics.primitive.Patch
        % the slider thumb
        sliderThumb (:,1) slidingNode
        % editfield for text control of slider value
        sliderValueEditField (:,1) matlab.ui.control.NumericEditField

        % PostSet listener for the slider value
        sliderValueListener (1,1)
        % context menu for the thumb
        thumbCM (:,1)
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        ValueChanged % ValueChangedFcn callback property will be generated
    end
    
    methods(Access=protected)
    
        function setup(obj)

            obj.Units = "normalized";
            obj.Position = [0 0 1 1];

            % grid layout manager to enclose all the components
            obj.containerGrid = uigridlayout(obj,...
                [1,3],...
                "ColumnWidth",{'1x',50,50},...
                "RowHeight",{'fit',obj.TrackHeight},...
                "BackgroundColor",[0 0 0],...
                "Padding",[5 5 5 5],...
                "Scrollable","on",...
                "RowSpacing",0);

            % uilabel to diaply the title text
            obj.titleLabel = uilabel(obj.containerGrid,...
                "Text",obj.Title,...
                "FontColor",obj.FontColor,...
                "FontSize",obj.FontSize);
            obj.titleLabel.Layout.Row = 1;
            obj.titleLabel.Layout.Column = 1;

            % uilabel for the minimum value editfield
            obj.minLabel = uilabel(obj.containerGrid,...
                "Text","Min",...
                "FontColor",obj.FontColor,...
                "FontSize",obj.FontSize);
            obj.minLabel.Layout.Row = 1;
            obj.minLabel.Layout.Column = 2;

            % uilabel for the maximum value editfield
            obj.maxLabel = uilabel(obj.containerGrid,...
                "Text","Max",...
                "FontColor",obj.FontColor,...
                "FontSize",obj.FontSize);
            obj.maxLabel.Layout.Row = 1;
            obj.maxLabel.Layout.Column = 3;

            % axes to hold the slider thumb
            obj.sliderThumbAxes = uiaxes(obj.containerGrid,...
                'XTick',[],...
                'YTick',[],...
                'XLim',obj.Limits,...
                'YLim',[0 obj.Height],...
                'XColor','none',...
                'YColor','none',...
                'Color','none',...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],...
                'LineWidth',1,...
                'Box','off',...
                'HitTest','on',...
                'PickableParts','all',...
                'Visible','off',...
                'ButtonDownFcn',@(o,e) obj.trackClicked(o,e));
            obj.sliderThumbAxes.Layout.Row =  2;
            obj.sliderThumbAxes.Layout.Column =  1;
            obj.sliderThumbAxes.Toolbar.Visible = 'off';
            disableDefaultInteractivity(obj.sliderThumbAxes)

            % create the patch object for the track
            obj.trackPatch = patch(obj.sliderThumbAxes,...
                'Faces',[1,2,3,4],...
                'Vertices',[0,0;1,0;1,1;0,1],...
                'EdgeColor',[0 0 0],...
                'FaceColor','flat',...
                'PickableParts','none',...
                'HitTest','off',...
                'LineWidth',0.5);

            % create the patch object for the range
            obj.rangePatch = patch(obj.sliderThumbAxes,...
                'Faces',[1,2,3,4],...
                'Vertices',[0,0;1,0;1,1;0,1],...
                'EdgeColor',[0 0 0],...
                'FaceColor','interp',...
                'PickableParts','none',...
                'HitTest','off',...
                'LineWidth',0.5);

            % create the lower value node
            obj.sliderThumb(1) = slidingNode(obj.sliderThumbAxes,...
                "EdgeColor",obj.ThumbEdgeColor,...
                "FaceColor",obj.ThumbFaceColor,...
                "Value",0,...
                "YPosition",0.5*obj.Height,...
                "ButtonDownFcn",@(o,e) obj.thumbClicked(o,e),...
                "ID",1,...
                "EdgeWidth",0.5);

            % create the upper value node
            obj.sliderThumb(2) = slidingNode(obj.sliderThumbAxes,...
                "EdgeColor",obj.ThumbEdgeColor,...
                "FaceColor",obj.ThumbFaceColor,...
                "Value",1,...
                "YPosition",0.5*obj.Height,...
                "ButtonDownFcn",@(o,e) obj.thumbClicked(o,e),...
                "ID",2,...
                "EdgeWidth",0.5);

            % set up listener for Value to enable the ValueChanged callback
            obj.sliderValueListener = addlistener(...
                obj,'Value',...
                'PostSet',@obj.valueChanged);

            % editfield for text input control of low slider value
            obj.sliderValueEditField(1) = uieditfield(obj.containerGrid,"numeric",...
                'Limits',obj.Limits,...
                'Value',obj.Value(1),...
                'ValueChangedFcn',@(o,e) obj.sliderEditfieldValueChanged(o,e),...
                'UserData',1);
            obj.sliderValueEditField(1).Layout.Row = 2;
            obj.sliderValueEditField(1).Layout.Column = 2;

            % editfield for text input control of high slider value
            obj.sliderValueEditField(2) = uieditfield(obj.containerGrid,"numeric",...
                'Limits',obj.Limits,...
                'Value',obj.Value(2),...
                'ValueChangedFcn',@(o,e) obj.sliderEditfieldValueChanged(o,e),...
                'UserData',2);
            obj.sliderValueEditField(2).Layout.Row = 2;
            obj.sliderValueEditField(2).Layout.Column = 3;

        end

        function update(obj)
            % set size of gridlayout manager row
            obj.containerGrid.RowHeight{2} = obj.Height;

            % set size and color of font for labels
            set([obj.titleLabel,obj.minLabel,obj.maxLabel],...
                "FontSize",obj.FontSize,...
                "FontColor",obj.FontColor);

            % update title label text
            obj.titleLabel.Text = obj.Title;

            % set the limits of the slider axes
            set(obj.sliderThumbAxes,'XLim',obj.Limits,'YLim',[0 obj.Height])

            % set vertical position of slider thumbs
            obj.sliderThumb(1).YPosition = 0.5*obj.Height;
            obj.sliderThumb(2).YPosition = 0.5*obj.Height;
            % set the limits of the editfield
            obj.sliderValueEditField(1).Limits = [obj.Limits(1) obj.sliderThumb(2).Value];
            obj.sliderValueEditField(2).Limits = [obj.sliderThumb(1).Value obj.Limits(2)];
            % set position of thumbs to fall within slider limits
            obj.sliderThumb(1).Value = max(obj.sliderThumb(1).Value,obj.Limits(1));
            obj.sliderThumb(2).Value = min(obj.sliderThumb(2).Value,obj.Limits(2)); 
            % background color of the component
            obj.containerGrid.BackgroundColor = obj.BackgroundColor;

            % adjust the coordinates of the track patch
            [Vt,Ft,Ct] = obj.getTrackPatchData();
            set(obj.trackPatch,...
                "Vertices",Vt,...
                "Faces",Ft,...
                "FaceVertexCData",Ct);

            % adjust the coordinates of the range patch
            [Vr,Fr,Cr] = obj.getRangePatchData();
            set(obj.rangePatch,...
                "Vertices",Vr,...
                "Faces",Fr,...
                "FaceVertexCData",Cr);

            % update thumb colors
            obj.sliderThumb(1).FaceColor = obj.ThumbFaceColor;
            obj.sliderThumb(2).FaceColor = obj.ThumbFaceColor;
            obj.sliderThumb(1).EdgeColor = obj.ThumbEdgeColor;
            obj.sliderThumb(2).EdgeColor = obj.ThumbEdgeColor;
        end
    
    end


    %% destructor

    methods

        function delete(obj)

            delete(obj.sliderValueListener)

        end

    end

    %% helper methods

    methods

        function [V,F,C] = getRangePatchData(obj)
            % Vertices (V), Faces (F), and FaceVertexCData (C) for 
            % the rectangular patch object showing the range

            sliderValue = obj.Value;
            % X and Y coordinates of each vertex along the bottom of colorbar (left to right)
            bottomX = (linspace(sliderValue(1),sliderValue(2),256)).';
            bottomY = repmat(0.5*(obj.Height-obj.RangeHeight),size(bottomX));
            % coordinates of each vertex along the top of colorbar (right to left)
            topX = flipud(bottomX);
            topY = bottomY + obj.RangeHeight;
            % 512 total vertices, 256 on top, 256 on bottom (two vertices per color in the colormap)
            V = [bottomX,bottomY;topX,topY];
            % one face made of vertices around the rectangle border
            F = 1:512;
            % RGB triplets for each vertex, such that the color of the vertex at V(n,:) is C(n,:)
            C = vertcat(obj.Colormap,flipud(obj.Colormap));
        end

        function [V,F,C] = getTrackPatchData(obj)
            % Vertices (V), Faces (F), and FaceVertexCData (C) for 
            % the rectangular patch object showing the track

            sliderLimits = obj.Limits;
            sliderValue = obj.Value;
            % x values
            leftX = sliderLimits(1);
            rightX = sliderLimits(2);
            midX = mean(sliderValue);
            % y values
            bottomY = 0.5*(obj.Height - obj.TrackHeight);
            topY = bottomY + obj.TrackHeight;
            % x and y vertices
            Vx = [leftX;midX;rightX;rightX;midX;leftX];
            Vy = [bottomY;bottomY;bottomY;topY;topY;topY];
            % 256 total vertices, one per color in the colormap
            V = [Vx,Vy];
            % one face made of vertices around the rectangle border
            F = [1,2,5,6;2,3,4,5];
            % RGB triplets for each vertex, such that the color of the vertex at Vertices(n,:) is FaceVertexCData(n,:)
            C = obj.Colormap([1,256],:);
        end

    end

    methods

        function Value = get.Value(obj)
            % get the component value based on the position of the slider thumb
            Value = [obj.sliderThumb(1).Value,obj.sliderThumb(2).Value];
        end

        function set.Value(obj,val)

            % if obj.RoundFractionalValues
            %     val = round(val);
            % else
            %     val = round(val,4);
            % end

            if obj.RoundFractionalValues
                val = round(val);
            end

            v1 = val(1);
            v2 = val(2);

            % set position of thumbs
            obj.sliderThumb(1).Value = v1;
            obj.sliderThumb(2).Value = v2;

            % set text shown in edit field (adjust limits first to avoid error)
            obj.sliderValueEditField(1).Limits = [obj.Limits(1) obj.sliderThumb(2).Value];
            obj.sliderValueEditField(2).Limits = [obj.sliderThumb(1).Value obj.Limits(2)];
            obj.sliderValueEditField(1).Value = v1;
            obj.sliderValueEditField(2).Value = v2;

        end

        function parentFig = get.parentFig(obj)
            parentFig = ancestor(obj,'figure','toplevel');
        end

    end

    %% callback methods

    methods

        % called when one of the sliding nodes is clicked
        function thumbClicked(obj,source,~)
            % the index of the clicked thumb
            thumbIdx = source.ID;
            % select the node
            obj.selectThumb(thumbIdx);
            % set window callbacks
            set(obj.parentFig,...
                "WindowButtonMotionFcn",@(o,e) obj.startSliding(o,e),...
                "WindowButtonUpFcn",@(o,e) obj.stopSliding(o,e));
            % start sliding
            obj.startSliding();
        end

        % called when the track is clicked
        function trackClicked(obj,source,~)
            % get the x value of point clicked on the slider thumb axes
            clickedPoint = source.CurrentPoint(1,1);
            % find which thumb is closest to the point
            [~,thumbIdx] = min(abs(obj.Value-clickedPoint));
            % select the thumb
            obj.selectThumb(thumbIdx);
            % set window callbacks
            set(obj.parentFig,...
                "WindowButtonMotionFcn",@(o,e) obj.startSliding(o,e),...
                "WindowButtonUpFcn",@(o,e) obj.stopSliding(o,e));
            % start sliding
            obj.startSliding();
        end

        function startSliding(obj,~,~)
            % set status flag to indicate slider is active
            obj.isSliding = true;
            % get limits for the currently sliding thumb
            if obj.activeThumbIdx == 1
                thumbLims = [obj.Limits(1) obj.sliderThumb(2).Value];
            else
                thumbLims = [obj.sliderThumb(1).Value obj.Limits(2)];
            end
            % get the x value of the cursor position on the slider track
            cursorX = obj.sliderThumbAxes.CurrentPoint(1,1);
            % set the element of the component Value corresponding to the active thumb
            obj.Value(obj.activeThumbIdx) = min(max(cursorX,thumbLims(1)),thumbLims(2));
        end

        function stopSliding(obj,~,~)
            % remove WindowButtonMotionFcn and WindowButtonUpFcn callbacks 
            obj.parentFig.WindowButtonMotionFcn = '';
            obj.parentFig.WindowButtonUpFcn = '';
            % restore status flag to indicate slider is no longer active
            obj.isSliding = false;
            % deselect the thumb
            obj.sliderThumb(obj.activeThumbIdx).deselect;
        end

        function sliderEditfieldValueChanged(obj,source,~)
            % set component value
            obj.Value(source.UserData) = source.Value;
        end  

        function valueChanged(obj,~,~)
            % notify object that slider value has changed - ValueChangedFcn will be called
            notify(obj,'ValueChanged');
        end

        function selectThumb(obj,thumbPosition)
            % set the active node idx
            obj.activeThumbIdx = thumbPosition;
            % select the corresponding thumb
            obj.sliderThumb(obj.activeThumbIdx).select();
        end

    end

end