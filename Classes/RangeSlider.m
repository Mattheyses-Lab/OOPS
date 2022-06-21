classdef RangeSlider < matlab.ui.componentcontainer.ComponentContainer
    % Range slider
    properties
        OldWindowButtonMotionFcn = '';
        OldWindowButtonUpFcn = '';
        StartUp = true;
        Limits = [0 1];
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
        TitleBGColor = [0 0 0 0.5];
        TickColor = [0 0 0];
        LabelColor = [1 1 1];
        LabelBGColor = [0 0 0 0.5];
    end
    
    properties (Dependent = true)
        Value
    end
    
    events (HasCallbackProperty, NotifyAccess = protected)
        ValueChanged % ValueChangedFcn callback property will be generated
    end
    
    properties (Access = private, Transient, NonCopyable)
        RangeAxes matlab.ui.control.UIAxes
        Knob SliderKnob
        KnobLabel matlab.graphics.primitive.Text
        KnobListener1
        KnobListener2
        MidLine matlab.graphics.primitive.Line
        RangeLine matlab.graphics.primitive.Line
    end
    
    properties (Dependent = true)
        CurrentPoint
    end
    
    methods (Access=protected)
        function setup(obj)
            
            obj.Interruptible = 'On';
            obj.BusyAction = 'Queue';
            obj.Units = 'Normalized';
            
            % Container for lines
            obj.RangeAxes = uiaxes(obj,'Units','Normalized',...
                'Position',[0.05 0.05 0.9 0.9],...
                'YLim',[0 1],...
                'XLim',obj.Limits,...
                'XTickLabelMode','Auto',...
                'YTick',[],...
                'Color','None',...
                'XAxisLocation','origin',...
                'XColor',obj.TickColor,...
                'YColor','None',...
                'TickLength',[0 0],...
                'TickDir','Both',...
                'Clipping','Off',...
                'TitleFontSizeMultiplier',1);
            obj.RangeAxes.Toolbar = axtoolbar(obj.RangeAxes,{});
            disableDefaultInteractivity(obj.RangeAxes);

            obj.RangeAxes.Title.String = obj.Title;
