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
%   SelectionMode controls single- or multiple-row interaction. ActiveRow is
%   the primary row for single-row operations, while SelectedRows is the
%   complete ordered batch target. Reorderable adds a structural grip column;
%   row moves preserve RowIDs and selection identity.
%   RowOperationRequestedFcn can cancel add, duplicate, remove, and reorder
%   operations before any table state changes.
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
        % Selection policy used by pointer gestures and assignments.
        SelectionMode (1,1) string
        % Primary selected row index, or zero when selection is empty.
        ActiveRow (1,1) double
        % Ordered numeric indices of every selected row.
        SelectedRows (1,:) double
        % Whether row grips and drag reordering are available.
        Reorderable (1,1) logical
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
        % Stable identity of the active row, or empty string.
        ActiveRowID (1,1) string = ""
        % Stable identities of all selected rows in table order.
        SelectedRowIDs (1,:) string = string.empty(1,0)
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
        % Relative luminance adjustment applied only to the active row.
        ActiveTint (1,1) double {mustBeBetween(ActiveTint,0,1)} = 0.10
        % Background used to indicate the current reorder destination.
        DropTargetBackgroundColor (1,3) double {mustBeBetween(DropTargetBackgroundColor,0,1)} = [1.0 0.45 0.0]
        % Minimum thickness of the expanded insertion slot during dragging.
        DropTargetThickness (1,1) double {mustBePositive} = 1
        % Width in pixels of the optional row-reorder grip column.
        GripWidth (1,1) double {mustBePositive} = 24
        % Pointer travel required before a primed grip begins dragging.
        DragThreshold (1,1) double {mustBeNonnegative} = 4
        % Optional factory returning a compatible one-row table.
        NewRowFcn = []
    end

    events (HasCallbackProperty, NotifyAccess=protected)
        % Emitted once after a user edit is stored in Data.
        CellEdited
        % Emitted once after a complete selection transition.
        SelectionChanged
        % Requested before a structural row operation is committed.
        RowOperationRequested
        % Emitted after a row is created by addRow or addNewRow.
        RowAdded
        % Emitted after a row is duplicated.
        RowDuplicated
        % Emitted after one or more rows are removed.
        RowsRemoved
        % Emitted after one row is moved to a new position.
        RowReordered
    end

    %% State and graphics

    % Private backing values and guards for dependent public properties.
    properties (Access=private)
        % Normalized column definitions currently used by the table.
        Columns_ (1,:) matlabx.ui.control.ControlTableColumn = ...
            matlabx.ui.control.ControlTableColumn.empty(1,0)
        % Authoritative table data backing the public Data property.
        Data_ table = table()
        % Backing selection policy.
        SelectionMode_ (1,1) string = "single"
        % Stable selected identities; numeric indices are derived on demand.
        SelectedRowIDs_ (1,:) string = string.empty(1,0)
        % Stable identity of the primary selected row.
        ActiveRowID_ (1,1) string = ""
        % Stable identity from which shift-selection ranges are extended.
        AnchorRowID_ (1,1) string = ""
        % Backing state for the structural grip column.
        Reorderable_ (1,1) logical = false
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
        % Header cell occupying the optional structural grip column.
        GripHeader = []
        % Per-row grid containers hosting reorder grip icons.
        GripGrids cell = {}
        % Per-row reorder grip image handles.
        GripImages cell = {}
        % Row-by-column cell grid containers.
        CellGrids cell = {}
        % Individually paintable insertion slots surrounding data rows.
        DropSlotPanels cell = {}
        % Row-by-column native control handles.
        CellControls cell = {}
        % Empty-state label shown when Data has no rows.
        EmptyLabel = []
        % Built-in context menu attached to table-owned graphics.
        BuiltInContextMenu_ = []
        % Named handles for enabling and disabling built-in menu actions.
        ContextMenuItems struct = struct()
    end

    % FigureEventHub registration state for pointer routing.
    properties (Access=private)
        % Figure event hub serving the current ancestor figure.
        Hub = []
        % Figure associated with Hub.
        HubFigure = []
        % Registration identifier returned by FigureEventHub.
        RouterId (1,1) double = NaN
        % Whether a grip press is waiting to cross the drag threshold.
        DragPrimed_ (1,1) logical = false
        % Whether the current grip gesture has crossed the drag threshold.
        Dragging_ (1,1) logical = false
        % Stable identity of the row participating in a grip drag.
        DragRowID_ (1,1) string = ""
        % Figure-coordinate pointer position at the initial grip press.
        DragStartPoint_ (1,2) double = [NaN NaN]
        % Current insertion slot highlighted as the reorder destination.
        DropTargetSlot_ (1,1) double = 0
        % Whether this component currently owns the figure pointer shape.
        PointerOwned_ (1,1) logical = false
        % Figure pointer name saved before showing grip feedback.
        PreviousPointer_ (1,1) string = "arrow"
        % Custom pointer pixels saved when replacing an existing custom cursor.
        PreviousPointerShapeCData_ = []
        % Custom pointer hotspot saved when replacing an existing custom cursor.
        PreviousPointerShapeHotSpot_ = []
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
                'RowSpacing',0, ...
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
                obj.cancelDrag_();
            end
            obj.ensureHub_();
        end
    end

    methods
        function delete(obj)
        %DELETE Release the FigureEventHub registration.
            obj.releaseHub_();
            if isvalidHandle_(obj.BuiltInContextMenu_)
                delete(obj.BuiltInContextMenu_);
            end
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
                'GripHeader',obj.GripHeader, ...
                'GripGrids',{obj.GripGrids}, ...
                'GripImages',{obj.GripImages}, ...
                'CellGrids',{obj.CellGrids}, ...
                'Controls',{obj.CellControls}, ...
                'EmptyLabel',obj.EmptyLabel, ...
                'HoveredRow',obj.HoveredRow_, ...
                'DropTargetSlot',obj.DropTargetSlot_, ...
                'DropSlotPanels',{obj.DropSlotPanels}, ...
                'ContextMenu',obj.BuiltInContextMenu_, ...
                'ContextMenuItems',obj.ContextMenuItems, ...
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
                obj.updateGripPointer_(target);
            elseif action == "down" && row > 0
                obj.ActiveRow = row;
            end
        end

        function debugSelectionGesture(obj,row,modifiers,isContext)
        %DEBUGSELECTIONGESTURE Exercise selection gestures without a pointer.
            arguments
                obj
                row (1,1) double
                modifiers (1,:) string = string.empty(1,0)
                isContext (1,1) logical = false
            end
            obj.validateRowIndex_(row);
            obj.applySelectionFlags_(row,isContext, ...
                any(ismember(modifiers,["meta","control"])), ...
                ismember("shift",modifiers));
        end

        function debugDropTarget(obj,slot)
        %DEBUGDROPTARGET Display or clear an insertion target for diagnostics.
            if ~isscalar(slot) || slot~=fix(slot) || slot<0 || ...
                    slot>numel(obj.DropSlotPanels)
                error('matlabx:ui:control:ControlTable:InvalidDropSlot', ...
                    'Drop slot must be zero or a current insertion slot.');
            end
            obj.updateDropTarget_(slot);
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
            oldState = obj.selectionState_();
            obj.SelectedRowIDs_ = string.empty(1,0);
            obj.ActiveRowID_ = "";
            obj.AnchorRowID_ = "";
            obj.publishSelectionProperties_();
            if obj.SetupComplete_, obj.rebuild_(); end
            obj.notifySelectionChange_(oldState);
        end

        function value = get.SelectionMode(obj)
        %GET.SELECTIONMODE Return the current single- or multiple-row policy.
            value = obj.SelectionMode_;
        end

        function set.SelectionMode(obj,value)
        %SET.SELECTIONMODE Change the gesture policy and normalize selection.
            value = string(value);
            if ~isscalar(value) || ~ismember(value,["single","multiple"])
                error('matlabx:ui:control:ControlTable:InvalidSelectionMode', ...
                    'SelectionMode must be "single" or "multiple".');
            end
            if obj.SelectionMode_ == value, return; end
            obj.SelectionMode_ = value;
            if value == "single" && numel(obj.SelectedRowIDs_) > 1
                active = obj.ActiveRowID_;
                if active == "", active = obj.SelectedRowIDs_(1); end
                obj.setSelectionByIDs_(active,active,active,true);
            end
            obj.refreshContextMenu_();
        end

        function value = get.ActiveRow(obj)
        %GET.ACTIVEROW Resolve the primary stable identity to a numeric row.
            value = obj.rowForID_(obj.ActiveRowID_);
        end

        function set.ActiveRow(obj,value)
        %SET.ACTIVEROW Select and activate one row, or clear with zero.
            value = obj.validateSelectionRows_(value,true);
            if value == 0
                obj.setSelectionByIDs_(string.empty(1,0),"","",true);
            else
                id = obj.RowIDs(value);
                selected = obj.SelectedRowIDs_;
                if ~ismember(id,selected)
                    if obj.SelectionMode_ == "single", selected = id;
                    else, selected(end+1) = id; end
                end
                obj.setSelectionByIDs_(selected,id,id,true);
            end
        end

        function value = get.SelectedRows(obj)
        %GET.SELECTEDROWS Return selected numeric indices in table order.
            value = obj.rowsForIDs_(obj.SelectedRowIDs_);
        end

        function set.SelectedRows(obj,value)
        %SET.SELECTEDROWS Replace the complete selected-row set.
            rows = obj.validateSelectionRows_(value,false);
            ids = obj.RowIDs(rows);
            if isempty(ids)
                active = "";
            elseif ismember(obj.ActiveRowID_,ids)
                active = obj.ActiveRowID_;
            else
                active = ids(1);
            end
            obj.setSelectionByIDs_(ids,active,active,true);
        end

        function value = get.Reorderable(obj)
        %GET.REORDERABLE Return whether row grips are displayed.
            value = obj.Reorderable_;
        end

        function set.Reorderable(obj,value)
        %SET.REORDERABLE Show or remove structural row-reordering grips.
            value = logical(value);
            if ~isscalar(value)
                error('matlabx:ui:control:ControlTable:InvalidReorderable', ...
                    'Reorderable must be a logical scalar.');
            end
            if obj.Reorderable_ == value, return; end
            obj.Reorderable_ = value;
            obj.cancelDrag_();
            if obj.SetupComplete_, obj.rebuild_(); end
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
            index = height(obj.Data_)+1;
            [rowID,rowData] = obj.prepareAdd_(index,rowData);
            if rowID == "", return; end
            rowID = obj.insertRowCore_(index,rowData,rowID);
            notify(obj,'RowAdded',matlabx.ui.control.ControlTableRowsChangedData( ...
                rowID,string.empty(1,0),double.empty(1,0),index));
        end

        function insertRow(obj,index,rowData)
        %INSERTROW Insert one compatible table row before INDEX.
            [rowID,rowData] = obj.prepareAdd_(index,rowData);
            if rowID == "", return; end
            rowID = obj.insertRowCore_(index,rowData,rowID);
            notify(obj,'RowAdded',matlabx.ui.control.ControlTableRowsChangedData( ...
                rowID,string.empty(1,0),double.empty(1,0),index));
        end

        function removeRow(obj,index)
        %REMOVEROW Remove one row and keep selection on a nearby row.
            obj.validateRowIndex_(index);
            obj.removeRows_(index);
        end

        function rowID = addNewRow(obj)
        %ADDNEWROW Create and append a row using NewRowFcn.
            if isempty(obj.NewRowFcn)
                error('matlabx:ui:control:ControlTable:MissingNewRowFcn', ...
                    'NewRowFcn must be assigned before calling addNewRow.');
            end
            row = obj.NewRowFcn(obj);
            index = height(obj.Data_)+1;
            [rowID,row] = obj.prepareAdd_(index,row);
            if rowID == "", return; end
            rowID = obj.insertRowCore_(index,row,rowID);
            notify(obj,'RowAdded',matlabx.ui.control.ControlTableRowsChangedData( ...
                rowID,string.empty(1,0),double.empty(1,0),index));
        end

        function rowID = duplicateRow(obj,index)
        %DUPLICATEROW Insert a copy after INDEX with a new stable identity.
            obj.validateRowIndex_(index);
            sourceID = obj.RowIDs(index);
            newIndex = index+1;
            row = obj.Data_(index,:);
            request = matlabx.ui.control.ControlTableRowOperationData( ...
                "duplicate",sourceID,index,index,newIndex,row);
            if ~obj.requestOperation_(request)
                rowID = "";
                return
            end
            rowID = obj.insertRowCore_(newIndex,row,newUUIDs_(1));
            obj.setSelectionByIDs_(rowID,rowID,rowID,true);
            notify(obj,'RowDuplicated',matlabx.ui.control.ControlTableRowsChangedData( ...
                rowID,sourceID,index,newIndex));
        end

        function rowID = duplicateActiveRow(obj)
        %DUPLICATEACTIVEROW Duplicate the current active row.
            if obj.ActiveRow == 0
                error('matlabx:ui:control:ControlTable:NoActiveRow', ...
                    'No row is active.');
            end
            rowID = obj.duplicateRow(obj.ActiveRow);
        end

        function removeSelectedRows(obj)
        %REMOVESELECTEDROWS Delete the complete selected row set in one operation.
            obj.removeRows_(obj.SelectedRows);
        end

        function moveRow(obj,oldIndex,newIndex)
        %MOVEROW Move one logical row while preserving its stable identity.
            obj.validateRowIndex_(oldIndex);
            obj.validateRowIndex_(newIndex);
            if oldIndex == newIndex, return; end
            rowID = obj.RowIDs(oldIndex);
            request = matlabx.ui.control.ControlTableRowOperationData( ...
                "reorder",rowID,oldIndex,oldIndex,newIndex,obj.Data_(oldIndex,:));
            if ~obj.requestOperation_(request), return; end
            obj.cancelDrag_();
            oldState = obj.selectionState_();
            order = 1:height(obj.Data_);
            moved = order(oldIndex);
            order(oldIndex) = [];
            order = [order(1:newIndex-1),moved,order(newIndex:end)];
            obj.Data_ = obj.Data_(order,:);
            obj.RowIDs = obj.RowIDs(order);
            obj.SelectedRowIDs_ = obj.RowIDs(ismember(obj.RowIDs,obj.SelectedRowIDs_));
            obj.CellGrids = obj.CellGrids(order,:);
            obj.CellControls = obj.CellControls(order,:);
            if obj.Reorderable_
                obj.GripGrids = obj.GripGrids(order);
                obj.GripImages = obj.GripImages(order);
            end
            obj.positionRowsFrom_(min(oldIndex,newIndex));
            obj.refreshDynamicControls_();
            obj.applyRowAppearancesFrom_(min(oldIndex,newIndex));
            obj.publishSelectionProperties_();
            obj.notifySelectionChange_(oldState);
            notify(obj,'RowReordered', ...
                matlabx.ui.control.ControlTableRowReorderedData(rowID,oldIndex,newIndex));
        end

        function selectAll(obj)
        %SELECTALL Select every row when multiple selection is enabled.
            if obj.SelectionMode_ ~= "multiple"
                error('matlabx:ui:control:ControlTable:SingleSelection', ...
                    'selectAll requires SelectionMode="multiple".');
            end
            active = obj.ActiveRowID_;
            if active == "" && ~isempty(obj.RowIDs), active = obj.RowIDs(1); end
            obj.setSelectionByIDs_(obj.RowIDs,active,active,true);
        end

        function clearSelection(obj)
        %CLEARSELECTION Clear active, selected, and range-anchor state.
            obj.setSelectionByIDs_(string.empty(1,0),"","",true);
        end

        function invertSelection(obj)
        %INVERTSELECTION Select precisely the rows not currently selected.
            if obj.SelectionMode_ ~= "multiple"
                error('matlabx:ui:control:ControlTable:SingleSelection', ...
                    'invertSelection requires SelectionMode="multiple".');
            end
            ids = obj.RowIDs(~ismember(obj.RowIDs,obj.SelectedRowIDs_));
            active = obj.promoteActiveID_(ids,obj.ActiveRow);
            obj.setSelectionByIDs_(ids,active,active,true);
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
            obj.cancelDrag_();
            obj.HoveredRow_ = 0;

            % Headers and cell graphics are children of SizingGrid, so one
            % delete clears the previous visual tree before handles reset.
            delete(obj.SizingGrid.Children);
            obj.HeaderGrids = cell(1,numel(obj.Columns_));
            obj.HeaderLabels = cell(1,numel(obj.Columns_));
            obj.GripHeader = [];
            obj.GripGrids = cell(height(obj.Data_),1);
            obj.GripImages = cell(height(obj.Data_),1);
            obj.CellGrids = cell(height(obj.Data_),numel(obj.Columns_));
            obj.CellControls = cell(size(obj.CellGrids));
            obj.DropSlotPanels = cell(max(0,height(obj.Data_)+1),1);
            obj.EmptyLabel = [];

            if isempty(obj.Columns_)
                obj.SizingGrid.ColumnWidth = {'1x'};
                obj.SizingGrid.RowHeight = {obj.headerHeight_(),obj.RowHeight};
                obj.createEmptyLabel_();
                obj.applyLayout_();
                return
            end

            if obj.Reorderable_
                obj.GripHeader = uigridlayout(obj.SizingGrid,[1 1], ...
                    Padding=0,RowSpacing=0,ColumnSpacing=0, ...
                    BackgroundColor=obj.HeaderBackgroundColor);
                obj.GripHeader.Layout.Row = 1;
                obj.GripHeader.Layout.Column = 1;
            end
            columnOffset = double(obj.Reorderable_);
            for column = 1:numel(obj.Columns_)
                definition = obj.Columns_(column);
                header = uigridlayout(obj.SizingGrid,[1 1], ...
                    ColumnWidth={'1x'},RowHeight={obj.headerNodeSize_()}, ...
                    Padding=obj.headerGridPadding_(), ...
                    RowSpacing=0,ColumnSpacing=0, ...
                    BackgroundColor=obj.HeaderBackgroundColor);
                header.Layout.Row = 1;
                header.Layout.Column = column + columnOffset;
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
                for slot = 1:height(obj.Data_)+1
                    obj.createDropSlot_(slot);
                end
                for row = 1:height(obj.Data_)
                    obj.createRowGraphics_(row);
                end
            end
            obj.applyLayout_();
            obj.applyAllRowAppearances_();
            obj.ensureHub_();
            obj.attachContextMenu_();
        end

        function createRowGraphics_(obj,row)
        %CREATEROWGRAPHICS_ Create and synchronize every cell in one row.
            rowID = obj.RowIDs(row);
            columnOffset = double(obj.Reorderable_);
            if obj.Reorderable_
                gripGrid = uigridlayout(obj.SizingGrid,[1 1], ...
                    Padding=[2 2 2 2],RowSpacing=0,ColumnSpacing=0, ...
                    BackgroundColor=obj.baseRowColor_(row));
                gripGrid.Layout.Row = obj.dataTrack_(row);
                gripGrid.Layout.Column = 1;
                metadata = struct('TableID',obj.ID,'RowID',rowID, ...
                    'ColumnID',"",'IsGrip',true);
                setappdata(gripGrid,'matlabxControlTableCell',metadata);
                grip = uiimage(gripGrid,ScaleMethod='fit',BackgroundColor='none');
                grip.Layout.Row = 1;
                grip.Layout.Column = 1;
                setappdata(grip,'matlabxControlTableCell',metadata);
                obj.GripGrids{row} = gripGrid;
                obj.GripImages{row} = grip;
            end
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
                    'ColumnID',obj.ColumnIDs(column),'IsGrip',false));
                cellGrid.Layout.Row = obj.dataTrack_(row);
                cellGrid.Layout.Column = column + columnOffset;
                control = obj.createControl_(cellGrid,rowID,obj.ColumnIDs(column));
                obj.CellGrids{row,column} = cellGrid;
                obj.CellControls{row,column} = control;
                obj.syncControl_(row,column);
            end
        end

        function createDropSlot_(obj,slot)
        %CREATEDROPSLOT_ Create one independently paintable insertion gap.
            panel = uipanel(obj.SizingGrid,BorderType='none', ...
                BackgroundColor=obj.CellBorderColor);
            panel.Layout.Row = obj.slotTrack_(slot);
            panel.Layout.Column = gridColumnSpan_( ...
                max(1,numel(obj.Columns_)+double(obj.Reorderable_)));
            setappdata(panel,'matlabxControlTableDropSlot',obj.ID);
            obj.DropSlotPanels{slot} = panel;
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
            obj.ActiveRow = row;
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
                if obj.Reorderable_ && isvalidHandle_(obj.GripGrids{row})
                    obj.GripGrids{row}.Layout.Row = obj.dataTrack_(row);
                end
                for column = 1:size(obj.CellGrids,2)
                    grid = obj.CellGrids{row,column};
                    if isvalidHandle_(grid), grid.Layout.Row = obj.dataTrack_(row); end
                end
            end
        end

        function positionDropSlotsFrom_(obj,firstSlot)
        %POSITIONDROPSLOTSFROM_ Reposition insertion gaps after structure changes.
            for slot = max(1,firstSlot):numel(obj.DropSlotPanels)
                if isvalidHandle_(obj.DropSlotPanels{slot})
                    obj.DropSlotPanels{slot}.Layout.Row = obj.slotTrack_(slot);
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
            obj.EmptyLabel.Layout.Column = gridColumnSpan_( ...
                max(1,numel(obj.Columns_)+double(obj.Reorderable_)));
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
            obj.SizingGrid.RowSpacing = 0;
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
            for slot = 1:numel(obj.DropSlotPanels)
                obj.applyDropSlotAppearance_(slot);
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
                widths = {obj.Columns_.Width};
                if obj.Reorderable_, widths = [{obj.GripWidth},widths]; end
                obj.SizingGrid.ColumnWidth = widths;
            end
            if height(obj.Data_) == 0
                obj.SizingGrid.RowHeight = {obj.headerHeight_(),obj.RowHeight};
                return
            end
            tracks = cell(1,2*height(obj.Data_)+1);
            for slot = 1:height(obj.Data_)+1
                % The old grid had spacing before the first data row and
                % between data rows, but no trailing space after the final
                % row. Keep the last insertion slot collapsed until it is
                % used as the active drop target.
                if slot == height(obj.Data_)+1
                    thickness = 0;
                else
                    thickness = obj.RowSpacing;
                end
                if slot == obj.DropTargetSlot_
                    thickness = max(thickness,obj.DropTargetThickness);
                end
                tracks{2*slot-1} = thickness;
                if slot <= height(obj.Data_), tracks{2*slot} = obj.RowHeight; end
            end
            obj.SizingGrid.RowHeight = [{obj.headerHeight_()},tracks];
        end

        function applyRowAppearance_(obj,row)
        %APPLYROWAPPEARANCE_ Paint every cell background in one row.
            if row < 1 || row > size(obj.CellGrids,1), return; end
            color = obj.resolveRowColor_(row);
            if obj.Reorderable_ && row <= numel(obj.GripGrids)
                if isvalidHandle_(obj.GripGrids{row})
                    obj.GripGrids{row}.BackgroundColor = color;
                end
                if isvalidHandle_(obj.GripImages{row})
                    obj.GripImages{row}.ImageSource = obj.gripIcon_(color);
                end
            end
            for column = 1:size(obj.CellGrids,2)
                cellGrid = obj.CellGrids{row,column};
                if isvalidHandle_(cellGrid), cellGrid.BackgroundColor = color; end
            end
        end

        function applyDropSlotAppearance_(obj,slot)
        %APPLYDROPSLOTAPPEARANCE_ Paint one normal or active insertion gap.
            if slot < 1 || slot > numel(obj.DropSlotPanels), return; end
            panel = obj.DropSlotPanels{slot};
            if ~isvalidHandle_(panel), return; end
            if slot == obj.DropTargetSlot_
                panel.BackgroundColor = obj.DropTargetBackgroundColor;
            else
                panel.BackgroundColor = obj.CellBorderColor;
            end
        end

        function track = dataTrack_(~,row)
        %DATATRACK_ Map a logical data row to its interleaved grid track.
            track = 2*row+1;
        end

        function track = slotTrack_(~,slot)
        %SLOTTRACK_ Map an insertion slot to its interleaved grid track.
            track = 2*slot;
        end

        function color = resolveRowColor_(obj,row)
        %RESOLVEROWCOLOR_ Choose the effective color for a row state.
            if obj.Dragging_ && obj.RowIDs(row) == obj.DragRowID_
                color = obj.DropTargetBackgroundColor;
                return
            end
            selected = ismember(obj.RowIDs(row),obj.SelectedRowIDs_);
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
            if obj.RowIDs(row) == obj.ActiveRowID_
                color = tintColor_(color,obj.ActiveTint);
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
        %ONDOWN Apply row selection or prime a reorder grip drag.
            row = obj.rowForTarget_(event.Target);
            if row == 0, return; end
            if obj.isGripTarget_(event.Target) && obj.Reorderable_
                obj.applyPointerSelection_(row,event);
                obj.DragPrimed_ = true;
                obj.DragRowID_ = obj.RowIDs(row);
                obj.DragStartPoint_ = event.CurrentPointFigure;
                return
            end
            obj.applyPointerSelection_(row,event);
        end

        function onMove(obj,event)
        %ONMOVE Update the row hover state.
            row = obj.rowForTarget_(event.Target);
            if ~obj.Dragging_, obj.updateHover_(row); end
            if obj.DragPrimed_ && ~obj.Dragging_
                delta = event.CurrentPointFigure - obj.DragStartPoint_;
                obj.Dragging_ = all(isfinite(delta)) && norm(delta) >= obj.DragThreshold;
                if obj.Dragging_
                    % Once dragging begins, the insertion slot and source
                    % row provide all feedback; ordinary hover is suppressed.
                    obj.updateHover_(0);
                    obj.applyRowAppearance_(obj.rowForID_(obj.DragRowID_));
                end
            end
            if obj.Dragging_
                obj.updateDropTarget_(obj.dropSlotForEvent_(event,row));
            end
            obj.updateGripPointer_(event.Target);
        end

        function onEnter(obj,event)
        %ONENTER Initialize hover when this table becomes the hub claimant.
            if ~obj.Dragging_
                obj.updateHover_(obj.rowForTarget_(event.Target));
            end
            obj.updateGripPointer_(event.Target);
        end

        function onLeave(obj,~)
        %ONLEAVE Clear hover when this table releases hub ownership.
            obj.updateHover_(0);
            if ~obj.Dragging_, obj.restorePointer_(); end
        end

        function onUp(obj,event)
        %ONUP Commit a valid row drop or cancel a primed grip gesture.
            if ~obj.DragPrimed_, return; end
            destinationSlot = obj.dropSlotForEvent_(event,obj.rowForTarget_(event.Target));
            source = obj.rowForID_(obj.DragRowID_);
            dragging = obj.Dragging_;
            obj.cancelDrag_();
            obj.updateHover_(obj.rowForTarget_(event.Target));
            obj.updateGripPointer_(event.Target);
            if dragging && source > 0 && destinationSlot > 0
                destination = destinationSlot - double(destinationSlot > source);
                if source ~= destination, obj.moveRow(source,destination); end
            end
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
                'Priority',10,'CaptureDuringDrag',true);
            obj.ensureContextMenu_(fig);
        end

        function releaseHub_(obj)
        %RELEASEHUB_ Remove the current event-hub registration and hover.
            % Restore any cursor claimed by this table while the old figure
            % reference is still available.
            obj.cancelDrag_();
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

        function tf = isGripTarget_(obj,target)
        %ISGRIPTARGET_ Return true when TARGET belongs to this table's grip.
            tf = false;
            current = target;
            while ~isempty(current) && isvalidHandle_(current)
                try
                    if isappdata(current,'matlabxControlTableCell')
                        metadata = getappdata(current,'matlabxControlTableCell');
                        tf = isfield(metadata,'TableID') && ...
                            string(metadata.TableID) == obj.ID && ...
                            isfield(metadata,'IsGrip') && metadata.IsGrip;
                        return
                    end
                    current = current.Parent;
                catch
                    return
                end
            end
        end

        function applyPointerSelection_(obj,row,event)
        %APPLYPOINTERSELECTION_ Apply explorer-style selection modifiers.
            isContext = string(event.MouseAction) == "contextclick";
            toggle = event.hasModifier("meta") || event.hasModifier("control");
            extend = event.hasModifier("shift");
            obj.applySelectionFlags_(row,isContext,toggle,extend);
        end

        function applySelectionFlags_(obj,row,isContext,toggle,extend)
        %APPLYSELECTIONFLAGS_ Commit one normalized explorer-style gesture.
            clickedID = obj.RowIDs(row);
            if isContext
                if ismember(clickedID,obj.SelectedRowIDs_)
                    obj.setSelectionByIDs_(obj.SelectedRowIDs_,clickedID, ...
                        obj.AnchorRowID_,true);
                else
                    obj.setSelectionByIDs_(clickedID,clickedID,clickedID,true);
                end
                return
            end
            if obj.SelectionMode_ == "single"
                obj.setSelectionByIDs_(clickedID,clickedID,clickedID,true);
                return
            end
            anchor = obj.rowForID_(obj.AnchorRowID_);
            if anchor == 0, anchor = row; end
            if extend
                range = min(anchor,row):max(anchor,row);
                rangeIDs = obj.RowIDs(range);
                if toggle
                    selected = setxor(obj.SelectedRowIDs_,rangeIDs,'stable');
                else
                    selected = rangeIDs;
                end
                active = clickedID;
                if ~ismember(active,selected)
                    active = obj.promoteActiveID_(selected,row);
                end
                obj.setSelectionByIDs_(selected,active,obj.RowIDs(anchor),true);
            elseif toggle
                selected = obj.SelectedRowIDs_;
                if ismember(clickedID,selected)
                    selected(selected == clickedID) = [];
                    if obj.ActiveRowID_ == clickedID
                        active = obj.promoteActiveID_(selected,row);
                    else
                        active = obj.ActiveRowID_;
                    end
                else
                    selected(end+1) = clickedID;
                    active = clickedID;
                end
                obj.setSelectionByIDs_(selected,active,clickedID,true);
            else
                obj.setSelectionByIDs_(clickedID,clickedID,clickedID,true);
            end
        end

        function slot = dropSlotForEvent_(obj,event,row)
        %DROPSLOTFOREVENT_ Resolve a pointer to the nearest insertion gap.
            slot = obj.dropSlotForTarget_(event.Target);
            if slot > 0 || row == 0, return; end

            % A cursor over the upper half of a row targets the gap before
            % it; the lower half targets the following gap.
            target = [];
            if obj.Reorderable_ && isvalidHandle_(obj.GripGrids{row})
                target = obj.GripGrids{row};
            elseif ~isempty(obj.CellGrids) && isvalidHandle_(obj.CellGrids{row,1})
                target = obj.CellGrids{row,1};
            end
            if isempty(target), return; end
            try
                bounds = getpixelposition(target,true);
                belowMidpoint = event.CurrentPointFigure(2) < bounds(2)+bounds(4)/2;
                slot = row + double(belowMidpoint);
            catch
                slot = row;
            end
        end

        function slot = dropSlotForTarget_(obj,target)
        %DROPSLOTFORTARGET_ Find an owned insertion slot in target ancestry.
            slot = 0;
            current = target;
            while ~isempty(current) && isvalidHandle_(current)
                try
                    if isappdata(current,'matlabxControlTableDropSlot') && ...
                            string(getappdata(current,'matlabxControlTableDropSlot')) == obj.ID
                        for i = 1:numel(obj.DropSlotPanels)
                            if isvalidHandle_(obj.DropSlotPanels{i}) && ...
                                    isequal(current,obj.DropSlotPanels{i})
                                slot = i;
                                return
                            end
                        end
                    end
                    current = current.Parent;
                catch
                    return
                end
            end
        end

        function updateDropTarget_(obj,slot)
        %UPDATEDROPTARGET_ Repaint and resize the active insertion slot.
            old = obj.DropTargetSlot_;
            if old == slot, return; end
            obj.DropTargetSlot_ = slot;
            obj.applyDropSlotAppearance_(old);
            obj.applyDropSlotAppearance_(slot);
            obj.applySizingTracks_();
        end

        function cancelDrag_(obj)
        %CANCELDRAG_ Clear all primed and active reorder state.
            old = obj.DropTargetSlot_;
            draggedRow = obj.rowForID_(obj.DragRowID_);
            obj.DragPrimed_ = false;
            obj.Dragging_ = false;
            obj.DragRowID_ = "";
            obj.DragStartPoint_ = [NaN NaN];
            obj.DropTargetSlot_ = 0;
            obj.applyDropSlotAppearance_(old);
            obj.applyRowAppearance_(draggedRow);
            if obj.SetupComplete_ && isvalidHandle_(obj.SizingGrid)
                obj.applySizingTracks_();
            end
            obj.restorePointer_();
        end

        function updateGripPointer_(obj,target)
        %UPDATEGRIPPOINTER_ Show open- or closed-hand feedback for the grip.
            if obj.Dragging_
                obj.setGripPointer_("dragging");
            elseif obj.isGripTarget_(target) && obj.Reorderable_
                obj.setGripPointer_("open");
            else
                obj.restorePointer_();
            end
        end

        function setGripPointer_(obj,state)
        %SETGRIPPOINTER_ Claim the figure pointer and apply a grip cursor.
            fig = obj.HubFigure;
            if isempty(fig) || ~isvalid(fig), return; end
            if ~obj.PointerOwned_
                obj.PreviousPointer_ = string(fig.Pointer);
                obj.PreviousPointerShapeCData_ = fig.PointerShapeCData;
                obj.PreviousPointerShapeHotSpot_ = fig.PointerShapeHotSpot;
                obj.PointerOwned_ = true;
            end
            if state == "dragging"
                fig.Pointer = 'top';
            else
                fig.Pointer = 'hand';
            end
        end

        function restorePointer_(obj)
        %RESTOREPOINTER_ Restore the figure pointer that preceded grip hover.
            if ~obj.PointerOwned_, return; end
            fig = obj.HubFigure;
            if ~isempty(fig) && isvalid(fig)
                if obj.PreviousPointer_ == "custom"
                    fig.PointerShapeCData = obj.PreviousPointerShapeCData_;
                    fig.PointerShapeHotSpot = obj.PreviousPointerShapeHotSpot_;
                end
                fig.Pointer = char(obj.PreviousPointer_);
            end
            obj.PointerOwned_ = false;
            obj.PreviousPointerShapeCData_ = [];
            obj.PreviousPointerShapeHotSpot_ = [];
        end

        function icon = gripIcon_(~,background)
        %GRIPICON_ Choose the grip asset that contrasts with BACKGROUND.
            root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
            luminance = dot(background,[0.2126 0.7152 0.0722]);
            if luminance < 0.55
                name = 'GripWhiteFGTransparentBG.png';
            else
                name = 'GripBlackFGTransparentBG.png';
            end
            icon = fullfile(root,'assets','icons',name);
        end

        function ensureContextMenu_(obj,fig)
        %ENSURECONTEXTMENU_ Create and attach the built-in table menu.
            if isvalidHandle_(obj.BuiltInContextMenu_) && isequal(obj.BuiltInContextMenu_.Parent,fig)
                obj.attachContextMenu_();
                return
            end
            if isvalidHandle_(obj.BuiltInContextMenu_), delete(obj.BuiltInContextMenu_); end
            menu = uicontextmenu(fig,ContextMenuOpeningFcn=@(~,~) obj.refreshContextMenu_());
            items.Add = uimenu(menu,Text='Add row',MenuSelectedFcn=@(~,~) obj.addNewRow());
            items.Duplicate = uimenu(menu,Text='Duplicate row',MenuSelectedFcn=@(~,~) obj.duplicateActiveRow());
            items.Delete = uimenu(menu,Text='Delete row',MenuSelectedFcn=@(~,~) obj.removeRow(obj.ActiveRow));
            items.SelectAll = uimenu(menu,Text='Select all',Separator='on',MenuSelectedFcn=@(~,~) obj.selectAll());
            items.Clear = uimenu(menu,Text='Clear selection',MenuSelectedFcn=@(~,~) obj.clearSelection());
            items.Invert = uimenu(menu,Text='Invert selection',MenuSelectedFcn=@(~,~) obj.invertSelection());
            items.DeleteSelected = uimenu(menu,Text='Delete selected',Separator='on',MenuSelectedFcn=@(~,~) obj.removeSelectedRows());
            obj.BuiltInContextMenu_ = menu;
            obj.ContextMenuItems = items;
            obj.attachContextMenu_();
        end

        function attachContextMenu_(obj)
        %ATTACHCONTEXTMENU_ Attach the menu without replacing explicit menus.
            targets = [{obj.SizingGrid,obj.EmptyLabel},obj.GripGrids(:)', ...
                obj.GripImages(:)',obj.DropSlotPanels(:)', ...
                obj.CellGrids(:)',obj.CellControls(:)'];
            for i = 1:numel(targets)
                target = targets{i};
                if isvalidHandle_(target) && isprop(target,'ContextMenu') && ...
                        isempty(target.ContextMenu)
                    target.ContextMenu = obj.BuiltInContextMenu_;
                end
            end
        end

        function refreshContextMenu_(obj)
        %REFRESHCONTEXTMENU_ Update built-in action availability.
            if isempty(fieldnames(obj.ContextMenuItems)), return; end
            set(obj.ContextMenuItems.Add,'Enable',onOff_(~isempty(obj.NewRowFcn)));
            set(obj.ContextMenuItems.Duplicate,'Enable',onOff_(obj.ActiveRow > 0));
            set(obj.ContextMenuItems.Delete,'Enable',onOff_(obj.ActiveRow > 0));
            set(obj.ContextMenuItems.SelectAll,'Enable',onOff_( ...
                obj.SelectionMode_ == "multiple" && numel(obj.SelectedRowIDs_) < height(obj.Data_)));
            set(obj.ContextMenuItems.Clear,'Enable',onOff_(~isempty(obj.SelectedRowIDs_)));
            set(obj.ContextMenuItems.Invert,'Enable',onOff_( ...
                obj.SelectionMode_ == "multiple" && height(obj.Data_) > 0));
            set(obj.ContextMenuItems.DeleteSelected,'Enable',onOff_(~isempty(obj.SelectedRowIDs_)));
        end
    end

    %% Data helpers and callback guard
    methods (Access=private)
        function [rowID,rowData] = prepareAdd_(obj,index,rowData)
        %PREPAREADD_ Validate an addition and request permission to commit it.
            obj.validateInsertIndex_(index);
            rowData = obj.normalizeRow_(rowData);
            request = matlabx.ui.control.ControlTableRowOperationData( ...
                "add",string.empty(1,0),double.empty(1,0),0,index,rowData);
            if obj.requestOperation_(request)
                rowID = newUUIDs_(1);
            else
                rowID = "";
            end
        end

        function allowed = requestOperation_(obj,eventData)
        %REQUESTOPERATION_ Emit one cancellable structural-operation request.
            notify(obj,'RowOperationRequested',eventData);
            allowed = ~eventData.Cancel;
        end

        function rowID = insertRowCore_(obj,index,rowData,rowID)
        %INSERTROWCORE_ Insert data, identity, and graphics without an event.
            obj.cancelDrag_();
            oldState = obj.selectionState_();
            cleanup = obj.beginRefresh_(); %#ok<NASGU>
            columnCount = numel(obj.Columns_);
            oldRowCount = height(obj.Data_);
            obj.Data_ = [obj.Data_(1:index-1,:);rowData;obj.Data_(index:end,:)];
            obj.RowIDs = [obj.RowIDs(1:index-1),rowID,obj.RowIDs(index:end)];
            obj.CellGrids = [obj.CellGrids(1:index-1,:);cell(1,columnCount);obj.CellGrids(index:end,:)];
            obj.CellControls = [obj.CellControls(1:index-1,:);cell(1,columnCount);obj.CellControls(index:end,:)];
            if obj.Reorderable_
                obj.GripGrids = [obj.GripGrids(1:index-1);{[]};obj.GripGrids(index:end)];
                obj.GripImages = [obj.GripImages(1:index-1);{[]};obj.GripImages(index:end)];
            end
            if oldRowCount == 0
                obj.DropSlotPanels = cell(2,1);
                obj.createDropSlot_(1);
                obj.createDropSlot_(2);
            else
                obj.DropSlotPanels = [obj.DropSlotPanels(1:index); ...
                    {[]};obj.DropSlotPanels(index+1:end)];
                obj.createDropSlot_(index+1);
            end
            if isvalidHandle_(obj.EmptyLabel), delete(obj.EmptyLabel); obj.EmptyLabel=[]; end
            if obj.HoveredRow_ >= index && obj.HoveredRow_ > 0
                obj.HoveredRow_ = obj.HoveredRow_+1;
            end
            obj.createRowGraphics_(index);
            obj.positionRowsFrom_(index+1);
            obj.positionDropSlotsFrom_(index);
            obj.applySizingTracks_();
            obj.refreshDynamicControls_();
            obj.applyRowAppearancesFrom_(index);
            obj.publishSelectionProperties_();
            obj.attachContextMenu_();
            clear cleanup
            obj.notifySelectionChange_(oldState);
        end

        function removeRows_(obj,rows)
        %REMOVEROWS_ Remove a normalized row set and emit one structural event.
            rows = obj.validateSelectionRows_(rows,false);
            if isempty(rows), return; end
            rows = sort(unique(rows));
            removedIDs = obj.RowIDs(rows);
            request = matlabx.ui.control.ControlTableRowOperationData( ...
                "remove",removedIDs,rows,0,0,obj.Data_(rows,:));
            if ~obj.requestOperation_(request), return; end
            obj.cancelDrag_();
            oldState = obj.selectionState_();
            formerActive = obj.ActiveRow;
            cleanup = obj.beginRefresh_(); %#ok<NASGU>
            for row = rows
                if obj.Reorderable_ && isvalidHandle_(obj.GripGrids{row})
                    delete(obj.GripGrids{row});
                end
                for column = 1:size(obj.CellGrids,2)
                    if isvalidHandle_(obj.CellGrids{row,column}), delete(obj.CellGrids{row,column}); end
                end
            end
            slotsToDelete = rows+1;
            for slot = slotsToDelete
                if isvalidHandle_(obj.DropSlotPanels{slot})
                    delete(obj.DropSlotPanels{slot});
                end
            end
            obj.Data_(rows,:) = [];
            obj.RowIDs(rows) = [];
            obj.CellGrids(rows,:) = [];
            obj.CellControls(rows,:) = [];
            if obj.Reorderable_
                obj.GripGrids(rows) = [];
                obj.GripImages(rows) = [];
            end
            obj.DropSlotPanels(slotsToDelete) = [];
            obj.SelectedRowIDs_ = obj.SelectedRowIDs_(ismember(obj.SelectedRowIDs_,obj.RowIDs));
            if ~ismember(obj.ActiveRowID_,obj.SelectedRowIDs_)
                if ~isempty(obj.SelectedRowIDs_)
                    obj.ActiveRowID_ = obj.promoteActiveID_(obj.SelectedRowIDs_,formerActive);
                elseif ~isempty(obj.RowIDs)
                    neighbor = min(max(1,min(rows)),height(obj.Data_));
                    obj.ActiveRowID_ = obj.RowIDs(neighbor);
                    obj.SelectedRowIDs_ = obj.ActiveRowID_;
                else
                    obj.ActiveRowID_ = "";
                end
            end
            if ~ismember(obj.AnchorRowID_,obj.RowIDs), obj.AnchorRowID_=obj.ActiveRowID_; end
            obj.publishSelectionProperties_();
            obj.HoveredRow_ = 0;
            obj.positionRowsFrom_(min(rows));
            obj.positionDropSlotsFrom_(min(rows));
            if height(obj.Data_)==0
                for slot = 1:numel(obj.DropSlotPanels)
                    if isvalidHandle_(obj.DropSlotPanels{slot}), delete(obj.DropSlotPanels{slot}); end
                end
                obj.DropSlotPanels = {};
                obj.createEmptyLabel_();
            end
            obj.applySizingTracks_();
            obj.refreshDynamicControls_();
            obj.applyRowAppearancesFrom_(min(rows));
            clear cleanup
            obj.notifySelectionChange_(oldState);
            notify(obj,'RowsRemoved',matlabx.ui.control.ControlTableRowsChangedData( ...
                removedIDs,string.empty(1,0),rows,double.empty(1,0)));
        end

        function state = selectionState_(obj)
        %SELECTIONSTATE_ Snapshot complete identity and numeric selection state.
            state = struct('ActiveRow',obj.rowForID_(obj.ActiveRowID_), ...
                'ActiveRowID',obj.ActiveRowID_, ...
                'SelectedRows',obj.rowsForIDs_(obj.SelectedRowIDs_), ...
                'SelectedRowIDs',obj.SelectedRowIDs_);
        end

        function setSelectionByIDs_(obj,ids,activeID,anchorID,emit)
        %SETSELECTIONBYIDS_ Normalize and atomically commit selection identity.
            oldState = obj.selectionState_();
            ids = reshape(string(ids),1,[]);
            ids = obj.RowIDs(ismember(obj.RowIDs,unique(ids,'stable')));
            if obj.SelectionMode_ == "single" && numel(ids)>1
                if ismember(string(activeID),ids), ids=string(activeID); else, ids=ids(1); end
            end
            activeID = string(activeID);
            if ~ismember(activeID,ids)
                if isempty(ids), activeID=""; else, activeID=ids(1); end
            end
            anchorID = string(anchorID);
            if ~ismember(anchorID,obj.RowIDs), anchorID=activeID; end
            if isequal(ids,obj.SelectedRowIDs_) && activeID==obj.ActiveRowID_ && ...
                    anchorID==obj.AnchorRowID_
                return
            end
            affected = unique([obj.rowsForIDs_(obj.SelectedRowIDs_), ...
                obj.rowsForIDs_(ids),obj.rowForID_(obj.ActiveRowID_),obj.rowForID_(activeID)]);
            obj.SelectedRowIDs_ = ids;
            obj.ActiveRowID_ = activeID;
            obj.AnchorRowID_ = anchorID;
            obj.publishSelectionProperties_();
            for row = affected, obj.applyRowAppearance_(row); end
            obj.refreshContextMenu_();
            if emit, obj.notifySelectionChange_(oldState); end
        end

        function publishSelectionProperties_(obj)
        %PUBLISHSELECTIONPROPERTIES_ Synchronize read-only public ID properties.
            obj.ActiveRowID = obj.ActiveRowID_;
            obj.SelectedRowIDs = obj.SelectedRowIDs_;
        end

        function notifySelectionChange_(obj,oldState)
        %NOTIFYSELECTIONCHANGE_ Emit one event only when public state changed.
            newState = obj.selectionState_();
            if isequal(oldState,newState), return; end
            notify(obj,'SelectionChanged', ...
                matlabx.ui.control.ControlTableSelectionChangedData(oldState,newState));
        end

        function rows = rowsForIDs_(obj,ids)
        %ROWSFORIDS_ Resolve stable identities in current table order.
            rows = find(ismember(obj.RowIDs,string(ids)));
            rows = reshape(rows,1,[]);
        end

        function row = rowForID_(obj,id)
        %ROWFORID_ Resolve one stable identity, returning zero when absent.
            row = find(obj.RowIDs==string(id),1);
            if isempty(row), row=0; end
        end

        function rows = validateSelectionRows_(obj,rows,scalarOnly)
        %VALIDATESELECTIONROWS_ Validate public numeric row selections.
            if isempty(rows), rows=double.empty(1,0); end
            if scalarOnly && isnumeric(rows) && isscalar(rows) && isequal(rows,0)
                rows = 0;
                return
            end
            if ~isnumeric(rows) || ~isvector(rows) || any(~isfinite(rows)) || ...
                    any(rows~=fix(rows)) || any(rows<1) || any(rows>height(obj.Data_)) || ...
                    (scalarOnly && ~isscalar(rows))
                error('matlabx:ui:control:ControlTable:InvalidSelectionRows', ...
                    'Rows must contain valid integer Data row indices.');
            end
            rows = reshape(double(rows),1,[]);
            rows = unique(rows,'stable');
        end

        function id = promoteActiveID_(obj,ids,referenceRow)
        %PROMOTEACTIVEID_ Choose the nearest selected row, preferring preceding.
            ids = reshape(string(ids),1,[]);
            if isempty(ids), id=""; return; end
            rows = obj.rowsForIDs_(ids);
            preceding = rows(rows<referenceRow);
            if ~isempty(preceding), row=preceding(end); else, row=rows(1); end
            id = obj.RowIDs(row);
        end

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

        function validateInsertIndex_(obj,index)
        %VALIDATEINSERTINDEX_ Require a valid insertion position.
            if ~isscalar(index) || index ~= fix(index) || index < 1 || ...
                    index > height(obj.Data_)+1
                error('matlabx:ui:control:ControlTable:InvalidInsertIndex', ...
                    'Insert index must be between 1 and height(Data)+1.');
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

function color = tintColor_(color,amount)
%TINTCOLOR_ Shift a color away from its current luminance extreme.
    luminance = dot(color,[0.2126 0.7152 0.0722]);
    if luminance < 0.5
        color = color + (1-color)*amount;
    else
        color = color*(1-amount);
    end
end

function value = onOff_(tf)
%ONOFF_ Convert a logical condition to a MATLAB on/off character value.
    if tf, value='on'; else, value='off'; end
end
