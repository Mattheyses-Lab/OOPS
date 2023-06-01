classdef uiaccordion < matlab.ui.componentcontainer.ComponentContainer

properties
    Pane (1,1) matlab.ui.container.GridLayout
    FontSize (1,1) double = 12
    FontName (1,:) char = 'Helvetica'
    expanded (1,1) logical = false
    Name (1,:) char = 'Item'
    ItemBackgroundColor (1,3) double = [0.9 0.9 0.9]
    ItemForegroundColor (1,3) double = [0 0 0]
    PaneBackgroundColor (1,3) double = [1 1 1]
    BorderType (1,:) char {mustBeMember(BorderType,{'line','none'})} = 'none'
    BorderColor (1,3) double = [0 0 0]
    BorderWidth (1,1) = 1
end

properties(Dependent = true)
    nodeSize (1,1) double
    nodeSizeWithBorders (1,1) double
end

% properties hidden from the user, used for set/get methods for rLim
properties(Access = private)

end
    
properties(Access = private,Transient,NonCopyable)
    % outermost grid for the entire component
    containerGrid (1,1) matlab.ui.container.GridLayout
    % panel to enclose the all the components
    enclosingPanel (1,1) matlab.ui.container.Panel
    % grid layout manager to fill the panel 
    mainGrid (1,1) matlab.ui.container.GridLayout
    % uigridlayout visible when the item is collapsed
    collapsedGrid (1,1) matlab.ui.container.GridLayout
    % uipanel to contain the accordion item in the collapsed state
    itemPanel (1,1) matlab.ui.container.Panel
    % uigridlayout to hold the components within the itemPanel
    itemPanelGrid (1,1) matlab.ui.container.GridLayout
    % uilabel to show the item name
    itemLabel (1,1) matlab.ui.control.Label
    % uibutton to expand/collapse this accordion
    accordionButton (1,1) matlab.ui.control.Button
    % uipanel to hold the accordion pane
    panePanel (1,1) matlab.ui.container.Panel
    % uigridlayout visible when the item is expanded
    expandedGrid (1,1) matlab.ui.container.GridLayout
end

