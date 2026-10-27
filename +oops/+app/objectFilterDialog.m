function filters = objectFilterDialog(parent,project)
%OBJECTFILTERDIALOG Collect one or more AND-combined object-property filters.

arguments
    parent (1,1) matlab.ui.Figure
    project (1,1) oops.model.Project
end

properties = oops.model.ObjectMeasurements.plottableNames(project);
labels = oops.model.ObjectMeasurements.labels(properties,project);
operators = [">",">=","==","~=","<=","<"];

% Categorical table variables render as constrained drop-downs. This keeps
% internal property names and comparison operators out of free-form text input.
propertyChoice = categorical(labels(1),labels,'Ordinal',true);
operatorChoice = categorical(operators(1),operators,'Ordinal',true);

dialog = uifigure('Name','Object property filters','WindowStyle','modal', ...
    'Position',[0 0 620 300], ...
    'Color',[.12 .12 .12]);
oops.app.centerDialog(dialog);
cleanup = onCleanup(@() closeDialog(dialog));
grid = uigridlayout(dialog,[3 1], ...
    'RowHeight',{'1x','fit','fit'},'ColumnWidth',{'1x'}, ...
    'Padding',10,'RowSpacing',8,'BackgroundColor',[.12 .12 .12]);

data = table(propertyChoice,operatorChoice,0, ...
    'VariableNames',{'Property','Operator','Value'});
tableControl = uitable(grid,'Data',data, ...
    'ColumnName',{'Property','Comparison','Value'}, ...
    'ColumnEditable',[true true true], ...
    'RowName',{},'BackgroundColor',[.18 .18 .18;.22 .22 .22], ...
    'ForegroundColor',[.9 .9 .9]);
tableControl.Layout.Row = 1;

editGrid = uigridlayout(grid,[1 3], ...
    'ColumnWidth',{'fit','fit','1x'},'RowHeight',{'fit'}, ...
    'Padding',0,'ColumnSpacing',5,'BackgroundColor',[.12 .12 .12]);
editGrid.Layout.Row = 2;
uibutton(editGrid,'Text','Add filter', ...
    'ButtonPushedFcn',@(~,~) addFilter());
uibutton(editGrid,'Text','Remove last', ...
    'ButtonPushedFcn',@(~,~) removeFilter());

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

    function addFilter()
        rows = tableControl.Data;
        rows(end+1,:) = {propertyChoice,operatorChoice,0};
        tableControl.Data = rows;
    end

    function removeFilter()
        rows = tableControl.Data;

        if height(rows) > 1
            rows(end,:) = [];
            tableControl.Data = rows;
        end
    end

    function accept()
        rows = tableControl.Data;

        for k = 1:height(rows)
            propertyLabel = string(rows.Property(k));
            operator = string(rows.Operator(k));
            labelIndex = find(labels == propertyLabel,1);

            if isempty(labelIndex) || ismissing(propertyLabel) || ...
                    ismissing(operator) || ~isfinite(rows.Value(k))
                uialert(dialog,'Every filter requires a property and finite value.', ...
                    'Invalid filter','Icon','error');
                return;
            end

            filters(k,1) = struct( ...
                'Property',properties(labelIndex), ...
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

function closeDialog(dialog)
%CLOSEDIALOG Release the modal figure after errors or external teardown.

if isvalid(dialog)
    delete(dialog);
end
end
