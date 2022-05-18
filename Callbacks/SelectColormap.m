function SelectedMap = SelectColormap(ColormapsStruct)

    SelectedMap = zeros(256,3);

    ColormapNames = fieldnames(ColormapsStruct);

    nColormaps = length(ColormapNames);
    
    Height = nColormaps*50;
    
    ScreenSize = GetMaximizedScreenSize(0);

    ColormapSelector = uifigure('Name','Colormap Selector',...
        'Units','Pixels',...
        'Position',[ScreenSize(3)/2-150 (ScreenSize(4)-Height)/2 300 Height],...
        'Visible','On',...
        'WindowStyle','Modal',...
        'HandleVisibility','On',...
        'Color','White');

    ColormapGrid = uigridlayout(ColormapSelector,[nColormaps,1]);
    ColormapGrid.Padding = 10;
    ColormapGrid.RowSpacing = 10;
    ColormapGrid.ColumnSpacing = 0;
    RowHeights = {};
    for i = 1:nColormaps
        RowHeights{i} = 50;
    end
    
    ColormapSingleLine = linspace(0,1,300);
    ColormapImage = zeros(50,300);
    for i = 1:50
        ColormapImage(i,1:end) = ColormapSingleLine;
    end
    
    for i = 1:nColormaps
        
        ColormapsAxes(i) = uiaxes(ColormapGrid,...
            'Units','Normalized',...
            'Visible','Off',...
            'Tag',ColormapNames{i},...
            'XTick',[],...
            'YTick',[]);
        
        ColormapsAxes(i).Toolbar.Visible = 'Off';
        ColormapsAxes(i).Layout.Row = i;

        set(ColormapsAxes(i),'Colormap',ColormapsStruct.(ColormapNames{i}));

    end
    
     drawnow
     pause(0.3)
    
    for i = 1:nColormaps
        Colorbars(i) = colorbar(ColormapsAxes(i),'South');
        Colorbars(i).Ticks = [];
        Colorbars(i).Units = 'Normalized';
        Colorbars(i).Position = ColormapsAxes(i).InnerPosition;
        Colorbars(i).ButtonDownFcn = @ColormapSelected;
        Colorbars(i).Tag = ColormapNames{i};
    end
    
    waitfor(ColormapSelector)
    
    return

    function [] = ColormapSelected(source,event)
        SelectedMap = ColormapsStruct.(source.Tag);
        close(ColormapSelector);
    end

end