classdef ControlTable < matlab.ui.componentcontainer.ComponentContainer
%CONTROLTABLE Table-like editor composed from native MATLAB UI controls.
%
%   T = matlabx.ui.control.ControlTable(PARENT,Columns=COLUMNS,Data=DATA)
%   creates an aligned header and control-cell grid. DATA is a MATLAB table
%   and remains authoritative; graphics handles are never stored in it.
%
%   Supported ControlType values are dropdown, checkbox, text, numeric, and
%   color. Color columns store one RGB triplet per table row and display a
%   uicolorpicker dropdown.
%   Dropdown choices may be static or supplied per row by ItemsFcn:
%
%       [items,itemsData] = fcn(rowData,rowIndex,tableData)
%
%   EnabledFcn uses the same inputs and returns one logical value. The
%   component is intended for modest configuration tables rather than large,
%   virtualized datasets.
%
%   Example:
%       columns = [ ...
%           matlabx.ui.control.ControlTableColumn( ...
%               Name="Name",Label="Name",Width="1x",ControlType="text"), ...
%           matlabx.ui.control.ControlTableColumn( ...
%               Name="Enabled",Label="Enabled",Width=80,ControlType="checkbox")];
%       data = table(["First";"Second"],[true;false], ...
%           VariableNames=["Name","Enabled"]);
%       t = matlabx.ui.control.ControlTable(parent,Columns=columns,Data=data);
%
%   To scroll a table within constrained space, place it in a scrollable
%   one-cell grid whose row height is "fit":
%
%       host = uigridlayout(parent,[1 1], ...
%           ColumnWidth={'1x'},RowHeight={'fit'}, ...
%           Padding=[0 0 0 0],Scrollable='on');
%       t = matlabx.ui.control.ControlTable(host, ...
%           Columns=columns,Data=data);
%
%   The host defines the scrolling viewport while allowing ControlTable to
%   retain its natural content height and border appearance.
%
%   Run ControlTable.demo to open an interactive example.
%
%   See also matlabx.ui.control.ControlTableColumn

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

    %% Public API

    % Authoritative data, column definitions, selection, and border sizing.
    properties (Dependent)
        % Column definitions controlling headers, widths, and cell controls.
        Columns
        % Authoritative row data.
        Data table
        % Selected row index, or zero when no row is selected.
        SelectedRow (1,1) double
        % Outer border width as a scalar or [left bottom right top].
        BorderWidth
        % Inner border width as a scalar or [left bottom right top].
        InnerBorderWidth
    end

    properties (SetAccess=private)
        % Runtime UUID used to identify graphics owned by this table.
        ID (1,1) string = ""
        % Stable runtime identities corresponding to Data rows.
        RowIDs (1,:) string = string.empty(1,0)
        % Stable runtime identities corresponding to Columns.
        ColumnIDs (1,:) string = string.empty(1,0)
    end

    % Public sizing, spacing, text, and appearance configuration.
    properties
        % Fixed height applied to every data row.
        RowHeight (1,1) double {mustBePositive} = 30
        % Separator thickness between rows.
        RowSpacing (1,1) double {mustBeNonnegative} = 1
        % Separator thickness between columns.
        ColumnSpacing (1,1) double {mustBeNonnegative} = 1
        % Padding inside the inner border [left bottom right top].
        InnerPadding (1,4) double {mustBeNonnegative} = [0 0 0 0]
        % Padding around native controls within each cell.
        CellPadding (1,4) double {mustBeNonnegative} = [4 3 4 3]
        % Font size of column header labels, in pixels.
        HeaderFontSize (1,1) double {mustBePositive} = 12
        % Vertical padding above and below column header labels.
        HeaderPadding (1,1) double {mustBeNonnegative} = 3
        % Text shown below the header when Data has no rows.
        EmptyText (1,1) string = "No rows"

        % Background color used by odd, unselected data rows.
        CellBackgroundColor (1,3) double {mustBeBetween(CellBackgroundColor,0,1)} = [0.18 0.18 0.18]
        % Background color used by even, unselected data rows.
        AlternateRowColor (1,3) double {mustBeBetween(AlternateRowColor,0,1)} = [0.22 0.22 0.22]
        % Background color used by the row beneath the pointer.
        HoverBackgroundColor (1,3) double {mustBeBetween(HoverBackgroundColor,0,1)} = [0.30 0.30 0.30]
        % Background color used by the selected row.
        SelectedBackgroundColor (1,3) double {mustBeBetween(SelectedBackgroundColor,0,1)} = [0.00 0.36 0.60]
        % Background color used when the selected row is also hovered.
        SelectedHoverBackgroundColor (1,3) double {mustBeBetween(SelectedHoverBackgroundColor,0,1)} = [0.00 0.45 0.74]
        % Background color of column header cells.
        HeaderBackgroundColor (1,3) double {mustBeBetween(HeaderBackgroundColor,0,1)} = [0.12 0.12 0.12]
        % Background color applied to compatible native cell controls.
        ControlBackgroundColor (1,3) double {mustBeBetween(ControlBackgroundColor,0,1)} = [0.30 0.30 0.30]
        % Foreground color applied to headers, labels, and cell controls.
        FontColor (1,3) double {mustBeBetween(FontColor,0,1)} = [0.90 0.90 0.90]
        % Color visible in spacing between adjacent table cells.
        CellBorderColor (1,3) double {mustBeBetween(CellBorderColor,0,1)} = [0.28 0.29 0.32]
        % Color of the inner table border.
        InnerBorderColor (1,3) double {mustBeBetween(InnerBorderColor,0,1)} = [0.14 0.15 0.18]
        % Color of the outer table border.
        BorderColor (1,3) double {mustBeBetween(BorderColor,0,1)} = [0.44 0.46 0.50]
    end

    events (HasCallbackProperty, NotifyAccess=protected)
        % Emitted once after a user edit is stored in Data.
        CellEdited
        % Emitted whenever SelectedRow changes.
        SelectionChanged
    end

    %% State and graphics

    % Private backing values and guards for dependent public properties.
    properties (Access=private)
        % Normalized column definitions currently used by the table.
        Columns_ (1,:) matlabx.ui.control.ControlTableColumn = ...
            matlabx.ui.control.ControlTableColumn.empty(1,0)
        % Authoritative table data backing the public Data property.
        Data_ table = table()
        % Backing value for the selected row index.
        SelectedRow_ (1,1) double = 0
        % Row currently highlighted by pointer hover, or zero.
        HoveredRow_ (1,1) double = 0
        % Guard suppressing callbacks during programmatic control updates.
        Refreshing_ (1,1) logical = false
        % Whether setup has created the internal graphics hierarchy.
        SetupComplete_ (1,1) logical = false
        % Whether the public Data property has been explicitly assigned.
        DataAssigned_ (1,1) logical = false
        % Normalized four-element outer border padding.
        BorderWidth_ (1,4) double = [1 1 1 1]
        % Normalized four-element inner border padding.
        InnerBorderWidth_ (1,4) double = [1 1 1 1]
    end

    % MATLAB graphics owned by the component and excluded from copying.
    properties (Access=private,Transient,NonCopyable)
        % Outermost grid whose background and padding form the outer border.
        OuterGrid matlab.ui.container.GridLayout
        % Nested grid whose background and padding form the inner border.
        InnerGrid matlab.ui.container.GridLayout
        % Shared header/body grid defining all row and column tracks.
        SizingGrid matlab.ui.container.GridLayout
        % Per-column grid containers for header labels.
        HeaderGrids cell = {}
        % Per-column header label handles.
        HeaderLabels cell = {}
        % Row-by-column cell grid containers.
        CellGrids cell = {}
        % Row-by-column native control handles.
        CellControls cell = {}
        % Empty-state label shown when Data has no rows.
        EmptyLabel = []
    end

    % FigureEventHub registration state for pointer routing.
    properties (Access=private)
        % Figure event hub serving the current ancestor figure.
        Hub = []
        % Figure associated with Hub.
        HubFigure = []
        % Registration identifier returned by FigureEventHub.
        RouterId (1,1) double = NaN
    end

    %% Component lifecycle
    methods (Access=protected)
        function setup(obj)
        %SETUP Construct the shared header/body sizing grid.
            obj.ID = string(char(java.util.UUID.randomUUID()));
            obj.Position = [10 10 600 240];

            obj.OuterGrid = uigridlayout(obj,[1 1], ...
                'Padding',obj.BorderWidth, ...
                'ColumnWidth',{'1x'}, ...
                'RowHeight',{'1x'}, ...
                'RowSpacing',0, ...
                'ColumnSpacing',0, ...
                'BackgroundColor',obj.BorderColor);
            obj.InnerGrid = uigridlayout(obj.OuterGrid,[1 1], ...
                'Padding',obj.InnerBorderWidth, ...
                'RowSpacing',0, ...
                'ColumnSpacing',0, ...
                'BackgroundColor',obj.InnerBorderColor);
            obj.SizingGrid = uigridlayout(obj.InnerGrid,[1 1], ...
                'Padding',obj.InnerPadding, ...
                'RowSpacing',obj.RowSpacing, ...
                'ColumnSpacing',obj.ColumnSpacing, ...
                'BackgroundColor',obj.CellBorderColor);
            obj.SetupComplete_ = true;
            obj.rebuild_();
            obj.ensureHub_();
        end

        function update(obj)
        %UPDATE Apply layout and appearance properties.
            if ~obj.SetupComplete_ || isempty(obj.SizingGrid) || ~isvalid(obj.SizingGrid)
                return
            end
            obj.applyLayout_();
            obj.applyAllRowAppearances_();
            if string(obj.Visible) == "off"
                obj.updateHover_(0);
            end
            obj.ensureHub_();
        end
    end

    methods
        function delete(obj)
        %DELETE Release the FigureEventHub registration.
            obj.releaseHub_();
        end
    end

    methods (Hidden)
        function state = debug(obj)
        %DEBUG Return graphics and interaction state for diagnostics/tests.
            state = struct( ...
                'OuterGrid',obj.OuterGrid, ...
                'InnerGrid',obj.InnerGrid, ...
                'SizingGrid',obj.SizingGrid, ...
                'HeaderGrids',{obj.HeaderGrids}, ...
                'HeaderLabels',{obj.HeaderLabels}, ...
                'CellGrids',{obj.CellGrids}, ...
                'Controls',{obj.CellControls}, ...
                'EmptyLabel',obj.EmptyLabel, ...
                'HoveredRow',obj.HoveredRow_, ...
                'Refreshing',obj.Refreshing_, ...
                'Hub',obj.Hub, ...
                'RouterId',obj.RouterId);
        end

        function row = debugPointerTarget(obj,target,action)
        %DEBUGPOINTERTARGET Exercise target traversal without moving a pointer.
            arguments
                obj
                target
                action (1,1) string {mustBeMember(action,["query","move","down"])} = "query"
            end
            row = obj.rowForTarget_(target);
            if action == "move"
                obj.updateHover_(row);
            elseif action == "down" && row > 0
                obj.SelectedRow = row;
            end
        end
    end

    %% Dependent properties
    methods
        function value = get.Columns(obj)
        %GET.COLUMNS Return the normalized column definitions.
            value = obj.Columns_;
        end

        function set.Columns(obj,value)
        %SET.COLUMNS Validate definitions and rebuild the table structure.
            value = matlabx.ui.control.ControlTableColumn.normalize(value);
            names = [value.Name];
            if numel(unique(names)) ~= numel(names)
                error('matlabx:ui:control:ControlTable:DuplicateColumns', ...
                    'Column Name values must be unique.');
            end
            if obj.DataAssigned_
                obj.validateData_(obj.Data_,value);
            end
            obj.Columns_ = value;
            obj.ColumnIDs = newUUIDs_(numel(value));
            if obj.SetupComplete_, obj.rebuild_(); end
        end

        function value = get.Data(obj)
        %GET.DATA Return the authoritative table data.
            value = obj.Data_;
        end

        function set.Data(obj,value)
        %SET.DATA Replace all row data and regenerate stable row identities.
            if ~istable(value)
                error('matlabx:ui:control:ControlTable:InvalidData', ...
                    'Data must be a MATLAB table.');
            end
            obj.validateData_(value,obj.Columns_);
            obj.Data_ = value;
            obj.DataAssigned_ = true;
            obj.RowIDs = newUUIDs_(height(value));
            newSelection = obj.nearestRow_(obj.SelectedRow_);
            if obj.SetupComplete_, obj.rebuild_(); end
            obj.SelectedRow = newSelection;
        end

        function value = get.SelectedRow(obj)
        %GET.SELECTEDROW Return the selected numeric row index.
            value = obj.SelectedRow_;
        end

        function set.SelectedRow(obj,value)
        %SET.SELECTEDROW Validate, display, and announce a selection change.
            if isempty(value), value = 0; end
            if ~isscalar(value) || ~isnumeric(value) || ~isfinite(value) || ...
                    value < 0 || value ~= fix(value) || value > height(obj.Data_)
                error('matlabx:ui:control:ControlTable:InvalidSelectedRow', ...
                    'SelectedRow must be zero or a valid row index.');
            end
            old = obj.SelectedRow_;
            if old == value, return; end
            obj.SelectedRow_ = value;
            obj.applyRowAppearance_(old);
            obj.applyRowAppearance_(value);
            notify(obj,'SelectionChanged', ...
                matlabx.ui.control.ControlTableSelectionChangedData(old,value));
        end

        function value = get.BorderWidth(obj)
        %GET.BORDERWIDTH Return normalized outer-border padding.
            value = obj.BorderWidth_;
        end

        function set.BorderWidth(obj,value)
        %SET.BORDERWIDTH Normalize and apply outer-border padding.
            value = normalizeBorderWidth_(value,'BorderWidth');
            if isequal(value,obj.BorderWidth_), return; end
            obj.BorderWidth_ = value;
            if obj.SetupComplete_, obj.applyLayout_(); end
        end

        function value = get.InnerBorderWidth(obj)
        %GET.INNERBORDERWIDTH Return normalized inner-border padding.
            value = obj.InnerBorderWidth_;
        end

        function set.InnerBorderWidth(obj,value)
        %SET.INNERBORDERWIDTH Normalize and apply inner-border padding.
            value = normalizeBorderWidth_(value,'InnerBorderWidth');
            if isequal(value,obj.InnerBorderWidth_), return; end
            obj.InnerBorderWidth_ = value;
            if obj.SetupComplete_, obj.applyLayout_(); end
        end
    end

    %% Row and refresh API
    methods
        function refresh(obj)
        %REFRESH Rebuild all graphics without changing Data.
            obj.rebuild_();
        end

        function refreshRow(obj,index)
        %REFRESHROW Reevaluate controls, choices, and enabled state for one row.
            obj.validateRowIndex_(index);
            if obj.Refreshing_, return; end
            cleanup = obj.beginRefresh_(); %#ok<NASGU>
            for column = 1:numel(obj.Columns_)
                obj.syncControl_(index,column);
            end
            obj.applyRowAppearance_(index);
        end

        function replaceRow(obj,index,rowData)
        %REPLACEROW Replace one row without emitting CellEdited.
            obj.validateRowIndex_(index);
            rowData = obj.normalizeRow_(rowData);
            obj.Data_(index,:) = rowData;
            cleanup = obj.beginRefresh_(); %#ok<NASGU>
            obj.refreshRowControls_(index);
            obj.refreshDynamicControls_();
        end

        function addRow(obj,rowData)
        %ADDROW Append one compatible table row.
            obj.insertRow(height(obj.Data_)+1,rowData);
        end

        function insertRow(obj,index,rowData)
        %INSERTROW Insert one compatible table row before INDEX.
            if ~isscalar(index) || index ~= fix(index) || index < 1 || index > height(obj.Data_)+1
                error('matlabx:ui:control:ControlTable:InvalidInsertIndex', ...
                    'Insert index must be between 1 and height(Data)+1.');
            end
            rowData = obj.normalizeRow_(rowData);
            cleanup = obj.beginRefresh_(); %#ok<NASGU>
            columnCount = numel(obj.Columns_);

            % Insert authoritative data, identity, and handle slots together.
            % Existing cells keep their UUIDs and graphics handles.
            obj.Data_ = [obj.Data_(1:index-1,:); rowData; obj.Data_(index:end,:)];
            obj.RowIDs = [obj.RowIDs(1:index-1),newUUIDs_(1),obj.RowIDs(index:end)];
            obj.CellGrids = [obj.CellGrids(1:index-1,:); ...
                cell(1,columnCount); obj.CellGrids(index:end,:)];
            obj.CellControls = [obj.CellControls(1:index-1,:); ...
                cell(1,columnCount); obj.CellControls(index:end,:)];
            if isvalidHandle_(obj.EmptyLabel)
                delete(obj.EmptyLabel);
                obj.EmptyLabel = [];
            end
            oldSelection = obj.SelectedRow_;

            % Numeric interaction indices move with their logical rows.
            if obj.SelectedRow_ >= index && obj.SelectedRow_ > 0
                obj.SelectedRow_ = obj.SelectedRow_ + 1;
            end
            if obj.HoveredRow_ >= index && obj.HoveredRow_ > 0
                obj.HoveredRow_ = obj.HoveredRow_ + 1;
            end
            obj.createRowGraphics_(index);
            obj.positionRowsFrom_(index+1);
            obj.applySizingTracks_();

            % Cross-row callbacks may make choices or enabled states change
            % even in rows whose own data and graphics were retained.
            obj.refreshDynamicControls_();
            obj.applyRowAppearancesFrom_(index);
            clear cleanup
            if oldSelection ~= obj.SelectedRow_
                notify(obj,'SelectionChanged', ...
                    matlabx.ui.control.ControlTableSelectionChangedData( ...
                    oldSelection,obj.SelectedRow_));
            end
        end

        function removeRow(obj,index)
        %REMOVEROW Remove one row and keep selection on a nearby row.
            obj.validateRowIndex_(index);
            cleanup = obj.beginRefresh_(); %#ok<NASGU>
            oldSelection = obj.SelectedRow_;

            % Deleting each cell grid also deletes its hosted native control.
            for column = 1:size(obj.CellGrids,2)
                if isvalidHandle_(obj.CellGrids{index,column})
                    delete(obj.CellGrids{index,column});
                end
            end
            obj.Data_(index,:) = [];
            obj.RowIDs(index) = [];
            obj.CellGrids(index,:) = [];
            obj.CellControls(index,:) = [];

            % Keep selection near the removed row while preserving selection
            % of surviving rows whose numeric index merely shifted.
            if oldSelection == index
                newSelection = min(index,height(obj.Data_));
            elseif oldSelection > index
                newSelection = oldSelection - 1;
            else
                newSelection = oldSelection;
            end
            obj.SelectedRow_ = newSelection;
            if obj.HoveredRow_ == index
                obj.HoveredRow_ = 0;
            elseif obj.HoveredRow_ > index
                obj.HoveredRow_ = obj.HoveredRow_ - 1;
            end
            obj.positionRowsFrom_(index);
            if height(obj.Data_) == 0, obj.createEmptyLabel_(); end
            obj.applySizingTracks_();
            obj.refreshDynamicControls_();
            appearanceStart = index;
            if oldSelection == index && newSelection > 0
                appearanceStart = min(index,newSelection);
            end
            obj.applyRowAppearancesFrom_(appearanceStart);
            clear cleanup
            if oldSelection ~= newSelection
                notify(obj,'SelectionChanged', ...
                    matlabx.ui.control.ControlTableSelectionChangedData( ...
                    oldSelection,newSelection));
            end
        end
    end

    %% Demonstration
    methods (Static)
        function [fig,controlTable] = demo()
        %DEMO Open a small interactive ControlTable demonstration.
        %
        %   matlabx.ui.control.ControlTable.demo creates a mixed-control
        %   table with fixed, fitted, and weighted column widths. Use the
        %   buttons below the table to add, duplicate, or delete rows.
        %
        %   [FIG,T] = matlabx.ui.control.ControlTable.demo also returns the
        %   figure and ControlTable handles.
            [fig,controlTable] = matlabx.ui.demo.controlTable();
        end
    end

    %% Private construction and synchronization
    methods (Access=private)
        function rebuild_(obj)
        %REBUILD_ Recreate headers and cell graphics from Columns and Data.
        %
        %   Full rebuilds are reserved for wholesale Data or Columns changes.
        %   Stable row and column IDs survive refresh(), while the graphics
        %   handles themselves are replaced.
            if ~obj.SetupComplete_ || obj.Refreshing_, return; end
            cleanup = obj.beginRefresh_(); %#ok<NASGU>
            obj.HoveredRow_ = 0;

            % Headers and cell graphics are children of SizingGrid, so one
            % delete clears the previous visual tree before handles reset.
            delete(obj.SizingGrid.Children);
            obj.HeaderGrids = cell(1,numel(obj.Columns_));
            obj.HeaderLabels = cell(1,numel(obj.Columns_));
            obj.CellGrids = cell(height(obj.Data_),numel(obj.Columns_));
            obj.CellControls = cell(size(obj.CellGrids));
            obj.EmptyLabel = [];

            if isempty(obj.Columns_)
                obj.SizingGrid.ColumnWidth = {'1x'};
                obj.SizingGrid.RowHeight = {obj.headerHeight_(),obj.RowHeight};
                obj.createEmptyLabel_();
                obj.applyLayout_();
                return
            end

            for column = 1:numel(obj.Columns_)
                definition = obj.Columns_(column);
                header = uigridlayout(obj.SizingGrid,[1 1], ...
                    ColumnWidth={'1x'},RowHeight={obj.headerNodeSize_()}, ...
                    Padding=obj.headerGridPadding_(), ...
                    RowSpacing=0,ColumnSpacing=0, ...
                    BackgroundColor=obj.HeaderBackgroundColor);
                header.Layout.Row = 1;
                header.Layout.Column = column;
                label = uilabel(header,Text=definition.Label, ...
                    BackgroundColor=obj.HeaderBackgroundColor, ...
                    FontColor=obj.FontColor,FontSize=obj.HeaderFontSize, ...
                    FontWeight='bold',VerticalAlignment='center');
                obj.HeaderGrids{column} = header;
                obj.HeaderLabels{column} = label;
            end

            if height(obj.Data_) == 0
                obj.createEmptyLabel_();
            else
                for row = 1:height(obj.Data_)
                    obj.createRowGraphics_(row);
                end
            end
            obj.applyLayout_();
            obj.applyAllRowAppearances_();
            obj.ensureHub_();
        end

        function createRowGraphics_(obj,row)
        %CREATEROWGRAPHICS_ Create and synchronize every cell in one row.
            rowID = obj.RowIDs(row);
            for column = 1:numel(obj.Columns_)
                definition = obj.Columns_(column);
                if definition.ControlType == "checkbox"
                    cellGrid = uigridlayout(obj.SizingGrid,[1 3], ...
                        ColumnWidth={'1x','fit','1x'});
                else
                    cellGrid = uigridlayout(obj.SizingGrid,[1 1], ...
                        ColumnWidth={'1x'});
                end
                cellGrid.RowHeight = {'1x'};
                cellGrid.Padding = obj.CellPadding;
                cellGrid.RowSpacing = 0;
                cellGrid.ColumnSpacing = 0;
                cellGrid.BackgroundColor = obj.baseRowColor_(row);
                setappdata(cellGrid,'matlabxControlTableCell',struct( ...
                    'TableID',obj.ID,'RowID',rowID, ...
                    'ColumnID',obj.ColumnIDs(column)));
                cellGrid.Layout.Row = row + 1;
                cellGrid.Layout.Column = column;
                control = obj.createControl_(cellGrid,rowID,obj.ColumnIDs(column));
                obj.CellGrids{row,column} = cellGrid;
                obj.CellControls{row,column} = control;
                obj.syncControl_(row,column);
            end
        end

        function control = createControl_(obj,parent,rowID,columnID)
        %CREATECONTROL_ Construct one native control and bind its stable IDs.
            [~,column] = obj.indicesForIDs_(rowID,columnID);
            definition = obj.Columns_(column);
            callback = @(source,~) obj.onControlEdited_(source,rowID,columnID);
            switch definition.ControlType
                case "dropdown"
                    control = uidropdown(parent,Items={''},ValueChangedFcn=callback);
                case "checkbox"
                    control = uicheckbox(parent,Text='',ValueChangedFcn=callback);
                case "text"
                    control = uieditfield(parent,'text',ValueChangedFcn=callback);
                case "numeric"
                    control = uieditfield(parent,'numeric',ValueChangedFcn=callback);
                case "color"
                    control = uicolorpicker(parent,ValueChangedFcn=callback);
            end
            control.Layout.Row = 1;
            if definition.ControlType == "checkbox"
                control.Layout.Column = 2;
            else
                control.Layout.Column = 1;
            end
            obj.applyControlAppearance_(control);
        end

        function syncControl_(obj,row,column)
        %SYNCCONTROL_ Apply current data, choices, validity, and enable state.
        %
        %   Dropdown values that are absent from their current choices keep
        %   their authoritative Data value. The visible control receives a
        %   temporary blank choice and an IsValid=false runtime marker until
        %   the user selects an allowed value.
            control = obj.CellControls{row,column};
            if isempty(control) || ~isvalid(control), return; end
            definition = obj.Columns_(column);
            value = obj.tableValue_(row,definition.Name);
            enabled = definition.Editable;
            if ~isempty(definition.EnabledFcn)
                result = definition.EnabledFcn( ...
                    obj.Data_(row,:),row,obj.Data_);
                if ~islogical(result) || ~isscalar(result)
                    error('matlabx:ui:control:ControlTable:InvalidEnabledResult', ...
                        'EnabledFcn for "%s" must return one logical value.',definition.Name);
                end
                enabled = enabled && result;
            end

            switch definition.ControlType
                case "dropdown"
                    [items,itemsData] = obj.dropdownItems_(definition,row);
                    labels = reshape(string(items),1,[]);
                    if isempty(itemsData)
                        choices = labels;
                    else
                        if numel(itemsData) ~= numel(labels)
                            error('matlabx:ui:control:ControlTable:ItemsSizeMismatch', ...
                                'ItemsFcn for "%s" returned unequal Items and ItemsData.',definition.Name);
                        end
                        choices = itemsData;
                    end
                    match = findChoice_(choices,value);
                    if match > 0
                        % Rebuild Items before assigning Value because MATLAB
                        % requires dropdown Value to exist in ItemsData.
                        control.ItemsData = {};
                        control.Items = cellstr(labels);
                        if ~isempty(itemsData), control.ItemsData = itemsData; end
                        control.Value = choiceAt_(choices,match);
                        obj.setChoiceValidity_(control,true,"");
                    else
                        % Preserve the unavailable Data value outside the
                        % control. A private sentinel backs the visible blank
                        % item until the user selects a valid replacement.
                        if isempty(labels), enabled = false; end
                        sentinel = obj.unavailableSentinel_(control);
                        control.ItemsData = {};
                        control.Items = cellstr([labels ""]);
                        control.ItemsData = [choicesToCells_(choices),{char(sentinel)}];
                        control.Value = char(sentinel);
                        obj.setChoiceValidity_(control,false,sentinel);
                    end
                case "checkbox"
                    control.Value = logical(value);
                case "text"
                    control.Value = char(string(value));
                case "numeric"
                    if ~isnumeric(value) || ~isscalar(value)
                        error('matlabx:ui:control:ControlTable:InvalidNumericValue', ...
                            'Column "%s" must contain numeric scalar values.',definition.Name);
                    end
                    control.Value = double(value);
                case "color"
                    if ~isnumeric(value) || ~isreal(value) || ...
                            ~isequal(size(value),[1 3]) || ...
                            any(~isfinite(value)) || any(value < 0 | value > 1)
                        error('matlabx:ui:control:ControlTable:InvalidColorValue', ...
                            'Column "%s" must contain one RGB triplet per row.', ...
                            definition.Name);
                    end
                    control.Value = double(value);
            end
            control.Enable = matlab.lang.OnOffSwitchState(enabled);
        end

        function [items,itemsData] = dropdownItems_(obj,definition,row)
        %DROPDOWNITEMS_ Resolve static or row-dependent dropdown choices.
            if ~isempty(definition.ItemsFcn)
                [items,itemsData] = definition.ItemsFcn( ...
                    obj.Data_(row,:),row,obj.Data_);
            else
                items = definition.Items;
                itemsData = definition.ItemsData;
            end
        end

        function sentinel = unavailableSentinel_(~,control)
        %UNAVAILABLESENTINEL_ Return the stable temporary dropdown sentinel.
            sentinel = "";
            if isappdata(control,'matlabxControlTableValueValidity')
                state = getappdata(control,'matlabxControlTableValueValidity');
                if isstruct(state) && isfield(state,'IsValid') && ...
                        ~state.IsValid && isfield(state,'Sentinel')
                    sentinel = string(state.Sentinel);
                end
            end
            if sentinel == ""
                sentinel = string(char(java.util.UUID.randomUUID()));
            end
        end

        function setChoiceValidity_(~,control,isValid,sentinel)
        %SETCHOICEVALIDITY_ Store dropdown validity metadata on a control.
            setappdata(control,'matlabxControlTableValueValidity',struct( ...
                'IsValid',logical(isValid),'Sentinel',string(sentinel)));
        end

        function tf = isUnavailableChoice_(~,control)
        %ISUNAVAILABLECHOICE_ Test whether a dropdown value is currently invalid.
            tf = false;
            if isappdata(control,'matlabxControlTableValueValidity')
                state = getappdata(control,'matlabxControlTableValueValidity');
                tf = isstruct(state) && isfield(state,'IsValid') && ~state.IsValid;
            end
        end

        function tf = isUnavailableSentinel_(~,control,value)
        %ISUNAVAILABLESENTINEL_ Test whether VALUE is the temporary blank choice.
            tf = false;
            if isappdata(control,'matlabxControlTableValueValidity')
                state = getappdata(control,'matlabxControlTableValueValidity');
                tf = isfield(state,'Sentinel') && ...
                    string(value) == string(state.Sentinel);
            end
        end

        function onControlEdited_(obj,control,rowID,columnID)
        %ONCONTROLEDITED_ Commit a native control edit and refresh dependencies.
        %
        %   Stable IDs are resolved at callback time so inserted or deleted
        %   rows do not invalidate existing callbacks. Internal controls are
        %   reconciled before CellEdited is emitted, ensuring listeners see a
        %   settled component with Refreshing=false.
            if obj.Refreshing_, return; end
            [row,column] = obj.indicesForIDs_(rowID,columnID);
            if row == 0 || column == 0, return; end
            if obj.isUnavailableChoice_(control) && ...
                    obj.isUnavailableSentinel_(control,control.Value)
                return
            end
            definition = obj.Columns_(column);
            oldValue = obj.tableValue_(row,definition.Name);
            newValue = control.Value;
            newValue = coerceValue_(newValue,oldValue);
            obj.setTableValue_(row,definition.Name,newValue);

            % Reconcile callback-driven controls before application code is
            % notified, so listeners never observe an intermediate UI state.
            eventData = matlabx.ui.control.ControlTableCellEditedData( ...
                row,column,definition.Name,oldValue,newValue);
            cleanup = obj.beginRefresh_(); %#ok<NASGU>
            obj.syncControl_(row,column);
            obj.refreshDynamicControls_(row,column);
            clear cleanup
            obj.SelectedRow = row;
            if isvalid(obj), notify(obj,'CellEdited',eventData); end
        end

        function refreshRowControls_(obj,row)
        %REFRESHROWCONTROLS_ Synchronize every control in one row.
            for column = 1:numel(obj.Columns_)
                obj.syncControl_(row,column);
            end
        end

        function refreshDynamicControls_(obj,skipRow,skipColumn)
        %REFRESHDYNAMICCONTROLS_ Reevaluate callback-driven columns in all rows.
        %
        %   Static controls are left untouched. SKIPROW and SKIPCOLUMN avoid
        %   repeating synchronization already performed for the edited cell.
            if nargin < 2, skipRow = 0; end
            if nargin < 3, skipColumn = 0; end
            dynamic = find(arrayfun(@(column) ...
                ~isempty(column.ItemsFcn) || ~isempty(column.EnabledFcn), ...
                obj.Columns_));
            for row = 1:height(obj.Data_)
                for column = dynamic
                    if row == skipRow && column == skipColumn, continue; end
                    obj.syncControl_(row,column);
                end
            end
        end

        function positionRowsFrom_(obj,firstRow)
        %POSITIONROWSFROM_ Update graphics row positions after a structural edit.
            for row = max(1,firstRow):height(obj.Data_)
                for column = 1:size(obj.CellGrids,2)
                    grid = obj.CellGrids{row,column};
                    if isvalidHandle_(grid), grid.Layout.Row = row + 1; end
                end
            end
        end

        function createEmptyLabel_(obj)
        %CREATEEMPTYLABEL_ Create the message spanning an empty table body.
            if isvalidHandle_(obj.EmptyLabel), return; end
            obj.EmptyLabel = uilabel(obj.SizingGrid,Text=obj.EmptyText, ...
                HorizontalAlignment='center',FontAngle='italic', ...
                BackgroundColor=obj.CellBackgroundColor, ...
                FontColor=obj.FontColor);
            obj.EmptyLabel.Layout.Row = 2;
            obj.EmptyLabel.Layout.Column = gridColumnSpan_(max(1,numel(obj.Columns_)));
        end

        function [row,column] = indicesForIDs_(obj,rowID,columnID)
        %INDICESFORIDS_ Resolve stable identities to current numeric indices.
            row = find(obj.RowIDs == string(rowID),1);
            column = find(obj.ColumnIDs == string(columnID),1);
            if isempty(row), row = 0; end
            if isempty(column), column = 0; end
        end

        function applyLayout_(obj)
        %APPLYLAYOUT_ Apply all border, spacing, sizing, and appearance settings.
            if isempty(obj.OuterGrid) || ~isvalid(obj.OuterGrid), return; end
            obj.OuterGrid.BackgroundColor = obj.BorderColor;
            obj.OuterGrid.Padding = obj.BorderWidth;
            obj.InnerGrid.BackgroundColor = obj.InnerBorderColor;
            obj.InnerGrid.Padding = obj.InnerBorderWidth;
            obj.SizingGrid.BackgroundColor = obj.CellBorderColor;
            obj.SizingGrid.Padding = obj.InnerPadding;
            obj.SizingGrid.RowSpacing = obj.RowSpacing;
            obj.SizingGrid.ColumnSpacing = obj.ColumnSpacing;
            obj.applySizingTracks_();
            for i = 1:numel(obj.HeaderGrids)
                if isvalidHandle_(obj.HeaderGrids{i})
                    obj.HeaderGrids{i}.RowHeight = {obj.headerNodeSize_()};
                    obj.HeaderGrids{i}.Padding = obj.headerGridPadding_();
                    obj.HeaderGrids{i}.BackgroundColor = obj.HeaderBackgroundColor;
                end
                if isvalidHandle_(obj.HeaderLabels{i})
                    obj.HeaderLabels{i}.BackgroundColor = obj.HeaderBackgroundColor;
                    obj.HeaderLabels{i}.FontColor = obj.FontColor;
                    obj.HeaderLabels{i}.FontSize = obj.HeaderFontSize;
                end
            end
            for i = 1:numel(obj.CellControls)
                if isvalidHandle_(obj.CellControls{i})
                    obj.applyControlAppearance_(obj.CellControls{i});
                end
            end
            for i = 1:numel(obj.CellGrids)
                if isvalidHandle_(obj.CellGrids{i})
                    obj.CellGrids{i}.Padding = obj.CellPadding;
                end
            end
            if isvalidHandle_(obj.EmptyLabel)
                obj.EmptyLabel.Text = obj.EmptyText;
                obj.EmptyLabel.BackgroundColor = obj.CellBackgroundColor;
                obj.EmptyLabel.FontColor = obj.FontColor;
            end
        end

        function applyControlAppearance_(obj,control)
        %APPLYCONTROLAPPEARANCE_ Apply supported colors to one native control.
            if isprop(control,'BackgroundColor')
                control.BackgroundColor = obj.ControlBackgroundColor;
            end
            if isprop(control,'FontColor')
                control.FontColor = obj.FontColor;
            end
        end

        function value = headerNodeSize_(obj)
        %HEADERNODESIZE_ Return the label row height inside a header cell.
            value = obj.HeaderFontSize + 6;
        end

        function value = headerHeight_(obj)
        %HEADERHEIGHT_ Return total header height including vertical padding.
            value = obj.headerNodeSize_() + 2*obj.HeaderPadding;
        end

        function value = headerGridPadding_(obj)
        %HEADERGRIDPADDING_ Return padding used to align header labels.
            value = [obj.HeaderPadding+5 obj.HeaderPadding 1 obj.HeaderPadding];
        end

        function applyAllRowAppearances_(obj)
        %APPLYALLROWAPPEARANCES_ Repaint every row interaction state.
            for row = 1:height(obj.Data_)
                obj.applyRowAppearance_(row);
            end
        end

        function applyRowAppearancesFrom_(obj,firstRow)
        %APPLYROWAPPEARANCESFROM_ Repaint rows affected by an index shift.
            for row = max(1,firstRow):height(obj.Data_)
                obj.applyRowAppearance_(row);
            end
        end

        function applySizingTracks_(obj)
        %APPLYSIZINGTRACKS_ Update shared column widths and body row heights.
            if isempty(obj.Columns_)
                obj.SizingGrid.ColumnWidth = {'1x'};
            else
                obj.SizingGrid.ColumnWidth = {obj.Columns_.Width};
            end
            rowCount = max(1,height(obj.Data_));
            obj.SizingGrid.RowHeight = [{obj.headerHeight_()}, ...
                repmat({obj.RowHeight},1,rowCount)];
        end

        function applyRowAppearance_(obj,row)
        %APPLYROWAPPEARANCE_ Paint every cell background in one row.
            if row < 1 || row > size(obj.CellGrids,1), return; end
            color = obj.resolveRowColor_(row);
            for column = 1:size(obj.CellGrids,2)
                cellGrid = obj.CellGrids{row,column};
                if isvalidHandle_(cellGrid), cellGrid.BackgroundColor = color; end
            end
        end

        function color = resolveRowColor_(obj,row)
        %RESOLVEROWCOLOR_ Choose the effective color for a row state.
            selected = row == obj.SelectedRow_;
            hovered = row == obj.HoveredRow_;
            if selected && hovered
                color = obj.SelectedHoverBackgroundColor;
            elseif selected
                color = obj.SelectedBackgroundColor;
            elseif hovered
                color = obj.HoverBackgroundColor;
            else
                color = obj.baseRowColor_(row);
            end
        end

        function color = baseRowColor_(obj,row)
        %BASEROWCOLOR_ Return the odd/even background color for ROW.
            if mod(row,2) == 0
                color = obj.AlternateRowColor;
            else
                color = obj.CellBackgroundColor;
            end
        end
    end

    %% FigureEventHub routing protocol
    methods
        function tf = matches(obj,event)
        %MATCHES Return true for a cell owned by this table instance.
            tf = string(obj.Visible) == "on" && ...
                obj.rowForTarget_(event.Target) > 0;
        end

        function onDown(obj,event)
        %ONDOWN Select the row containing the pointer target.
            row = obj.rowForTarget_(event.Target);
            if row > 0, obj.SelectedRow = row; end
        end

        function onMove(obj,event)
        %ONMOVE Update the row hover state.
            obj.updateHover_(obj.rowForTarget_(event.Target));
        end

        function onEnter(obj,event)
        %ONENTER Initialize hover when this table becomes the hub claimant.
            obj.updateHover_(obj.rowForTarget_(event.Target));
        end

        function onLeave(obj,~)
        %ONLEAVE Clear hover when this table releases hub ownership.
            obj.updateHover_(0);
        end

        function onUp(~,~)
        %ONUP Leave pointer-release behavior to native child controls.
        end

        function onScroll(~,~)
        %ONSCROLL Leave scrolling behavior to the containing scrollable grid.
        end

        function onKeyPress(~,~)
        %ONKEYPRESS Leave key-press behavior to the focused native control.
        end

        function onKeyRelease(~,~)
        %ONKEYRELEASE Leave key-release behavior to the focused native control.
        end
    end

    %% FigureEventHub registration lifecycle
    methods (Access=private)
        function ensureHub_(obj)
        %ENSUREHUB_ Register with the current ancestor figure's event hub.
            if ~obj.SetupComplete_, return; end
            fig = ancestor(obj,'figure');
            if isempty(fig) || ~isvalid(fig)
                obj.releaseHub_();
                return
            end
            if ~isempty(obj.HubFigure) && isvalid(obj.HubFigure) && isequal(obj.HubFigure,fig)
                return
            end
            obj.releaseHub_();
            obj.Hub = matlabx.ui.interaction.FigureEventHub.ensure(fig);
            obj.HubFigure = fig;
            obj.RouterId = obj.Hub.register(obj, ...
                'Priority',10,'CaptureDuringDrag',false);
        end

        function releaseHub_(obj)
        %RELEASEHUB_ Remove the current event-hub registration and hover.
            try
                if ~isempty(obj.Hub) && isvalid(obj.Hub)
                    obj.Hub.unregister(obj.RouterId);
                end
            catch
            end
            obj.Hub = [];
            obj.HubFigure = [];
            obj.RouterId = NaN;
            obj.updateHover_(0);
        end

        function updateHover_(obj,row)
        %UPDATEHOVER_ Change the hovered row and repaint only affected rows.
            old = obj.HoveredRow_;
            if old == row, return; end
            obj.HoveredRow_ = row;
            obj.applyRowAppearance_(old);
            obj.applyRowAppearance_(row);
        end

        function row = rowForTarget_(obj,target)
        %ROWFORTARGET_ Return the current row containing a graphics target.
            [row,~] = obj.cellIndicesForTarget_(target);
        end

        function [row,column] = cellIndicesForTarget_(obj,target)
        %CELLINDICESFORTARGET_ Walk target ancestors to find owned cell IDs.
        %
        %   Cell metadata contains stable IDs rather than numeric indices.
        %   Resolving IDs here keeps hover and selection correct after rows
        %   move without retagging every surviving graphics object.
            row = 0;
            column = 0;
            current = target;
            while ~isempty(current) && isvalidHandle_(current)
                try
                    if isappdata(current,'matlabxControlTableCell')
                        cellData = getappdata(current,'matlabxControlTableCell');
                        if isstruct(cellData) && isfield(cellData,'TableID') && ...
                                isfield(cellData,'RowID') && ...
                                isfield(cellData,'ColumnID') && ...
                                string(cellData.TableID) == obj.ID
                            [row,column] = obj.indicesForIDs_( ...
                                cellData.RowID,cellData.ColumnID);
                            return
                        end
                    end
                catch
                    % Some opaque event targets do not support application
                    % data. Continue with their graphics parent instead.
                end
                if isequal(current,obj), return; end
                try
                    current = current.Parent;
                catch
                    return
                end
            end
        end
    end

    %% Data helpers and callback guard
    methods (Access=private)
        function validateData_(~,data,columns)
        %VALIDATEDATA_ Require one table variable for every column definition.
            if isempty(columns), return; end
            missing = setdiff([columns.Name],string(data.Properties.VariableNames),'stable');
            if ~isempty(missing)
                error('matlabx:ui:control:ControlTable:MissingVariables', ...
                    'Data is missing column variables: %s.',strjoin(missing,', '));
            end
        end

        function validateRowIndex_(obj,index)
        %VALIDATEROWINDEX_ Require INDEX to identify an existing data row.
            if ~isscalar(index) || index ~= fix(index) || index < 1 || index > height(obj.Data_)
                error('matlabx:ui:control:ControlTable:InvalidRowIndex', ...
                    'Row index must identify an existing Data row.');
            end
        end

        function row = normalizeRow_(obj,row)
        %NORMALIZEROW_ Validate and reorder a one-row table for insertion.
            if ~istable(row) || height(row) ~= 1
                error('matlabx:ui:control:ControlTable:InvalidRow', ...
                    'Row data must be a one-row MATLAB table.');
            end
            required = string(obj.Data_.Properties.VariableNames);
            missing = setdiff(required,string(row.Properties.VariableNames));
            if ~isempty(missing)
                error('matlabx:ui:control:ControlTable:InvalidRow', ...
                    'Row data is missing variables: %s.',strjoin(missing,', '));
            end
            row = row(:,cellstr(required));
        end

        function value = tableValue_(obj,row,name)
        %TABLEVALUE_ Read one logical cell value from a table variable.
        %
        %   Cell variables are unwrapped; ordinary variables retain all
        %   columns in the requested row, allowing values such as RGB triplets.
            variable = obj.Data_.(name);
            if iscell(variable)
                value = variable{row};
            else
                value = variable(row,:);
                if isscalar(value), value = value(1); end
            end
        end

        function setTableValue_(obj,row,name,value)
        %SETTABLEVALUE_ Store one logical cell value in a table variable.
            variable = obj.Data_.(name);
            if iscell(variable)
                obj.Data_.(name){row} = value;
            else
                obj.Data_.(name)(row,:) = value;
            end
        end

        function row = nearestRow_(obj,row)
        %NEARESTROW_ Clamp a prior selection to the current data height.
            if height(obj.Data_) == 0 || row == 0
                row = 0;
            else
                row = min(row,height(obj.Data_));
            end
        end

        function cleanup = beginRefresh_(obj)
        %BEGINREFRESH_ Enter guarded synchronization until CLEANUP is cleared.
            obj.Refreshing_ = true;
            cleanup = onCleanup(@() obj.finishRefresh_());
        end

        function finishRefresh_(obj)
        %FINISHREFRESH_ Leave guarded synchronization if the component survives.
            if isvalid(obj), obj.Refreshing_ = false; end
        end
    end