methods(Access = protected)
    function setup(obj)
        % grid layout manager to hold the panel
        obj.containerGrid = uigridlayout(obj,...
            [1,1],...
            "ColumnWidth",{'1x'},...
            "RowHeight",{'fit'},...
            "BackgroundColor",obj.ItemBackgroundColor,...
            "Padding",[0 0 0 0]);

        obj.enclosingPanel = uipanel(obj.containerGrid,...
            "BorderType",obj.BorderType,...
            "BorderColor",obj.BorderColor,...
            "BorderWidth",obj.BorderWidth);

        % grid layout manager to hold the components within the panel
        obj.mainGrid = uigridlayout(obj.enclosingPanel,...
            [1,1],...
            "ColumnWidth",{'1x'},...
            "RowHeight",{obj.nodeSizeWithBorders},...
            "Padding",[0 0 0 0],...
            "BackgroundColor",obj.ItemBackgroundColor);
        % grid layout manager to hold the accordion node when it is collapsed
        obj.collapsedGrid = uigridlayout(obj.mainGrid,...
            [1,1],...
            "ColumnWidth",{'1x'},...
            "RowHeight",{'fit'},...
            "Padding",[0 0 0 0],...
            "BackgroundColor",obj.ItemBackgroundColor);
        obj.collapsedGrid.Layout.Row = 1;



        % panel to hold this accordion item
        obj.itemPanel = uipanel(obj.collapsedGrid,...
            "BackgroundColor",obj.ItemBackgroundColor,...
            "BorderType",obj.BorderType,...
            "BorderColor",obj.BorderColor,...
            "BorderWidth",obj.BorderWidth);
        % grid within the node panel
        obj.itemPanelGrid = uigridlayout(obj.itemPanel,...
            [1,2],...
            "ColumnWidth",{obj.nodeSize,'fit'},...
            "RowHeight",{obj.nodeSize},...
            "Padding",[1 1 1 1],...
            "BackgroundColor",obj.ItemBackgroundColor);
        % button to open/close the item
        obj.accordionButton = uibutton(obj.itemPanelGrid,...
            "BackgroundColor",obj.ItemBackgroundColor,...
            "FontColor",[1 1 1],...
            "FontSize",obj.FontSize,...
            "Icon","AccordionCollapsedIcon.png",...
            "IconAlignment","center",...
            "ButtonPushedFcn",@(o,e) obj.componentNodeClicked(o,e),...
            "Text",'');
        obj.accordionButton.Layout.Column = 1;
        obj.accordionButton.Layout.Row = 1;
        % label to display item name
        obj.itemLabel = uilabel(obj.itemPanelGrid,...
            "BackgroundColor",obj.ItemBackgroundColor,...
            "FontColor",obj.ItemForegroundColor,...
            "FontSize",obj.FontSize,...
            "Text","Item");
        obj.itemLabel.Layout.Column = 2;
        obj.itemLabel.Layout.Row = 1;
        % grid layout manager to hold the accordion item (when expanded) and its Pane
        obj.expandedGrid = uigridlayout(obj.mainGrid,[2,1],...
            "RowHeight",{obj.nodeSizeWithBorders,'fit'},...
            "RowSpacing",0,...
            "Visible","off",...
            "Padding",[0 0 0 0],...
            "BackgroundColor",obj.PaneBackgroundColor);
        obj.expandedGrid.Layout.Row = 1;
        % uipanel to hold the Pane
        obj.panePanel = uipanel(obj.expandedGrid,...
            "BackgroundColor",obj.PaneBackgroundColor,...
            "BorderType",obj.BorderType,...
            "BorderColor",obj.BorderColor,...
            "BorderWidth",obj.BorderWidth);
        obj.panePanel.Layout.Row = 2;
        % grid layout manager to act as the Pane for this accordion item - holds user-specified components
        obj.Pane = uigridlayout(obj.panePanel,[1,1],...
            "BackgroundColor",obj.PaneBackgroundColor,...
            "Padding",[5 5 5 5]);
    end

    function update(obj)
        % update font size of the accordion item title
        obj.accordionButton.FontSize = obj.FontSize;
        obj.itemLabel.FontSize = obj.FontSize;

        % set row heights in the grid layout managers
        if obj.expanded
            obj.mainGrid.RowHeight{1} = 'fit';
            obj.itemLabel.FontWeight = 'bold';
        else
            obj.mainGrid.RowHeight{1} = obj.nodeSizeWithBorders;
            obj.itemLabel.FontWeight = 'normal';
        end
        obj.collapsedGrid.RowHeight{1} = 'fit';
        obj.expandedGrid.RowHeight{1} = obj.nodeSizeWithBorders;

        % update the item name label
        obj.itemLabel.Text = obj.Name;
        obj.itemLabel.FontColor = obj.ItemForegroundColor;
        obj.itemLabel.BackgroundColor = obj.ItemBackgroundColor;

        % update the name panel and grid
        obj.itemPanel.BackgroundColor = obj.ItemBackgroundColor;
        obj.itemPanelGrid.BackgroundColor = obj.ItemBackgroundColor;
        % update font name of the accordion item
        obj.accordionButton.FontName = obj.FontName;
    end
end

methods

    function nodeSize = get.nodeSize(obj)
        nodeSize = obj.FontSize + 6;
    end

    function nodeSizeWithBorders = get.nodeSizeWithBorders(obj)
        switch obj.BorderType
            case 'line'
                nodeSizeWithBorders = obj.nodeSize + obj.BorderWidth*2 + 2;
            case 'none'
                nodeSizeWithBorders = obj.nodeSize + 2;
        end
    end

    % "open" this accordion item
    function expand(obj)
        obj.accordionButton.Icon = "AccordionExpandedIcon.png";
        obj.itemPanel.Parent = obj.expandedGrid;
        obj.expandedGrid.Visible = 'on';
        obj.collapsedGrid.Visible = 'off';
        obj.mainGrid.RowHeight{1} = 'fit';
        obj.expanded = true;
    end

    % "close" this accordion item
    function collapse(obj)
        obj.accordionButton.Icon = "AccordionCollapsedIcon.png";
        obj.itemPanel.Parent = obj.collapsedGrid;
        obj.collapsedGrid.Visible = 'on';
        obj.expandedGrid.Visible = 'off';
        obj.mainGrid.RowHeight{1} = obj.nodeSize;
        obj.expanded = false;
    end

end

methods(Access=private)

    %% callbacks

    function componentNodeClicked(obj,~,~)
        % if expanded
        if obj.expanded
            obj.collapse(); % then collapse
        else
            obj.expand(); % otherwise expand
        end
    end

end

end