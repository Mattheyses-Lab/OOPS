classdef CustomAxes < handle
    
    properties
        Ax
        Im
    end

    methods
        function obj = CustomAxes(Parent,Position,Tag,Image)
            obj.Ax = uiaxes('Parent',Parent,...
                'Units','Pixels',...
                'InnerPosition',Position,...
                'Tag',Tag,...
                'XTick',[],...
                'YTick',[]);
            
            pbarOriginal = obj.Ax.PlotBoxAspectRatio;
            
            obj.Im = imshow(Image,'Parent',obj.Ax);
            obj.Im.Tag = Tag;
            
            % restore defaults after calling imshow()
            obj.Ax.PlotBoxAspectRatioMode = 'manual';
            obj.Ax.PlotBoxAspectRatio = pbarOriginal;

            drawnow
        end
        
        function delete(obj)
            % delete custom axes
            delete(obj)
            delete(obj.Ax)
        end
    end
end