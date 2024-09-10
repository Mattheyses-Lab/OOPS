classdef colorPickerWidget < matlab.ui.componentcontainer.ComponentContainer
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

    properties(SetObservable=true)
        currentColor (1,3) = [1 0 0]
    end

    properties(Access=private,Dependent=true)
        % ancestor figure of the component
        parentFig
        % true if any of the RGB sliders are active
        RGBSlidersActive
    end
    
    properties(Access = private,Transient,NonCopyable)
        % outermost grid for the entire component
        containerGrid (1,1) matlab.ui.container.GridLayout

        % panel to hold SVAxes
        SVPanel (1,1) matlab.ui.container.Panel
        % axes to hold the colorbar slider
        SVAxes (1,1) matlab.ui.control.UIAxes
        % image to show colormap
        SVImage (1,1) matlab.graphics.primitive.Image
        % SV selection cursor
        SVCursor (1,1) matlab.graphics.primitive.Line


        % panel to hold HAxes
        HPanel (1,1) matlab.ui.container.Panel
        % axes to hold the colorbar slider
        HAxes (1,1) matlab.ui.control.UIAxes
        % image to show colormap
        HImage (1,1) matlab.graphics.primitive.Image
        % H selection cursor
        HCursor (1,1) matlab.graphics.chart.decoration.ConstantLine

        % panel to hold HAxes
        examplePanel (1,1) matlab.ui.container.Panel
        % axes to hold the colorbar slider
        exampleAxes (1,1) matlab.ui.control.UIAxes
        % image to show colormap
        exampleImage (1,1) matlab.graphics.primitive.Image

        % text label to display the RGB or HSV values
        colorDisplayLabel (1,1) matlab.ui.control.Label

        % custom slider+ediffield for RGB values
        RSlider (:,1) sliderEditField
        GSlider (:,1) sliderEditField
        BSlider (:,1) sliderEditField

        % listener for the colormap
        colorListener (1,1)

        % status flags for better callback control
        HCursorActive (1,1) logical = false
        SVCursorActive (1,1) logical = false
        isUpdating (1,1) logical = false

    end

    properties(Dependent=true)
        currentH (1,1) = 0;
        currentS (1,1) = 1;
        currentV (1,1) = 1;

        displayHSV (1,:) char
        displayRGB (1,:) char
    end

    events (HasCallbackProperty, NotifyAccess = protected)
        ColorChanged % ColorChangedFcn callback property will be generated
    end
    
    methods(Access=protected)
    
        function setup(obj)
            % grid layout manager to enclose all the components
            obj.containerGrid = uigridlayout(obj,...
                [6,2],...
                "ColumnWidth",{'1x',25},...
                "RowHeight",{'1x',25,25,35,35,35},...
                "BackgroundColor",[0 0 0],...
                "Padding",[0 0 0 0],...
                "Scrollable","on",...
                "RowSpacing",5,...
                "ColumnSpacing",5);

            % panel to hold SVAxes
            obj.SVPanel = uipanel(obj.containerGrid,"BorderColor",[1 1 1]);
            obj.SVPanel.Layout.Row =  1;

            % axes to hold the example colorbar image
            obj.SVAxes = uiaxes(obj.SVPanel,...
                'XTick',[],...
                'YTick',[],...
                'XLim',[0.5 101.5],...
                'YLim',[0.5 101.5],...
                'XColor',[0 0 0],...
                'YColor',[0 0 0],...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],...
                'LineWidth',2,...
                'Box','on',...
                'BoxStyle','full',...
                'HitTest','on',...
                'PickableParts','all',...
                'ButtonDownFcn',@(o,e) obj.SVClicked(o,e));
            obj.SVAxes.Toolbar.Visible = 'off';
            obj.SVAxes.Interactions = [];
            disableDefaultInteractivity(obj.SVAxes)

            % image to display the colormap
            obj.SVImage = image(obj.SVAxes,...
                'CData',obj.makeSVImage(obj.currentH),...
                'CDataMapping','scaled',...
                'PickableParts','none',...
                'HitTest','off');

            obj.SVCursor = line(obj.SVAxes,...
                101,...
                101,...
                'ButtonDownFcn',@(o,e) obj.SVClicked(o,e),...
                'MarkerFaceColor',[1 1 1],...
                'MarkerEdgeColor',[0 0 0],...
                'MarkerSize',10,...
                'Marker','o',...
                'LineWidth',1);

            obj.HPanel = uipanel(obj.containerGrid,"BorderColor",[1 1 1]);
            obj.HPanel.Layout.Row =  1;
            obj.HPanel.Layout.Column =  2;

            % axes to hold the example colorbar image
            obj.HAxes = uiaxes(obj.HPanel,...
                'XTick',[],...
                'YTick',[],...
                'XLim',[0.5 25.5],...
                'YLim',[0.5 361.5],...
                'XColor',[0 0 0],...
                'YColor',[0 0 0],...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],...
                'LineWidth',2,...
                'Box','on',...
                'BoxStyle','full',...
                'HitTest','on',...
                'PickableParts','all',...
                'ButtonDownFcn',@(o,e) obj.HClicked(o,e));
            obj.HAxes.Toolbar.Visible = 'off';
            obj.HAxes.Interactions = [];
            disableDefaultInteractivity(obj.HAxes)

            % image to display the hues
            obj.HImage = image(obj.HAxes,...
                'CData',obj.makeHueImage,...
                'PickableParts','none',...
                'HitTest','off');

            % constant line for control of hue
            obj.HCursor = yline(obj.HAxes,361,...
                'ButtonDownFcn',@(o,e) obj.HClicked(o,e),...
                'LineWidth',1,...
                'Color',[0 0 0]);

            % panel to hold exampleAxes
            obj.examplePanel = uipanel(obj.containerGrid,"BorderColor",[1 1 1]);
            obj.examplePanel.Layout.Row =  2;
            obj.examplePanel.Layout.Column =  1;

            % axes to hold the example colorbar image
            obj.exampleAxes = uiaxes(obj.examplePanel,...
                'XTick',[],...
                'YTick',[],...
                'XLim',[0.5 101.5],...
                'YLim',[0.5 25.5],...
                'XColor',[0 0 0],...
                'YColor',[0 0 0],...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],...
                'LineWidth',2,...
                'Box','on',...
                'BoxStyle','full',...
                'HitTest','off',...
                'PickableParts','none');
            obj.exampleAxes.Toolbar.Visible = 'off';
            obj.exampleAxes.Interactions = [];
            disableDefaultInteractivity(obj.exampleAxes)

            % image to display the colormap
            obj.exampleImage = image(obj.exampleAxes,...
                'CData',obj.makeSingleColorImage(obj.currentColor),...
                'CDataMapping','scaled',...
                'PickableParts','none',...
                'HitTest','off');

            % uilabel to display RGB, HSV values
            obj.colorDisplayLabel = uilabel(obj.containerGrid,"Text",'HSV: ','FontColor',[1 1 1]);
            obj.colorDisplayLabel.Layout.Row = 3;
            obj.colorDisplayLabel.Layout.Column = [1 2];

            % RGB slider 1 - R
            obj.RSlider = sliderEditField(obj.containerGrid,...
                'Height',25,...
                'TrackHeight',8,...
                'Limits',[0 255],...
                'Value',255,...
                'RoundFractionalValues','On',...
                'TrackColormap',obj.getMap('red'),...
                'SliderValueChangedFcn', @(o,e) obj.RGBSlidersMoved(o,e),...
                'BackgroundColor',[0 0 0]);
            obj.RSlider.Layout.Row = 4;
            obj.RSlider.Layout.Column = [1 2];

            % RGB slider 2 - G
            obj.GSlider = sliderEditField(obj.containerGrid,...
                'Height',25,...
                'TrackHeight',8,...
                'Limits',[0 255],...
                'Value',255,...
                'RoundFractionalValues','On',...
                'TrackColormap',obj.getMap('green'),...
                'SliderValueChangedFcn', @(o,e) obj.RGBSlidersMoved(o,e),...
                'BackgroundColor',[0 0 0]);
            obj.GSlider.Layout.Row = 5;
            obj.GSlider.Layout.Column = [1 2];

            % RGB slider 3 - B
            obj.BSlider = sliderEditField(obj.containerGrid,...
                'Height',25,...
                'TrackHeight',8,...
                'Limits',[0 255],...
                'Value',255,...
                'RoundFractionalValues','On',...
                'TrackColormap',obj.getMap('blue'),...
                'SliderValueChangedFcn', @(o,e) obj.RGBSlidersMoved(o,e),...
                'BackgroundColor',[0 0 0]);
            obj.BSlider.Layout.Row = 6;
            obj.BSlider.Layout.Column = [1 2];

            % set up listener for cmap to enable the ColormapChanged callback
            obj.colorListener = addlistener(...
                obj,'currentColor',...
                'PostSet',@obj.colorChanged);

        end

        function update(obj)

            % set status flag to indicate we are updating
            obj.isUpdating = true;

            % get current color in RGB and HSV
            currentRGB = obj.currentColor;
            %currentHSV = rgb2hsv(currentRGB);

            % HSV values in the range [0,1]
            normalizedHSV = rgb2hsv(currentRGB);

            % HSV values in the range [1,361], [1,101], and [1,101], respectively
            currentHSV = round(normalizedHSV.*[360 100 100] + 1);

            % update the example color
            obj.exampleImage.CData = obj.makeSingleColorImage(currentRGB);

            % if none of the interactive RGB/HSV components are active
            if ~any([obj.SVCursorActive,obj.HCursorActive,obj.RGBSlidersActive])
                % update axes positions
                set([obj.SVAxes,obj.HAxes,obj.exampleAxes],"InnerPosition",[0 0 1 1]);
                % update H cursor position
                obj.HCursor.Value = currentHSV(1);
                % update SV image
                obj.SVImage.CData = obj.makeSVImage(normalizedHSV(1));
                % update SV cursor position
                set(obj.SVCursor,'XData',currentHSV(2),'YData',currentHSV(3));
            elseif obj.HCursorActive
                % update SV image
                obj.SVImage.CData = obj.makeSVImage(normalizedHSV(1));
            elseif obj.RGBSlidersActive
                % update H cursor position
                obj.HCursor.Value = currentHSV(1);
                % update SV image
                obj.SVImage.CData = obj.makeSVImage(normalizedHSV(1));
                % update SV cursor position
                set(obj.SVCursor,'XData',currentHSV(2),'YData',currentHSV(3));
            end


            % if RGBSliders inactive
            if ~obj.RGBSlidersActive
                % update RGB sliders
                obj.RSlider.Value = currentRGB(1)*255;
                obj.GSlider.Value = currentRGB(2)*255;
                obj.BSlider.Value = currentRGB(3)*255;
            end

            % update the RGB slider tracks
            obj.updateRGBSliderTracks();

            % update the color display labels
            obj.colorDisplayLabel.Text = [obj.displayHSV,' | ',obj.displayRGB];

            % release status flag once done updating
            obj.isUpdating = false;

        end
    
    end

    %% destructor

    methods

        function delete(obj)

            delete(obj.colorListener)

        end

    end


    %% dependent Set/Get methods

    methods

        function currentH = get.currentH(obj)
            currentH = min(max((obj.HCursor.Value-1)/360,0),1);
        end        

        function currentS = get.currentS(obj)
            currentS = min(max((obj.SVCursor.XData-1)/100,0),1);
        end

        function currentV = get.currentV(obj)
            currentV = min(max((obj.SVCursor.YData-1)/100,0),1);
        end

        function displayHSV = get.displayHSV(obj)
            displayH = obj.currentH*360;
            displayS = obj.currentS*100;
            displayV = obj.currentV*100;
            displayHSV = ['HSV = (',num2str(displayH),'°, ',num2str(displayS),'%, ',num2str(displayV),'%)'];
        end

        function displayRGB = get.displayRGB(obj)
            currentRGB = round(obj.currentColor.*255);

            displayRGB = ['RGB = (',num2str(currentRGB(1)),', ',num2str(currentRGB(2)),', ',num2str(currentRGB(3)),')'];

        end

        function parentFig = get.parentFig(obj)
            parentFig = ancestor(obj,'figure','toplevel');
        end

        function RGBSlidersActive = get.RGBSlidersActive(obj)
            % true if any of the sliders are active
            RGBSlidersActive = any([obj.RSlider.isSliding,obj.GSlider.isSliding,obj.BSlider.isSliding]);
        end
        

    end

    %% helper methods

    methods

        function updateRGBSliderTracks(obj)

            baseTrack = repmat((linspace(0,1,256)).',1,3);

            % current RGB values mapped to [0,1]
            currentRGB = [obj.RSlider.Value, obj.GSlider.Value, obj.BSlider.Value]./255;

            RTrack = baseTrack;
            RTrack(:,2) = currentRGB(2);
            RTrack(:,3) = currentRGB(3);

            GTrack = baseTrack;
            GTrack(:,1) = currentRGB(1);
            GTrack(:,3) = currentRGB(3);

            BTrack = baseTrack;
            BTrack(:,1) = currentRGB(1);
            BTrack(:,2) = currentRGB(2);

            obj.RSlider.TrackColormap = RTrack;
            obj.GSlider.TrackColormap = GTrack;
            obj.BSlider.TrackColormap = BTrack;

        end

    end


    %% callback methods

    methods

        % called when one of the sliding nodes is clicked
        function SVClicked(obj,~,~)

            obj.startSVSliding();
            
            % choose behavior based on the type of click
            switch obj.parentFig.SelectionType
                case 'alt'
                %% ctrl-click or right-click

                case 'normal'
                %% left-click - enable sliding
                    % set WindowButtonMotionFcn to enable sliding
                    obj.parentFig.WindowButtonMotionFcn = @(o,e) obj.startSVSliding(o,e);
                    % set WindowButtonUpFcn so that sliding ends when button is released
                    obj.parentFig.WindowButtonUpFcn = @(o,e) obj.stopSVSliding(o,e);
                case 'extend'
                %% shift-click

                case 'open'
                %% double-click

            end
        end

        function startSVSliding(obj,~,~)

            % SV cursor is actively moving
            obj.SVCursorActive = true;

            currentPoint = obj.SVAxes.CurrentPoint;
            S_position = min(max(round(currentPoint(1,1)),1),101);
            V_position = min(max(round(currentPoint(1,2)),1),101);

            set(obj.SVCursor,'XData',S_position,'YData',V_position);

            % set the new color
            obj.currentColor = hsv2rgb([obj.currentH,obj.currentS,obj.currentV]);

        end

        function stopSVSliding(obj,~,~)
            obj.parentFig.WindowButtonMotionFcn = '';
            obj.parentFig.WindowButtonUpFcn = '';

            % SV cursor is no longer actively moving
            obj.SVCursorActive = false;
        end

        % called when one of the sliding nodes is clicked
        function HClicked(obj,~,~)

            obj.startHSliding();
            
            % choose behavior based on the type of click
            switch obj.parentFig.SelectionType
                case 'alt'
                %% ctrl-click or right-click

                case 'normal'
                %% left-click - enable sliding
                    % set WindowButtonMotionFcn to enable sliding
                    obj.parentFig.WindowButtonMotionFcn = @(o,e) obj.startHSliding(o,e);
                    % set WindowButtonUpFcn so that sliding ends when button is released
                    obj.parentFig.WindowButtonUpFcn = @(o,e) obj.stopHSliding(o,e);
                case 'extend'
                % shift-click

                case 'open'
                %% double-click

            end
        end

        function startHSliding(obj,~,~)

            % H cursor is actively moving
            obj.HCursorActive = true;

            currentPoint = obj.HAxes.CurrentPoint;

            % get y position
            H_position = currentPoint(1,2);

            % restrict H cursor position to [1,361]
            obj.HCursor.Value = min(max(round(H_position),1),361);

            % set the new color
            obj.currentColor = hsv2rgb([obj.currentH,obj.currentS,obj.currentV]);

        end

        function stopHSliding(obj,~,~)
            obj.parentFig.WindowButtonMotionFcn = '';
            obj.parentFig.WindowButtonUpFcn = '';

            % H cursor is no longer actively moving
            obj.HCursorActive = false;

        end

        function RGBSlidersMoved(obj,~,~)

            if any([obj.HCursorActive,obj.SVCursorActive,obj.isUpdating])
                return
            end

            % RGB triplet from RGB slider positions
            newRGB = [obj.RSlider.Value, obj.GSlider.Value, obj.BSlider.Value];
            % map values in the range [0,255] to [0,1]
            obj.currentColor = newRGB./255;

        end

        function colorChanged(obj,~,~)
            % notify object that cmap has changed - ColormapChangedFcn will be called
            notify(obj,'ColorChanged');
        end

    end



    %% methods for making color images

    methods (Static=true)

        function singleColorImage = makeSingleColorImage(singleColor)
            singleColorImage = repmat(reshape(singleColor,1,1,3),25,101);
        end

        function hueImage = makeHueImage()
            hueImage = repmat(reshape(hsv(361),[361,1,3]),1,25);
        end

        function SVImage = makeSVImage(hueIn)
            S = repmat(linspace(0,1,101),101,1);
            V = S';
            H = ones(size(S)).*hueIn;
            SVImage = hsv2rgb(H,S,V);
        end

        function mapOut = getMap(mapColor)

            baseGradient = linspace(0,1,256).';
            emptyChannel = zeros(size(baseGradient));

            switch mapColor
                case 'red'
                    mapOut = [baseGradient,emptyChannel,emptyChannel];
                case 'green'
                    mapOut = [emptyChannel,baseGradient,emptyChannel];
                case 'blue'
                    mapOut = [emptyChannel,emptyChannel,baseGradient];
            end
        end


    end

end