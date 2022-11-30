classdef PODSLabel < handle
% simple class used for labeling objects
    
    properties
        Name char
        Color double
        Settings PODSSettings
    end
    
    properties(Dependent = true)
        
        NameAndColor

        ColorString

        SelfIdx
        
    end
    
    methods
        
        function obj = PODSLabel(Name,Color,Settings)
            obj.Name = Name;
            obj.Color = Color;
            obj.Settings = Settings;
        end
        
        function NameAndColor = get.NameAndColor(obj)
            NameAndColor = [obj.Name,' (',obj.ColorString,')'];
        end
        
        function ColorString = get.ColorString(obj)
            ColorStringCell = colornames('MATLAB',obj.Color);
            ColorString = ColorStringCell{1};
        end

        function SelfIdx = get.SelfIdx(obj)
            SelfIdx = find(obj.Settings.ObjectLabels==obj);
        end

    end

end