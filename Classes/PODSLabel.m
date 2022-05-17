classdef PODSLabel < dynamicprops
% simple class used for labeling objects
    
    properties
        Name char
        Color double
        LabelNumber char
    end
    
    properties(Dependent = true)
        
        NameAndColor

        ColorString
        
    end
    
    methods
        
        function obj = PODSLabel(Name,Color,LabelIdx)
            obj.Name = Name;
            obj.Color = Color;
            obj.LabelNumber = num2str(LabelIdx);
        end
        
        function NameAndColor = get.NameAndColor(obj)
            NameAndColor = [obj.Name,' (',obj.ColorString,')'];
        end
        
        function ColorString = get.ColorString(obj)
            ColorStringCell = colornames('MATLAB',obj.Color);
            ColorString = ColorStringCell{1};
        end

    end

end