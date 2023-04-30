classdef customColormap

    properties
        Map (256,3) double {mustBeInRange(Map,0,1)} = gray;
        Name (1,1) string = "Untitled colormap";
        Source (1,1) string  = "Custom";
        Attributes (:,1) cell {mustBeMember(Attributes,{'Linear','Circular','PerceptuallyUniform','none'})} = {'none'};
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
                NameValuePairs.Name (1,1) string = "Untitled colormap";
                NameValuePairs.Source (1,1) string = "Custom";
                NameValuePairs.Attributes (:,1) cell {mustBeMember(NameValuePairs.Attributes,{'Linear','Circular','PerceptuallyUniform','none'})} = {'none'};
            end
            % set properties
            obj.Map = NameValuePairs.Map;
            obj.Name = NameValuePairs.Name;
            obj.Source = NameValuePairs.Source;
            obj.Attributes = NameValuePairs.Attributes;
        end

        function TF = eq(A,B)
            if strcmp(A.Name,B.Name) && ...
                    all(A.Map(:)==B.Map(:)) && ...
                    all(ismember(A.Attributes,B.Attributes)) && ...
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

        function addAttribute(obj,attribute)
            if ~ismember(attribute,obj.Attributes)
                obj.Attributes{end+1} = attribute;
            else
                error('The customColormap already has this attribute.')
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