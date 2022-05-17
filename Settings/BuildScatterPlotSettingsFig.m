function BuildScatterPlotSettingsFig()
%% Builds figure that allows changing scatterplot settings in the main gui
%       this function is not used by the main gui, only to build the figure
%       which will be saved as a .fig file for faster loading
    try
        load('ScatterPlotSettings.mat');
    catch
        ScatterPlotSettings = struct();
        ScatterPlotSettings.XVariable = 'SBRatio';
        ScatterPlotSettings.YVariable = 'OFAvg';
    end
    
    fHScatterPlotSettings = uifigure('Name','Scatter Plot Settings',...
        'Visible','Off',...
        'WindowStyle','Modal',...
        'HandleVisibility','On',...
        'Color','White',...
        'Position',[0 0 500 400],...
        'CreateFcn',@LoadScatterPlotSettings);

    movegui(fHScatterPlotSettings,'center');
    
    MyGrid = uigridlayout(fHScatterPlotSettings,[2,2])
    MyGrid.RowSpacing = 10;
    MyGrid.ColumnSpacing = 10;
    MyGrid.RowHeight = {'1x',20};
    MyGrid.ColumnWidth = {'1x','1x'};

    % setting up x-axis variable selection
    XVarListBoxPanel = uipanel(MyGrid,'Title','X-axis Variable');
    XVarListBoxPanel.Layout.Row = 1;
    XVarListBoxPanel.Layout.Column = 1;
    
    XVarGrid = uigridlayout(XVarListBoxPanel,[1,1]);
    XVarGrid.Padding = [0 0 0 0];

    XSelectBox = uilistbox(XVarGrid,...
        'Items', ScatterPlotSettings.VariablesLong,...
        'ItemsData', ScatterPlotSettings.VariablesShort,...
        'Value',ScatterPlotSettings.XVariable,...
        'Tag','YSelectBox');    
    
    % setting up y-axis variable selection
    YVarListBoxPanel = uipanel(MyGrid,'Title','Y-axis Variable');
    YVarListBoxPanel.Layout.Row = 1;
    YVarListBoxPanel.Layout.Column = 2;

    YVarGrid = uigridlayout(YVarListBoxPanel,[1,1]);
    YVarGrid.Padding = [0 0 0 0];

    YSelectBox = uilistbox(YVarGrid,...
        'Items', ScatterPlotSettings.VariablesLong,...
        'ItemsData', ScatterPlotSettings.VariablesShort,...
        'Value',ScatterPlotSettings.YVariable,...
        'Tag','YSelectBox');

    % button to save settings and continue
    DoneButton = uibutton(MyGrid,'Push','Text','Save and Return to PODS','ButtonPushedFcn',@SaveScatterPlotSettings);
    DoneButton.Layout.Row = 2;
    DoneButton.Layout.Column = [1 2];

    function SaveScatterPlotSettings(source,event)
        ScatterPlotSettings.XVariable = XSelectBox.Value;
        ScatterPlotSettings.YVariable = YSelectBox.Value;
        CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
        SavePath = strjoin(CurrentPathSplit(1:end-1),'/');
        save([SavePath,'/ScatterPlotSettings.mat'],'ScatterPlotSettings');
        close(fHScatterPlotSettings)
    end    

    function LoadScatterPlotSettings(source,event)
        movegui(source,'center');
        load('ScatterPlotSettings.mat');
        try
            XSelectBox.Items = ScatterPlotSettings.VariablesLong;
            XSelectBox.ItemsData = ScatterPlotSettings.VariablesShort;
        end
        try
            YSelectBox.Items = ScatterPlotSettings.VariablesLong;
            YSelectBox.ItemsData = ScatterPlotSettings.VariablesShort;
        end        
        % select button in group according to settings file
        try
            XSelectBox.Value = ScatterPlotSettings.XVariable;
        end
        try
            YSelectBox.Value = ScatterPlotSettings.YVariable;
        end
        set(source,'Visible','On');        
    end



end