function ChosenLabel = ChooseObjectLabel(source)

% can delete this function %

    PODSData = guidata(source);

    ChosenLabel = PODSData.Settings.ObjectLabels(1);
    
    fHChooseLabel = uifigure('Name','Choose a label for the selected objects',...
        'Units','Pixels',...
        'Position',[0 0 400 400],...
        'Visible','Off',...
        'WindowStyle','Normal',...
        'HandleVisibility','On',...
        'Color','White',...
        'AutoresizeChildren','On');
    
    movegui(fHChooseLabel,'center')
    
    MyGrid = uigridlayout(fHChooseLabel,[3,2]);
    MyGrid.Padding = [10,20,10,20];
    MyGrid.RowSpacing = 20;
    MyGrid.ColumnSpacing = 10;
    MyGrid.RowHeight = {'1x',20,20};
    MyGrid.ColumnWidth = {'1x','1x'};

    LabelList = uilistbox('Parent',MyGrid,...
        'enable','on',...
        'Items',{PODSData.Settings.ObjectLabels.NameAndColor},...
        'MultiSelect','Off',...
        'ValueChangedFcn',@LabelListValueChanged);
    
    LabelList.Layout.Row = 1;
    LabelList.Layout.Column = [1 2];
    UpdateLabelList();

    EditNameButton = uibutton(MyGrid,...
        'Push',...
        'Text','Edit Name',...
        'ButtonPushedFcn',@pbEditLabelName);
    EditNameButton.Layout.Row = 2;
    EditNameButton.Layout.Column = 1;
    
    EditColorButton = uibutton(MyGrid,...
        'Push',...
        'Text','Edit Color',...
        'ButtonPushedFcn',@pbEditLabelColor);
    EditColorButton.Layout.Row = 2;
    EditColorButton.Layout.Column = 2;    

    DoneButton = uibutton(MyGrid,...
        'Push',...
        'Text','Apply label to selected objects',...
        'ButtonPushedFcn',@pbCloseAndContinue);
    DoneButton.Layout.Row = 3;
    DoneButton.Layout.Column = [1 2];
    
    fHChooseLabel.Visible = 'On';
    
    % pause here until the figure is closed
    waitfor(fHChooseLabel)
    % update the gui data
    guidata(source,PODSData);

    function LabelListValueChanged(source,event)
        LabelListChoice = LabelList.Items{LabelList.Value};
        
        if strcmp(LabelListChoice,'+')
            % if uses selects '+', make a new label
            disp('Creating new label...')
            %PODSData.Settings.ObjectLabels(end+1) = MakeNewLabel(LabelList.Value);
            
            PODSData.Settings.ObjectLabels(end+1) = PODSLabel(['Label ',num2str(LabelList.Value)],[1 1 1],LabelList.Value);
            ChosenLabel = PODSData.Settings.ObjectLabels(end);
            UpdateLabelList();
        else
            % ChosenLabel is set from LabelList idx using PODSSettings.ObjectLabels
            ChosenLabel = PODSData.Settings.ObjectLabels(LabelList.Value);
        end
    end
    
    function pbEditLabelName(source,event)
        fHChooseLabel.Visible = 'Off';
        fHEditLabelName = uifigure('Name','Enter a new label name',...
            'Units','Pixels',...
            'Position',[0 0 300 100],...
            'Visible','Off',...
            'WindowStyle','Modal',...
            'HandleVisibility','On',...
            'Color','White',...
            'AutoresizeChildren','On');
        
        movegui(fHEditLabelName,'center');
        
        MyGrid2 = uigridlayout(fHEditLabelName,[2,1]);
        MyGrid2.Padding = [10,20,10,20];
        MyGrid2.RowSpacing = 20;
        MyGrid2.ColumnSpacing = 10;
        MyGrid2.RowHeight = {20,20};
        MyGrid2.ColumnWidth = {'1x'};
        
        EditLabelNameEditBox = uieditfield('Parent',MyGrid2,'Value',ChosenLabel.Name);
        
        DoneEditingLabelButton = uibutton(MyGrid2,...
            'Push',...
            'Text','Save Label Name',...
            'ButtonPushedFcn',@pbDoneEditingLabelName);
        
        fHEditLabelName.Visible = 'On';
        waitfor(fHEditLabelName);
        
        UpdateLabelList();
        fHChooseLabel.Visible = 'On';
        
        function pbDoneEditingLabelName(source,event)
            ChosenLabel.Name = EditLabelNameEditBox.Value;
            close(fHEditLabelName);
        end
    end

    function pbEditLabelColor(source,event)
        ChosenLabel.Color = uisetcolor();
        figure(PODSData.Handles.fH)
        figure(fHChooseLabel)
        UpdateLabelList();
    end

    function UpdateLabelList()
        LabelList.Items = {PODSData.Settings.ObjectLabels.NameAndColor,'+'};
        LabelList.ItemsData = [1:1:length(LabelList.Items)];
    end

    function pbCloseAndContinue(source,event)
        close(fHChooseLabel);
    end

end