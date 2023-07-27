function filterSetOut = defineFilterSet(vars,varsLong)
% opens a figure for the user to define a set of property filters (see propertyFilterSet.m)

latexStyle = uistyle("Interpreter","latex");

filterSetOut = [];

%% set up main figure and its grids

    fH_defineFilterSet = uifigure("WindowStyle","alwaysontop",...
        "Name","Define property filters",...
        "Units","pixels",...
        "Position",[100 100 500 300],...
        "Visible","off",...
        "CloseRequestFcn",@CloseAndCancel);

    mainGrid = uigridlayout(fH_defineFilterSet,[2,1],...
        "Padding",[5 5 5 5],...
        "RowHeight",{'1x',30},...
        "ColumnWidth",{'1x'});

    filterModuleGrid = uigridlayout(mainGrid,[1,5],...
        "Padding",[5 5 5 5],...
        "RowSpacing",5,...
        "Scrollable","on",...
        "RowHeight",{20},...
        "ColumnWidth",{'1x',60,'0.5x',20,20});

    exitOptionsGrid = uigridlayout(mainGrid,[1,2],...
        "Padding",[5 5 5 5],...
        "RowHeight",{20},...
        "ColumnWidth",{'1x','1x'});

    nFilters = 1;

%% set up first filter module

    propDropdown(1) = uidropdown(filterModuleGrid,...
        "Items",varsLong,...
        "ItemsData",vars);

    propRelationshipDropdown(1) = uidropdown(filterModuleGrid,...
        "Items",{'$$>$$','$$>=$$','$$=$$','$$<=$$','$$<$$'},...
        "ItemsData",{'>','>=','==','<=','<'});
    addStyle(propRelationshipDropdown(1),latexStyle);

    propValueEditfield(1) = uieditfield(filterModuleGrid,"numeric");

    addFilterButton = uibutton(filterModuleGrid,...
        "Text","",...
        "Icon","PlusSymbolIcon.png",...
        "IconAlignment","center",...
        "ButtonPushedFcn",@addFilterModule);

    deleteFilterButton = uibutton(filterModuleGrid,...
        "Text","",...
        "Icon","MinusSymbolIcon.png",...
        "IconAlignment","center",...
        "ButtonPushedFcn",@deleteFilterModule,...
        "Enable","off");

%% set up exit buttons

    cancelButton = uibutton(exitOptionsGrid,...
        "Text","Cancel",...
        "ButtonPushedFcn",@CloseAndCancel);

    continueButton = uibutton(exitOptionsGrid,...
        "Text","Continue",...
        "ButtonPushedFcn",@CloseAndContinue);

%% move window to center and make it visible

    movegui(fH_defineFilterSet,'center')
    fH_defineFilterSet.Visible = 'On';

    % wait until the window is closed to return
    waitfor(fH_defineFilterSet);

%% nested callbacks

    function addFilterModule(~,~)
        % increment filter counter
        nFilters = nFilters + 1;
        % add a row to the filter module grid
        filterModuleGrid.RowHeight = num2cell(repmat(20,1,nFilters));
        % components for the new filter module
        propDropdown(nFilters) = uidropdown(filterModuleGrid,...
        "Items",varsLong,...
        "ItemsData",vars);
        propRelationshipDropdown(nFilters) = uidropdown(filterModuleGrid,...
            "Items",{'$$>$$','$$>=$$','$$=$$','$$<=$$','$$<$$'},...
            "ItemsData",{'>','>=','==','<=','<'});
        addStyle(propRelationshipDropdown(nFilters),latexStyle);
        propValueEditfield(nFilters) = uieditfield(filterModuleGrid,"numeric");
        % move plus and minus buttons to the last row
        addFilterButton.Layout.Row = nFilters;
        deleteFilterButton.Layout.Row = nFilters;
        % enable/disable the deleteFilterButton based on nFilters
        deleteFilterButton.Enable = nFilters > 1;
    end

    function deleteFilterModule(~,~)
        % delete components for the filter module in the last row
        delete(propDropdown(nFilters));
        delete(propRelationshipDropdown(nFilters));
        delete(propValueEditfield(nFilters));
        % decrement filter counter
        nFilters = nFilters - 1;
        % move plus and minus buttons to the last row
        addFilterButton.Layout.Row = nFilters;
        deleteFilterButton.Layout.Row = nFilters;
        % remove the last row from the filter module grid
        filterModuleGrid.RowHeight = num2cell(repmat(20,1,nFilters));
        % enable/disable the deleteFilterButton based on nFilters
        deleteFilterButton.Enable = nFilters > 1;
    end

    function CloseAndCancel(~,~)
        filterSetOut = [];
        delete(fH_defineFilterSet);
    end

    function CloseAndContinue(~,~)
        % create an empty property filter set
        filterSetOut = propertyFilterSet();
        % add a new filter for each filter module row defined by the user
        for i = 1:nFilters
            propRealName = propDropdown(i).Value;
            propFullName = varsLong(ismember(vars,propRealName));
            propFullName = propFullName{1};
            propRelationship = propRelationshipDropdown(i).Value;
            propValue = propValueEditfield(i).Value;

            filterSetOut.addFilter(...
                propFullName,...
                propRealName,...
                propRelationship,...
                propValue...
                );
        end
        % delete the figure window
        delete(fH_defineFilterSet);
    end

end