classdef SimpleForm < matlab.ui.componentcontainer.ComponentContainer
%%  SIMPLEFORM creates a simple form (list of editfields) to be placed in a figure
%
%   NOTES:
%       The easiest way to use this class is by calling the function SimpleFormFig(), which
%       will create the parent figure for you.
%
%   See also SimpleFormFig
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------


    properties
        Params = {'Param 1'}
        BGColor = "Black"
        FontColor = "White"
        SaveStatus = "Cancel"
    end

    properties(Dependent=true)
        nParams
        FigInnerHeight
        Outputs
    end
    
    properties(Access=private,Transient,NonCopyable)
        Grid matlab.ui.container.GridLayout
        EditFields matlab.ui.control.EditField
        EditFieldLabels matlab.ui.control.Label
        ButtonGrid matlab.ui.container.GridLayout
        DoneButton matlab.ui.control.Button
        CancelButton matlab.ui.control.Button
    end
    
    methods(Access=protected)
        function setup(obj)
            
            obj.Units = 'normalized';
            obj.Position = [0 0 1 1];
            obj.Grid = uigridlayout(obj,[obj.nParams+1 2],'RowHeight',[repmat({20},1,obj.nParams),{'fit'}],'ColumnWidth',{'fit','1x'});


            for i = 1:obj.nParams
                obj.EditFieldLabels(i) = uilabel(obj.Grid,"Text","placeholder");
                obj.EditFieldLabels(i).Layout.Row = i;
                obj.EditFieldLabels(i).Layout.Column = 1;
    
                obj.EditFields(i) = uieditfield(obj.Grid);
                obj.EditFields(i).Placeholder = "placeholder";
                obj.EditFields(i).Layout.Row = i;
                obj.EditFields(i).Layout.Column = 2;
            end


            obj.ButtonGrid = uigridlayout(obj.Grid,[2 3]);
            obj.ButtonGrid.Padding = [0 0 0 0];
            obj.ButtonGrid.RowHeight = [20,20];
            obj.ButtonGrid.ColumnWidth = {'1x','2x','1x'};

            obj.DoneButton = uibutton(obj.ButtonGrid,...
                "ButtonPushedFcn",@(o,e) obj.Finish(o,e),...
                "Text","Save");
            obj.DoneButton.Layout.Row = 1;
            obj.DoneButton.Layout.Column = 2;

            obj.CancelButton = uibutton(obj.ButtonGrid,...
                "ButtonPushedFcn",@(o,e) obj.Finish(o,e),...
                "Text","Cancel");
            obj.CancelButton.Layout.Row = 2;
            obj.CancelButton.Layout.Column = 2;

        end
        
        function update(obj)

            try

                obj.EditFields = obj.EditFields(isvalid(obj.EditFields));
                obj.EditFieldLabels = obj.EditFieldLabels(isvalid(obj.EditFieldLabels));
    
                n_Params = obj.nParams;
                n_EditFields = numel(obj.EditFields);
    
                obj.Grid.BackgroundColor = obj.BGColor;
    
    
                if n_EditFields < n_Params % need to make more edit fields
                    for i = n_EditFields+1:n_Params
                        obj.EditFieldLabels(i) = uilabel(obj.Grid);
                        obj.EditFields(i) = uieditfield(obj.Grid);
                    end
                elseif n_EditFields > n_Params % need to delete some edit fields
                    delete(obj.EditFields(n_Params+1:n_EditFields));
                    delete(obj.EditFieldLabels(n_Params+1:n_EditFields));
                end
    
                % update size of grid container
                obj.Grid.RowHeight = [repmat({20},1,obj.nParams),{'fit'}];
    
                for i = 1:obj.nParams
    
                    obj.EditFieldLabels(i).Layout.Row = i;
                    obj.EditFieldLabels(i).Layout.Column = 1;
    
                    obj.EditFields(i).Layout.Row = i;
                    obj.EditFields(i).Layout.Column = 2;
    
    
                    obj.EditFieldLabels(i).FontColor = obj.FontColor;
                    obj.EditFieldLabels(i).Text = obj.Params{i};
    
                    obj.EditFields(i).Placeholder = obj.Params{i};
                end
    
                obj.ButtonGrid.Layout.Row = obj.nParams+1;
                obj.ButtonGrid.Layout.Column = [1 2];
                obj.ButtonGrid.BackgroundColor = obj.BGColor;
                
                obj.Grid.ColumnWidth = {'fit','1x'};

                % reorder the children so that pressing tab functions as expected
                obj.Grid.Children = [obj.EditFields,obj.EditFieldLabels,obj.ButtonGrid];

            catch ME
                disp(ME.getReport)
            end

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
                FigInnerHeight = 20*(obj.nParams+2)+10*(obj.nParams+1)+20;
            end

            function Finish(obj,source,~)
                obj.SaveStatus = source.Text;
                close(obj.Parent);
            end

            function delete(obj)
                delete(obj)
            end

            function focusFirst(obj)
                focus(obj.EditFields(1));
            end

        end



end