% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

classdef AccordionItem < matlab.ui.componentcontainer.ComponentContainer

properties
    % text displayed in the title
    % Title (1,:) char = 'Title'
    Title (1,1) string

    % expand/collapse indicator icons
    expandedIconLight (1,:) char = matlabx.internal.Paths.icons('CollapseWhiteIcon.png')
    collapsedIconLight (1,:) char = matlabx.internal.Paths.icons('ExpandWhiteIcon.png')
    expandedIconDark (1,:) char = matlabx.internal.Paths.icons('CollapseIcon.png')
    collapsedIconDark (1,:) char = matlabx.internal.Paths.icons('ExpandIcon.png')
end

%% Fonts
properties(AbortSet,SetObservable=true)
    % font size of the title label
    TitleFontSize (1,1) double = 12
    % font size of objects placed in the pane
    ContentFontSize (1,1) double = 12
    % whether to use ContentFontSize when the component updates, disable to use manual font sizes
    MatchPaneFontSizes (1,1) logical = true
    % name of the font used for the title
    FontName (1,:) char = 'Helvetica'
end

%% Colors
properties(AbortSet,SetObservable=true)
    TitleBackgroundColor (1,3) double = [0.95 0.95 0.95]
    HoverTitleBackgroundColor (1,3) double = [1 1 1]
    FontColor (1,3) double = [0 0 0]
    PaneBackgroundColor (1,3) double = [1 1 1]
    BorderColor (1,3) double = [0.7 0.7 0.7]
end

%% Sizing and spacing
properties(AbortSet,SetObservable=true)
    % width of the border around the Item when collapsed
    BorderWidth (1,1) = 1
    % width of the border around the item when expanded
    ExpandedBorderWidth (1,1) = 1
    % padding above and below title
    TitlePadding (1,1) double = 3
end

%% Private ID/meta
properties(SetAccess=private)
    ID (1,:) string = string.empty(1,0)
end

properties(SetAccess=private)
    Pane (1,1) matlab.ui.container.GridLayout
end

% modes
properties(AbortSet,SetObservable=true)
    expanded (1,1) logical = false
    Hover (1,1) logical = false
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
    % uigridlayout to hold the components within the itemPanel
    itemGrid (1,1) matlab.ui.container.GridLayout
    % uilabel to show the item name
    itemLabel (1,1) matlab.ui.control.Label
    % icon in the title bar to show expanded/collapsed status
    titleIcon (1,1) matlab.ui.control.Image
    % uigridlayout visible when the item is expanded
    expandedGrid (1,1) matlab.ui.container.GridLayout

    % dynamic properties
    P (:,1) matlab.metadata.DynamicProperty
    % property listeners
    L event.listener

    % flag for coalescing updates
    pendingUpdate logical = false
end

%% ComponentContainer lifecycle
methods(Access=protected)

    function setup(obj)

        % create unique ID
        obj.ID = string(char(java.util.UUID.randomUUID()));

        % grid layout manager to hold the panel
        obj.containerGrid = uigridlayout(obj,...
            [1,1],...
            "ColumnWidth",{'1x'},...
            "RowHeight",{'fit'},...
            "BackgroundColor",obj.TitleBackgroundColor,...
            "Padding",[0 0 0 0],...
            "Tag","ContainerGrid");

        % grid layout manager to hold the components within the panel
        obj.mainGrid = uigridlayout(obj.containerGrid,...
            [1,1],...
            "ColumnWidth",{'1x'},...
            "RowHeight",{obj.nodeSizeWithBorders},...
            "Padding",[0 0 0 0],...
            "BackgroundColor",obj.TitleBackgroundColor,...
            "Tag","MainGrid");

        % grid layout manager to hold the accordion item (when expanded) and its Pane
        obj.expandedGrid = uigridlayout(obj.mainGrid,[2,1],...
            "RowHeight",{'fit','fit'},...
            "ColumnWidth",{'1x'},...
            "RowSpacing",obj.BorderWidth,...
            "Visible","on",...
            "Padding",repmat(obj.BorderWidth,1,4),...
            "BackgroundColor",obj.BorderColor,...
            "Tag","ExpandedGrid");
        obj.expandedGrid.Layout.Row = 1;

        % grid within the node panel
        obj.itemGrid = uigridlayout(obj.expandedGrid,...
            [1,2],...
            "ColumnWidth",{obj.nodeSize,'fit'},...
            "RowHeight",{obj.nodeSize},...
            "Padding",[1 1 1 1],...
            "ColumnSpacing",5,...
            "BackgroundColor",obj.TitleBackgroundColor,...
            "Tag","TitleBar");
        obj.itemGrid.Layout.Row = 1;

        % button to open/close the item
        obj.titleIcon = uiimage(obj.itemGrid,...
            "BackgroundColor","none",...
            "ImageSource",matlabx.internal.Paths.icons('ExpandIcon.png'),...
            "Tag","TitleBar",...
            "UserData",obj.ID);
        obj.titleIcon.Layout.Column = 1;
        obj.titleIcon.Layout.Row = 1;

        % label to display item name
        obj.itemLabel = uilabel(obj.itemGrid,...
            "BackgroundColor",obj.TitleBackgroundColor,...
            "FontColor",obj.FontColor,...
            "FontSize",obj.TitleFontSize,...
            "VerticalAlignment","center",...
            "Text","Item",...
            "Tag","TitleBar");
        obj.itemLabel.Layout.Column = 2;
        obj.itemLabel.Layout.Row = 1;

        % grid layout manager to act as the Pane for this accordion item - holds user-specified components
        obj.Pane = uigridlayout(obj.expandedGrid,[1,1],...
            "BackgroundColor",obj.PaneBackgroundColor,...
            "Padding",[5 5 5 5],...
            "Tag","PaneGrid");
        obj.Pane.Layout.Row = 2;

        % add UUID property to title bar components for tracking ownership
        obj.P(1) = addprop(obj.itemGrid,'UUID');
        obj.P(2) = addprop(obj.itemLabel,'UUID');
        obj.P(3) = addprop(obj.titleIcon,'UUID');
        set([obj.itemGrid,obj.itemLabel,obj.titleIcon],'UUID',obj.ID);

        % set up listener for properties controlling item sizing/spacing
        obj.L = addlistener(obj, {'BorderWidth','ExpandedBorderWidth','TitlePadding','TitleFontSize'}, ...
            'PostSet', @(~,~) obj.queueSizingUpdate());

        % set up listener for properties controlling component colors
        obj.L(2) = addlistener(obj, ...
            {'TitleBackgroundColor',...
            'HoverTitleBackgroundColor',...
            'FontColor',...
            'PaneBackgroundColor',...
            'BorderColor'}, ...
            'PostSet', @(~,~) obj.updateColors());

        % set up listener for properties controlling font appearance
        obj.L(3) = addlistener(obj, ...
            {'ContentFontSize',...
            'MatchPaneFontSizes',...
            'TitleFontSize',...
            'FontName'}, ...
            'PostSet', @(~,~) obj.updateFonts());

        % set up listener for Hover status
        obj.L(4) = addlistener(obj, 'Hover', ...
            'PostSet', @(~,~) obj.updateOnHover());

        % set up listener for expanded status
        obj.L(5) = addlistener(obj, 'expanded', ...
            'PostSet', @(~,~) obj.updateOnExpand());

    end

    function update(obj)
        % update the item title label
        obj.itemLabel.Text = obj.Title;
    end

