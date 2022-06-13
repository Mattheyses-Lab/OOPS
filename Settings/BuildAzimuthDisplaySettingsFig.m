function BuildAzimuthDisplaySettingsFig()

    try
        load('AzimuthDisplaySettings.mat')
    catch
        disp('Failed to load "AzimuthDisplaySettings.mat", proceeding with default settings...');
        AzimuthDisplaySettings = struct();
        AzimuthDisplaySettings.LineAlpha = 0.5;
        AzimuthDisplaySettings.LineWidth = 1;
        AzimuthDisplaySettings.LineScale = 100;
        AzimuthDisplaySettings.ScaleDownFactor = 1;
    end

    fHAzimuthSettings = uifigure('Name','Choose Azimuth Display Settings',...
        'Visible','Off',...
        'WindowStyle','Modal',...
        'HandleVisibility','On',...
        'Color','White',...
        'Position',[0 0 400 220],...
        'CreateFcn',@LoadAzimuthDisplaySettings);
    
    movegui(fHAzimuthSettings,'center')
    
    MyGrid = uigridlayout(fHAzimuthSettings,[5,2]);
    MyGrid.Padding = [10,20,10,20];
    MyGrid.RowSpacing = 20;
    MyGrid.ColumnSpacing = 10;
    MyGrid.RowHeight = {20,20,20,20,20};
    MyGrid.ColumnWidth = {'fit','1x'};
        
    AzimuthLineAlphaLabel = uilabel('Parent',MyGrid,'Text','Azimuth Line Alpha (default: 0.5)');
    AzimuthLineAlphaDropdown = uidropdown('Parent',MyGrid,...
        'Items',{'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
        'ItemsData',{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1},...
        'Value',AzimuthDisplaySettings.LineAlpha);

    AzimuthLineWidthLabel = uilabel('Parent',MyGrid,'Text','Azimuth Line Width (default: 1 pt)');
    AzimuthLineWidthDropdown = uidropdown('Parent',MyGrid,...
        'Items',{'1','2','3','4','5','6','7','8','9','10'},...
        'ItemsData',{1,2,3,4,5,6,7,8,9,10},...
        'Value',AzimuthDisplaySettings.LineWidth);    

    AzimuthLineScaleLabel = uilabel('Parent',MyGrid,'Text','Azimuth Line Scale Factor (default: 100)');
    AzimuthLineScaleEditfield = uieditfield('Parent',MyGrid,'Value',num2str(AzimuthDisplaySettings.LineScale));    
    
    AzimuthLineScaleDownLabel = uilabel('Parent',MyGrid,'Text','Number of Lines to Show (default: All)');
    AzimuthLineScaleDownDropdown = uidropdown('Parent',MyGrid,...
        'Items',{'All','Half','Quarter'},...
        'ItemsData',{1,2,4},...
        'Value',AzimuthDisplaySettings.ScaleDownFactor);
    AzimuthLineScaleDownDropdown.ItemsData = [1 2 4];

    SavePushbutton = uibutton(MyGrid,...
        'Push',...
        'Text','Save and Return to PODS',...
        'ButtonPushedFcn',@SaveAzimuthSettings);
    
    SavePushbutton.Layout.Column = [1 2];
    
    fHAzimuthSettings.Visible = 'On';
    
    return


    function SaveAzimuthSettings(source,event)
        if ismac
            AzimuthDisplaySettings.LineAlpha = AzimuthLineAlphaDropdown.Value;
            AzimuthDisplaySettings.LineWidth = AzimuthLineWidthDropdown.Value;
            AzimuthDisplaySettings.LineScale = str2num(AzimuthLineScaleEditfield.Value);
            AzimuthDisplaySettings.ScaleDownFactor = AzimuthLineScaleDownDropdown.Value;
            CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'/');
            save([SavePath,'/AzimuthDisplaySettings.mat'],'AzimuthDisplaySettings');
            close(fHAzimuthSettings)
        elseif ispc
            AzimuthDisplaySettings.LineAlpha = AzimuthLineAlphaDropdown.Value;
            AzimuthDisplaySettings.LineWidth = AzimuthLineWidthDropdown.Value;
            AzimuthDisplaySettings.LineScale = str2num(AzimuthLineScaleEditfield.Value);
            AzimuthDisplaySettings.ScaleDownFactor = AzimuthLineScaleDownDropdown.Value;
            CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'\');
            save([SavePath,'\AzimuthDisplaySettings.mat'],'AzimuthDisplaySettings');
            close(fHAzimuthSettings)
        end
    end

    function LoadAzimuthDisplaySettings(source,event)
        movegui(source,'center');
        load('AzimuthDisplaySettings.mat');
        try
            load('AzimuthDisplaySettings.mat');
            AzimuthLineAlphaDropdown.Value = AzimuthDisplaySettings.LineAlpha;
            AzimuthLineWidthDropdown.Value = AzimuthDisplaySettings.LineWidth;
            AzimuthLineScaleEditfield.Value = num2str(AzimuthDisplaySettings.LineScale);
            AzimuthLineScaleDownDropdown.Value = AzimuthDisplaySettings.ScaleDownFactor;
        catch
            disp('Failed to load "AzimuthDisplaySettings.mat", proceeding with default settings...');
            AzimuthLineAlphaDropdown.Value = 0.5;
            AzimuthLineWidthDropdown.Value = 1;
            AzimuthLineScaleEditfield.Value = num2str(100);
            AzimuthLineScaleDownDropdown.Value = 1;
        end
        set(source,'Visible','On');
    end
end