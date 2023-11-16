classdef customPalette
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
        Colors (:,3) double {mustBeInRange(Colors,0,1)} = hsv(12);
        Name (1,1) string = "Untitled";
        Source (1,1) string  = "Custom";
    end

    properties (Dependent = true)
        nColors
    end

    methods
        % constructor method
        function obj = customPalette(NameValuePairs)
            % constructor input validation
            arguments
                NameValuePairs.Colors (:,3) double {mustBeInRange(NameValuePairs.Colors,0,1)} = hsv(12);
                NameValuePairs.Name (1,1) string = "Untitled";
                NameValuePairs.Source (1,1) string = "Custom";
            end
            % set properties
            obj.Colors = NameValuePairs.Colors;
            obj.Name = NameValuePairs.Name;
            obj.Source = NameValuePairs.Source;
        end

        function nColors = get.nColors(obj)
            nColors = size(obj.Colors,1);
        end

        function TF = eq(A,B)
            if strcmp(A.Name,B.Name) && ...
                    all(A.Colors(:)==B.Colors(:)) && ...
                    strcmp(A.Source,B.Source)
                TF = true;
            else
                TF = false;
            end
        end

        function paletteImage = paletteImage(obj,swatchSize,borderWidth,backgroundColor)

            nClrs = obj.nColors;

            colorSquares = cell(nClrs,1);

            for i = 1:nClrs
                colorSquares{i} = makeRGBColorSquare(obj.Colors(i,:),swatchSize);
            end

            paletteImage = imtile(colorSquares,...
                'ThumbnailSize',[swatchSize swatchSize],...
                'BorderSize',borderWidth,...
                'BackgroundColor',backgroundColor,...
                'GridSize',[NaN NaN]);

        end

    end

end