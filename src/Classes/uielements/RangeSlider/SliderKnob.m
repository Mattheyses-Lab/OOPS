classdef SliderKnob < handle
%%  SLIDERKNOB creates a slideable "thumb" for a range slider
%
%   NOTES:
%       This class is not meant to be be used independently. It is used internally by RangeSlider to create sliding thumbs.
%
%   See also RangeSlider
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
        KnobFcn
    end

    properties (Dependent = true, SetObservable, AbortSet)
        Value
        YPosition
        Color
        EdgeColor
        KnobSize
        ButtonDownFcn
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
            obj.KnobFcn = ButtonDownFcn;
        end

        function Value = get.Value(obj)
            Value = obj.Knob.XData;
        end
        
        function set.Value(obj,val)
            obj.Knob.XData = val;
        end

        function set.ButtonDownFcn(obj,val)
            obj.Knob.ButtonDownFcn = val;
        end

        function ButtonDownFcn = get.ButtonDownFcn(obj)
            ButtonDownFcn = obj.Knob.ButtonDownFcn;
        end

        
        function Color = get.Color(obj)
            Color = obj.Knob.MarkerFaceColor;
        end
        
        function set.Color(obj,val)
            obj.Knob.MarkerFaceColor = val;
        end
        
        function EdgeColor = get.EdgeColor(obj)
            EdgeColor = obj.Knob.MarkerEdgeColor;
        end
        
        function set.EdgeColor(obj,val)
            obj.Knob.MarkerEdgeColor = val;
        end        

        function KnobSize = get.KnobSize(obj)
            KnobSize = obj.Knob.MarkerSize;
        end
        
        function set.KnobSize(obj,val)
            obj.Knob.MarkerSize = val;
        end     
        
        function YPosition = get.YPosition(obj)
            YPosition = obj.Knob.YData;
        end
        
        function set.YPosition(obj,val)
            obj.Knob.YData = val;
        end        

    end

end