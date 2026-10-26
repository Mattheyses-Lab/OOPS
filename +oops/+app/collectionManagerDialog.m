% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function collectionManagerDialog(parent,title,itemsFcn,actions,opts)
%COLLECTIONMANAGERDIALOG Manage one flat ordered model collection.

arguments
    parent (1,1) matlab.ui.Figure
    title (1,1) string
    itemsFcn (1,1) function_handle
    actions (1,1) struct
    opts.Hint (1,1) string = "Highlight an item to edit, delete, or reorder it."
end

dialog = uifigure('Name',char(title),'WindowStyle','normal', ...
    'AutoResizeChildren','off','Position',[100 100 440 500], ...
    'Color',[.12 .12 .12]);
oops.app.centerDialog(dialog);

grid = uigridlayout(dialog,[3 1], ...
    'RowHeight',{'1x','fit','fit'},'ColumnWidth',{'1x'}, ...
    'Padding',5,'RowSpacing',5,'BackgroundColor',[.12 .12 .12]);

tree = uitree(grid,'checkbox','BackgroundColor',[.18 .18 .18], ...
    'FontColor',[.9 .9 .9], ...
    'SelectionChangedFcn',@(~,~) updateButtons());

buttons = uigridlayout(grid,[1 5], ...
    'ColumnWidth',{'1x','1x','1x','1x','1x'}, ...
    'RowHeight',{'fit'},'Padding',0,'ColumnSpacing',5, ...
    'BackgroundColor',[.12 .12 .12]);
newButton = uibutton(buttons,'Text','New...', ...
    'ButtonPushedFcn',@(~,~) runAction(actions.New,""));
editButton = uibutton(buttons,'Text','Edit...', ...
    'ButtonPushedFcn',@(~,~) runAction(actions.Edit,selectedID()));
deleteButton = uibutton(buttons,'Text','Delete', ...
    'ButtonPushedFcn',@(~,~) runAction(actions.Delete,selectedID()));
upButton = uibutton(buttons,'Text','Move up', ...
    'ButtonPushedFcn',@(~,~) runMove(-1));
downButton = uibutton(buttons,'Text','Move down', ...
    'ButtonPushedFcn',@(~,~) runMove(1));

footer = uigridlayout(grid,[1 2], ...
    'ColumnWidth',{'1x','fit'},'RowHeight',{'fit'}, ...
    'Padding',0,'ColumnSpacing',5,'BackgroundColor',[.12 .12 .12]);
uilabel(footer,'Text',char(opts.Hint+" Changes are applied immediately."), ...
    'FontColor',[.75 .75 .75]);
uibutton(footer,'Text','Close','ButtonPushedFcn',@(~,~) uiresume(dialog));

refresh("");
dialog.CloseRequestFcn = @(~,~) uiresume(dialog);
uiwait(dialog);

if isvalid(dialog)
    delete(dialog);
end

    function id = selectedID()
        id = "";

        if ~isempty(tree.SelectedNodes)
            id = string(tree.SelectedNodes(1).NodeData);
        end
    end

    function runAction(action,id)
        isNew = isequal(action,actions.New);

        if id == "" && ~isNew
            return;
        end

        try
            action(id,dialog);
        catch ME
            oops.Log.EXCEPTION(ME);
            uialert(dialog,ME.message,'OOPS');
            return;
        end

        if isNew
            refresh("__last__");
        else
            refresh(id);
        end

        figure(dialog);
    end

    function runMove(offset)
        id = selectedID();

        if id == ""
            return;
        end

        try
            actions.Move(id,offset,dialog);
        catch ME
            oops.Log.EXCEPTION(ME);
            uialert(dialog,ME.message,'OOPS');
            return;
        end

        refresh(id);
    end

    function refresh(preferredID)
        checked = strings(0,1);

        if ~isempty(tree.CheckedNodes)
            checked = string({tree.CheckedNodes.NodeData});
        end

        % CheckedNodes and SelectedNodes must not retain handles that are
        % about to be deleted from this tree.
        tree.CheckedNodes = [];
        tree.SelectedNodes = [];
        delete(tree.Children);
        items = itemsFcn();

        for k = 1:numel(items)
            node = uitreenode(tree,'Text',char(items(k).Name), ...
                'NodeData',items(k).ID);
            node.Icon = char(matlabx.ui.icon.get( ...
                Shape="circle",Color=items(k).Color,Size=16));
        end

        % Query the tree after construction so every assigned handle is known
        % by MATLAB to be a current direct child of this exact tree.
        nodes = tree.Children;

        if ~isempty(nodes)
            ids = string({nodes.NodeData});
            keep = ismember(ids,checked);

            if any(keep)
                tree.CheckedNodes = nodes(keep);
            end

            if preferredID == "__last__"
                selected = numel(nodes);
            else
                selected = find(ids == preferredID,1);
            end

            if isempty(selected)
                selected = 1;
            end

            tree.SelectedNodes = nodes(selected);
        end

        updateButtons();
    end

    function updateButtons()
        items = itemsFcn();
        id = selectedID();
        index = find(string({items.ID}) == id,1);
        selected = ~isempty(index);
        protected = selected && items(index).Protected;
        editButton.Enable = matlab.lang.OnOffSwitchState(selected);
        deleteButton.Enable = matlab.lang.OnOffSwitchState(selected && ~protected);
        upButton.Enable = matlab.lang.OnOffSwitchState( ...
            selected && ~protected && index > 1 && ~items(index-1).Protected);
        downButton.Enable = matlab.lang.OnOffSwitchState( ...
            selected && ~protected && index < numel(items));
        newButton.Enable = 'on';
    end
end
