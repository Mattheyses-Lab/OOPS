classdef uiaccordion < matlab.ui.componentcontainer.ComponentContainer

    properties
        FontSize (1,1) double = 12
    end
    
    properties(SetAccess = private)
        Items (:,1) uiaccordionitem
    end
    
    properties(Dependent = true,SetAccess = private)
        nItems (1,1) double
        Contents (:,1)
    end
        
    properties(Access = private,Transient,NonCopyable)
        % outermost grid for the entire component
        containerGrid (1,1) matlab.ui.container.GridLayout
    end
    
    methods(Access = protected)
    
        function setup(obj)
            % grid layout manager to enclose all the components
            obj.containerGrid = uigridlayout(obj,...
                [1,1],...
                "ColumnWidth",{'1x'},...
                "RowHeight",{'fit'},...
                "RowSpacing",5,...
                "BackgroundColor",obj.BackgroundColor,...
                "Padding",[5 5 5 5],...
                "Scrollable","on");
        end
    
        function update(obj)
    
            obj.Items = obj.Items(isvalid(obj.Items));
    
            if obj.nItems==0
                obj.containerGrid.RowHeight = {'fit'};
            else
                % place items in the appropriate row of the grid
                for i = 1:obj.nItems
                    obj.Items(i).Layout.Row = i;
                    obj.Items(i).FontSize = obj.FontSize;
                    fontsize(obj.Items(i).Pane,obj.FontSize,"pixels");
                end
                % set the grid row heights
                obj.containerGrid.RowHeight = repmat({'fit'},1,obj.nItems);
            end
    
            obj.containerGrid.BackgroundColor = obj.BackgroundColor;
        end
    
    end
    
    methods
    
        function Contents = get.Contents(obj)
            Contents = cat(1,obj.Items(:).Contents);
        end
    
        function nItems = get.nItems(obj)
            nItems = numel(obj.Items);
        end
    
        function addItem(obj,Options)
            arguments
                obj (1,1) uiaccordion
                Options.FontSize (1,1) double = 12
                Options.FontName (1,:) char = 'Helvetica'
                Options.Title (1,:) char = 'Title'
                Options.TitleBackgroundColor (1,3) double = [0.95 0.95 0.95]
                Options.FontColor (1,3) double = [0 0 0]
                Options.PaneBackgroundColor (1,3) double = [1 1 1]
                Options.BorderColor (1,3) double = [0.7 0.7 0.7]
                Options.BorderWidth (1,1) = 1
                Options.ExpandedBorderWidth (1,1) = 1
            end
            names = fieldnames(Options).';
            values = cellfun(@(name) Options.(name),names,"UniformOutput",false);
            arguments = cat(1,names,values);
            obj.Items(end+1) = uiaccordionitem(obj.containerGrid,arguments{:});
        end
    
        function deleteItem(obj,idx)
            if idx > obj.nItems || idx < 1
                error('uiaccordion:invalidIndex',...
                    'idx must be a positive integer <= number of accordion items');
            else
                delete(obj.Items(idx));
                obj.update();
            end
        end
    
        function delete(obj)
            % delete the individual accordion items
            delete(obj.Items);
        end
    
    end

end