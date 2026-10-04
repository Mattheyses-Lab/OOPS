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

classdef Point < matlabx.ui.axes.AxesTool
%POINT Create and manipulate point overlays in ImageAxes.
%
%   The Point tool follows the same ownership pattern as Box: the tool
%   interprets gestures and emits compatibility callbacks, while
%   ImageAxesOverlayManager owns overlay lifetime plus active, hovered, and
%   selected state.

    properties
        Marker (1,:) char = '+'
        MarkerSize (1,1) double {mustBePositive} = 8
        MarkerEdgeColor = [1 1 1]
        MarkerFaceColor = 'none'
        ActivateOnCreate (1,1) logical = true
        DragStartThresholdPx (1,1) double {mustBeNonnegative} = 3
    end

    properties
        PointCreatedFcn
        PointMoveStartedFcn
        PointPreviewMovedFcn
        PointMoveCommittedFcn
        PointDeletedFcn
        PointActivatedFcn
        PointSelectionChangedFcn
    end

    properties (SetAccess=private, Dependent)
        nPoints
    end

    properties (Access=private, Transient, NonCopyable)
        PointROI (:,1) matlabx.ui.axes.overlays.Point
    end

    properties (Access=private)
        PointIds (1,:) string = string.empty(1,0)
        PointPositions (:,2) double = zeros(0,2)
        DragStartFigurePoint (1,2) double = [NaN NaN]
    end

    methods
        function obj = Point(host)
        %POINT Create the Point tool for one ImageAxes host.
            obj@matlabx.ui.axes.AxesTool(host, "Point", ...
                'Tooltip', 'Point overlays', ...
                'AxesType', "image", ...
                'Icon', matlabx.internal.Paths.icons('AddPoint.png'), ...
                'Priority', 10, ...
                'IsExclusive', true, ...
                'InterceptsDown', true, ...
                'PassivelyInterceptsDown', true, ...
                'PassivelyInterceptsMove', true, ...
                'PassivelyInterceptsUp', true);

            obj.PointROI = matlabx.ui.axes.overlays.Point.empty();
        end

        function onInstall(obj)
        %ONINSTALL Register tool-owned interaction modes.
            obj.addMode('PrimedForDrag');
            obj.addMode('DragPoint');
            obj.addMode('HoverPoint');
        end

        function onUninstall(obj)
        %ONUNINSTALL Remove modes and point overlays owned by this tool.
            obj.removeMode('PrimedForDrag');
            obj.removeMode('DragPoint');
            obj.removeMode('HoverPoint');
            obj.clearPoints();
        end

        function contributeContextMenu(obj, menu)
        %CONTRIBUTECONTEXTMENU Add Point commands to the host context menu.
            menu.addSubmenu( ...
                "Point", ...
                "Point", ...
                "Owner", obj);

            menu.addItem( ...
                "Point.ClearSelection", ...
                "Clear Selection", ...
                @(~,~) obj.clearPointSelection(Emit=true), ...
                "Parent", "Point", ...
                "Owner", obj, ...
                "Separator", "on", ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasSelectedPoints()), ...
                "RefreshFcn", @(h) obj.refreshRequiresSelection(h));

            menu.addItem( ...
                "Point.SelectAll", ...
                "Select All", ...
                @(~,~) obj.selectAllPoints(), ...
                "Parent", "Point", ...
                "Owner", obj, ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasAnyPoints()), ...
                "RefreshFcn", @(h) obj.refreshRequiresPoints(h));

            menu.addItem( ...
                "Point.DeleteSelected", ...
                "Delete Selected", ...
                @(~,~) obj.deleteSelectedPoints(), ...
                "Parent", "Point", ...
                "Owner", obj, ...
                "Separator", "on", ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasSelectedPoints()), ...
                "RefreshFcn", @(h) obj.refreshRequiresSelection(h));

            menu.addItem( ...
                "Point.DeleteAll", ...
                "Delete All", ...
                @(~,~) obj.deleteAllPoints(), ...
                "Parent", "Point", ...
                "Owner", obj, ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasAnyPoints()), ...
                "RefreshFcn", @(h) obj.refreshRequiresPoints(h));

            menu.addItem( ...
                "Point.Help", ...
                "Help...", ...
                @(~,~) obj.Host.openToolHelpWindow(obj), ...
                "Parent", "Point", ...
                "Owner", obj, ...
                "Separator", "on");
        end
    end

    %% Help
    methods
        function summary = getHelpSummary(~)
        %GETHELPSUMMARY Return a one-line Point description.
            summary = "Create, activate, select, move, and delete point overlays.";
        end

        function usage = getUsageHelp(~)
        %GETUSAGEHELP Return short Point usage notes.
            usage = [ ...
                "Enable Point and click the image to create a new point."; ...
                "Click an existing point to activate it and prime drag movement."; ...
                "Use selection commands from the Point context menu for batch actions."];
        end

        function B = getBindingHelp(obj)
        %GETBINDINGHELP Return Point click binding descriptions.
            B = struct( ...
                "ToggleTool", obj.ToggleHotkey, ...
                "CreatePoint", "click image background while Point is enabled", ...
                "ActivateAndDrag", "click point, then drag", ...
                "ToggleSelection", "shift+extendclick point", ...
                "ClearSelection", "shift+doubleclick image background while Point is enabled", ...
                "Deactivate", "alt+click point", ...
                "DeletePoint", "control+contextclick point");
        end

        function notes = getNotesHelp(~)
        %GETNOTESHELP Return additional Point behavior notes.
            notes = [ ...
                "Active and selected are separate states."; ...
                "Only the active point is dragged; selected points are used for batch menu actions."; ...
                "Right-click context menus are reserved for ImageAxes and tool commands."];
        end
    end

    %% Active event hooks
    methods
        function onDown(obj, E)
        %ONDOWN Create a point or clear selection from background gestures.
            switch E.MouseChord
                case "click"
                    if obj.isPointOverlayTarget(E.Target)
                        return
                    end

                    H = obj.Host;
                    XY = H.cursorPosition;
                    if isempty(XY)
                        return
                    end

                    id = matlabx.utils.text.uniqueID();
                    obj.addPoint(id, XY);

                    if ~isempty(obj.PointCreatedFcn)
                        obj.PointCreatedFcn(H, struct('ID', id, 'PositionPx', obj.pointPositionById(id)));
                    end

                    if obj.ActivateOnCreate
                        obj.emitActiveChanged(id);
                    end

                case "shift+doubleclick"
                    obj.clearPointSelection("Emit", true);

                otherwise
                    return
            end
        end
    end

    %% Passive event hooks
    methods
        function onPassiveDown(obj, E)
        %ONPASSIVEDOWN Handle clicks on existing Point overlays.
            overlay = obj.pointOverlayForTarget(E.Target);
            if isempty(overlay) || ~obj.hasPoint(overlay.ID)
                return
            end

            obj.pointClickedById(overlay.ID, E);
            E.stop();
        end

        function onPassiveMove(obj, E)
        %ONPASSIVEMOVE Update hover or drag state for existing points.
            if obj.Mode.PrimedForDrag
                if ~obj.hasExceededDragThreshold(E)
                    return
                end

                obj.startDraggingPoint(obj.activePointIdx());
                return
            end

            if obj.Mode.DragPoint
                obj.dragPoint(obj.activePointIdx());
                return
            end

            overlay = obj.pointOverlayForTarget(E.Target);
            if isempty(overlay) || ~obj.hasPoint(overlay.ID)
                obj.stopHover();
                return
            end

            obj.startHoverById(overlay.ID);
        end

        function onPassiveUp(obj,~)
        %ONPASSIVEUP Commit or cancel point drag state on mouse release.
            if obj.Mode.PrimedForDrag
                obj.setMode('PrimedForDrag', false);
                obj.clearDragStart();
                return
            end

            if obj.Mode.DragPoint
                obj.stopDraggingPoint(obj.activePointIdx());
            end
        end
    end

    %% Derived getters
    methods
        function n = get.nPoints(obj)
        %GET.NPOINTS Return number of valid Point overlays owned by this tool.
            if isempty(obj.PointROI)
                n = 0;
            else
                n = sum(isvalid(obj.PointROI));
            end
        end
    end

    %% Private helpers
    methods (Access=private)
        function id = normalizeId_(~, id)
        %NORMALIZEID_ Convert input to a scalar string ID.
            id = string(id);
            if isempty(id)
                id = "";
            else
                id = id(1);
            end
        end

        function idx = idxOfId(obj, id)
        %IDXOFID Return local PointROI index for an ID.
            id = obj.normalizeId_(id);
            if strlength(id) == 0
                idx = [];
                return
            end

            idx = find(obj.PointIds == id, 1, 'first');
        end

        function idx = activePointIdx(obj)
        %ACTIVEPOINTIDX Return local index of manager-active Point overlay.
            idx = obj.idxOfId(obj.activePointId());
        end

        function id = activePointId(obj)
        %ACTIVEPOINTID Return active Point ID filtered to overlays owned by this tool.
            id = obj.Host.Overlays.getActiveID(Type="Point");
            if ~obj.hasPoint(id)
                id = "";
            end
        end

        function id = activeHoverId(obj)
        %ACTIVEHOVERID Return hovered Point ID filtered to overlays owned by this tool.
            id = obj.Host.Overlays.getHoverID(Type="Point");
            if ~obj.hasPoint(id)
                id = "";
            end
        end

        function ids = selectedPointIds(obj)
        %SELECTEDPOINTIDS Return selected Point IDs filtered to overlays owned by this tool.
            ids = obj.Host.Overlays.getSelectedIDs(Type="Point");
            ids = ids(ismember(ids, obj.PointIds));
        end

        function tf = isValidPointIdx(obj, idx)
        %ISVALIDPOINTIDX True when idx addresses a valid local Point overlay.
            tf = ~isempty(idx) ...
                && isscalar(idx) ...
                && idx >= 1 ...
                && idx <= numel(obj.PointROI) ...
                && isvalid(obj.PointROI(idx));
        end

        function tf = hasPoint(obj, id)
        %HASPOINT True when this tool owns a point with ID.
            id = obj.normalizeId_(id);
            tf = strlength(id) > 0 && ismember(id, obj.PointIds);
        end

        function tf = hasAnyPoints(obj)
        %HASANYPOINTS True when this tool owns at least one valid point.
            tf = ~isempty(obj.PointROI) && any(isvalid(obj.PointROI));
        end

        function tf = hasSelectedPoints(obj)
        %HASSELECTEDPOINTS True when this tool owns selected points.
            tf = ~isempty(obj.selectedPointIds());
        end

        function overlay = pointOverlayForTarget(obj, target)
        %POINTOVERLAYFORTARGET Return owned Point overlay for a graphics target.
            overlay = obj.Host.Overlays.overlayForTarget(target);
            if ~isa(overlay, 'matlabx.ui.axes.overlays.Point') || ~obj.hasPoint(overlay.ID)
                overlay = [];
            end
        end

        function tf = isPointOverlayTarget(obj, target)
        %ISPOINTOVERLAYTARGET True when target belongs to an owned Point overlay.
            tf = ~isempty(obj.pointOverlayForTarget(target));
        end

        function refreshRequiresPoints(obj, h)
        %REFRESHREQUIRESPOINTS Enable menu item only when points exist.
            if isvalid(obj)
                h.Enable = matlab.lang.OnOffSwitchState(obj.hasAnyPoints());
            end
        end

        function refreshRequiresSelection(obj, h)
        %REFRESHREQUIRESSELECTION Enable menu item only when selection exists.
            if isvalid(obj)
                h.Enable = matlab.lang.OnOffSwitchState(obj.hasSelectedPoints());
            end
        end

        function pointClickedById(obj, id, E)
        %POINTCLICKEDBYID Apply Point click grammar to an existing point.
            id = obj.normalizeId_(id);
            if ~obj.hasPoint(id)
                return
            end

            switch E.MouseChord
                case "control+contextclick"
                    obj.deletePointById(id);
                    return

                case "alt+click"
                    obj.deactivateActive();

                case "shift+extendclick"
                    obj.toggleSelection(id, Emit=true);

                case "click"
                    obj.setActive(id);
                    obj.primeDrag(E);
            end
        end

        function setActive(obj, id)
        %SETACTIVE Make a point active and emit PointActivatedFcn.
            id = obj.normalizeId_(id);
            if ~obj.isValidPointIdx(obj.idxOfId(id))
                return
            end

            obj.Host.Overlays.setActive(id);
            obj.emitActiveChanged(id);
        end

        function deactivateActive(obj)
        %DEACTIVATEACTIVE Clear active point state and emit empty activation.
            if strlength(obj.activePointId()) == 0
                return
            end

            obj.setMode('PrimedForDrag', false);
            obj.setMode('DragPoint', false);
            obj.clearDragStart();
            obj.Host.Overlays.clearActive();
            obj.emitActiveChanged("");
        end

        function primeDrag(obj, E)
        %PRIMEDRAG Mark active point as ready to drag on the next move event.
            if obj.Enabled && strlength(obj.activePointId()) > 0
                obj.DragStartFigurePoint = E.CurrentPointFigure;
                obj.setMode('PrimedForDrag', true);
            end
        end

        function startDraggingPoint(obj, idx)
        %STARTDRAGGINGPOINT Transition from primed to dragging state.
            obj.setMode('PrimedForDrag', false);
            obj.clearDragStart();
            if ~obj.isValidPointIdx(idx)
                return
            end

            obj.setMode('DragPoint', true);
            if ~isempty(obj.PointMoveStartedFcn)
                obj.PointMoveStartedFcn(obj, struct('ID', obj.PointIds(idx)));
            end
            obj.Host.updateFromTool();
        end

        function dragPoint(obj, idx)
        %DRAGPOINT Move active point preview to the current cursor position.
            XY = obj.Host.cursorPosition;
            if isempty(XY) || ~obj.isValidPointIdx(idx)
                return
            end

            XY = obj.clampPoint(XY);
            obj.PointROI(idx).Position = XY;
            obj.PointPositions(idx,:) = XY;

            if ~isempty(obj.PointPreviewMovedFcn)
                obj.PointPreviewMovedFcn(obj, struct('ID', obj.PointIds(idx), 'PositionPx', XY));
            end
        end

        function stopDraggingPoint(obj, idx)
        %STOPDRAGGINGPOINT Commit final point position and emit callback.
            if obj.isValidPointIdx(idx)
                obj.dragPoint(idx);
                if ~isempty(obj.PointMoveCommittedFcn)
                    obj.PointMoveCommittedFcn(obj, struct( ...
                        'ID', obj.PointIds(idx), ...
                        'PositionPx', obj.PointPositions(idx,:)));
                end
            end

            obj.setMode('DragPoint', false);
            obj.clearDragStart();
            obj.Host.updateFromTool();
        end

        function tf = hasExceededDragThreshold(obj, E)
        %HASEXCEEDEDDRAGTHRESHOLD Return true after enough screen-pixel motion.
            d = obj.dragStartDistancePx(E);
            tf = isfinite(d) && d >= obj.DragStartThresholdPx;
        end

        function d = dragStartDistancePx(obj, E)
        %DRAGSTARTDISTANCEPX Measure motion from mouse-down in figure pixels.
            if any(isnan(obj.DragStartFigurePoint)) || any(isnan(E.CurrentPointFigure))
                d = Inf;
                return
            end

            delta = E.CurrentPointFigure - obj.DragStartFigurePoint;
            d = hypot(delta(1), delta(2));
        end

        function clearDragStart(obj)
        %CLEARDRAGSTART Clear stored figure-pixel drag origin.
            obj.DragStartFigurePoint = [NaN NaN];
        end

        function startHoverById(obj, id)
        %STARTHOVERBYID Mark a point as hovered through the overlay manager.
            id = obj.normalizeId_(id);
            idx = obj.idxOfId(id);
            if ~obj.isValidPointIdx(idx) || id == obj.activeHoverId()
                return
            end

            obj.Host.Overlays.setHover(id);
            obj.setMode('HoverPoint', true);
        end

        function stopHover(obj)
        %STOPHOVER Clear hovered Point state through the overlay manager.
            if ~obj.Mode.HoverPoint
                return
            end

            if strlength(obj.activeHoverId()) > 0
                obj.Host.Overlays.clearHover();
            end

            obj.setMode('HoverPoint', false);
        end

        function emitActiveChanged(obj, id)
        %EMITACTIVECHANGED Emit PointActivatedFcn if configured.
            if ~isempty(obj.PointActivatedFcn)
                obj.PointActivatedFcn(obj, struct('ID', obj.normalizeId_(id)));
            end
        end

        function emitSelectionChanged(obj)
        %EMITSELECTIONCHANGED Emit selected Point IDs if callback is configured.
            if ~isempty(obj.PointSelectionChangedFcn)
                obj.PointSelectionChangedFcn(obj, struct('IDs', obj.selectedPointIds()));
            end
        end

        function toggleSelection(obj, id, opts)
        %TOGGLESELECTION Toggle one point in the selected set.
            arguments
                obj
                id
                opts.Emit (1,1) logical = false
            end

            id = obj.normalizeId_(id);
            if ismember(id, obj.selectedPointIds())
                obj.Host.Overlays.deselect(id);
            else
                obj.Host.Overlays.select(id);
            end

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function deletePointById(obj, id)
        %DELETEPOINTBYID Delete a point and emit PointDeletedFcn.
            id = obj.normalizeId_(id);
            idx = obj.idxOfId(id);
            if ~obj.isValidPointIdx(idx)
                return
            end

            obj.deletePointByIdx(idx);
            if ~isempty(obj.PointDeletedFcn)
                obj.PointDeletedFcn(obj, struct('ID', id));
            end
        end

        function deletePointByIdx(obj, idx)
        %DELETEPOINTBYIDX Delete a local point without emitting PointDeletedFcn.
            if ~obj.isValidPointIdx(idx)
                return
            end

            id = obj.PointIds(idx);
            wasActive = obj.activePointId() == id;

            if obj.activeHoverId() == id
                obj.setMode('HoverPoint', false);
            end

            obj.Host.Overlays.remove(id);
            obj.PointROI(idx) = [];
            obj.PointPositions(idx,:) = [];
            obj.PointIds(idx) = [];

            if wasActive
                obj.emitActiveChanged("");
            end

            obj.emitSelectionChanged();
        end

        function xy = clampPoint(obj, xy)
        %CLAMPPOINT Keep a point inside image data bounds.
            xy = double(xy);
            xy(1) = min(max(xy(1), 1), obj.Host.ImageWidth);
            xy(2) = min(max(xy(2), 1), obj.Host.ImageHeight);
        end

        function position = pointPositionById(obj, id)
        %POINTPOSITIONBYID Return one point position by ID, or [NaN NaN].
            idx = obj.idxOfId(id);
            if obj.isValidPointIdx(idx)
                position = obj.PointPositions(idx,:);
            else
                position = [NaN NaN];
            end
        end
    end

    %% Host-facing methods
    methods
        function addPoint(obj, id, position, opts)
        %ADDPOINT Create a Point overlay owned by this tool.
            arguments
                obj
                id
                position (1,2) double
                opts.Marker = []
                opts.MarkerSize = []
                opts.MarkerEdgeColor = []
                opts.MarkerFaceColor = []
            end

            position = obj.clampPoint(position);
            next = obj.nPoints + 1;

            nv = { ...
                "ID", string(id), ...
                "Position", position, ...
                "Marker", obj.valueOrDefault(opts.Marker, obj.Marker), ...
                "MarkerSize", obj.valueOrDefault(opts.MarkerSize, obj.MarkerSize), ...
                "MarkerEdgeColor", obj.valueOrDefault(opts.MarkerEdgeColor, obj.MarkerEdgeColor), ...
                "MarkerFaceColor", obj.valueOrDefault(opts.MarkerFaceColor, obj.MarkerFaceColor), ...
                "ActivateOnCreate", obj.ActivateOnCreate};

            obj.PointROI(next) = obj.Host.Overlays.add("Point", nv{:});
            obj.PointPositions(end+1,:) = position;
            obj.PointIds(end+1) = string(id);
        end

        function removePoint(obj, id)
        %REMOVEPOINT Remove one point by ID.
            idx = obj.idxOfId(id);
            if isempty(idx)
                return
            end
            obj.deletePointByIdx(idx);
        end

        function clearPoints(obj)
        %CLEARPOINTS Remove all points owned by this tool.
            ids = obj.PointIds;
            for i = numel(ids):-1:1
                obj.Host.Overlays.remove(ids(i));
            end

            obj.PointROI = matlabx.ui.axes.overlays.Point.empty();
            obj.PointPositions = zeros(0,2);
            obj.PointIds = string.empty(1,0);
            obj.setModeIfPresent('PrimedForDrag', false);
            obj.setModeIfPresent('DragPoint', false);
            obj.setModeIfPresent('HoverPoint', false);
            obj.clearDragStart();
        end

        function setSelectedPointIDs(obj, ids, opts)
        %SETSELECTEDPOINTIDS Replace selected Point IDs.
            arguments
                obj
                ids
                opts.Emit (1,1) logical = false
            end

            ids = string(ids);
            ids = ids(ismember(ids, obj.PointIds));
            obj.Host.Overlays.setSelected(ids(:).', Type="Point");

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function ids = getSelectedPointIDs(obj)
        %GETSELECTEDPOINTIDS Return selected Point IDs.
            ids = obj.selectedPointIds();
        end

        function clearPointSelection(obj, opts)
        %CLEARPOINTSELECTION Clear selected points.
            arguments
                obj
                opts.Emit (1,1) logical = false
            end

            obj.Host.Overlays.clearSelection(Type="Point");

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function selectAllPoints(obj, opts)
        %SELECTALLPOINTS Select all points owned by this tool.
            arguments
                obj
                opts.Emit (1,1) logical = true
            end

            obj.setSelectedPointIDs(obj.PointIds, Emit=opts.Emit);
        end

        function deleteSelectedPoints(obj)
        %DELETESELECTEDPOINTS Delete selected points owned by this tool.
            ids = obj.selectedPointIds();
            for i = 1:numel(ids)
                obj.deletePointById(ids(i));
            end
        end

        function deleteAllPoints(obj)
        %DELETEALLPOINTS Delete all points owned by this tool.
            ids = obj.PointIds;
            for i = numel(ids):-1:1
                obj.deletePointById(ids(i));
            end
        end

        function setActivePointID(obj, id)
        %SETACTIVEPOINTID Public setter for active point ID.
            id = obj.normalizeId_(id);
            if strlength(id) == 0
                obj.deactivateActive();
            else
                obj.setActive(id);
            end
        end

        function setPointColorByID(obj, id, color)
        %SETPOINTCOLORBYID Set marker face color for one point.
            idx = obj.idxOfId(id);
            if obj.isValidPointIdx(idx)
                obj.PointROI(idx).MarkerFaceColor = color;
            end
        end
    end

    %% Host update helpers
    methods
        function onHostLeave(obj,~)
        %ONHOSTLEAVE Clear transient hover state when cursor leaves ImageAxes.
            obj.stopHover();
        end

        function pointer = getPreferredPointer(obj)
        %GETPREFERREDPOINTER Return pointer requested by current Point state.
            if obj.Mode.DragPoint
                pointer = 'fleur';
            elseif obj.Mode.HoverPoint
                pointer = 'hand';
            elseif obj.Enabled
                pointer = 'crosshair';
            else
                pointer = '';
            end
        end
    end

    %% Teardown
    methods (Access=protected)
        function teardown(obj)
        %TEARDOWN Delete Point overlays during tool destruction.
            try
                obj.clearPoints();
            catch
            end
        end
    end

    methods (Access=private)
        function setModeIfPresent(obj, modeName, value)
        %SETMODEIFPRESENT Set a mode only when it still exists.
            if obj.isMode(modeName)
                obj.setMode(modeName, value);
            end
        end
    end

    methods (Static, Access=private)
        function value = valueOrDefault(value, defaultValue)
        %VALUEORDEFAULT Return defaultValue when value is empty.
            if isempty(value)
                value = defaultValue;
            end
        end
    end
end
