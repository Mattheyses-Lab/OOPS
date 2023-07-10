classdef uiaccordionitem < matlab.ui.componentcontainer.ComponentContainer

properties
    FontSize (1,1) double = 12
    FontName (1,:) char = 'Helvetica'
    Title (1,:) char = 'Title'
    TitleBackgroundColor (1,3) double = [0.95 0.95 0.95]
    FontColor (1,3) double = [0 0 0]
    PaneBackgroundColor (1,3) double = [1 1 1]
    BorderColor (1,3) double = [0.7 0.7 0.7]
    BorderWidth (1,1) = 1
    ExpandedBorderWidth (1,1) = 1
    expandedIconLight (1,:) char = "AccordionExpandedIconWhite.png"
    collapsedIconLight (1,:) char = "AccordionCollapsedIconWhite.png"
    expandedIconDark (1,:) char = "AccordionExpandedIcon.png"
    collapsedIconDark (1,:) char = "AccordionCollapsedIcon.png"
end

properties(SetAccess=private)
    Pane (1,1) matlab.ui.container.GridLayout
    expanded (1,1) logical = false
end

properties(Dependent=true,SetAccess=private)
    nodeSize (1,1) double
    nodeSizeWithBorders (1,1) double
    gridPadding (1,4) double
    expandedGridPadding (1,4) double
    paneIsEmpty (1,1) logical
    buttonIcon (1,:) char
    Contents (:,1)
end
    
properties(Access=private,Transient,NonCopyable)
    % outermost grid for the entire component
    containerGrid (1,1) matlab.ui.container.GridLayout
    % grid layout manager to fill the panel 
    mainGrid (1,1) matlab.ui.container.GridLayout
    % uigridlayout visible when the item is collapsed
    collapsedGrid (1,1) matlab.ui.container.GridLayout
    % uigridlayout to hold the components within the itemPanel
    itemGrid (1,1) matlab.ui.container.GridLayout
    % uilabel to show the item name
    itemLabel (1,1) matlab.ui.control.Label
    % uibutton to expand/collapse this accordion
    accordionButton (1,1) matlab.ui.control.Button
    % uigridlayout visible when the item is expanded
    expandedGrid (1,1) matlab.ui.container.GridLayout
end

