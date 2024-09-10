classdef sliderEditField < matlab.ui.componentcontainer.ComponentContainer
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
        % track colormap
        TrackColormap (256,3) double = gray
        % height of the track
        TrackHeight (1,1) double = 5
        % overall height of the component
        Height (1,1) double = 25
        % flag to determine whether fractional values are rounded
        RoundFractionalValues (1,1) matlab.lang.OnOffSwitchState = 'off'
    end

    properties(SetAccess=private)
        % true if the slider is currently moving
        isSliding (1,1) logical = false
    end

    properties(SetObservable=true,Dependent=true)
        Value (1,1) double = 0.5
    end

    properties(Access=private,Dependent=true)
        % ancestor figure of the component
        parentFig
    end

    properties(Access = private,Transient,NonCopyable)
        % outermost grid for the entire component
        containerGrid (1,1) matlab.ui.container.GridLayout
        % patch object for slider track
        trackPatch (1,1) matlab.graphics.primitive.Patch
        % axes to hold slider thumb
        sliderThumbAxes (1,1) matlab.ui.control.UIAxes
        % the slider thumb
        sliderThumb (:,1) slidingNode
        % context menu for the thumb
        thumbCM (:,1)
        % PostSet listener for the slider value
        sliderValueListener (1,1)
        % editfield for text control of slider value
        sliderValueEditField (1,1) matlab.ui.control.NumericEditField
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        SliderValueChanged % SliderValueChangedFcn callback property will be generated
    end
    
    methods(Access=protected)
    
        function setup(obj)

            % grid layout manager to enclose all the components
            obj.containerGrid = uigridlayout(obj,...
                [1,2],...
                "ColumnWidth",{'1x',50},...
                "RowHeight",{obj.TrackHeight},...
                "BackgroundColor",[0 0 0],...
                "Padding",[5 5 5 5],...
                "Scrollable","on",...
                "RowSpacing",0);

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
                'LineWidth',2,...
                'Box','off',...
                'HitTest','on',...
                'PickableParts','all',...
                'Visible','off',...
                'ButtonDownFcn',@(o,e) obj.trackClicked(o,e));
            obj.sliderThumbAxes.Layout.Row =  1;
            obj.sliderThumbAxes.Layout.Column =  1;
            obj.sliderThumbAxes.Toolbar.Visible = 'off';
            obj.sliderThumbAxes.Interactions = [];
            disableDefaultInteractivity(obj.sliderThumbAxes)

            % get Vertices, Faces, and FaceVertexCData for the trackPatch
            [V,F,C] = obj.getTrackPatchData();

            % create the patch object
            obj.trackPatch = patch(obj.sliderThumbAxes,...
                'Faces',F,...
                'Vertices',V,...
                'FaceVertexCData',C,...
                'EdgeColor','interp',...
                'FaceColor','interp',...
                'PickableParts','none',...
                'HitTest','off');

            % create the beginning and end nodes
            obj.sliderThumb(1) = slidingNode(obj.sliderThumbAxes,...
                "EdgeColor",[1 1 1],...
                "FaceColor",[0 0 0],...
                "Value",0.5,...
                "YPosition",0.5*obj.Height,...
                "ButtonDownFcn",@(o,e) obj.trackClicked(o,e),...
                "ID",1);

            % set up listener for cmap to enable the ColormapChanged callback
            obj.sliderValueListener = addlistener(...
                obj,'Value',...
                'PostSet',@obj.sliderValueChanged);

            % editfield for text input control of slider value
            obj.sliderValueEditField = uieditfield(obj.containerGrid,"numeric",...
                'Limits',obj.Limits,...
                'Value',obj.Value,...
                'ValueChangedFcn',@(o,e) obj.sliderEditfieldValueChanged(o,e));
            obj.sliderValueEditField.Layout.Row = 1;
            obj.sliderValueEditField.Layout.Column = 2;

        end

        function update(obj)
            % set size of gridlayout manager row
            obj.containerGrid.RowHeight{1} = obj.Height;
            % set the limits of the slider axes
            set(obj.sliderThumbAxes,'XLim',obj.Limits,'YLim',[0 obj.Height])
            % update trackPatch coordinates
            [V,F,C] = obj.getTrackPatchData();
            set(obj.trackPatch,...
                'Vertices',V,...
                'Faces',F,...
                'FacevertexCData',C);
            % set vertical position of slider thumb
            obj.sliderThumb.YPosition = 0.5*obj.Height;
            % set the limits of the editfield
            obj.sliderValueEditField.Limits = obj.Limits;
            % background color of the component
            obj.containerGrid.BackgroundColor = obj.BackgroundColor;
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

        function [V,F,C] = getTrackPatchData(obj)
            % Vertices (V), Faces (F), and FaceVertexCData (C) for 
            % the rectangular patch object showing the track

            % X and Y coordinates of each vertex along the bottom of colorbar (left to right)
            bottomX = (linspace(obj.Limits(1),obj.Limits(2),256)).';
            bottomY = repmat(0.5*(obj.Height-obj.TrackHeight),size(bottomX));
            % coordinates of each vertex along the top of colorbar (right to left)
            topX = flipud(bottomX);
            topY = bottomY + obj.TrackHeight;
            % 512 total vertices, 256 on top, 256 on bottom (two vertices per color in the colormap)
            V = [bottomX,bottomY;topX,topY];
            % one face made of vertices around the rectangle border
            F = 1:512;
            % RGB triplets for each vertex, such that the color of the vertex at V(n,:) is C(n,:)
            C = vertcat(obj.TrackColormap,flipud(obj.TrackColormap));
        end

    end

    %% dependent Set/Get methods

    methods

        function Value = get.Value(obj)
            % get the component value based on the position of the slider thumb
            Value = obj.sliderThumb.Value;
        end

        function set.Value(obj,val)
            % adjust the value to fall within slider limits and round if necessary
            if obj.RoundFractionalValues
                adjustedValue = round(min(max(val,obj.Limits(1)),obj.Limits(2)));
            else
                adjustedValue = min(max(val,obj.Limits(1)),obj.Limits(2));
            end
            % set position of thumb
            obj.sliderThumb.Value = adjustedValue;
            % set text shown in edit field (adjust limits first to avoid error)
            obj.sliderValueEditField.Limits = obj.Limits;
            obj.sliderValueEditField.Value = adjustedValue;
        end

        function parentFig = get.parentFig(obj)
            parentFig = ancestor(obj,'figure','toplevel');
        end

    end

    %% callback methods

    methods

        % called when one of the sliding nodes is clicked
        function trackClicked(obj,~,~)

            obj.startSliding();

            % choose behavior based on the type of click
            switch obj.parentFig.SelectionType
                case 'alt'
                %% ctrl-click or right-click

                case 'normal'
                    %% left-click - enable sliding
                    % set WindowButtonMotionFcn to enable sliding
                    obj.parentFig.WindowButtonMotionFcn = @(o,e) obj.startSliding(o,e);
                    % set WindowButtonUpFcn so that sliding ends when button is released
                    obj.parentFig.WindowButtonUpFcn = @(o,e) obj.stopSliding(o,e);
                case 'extend'
                % shift-click
                % nothing yet

                case 'open'
                %% double-click

            end
        end

        function startSliding(obj,~,~)
            % set status flag to indicate slider is active
            obj.isSliding = true;
            % set the component value
            obj.Value = obj.sliderThumbAxes.CurrentPoint(1,1);
        end

        function stopSliding(obj,~,~)
            % remove WindowButtonMotionFcn and WindowButtonUpFcn callbacks 
            obj.parentFig.WindowButtonMotionFcn = '';
            obj.parentFig.WindowButtonUpFcn = '';
            % restore status flag to indicate slider is no longer active
            obj.isSliding = false;
        end

        function sliderEditfieldValueChanged(obj,~,~)
            % set component value
            obj.Value = obj.sliderValueEditField.Value;
        end        

        function sliderValueChanged(obj,~,~)
            % notify object that slider value has changed - ColormapChangedFcn will be called
            notify(obj,'SliderValueChanged');
        end

    end

end