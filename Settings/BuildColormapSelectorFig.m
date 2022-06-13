function BuildColormapSelectorFig()

    try
        load('ColormapsSettings.mat')
        load('Colormaps.mat')
        ColormapNames = fieldnames(Colormaps);
        ImageTypeFields = fieldnames(ColormapsSettings);
        nImageTypes = length(ImageTypeFields);
        ImageTypeFullNames = cell(1,nImageTypes);
        ImageTypeColormapsNames = cell(1,nImageTypes);
        ImageTypeColormaps = cell(1,nImageTypes);
        for i = 1:nImageTypes
            ImageTypeFullNames{i} = ColormapsSettings.(ImageTypeFields{i}){1};
            ImageTypeColormapsNames{i} = ColormapsSettings.(ImageTypeFields{i}){2};
            ImageTypeColormaps{i} = ColormapsSettings.(ImageTypeFields{i}){3};
        end
    catch
        ColormapsSettings = struct();
        Colormaps = struct();
    end

    fHColormapSelector = uifigure('Name','Select Colormap',...
        'Visible','Off',...
        'WindowStyle','Modal',...
        'HandleVisibility','On',...
        'Color','White',...
        'Position',[0 0 250 500],...
        'AutoResizeChildren','Off',...
        'SizeChangedFcn',@AdjustColorbarSize,...
        'CreateFcn',@LoadColormaps);
    
    movegui(fHColormapSelector,'center');
    
    MyGrid = uigridlayout(fHColormapSelector,[4,1]);
    MyGrid.RowSpacing = 10;
    MyGrid.ColumnSpacing = 10;
    MyGrid.RowHeight = {'0.4x','1x',30,20};
    MyGrid.ColumnWidth = {'1x'};
    
    ListBoxPanel1 = uipanel(MyGrid,'Title','Image Type');
    
    MyGrid2 = uigridlayout(ListBoxPanel1,[1,1]);
    MyGrid2.Padding = [0 0 0 0];
    
    ImageTypeSelectBox = uilistbox(MyGrid2,...
        'Items',ImageTypeFullNames,...
        'ItemsData',ImageTypeFields,...
        'Value',ImageTypeFields{1},...
        'Tag','ImageTypeSelectBox',...
        'ValueChangedFcn',@ImageTypeSelectionChanged);   
    
    ListBoxPanel2 = uipanel(MyGrid,'Title','Colormaps');
    
    MyGrid3 = uigridlayout(ListBoxPanel2,[1,1]);
    MyGrid3.Padding = [0 0 0 0];
    
    ColormapSelectBox = uilistbox(MyGrid3,...
        'Items',ColormapNames,...
        'Value',ImageTypeColormapsNames{1},...
        'Tag','ColormapSelectBox',...
        'ValueChangedFcn',@ColormapSelectionChanged);
    
    ExampleColormapAx = uiaxes(MyGrid,...
        'Visible','Off',...
        'XTick',[],...
        'YTick',[],...
        'Units','Normalized');

    drawnow
    pause(0.05)
    
    ExampleColorbar = colorbar(ExampleColormapAx,'South');
    ExampleColorbar.Ticks = [];
    ExampleColorbar.Position = ExampleColormapAx.Position;
    
    DoneButton = uibutton(MyGrid,'Push','Text','Save and Return to PODS','ButtonPushedFcn',@SaveColormapSettings);
    
    ExampleColormapAx.Colormap = ImageTypeColormaps{1};
    
    fHColormapSelector.Visible = 'On';
    
    return
    
    function ImageTypeSelectionChanged(source,event)
        ImageTypeName = source.Value;
        ColormapSelectBox.Value = ColormapsSettings.(ImageTypeName){2};
        ExampleColormapAx.Colormap = ColormapsSettings.(ImageTypeName){3};
    end

    function ColormapSelectionChanged(source,event)
        ImageTypeName = ImageTypeSelectBox.Value;
        ColormapsSettings.(ImageTypeName){2} = source.Value;
        ColormapsSettings.(ImageTypeName){3} = Colormaps.(source.Value);
        ExampleColormapAx.Colormap = Colormaps.(source.Value);
    end

    function SaveColormapSettings(source,event)
        if ismac
            CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'/');
            save([SavePath,'/ColormapsSettings.mat'],'ColormapsSettings');        
            delete(fHColormapSelector)
        elseif ispc
            CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'\');
            save([SavePath,'\ColormapsSettings.mat'],'ColormapsSettings');        
            delete(fHColormapSelector)
        end

    end

    function AdjustColorbarSize(source,event)
        ExampleColorbar.Position = ExampleColormapAx.Position;
        drawnow
    end

    function UpdateDisplay()
        ImageTypeSelectBox.Items = ImageTypeFullNames;
        ImageTypeSelectBox.ItemsData = ImageTypeFields;
        ImageTypeSelectBox.Value = ImageTypeFields{1};
        ColormapSelectBox.Items = ColormapNames;
        ColormapSelectBox.Value = ImageTypeColormapsNames{1};
        ExampleColormapAx.Colormap = ImageTypeColormaps{1};
    end

    function LoadColormaps(source,event)
        movegui(source,'center');
        load('ColormapsSettings.mat')
        load('Colormaps.mat')
        ColormapNames = fieldnames(Colormaps);
        ImageTypeFields = fieldnames(ColormapsSettings);
        nImageTypes = length(ImageTypeFields);
        ImageTypeFullNames = cell(1,nImageTypes);
        ImageTypeColormapsNames = cell(1,nImageTypes);
        ImageTypeColormaps = cell(1,nImageTypes);
        for i = 1:nImageTypes
            ImageTypeFullNames{i} = ColormapsSettings.(ImageTypeFields{i}){1};
            ImageTypeColormapsNames{i} = ColormapsSettings.(ImageTypeFields{i}){2};
            ImageTypeColormaps{i} = ColormapsSettings.(ImageTypeFields{i}){3};
        end        
        UpdateDisplay();
        source.Visible = 'On';
    end

    

end