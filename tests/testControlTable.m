classdef testControlTable < matlab.unittest.TestCase
    %TESTCONTROLTABLE Focused ControlTable data, editing, and lifecycle tests.

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

    methods (Test)
        function emptyDataKeepsHeadersAndMessage(testCase)
            [fig,component] = testCase.make_(testCase.emptyData_());
            testCase.addTeardown(@() delete(fig));
            state = component.debug();

            testCase.verifyNumElements(state.HeaderGrids,5);
            testCase.verifyNumElements(state.HeaderLabels,5);
            testCase.verifyTrue(isvalid(state.EmptyLabel));
            testCase.verifyEqual(string(state.EmptyLabel.Text),"No rows");
            testCase.verifyEqual(string(state.SizingGrid.Scrollable),"off");
        end

        function staticAndDynamicDropdowns(testCase)
            [fig,component] = testCase.make_(testCase.data_());
            testCase.addTeardown(@() delete(fig));
            controls = component.debug().Controls;

            format = controls{1,2};
            testCase.verifyEqual(string(format.Items),["PNG","OME-TIFF"]);
            testCase.verifyEqual(string(format.ItemsData),["png","ome-tiff"]);
            testCase.verifyEqual(string(format.Value),"png");

            firstScaling = controls{1,3};
            secondScaling = controls{2,3};
            testCase.verifyEqual(string(firstScaling.Items), ...
                ["Unscaled","User scaled","Auto scaled"]);
            testCase.verifyEqual(string(secondScaling.Items),"Unscaled");
            testCase.verifyEqual(string(controls{1,4}.Enable),"on");
            testCase.verifyEqual(string(controls{2,4}.Enable),"off");
        end

        function dropdownMatchingDoesNotMixTextAndNumericValues(testCase)
            columns = matlabx.ui.control.ControlTableColumn( ...
                Name="Choice",Label="Choice",ControlType="dropdown", ...
                Items=["One","Two"],ItemsData=[1 2]);
            data = table("1",VariableNames="Choice");
            [fig,component] = testCase.make_(data,columns);
            testCase.addTeardown(@() delete(fig));
            control = component.debug().Controls{1,1};
            validity = getappdata(control,'matlabxControlTableValueValidity');

            testCase.verifyFalse(validity.IsValid);
            testCase.verifyEqual(string(control.Items),["One","Two",""]);
            testCase.verifyEqual(component.Data.Choice,"1");
        end

        function assignedDataMustContainDefinedColumns(testCase)
            [fig,component] = testCase.make_(testCase.data_());
            testCase.addTeardown(@() delete(fig));

            testCase.verifyError(@() assignData_(component,table()), ...
                'matlabx:ui:control:ControlTable:MissingVariables');
        end

        function editingStoresValuesAndEmitsPayload(testCase)
            [fig,component] = testCase.make_(testCase.data_());
            testCase.addTeardown(@() delete(fig));
            component.CellEditedFcn = @(~,event) captureEdit_(fig,component,event);
            controls = component.debug().Controls;

            controls{1,5}.Value = true;
            controls{1,5}.ValueChangedFcn(controls{1,5},[]);
            event = getappdata(fig,'LastEdit');

            testCase.verifyTrue(component.Data.EmbedLUT(1));
            testCase.verifyEqual(event.Row,1);
            testCase.verifyEqual(event.Column,5);
            testCase.verifyEqual(event.Name,"EmbedLUT");
            testCase.verifyFalse(event.OldValue);
            testCase.verifyTrue(event.NewValue);
            testCase.verifyEqual(component.SelectedRow,1);
            testCase.verifyFalse(getappdata(fig,'RefreshingAtEdit'));
        end

        function colorPickerStoresRGBAndEmitsPayload(testCase)
            data = table([0.10 0.20 0.30; 0.80 0.70 0.60], ...
                VariableNames="Color");
            columns = matlabx.ui.control.ControlTableColumn( ...
                Name="Color",Label="Color",Width=70,ControlType="color");
            [fig,component] = testCase.make_(data,columns);
            testCase.addTeardown(@() delete(fig));
            component.CellEditedFcn = @(~,event) setappdata(fig,'LastEdit',event);
            picker = component.debug().Controls{1,1};

            testCase.verifyClass(picker,'matlab.ui.control.ColorPicker');
            testCase.verifyEqual(picker.Value,[0.10 0.20 0.30],'AbsTol',1e-12);
            picker.Value = [0.25 0.50 0.75];
            picker.ValueChangedFcn(picker,[]);
            event = getappdata(fig,'LastEdit');

            testCase.verifyEqual(component.Data.Color(1,:),[0.25 0.50 0.75], ...
                'AbsTol',1e-12);
            testCase.verifyEqual(event.Name,"Color");
            testCase.verifyEqual(event.OldValue,[0.10 0.20 0.30], ...
                'AbsTol',1e-12);
            testCase.verifyEqual(event.NewValue,[0.25 0.50 0.75], ...
                'AbsTol',1e-12);
        end

        function textNumericAndItemsDataEditing(testCase)
            data = testCase.data_();
            data.Note = ["one";"two"];
            data.Level = [1;2];
            columns = [testCase.columns_(), ...
                matlabx.ui.control.ControlTableColumn( ...
                    Name="Note",Label="Note",Width="1x",ControlType="text"), ...
                matlabx.ui.control.ControlTableColumn( ...
                    Name="Level",Label="Level",Width=80,ControlType="numeric")];
            [fig,component] = testCase.make_(data,columns);
            testCase.addTeardown(@() delete(fig));
            controls = component.debug().Controls;

            controls{1,2}.Value = "ome-tiff";
            controls{1,2}.ValueChangedFcn(controls{1,2},[]);
            controls = component.debug().Controls;
            controls{1,6}.Value = 'changed';
            controls{1,6}.ValueChangedFcn(controls{1,6},[]);
            controls{1,7}.Value = 4.5;
            controls{1,7}.ValueChangedFcn(controls{1,7},[]);

            testCase.verifyEqual(component.Data.Format(1),"ome-tiff");
            testCase.verifyEqual(component.Data.Note(1),"changed");
            testCase.verifyEqual(component.Data.Level(1),4.5);
            scaling = component.debug().Controls{1,3};
            testCase.verifyEqual(string(scaling.Items),["Unscaled",""]);
            testCase.verifyEqual(component.Data.Scaling(1),"auto");
            validity = getappdata(scaling,'matlabxControlTableValueValidity');
            testCase.verifyFalse(validity.IsValid);

            scaling.Value = "unscaled";
            scaling.ValueChangedFcn(scaling,[]);
            scaling = component.debug().Controls{1,3};
            testCase.verifyEqual(component.Data.Scaling(1),"unscaled");
            testCase.verifyEqual(string(scaling.Items),"Unscaled");
            validity = getappdata(scaling,'matlabxControlTableValueValidity');
            testCase.verifyTrue(validity.IsValid);
        end

        function programmaticRefreshDoesNotEmitEdit(testCase)
            [fig,component] = testCase.make_(testCase.data_());
            testCase.addTeardown(@() delete(fig));
            setappdata(fig,'EditCount',0);
            component.CellEditedFcn = @(~,~) setappdata(fig,'EditCount', ...
                getappdata(fig,'EditCount')+1);

            component.refresh();
            component.refreshRow(1);
            row = component.Data(1,:);
            row.ImageType = "Changed";
            component.replaceRow(1,row);

            testCase.verifyEqual(getappdata(fig,'EditCount'),0);
            testCase.verifyEqual(component.Data.ImageType(1),"Changed");
        end

        function selectionAndRowOperations(testCase)
            [fig,component] = testCase.make_(testCase.data_());
            testCase.addTeardown(@() delete(fig));
            component.SelectionChangedFcn = @(~,event) ...
                captureSelection_(fig,component,event);

            component.SelectedRow = 2;
            event = getappdata(fig,'Selection');
            testCase.verifyEqual([event.OldRow event.NewRow],[0 2]);

            component.addRow(component.Data(1,:));
            component.insertRow(2,component.Data(1,:));
            testCase.verifyEqual(height(component.Data),4);
            testCase.verifyFalse(getappdata(fig,'RefreshingAtSelection'));
            component.removeRow(2);
            testCase.verifyEqual(height(component.Data),3);
            testCase.verifyEqual(component.SelectedRow,2);
            testCase.verifyFalse(getappdata(fig,'RefreshingAtSelection'));
        end

        function rowOperationsPreserveStableIdentityAndGraphics(testCase)
            [fig,component] = testCase.make_(testCase.data_());
            testCase.addTeardown(@() delete(fig));
            originalIDs = component.RowIDs;
            original = component.debug();
            firstGrid = original.CellGrids{1,1};
            secondGrid = original.CellGrids{2,1};
            secondControl = original.Controls{2,1};

            component.insertRow(2,component.Data(1,:));
            inserted = component.debug();
            testCase.verifyEqual(component.RowIDs([1 3]),originalIDs);
            testCase.verifyNotEqual(component.RowIDs(2),originalIDs(1));
            testCase.verifyEqual(inserted.CellGrids{1,1},firstGrid);
            testCase.verifyEqual(inserted.CellGrids{3,1},secondGrid);
            testCase.verifyEqual(secondGrid.Layout.Row,4);

            secondControl.Value = 'renamed';
            secondControl.ValueChangedFcn(secondControl,[]);
            testCase.verifyEqual(component.Data.ImageType(3),"renamed");

            component.removeRow(2);
            removed = component.debug();
            testCase.verifyEqual(component.RowIDs,originalIDs);
            testCase.verifyEqual(removed.CellGrids{1,1},firstGrid);
            testCase.verifyEqual(removed.CellGrids{2,1},secondGrid);
            testCase.verifyEqual(secondGrid.Layout.Row,3);
        end

        function columnWidthsAndSharedTracks(testCase)
            columns = testCase.columns_();
            [fig,component] = testCase.make_(testCase.data_(),columns);
            testCase.addTeardown(@() delete(fig));
            state = component.debug();

            testCase.verifyEqual(state.SizingGrid.ColumnWidth, ...
                {'2x',110,130,'1x','fit'});
            testCase.verifyEqual(component.BorderWidth,[1 1 1 1]);
            testCase.verifyEqual(component.InnerBorderWidth,[1 1 1 1]);
            testCase.verifyEqual(component.InnerPadding,[0 0 0 0]);
            testCase.verifyEqual(component.RowSpacing,1);
            testCase.verifyEqual(component.ColumnSpacing,1);
            testCase.verifyEqual(state.OuterGrid.Padding,[1 1 1 1]);
            testCase.verifyEqual(state.InnerGrid.Padding,[1 1 1 1]);
            testCase.verifyEqual(state.SizingGrid.Padding,[0 0 0 0]);
            testCase.verifyEqual(string(state.OuterGrid.Scrollable),"off");
            testCase.verifyEqual(string(state.InnerGrid.Scrollable),"off");
            testCase.verifyEqual(string(state.SizingGrid.Scrollable),"off");
            testCase.verifyEqual(state.OuterGrid.BackgroundColor,component.BorderColor);
            testCase.verifyEqual(state.InnerGrid.BackgroundColor,component.InnerBorderColor);
            testCase.verifyEqual(state.SizingGrid.BackgroundColor,component.CellBorderColor);
            testCase.verifyNotEqual(component.BorderColor,component.InnerBorderColor);
            testCase.verifyNotEqual(component.InnerBorderColor,component.CellBorderColor);
            cellData = getappdata(state.CellGrids{1,1},'matlabxControlTableCell');
            testCase.verifyNotEmpty(component.ID);
            testCase.verifyEqual(string(cellData.TableID),component.ID);
            testCase.verifyEqual(string(cellData.RowID),component.RowIDs(1));
            testCase.verifyEqual(string(cellData.ColumnID),component.ColumnIDs(1));
            for column = 1:numel(columns)
                testCase.verifyEqual(state.HeaderGrids{column}.Layout.Column,column);
                testCase.verifyEqual(string(state.HeaderLabels{column}.Text), ...
                    columns(column).Label);
                testCase.verifyEqual(state.CellGrids{1,column}.Layout.Column,column);
            end
            testCase.verifyTrue(isfinite(state.RouterId));

            component.BorderWidth = 2;
            component.InnerBorderWidth = [1 2 3 4];
            testCase.verifyEqual(component.BorderWidth,[2 2 2 2]);
            testCase.verifyEqual(component.InnerBorderWidth,[1 2 3 4]);
            testCase.verifyEqual(component.debug().OuterGrid.Padding,[2 2 2 2]);
            testCase.verifyEqual(component.debug().InnerGrid.Padding,[1 2 3 4]);
        end

        function childHitTraversalAndCombinedAppearance(testCase)
            [fig,component] = testCase.make_(testCase.data_());
            testCase.addTeardown(@() delete(fig));
            state = component.debug();
            target = state.Controls{2,3};

            testCase.verifyEqual(component.debugPointerTarget(target),2);
            component.debugPointerTarget(target,"down");
            component.debugPointerTarget(target,"move");
            state = component.debug();

            testCase.verifyEqual(component.SelectedRow,2);
            testCase.verifyEqual(state.HoveredRow,2);
            testCase.verifyEqual(state.CellGrids{2,1}.BackgroundColor, ...
                component.SelectedHoverBackgroundColor,'AbsTol',1e-12);
            component.debugPointerTarget(fig,"move");
            testCase.verifyEqual(component.debug().CellGrids{2,1}.BackgroundColor, ...
                component.SelectedBackgroundColor,'AbsTol',1e-12);
        end

        function reparentingRebindsHub(testCase)
            [fig1,component] = testCase.make_(testCase.data_());
            fig2 = uifigure(Visible='off');
            grid2 = uigridlayout(fig2,[1 1]);
            testCase.addTeardown(@() deleteValid_(fig1));
            testCase.addTeardown(@() deleteValid_(fig2));
            firstHub = component.debug().Hub;

            component.Parent = grid2;
            drawnow;
            secondHub = component.debug().Hub;

            testCase.verifyNotEqual(firstHub,secondHub);
            testCase.verifyTrue(isfinite(component.debug().RouterId));
            delete(fig1);
            testCase.verifyTrue(isvalid(component));
        end

        function hidingClearsHover(testCase)
            [fig,component] = testCase.make_(testCase.data_());
            testCase.addTeardown(@() delete(fig));
            component.debugPointerTarget(component.debug().Controls{1,1},"move");
            testCase.verifyEqual(component.debug().HoveredRow,1);

            component.Visible = 'off';
            drawnow;

            testCase.verifyEqual(component.debug().HoveredRow,0);
        end

        function structDefinitionsAreAccepted(testCase)
            definitions = struct( ...
                'Name',{'Name','Enabled'}, ...
                'Label',{'Name','Enabled'}, ...
                'Width',{'1x',80}, ...
                'ControlType',{'text','checkbox'});
            data = table(["A";"B"],[true;false], ...
                VariableNames=["Name","Enabled"]);
            [fig,component] = testCase.make_(data,definitions);
            testCase.addTeardown(@() delete(fig));

            testCase.verifyNumElements(component.Columns,2);
            testCase.verifyEqual([component.Columns.Name],["Name","Enabled"]);
        end
    end

    methods (Static, Access=private)
        function [fig,component] = make_(data,columns)
            if nargin < 2, columns = testControlTable.columns_(); end
            fig = uifigure(Visible='off');
            grid = uigridlayout(fig,[1 1]);
            component = matlabx.ui.control.ControlTable(grid, ...
                Columns=columns,Data=data);
            drawnow;
        end

        function data = data_()
            data = table( ...
                ["Average intensity";"Order"], ...
                ["png";"ome-tiff"], ...
                ["auto";"unscaled"], ...
                ["light";""], ...
                [false;true], ...
                VariableNames=["ImageType","Format","Scaling","AutoMethod","EmbedLUT"]);
        end

        function data = emptyData_()
            data = testControlTable.data_();
            data(1:height(data),:) = [];
        end

        function columns = columns_()
            columns = [ ...
                matlabx.ui.control.ControlTableColumn( ...
                    Name="ImageType",Label="Image type",Width="2x",ControlType="text"), ...
                matlabx.ui.control.ControlTableColumn( ...
                    Name="Format",Label="Format",Width=110,ControlType="dropdown", ...
                    Items=["PNG","OME-TIFF"],ItemsData=["png","ome-tiff"]), ...
                matlabx.ui.control.ControlTableColumn( ...
                    Name="Scaling",Label="Scaling",Width=130,ControlType="dropdown", ...
                    ItemsFcn=@scalingChoices_), ...
                matlabx.ui.control.ControlTableColumn( ...
                    Name="AutoMethod",Label="Auto method",Width="1x", ...
                    ControlType="dropdown",Items=["Light","Gentle"], ...
                    ItemsData=["light","gentle"],EnabledFcn=@autoEnabled_), ...
                matlabx.ui.control.ControlTableColumn( ...
                    Name="EmbedLUT",Label="Embed LUT",Width="fit",ControlType="checkbox")];
        end
    end
end

function [items,itemsData] = scalingChoices_(row,~,~)
    if row.Format == "ome-tiff"
        items = "Unscaled";
        itemsData = "unscaled";
    else
        items = ["Unscaled","User scaled","Auto scaled"];
        itemsData = ["unscaled","user","auto"];
    end
end

function enabled = autoEnabled_(row,~,~)
    enabled = row.Scaling == "auto";
end

function deleteValid_(value)
    if ~isempty(value) && isvalid(value), delete(value); end
end

function assignData_(component,value)
    component.Data = value;
end

function captureSelection_(fig,component,event)
    setappdata(fig,'Selection',event);
    setappdata(fig,'RefreshingAtSelection',component.debug().Refreshing);
end

function captureEdit_(fig,component,event)
    setappdata(fig,'LastEdit',event);
    setappdata(fig,'RefreshingAtEdit',component.debug().Refreshing);
end
