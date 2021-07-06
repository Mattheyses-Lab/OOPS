classdef CustomAxes < handle
    
    properties
        Ax
        Im
        tb
    end

    methods
        function obj = CustomAxes(Parent,Position,Tag,Image,Title)
            obj.Ax = uiaxes('Parent',Parent,...
                'Units','Pixels',...
                'InnerPosition',Position,...
                'Tag',Tag,...
                'XTick',[],...
                'YTick',[]);
            
            pbarOriginal = obj.Ax.PlotBoxAspectRatio;
            
            obj.Im = imshow(full(Image),'Parent',obj.Ax);
            obj.Im.Tag = Tag;
            
            % restore defaults after calling imshow()
            obj.Ax.PlotBoxAspectRatioMode = 'manual';
            obj.Ax.PlotBoxAspectRatio = pbarOriginal;
            clear pbarOriginal
            
            obj.Ax.Title.String = Title;
            obj.Ax.Title.Units = 'Normalized';
            obj.Ax.Title.HorizontalAlignment = 'Center';
            obj.Ax.Title.VerticalAlignment = 'Top';
            obj.Ax.Title.Color = 'Yellow';
            obj.Ax.Title.Position = [0.5,1.0,0];            
            
            obj.tb = axtoolbar(obj.Ax,{});

            btn = axtoolbarbtn(obj.tb,'state');
            btn.Icon = 'MagnifyingGlassBlackAndYellow.png';
            btn.Tooltip = 'Zoom to Cursor';
            btn.ValueChangedFcn = @ZoomToCursor;
            
            drawnow
        end
        
        function delete(obj)
            % delete custom axes
            delete(obj)
            delete(obj.Ax)
        end
        
        
        function obj = SetAxisTitle(obj,title)
            % Set image (actually axis) title to top center of axis
            obj.Ax.Title.String = title;
            obj.Ax.Title.Units = 'Normalized';
            obj.Ax.Title.HorizontalAlignment = 'Center';
            obj.Ax.Title.VerticalAlignment = 'Top';
            obj.Ax.Title.Color = 'Yellow';
            obj.Ax.Title.Position = [0.5,1.0,0];
        end        
        
        
        
    end
end