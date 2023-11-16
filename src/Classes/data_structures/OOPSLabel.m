classdef OOPSLabel < handle
% simple class used for labeling objects
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
        Name char
        Color double
        Settings OOPSSettings
    end
    
    properties(Dependent = true)
        
        NameAndColor

        ColorString

        SelfIdx
        
    end
    
    methods
        
        function obj = OOPSLabel(Name,Color,Settings)
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