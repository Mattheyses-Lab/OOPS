% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function applied = collectionManagerDialog(parent,title,items,actions,opts)
%COLLECTIONMANAGERDIALOG Stage edits to one flat ordered model collection.

arguments
    parent (1,1) matlab.ui.Figure
    title (1,1) string
    items table
    actions (1,1) struct
    opts.ItemName (1,1) string = "item"
    opts.AllowMerge (1,1) logical = false
    opts.ShowID (1,1) logical = false
    opts.ShowHotkey (1,1) logical = false
end

applied = false;
original = items;
dialog = uifigure('Name',char(title),'WindowStyle','normal', ...
    'AutoResizeChildren','off','Position',[100 100 520 500], ...
    'Color',[.12 .12 .12]);
oops.app.centerDialog(dialog);

grid = uigridlayout(dialog,[3 1], ...
    'RowHeight',{'1x','fit','fit'},'ColumnWidth',{'1x'}, ...
    'Padding',5,'RowSpacing',5,'BackgroundColor',[.12 .12 .12]);

host = uigridlayout(grid,[1 1], ...
    'RowHeight',{'fit'},'ColumnWidth',{'1x'}, ...
    'Padding',0,'RowSpacing',0,'ColumnSpacing',0,'Scrollable','on');

columns = [ ...
    matlabx.ui.control.ControlTableColumn( ...
        Name="Name",Label="Name",Width="2x",ControlType="text") ...
    matlabx.ui.control.ControlTableColumn( ...
        Name="Color",Label="Color",Width=90,ControlType="color")];

if opts.ShowID
    columns = [columns(1), ...
        matlabx.ui.control.ControlTableColumn( ...
            Name="ID",Label="ID",Width="2x",ControlType="text", ...
            EnabledFcn=@(row,~,~) ~row.Protected), ...
        columns(2)];
end

if opts.ShowHotkey
    columns(end+1) = matlabx.ui.control.ControlTableColumn( ...
        Name="Hotkey",Label="Hotkey",Width=80,ControlType="text");
end

tableUI = matlabx.ui.control.ControlTable(host, ...
    Columns=columns,Data=items,SelectionMode="multiple",Reorderable=true);
tableUI.RowOperationRequestedFcn = @validateRowOperation;
tableUI.NewRowFcn = @(~) actions.New(tableUI.Data);

buttonWidths = {'fit','fit','1x'};
if opts.AllowMerge, buttonWidths = {'fit','fit','fit','1x'}; end
buttons = uigridlayout(grid,[1 numel(buttonWidths)], ...
    'ColumnWidth',buttonWidths,'RowHeight',{'fit'}, ...
    'Padding',0,'ColumnSpacing',5,'BackgroundColor',[.12 .12 .12]);
uibutton(buttons,'Text',char("Add "+opts.ItemName), ...
    'ButtonPushedFcn',@(~,~) tableUI.addNewRow());
deleteButton = uibutton(buttons,'Text','Delete selected', ...
    'ButtonPushedFcn',@(~,~) tableUI.removeSelectedRows());
mergeButton = [];
if opts.AllowMerge
    mergeButton = uibutton(buttons,'Text','Merge selected', ...
        'ButtonPushedFcn',@(~,~) mergeSelected());
end

footer = uigridlayout(grid,[1 3], ...
    'ColumnWidth',{'1x','fit','fit'},'RowHeight',{'fit'}, ...
    'Padding',0,'ColumnSpacing',5,'BackgroundColor',[.12 .12 .12]);
uibutton(footer,'Text','Cancel','ButtonPushedFcn',@(~,~) cancel());
uibutton(footer,'Text','Apply','ButtonPushedFcn',@(~,~) apply());

tableUI.SelectionChangedFcn = @(~,~) updateButtons();
updateButtons();
dialog.CloseRequestFcn = @(~,~) cancel();
uiwait(dialog);

if isvalid(dialog)
    delete(dialog);
end

    function validateRowOperation(~,event)
        switch event.Operation
            case "duplicate"
                event.Cancel = true;
                uialert(dialog,'Use Add row so the new item receives a unique identity.', ...
                    'Duplicate unavailable','Icon','info');

            case "remove"
                if any(event.ProposedData.Protected)
                    event.Cancel = true;
                    uialert(dialog,'The protected item cannot be deleted.', ...
                        'Protected item','Icon','warning');
                end

            case "reorder"
                source = event.SourceRow;
                destination = event.DestinationRow;
                protected = find(tableUI.Data.Protected);

                if tableUI.Data.Protected(source) || ...
                        any(protected >= min(source,destination) & ...
                        protected <= max(source,destination))
                    event.Cancel = true;
                end
        end
    end

    function mergeSelected()
        rows = tableUI.SelectedRows;
        if numel(rows) < 2 || any(tableUI.Data.Protected(rows))
            return;
        end

        try
            merged = actions.Merge(tableUI.Data,rows);
        catch ME
            showError(ME);
            return;
        end

        tableUI.removeSelectedRows();
        tableUI.addRow(merged);
        tableUI.ActiveRow = height(tableUI.Data);
    end

    function apply()
        try
            accepted = actions.Apply(original,tableUI.Data,dialog);
        catch ME
            showError(ME);
            return;
        end

        if accepted
            applied = true;
            uiresume(dialog);
        end
    end

    function cancel()
        uiresume(dialog);
    end

    function updateButtons()
        selected = tableUI.SelectedRows;
        protected = ~isempty(selected) && any(tableUI.Data.Protected(selected));
        deleteButton.Enable = matlab.lang.OnOffSwitchState(~isempty(selected) && ~protected);
        if opts.AllowMerge
            mergeButton.Enable = matlab.lang.OnOffSwitchState( ...
                numel(selected) >= 2 && ~protected);
        end
    end

    function showError(exception)
        oops.Log.EXCEPTION(exception);
        uialert(dialog,exception.message,'OOPS','Icon','error');
    end
end
