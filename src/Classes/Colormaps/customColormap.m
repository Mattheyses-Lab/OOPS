classdef customColormap
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
        Map (256,3) double {mustBeInRange(Map,0,1)} = gray;
        Name (1,1) string = "Untitled colormap";
        Source (1,1) string  = "Custom";
    end

    properties (Dependent = true)
        invertedMap
    end
    
    methods
        % constructor method
        function obj = customColormap(NameValuePairs)
            % constructor input validation
            arguments
                NameValuePairs.Map (256,3) double {mustBeInRange(NameValuePairs.Map,0,1)} = gray;
                NameValuePairs.Name (1,1) string = "Untitled";
                NameValuePairs.Source (1,1) string = "Custom";
            end
            % set properties
            obj.Map = NameValuePairs.Map;
            obj.Name = NameValuePairs.Name;
            obj.Source = NameValuePairs.Source;
        end

        function TF = eq(A,B)
            if strcmp(A.Name,B.Name) && ...
                    all(A.Map(:)==B.Map(:)) && ...
                    strcmp(A.Source,B.Source)
                TF = true;
            else
                TF = false;
            end
        end

        function mapImage = colormapImage(obj,sz,dir)
            % sz (1x2) - size of the image to return

            % which direction should the colormap image be
            switch dir
                case 'r'
                    mapImage = ind2rgb(im2uint8(repmat(linspace(0,1,sz(2)),sz(1),1)),obj.Map);
                case 'l'
                    mapImage = ind2rgb(im2uint8(repmat(linspace(1,0,sz(2)),sz(1),1)),obj.Map);
                case 'u'
                    mapImage = ind2rgb(im2uint8(repmat(linspace(1,0,sz(1)).',1,sz(2))),obj.Map);
                case 'd'
                    mapImage = ind2rgb(im2uint8(repmat(linspace(0,1,sz(1)).',1,sz(2))),obj.Map);
            end
            
        end

        function invertedMap = get.invertedMap(obj)
            invertedMap = flipud(obj.Map);
        end
    end

    % methods (Static)
    % 
    % end
    
end