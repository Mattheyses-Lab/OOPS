function BuildSwarmChartSettingsFig()

    try
        load('SwarmChartSettings.mat');
    catch
        SwarmChartSettings = struct();
        SwarmChartSettings.GroupingType = 'Label';
        SwarmChartSettings.ColorMode = 'ID';
        SwarmChartSettings.YVariable = 'OFAvg';
    end

    fHSwarmChartSettings = uifigure('Name','Swarm Chart Settings',...
        'Visible','Off',...
        'WindowStyle','Modal',...
        'HandleVisibility','On',...
        'Color','White',...
        'Position',[0 0 300 300],...
        'CreateFcn',@LoadSwarmChartSettings);

    movegui(fHSwarmChartSettings,'center');

    MyGrid = uigridlayout(fHSwarmChartSettings,[3,2]);
    MyGrid.RowSpacing = 10;
    MyGrid.ColumnSpacing = 10;
    MyGrid.RowHeight = {'1x',110,20};
    MyGrid.ColumnWidth = {'1x','1x'};
    
    
    ListBoxPanel = uipanel(MyGrid,'Title','Y-axis Variable');
    ListBoxPanel.Layout.Row = 1;
    ListBoxPanel.Layout.Column = [1 2];
    
    %pos = ListBoxPanel.InnerPosition;
    
    MyGrid2 = uigridlayout(ListBoxPanel,[1,1]);
    MyGrid2.Padding = [0 0 0 0];

    YSelectBox = uilistbox(MyGrid2,...
        'Items',SwarmChartSettings.VariablesLong,...
        'ItemsData',SwarmChartSettings.VariablesShort,...
        'Tag','YSelectBox');
    
    % set current value based on settings file
    YSelectBox.Value = SwarmChartSettings.YVariable;
    
    % button group 1
    ButtonGroup1 = uibuttongroup(MyGrid,'Title','X-axis grouping');
    
    % button group 2
    ButtonGroup2 = uibuttongroup(MyGrid,'Title','Color Mode');

    DoneButton = uibutton(MyGrid,'Push','Text','Save and Return to PODS','ButtonPushedFcn',@SaveSwarmChartSettings);
    DoneButton.Layout.Column = [1 2];
    
    % draw the current figure to update final container sizes
    drawnow
    pause(0.05)
    
    pos = ButtonGroup1.InnerPosition;
    height2 = pos(4);
    width2 = pos(3);    
    % radio buttons for x-axis grouping
    ButtonGroup1rb1 = uiradiobutton(ButtonGroup1,'Text','Group','Position',[10 height2-25 width2-20 15]);
    ButtonGroup1rb2 = uiradiobutton(ButtonGroup1,'Text','Label','Position',[10 height2-50 width2-20 15]);
    ButtonGroup1rb3 = uiradiobutton(ButtonGroup1,'Text','Both','Position',[10 height2-75 width2-20 15]);
    
    % select button in group according to settings file
    switch SwarmChartSettings.GroupingType
        case 'Group'
            ButtonGroup1.SelectedObject = ButtonGroup1rb1;
        case 'Label'
            ButtonGroup1.SelectedObject = ButtonGroup1rb2;
        case 'Both'
            ButtonGroup1.SelectedObject = ButtonGroup1rb3;
    end
    
    % radio buttons for coloring type
    ButtonGroup2rb1 = uiradiobutton(ButtonGroup2,'Text','Magnitude','Position',[10 height2-25 width2-20 15]);
    ButtonGroup2rb2 = uiradiobutton(ButtonGroup2,'Text','ID','Position',[10 height2-50 width2-20 15]);    
    
    % select button in group according to settings file
    switch SwarmChartSettings.ColorMode
        case 'Magnitude'
            ButtonGroup2.SelectedObject = ButtonGroup2rb1;
        case 'ID'
            ButtonGroup2.SelectedObject = ButtonGroup2rb2;
    end    

    fHSwarmChartSettings.Visible = 'On';
    
    function SaveSwarmChartSettings(source,event)
        if ismac
            SwarmChartSettings.GroupingType = ButtonGroup1.SelectedObject.Text;
            SwarmChartSettings.ColorMode = ButtonGroup2.SelectedObject.Text;
            SwarmChartSettings.YVariable = YSelectBox.Value;
            CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'/');
            save([SavePath,'/SwarmChartSettings.mat'],'SwarmChartSettings');
            close(fHSwarmChartSettings)
        elseif ispc
            SwarmChartSettings.GroupingType = ButtonGroup1.SelectedObject.Text;
            SwarmChartSettings.ColorMode = ButtonGroup2.SelectedObject.Text;
            SwarmChartSettings.YVariable = YSelectBox.Value;
            CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'\');
            save([SavePath,'\SwarmChartSettings.mat'],'SwarmChartSettings');
            close(fHSwarmChartSettings)
        end
    end

    function LoadSwarmChartSettings(source,event)
        movegui(source,'center');
        load('SwarmChartSettings.mat');
        % select button in group according to settings file
        try
            switch SwarmChartSettings.GroupingType
                case 'Group'
                    ButtonGroup1.SelectedObject = ButtonGroup1rb1;
                case 'Label'
                    ButtonGroup1.SelectedObject = ButtonGroup1rb2;
                case 'Both'
                    ButtonGroup1.SelectedObject = ButtonGroup1rb3;
            end
        end
        
        try
            switch SwarmChartSettings.ColorMode
                case 'Magnitude'
                    ButtonGroup2.SelectedObject = ButtonGroup2rb1;
                case 'ID'
                    ButtonGroup2.SelectedObject = ButtonGroup2rb2;
            end
        end
        try
            YSelectBox.Items = SwarmChartSettings.VariablesLong;
            YSelectBox.ItemsData = SwarmChartSettings.VariablesShort;
        end
        try
            % set current value based on settings file
            YSelectBox.Value = SwarmChartSettings.YVariable;
        end
        set(source,'Visible','On');
    end

end