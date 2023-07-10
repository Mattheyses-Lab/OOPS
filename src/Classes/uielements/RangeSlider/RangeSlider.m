classdef RangeSlider < matlab.ui.componentcontainer.ComponentContainer
    % Range slider
    properties
        OldWindowButtonMotionFcn = '';
        OldWindowButtonUpFcn = '';
        StartUp = true;
        Knob1Color = [1 1 1];
        Knob1EdgeColor = [0 0 0];
        Knob2Color = [1 1 1];
        Knob2EdgeColor = [0 0 0];
        KnobShape = 'o';
        KnobSize = 10;
        MidLineColor = '#A9A9A9';
        RangeColor = [0 0 0];
        YDist = 0;
        Title = 'Range Slider';
        TitleColor = [1 1 1];
        TitleBGColor = 'none';
        TickColor = [0 0 0];
        LabelColor = [1 1 1];
        LabelBGColor = 'none';
        FontSize = 12;
    end

    properties (SetObservable = true)
        Limits = [0 1];
    end
    
    properties (Dependent = true)
        Value
    end

    properties (Dependent = true, SetAccess = private)
        sliderRowHeight
    end
    
    events (HasCallbackProperty, NotifyAccess = protected)
        ValueChanged % ValueChangedFcn callback property will be generated
    end
    
    properties (Access = private, Transient, NonCopyable)
        Grid matlab.ui.container.GridLayout
        RangeAxes matlab.ui.control.UIAxes
        Knob SliderKnob
        KnobListener1
        KnobListener2
        LimitsListener
        MidLine matlab.graphics.primitive.Line
        RangeLine matlab.graphics.primitive.Line

        Label (1,1) matlab.ui.control.Label
    end
    
    properties (Dependent = true)
        CurrentPoint
    end
    
    methods (Access=protected)
        function setup(obj)
            
            obj.Interruptible = 'off';
            obj.BusyAction = 'cancel';
            obj.Units = 'Normalized';

            obj.Grid = uigridlayout(obj,[2,1],...
                'RowHeight',{'fit','1x'},...
                'RowSpacing',0,...
                'BackgroundColor','Black');

            obj.Label = uilabel(obj.Grid,...
                "Text",obj.Title,...
                "FontColor",obj.TitleColor);
            obj.Label.Layout.Row = 1;

            
            % Container for lines
            obj.RangeAxes = uiaxes(obj.Grid,...
                'YLim',[0 1],...
                'XLim',obj.Limits,...
                'XTickLabelMode','Auto',...
                'YTick',[],...
                'Color','none',...
                'XAxisLocation','origin',...
                'XColor',obj.TickColor,...
                'YColor','None',...
                'TickLength',[0 0],...
                'TickDir','out',...
                'Clipping','Off',...
                'TitleFontSizeMultiplier',1);
            obj.RangeAxes.Layout.Row = 2;

            % obj.RangeAxes.Title.String = obj.Title;
            % obj.RangeAxes.Title.Color = 'white';
            % obj.RangeAxes.Title.Editing = "off";
            % obj.RangeAxes.Title.HitTest = "off";
            % obj.RangeAxes.Title.PickableParts = "none";

            obj.RangeAxes.Toolbar = axtoolbar(obj.RangeAxes,{});
            disableDefaultInteractivity(obj.RangeAxes);
            
            obj.Knob(1) = SliderKnob(obj.RangeAxes,...
                obj.Limits(1),...
                obj.YDist,...
                obj.KnobSize,...
                obj.Knob1Color,...
                obj.Knob1EdgeColor,...
                @(o,e) obj.StartMovingKnob1(),...
                obj.KnobShape);

            obj.Knob(2) = SliderKnob(obj.RangeAxes,...
                obj.Limits(2),...
                obj.YDist,...
                obj.KnobSize,...
                obj.Knob2Color,...
                obj.Knob1EdgeColor,...
                @(o,e) obj.StartMovingKnob2(),...
                obj.KnobShape);
            
            obj.KnobListener1 = addlistener(...
                obj.Knob(1),'Value',...
                'PostSet',@(o,e) obj.HandleKnob1ValueChanged);
            obj.KnobListener2 = addlistener(...
                obj.Knob(2),'Value',...
                'PostSet',@(o,e) obj.HandleKnob2ValueChanged);
            
            obj.MidLine = line(obj.RangeAxes,...
                obj.Limits,[obj.YDist,obj.YDist],...
                'LineWidth',2,...
                'Color',obj.MidLineColor,...
                'HitTest','Off',...
                'PickableParts','None');
            
            obj.RangeLine = line(obj.RangeAxes,...
                obj.Limits,[obj.YDist,obj.YDist],...
                'LineWidth',5,...
                'Color',obj.RangeColor,...
                'HitTest','Off',...
                'PickableParts','None');            

            obj.RangeAxes.Children = [...
                obj.RangeAxes.Children(3);...
                obj.RangeAxes.Children(4);...
                obj.RangeAxes.Children(1);...
                obj.RangeAxes.Children(2)];

            obj.LimitsListener = addlistener(...
                obj,'Limits',...
                'PostSet',@(o,e) obj.LimitsChanged);
        end
        
        function update(obj)

            switch obj.HitTest
                case 'on'
                    obj.Knob(1).ButtonDownFcn = obj.Knob(1).KnobFcn;
                    obj.Knob(2).ButtonDownFcn = obj.Knob(2).KnobFcn;
                case 'off'
                    obj.Knob(1).ButtonDownFcn = '';
                    obj.Knob(2).ButtonDownFcn = '';
            end

            obj.Grid.RowHeight{2} = obj.sliderRowHeight;

            obj.RangeAxes.XLim = obj.Limits;
            obj.RangeAxes.FontSize = obj.FontSize;

            obj.Knob(1).Color = obj.Knob1Color;
            obj.Knob(1).EdgeColor = obj.Knob1EdgeColor;
            obj.Knob(1).YPosition = obj.YDist;

            obj.Knob(2).Color = obj.Knob2Color;
            obj.Knob(2).EdgeColor = obj.Knob2EdgeColor;
            obj.Knob(2).YPosition = obj.YDist;

            obj.MidLine.Color = obj.MidLineColor;
            obj.MidLine.XData = obj.Limits;
            obj.MidLine.YData = [obj.YDist obj.YDist];

            obj.RangeLine.Color = obj.RangeColor;
            obj.RangeLine.YData = [obj.YDist obj.YDist];
            % test below
            obj.RangeLine.XData = obj.Value;

            obj.RangeAxes.XColor = obj.TickColor;

            obj.Label.Text = [obj.Title,' (',num2str(round(obj.Value(1),2)),' - ',num2str(round(obj.Value(2),2)),')'];
            obj.Label.FontColor = obj.TitleColor;

            obj.Grid.BackgroundColor = obj.BackgroundColor;

        end
        
    end
        methods (Access=private)
            function StartMovingKnob1(obj)
                obj.Knob(1).KnobSize = 12;
                % store old callbacks so we can reset later
                obj.OldWindowButtonMotionFcn = get(gcf,'WindowButtonMotionFcn');
                obj.OldWindowButtonUpFcn = get(gcf,'WindowButtonUpFcn');
                % set callbacks to adjust sliders
                set(gcf,'WindowButtonUpFcn',@(o,e) obj.StopMovingAndRestoreCallbacks());
                set(gcf,'WindowButtonMotionFcn',@(o,e) obj.MoveKnob1());
            end

            function StartMovingKnob2(obj)
                obj.Knob(2).KnobSize = 12;
                % store old callbacks so we can reset later
                obj.OldWindowButtonMotionFcn = get(gcf,'WindowButtonMotionFcn');
                obj.OldWindowButtonUpFcn = get(gcf,'WindowButtonUpFcn');
                % set callbacks to adjust sliders
                set(gcf,'WindowButtonUpFcn',@(o,e) obj.StopMovingAndRestoreCallbacks());
                set(gcf,'WindowButtonMotionFcn',@(o,e) obj.MoveKnob2());
            end
            
            function HandleKnob1ValueChanged(obj)
                % Execute the event listeners and the ValueChangedFcn callback property
                notify(obj,'ValueChanged');
            end
            
            function HandleKnob2ValueChanged(obj)
                % Execute the event listeners and the ValueChangedFcn callback property
                notify(obj,'ValueChanged');
            end

            function LimitsChanged(obj)
                obj.Value(1) = max(obj.Value(1),obj.Limits(1));
                obj.Value(2) = min(obj.Value(2),obj.Limits(2));
            end
        end
        
        methods

            function sliderRowHeight = get.sliderRowHeight(obj)
                % sliderRowHeight = obj.FontSize + 20;
                sliderRowHeight = 20;
            end
            
            function Value = get.Value(obj)
                Value = [obj.Knob(1).Value obj.Knob(2).Value];
            end
            
            function set.Value(obj,val)
                obj.Knob(1).Value = val(1);
                obj.Knob(2).Value = val(2);
                obj.RangeLine.XData = val;
            end

            function delete(obj)
                delete(obj)
            end

            function CurrentPoint = get.CurrentPoint(obj)
                CurrentPoint = obj.RangeAxes.CurrentPoint(1,1);
            end
            
            function MoveKnob1(obj)
                obj.Value(1) = max(min(obj.CurrentPoint,obj.Knob(2).Value),obj.Limits(1));
                %drawnow
            end
            
            function MoveKnob2(obj)
                obj.Value(2) = min(max(obj.CurrentPoint,obj.Knob(1).Value),obj.Limits(2));
                %drawnow
            end

            function StopMovingAndRestoreCallbacks(obj)
                set(gcf,'WindowButtonMotionFcn',obj.OldWindowButtonMotionFcn);
                set(gcf,'WindowButtonUpFcn',obj.OldWindowButtonUpFcn);
                obj.Knob(1).KnobSize = 10;
                obj.Knob(2).KnobSize = 10;
            end
        end

end