end

%% Update helper methods
methods (Access=private)
    function queueSizingUpdate(obj)
        if obj.pendingUpdate
            return
        end
        obj.pendingUpdate = true;
        % coalesce updates
        drawnow limitrate nocallbacks
        obj.updateSizing();
        obj.pendingUpdate = false;
    end

    function updateSizing(obj)
        % update itemGrid RowHeight, ColumnWidth, and Padding
        obj.itemGrid.RowHeight = obj.nodeSize;
        obj.itemGrid.ColumnWidth{1} = obj.TitleFontSize;
        obj.itemGrid.Padding = [obj.TitlePadding+5,obj.TitlePadding,1,obj.TitlePadding];
        % set grid padding and row spacing to simulate borders
        obj.expandedGrid.RowSpacing = obj.ExpandedBorderWidth;
        % update components whose size depend on whether the item is expanded
        obj.updateOnExpand();
    end

    function updateColors(obj)
        % update the background color of the Pane
        obj.Pane.BackgroundColor = obj.PaneBackgroundColor;
        % update border colors
        obj.expandedGrid.BackgroundColor = obj.BorderColor;
        % update item label colors
        obj.itemLabel.FontColor = obj.FontColor;
        % update titleIcon images
        obj.titleIcon.ImageSource = obj.buttonIcon;
        % update itemGrid BackgroundColor
        obj.updateOnHover();
    end

    function updateFonts(obj)
        if obj.MatchPaneFontSizes
            % update font sizes of objects in the Pane
            fontsize(obj.Pane,obj.ContentFontSize,"pixels");
        end
        % update item label fonts
        obj.itemLabel.FontSize = obj.TitleFontSize;
        obj.itemLabel.FontName = obj.FontName;
    end

    function updateOnHover(obj)
        % update the BackgroundColor of specific components based on Hover status
        if obj.Hover
            obj.itemGrid.BackgroundColor = obj.HoverTitleBackgroundColor;
            obj.itemLabel.BackgroundColor = obj.HoverTitleBackgroundColor;
        else
            obj.itemGrid.BackgroundColor = obj.TitleBackgroundColor;
            obj.itemLabel.BackgroundColor = obj.TitleBackgroundColor;
        end
    end

    function updateOnExpand(obj)
        switch obj.expanded
            case true
                obj.mainGrid.RowHeight{1} = 'fit';
                obj.itemLabel.FontWeight = 'bold';
                obj.expandedGrid.Padding = obj.expandedGridPadding;
                obj.titleIcon.ImageSource = obj.buttonIcon;
                obj.Pane.Visible = 'on';
            case false
                obj.mainGrid.RowHeight{1} = obj.nodeSizeWithBorders;
                obj.itemLabel.FontWeight = 'normal';
                obj.expandedGrid.Padding = obj.gridPadding;
                obj.titleIcon.ImageSource = obj.buttonIcon;
                obj.Pane.Visible = 'off';
        end
    end

end


%% Helper methods (expand/collapse/hover/etc.)
methods

    % "open" this accordion item
    function expand(obj)
        % already expanded -> return
        if obj.expanded, return; end
        % expand it
        obj.expanded = true;
    end

    % "close" this accordion item
    function collapse(obj)
        % already collapsed -> return
        if ~obj.expanded, return; end
        % collapse it
        obj.expanded = false;
    end

end

%% Derived getters
methods

    function Contents = get.Contents(obj)
        Contents = obj.Pane.Children();
    end

    function buttonIcon = get.buttonIcon(obj)
        if isequal(matlabx.colors.ops.getBWContrastColor(obj.TitleBackgroundColor),[0 0 0])
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
        nodeSize = obj.TitleFontSize + 6;
    end

    function nodeSizeWithBorders = get.nodeSizeWithBorders(obj)
        nodeSizeWithBorders = obj.nodeSize + obj.BorderWidth*2 + obj.TitlePadding*2;
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

methods(Access=?matlabx.ui.container.Accordion)

    function delete(~), end

end

end