end

function match = findChoice_(choices,value)
%FINDCHOICE_ Find VALUE without conflating textual and numeric choices.
    match = 0;
    for i = 1:numel(choices)
        choice = choiceAt_(choices,i);
        if isequaln(choice,value) || ...
                (isTextScalar_(choice) && isTextScalar_(value) && ...
                string(choice) == string(value)) || ...
                (isnumeric(choice) && isnumeric(value) && ...
                isscalar(choice) && isscalar(value) && ...
                isequaln(double(choice),double(value)))
            match = i;
            return
        end
    end
end

function tf = isTextScalar_(value)
%ISTEXTSCALAR_ Return true for one string or one character vector.
    tf = (isstring(value) && isscalar(value)) || ...
        (ischar(value) && (isrow(value) || isempty(value)));
end

function value = choiceAt_(choices,index)
%CHOICEAT_ Extract one dropdown value from cell or ordinary choice storage.
    if iscell(choices)
        value = choices{index};
    else
        value = choices(index);
    end
end

function value = coerceValue_(value,prototype)
%COERCEVALUE_ Preserve the table variable's scalar storage type after edits.
    if isstring(prototype)
        value = string(value);
    elseif ischar(prototype)
        value = char(string(value));
    elseif islogical(prototype)
        value = logical(value);
    elseif isnumeric(prototype)
        value = cast(value,'like',prototype);
    end
