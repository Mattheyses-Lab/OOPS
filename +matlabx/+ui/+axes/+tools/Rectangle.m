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

classdef Rectangle < matlabx.ui.axes.AxesTool
%RECTANGLE Draw and manipulate rectangle overlays in ImageAxes.
%
%   The Rectangle tool is an interaction controller for overlays.Rectangle.
%   It creates axis-aligned rectangles by click-dragging in empty image space,
%   activates existing rectangles, toggles selection, translates by dragging
%   the rectangle body, and resizes from corner or edge handles.

    properties
        EdgeColor = [1 1 1]
        EdgeAlpha (1,1) double {mustBeGreaterThanOrEqual(EdgeAlpha,0), mustBeLessThanOrEqual(EdgeAlpha,1)} = 1
        LineWidth (1,1) double {mustBePositive} = 1
        MarkerSize (1,1) double {mustBePositive} = 4
        HoverMarkerSize (1,1) double {mustBePositive} = 5
        ActivateOnCreate (1,1) logical = true
        DragStartThresholdPx (1,1) double {mustBeNonnegative} = 3
    end

    properties
        RectangleCreatedFcn
        RectangleMoveStartedFcn
        RectanglePreviewMovedFcn
        RectangleMoveCommittedFcn
        RectangleDeletedFcn
        RectangleActivatedFcn
        RectangleSelectionChangedFcn
    end

    properties (SetAccess=private, Dependent)
        nRectangles
    end

    properties (Access=private, Transient, NonCopyable)
        RectangleROI (:,1) matlabx.ui.axes.overlays.Rectangle
    end

    properties (Access=private)
        RectangleIds (1,:) string = string.empty(1,0)
        DrawingRectangleID (1,1) string = ""
        HoverPart (1,1) string = ""
        PendingDragPart (1,1) string = ""
        DragStartFigurePoint (1,2) double = [NaN NaN]
        DragStartCursor (1,2) double = [NaN NaN]
        DragStartPosition (1,4) double = [NaN NaN NaN NaN]
    end

    methods
        function obj = Rectangle(host)
        %RECTANGLE Create the Rectangle tool for one ImageAxes host.
            obj@matlabx.ui.axes.AxesTool(host, "Rectangle", ...
                'Tooltip', 'Rectangle overlays', ...
                'AxesType', "image", ...
                'Icon', matlabx.internal.Paths.icons('Rectangle.png'), ...
                'Priority', 9, ...
                'IsExclusive', true, ...
                'InterceptsDown', true, ...
                'InterceptsMove', true, ...
                'InterceptsUp', true, ...
                'PassivelyInterceptsDown', true, ...
                'PassivelyInterceptsMove', true);

            obj.RectangleROI = matlabx.ui.axes.overlays.Rectangle.empty();
        end

        function onInstall(obj)
        %ONINSTALL Register tool-owned interaction modes.
            obj.addMode('DrawingRectangle');
            obj.addMode('PrimedForDrag');
            obj.addMode('DragRectangle');
            obj.addMode('ResizeRectangle');
            obj.addMode('HoverRectangle');
            obj.addMode('HoverHandle');
        end

        function onUninstall(obj)
        %ONUNINSTALL Remove modes and rectangle overlays owned by this tool.
            obj.clearRectangles();
            obj.removeMode('DrawingRectangle');
            obj.removeMode('PrimedForDrag');
            obj.removeMode('DragRectangle');
            obj.removeMode('ResizeRectangle');
            obj.removeMode('HoverRectangle');
            obj.removeMode('HoverHandle');
        end

        function contributeContextMenu(obj, menu)
        %CONTRIBUTECONTEXTMENU Add Rectangle commands to the host context menu.
            menu.addSubmenu( ...
                "Rectangle", ...
                "Rectangle", ...
                "Owner", obj);

            menu.addItem( ...
                "Rectangle.ClearSelection", ...
                "Clear Selection", ...
                @(~,~) obj.clearRectangleSelection(Emit=true), ...
                "Parent", "Rectangle", ...
                "Owner", obj, ...
                "Separator", "on", ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasSelectedRectangles()), ...
                "RefreshFcn", @(h) obj.refreshRequiresSelection(h));

            menu.addItem( ...
                "Rectangle.SelectAll", ...
                "Select All", ...
                @(~,~) obj.selectAllRectangles(), ...
                "Parent", "Rectangle", ...
                "Owner", obj, ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasAnyRectangles()), ...
                "RefreshFcn", @(h) obj.refreshRequiresRectangles(h));

            menu.addItem( ...
                "Rectangle.DeleteSelected", ...
                "Delete Selected", ...
                @(~,~) obj.deleteSelectedRectangles(), ...
                "Parent", "Rectangle", ...
                "Owner", obj, ...
                "Separator", "on", ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasSelectedRectangles()), ...
                "RefreshFcn", @(h) obj.refreshRequiresSelection(h));

            menu.addItem( ...
                "Rectangle.DeleteAll", ...
                "Delete All", ...
                @(~,~) obj.deleteAllRectangles(), ...
                "Parent", "Rectangle", ...
                "Owner", obj, ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasAnyRectangles()), ...
                "RefreshFcn", @(h) obj.refreshRequiresRectangles(h));

            menu.addItem( ...
                "Rectangle.Help", ...
                "Help...", ...
                @(~,~) obj.Host.openToolHelpWindow(obj), ...
                "Parent", "Rectangle", ...
                "Owner", obj, ...
                "Separator", "on");
        end
    end

    %% Help
    methods
        function summary = getHelpSummary(~)
        %GETHELPSUMMARY Return a one-line Rectangle description.
            summary = "Create, activate, select, translate, and resize rectangle overlays.";
        end

        function usage = getUsageHelp(~)
        %GETUSAGEHELP Return short Rectangle usage notes.
            usage = [ ...
                "Enable Rectangle and click-drag empty image space to create a rectangle."; ...
                "Click an existing rectangle to activate it."; ...
                "Drag inside an active rectangle to translate it."; ...
                "Drag corner or side handles to resize it."];
        end

        function B = getBindingHelp(obj)
        %GETBINDINGHELP Return Rectangle click binding descriptions.
            B = struct( ...
                "ToggleTool", obj.ToggleHotkey, ...
                "CreateRectangle", "click-drag image background while Rectangle is enabled", ...
                "Activate", "click rectangle", ...
                "ToggleSelection", "shift+extendclick rectangle", ...
                "ClearSelection", "shift+doubleclick image background", ...
                "Deactivate", "alt+click rectangle", ...
                "DeleteRectangle", "control+contextclick rectangle", ...
                "Translate", "click-drag rectangle body", ...
                "Resize", "click-drag corner or side handle", ...
                "ForceSquare", "hold shift while drawing or resizing", ...
                "ResizeFromCenter", "hold alt while drawing or resizing");
        end

        function notes = getNotesHelp(~)
        %GETNOTESHELP Return additional Rectangle behavior notes.
            notes = [ ...
                "Rectangle overlay state is owned by ImageAxes.Overlays."; ...
                "The Rectangle tool emits rectangle-specific callbacks for app controllers."; ...
                "Handles are shown while a rectangle is hovered or active."];
        end
    end

    %% Active event hooks
    methods
        function onDown(obj, E)
        %ONDOWN Start drawing a rectangle from a background click.
            if obj.isRectangleOverlayTarget(E.Target)
                return
            end

            if E.MouseChord == "shift+doubleclick"
                obj.clearRectangleSelection(Emit=true);
                E.stop();
                return
            end

            if ~any(E.MouseChord == ["click", "shift+extendclick", ...
                    "alt+click", "shift+alt+extendclick"])
                return
            end

            XY = obj.Host.cursorPosition;
            if isempty(XY)
                return
            end

            obj.DrawingRectangleID = "";
            obj.DragStartFigurePoint = E.CurrentPointFigure;
            obj.DragStartCursor = XY;
            obj.setMode('DrawingRectangle', true);
            E.stop();
        end

        function onMove(obj, E)
        %ONMOVE Update drawing or drag preview while mouse is down.
            if obj.Mode.DrawingRectangle
                obj.previewDrawRectangle(E);
                return
            end

            if obj.Mode.PrimedForDrag
                if ~obj.hasExceededDragThreshold(E)
                    return
                end

                obj.startDraggingRectangle();
                return
            end

            if obj.isDragging()
                obj.dragActiveRectangle(E);
            end
        end

        function onUp(obj, E)
        %ONUP Commit rectangle drawing or drag state.
            if obj.Mode.DrawingRectangle
                id = obj.DrawingRectangleID;
                if strlength(id) > 0
                    obj.previewDrawRectangle(E);
                    obj.emitMoveCommitted(id);
                end
                obj.setMode('DrawingRectangle', false);
                obj.setDrawingRectangleMarkersVisible("off");
                obj.DrawingRectangleID = "";
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
                id = obj.activeRectangleId();
                obj.dragActiveRectangle(E);
                obj.clearDragModes();
                obj.emitMoveCommitted(id);
            end
        end
    end

    %% Passive event hooks
    methods
        function onPassiveDown(obj, E)
        %ONPASSIVEDOWN Handle clicks on existing Rectangle overlays.
            overlay = obj.rectangleOverlayForTarget(E.Target);
            if isempty(overlay) || ~obj.hasRectangle(overlay.ID)
                return
            end

            part = obj.hitPartForEvent(E, overlay);
            obj.rectangleClickedById(overlay.ID, part, E);
            E.stop();
        end

        function onPassiveMove(obj, E)
        %ONPASSIVEMOVE Update hover state for existing Rectangle overlays.
            if obj.Mode.DrawingRectangle || obj.Mode.PrimedForDrag || obj.isDragging()
                return
            end

            overlay = obj.rectangleOverlayForTarget(E.Target);
            if isempty(overlay) || ~obj.hasRectangle(overlay.ID)
                obj.stopHover();
                return
            end

            part = obj.hitPartForEvent(E, overlay);
            obj.startHoverById(overlay.ID, part);
        end
    end

    %% Derived getters
    methods
        function n = get.nRectangles(obj)
        %GET.NRECTANGLES Return number of valid Rectangle overlays owned by this tool.
            if isempty(obj.RectangleROI)
                n = 0;
            else
                n = sum(isvalid(obj.RectangleROI));
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
        %IDXOFID Return local RectangleROI index for an ID.
            id = obj.normalizeId_(id);
            if strlength(id) == 0
                idx = [];
                return
            end

            idx = find(obj.RectangleIds == id, 1, 'first');
        end

        function tf = isValidRectangleIdx(obj, idx)
        %ISVALIDRECTANGLEIDX True when idx addresses a valid Rectangle overlay.
            tf = ~isempty(idx) ...
                && isscalar(idx) ...
                && idx >= 1 ...
                && idx <= numel(obj.RectangleROI) ...
                && isvalid(obj.RectangleROI(idx));
        end

        function tf = hasRectangle(obj, id)
        %HASRECTANGLE True when this tool owns a rectangle with ID.
            id = obj.normalizeId_(id);
            tf = strlength(id) > 0 && ismember(id, obj.RectangleIds);
        end

        function id = activeRectangleId(obj)
        %ACTIVERECTANGLEID Return active Rectangle ID owned by this tool.
            id = obj.Host.Overlays.getActiveID(Type="Rectangle");
            if ~obj.hasRectangle(id)
                id = "";
            end
        end

        function idx = activeRectangleIdx(obj)
        %ACTIVERECTANGLEIDX Return local index of manager-active Rectangle overlay.
            idx = obj.idxOfId(obj.activeRectangleId());
        end

        function ids = selectedRectangleIds(obj)
        %SELECTEDRECTANGLEIDS Return selected Rectangle IDs owned by this tool.
            ids = obj.Host.Overlays.getSelectedIDs(Type="Rectangle");
            ids = ids(ismember(ids, obj.RectangleIds));
        end

        function tf = hasAnyRectangles(obj)
        %HASANYRECTANGLES True when this tool owns at least one rectangle.
            tf = ~isempty(obj.RectangleROI) && any(isvalid(obj.RectangleROI));
        end

        function tf = hasSelectedRectangles(obj)
        %HASSELECTEDRECTANGLES True when this tool owns selected rectangles.
            tf = ~isempty(obj.selectedRectangleIds());
        end

        function refreshRequiresRectangles(obj, h)
        %REFRESHREQUIRESRECTANGLES Enable menu item only when rectangles exist.
            if isvalid(obj)
                h.Enable = matlab.lang.OnOffSwitchState(obj.hasAnyRectangles());
            end
        end

        function refreshRequiresSelection(obj, h)
        %REFRESHREQUIRESSELECTION Enable menu item only when selection exists.
            if isvalid(obj)
                h.Enable = matlab.lang.OnOffSwitchState(obj.hasSelectedRectangles());
            end
        end

        function overlay = rectangleOverlayForTarget(obj, target)
        %RECTANGLEOVERLAYFORTARGET Return owned Rectangle overlay for target.
            overlay = obj.Host.Overlays.overlayForTarget(target);
            if ~isa(overlay, 'matlabx.ui.axes.overlays.Rectangle') || ~obj.hasRectangle(overlay.ID)
                overlay = [];
            end
        end

        function tf = isRectangleOverlayTarget(obj, target)
        %ISRECTANGLEOVERLAYTARGET True when target belongs to an owned Rectangle.
            tf = ~isempty(obj.rectangleOverlayForTarget(target));
        end

        function part = hitPartForEvent(obj, E, overlay)
        %HITPARTFOREVENT Classify Rectangle hit as body or one of 8 handles.
            if isempty(overlay)
                part = "";
                return
            end

            tag = "";
            try
                tag = string(E.Target.Tag);
            catch
            end

            if tag ~= "OverlayRectangleMarkers"
                part = "body";
                return
            end

            xy = obj.Host.cursorPosition;
            if isempty(xy)
                try
                    xy = E.CurrentAxes.CurrentPoint(1,1:2);
                catch
                    part = "body";
                    return
                end
            end

            points = overlay.HandlePoints;
            distances = hypot(points(:,1) - xy(1), points(:,2) - xy(2));
            [~, idx] = min(distances);

            names = ["bottomLeft","bottom","bottomRight","right", ...
                "topRight","top","topLeft","left"];
            part = names(idx);
        end

        function rectangleClickedById(obj, id, part, E)
        %RECTANGLECLICKEDBYID Apply Rectangle click grammar to an existing rectangle.
            id = obj.normalizeId_(id);
            if ~obj.hasRectangle(id)
                return
            end

            switch E.MouseChord
                case "click"
                    obj.setActive(id);
                    if obj.Enabled
                        obj.primeDrag(part, E);
                    end

                case "shift+extendclick"
                    obj.toggleSelection(id, Emit=true);

                case "alt+click"
                    obj.deactivateActive();

                case "control+contextclick"
                    obj.deleteRectangleById(id);
            end
        end

        function setActive(obj, id)
        %SETACTIVE Make a rectangle active and emit RectangleActivatedFcn.
            id = obj.normalizeId_(id);
            if ~obj.isValidRectangleIdx(obj.idxOfId(id))
                return
            end

            obj.Host.Overlays.setActive(id);
            obj.emitActiveChanged(id);
        end

        function deactivateActive(obj)
        %DEACTIVATEACTIVE Clear active rectangle state and emit empty activation.
            if strlength(obj.activeRectangleId()) == 0
                return
            end

            obj.clearDragModes();
            obj.Host.Overlays.clearActive();
            obj.emitActiveChanged("");
        end

        function toggleSelection(obj, id, opts)
        %TOGGLESELECTION Toggle one rectangle in the selected set.
            arguments
                obj
                id
                opts.Emit (1,1) logical = false
            end

            id = obj.normalizeId_(id);
            if ismember(id, obj.selectedRectangleIds())
                obj.Host.Overlays.deselect(id);
            else
                obj.Host.Overlays.select(id);
            end

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function primeDrag(obj, part, E)
        %PRIMEDRAG Store drag intent until cursor motion crosses threshold.
            XY = obj.Host.cursorPosition;
            idx = obj.activeRectangleIdx();
            if isempty(XY) || ~obj.isValidRectangleIdx(idx)
                return
            end

            obj.PendingDragPart = string(part);
            obj.DragStartFigurePoint = E.CurrentPointFigure;
            obj.DragStartCursor = XY;
            obj.DragStartPosition = obj.RectangleROI(idx).Position;
            obj.setMode('PrimedForDrag', true);
        end

        function startDraggingRectangle(obj)
        %STARTDRAGGINGRECTANGLE Convert primed drag state into a drag mode.
            id = obj.activeRectangleId();
            if strlength(id) == 0
                obj.setMode('PrimedForDrag', false);
                return
            end

            obj.setMode('PrimedForDrag', false);
            if obj.PendingDragPart == "body"
                obj.setMode('DragRectangle', true);
            else
                obj.setMode('ResizeRectangle', true);
            end

            if ~isempty(obj.RectangleMoveStartedFcn)
                obj.RectangleMoveStartedFcn(obj, struct('ID', id));
            end
        end

        function clearDragModes(obj)
        %CLEARDRAGMODES Clear drag modes and stored drag state.
            obj.setModeIfPresent('PrimedForDrag', false);
            obj.setModeIfPresent('DragRectangle', false);
            obj.setModeIfPresent('ResizeRectangle', false);
            obj.PendingDragPart = "";
            obj.clearDragStart();
            obj.DragStartCursor = [NaN NaN];
            obj.DragStartPosition = [NaN NaN NaN NaN];
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

        function previewDrawRectangle(obj, E)
        %PREVIEWDRAWRECTANGLE Update opposite corner while drawing.
            if strlength(obj.DrawingRectangleID) == 0
                if ~obj.hasExceededDragThreshold(E)
                    return
                end

                obj.startDrawingRectangleOverlay(E);
            end

            idx = obj.idxOfId(obj.DrawingRectangleID);
            XY = obj.Host.cursorPosition;
            if isempty(XY) || ~obj.isValidRectangleIdx(idx)
                return
            end

            p0 = obj.DragStartCursor;
            if any(isnan(p0))
                p0 = obj.RectangleROI(idx).Position(1:2);
            end

            obj.RectangleROI(idx).Position = ...
                obj.drawPosition(p0, XY, E.hasModifier("shift"), E.hasModifier("alt"));
            obj.emitPreviewMoved(obj.RectangleIds(idx));
        end

        function startDrawingRectangleOverlay(obj, E)
        %STARTDRAWINGRECTANGLEOVERLAY Create overlay after draw threshold.
            XY = obj.DragStartCursor;
            if isempty(XY) || any(isnan(XY))
                return
            end

            id = matlabx.utils.text.uniqueID();
            obj.addRectangle(id, [XY 0 0]);
            obj.DrawingRectangleID = id;
            obj.setDrawingRectangleMarkersVisible("on");

            if ~isempty(obj.RectangleCreatedFcn)
                obj.RectangleCreatedFcn(obj, struct('ID', id, 'Position', [XY 0 0]));
            end

            if obj.ActivateOnCreate
                obj.emitActiveChanged(id);
            end

            obj.previewDrawRectangle(E);
        end

        function setDrawingRectangleMarkersVisible(obj, value)
        %SETDRAWINGRECTANGLEMARKERSVISIBLE Temporarily show handles while drawing.
            idx = obj.idxOfId(obj.DrawingRectangleID);
            if obj.isValidRectangleIdx(idx)
                obj.RectangleROI(idx).AlwaysShowMarkers = value;
            end
        end

        function dragActiveRectangle(obj, E)
        %DRAGACTIVERECTANGLE Update rectangle geometry while dragging.
            idx = obj.activeRectangleIdx();
            XY = obj.Host.cursorPosition;
            if isempty(XY) || ~obj.isValidRectangleIdx(idx)
                return
            end

            pos = obj.DragStartPosition;
            if obj.Mode.DragRectangle
                delta = XY - obj.DragStartCursor;
                pos(1:2) = pos(1:2) + delta;
                pos = obj.clampRectangleTranslation(pos);
            elseif obj.Mode.ResizeRectangle
                pos = obj.resizedPosition(pos, XY, obj.PendingDragPart, ...
                    E.hasModifier("shift"), E.hasModifier("alt"));
            end

            obj.RectangleROI(idx).Position = pos;
            obj.emitPreviewMoved(obj.RectangleIds(idx));
        end

        function pos = resizedPosition(obj, startPos, XY, part, forceSquare, fromCenter)
        %RESIZEDPOSITION Resize startPos by moving edges implied by part.
            x1 = startPos(1);
            y1 = startPos(2);
            x2 = startPos(1) + startPos(3);
            y2 = startPos(2) + startPos(4);

            part = string(part);

            if fromCenter
                pos = obj.centerResizedPosition(startPos, XY, part, forceSquare);
                return
            end

            if forceSquare
                pos = obj.squareResizedPosition(startPos, XY, part);
                return
            end

            switch part
                case {"bottomLeft","left","topLeft"}
                    x1 = XY(1);
                case {"bottomRight","right","topRight"}
                    x2 = XY(1);
            end

            switch part
                case {"bottomLeft","bottom","bottomRight"}
                    y1 = XY(2);
                case {"topLeft","top","topRight"}
                    y2 = XY(2);
            end

            pos = obj.clampRectanglePosition([min(x1,x2), min(y1,y2), abs(x2-x1), abs(y2-y1)]);
        end

        function pos = centerResizedPosition(obj, startPos, XY, part, forceSquare)
        %CENTERRESIZEDPOSITION Resize symmetrically around the start center.
            cx = startPos(1) + startPos(3)/2;
            cy = startPos(2) + startPos(4)/2;
            dx = abs(XY(1) - cx);
            dy = abs(XY(2) - cy);
            maxDx = min(cx - 1, obj.Host.ImageWidth - cx);
            maxDy = min(cy - 1, obj.Host.ImageHeight - cy);

            switch string(part)
                case {"left", "right"}
                    dy = startPos(4)/2;
                case {"top", "bottom"}
                    dx = startPos(3)/2;
                case "body"
                    pos = startPos;
                    return
            end

            if forceSquare
                sideHalf = min(max(dx, dy), min(maxDx, maxDy));
                dx = sideHalf;
                dy = sideHalf;
            elseif any(string(part) == ["bottomLeft", "bottomRight", "topLeft", "topRight"])
                [dx, dy] = obj.limitCoupledHalfSize(dx, dy, maxDx, maxDy);
            else
                dx = min(dx, maxDx);
                dy = min(dy, maxDy);
            end

            pos = [cx - dx, cy - dy, 2*dx, 2*dy];
        end

        function pos = squareResizedPosition(obj, startPos, XY, part)
        %SQUARERESIZEDPOSITION Resize while preserving square aspect ratio.
            x1 = startPos(1);
            y1 = startPos(2);
            x2 = startPos(1) + startPos(3);
            y2 = startPos(2) + startPos(4);
            cx = x1 + startPos(3)/2;
            cy = y1 + startPos(4)/2;

            switch string(part)
                case "bottomLeft"
                    pos = obj.positionFromCorners([x2 y2], XY, true);
                case "bottomRight"
                    pos = obj.positionFromCorners([x1 y2], XY, true);
                case "topRight"
                    pos = obj.positionFromCorners([x1 y1], XY, true);
                case "topLeft"
                    pos = obj.positionFromCorners([x2 y1], XY, true);
                case "left"
                    side = abs(x2 - XY(1));
                    direction = obj.nonzeroSign(XY(1) - x2);
                    side = obj.limitSideFromVerticalEdge(side, x2, cy, direction);
                    xEdge = x2 + direction * side;
                    pos = [min(xEdge, x2), cy - side/2, side, side];
                case "right"
                    side = abs(XY(1) - x1);
                    direction = obj.nonzeroSign(XY(1) - x1);
                    side = obj.limitSideFromVerticalEdge(side, x1, cy, direction);
                    xEdge = x1 + direction * side;
                    pos = [min(x1, xEdge), cy - side/2, side, side];
                case "bottom"
                    side = abs(y2 - XY(2));
                    direction = obj.nonzeroSign(XY(2) - y2);
                    side = obj.limitSideFromHorizontalEdge(side, cx, y2, direction);
                    yEdge = y2 + direction * side;
                    pos = [cx - side/2, min(yEdge, y2), side, side];
                case "top"
                    side = abs(XY(2) - y1);
                    direction = obj.nonzeroSign(XY(2) - y1);
                    side = obj.limitSideFromHorizontalEdge(side, cx, y1, direction);
                    yEdge = y1 + direction * side;
                    pos = [cx - side/2, min(y1, yEdge), side, side];
                otherwise
                    pos = startPos;
            end
        end

        function pos = drawPosition(obj, p0, XY, forceSquare, fromCenter)
        %DRAWPOSITION Return rectangle position while drawing a new rectangle.
            p0 = obj.clampPointToImage(p0);
            XY = obj.clampPointToImage(XY);

            if fromCenter
                dx = abs(XY(1) - p0(1));
                dy = abs(XY(2) - p0(2));
                if forceSquare
                    maxHalfSide = min([p0(1) - 1, obj.Host.ImageWidth - p0(1), ...
                        p0(2) - 1, obj.Host.ImageHeight - p0(2)]);
                    halfSide = min(max(dx, dy), maxHalfSide);
                    dx = halfSide;
                    dy = halfSide;
                else
                    maxDx = min(p0(1) - 1, obj.Host.ImageWidth - p0(1));
                    maxDy = min(p0(2) - 1, obj.Host.ImageHeight - p0(2));
                    [dx, dy] = obj.limitCoupledHalfSize(dx, dy, maxDx, maxDy);
                end

                pos = [p0(1)-dx, p0(2)-dy, 2*dx, 2*dy];
            else
                pos = obj.positionFromCorners(p0, XY, forceSquare);
            end
        end

        function pos = positionFromCorners(obj, p1, p2, forceSquare)
        %POSITIONFROMCORNERS Return [x y w h] from two opposing corners.
            if forceSquare
                delta = p2 - p1;
                side = max(abs(delta));
                direction = sign(delta);
                direction(direction == 0) = 1;

                maxX = obj.maxDistanceToBoundary(p1(1), direction(1), obj.Host.ImageWidth);
                maxY = obj.maxDistanceToBoundary(p1(2), direction(2), obj.Host.ImageHeight);
                side = min(side, min(maxX, maxY));
                p2 = p1 + direction .* side;
            end

            pos = [min(p1(1),p2(1)), min(p1(2),p2(2)), ...
                abs(p2(1)-p1(1)), abs(p2(2)-p1(2))];
        end

        function xy = clampPointToImage(obj, xy)
        %CLAMPPOINTTOIMAGE Keep one image-space point inside image bounds.
            xy = double(xy);
            xy(1) = min(max(xy(1), 1), obj.Host.ImageWidth);
            xy(2) = min(max(xy(2), 1), obj.Host.ImageHeight);
        end

        function pos = clampRectanglePosition(obj, pos)
        %CLAMPRECTANGLEPOSITION Keep rectangle extent inside image bounds.
            pos = double(pos);
            x1 = min(pos(1), pos(1) + pos(3));
            x2 = max(pos(1), pos(1) + pos(3));
            y1 = min(pos(2), pos(2) + pos(4));
            y2 = max(pos(2), pos(2) + pos(4));

            x1 = min(max(x1, 1), obj.Host.ImageWidth);
            x2 = min(max(x2, 1), obj.Host.ImageWidth);
            y1 = min(max(y1, 1), obj.Host.ImageHeight);
            y2 = min(max(y2, 1), obj.Host.ImageHeight);

            pos = [min(x1,x2), min(y1,y2), abs(x2-x1), abs(y2-y1)];
        end

        function pos = clampRectangleTranslation(obj, pos)
        %CLAMPRECTANGLETRANSLATION Shift a rectangle back inside image bounds.
            pos = double(pos);
            pos(3) = min(pos(3), obj.Host.ImageWidth - 1);
            pos(4) = min(pos(4), obj.Host.ImageHeight - 1);

            if pos(3) >= obj.Host.ImageWidth
                pos(1) = 1;
            else
                pos(1) = min(max(pos(1), 1), obj.Host.ImageWidth - pos(3));
            end

            if pos(4) >= obj.Host.ImageHeight
                pos(2) = 1;
            else
                pos(2) = min(max(pos(2), 1), obj.Host.ImageHeight - pos(4));
            end
        end

        function maxDistance = maxDistanceToBoundary(~, value, direction, upperBound)
        %MAXDISTANCETOBOUNDARY Return signed-direction distance to image edge.
            if direction < 0
                maxDistance = value - 1;
            else
                maxDistance = upperBound - value;
            end
            maxDistance = max(maxDistance, 0);
        end

        function side = limitSideFromVerticalEdge(obj, side, fixedX, centerY, direction)
        %LIMITSIDEFROMVERTICALEDGE Cap square side for left/right handles.
            maxHorizontal = obj.maxDistanceToBoundary(fixedX, direction, obj.Host.ImageWidth);
            maxVertical = 2 * min(centerY - 1, obj.Host.ImageHeight - centerY);
            side = min(side, min(maxHorizontal, maxVertical));
        end

        function side = limitSideFromHorizontalEdge(obj, side, centerX, fixedY, direction)
        %LIMITSIDEFROMHORIZONTALEDGE Cap square side for top/bottom handles.
            maxVertical = obj.maxDistanceToBoundary(fixedY, direction, obj.Host.ImageHeight);
            maxHorizontal = 2 * min(centerX - 1, obj.Host.ImageWidth - centerX);
            side = min(side, min(maxHorizontal, maxVertical));
        end

        function [dx, dy] = limitCoupledHalfSize(~, dx, dy, maxDx, maxDy)
        %LIMITCOUPLEDHALFSIZE Scale centered half-size until first boundary.
            maxDx = max(maxDx, 0);
            maxDy = max(maxDy, 0);
            scale = 1;

            if dx > maxDx && dx > 0
                scale = min(scale, maxDx / dx);
            end

            if dy > maxDy && dy > 0
                scale = min(scale, maxDy / dy);
            end

            dx = dx * scale;
            dy = dy * scale;
        end

        function value = nonzeroSign(~, value)
        %NONZEROSIGN Return sign(value), using +1 when value is zero.
            value = sign(value);
            if value == 0
                value = 1;
            end
        end

        function startHoverById(obj, id, part)
        %STARTHOVERBYID Mark a rectangle as hovered and store hover-part mode.
            id = obj.normalizeId_(id);
            if ~obj.hasRectangle(id)
                return
            end

            obj.Host.Overlays.setHover(id);
            obj.HoverPart = string(part);
            obj.setMode('HoverRectangle', part == "body");
            obj.setMode('HoverHandle', part ~= "body");
        end

        function stopHover(obj)
        %STOPHOVER Clear hovered Rectangle state and pointer modes.
            hasHoverModes = obj.isMode('HoverRectangle') && obj.isMode('HoverHandle');
            if ~hasHoverModes
                return
            end

            if ~obj.Mode.HoverRectangle && ~obj.Mode.HoverHandle
                return
            end

            obj.Host.Overlays.clearHover();
            obj.HoverPart = "";
            obj.setMode('HoverRectangle', false);
            obj.setMode('HoverHandle', false);
        end

        function emitActiveChanged(obj, id)
        %EMITACTIVECHANGED Emit RectangleActivatedFcn if configured.
            if ~isempty(obj.RectangleActivatedFcn)
                obj.RectangleActivatedFcn(obj, struct('ID', obj.normalizeId_(id)));
            end
        end

        function emitSelectionChanged(obj)
        %EMITSELECTIONCHANGED Emit selected Rectangle IDs if configured.
            if ~isempty(obj.RectangleSelectionChangedFcn)
                obj.RectangleSelectionChangedFcn(obj, struct('IDs', obj.selectedRectangleIds()));
            end
        end

        function emitPreviewMoved(obj, id)
        %EMITPREVIEWMOVED Emit high-frequency rectangle geometry preview.
            idx = obj.idxOfId(id);
            if ~obj.isValidRectangleIdx(idx) || isempty(obj.RectanglePreviewMovedFcn)
                return
            end

            obj.RectanglePreviewMovedFcn(obj, struct( ...
                'ID', obj.RectangleIds(idx), ...
                'Position', obj.RectangleROI(idx).Position));
        end

        function emitMoveCommitted(obj, id)
        %EMITMOVECOMMITTED Emit committed rectangle geometry.
            idx = obj.idxOfId(id);
            if ~obj.isValidRectangleIdx(idx) || isempty(obj.RectangleMoveCommittedFcn)
                return
            end

            obj.RectangleMoveCommittedFcn(obj, struct( ...
                'ID', obj.RectangleIds(idx), ...
                'Position', obj.RectangleROI(idx).Position));
        end
    end

    %% Host-facing methods
    methods
        function addRectangle(obj, id, position, opts)
        %ADDRECTANGLE Create a Rectangle overlay owned by this tool.
            arguments
                obj
                id
                position (1,4) double
                opts.EdgeColor = []
                opts.EdgeAlpha = []
                opts.LineWidth = []
                opts.MarkerSize = []
                opts.HoverMarkerSize = []
            end

            position = obj.clampRectanglePosition(position);
            next = obj.nRectangles + 1;

            nv = { ...
                "ID", string(id), ...
                "Position", position, ...
                "EdgeColor", obj.valueOrDefault(opts.EdgeColor, obj.EdgeColor), ...
                "EdgeAlpha", obj.valueOrDefault(opts.EdgeAlpha, obj.EdgeAlpha), ...
                "LineWidth", obj.valueOrDefault(opts.LineWidth, obj.LineWidth), ...
                "MarkerSize", obj.valueOrDefault(opts.MarkerSize, obj.MarkerSize), ...
                "HoverMarkerSize", obj.valueOrDefault(opts.HoverMarkerSize, obj.HoverMarkerSize), ...
                "ActivateOnCreate", obj.ActivateOnCreate};

            obj.RectangleROI(next) = obj.Host.Overlays.add("Rectangle", nv{:});
            obj.RectangleIds(end+1) = string(id);
            obj.DragStartCursor = position(1:2);
        end

        function removeRectangle(obj, id)
        %REMOVERECTANGLE Remove one rectangle by ID.
            idx = obj.idxOfId(id);
            if isempty(idx)
                return
            end
            obj.deleteRectangleByIdx(idx);
        end

        function clearRectangles(obj)
        %CLEARRECTANGLES Remove all rectangles owned by this tool.
            ids = obj.RectangleIds;
            for i = numel(ids):-1:1
                obj.Host.Overlays.remove(ids(i));
            end

            obj.RectangleROI = matlabx.ui.axes.overlays.Rectangle.empty();
            obj.RectangleIds = string.empty(1,0);
            obj.DrawingRectangleID = "";
            obj.clearDragModes();
            obj.stopHover();
        end

        function clearRectangleSelection(obj, opts)
        %CLEARRECTANGLESELECTION Clear selected rectangles.
            arguments
                obj
                opts.Emit (1,1) logical = false
            end

            obj.Host.Overlays.clearSelection(Type="Rectangle");

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function selectAllRectangles(obj, opts)
        %SELECTALLRECTANGLES Select all rectangles owned by this tool.
            arguments
                obj
                opts.Emit (1,1) logical = true
            end

            obj.setSelectedRectangleIDs(obj.RectangleIds, Emit=opts.Emit);
        end

        function setSelectedRectangleIDs(obj, ids, opts)
        %SETSELECTEDRECTANGLEIDS Replace selected Rectangle IDs.
            arguments
                obj
                ids
                opts.Emit (1,1) logical = false
            end

            ids = string(ids);
            ids = ids(ismember(ids, obj.RectangleIds));
            obj.Host.Overlays.setSelected(ids(:).', Type="Rectangle");

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function ids = getSelectedRectangleIDs(obj)
        %GETSELECTEDRECTANGLEIDS Return selected Rectangle IDs.
            ids = obj.selectedRectangleIds();
        end

        function setActiveRectangleID(obj, id)
        %SETACTIVERECTANGLEID Public setter for active rectangle ID.
            id = obj.normalizeId_(id);
            if strlength(id) == 0
                obj.Host.Overlays.clearActive();
                obj.emitActiveChanged("");
            else
                obj.setActive(id);
            end
        end

        function deleteSelectedRectangles(obj)
        %DELETESELECTEDRECTANGLES Delete selected rectangles owned by this tool.
            ids = obj.selectedRectangleIds();
            for i = 1:numel(ids)
                obj.deleteRectangleById(ids(i));
            end
        end

        function deleteAllRectangles(obj)
        %DELETEALLRECTANGLES Delete all rectangles owned by this tool.
            ids = obj.RectangleIds;
            for i = numel(ids):-1:1
                obj.deleteRectangleById(ids(i));
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
        %GETPREFERREDPOINTER Return pointer requested by Rectangle state.
            if obj.Mode.DragRectangle
                pointer = 'fleur';
            elseif obj.Mode.ResizeRectangle
                pointer = obj.pointerForPart(obj.PendingDragPart);
            elseif obj.Mode.DrawingRectangle
                pointer = 'crosshair';
            elseif obj.Mode.HoverHandle
                pointer = obj.pointerForPart(obj.HoverPart);
            elseif obj.Mode.HoverRectangle
                pointer = 'hand';
            elseif obj.Enabled
                pointer = 'crosshair';
            else
                pointer = '';
            end
        end
    end

    methods (Access=private)
        function deleteRectangleById(obj, id)
        %DELETERECTANGLEBYID Delete a rectangle and emit RectangleDeletedFcn.
            id = obj.normalizeId_(id);
            idx = obj.idxOfId(id);
            if ~obj.isValidRectangleIdx(idx)
                return
            end

            obj.deleteRectangleByIdx(idx);
            if ~isempty(obj.RectangleDeletedFcn)
                obj.RectangleDeletedFcn(obj, struct('ID', id));
            end
        end

        function deleteRectangleByIdx(obj, idx)
        %DELETERECTANGLEBYIDX Delete a local rectangle without emitting deleted callback.
            if ~obj.isValidRectangleIdx(idx)
                return
            end

            id = obj.RectangleIds(idx);
            wasActive = obj.activeRectangleId() == id;

            obj.Host.Overlays.remove(id);
            obj.RectangleROI(idx) = [];
            obj.RectangleIds(idx) = [];

            if wasActive
                obj.emitActiveChanged("");
            end

            obj.emitSelectionChanged();
        end

        function setModeIfPresent(obj, modeName, value)
        %SETMODEIFPRESENT Set a mode only if it is currently registered.
            if obj.isMode(modeName)
                obj.setMode(modeName, value);
            end
        end

        function tf = isDragging(obj)
        %ISDRAGGING True when any rectangle drag mode is active.
            tf = obj.Mode.DragRectangle || obj.Mode.ResizeRectangle;
        end

        function out = valueOrDefault(~, value, defaultValue)
        %VALUEORDEFAULT Return defaultValue when value is empty.
            if isempty(value)
                out = defaultValue;
            else
                out = value;
            end
        end

        function pointer = pointerForPart(~, part)
        %POINTERFORPART Return MATLAB figure pointer for a rectangle handle.
            switch string(part)
                case {"left", "right"}
                    pointer = 'left';
                case {"top", "bottom"}
                    pointer = 'top';
                case {"bottomLeft", "topRight"}
                    pointer = 'botr';
                case {"bottomRight", "topLeft"}
                    pointer = 'botl';
                otherwise
                    pointer = 'fleur';
            end
        end
    end
end
