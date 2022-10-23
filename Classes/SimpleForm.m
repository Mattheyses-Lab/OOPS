classdef SimpleForm < matlab.ui.componentcontainer.ComponentContainer
    % SimpleForm: list of custom editfields to be placed in a figure, will resize the 
    % figure according to number of user-specific params
    properties
        Params = {'Param 1'}
        BGColor = "Black"
        FontColor = "White"
        SaveStatus = "Cancel"
    end

    properties (Dependent = true)
        nParams
        FigInnerHeight
        Outputs
    end
    
    properties (Dependent = true)
        %
    end
    
    events (HasCallbackProperty, NotifyAccess = protected)
        %WindowClosing % WindowClosing callback property will be generated
        %nParamsChanged
    end
    
    properties (Access = private, Transient, NonCopyable)
        Grid matlab.ui.container.GridLayout
        EditFields matlab.ui.control.EditField
        EditFieldLabels matlab.ui.control.Label
        ButtonGrid matlab.ui.container.GridLayout
        DoneButton matlab.ui.control.Button
        CancelButton matlab.ui.control.Button
    end
    
    methods (Access=protected)
        function setup(obj)
            
            obj.Units = 'normalized';
            obj.Position = [0 0 1 1];
            obj.Grid = uigridlayout(obj,[obj.nParams+1 2]);

            for i = 1:obj.nParams
                obj.EditFieldLabels(i) = uilabel(obj.Grid,"Text",obj.Params{i});
                obj.EditFieldLabels(i).Layout.Row = i;
                obj.EditFieldLabels(i).Layout.Column = 1;

                obj.EditFields(i) = uieditfield(obj.Grid);
                obj.EditFields(i).Layout.Row = i;
                obj.EditFields(i).Layout.Column = 2;
            end

            obj.ButtonGrid = uigridlayout(obj.Grid,[1 2]);
            obj.ButtonGrid.Padding = [0 0 0 0];
            obj.ButtonGrid.RowHeight = 20;
            obj.ButtonGrid.ColumnWidth = {'1x','1x'};

            obj.CancelButton = uibutton(obj.ButtonGrid,...
                "ButtonPushedFcn",@(o,e) obj.Finish(o,e),...
                "Text","Cancel");
            obj.CancelButton.Layout.Row = 1;
            obj.CancelButton.Layout.Column = 1;

            obj.DoneButton = uibutton(obj.ButtonGrid,...
                "ButtonPushedFcn",@(o,e) obj.Finish(o,e),...
                "Text","Save");
            obj.DoneButton.Layout.Row = 1;
            obj.DoneButton.Layout.Column = 2;

        end
        
        function update(obj)

            obj.Grid.BackgroundColor = obj.BGColor;

            delete(obj.EditFieldLabels);
            delete(obj.EditFields);

            for i = 1:numel(obj.Params)
                obj.EditFieldLabels(i) = uilabel(obj.Grid,"Text",obj.Params{i});
                obj.EditFieldLabels(i).Layout.Row = i;
                obj.EditFieldLabels(i).Layout.Column = 1;
                obj.EditFieldLabels(i).FontColor = obj.FontColor;

                obj.EditFields(i) = uieditfield(obj.Grid);
                obj.EditFields(i).Layout.Row = i;
                obj.EditFields(i).Layout.Column = 2;

                obj.Grid.RowHeight{i} = 20;
            end

            obj.ButtonGrid.Layout.Row = obj.nParams+1;
            obj.ButtonGrid.Layout.Column = [1 2];
            obj.ButtonGrid.BackgroundColor = obj.BGColor;
            
            obj.Grid.RowHeight{obj.nParams+1} = 20;

            obj.Grid.ColumnWidth{1} = 'fit';

        end
        
    end
        
        methods

            function nParams = get.nParams(obj)
                nParams = numel(obj.Params);
            end

            function Outputs = get.Outputs(obj)
                Outputs = cell(obj.nParams,1);
                for i = 1:obj.nParams
                    Outputs{i} = obj.EditFields(i).Value;
                end
            end

            function FigInnerHeight = get.FigInnerHeight(obj)
                FigInnerHeight = 20*(obj.nParams+1)+10*(obj.nParams)+20;
            end

            function Finish(obj,source,~)
                obj.SaveStatus = source.Text;
                close(obj.Parent);
            end

            function delete(obj)
                delete(obj)
            end

        end



end