%             obj.RangeAxes.Title.FontSize = 15;
            obj.RangeAxes.Title.HorizontalAlignment = 'Center';
            obj.RangeAxes.Title.VerticalAlignment = 'Top';
            obj.RangeAxes.Title.Color = obj.TitleColor;
            obj.RangeAxes.Title.BackgroundColor = obj.TitleBGColor;
            obj.RangeAxes.Title.Position = [0.5,0.8,0];
            obj.RangeAxes.Title.HitTest = 'Off';
            
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
            
            obj.KnobListener1 = addlistener(obj.Knob(1),'Value','PostSet',@(o,e) obj.HandleKnob1ValueChanged);
            obj.KnobListener2 = addlistener(obj.Knob(2),'Value','PostSet',@(o,e) obj.HandleKnob2ValueChanged);
            
            obj.MidLine = line(obj.RangeAxes,obj.Limits,[obj.YDist,obj.YDist],...
                'LineWidth',2,...
                'Color',obj.MidLineColor,...
                'HitTest','Off',...
                'PickableParts','None');
            
            obj.RangeLine = line(obj.RangeAxes,obj.Limits,[obj.YDist,obj.YDist],...
                'LineWidth',5,...
                'Color',obj.RangeColor,...
                'HitTest','Off',...
                'PickableParts','None');            

            obj.RangeAxes.Children = [obj.RangeAxes.Children(3);obj.RangeAxes.Children(4);obj.RangeAxes.Children(1);obj.RangeAxes.Children(2)];
            
            obj.KnobLabel(1) = text(obj.RangeAxes,...
                obj.Limits(1)-0.01,...
                obj.YDist+0.15,...
                num2str(obj.Limits(1)),...
                'VerticalAlignment','Bottom',...
                'HorizontalAlignment','Right',...
                'HitTest','Off',...
                'Margin',1);
            obj.KnobLabel(2) = text(obj.RangeAxes,...
                obj.Limits(2)+0.015,...
                obj.YDist+0.1,...
                num2str(obj.Limits(2)),...
                'VerticalAlignment','Bottom',...
                'HorizontalAlignment','Left',...
                'HitTest','Off',...
                'Margin',1);
        end
        
        function update(obj)
            if obj.StartUp
                obj.RangeAxes.XLim = obj.Limits;
                obj.Knob(1).Color = obj.Knob1Color;
                obj.Knob(1).EdgeColor = obj.Knob1EdgeColor;
                obj.Knob(1).YPosition = obj.YDist;
                obj.KnobLabel(1).Position(2) = obj.YDist+0.15;
                obj.KnobLabel(1).Color = obj.LabelColor;
                obj.KnobLabel(1).BackgroundColor = obj.LabelBGColor;
                obj.Knob(2).Color = obj.Knob2Color;
                obj.Knob(2).EdgeColor = obj.Knob2EdgeColor;
                obj.Knob(2).YPosition = obj.YDist;
                obj.KnobLabel(2).Position(2) = obj.YDist+0.15;
                obj.KnobLabel(2).Color = obj.LabelColor;
                obj.KnobLabel(2).BackgroundColor = obj.LabelBGColor;
                obj.MidLine.Color = obj.MidLineColor;
                obj.MidLine.XData = obj.Limits;
                obj.MidLine.YData = [obj.YDist obj.YDist];
                obj.RangeLine.Color = obj.RangeColor;
                obj.RangeLine.YData = [obj.YDist obj.YDist];
                obj.RangeAxes.Title.String = obj.Title;
                obj.RangeAxes.Title.Color = obj.TitleColor;
                obj.RangeAxes.XColor = obj.TickColor;
                %obj.StartUp = false;
            end

            %disp('Updating slider');

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
        end
        
        methods
            
            function Value = get.Value(obj)
                Value = [obj.Knob(1).Value obj.Knob(2).Value];
            end
            
            function set.Value(obj,val)
                obj.Knob(1).Value = val(1);
                obj.KnobLabel(1).Position(1) = val(1)-0.01;
                obj.KnobLabel(1).String = num2str(round(val(1),2));
                obj.Knob(2).Value = val(2);
                obj.KnobLabel(2).Position(1) = val(2)+0.01;
                obj.KnobLabel(2).String = num2str(round(val(2),2));
                obj.RangeLine.XData = val;
            end

            function delete(obj)
                delete(obj)
            end

            function CurrentPoint = get.CurrentPoint(obj)
                CurrentPoint = obj.RangeAxes.CurrentPoint(1,1);
            end
            
            function MoveKnob1(obj)
                if obj.CurrentPoint >= obj.Knob(2).Value
                    obj.Knob(1).Value = obj.Knob(2).Value;
                elseif obj.CurrentPoint <= obj.Limits(1)
                    obj.Knob(1).Value = obj.Limits(1);
                else
                    obj.Knob(1).Value = obj.CurrentPoint;
                end
                obj.RangeLine.XData(1) = obj.Knob(1).Value;
                obj.KnobLabel(1).Position(1) = obj.Knob(1).Value-0.01;
                obj.KnobLabel(1).String = num2str(round(obj.Knob(1).Value,2));

                drawnow
            end
            
            function MoveKnob2(obj)
                if obj.CurrentPoint <= obj.Knob(1).Value
                    obj.Knob(2).Value = obj.Knob(1).Value;
                elseif obj.CurrentPoint >= obj.Limits(2)
                    obj.Knob(2).Value = obj.Limits(2);
                else
                    obj.Knob(2).Value = obj.CurrentPoint;
                end
                obj.RangeLine.XData(2) = obj.Knob(2).Value;
                obj.KnobLabel(2).Position(1) = obj.Knob(2).Value+0.01;
                obj.KnobLabel(2).String = num2str(round(obj.Knob(2).Value,2));
                drawnow
            end

            function StopMovingAndRestoreCallbacks(obj)
                set(gcf,'WindowButtonMotionFcn',obj.OldWindowButtonMotionFcn);
                set(gcf,'WindowButtonUpFcn',obj.OldWindowButtonUpFcn);
                obj.Knob(1).KnobSize = 10;
                obj.Knob(2).KnobSize = 10;
            end
        end

end