methods(Access=protected)
    function setup(obj)
        % grid layout manager to hold the panel
        obj.containerGrid = uigridlayout(obj,...
            [1,1],...
            "ColumnWidth",{'1x'},...
            "RowHeight",{'fit'},...
            "BackgroundColor",obj.TitleBackgroundColor,...
            "Padding",[0 0 0 0]);

        % grid layout manager to hold the components within the panel
        obj.mainGrid = uigridlayout(obj.containerGrid,...
            [1,1],...
            "ColumnWidth",{'1x'},...
            "RowHeight",{obj.nodeSizeWithBorders},...
            "Padding",[0 0 0 0],...
            "BackgroundColor",obj.TitleBackgroundColor);
        % grid layout manager to hold the accordion node when it is collapsed
        obj.collapsedGrid = uigridlayout(obj.mainGrid,...
            [1,1],...
            "ColumnWidth",{'1x'},...
            "RowHeight",{'fit'},...
            "Padding",repmat(obj.BorderWidth,1,4),...
            "BackgroundColor",obj.BorderColor);
        obj.collapsedGrid.Layout.Row = 1;


        % grid within the node panel
        obj.itemGrid = uigridlayout(obj.collapsedGrid,...
            [1,2],...
            "ColumnWidth",{obj.nodeSize,'fit'},...
            "RowHeight",{obj.nodeSize},...
            "Padding",[1 1 1 1],...
            "BackgroundColor",obj.TitleBackgroundColor);
        % button to open/close the item
        obj.accordionButton = uibutton(obj.itemGrid,...
            "BackgroundColor",obj.TitleBackgroundColor,...
            "FontColor",[1 1 1],...
            "FontSize",obj.FontSize,...
            "Icon","AccordionCollapsedIcon.png",...
            "IconAlignment","center",...
            "ButtonPushedFcn",@(o,e) obj.componentNodeClicked(o,e),...
            "Text",'');
        obj.accordionButton.Layout.Column = 1;
        obj.accordionButton.Layout.Row = 1;
        % label to display item name
        obj.itemLabel = uilabel(obj.itemGrid,...
            "BackgroundColor",obj.TitleBackgroundColor,...
            "FontColor",obj.FontColor,...
            "FontSize",obj.FontSize,...
            "Text","Item");
        obj.itemLabel.Layout.Column = 2;
        obj.itemLabel.Layout.Row = 1;

        % grid layout manager to hold the accordion item (when expanded) and its Pane
        obj.expandedGrid = uigridlayout(obj.mainGrid,[2,1],...
            "RowHeight",{obj.nodeSizeWithBorders,'fit'},...
            "ColumnWidth",{'1x'},...
            "RowSpacing",obj.BorderWidth,...
            "Visible","off",...
            "Padding",repmat(obj.BorderWidth,1,4),...
            "BackgroundColor",obj.BorderColor);
        obj.expandedGrid.Layout.Row = 1;
        % grid layout manager to act as the Pane for this accordion item - holds user-specified components
        obj.Pane = uigridlayout(obj.expandedGrid,[1,1],...
            "BackgroundColor",obj.PaneBackgroundColor,...
            "Padding",[5 5 5 5]);
        obj.Pane.Layout.Row = 2;
    end

    function update(obj)
        % update expand/collapse button
        obj.accordionButton.BackgroundColor = obj.TitleBackgroundColor;
        % set row heights in the grid layout managers
        if obj.expanded
            obj.mainGrid.RowHeight{1} = 'fit';
            obj.itemLabel.FontWeight = 'bold';
            obj.expandedGrid.Padding = obj.expandedGridPadding;
            obj.accordionButton.Icon = obj.buttonIcon;
            obj.itemGrid.Parent = obj.expandedGrid;
            obj.expandedGrid.Visible = 'on';
            obj.collapsedGrid.Visible = 'off';
        else
            obj.mainGrid.RowHeight{1} = obj.nodeSizeWithBorders;
            obj.itemLabel.FontWeight = 'normal';
            obj.expandedGrid.Padding = obj.gridPadding;
            obj.accordionButton.Icon = obj.buttonIcon;
            obj.itemGrid.Parent = obj.collapsedGrid;
            obj.collapsedGrid.Visible = 'on';
            obj.expandedGrid.Visible = 'off';
        end

        % update itemGrid row height and column 1 width to account for changing FontSize
        obj.itemGrid.RowHeight = obj.nodeSize;
        obj.itemGrid.ColumnWidth{1} = obj.nodeSize;

        % make sure collapsed and expanded grids are sized to fit components
        obj.collapsedGrid.RowHeight{1} = 'fit';
        obj.expandedGrid.RowHeight{1} = 'fit';
        % set grid padding and row spacing to simulate borders
        obj.collapsedGrid.Padding = obj.gridPadding;
        obj.expandedGrid.RowSpacing = obj.BorderWidth;
        % update the item name label
        obj.itemLabel.Text = obj.Title;
        obj.itemLabel.FontColor = obj.FontColor;
        obj.itemLabel.FontSize = obj.FontSize;
        obj.itemLabel.FontName = obj.FontName;
        obj.itemLabel.BackgroundColor = obj.TitleBackgroundColor;
        % update the background color of item grid
        obj.itemGrid.BackgroundColor = obj.TitleBackgroundColor;
        % update font name of the title
        obj.accordionButton.FontName = obj.FontName;
        % update the background color of the Pane
        obj.Pane.BackgroundColor = obj.PaneBackgroundColor;
        % update border colors
        obj.expandedGrid.BackgroundColor = obj.BorderColor;
        obj.collapsedGrid.BackgroundColor = obj.BorderColor;
    end
end

methods

    function Contents = get.Contents(obj)
        Contents = obj.Pane.Children();
    end

    function buttonIcon = get.buttonIcon(obj)
        if isequal(getBWContrastColor(obj.TitleBackgroundColor),[0 0 0])
            if obj.expanded
                buttonIcon = obj.expandedIconDark;
            else
                buttonIcon = obj.collapsedIconDark;
            end
        else
            if obj.expanded
                buttonIcon = obj.expandedIconLight;
            else
                buttonIcon = obj.collapsedIconLight;
            end
        end
    end

    function nodeSize = get.nodeSize(obj)
        nodeSize = obj.FontSize + 6;
    end

    function nodeSizeWithBorders = get.nodeSizeWithBorders(obj)
        nodeSizeWithBorders = obj.nodeSize + obj.BorderWidth*2 + 2;
    end

    function gridPadding = get.gridPadding(obj)
        gridPadding = repmat(obj.BorderWidth,1,4);
    end

    function expandedGridPadding = get.expandedGridPadding(obj)
        expandedGridPadding = repmat(obj.ExpandedBorderWidth,1,4);
    end

    function paneIsEmpty = get.paneIsEmpty(obj)
        paneIsEmpty = isempty(obj.Pane.Children);
    end

    % "open" this accordion item
    function expand(obj)
        obj.expanded = true;
    end

    % "close" this accordion item
    function collapse(obj)
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

methods(Access=?uiaccordion)

    function delete(obj)
        delete(obj)
    end

end

end