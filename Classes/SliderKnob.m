classdef SliderKnob < handle
    
    properties (Dependent = true, SetObservable, AbortSet)
        Value
        YPosition
        Color
        EdgeColor
        KnobSize
    end    
    
    properties (Access = private, Transient, NonCopyable)
        Knob matlab.graphics.primitive.Line
    end

    methods
        
        function obj = SliderKnob(Parent,Value,YPosition,KnobSize,Color,EdgeColor,ButtonDownFcn,KnobShape)
            obj.Knob = line(Parent,...
                Value,...
                YPosition,...
                'ButtonDownFcn',ButtonDownFcn,...
                'MarkerFaceColor',Color,...
                'MarkerEdgeColor',EdgeColor,...
                'MarkerSize',KnobSize,...
                'Marker',KnobShape);
        end

        function Value = get.Value(obj)
            Value = obj.Knob.XData;
        end
        
        function obj = set.Value(obj,val)
            obj.Knob.XData = val;
        end
        
        function Color = get.Color(obj)
            Color = obj.Knob.MarkerFaceColor;
        end
        
        function obj = set.Color(obj,val)
            obj.Knob.MarkerFaceColor = val;
        end
        
        function EdgeColor = get.EdgeColor(obj)
            EdgeColor = obj.Knob.MarkerEdgeColor;
        end
        
        function obj = set.EdgeColor(obj,val)
            obj.Knob.MarkerEdgeColor = val;
        end        

        function KnobSize = get.KnobSize(obj)
            KnobSize = obj.Knob.MarkerSize;
        end
        
        function obj = set.KnobSize(obj,val)
            obj.Knob.MarkerSize = val;
        end     
        
        function YPosition = get.YPosition(obj)
            YPosition = obj.Knob.YData;
        end
        
        function obj = set.YPosition(obj,val)
            obj.Knob.YData = val;
        end        

    end

end