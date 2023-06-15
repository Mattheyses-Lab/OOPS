classdef customPalette

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