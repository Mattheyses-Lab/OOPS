function filters = objectFilterDialog(parent,project)
%OBJECTFILTERDIALOG Collect one or more AND-combined object-property filters.

arguments
    parent (1,1) matlab.ui.Figure
    project (1,1) oops.model.Project
end

properties = oops.model.ObjectMeasurements.plottableNames(project);
labels = oops.model.ObjectMeasurements.labels(properties,project);
operators = [">",">=","==","~=","<=","<"];
properties = reshape(properties,1,[]);
labels = reshape(labels,1,[]);

dialog = uifigure('Name','Object property filters','WindowStyle','modal', ...
    'Position',[0 0 620 300], ...
    'Color',[.12 .12 .12]);
oops.app.centerDialog(dialog);
cleanup = onCleanup(@() closeDialog(dialog));
grid = uigridlayout(dialog,[3 1], ...
    'RowHeight',{'1x','fit','fit'},'ColumnWidth',{'1x'}, ...
    'Padding',10,'RowSpacing',8,'BackgroundColor',[.12 .12 .12]);

data = table(properties(1),operators(1),0, ...
    'VariableNames',{'Property','Operator','Value'});
tableHost = uigridlayout(grid,[1 1],'ColumnWidth',{'1x'}, ...
    'RowHeight',{'fit'},'Padding',0,'Scrollable','on', ...
    'BackgroundColor',[.12 .12 .12]);
tableHost.Layout.Row = 1;
columns = [ ...
    matlabx.ui.control.ControlTableColumn( ...
        Name="Property",Label="Property",Width="2x",ControlType="dropdown", ...
        Items=labels,ItemsData=properties) ...
    matlabx.ui.control.ControlTableColumn( ...
        Name="Operator",Label="Comparison",Width=120,ControlType="dropdown", ...
        Items=operators,ItemsData=operators) ...
    matlabx.ui.control.ControlTableColumn( ...
        Name="Value",Label="Value",Width="1x",ControlType="numeric")];
tableControl = matlabx.ui.control.ControlTable(tableHost, ...
    Columns=columns,Data=data,SelectionMode="multiple");
tableControl.NewRowFcn = @(~) defaultFilterRow(properties(1));

editGrid = uigridlayout(grid,[1 3], ...
    'ColumnWidth',{'fit','fit','1x'},'RowHeight',{'fit'}, ...
    'Padding',0,'ColumnSpacing',5,'BackgroundColor',[.12 .12 .12]);
editGrid.Layout.Row = 2;
uibutton(editGrid,'Text','Add filter', ...
    'ButtonPushedFcn',@(~,~) tableControl.addNewRow());
uibutton(editGrid,'Text','Remove selected', ...
    'ButtonPushedFcn',@(~,~) tableControl.removeSelectedRows());

buttonGrid = uigridlayout(grid,[1 3], ...
    'ColumnWidth',{'1x','fit','fit'},'RowHeight',{'fit'}, ...
    'Padding',0,'ColumnSpacing',5,'BackgroundColor',[.12 .12 .12]);
buttonGrid.Layout.Row = 3;
uibutton(buttonGrid,'Text','Cancel', ...
    'ButtonPushedFcn',@(~,~) cancel());
apply = uibutton(buttonGrid,'Text','Apply', ...
    'ButtonPushedFcn',@(~,~) accept());
apply.Layout.Column = 3;

filters = struct('Property',{},'Operator',{},'Value',{});
dialog.CloseRequestFcn = @(~,~) cancel();
uiwait(dialog);

    function accept()
        rows = tableControl.Data;

        for k = 1:height(rows)
            propertyName = string(rows.Property(k));
            operator = string(rows.Operator(k));

            if ~ismember(propertyName,properties) || ismissing(propertyName) || ...
                    ismissing(operator) || ~isfinite(rows.Value(k))
                uialert(dialog,'Every filter requires a property and finite value.', ...
                    'Invalid filter','Icon','error');
                return;
            end

            filters(k,1) = struct( ...
                'Property',propertyName, ...
                'Operator',operator, ...
                'Value',double(rows.Value(k)));
        end

        uiresume(dialog);
        delete(dialog);
    end

    function cancel()
        filters = struct('Property',{},'Operator',{},'Value',{});
        uiresume(dialog);
        delete(dialog);
    end
end

function row = defaultFilterRow(property)
row = table(property,">",0, ...
    'VariableNames',{'Property','Operator','Value'});
end

function closeDialog(dialog)
%CLOSEDIALOG Release the modal figure after errors or external teardown.

if isvalid(dialog)
    delete(dialog);
end
end
