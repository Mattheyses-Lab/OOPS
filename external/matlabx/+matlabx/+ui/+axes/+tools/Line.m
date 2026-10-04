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

classdef Line < matlabx.ui.axes.AxesTool
%LINE Draw and manipulate line overlays in ImageAxes.
%
%   The Line tool is an interaction controller for overlays.Line. It creates
%   line overlays by click-dragging endpoint to endpoint, activates existing
%   lines, toggles selection, translates active lines from the midpoint marker,
%   and adjusts endpoints from endpoint markers.

    properties
        LineColor = [1 1 1]
        LineAlpha (1,1) double {mustBeGreaterThanOrEqual(LineAlpha,0), mustBeLessThanOrEqual(LineAlpha,1)} = 1
        LineWidth (1,1) double {mustBePositive} = 1
        MarkerSize (1,1) double {mustBePositive} = 4
        HoverMarkerSize (1,1) double {mustBePositive} = 5
        ActivateOnCreate (1,1) logical = true
        DragStartThresholdPx (1,1) double {mustBeNonnegative} = 3
    end

    properties
        % Line-specific compatibility callbacks for app controllers.
        LineCreatedFcn
        LineMoveStartedFcn
        LinePreviewMovedFcn
        LineMoveCommittedFcn
        LineDeletedFcn
        LineActivatedFcn
        LineSelectionChangedFcn
    end

    properties (SetAccess=private, Dependent)
        nLines
    end

    properties (Access=private, Transient, NonCopyable)
        LineROI (:,1) matlabx.ui.axes.overlays.Line
    end

    properties (Access=private)
        LineIds (1,:) string = string.empty(1,0)
        DrawingLineID (1,1) string = ""
        PendingDragPart (1,1) string = ""
        DragStartFigurePoint (1,2) double = [NaN NaN]
        DragStartCursor (1,2) double = [NaN NaN]
        DragStartEndpoints (2,2) double = [NaN NaN; NaN NaN]
        DragStartUnitVector (1,2) double = [NaN NaN]
    end

    methods
        function obj = Line(host)
        %LINE Create the Line tool for one ImageAxes host.
            obj@matlabx.ui.axes.AxesTool(host, "Line", ...
                'Tooltip', 'Line overlays', ...
                'AxesType', "image", ...
                'Icon', matlabx.internal.Paths.icons('DrawLine.png'), ...
                'Priority', 9, ...
                'IsExclusive', true, ...
                'InterceptsDown', true, ...
                'InterceptsMove', true, ...
                'InterceptsUp', true, ...
                'PassivelyInterceptsDown', true, ...
                'PassivelyInterceptsMove', true);

            obj.LineROI = matlabx.ui.axes.overlays.Line.empty();
        end

        function onInstall(obj)
        %ONINSTALL Register tool-owned interaction modes.
            obj.addMode('DrawingLine');
            obj.addMode('PrimedForDrag');
            obj.addMode('DragLine');
            obj.addMode('DragEndpoint1');
            obj.addMode('DragEndpoint2');
            obj.addMode('ExtendEndpoint1FixedAngle');
            obj.addMode('ExtendEndpoint2FixedAngle');
            obj.addMode('ExtendBoth');
            obj.addMode('ExtendBothFixedAngle');
            obj.addMode('HoverLine');
            obj.addMode('HoverMidpoint');
            obj.addMode('HoverEndpoint');
        end

        function onUninstall(obj)
        %ONUNINSTALL Remove modes and line overlays owned by this tool.
            obj.clearLines();
            obj.removeMode('DrawingLine');
            obj.removeMode('PrimedForDrag');
            obj.removeMode('DragLine');
            obj.removeMode('DragEndpoint1');
            obj.removeMode('DragEndpoint2');
            obj.removeMode('ExtendEndpoint1FixedAngle');
            obj.removeMode('ExtendEndpoint2FixedAngle');
            obj.removeMode('ExtendBoth');
            obj.removeMode('ExtendBothFixedAngle');
            obj.removeMode('HoverLine');
            obj.removeMode('HoverMidpoint');
            obj.removeMode('HoverEndpoint');
        end

        function contributeContextMenu(obj, menu)
        %CONTRIBUTECONTEXTMENU Add Line commands to the host context menu.
            menu.addSubmenu( ...
                "Line", ...
                "Line", ...
                "Owner", obj);

            menu.addItem( ...
                "Line.ClearSelection", ...
                "Clear Selection", ...
                @(~,~) obj.clearLineSelection(Emit=true), ...
                "Parent", "Line", ...
                "Owner", obj, ...
                "Separator", "on", ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasSelectedLines()), ...
                "RefreshFcn", @(h) obj.refreshRequiresSelection(h));

            menu.addItem( ...
                "Line.SelectAll", ...
                "Select All", ...
                @(~,~) obj.selectAllLines(), ...
                "Parent", "Line", ...
                "Owner", obj, ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasAnyLines()), ...
                "RefreshFcn", @(h) obj.refreshRequiresLines(h));

            menu.addItem( ...
                "Line.DeleteSelected", ...
                "Delete Selected", ...
                @(~,~) obj.deleteSelectedLines(), ...
                "Parent", "Line", ...
                "Owner", obj, ...
                "Separator", "on", ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasSelectedLines()), ...
                "RefreshFcn", @(h) obj.refreshRequiresSelection(h));

            menu.addItem( ...
                "Line.DeleteAll", ...
                "Delete All", ...
                @(~,~) obj.deleteAllLines(), ...
                "Parent", "Line", ...
                "Owner", obj, ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasAnyLines()), ...
                "RefreshFcn", @(h) obj.refreshRequiresLines(h));

            menu.addItem( ...
                "Line.Help", ...
                "Help...", ...
                @(~,~) obj.Host.openToolHelpWindow(obj), ...
                "Parent", "Line", ...
                "Owner", obj, ...
                "Separator", "on");
        end
    end

    %% Help
    methods
        function summary = getHelpSummary(~)
        %GETHELPSUMMARY Return a one-line Line description.
            summary = "Create, activate, select, translate, and edit line overlays.";
        end

        function usage = getUsageHelp(~)
        %GETUSAGEHELP Return short Line usage notes.
            usage = [ ...
                "Enable Line and click-drag from endpoint to endpoint to create a line."; ...
                "Click an existing line to activate it."; ...
                "Drag the midpoint marker to translate the line."; ...
                "Drag endpoint markers to adjust one endpoint while leaving the other fixed."];
        end

        function B = getBindingHelp(obj)
        %GETBINDINGHELP Return Line click binding descriptions.
            B = struct( ...
                "ToggleTool", obj.ToggleHotkey, ...
                "CreateLine", "click-drag image background while Line is enabled", ...
                "Activate", "click line", ...
                "ToggleSelection", "shift+extendclick line", ...
                "ClearSelection", "shift+doubleclick image background", ...
                "Deactivate", "alt+click line body", ...
                "DeleteLine", "control+contextclick line", ...
                "Translate", "click-drag midpoint marker", ...
                "AdjustEndpoint", "click-drag endpoint marker", ...
                "ExtendEndpointFixedAngle", "shift+extendclick endpoint marker and drag", ...
                "ExtendBoth", "alt+click line and drag", ...
                "ExtendBothFixedAngle", "shift+alt+extendclick line and drag");
        end

        function notes = getNotesHelp(~)
        %GETNOTESHELP Return additional Line behavior notes.
            notes = [ ...
                "Line overlay state is owned by ImageAxes.Overlays."; ...
                "The Line tool emits line-specific callbacks for app controllers."; ...
                "Markers are shown while a line is hovered or active."];
        end
    end

    %% Active event hooks
    methods
        function onDown(obj, E)
        %ONDOWN Start drawing a line from a background click.
            if obj.isLineOverlayTarget(E.Target)
                return
            end

            if E.MouseChord == "shift+doubleclick"
                obj.clearLineSelection(Emit=true);
                E.stop();
                return
            end

            if E.MouseChord ~= "click"
                return
            end

            XY = obj.Host.cursorPosition;
            if isempty(XY)
                return
            end

            obj.DrawingLineID = "";
            obj.DragStartFigurePoint = E.CurrentPointFigure;
            obj.DragStartCursor = XY;
            obj.setMode('DrawingLine', true);
            E.stop();
        end

        function onMove(obj, E)
        %ONMOVE Update drawing or drag preview while the mouse is down.
            if obj.Mode.DrawingLine
                if strlength(obj.DrawingLineID) == 0
                    if ~obj.hasExceededDragThreshold(E)
                        return
                    end

                    obj.startDrawingLineOverlay();
                    return
                end

                obj.previewDrawLine();
                return
            end

            if obj.Mode.PrimedForDrag
                if ~obj.hasExceededDragThreshold(E)
                    return
                end

                obj.startDraggingLine();
                return
            end

            if obj.isDragging()
                obj.dragActiveLine();
            end
        end

        function onUp(obj, ~)
        %ONUP Commit line drawing or drag state.
            if obj.Mode.DrawingLine
                id = obj.DrawingLineID;
                if strlength(id) > 0
                    obj.previewDrawLine();
                    obj.emitMoveCommitted(id);
                end
                obj.setMode('DrawingLine', false);
                obj.setDrawingLineMarkersVisible("off");
                obj.DrawingLineID = "";
                obj.clearDragStart();
                obj.DragStartCursor = [NaN NaN];
                return
            end

            if obj.Mode.PrimedForDrag
                obj.setMode('PrimedForDrag', false);
                obj.PendingDragPart = "";
                obj.clearDragStart();
                return
            end

            if obj.isDragging()
                id = obj.activeLineId();
                obj.dragActiveLine();
                obj.clearDragModes();
                obj.emitMoveCommitted(id);
            end
        end
    end

    %% Passive event hooks
    methods
        function onPassiveDown(obj, E)
        %ONPASSIVEDOWN Handle clicks on existing Line overlays.
            overlay = obj.lineOverlayForTarget(E.Target);
            if isempty(overlay) || ~obj.hasLine(overlay.ID)
                return
            end

            part = obj.hitPartForEvent(E, overlay);
            obj.lineClickedById(overlay.ID, part, E);
            E.stop();
        end

        function onPassiveMove(obj, E)
        %ONPASSIVEMOVE Update hover state for existing Line overlays.
            if obj.Mode.DrawingLine || obj.Mode.PrimedForDrag ...
                    || obj.isDragging()
                return
            end

            overlay = obj.lineOverlayForTarget(E.Target);
            if isempty(overlay) || ~obj.hasLine(overlay.ID)
                obj.stopHover();
                return
            end

            part = obj.hitPartForEvent(E, overlay);
            obj.startHoverById(overlay.ID, part);
        end
    end

    %% Derived getters
    methods
        function n = get.nLines(obj)
        %GET.NLINES Return number of valid Line overlays owned by this tool.
            if isempty(obj.LineROI)
                n = 0;
            else
                n = sum(isvalid(obj.LineROI));
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
        %IDXOFID Return local LineROI index for an ID.
            id = obj.normalizeId_(id);
            if strlength(id) == 0
                idx = [];
                return
            end

            idx = find(obj.LineIds == id, 1, 'first');
        end

        function tf = isValidLineIdx(obj, idx)
        %ISVALIDLINEIDX True when idx addresses a valid local Line overlay.
            tf = ~isempty(idx) ...
                && isscalar(idx) ...
                && idx >= 1 ...
                && idx <= numel(obj.LineROI) ...
                && isvalid(obj.LineROI(idx));
        end

        function tf = hasLine(obj, id)
        %HASLINE True when this tool owns a line with ID.
            id = obj.normalizeId_(id);
            tf = strlength(id) > 0 && ismember(id, obj.LineIds);
        end

        function id = activeLineId(obj)
        %ACTIVELINEID Return active Line ID filtered to overlays owned by this tool.
            id = obj.Host.Overlays.getActiveID(Type="Line");
            if ~obj.hasLine(id)
                id = "";
            end
        end

        function idx = activeLineIdx(obj)
        %ACTIVELINEIDX Return local index of manager-active Line overlay.
            idx = obj.idxOfId(obj.activeLineId());
        end

        function ids = selectedLineIds(obj)
        %SELECTEDLINEIDS Return selected Line IDs filtered to overlays owned by this tool.
            ids = obj.Host.Overlays.getSelectedIDs(Type="Line");
            ids = ids(ismember(ids, obj.LineIds));
        end

        function tf = hasAnyLines(obj)
        %HASANYLINES True when this tool owns at least one valid line.
            tf = ~isempty(obj.LineROI) && any(isvalid(obj.LineROI));
        end

        function tf = hasSelectedLines(obj)
        %HASSELECTEDLINES True when this tool owns selected lines.
            tf = ~isempty(obj.selectedLineIds());
        end

        function refreshRequiresLines(obj, h)
        %REFRESHREQUIRESLINES Enable menu item only when lines exist.
            if isvalid(obj)
                h.Enable = matlab.lang.OnOffSwitchState(obj.hasAnyLines());
            end
        end

        function refreshRequiresSelection(obj, h)
        %REFRESHREQUIRESSELECTION Enable menu item only when selection exists.
            if isvalid(obj)
                h.Enable = matlab.lang.OnOffSwitchState(obj.hasSelectedLines());
            end
        end

        function overlay = lineOverlayForTarget(obj, target)
        %LINEOVERLAYFORTARGET Return owned Line overlay for a graphics target.
            overlay = obj.Host.Overlays.overlayForTarget(target);
            if ~isa(overlay, 'matlabx.ui.axes.overlays.Line') || ~obj.hasLine(overlay.ID)
                overlay = [];
            end
        end

        function tf = isLineOverlayTarget(obj, target)
        %ISLINEOVERLAYTARGET True when target belongs to an owned Line overlay.
            tf = ~isempty(obj.lineOverlayForTarget(target));
        end

        function part = hitPartForEvent(obj, E, overlay)
        %HITPARTFOREVENT Classify a Line hit as line, midpoint, or endpoint.
            if isempty(overlay)
                part = "";
                return
            end

            tag = "";
            try
                tag = string(E.Target.Tag);
            catch
            end

            if tag ~= "OverlayLineMarkers"
                part = "line";
                return
            end

            xy = obj.Host.cursorPosition;
            if isempty(xy)
                try
                    xy = E.CurrentAxes.CurrentPoint(1,1:2);
                catch
                    part = "line";
                    return
                end
            end

            points = [overlay.Endpoint1; overlay.Midpoint; overlay.Endpoint2];
            distances = hypot(points(:,1) - xy(1), points(:,2) - xy(2));
            [~, idx] = min(distances);

            switch idx
                case 1
                    part = "endpoint1";
                case 2
                    part = "midpoint";
                case 3
                    part = "endpoint2";
            end
        end

        function lineClickedById(obj, id, part, E)
        %LINECLICKEDBYID Apply Line click grammar to an existing line.
            id = obj.normalizeId_(id);
            if ~obj.hasLine(id)
                return
            end

            switch E.MouseChord
                case "click"
                    obj.setActive(id);
                    if obj.Enabled && any(part == ["midpoint", "endpoint1", "endpoint2"])
                        obj.primeDrag(part, E);
                    end

                case "shift+extendclick"
                    if obj.Enabled && any(part == ["endpoint1", "endpoint2"])
                        obj.setActive(id);
                        obj.primeDrag("extend" + erase(part,"endpoint") + "fixed", E);
                    else
                        obj.toggleSelection(id, Emit=true);
                    end

                case "alt+click"
                    if obj.Enabled && any(part == ["midpoint", "endpoint1", "endpoint2"])
                        obj.setActive(id);
                        obj.primeDrag("extendBoth", E);
                    else
                        obj.deactivateActive();
                    end

                case "shift+alt+extendclick"
                    obj.setActive(id);
                    if obj.Enabled
                        obj.primeDrag("extendBothFixed", E);
                    end

                case "control+contextclick"
                    obj.deleteLineById(id);
            end
        end

        function setActive(obj, id)
        %SETACTIVE Make a line active and emit LineActivatedFcn.
            id = obj.normalizeId_(id);
            if ~obj.isValidLineIdx(obj.idxOfId(id))
                return
            end

            obj.Host.Overlays.setActive(id);
            obj.emitActiveChanged(id);
        end

        function deactivateActive(obj)
        %DEACTIVATEACTIVE Clear active line state and emit empty activation.
            if strlength(obj.activeLineId()) == 0
                return
            end

            obj.clearDragModes();
            obj.Host.Overlays.clearActive();
            obj.emitActiveChanged("");
        end

        function toggleSelection(obj, id, opts)
        %TOGGLESELECTION Toggle one line in the selected set.
            arguments
                obj
                id
                opts.Emit (1,1) logical = false
            end

            id = obj.normalizeId_(id);
            if ismember(id, obj.selectedLineIds())
                obj.Host.Overlays.deselect(id);
            else
                obj.Host.Overlays.select(id);
            end

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function primeDrag(obj, part, E)
        %PRIMEDRAG Store drag intent until the cursor actually moves.
            XY = obj.Host.cursorPosition;
            idx = obj.activeLineIdx();
            if isempty(XY) || ~obj.isValidLineIdx(idx)
                return
            end

            obj.PendingDragPart = string(part);
            obj.DragStartFigurePoint = E.CurrentPointFigure;
            obj.DragStartCursor = XY;
            obj.DragStartEndpoints = obj.LineROI(idx).Endpoints;
            obj.DragStartUnitVector = obj.lineUnitVector(obj.DragStartEndpoints);
            obj.setMode('PrimedForDrag', true);
        end

        function startDraggingLine(obj)
        %STARTDRAGGINGLINE Convert primed drag state into a drag mode.
            id = obj.activeLineId();
            if strlength(id) == 0
                obj.setMode('PrimedForDrag', false);
                return
            end

            obj.setMode('PrimedForDrag', false);
            switch obj.PendingDragPart
                case "midpoint"
                    obj.setMode('DragLine', true);
                case "endpoint1"
                    obj.setMode('DragEndpoint1', true);
                case "endpoint2"
                    obj.setMode('DragEndpoint2', true);
                case "extend1fixed"
                    obj.setMode('ExtendEndpoint1FixedAngle', true);
                case "extend2fixed"
                    obj.setMode('ExtendEndpoint2FixedAngle', true);
                case "extendBoth"
                    obj.setMode('ExtendBoth', true);
                case "extendBothFixed"
                    obj.setMode('ExtendBothFixedAngle', true);
            end

            if ~isempty(obj.LineMoveStartedFcn)
                obj.LineMoveStartedFcn(obj, struct('ID', id));
            end
        end

        function clearDragModes(obj)
        %CLEARDRAGMODES Clear all drag-related modes and stored drag state.
            obj.setModeIfPresent('PrimedForDrag', false);
            obj.setModeIfPresent('DragLine', false);
            obj.setModeIfPresent('DragEndpoint1', false);
            obj.setModeIfPresent('DragEndpoint2', false);
            obj.setModeIfPresent('ExtendEndpoint1FixedAngle', false);
            obj.setModeIfPresent('ExtendEndpoint2FixedAngle', false);
            obj.setModeIfPresent('ExtendBoth', false);
            obj.setModeIfPresent('ExtendBothFixedAngle', false);
            obj.PendingDragPart = "";
            obj.clearDragStart();
            obj.DragStartCursor = [NaN NaN];
            obj.DragStartEndpoints = [NaN NaN; NaN NaN];
            obj.DragStartUnitVector = [NaN NaN];
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

        function previewDrawLine(obj)
        %PREVIEWDRAWLINE Update second endpoint while drawing a new line.
            if strlength(obj.DrawingLineID) == 0
                return
            end

            idx = obj.idxOfId(obj.DrawingLineID);
            XY = obj.Host.cursorPosition;
            if isempty(XY) || ~obj.isValidLineIdx(idx)
                return
            end

            obj.LineROI(idx).Endpoint2 = obj.clampPointToImage(XY);
            obj.emitPreviewMoved(obj.LineIds(idx));
        end

        function startDrawingLineOverlay(obj)
        %STARTDRAWINGLINEOVERLAY Create overlay after draw threshold.
            XY = obj.DragStartCursor;
            if isempty(XY) || any(isnan(XY))
                return
            end

            id = matlabx.utils.text.uniqueID();
            obj.addLine(id, [XY; XY]);
            obj.DrawingLineID = id;
            obj.setDrawingLineMarkersVisible("on");

            if ~isempty(obj.LineCreatedFcn)
                obj.LineCreatedFcn(obj, struct('ID', id, 'Endpoints', [XY; XY]));
            end

            if obj.ActivateOnCreate
                obj.emitActiveChanged(id);
            end

            obj.previewDrawLine();
        end

        function setDrawingLineMarkersVisible(obj, value)
        %SETDRAWINGLINEMARKERSVISIBLE Temporarily show handles while drawing.
            idx = obj.idxOfId(obj.DrawingLineID);
            if obj.isValidLineIdx(idx)
                obj.LineROI(idx).AlwaysShowMarkers = value;
            end
        end

        function dragActiveLine(obj)
        %DRAGACTIVELINE Update line geometry while dragging.
            idx = obj.activeLineIdx();
            XY = obj.Host.cursorPosition;
            if isempty(XY) || ~obj.isValidLineIdx(idx)
                return
            end

            endpoints = obj.DragStartEndpoints;
            if obj.Mode.DragLine
                delta = XY - obj.DragStartCursor;
                delta = obj.clampLineTranslationDelta(obj.DragStartEndpoints, delta);
                endpoints = endpoints + delta;
            elseif obj.Mode.DragEndpoint1
                endpoints(1,:) = obj.clampPointToImage(XY);
            elseif obj.Mode.DragEndpoint2
                endpoints(2,:) = obj.clampPointToImage(XY);
            elseif obj.Mode.ExtendEndpoint1FixedAngle
                endpoints = obj.extendOneEndpointFixedAngle(1, XY);
            elseif obj.Mode.ExtendEndpoint2FixedAngle
                endpoints = obj.extendOneEndpointFixedAngle(2, XY);
            elseif obj.Mode.ExtendBoth
                endpoints = obj.extendBothFromMidpoint(XY, PreserveRotation=false);
            elseif obj.Mode.ExtendBothFixedAngle
                endpoints = obj.extendBothFromMidpoint(XY, PreserveRotation=true);
            end

            endpoints = obj.clampEndpointsToImage(endpoints);
            obj.LineROI(idx).Endpoints = endpoints;
            obj.emitPreviewMoved(obj.LineIds(idx));
        end

        function startHoverById(obj, id, part)
        %STARTHOVERBYID Mark a line as hovered and store hover-part mode.
            id = obj.normalizeId_(id);
            if ~obj.hasLine(id)
                return
            end

            obj.Host.Overlays.setHover(id);
            obj.setMode('HoverLine', part == "line");
            obj.setMode('HoverMidpoint', part == "midpoint");
            obj.setMode('HoverEndpoint', any(part == ["endpoint1", "endpoint2"]));
        end

        function stopHover(obj)
        %STOPHOVER Clear hovered Line state and pointer modes.
            hasHoverModes = obj.isMode('HoverLine') ...
                && obj.isMode('HoverMidpoint') ...
                && obj.isMode('HoverEndpoint');

            if ~hasHoverModes
                return
            end

            if ~obj.Mode.HoverLine && ~obj.Mode.HoverMidpoint && ~obj.Mode.HoverEndpoint
                return
            end

            obj.Host.Overlays.clearHover();
            obj.setMode('HoverLine', false);
            obj.setMode('HoverMidpoint', false);
            obj.setMode('HoverEndpoint', false);
        end

        function emitActiveChanged(obj, id)
        %EMITACTIVECHANGED Emit LineActivatedFcn if configured.
            if ~isempty(obj.LineActivatedFcn)
                obj.LineActivatedFcn(obj, struct('ID', obj.normalizeId_(id)));
            end
        end

        function emitSelectionChanged(obj)
        %EMITSELECTIONCHANGED Emit selected Line IDs if callback is configured.
            if ~isempty(obj.LineSelectionChangedFcn)
                obj.LineSelectionChangedFcn(obj, struct('IDs', obj.selectedLineIds()));
            end
        end

        function emitPreviewMoved(obj, id)
        %EMITPREVIEWMOVED Emit high-frequency line geometry preview.
            idx = obj.idxOfId(id);
            if ~obj.isValidLineIdx(idx) || isempty(obj.LinePreviewMovedFcn)
                return
            end

            obj.LinePreviewMovedFcn(obj, struct( ...
                'ID', obj.LineIds(idx), ...
                'Endpoints', obj.LineROI(idx).Endpoints));
        end

        function emitMoveCommitted(obj, id)
        %EMITMOVECOMMITTED Emit committed line geometry.
            idx = obj.idxOfId(id);
            if ~obj.isValidLineIdx(idx) || isempty(obj.LineMoveCommittedFcn)
                return
            end

            obj.LineMoveCommittedFcn(obj, struct( ...
                'ID', obj.LineIds(idx), ...
                'Endpoints', obj.LineROI(idx).Endpoints));
        end
    end

    %% Host-facing methods
    methods
        function addLine(obj, id, endpoints, opts)
        %ADDLINE Create a Line overlay owned by this tool.
            arguments
                obj
                id
                endpoints (2,2) double
                opts.LineColor = []
                opts.LineAlpha = []
                opts.LineWidth = []
                opts.MarkerSize = []
                opts.HoverMarkerSize = []
            end

            endpoints = obj.clampEndpointsToImage(endpoints);
            next = obj.nLines + 1;

            nv = { ...
                "ID", string(id), ...
                "Endpoints", endpoints, ...
                "LineColor", obj.valueOrDefault(opts.LineColor, obj.LineColor), ...
                "LineAlpha", obj.valueOrDefault(opts.LineAlpha, obj.LineAlpha), ...
                "LineWidth", obj.valueOrDefault(opts.LineWidth, obj.LineWidth), ...
                "MarkerSize", obj.valueOrDefault(opts.MarkerSize, obj.MarkerSize), ...
                "HoverMarkerSize", obj.valueOrDefault(opts.HoverMarkerSize, obj.HoverMarkerSize), ...
                "ActivateOnCreate", obj.ActivateOnCreate};

            obj.LineROI(next) = obj.Host.Overlays.add("Line", nv{:});
            obj.LineIds(end+1) = string(id);
        end

        function removeLine(obj, id)
        %REMOVELINE Remove one line by ID.
            idx = obj.idxOfId(id);
            if isempty(idx)
                return
            end
            obj.deleteLineByIdx(idx);
        end

        function clearLines(obj)
        %CLEARLINES Remove all lines owned by this tool.
            ids = obj.LineIds;
            for i = numel(ids):-1:1
                obj.Host.Overlays.remove(ids(i));
            end

            obj.LineROI = matlabx.ui.axes.overlays.Line.empty();
            obj.LineIds = string.empty(1,0);
            obj.DrawingLineID = "";
            obj.clearDragModes();
            obj.stopHover();
        end

        function clearLineSelection(obj, opts)
        %CLEARLINESELECTION Clear selected lines.
            arguments
                obj
                opts.Emit (1,1) logical = false
            end

            obj.Host.Overlays.clearSelection(Type="Line");

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function selectAllLines(obj, opts)
        %SELECTALLLINES Select all lines owned by this tool.
            arguments
                obj
                opts.Emit (1,1) logical = true
            end

            obj.setSelectedLineIDs(obj.LineIds, Emit=opts.Emit);
        end

        function setSelectedLineIDs(obj, ids, opts)
        %SETSELECTEDLINEIDS Replace selected Line IDs.
            arguments
                obj
                ids
                opts.Emit (1,1) logical = false
            end

            ids = string(ids);
            ids = ids(ismember(ids, obj.LineIds));
            obj.Host.Overlays.setSelected(ids(:).', Type="Line");

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function ids = getSelectedLineIDs(obj)
        %GETSELECTEDLINEIDS Return selected Line IDs.
            ids = obj.selectedLineIds();
        end

        function setActiveLineID(obj, id)
        %SETACTIVELINEID Public setter for active line ID.
            id = obj.normalizeId_(id);
            if strlength(id) == 0
                obj.Host.Overlays.clearActive();
                obj.emitActiveChanged("");
            else
                obj.setActive(id);
            end
        end

        function deleteSelectedLines(obj)
        %DELETESELECTEDLINES Delete selected lines owned by this tool.
            ids = obj.selectedLineIds();
            for i = 1:numel(ids)
                obj.deleteLineById(ids(i));
            end
        end

        function deleteAllLines(obj)
        %DELETEALLLINES Delete all lines owned by this tool.
            ids = obj.LineIds;
            for i = numel(ids):-1:1
                obj.deleteLineById(ids(i));
            end
        end
    end

    methods (Access=private)
        function deleteLineById(obj, id)
        %DELETELINEBYID Delete a line and emit LineDeletedFcn.
            id = obj.normalizeId_(id);
            idx = obj.idxOfId(id);
            if ~obj.isValidLineIdx(idx)
                return
            end

            obj.deleteLineByIdx(idx);
            if ~isempty(obj.LineDeletedFcn)
                obj.LineDeletedFcn(obj, struct('ID', id));
            end
        end

        function deleteLineByIdx(obj, idx)
        %DELETELINEBYIDX Delete a local line without emitting LineDeletedFcn.
            if ~obj.isValidLineIdx(idx)
                return
            end

            id = obj.LineIds(idx);
            wasActive = obj.activeLineId() == id;

            obj.Host.Overlays.remove(id);
            obj.LineROI(idx) = [];
            obj.LineIds(idx) = [];

            if wasActive
                obj.emitActiveChanged("");
            end

            obj.emitSelectionChanged();
        end

        function setModeIfPresent(obj, modeName, value)
        %SETMODEIFPRESENT Set a mode only when it still exists.
            if obj.isMode(modeName)
                obj.setMode(modeName, value);
            end
        end

        function tf = isDragging(obj)
        %ISDRAGGING True when any line drag/extension mode is active.
            tf = obj.Mode.DragLine ...
                || obj.Mode.DragEndpoint1 ...
                || obj.Mode.DragEndpoint2 ...
                || obj.Mode.ExtendEndpoint1FixedAngle ...
                || obj.Mode.ExtendEndpoint2FixedAngle ...
                || obj.Mode.ExtendBoth ...
                || obj.Mode.ExtendBothFixedAngle;
        end

        function endpoints = extendOneEndpointFixedAngle(obj, endpointIdx, xy)
        %EXTENDONEENDPOINTFIXEDANGLE Move one endpoint along the original angle.
            endpoints = obj.DragStartEndpoints;
            otherIdx = 3 - endpointIdx;
            origin = endpoints(otherIdx,:);
            direction = obj.endpointDirection(endpointIdx);
            distance = max(dot(xy - origin, direction), 0.5);
            endpoints(endpointIdx,:) = origin + direction .* distance;
            endpoints = obj.clampEndpointsToImage(endpoints);
        end

        function endpoints = extendBothFromMidpoint(obj, xy, opts)
        %EXTENDBOTHFROMMIDPOINT Scale line length symmetrically about midpoint.
            arguments
                obj
                xy (1,2) double
                opts.PreserveRotation (1,1) logical = false
            end

            midpoint = mean(obj.DragStartEndpoints, 1);
            v = xy - midpoint;

            if opts.PreserveRotation
                direction = obj.DragStartUnitVector;
                halfLength = abs(dot(v, direction));
            else
                halfLength = hypot(v(1), v(2));
                if halfLength > eps
                    direction = v ./ halfLength;
                else
                    direction = obj.DragStartUnitVector;
                end
            end

            halfLength = max(halfLength, 0.5);
            endpoints = [midpoint - direction .* halfLength; midpoint + direction .* halfLength];
            endpoints = obj.clampEndpointsToImage(endpoints);
        end

        function direction = endpointDirection(obj, endpointIdx)
        %ENDPOINTDIRECTION Unit vector from the fixed endpoint to the moving endpoint.
            if endpointIdx == 1
                direction = -obj.DragStartUnitVector;
            else
                direction = obj.DragStartUnitVector;
            end
        end

        function direction = lineUnitVector(~, endpoints)
        %LINEUNITVECTOR Return endpoint1-to-endpoint2 unit vector.
            d = endpoints(2,:) - endpoints(1,:);
            L = hypot(d(1), d(2));

            if L <= eps || any(isnan(d))
                direction = [1 0];
            else
                direction = d ./ L;
            end
        end

        function xy = clampPointToImage(obj, xy)
        %CLAMPPOINTTOIMAGE Keep one image-space point inside image bounds.
            xy = double(xy);
            xy(1) = min(max(xy(1), 1), obj.Host.ImageWidth);
            xy(2) = min(max(xy(2), 1), obj.Host.ImageHeight);
        end

        function endpoints = clampEndpointsToImage(obj, endpoints)
        %CLAMPENDPOINTSTOIMAGE Clamp both line endpoints to image bounds.
            endpoints = double(endpoints);
            endpoints(:,1) = min(max(endpoints(:,1), 1), obj.Host.ImageWidth);
            endpoints(:,2) = min(max(endpoints(:,2), 1), obj.Host.ImageHeight);
        end

        function delta = clampLineTranslationDelta(obj, endpoints, delta)
        %CLAMPLINETRANSLATIONDELTA Limit translation without changing shape.
            endpoints = double(endpoints);
            delta = double(delta);

            minX = min(endpoints(:,1));
            maxX = max(endpoints(:,1));
            minY = min(endpoints(:,2));
            maxY = max(endpoints(:,2));

            delta(1) = min(max(delta(1), 1 - minX), obj.Host.ImageWidth - maxX);
            delta(2) = min(max(delta(2), 1 - minY), obj.Host.ImageHeight - maxY);
        end
    end

    %% Host update helpers
    methods
        function pointer = getPreferredPointer(obj)
        %GETPREFERREDPOINTER Return pointer requested by current Line state.
            if obj.Mode.DragLine
                pointer = 'fleur';
            elseif obj.Mode.ExtendBoth || obj.Mode.ExtendBothFixedAngle
                pointer = 'fleur';
            elseif obj.Mode.DragEndpoint1 || obj.Mode.DragEndpoint2 ...
                    || obj.Mode.ExtendEndpoint1FixedAngle || obj.Mode.ExtendEndpoint2FixedAngle
                pointer = 'circle';
            elseif obj.Mode.DrawingLine
                pointer = 'crosshair';
            elseif obj.Mode.HoverMidpoint
                pointer = 'fleur';
            elseif obj.Mode.HoverEndpoint
                pointer = 'circle';
            elseif obj.Mode.HoverLine
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
        %TEARDOWN Delete Line overlays during tool destruction.
            try
                obj.clearLines();
            catch
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