end

function tf = isvalidHandle_(value)
%ISVALIDHANDLE_ Test handle validity across graphics and handle-class values.
    tf = ~isempty(value);
    if ~tf, return; end
    try
        tf = isvalid(value);
    catch
        tf = isgraphics(value);
    end
end

function value = normalizeBorderWidth_(value,name)
%NORMALIZEBORDERWIDTH_ Expand scalar padding or validate a four-vector.
    validateattributes(value,{'numeric'}, ...
        {'real','finite','nonnegative','vector'},mfilename,name);
    if ~ismember(numel(value),[1 4])
        error('matlabx:ui:control:ControlTable:InvalidBorderWidth', ...
            '%s must be a scalar or a four-element padding vector.',name);
    end
    value = reshape(double(value),1,[]);
    if isscalar(value), value = repmat(value,1,4); end
end

function ids = newUUIDs_(count)
%NEWUUIDS_ Generate COUNT stable runtime string identifiers.
    ids = strings(1,count);
    for i = 1:count
        ids(i) = string(char(java.util.UUID.randomUUID()));
    end
end

function values = choicesToCells_(choices)
%CHOICESTOCELLS_ Convert dropdown values to a row cell array.
    values = cell(1,numel(choices));
    for i = 1:numel(choices)
        values{i} = choiceAt_(choices,i);
    end
end

function span = gridColumnSpan_(columnCount)
%GRIDCOLUMNSPAN_ Return a valid scalar or two-endpoint grid span.
    if columnCount == 1
        span = 1;
    else
        span = [1 columnCount];
    end
end
