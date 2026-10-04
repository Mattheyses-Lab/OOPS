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

classdef Accordion < matlab.ui.componentcontainer.ComponentContainer
% custom class for expandable accordion container with scrollable content
% Notes:
%   for most predictable behavior, the accordion should be 
%   placed in its own 1x1 uigridlayout() container with 
%   RowHeight={'fit'} and ColumnWidth={'1x'} 

    properties
        ItemSpacing (1,1) double = 5;
        BorderWidth (1,1) double = 1;
        MatchFontSizes (1,1) logical = true
        Padding (1,1) double = 5;
        BorderColor (1,3) double = [0.7 0.7 0.7];
    end
    
    %% Items/Item management
    properties(SetAccess = private)
        Items (:,1) matlabx.ui.container.AccordionItem

        % track item IDs in parallel with Item handles
        ItemIDs (1,:) string = string.empty(1,0)

        % ID of the item being hovered on, empty string if none
        HoverID (1,:) string = string.empty(1,0)
    end

    properties(Access=private)
        % dictionary to access items by name
        ItemsDict dictionary = dictionary(string.empty(1,0), matlabx.ui.container.AccordionItem.empty(1,0))
    end
    
    %% Derived properties
    properties(Dependent,Access=private)
        ParentFig
    end

    properties(Dependent = true,SetAccess = private)
        nItems (1,1) double
        Contents (:,1)
        ItemPadding (1,4) double
        BorderPadding (1,4) double
    end
        
    %% Private UI/graphics
    properties(Access = private,Transient,NonCopyable)
        % outermost grid for the entire component
        containerGrid (1,1) matlab.ui.container.GridLayout
        % second grid layout manager to hold each accordion item
        itemGrid (1,1) matlab.ui.container.GridLayout
    end

    %% Hub registration
    properties (Access=private)
        Hub matlabx.ui.interaction.FigureEventHub
        RouterId double = NaN
    end

    %% ComponentContainer lifecycle
    methods(Access = protected)
    
        function setup(obj)
            % grid layout manager to enclose all the components
            obj.containerGrid = uigridlayout(obj,...
                [1,1],...
                "ColumnWidth",{'1x'},...
                "RowHeight",{'fit'},...
                "RowSpacing",obj.ItemSpacing,...
                "BackgroundColor",obj.BorderColor,...
                "Padding",obj.BorderPadding,...
                "Scrollable","on");
            % second grid layout manager to hold each accordion item
            obj.itemGrid = uigridlayout(obj.containerGrid,...
                [1,1],...
                "ColumnWidth",{'1x'},...
                "RowHeight",{'fit'},...
                "RowSpacing",obj.ItemSpacing,...
                "BackgroundColor",obj.BackgroundColor,...
                "Padding",obj.ItemPadding,...
                "Scrollable","on");
            % Hub registration (one hub per figure; this instance registers itself)
            obj.Hub = matlabx.ui.interaction.FigureEventHub.ensure(obj.ParentFig);
            obj.RouterId = obj.Hub.register(obj, ...
                'Priority', 10, ...
                'CaptureDuringDrag', false);
        end
    
        function update(obj)
            obj.Items = obj.Items(isvalid(obj.Items));
    
            if obj.nItems==0
                obj.itemGrid.RowHeight = {'fit'};
            else
                % place items in the appropriate row of the grid
                for i = 1:obj.nItems
                    obj.Items(i).Layout.Row = i;
                end
                % set the grid row heights
                obj.itemGrid.RowHeight = repmat({'fit'},1,obj.nItems);
            end
    
            set(obj.itemGrid,...
                'BackgroundColor',obj.BackgroundColor,...
                'RowSpacing',obj.ItemSpacing,...
                'Padding',obj.ItemPadding);

            set(obj.containerGrid,...
                'BackgroundColor',obj.BorderColor,...
                'Padding',obj.BorderPadding);
        end
    
    end
    

    %% Hub-facing event handlers (matches / onDown / onMove / onUp / onScroll / onEnter / onLeave) (and helpers)
    methods

        % determine whether this instance should claim event from FigureEventHub
        function tf = matches(~,E)
            % tf = matches(obj, tgt, kind, evt)
            % obj: this component
            % tgt: hittest result from FigureEventHub that we are checking for a match to this component
            % kind: the specific kind of mouse event (i.e. 'move', 'down', 'up', or 'scroll')
            % evt: event data associated with the event

            % only return true if target Tag='TitleBar'
            tf = isprop(E.Target,'Tag') && strcmp(E.Target.Tag,'TitleBar');
        end

        function onDown(obj,E)
            ID = obj.getTargetID(E.Target);
            item = obj.Items(obj.idxOfID(ID));
            % flip expanded state when title bar is clicked
            if item.expanded
                item.collapse();
            else
                item.expand();
            end
        end

        function onMove(obj,E)
            ID = obj.getTargetID(E.Target);
            obj.updateHover(obj.idxOfID(ID));
        end

        % No-ops so FigureEventHub doesn't error
        function onUp(~, ~),        end
        function onScroll(~, ~),    end
        function onKeyPress(~, ~),       end
        function onKeyRelease(~, ~),     end
        
        function onEnter(obj,E)
            ID = obj.getTargetID(E.Target);
            obj.updateHover(obj.idxOfID(ID));
        end

        function onLeave(obj,~), obj.updateHover([]); end

        function updateHover(obj,idx)
            % transfers hover mode to item specified by hoverIdx

            hoverStatus = [obj.Items(:).Hover];
            hoverIdx = find(hoverStatus);

            % turn off any existing hover (unless it is the Item that should be hovered)
            if ~isempty(hoverIdx)

                for i = 1:numel(hoverIdx)
                    if hoverIdx(i) ~= idx
                        obj.Items(hoverIdx(i)).Hover = false;
                    end
                end

            end

            if ~isempty(idx)
                obj.Items(idx).Hover = true;
            else
                set(obj.Items(:),'Hover',false);
            end
        end

    end


    %% Derived getters
    methods
    
        function Contents = get.Contents(obj)
            Contents = cat(1,obj.Items(:).Contents);
        end
    
        function nItems = get.nItems(obj)
            nItems = numel(obj.Items);
        end

        function ItemPadding = get.ItemPadding(obj)
            ItemPadding = repmat(obj.Padding,1,4);
        end

        function BorderPadding = get.BorderPadding(obj)
            BorderPadding = repmat(obj.BorderWidth,1,4);
        end

        function f = get.ParentFig(obj),   f = ancestor(obj,'Figure'); end

    end

    %% Item management
    methods

        function addItem(obj,Options)
            arguments
                obj (1,1) matlabx.ui.container.Accordion
                Options.TitleFontSize (1,1) double = 12
                Options.ContentFontSize (1,1) double = 12
                Options.MatchPaneFontSizes (1,1) logical = true
                Options.FontName (1,:) char = 'Helvetica'
                %Options.Title (1,:) char = 'Title'
                Options.Title (1,:) string = strings(1,0)
                Options.TitleBackgroundColor (1,3) double = [0.95 0.95 0.95]
                Options.HoverTitleBackgroundColor (1,3) double = [1 1 1]
                Options.TitlePadding (1,1) double = 1
                Options.FontColor (1,3) double = [0 0 0]
                Options.PaneBackgroundColor (1,3) double = [1 1 1]
                Options.BorderColor (1,3) double = [0.7 0.7 0.7]
                Options.BorderWidth (1,1) double = 1
                Options.ExpandedBorderWidth (1,1) double = 1
            end

            % duplicate Title -> error
            if obj.hasItem(Options.Title)
                error('matlabx:ui:uiacordion:InvalidTitle','An item already exists with the title: %s',Options.Title)
            end

            % Title empty -> create unique
            if isempty(Options.Title)
                Options.Title = obj.getUniqueTitle();
            end


            names = fieldnames(Options).';
            values = cellfun(@(name) Options.(name),names,"UniformOutput",false);
            arguments = cat(1,names,values);

            newItem = matlabx.ui.container.AccordionItem(obj.itemGrid,arguments{:});

            obj.Items(end+1) = newItem;
            obj.ItemIDs(end+1) = newItem.ID;
            % add to dictionary
            obj.ItemsDict(newItem.Title) = newItem;
        end
    
        function deleteItem(obj,titleOrIdx)
            % if titleOrIdx > obj.nItems || titleOrIdx < 1
            %     error('Accordion:InvalidIndex',...
            %         'idx must be a positive integer <= number of accordion items');
            % else
            %     delete(obj.Items(titleOrIdx));
            %     obj.ItemIDs(titleOrIdx) = [];
            %     obj.update();
            % end

            if ischar(titleOrIdx) || isstring(titleOrIdx)
                titleOrIdx = string(titleOrIdx);
                itemToDelete = obj.getItem(titleOrIdx);
                if isempty(itemToDelete)
                    return
                end

                idx = obj.idxOfID(itemToDelete.ID);
            else
                if titleOrIdx > obj.nItems || titleOrIdx < 1
                    error('Accordion:InvalidIndex',...
                        'idx must be a positive integer <= number of accordion items');
                end

                idx = titleOrIdx;
                itemToDelete = obj.Items(idx);
            end

            % remove from dict
            obj.removeItemFromDict(itemToDelete.Title);
            % delete it
            delete(obj.Items(idx))
            % remove its UUID
            obj.ItemIDs(titleOrIdx) = [];
            % update
            obj.update();
        end

    end

    %% Item management

    methods

        function tf = hasItem(obj,name)
            tf = isKey(obj.ItemsDict,name);
        end


        function item = getItem(obj,name)
            if obj.hasItem(name)
                item = obj.ItemsDict(name);
            else
                item = [];
            end
        end

    end

    %% Private helpers

    methods(Access=private)

        function idx = idxOfID(obj, ID)
            % find idx of Item using its UUID
            idx = find(obj.ItemIDs == string(ID), 1, 'first');
        end

        function ID = getTargetID(~,tgt)
            if isprop(tgt,'UUID')
                ID = tgt.UUID;
            else
                ID = [];
            end
        end

        function str = getUniqueTitle(obj)
            str = "Item 1";
            ctr = 2;
            while obj.hasItem(str)
                str = sprintf("Item %i",ctr);
                ctr = ctr+1;
            end
        end

        function removeItemFromDict(obj,name)
            % remove the dict entry for the item specified by name
            if obj.hasItem(name)
                remove(obj.ItemsDict,name)
            end
        end


    end

    %% Teardown
    methods

        function delete(obj)
            % Unregister from hub (safe if figure already gone)
            try
                if ~isempty(obj.Hub) && isvalid(obj.Hub) && ~isnan(obj.RouterId)
                    obj.Hub.unregister(obj.RouterId);
                end
            catch ME
                warning('Failed to unregister from FigureEventHub...')
                disp(ME.getReport);
            end

            % delete the individual accordion items
            delete(obj.Items);
        end

    end

end
