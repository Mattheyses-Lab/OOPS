function [fig,controlTable] = controlTable()
%CONTROLTABLE Interactive demonstration of matlabx.ui.control.ControlTable.
%
%   matlabx.ui.demo.controlTable opens a small booking editor showing every
%   supported control type, several column-width modes, row-dependent
%   and cross-row choices, selection, and incremental row operations.

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

    data = table( ...
        ["Morning stand-up";"Sample preparation";"Project review"], ...
        ["meeting";"laboratory";"meeting"], ...
        ["cedar";"lab-a";"maple"], ...
        [0.5;2;1], ...
        [0.20 0.60 0.95; 0.95 0.55 0.20; 0.65 0.45 0.90], ...
        [true;true;false], ...
        VariableNames=["Booking","SpaceType","Room","Hours","Color","Confirmed"]);

    columns = [ ...
        matlabx.ui.control.ControlTableColumn( ...
            Name="Booking",Label="Booking",Width="2x",ControlType="text"), ...
        matlabx.ui.control.ControlTableColumn( ...
            Name="SpaceType",Label="Space type",Width=130,ControlType="dropdown", ...
            Items=["Meeting room","Laboratory"], ...
            ItemsData=["meeting","laboratory"]), ...
        matlabx.ui.control.ControlTableColumn( ...
            Name="Room",Label="Available room",Width=150, ...
            ControlType="dropdown",ItemsFcn=@roomChoices_), ...
        matlabx.ui.control.ControlTableColumn( ...
            Name="Hours",Label="Hours",Width=80,ControlType="numeric", ...
            EnabledFcn=@bookingConfirmed_), ...
        matlabx.ui.control.ControlTableColumn( ...
            Name="Color",Label="Color",Width=65,ControlType="color"), ...
        matlabx.ui.control.ControlTableColumn( ...
            Name="Confirmed",Label="Confirmed",Width="fit", ...
            ControlType="checkbox")];

    fig = uifigure(Name='ControlTable demo',Position=[100 100 980 380], ...
        Color=[0.12 0.12 0.12]);
    grid = uigridlayout(fig,[3 1], ...
        'RowHeight',{42,'1x',30}, ...
        'Padding',[10 10 10 10], ...
        'RowSpacing',8, ...
        'BackgroundColor',[0.08 0.09 0.11]);

    introduction = uigridlayout(grid,[2 1], ...
        RowHeight={20,18},ColumnWidth={'1x'},Padding=0,RowSpacing=0, ...
        BackgroundColor=[0.08 0.09 0.11]);
    uilabel(introduction,Text='Hypothetical room bookings', ...
        FontWeight='bold',FontColor=[0.90 0.90 0.90]);
    uilabel(introduction, ...
        Text='Change a space type to invalidate its room, or duplicate a confirmed booking to reserve the same room twice.', ...
        FontColor=[0.68 0.70 0.74]);
    tableHost = uigridlayout(grid,[1 1], ...
        ColumnWidth={'1x'},RowHeight={'fit'},Padding=[0 0 0 0], ...
        RowSpacing=0,ColumnSpacing=0, ...
        BackgroundColor=[0.08 0.09 0.11],Scrollable='on');
    controlTable = matlabx.ui.control.ControlTable(tableHost, ...
        Columns=columns,Data=data);

    footer = uigridlayout(grid,[1 5], ...
        ColumnWidth={80,80,80,'1x','2x'},Padding=[0 0 0 0],ColumnSpacing=6, ...
        BackgroundColor=[0.08 0.09 0.11]);
    uibutton(footer,Text='Add',ButtonPushedFcn=@addRow_);
    uibutton(footer,Text='Duplicate',ButtonPushedFcn=@duplicateRow_);
    uibutton(footer,Text='Delete',ButtonPushedFcn=@deleteRow_);
    status = uilabel(footer,Text='Edit a cell or select a row.', ...
        FontColor=[0.90 0.90 0.90]);
    status.Layout.Column = [4 5];
    controlTable.CellEditedFcn = @(~,event) set(status,'Text',sprintf( ...
        'Edited row %d, %s',event.Row,event.Name));
    controlTable.SelectionChangedFcn = @(~,event) set(status,'Text',sprintf( ...
        'Selected row %d',event.NewRow));
    movegui(fig,'center');

    function addRow_(~,~)
    %ADDROW_ Append a valid example booking with a new stable row ID.
        index = height(controlTable.Data) + 1;
        names = ["Team meeting","Bench work"];
        types = ["meeting","laboratory"];
        rooms = ["cedar","lab-a"];
        choice = mod(index-1,numel(types))+1;
        colors = [0.30 0.70 0.95; 0.95 0.65 0.25];
        row = table(names(choice),types(choice),rooms(choice),1, ...
            colors(choice,:),true, ...
            VariableNames=controlTable.Data.Properties.VariableNames);
        controlTable.addRow(row);
        controlTable.SelectedRow = index;
    end

    function duplicateRow_(~,~)
    %DUPLICATEROW_ Append a copy so cross-row room validity can be tested.
        index = controlTable.SelectedRow;
        if index == 0
            status.Text = 'Select a row to duplicate.';
            return
        end
        row = controlTable.Data(index,:);
        controlTable.addRow(row);
        controlTable.SelectedRow = height(controlTable.Data);
    end

    function deleteRow_(~,~)
    %DELETEROW_ Remove the selected booking through the incremental API.
        index = controlTable.SelectedRow;
        if index == 0
            status.Text = 'Select a row to delete.';
            return
        end
        controlTable.removeRow(index);
        status.Text = sprintf('Deleted row %d',index);
    end
end

function [items,itemsData] = roomChoices_(row,rowIndex,tableData)
%ROOMCHOICES_ Return compatible rooms not reserved by earlier confirmed rows.
    switch row.SpaceType
        case "meeting"
            items = ["Cedar","Maple"];
            itemsData = ["cedar","maple"];
        case "laboratory"
            items = ["Lab A","Lab B"];
            itemsData = ["lab-a","lab-b"];
    end

    % Earlier confirmed rows reserve their rooms. This deterministic policy
    % keeps the earlier booking valid and makes a later duplicate visibly
    % invalid until the user selects another compatible room.
    earlierRows = 1:rowIndex-1;
    confirmedRows = earlierRows(tableData.Confirmed(earlierRows));
    reserved = tableData.Room(confirmedRows);
    available = ~ismember(itemsData,reserved);
    items = items(available);
    itemsData = itemsData(available);
end

function enabled = bookingConfirmed_(row,~,~)
%BOOKINGCONFIRMED_ Enable duration editing only for confirmed bookings.
    enabled = row.Confirmed;
end
