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

classdef Box < matlabx.ui.axes.AxesTool
%BOX Optimistic box-region interaction tool for ImageAxes.
%
%   The Box tool is an interaction controller. It interprets mouse gestures,
%   creates overlays.Box instances through the host OverlayManager, manages drag
%   mode, and emits Box-specific compatibility callbacks. Overlay lifetime and
%   active/hover/selection state are owned by ImageAxesOverlayManager.

    %% Draggable box management

    %% Private UI/Graphics
    properties (Access = private, Transient, NonCopyable)
        BoxROI (:,1) matlabx.ui.axes.overlays.Box
    end

    % Callbacks
    properties
        % Optimistic, widget-first events (controller may ignore them):
        % BoxCreatedFcn:            data.ID, data.CenterPx, data.BoxSize
        % BoxMoveStartedFcn:        data.ID
        % BoxPreviewMovedFcn:       data.ID, data.CenterPx
        % BoxMoveCommittedFcn:      data.ID, data.CenterPx
        % BoxDeletedFcn:            data.ID
        % BoxActivatedFcn:          data.ID
        % BoxSelectionChangedFcn:   data.IDs
        BoxCreatedFcn
        BoxMoveStartedFcn
        BoxPreviewMovedFcn
        BoxMoveCommittedFcn
        BoxDeletedFcn
        BoxActivatedFcn
        BoxSelectionChangedFcn
    end

    % Identity
    properties (Access=private)
        % track box IDs in parallel with overlay handles
        BoxIds (1,:) string = string.empty(1,0)
        DragStartFigurePoint (1,2) double = [NaN NaN]
    end

    % Box Settings/Info
    properties
        BoxSize (1,1) double = 50
        ActivateOnCreate (1,1) logical = true
        DragStartThresholdPx (1,1) double {mustBeNonnegative} = 3
        BoxCenters (:,2) double = []
    end

    properties (SetAccess=private, Dependent)
        nBoxes
    end

    %% Lifecycle toggles
    methods
        function obj = Box(host)
        %BOX Create the Box tool for one ImageAxes host.
            obj@matlabx.ui.axes.AxesTool(host, "Box",...
                'Tooltip','Box regions',...
                'AxesType',"image",...
                'Icon',matlabx.internal.Paths.icons('AddRectangleIcon.png'),...
                'Priority',10,...
                'IsExclusive',true,...
                'InterceptsDown',true,...
                'PassivelyInterceptsDown',true,...
                'PassivelyInterceptsMove',true,...
                'PassivelyInterceptsUp',true);

            % Box overlay array (empty to start)
            obj.BoxROI = matlabx.ui.axes.overlays.Box.empty();

        end
        function onInstall(obj)
        %ONINSTALL Register tool-owned modes after installation.
            obj.addMode('PrimedForDrag');
            obj.addMode('DragBox');
            obj.addMode('HoverBox');
        end

        function onUninstall(obj)
        %ONUNINSTALL Remove modes and overlays owned by this tool.
            obj.removeMode('PrimedForDrag');
            obj.removeMode('DragBox');
            obj.removeMode('HoverBox');
            obj.clearBoxes();
        end

        function contributeContextMenu(obj, menu)
        %CONTRIBUTECONTEXTMENU Add Box commands to the host context menu.
            menu.addSubmenu( ...
                "Box", ...
                "Box", ...
                "Owner", obj);

            menu.addItem( ...
                "Box.ClearSelection", ...
                "Clear Selection", ...
                @(~,~) obj.clearBoxSelection(Emit=true), ...
                "Parent", "Box", ...
                "Owner", obj, ...
                "Separator", "on", ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasSelectedBoxes()), ...
                "RefreshFcn", @(h) obj.refreshRequiresSelection(h));

            menu.addItem( ...
                "Box.SelectAll", ...
                "Select All", ...
                @(~,~) obj.selectAllBoxes(), ...
                "Parent", "Box", ...
                "Owner", obj, ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasAnyBoxes()), ...
                "RefreshFcn", @(h) obj.refreshRequiresBoxes(h));

            menu.addItem( ...
                "Box.DeleteSelected", ...
                "Delete Selected", ...
                @(~,~) obj.deleteSelectedBoxes(), ...
                "Parent", "Box", ...
                "Owner", obj, ...
                "Separator", "on", ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasSelectedBoxes()), ...
                "RefreshFcn", @(h) obj.refreshRequiresSelection(h));

            menu.addItem( ...
                "Box.DeleteAll", ...
                "Delete All", ...
                @(~,~) obj.deleteAllBoxes(), ...
                "Parent", "Box", ...
                "Owner", obj, ...
                "Enabled", matlab.lang.OnOffSwitchState(obj.hasAnyBoxes()), ...
                "RefreshFcn", @(h) obj.refreshRequiresBoxes(h));

            menu.addItem( ...
                "Box.Help", ...
                "Help...", ...
                @(~,~) obj.Host.openToolHelpWindow(obj), ...
                "Parent", "Box", ...
                "Owner", obj, ...
                "Separator", "on");
        end

    end

    %% Help
    methods
        function summary = getHelpSummary(~)
        %GETHELPSUMMARY Return a one-line Box description.
            summary = "Create, activate, select, move, and delete square box regions.";
        end

        function usage = getUsageHelp(~)
        %GETUSAGEHELP Return short Box usage notes.
            usage = [ ...
                "Enable Box and click the image to create a new box."; ...
                "Click an existing box to activate it and prime drag movement."; ...
                "Use selection commands from the Box context menu for batch actions."];
        end

        function B = getBindingHelp(obj)
        %GETBINDINGHELP Return Box click binding descriptions.
            B = struct( ...
                "ToggleTool", obj.ToggleHotkey, ...
                "CreateBox", "click image background while Box is enabled", ...
                "ActivateAndDrag", "click box, then drag", ...
                "ToggleSelection", "shift+extendclick box", ...
                "Deactivate", "alt+click box", ...
                "DeleteBox", "control+contextclick box");
        end

        function notes = getNotesHelp(~)
        %GETNOTESHELP Return additional Box behavior notes.
            notes = [ ...
                "Active and selected are separate states."; ...
                "Only the active box is dragged; selected boxes are used for batch menu actions."; ...
                "Right-click context menus are reserved for ImageAxes and tool commands."];
        end
    end

    %% Active event hooks (only when Enabled==true && IsInterceptor==true)
    methods

        function onDown(obj, E)
        %ONDOWN Create a new box on plain image click while enabled.

            switch E.MouseChord
                case "click"
                    H = obj.Host;
                    XY = H.cursorPosition;
        
                    if isempty(XY)
                        return
                    end
        
                    s = obj.BoxSize;
                    [cx,cy] = obj.clampCenter(XY, s);
                    ID = matlabx.utils.text.uniqueID();
        
                    % Draw now; notify controller (optimistic)
                    obj.addBox(ID, [cx cy], s);      
        
                    if ~isempty(obj.BoxCreatedFcn)
                        obj.BoxCreatedFcn(H, struct('ID', ID, 'CenterPx', [cx cy], 'BoxSize', s));
                    end
        
                    if obj.ActivateOnCreate
                        obj.emitActiveChanged(ID);
                    end

                case "shift+doubleclick"
                    obj.clearBoxSelection("Emit",true);

                otherwise
                    return

            end

        end

    end

    %% Passive event hooks (only when Installed==true && IsPassiveInterceptor==true)
    methods

        function onPassiveDown(obj,E)
        %ONPASSIVEDOWN Handle clicks on existing Box overlays.
            obj.printStatus(sprintf('%s.onPassiveDown()', obj.Name));

            % Box overlay clicks handled by overlay lookup (drag/delete)
            overlay = obj.Host.Overlays.overlayForTarget(E.Target);
            if isa(overlay, 'matlabx.ui.axes.overlays.Box') && obj.hasBox(overlay.ID)
                obj.boxClickedById(overlay.ID,E);
                E.stop();
            end
        end

        function onPassiveMove(obj,E)
        %ONPASSIVEMOVE Update hover or drag state for existing boxes.

            % if we are primed for drag (button down on box with no cursor movement)
            if obj.Mode.PrimedForDrag
                if ~obj.hasExceededDragThreshold(E)
                    return
                end

                % start dragging once the cursor has moved far enough on screen
                obj.startDraggingBox(obj.activeBoxIdx());
                return
            end

            % if we are in the middle of dragging a box
            if obj.Mode.DragBox
                % keep dragging and return
                obj.dragBox(obj.activeBoxIdx());
                return
            end

            % cursor target is a Box overlay graphic
            overlay = obj.Host.Overlays.overlayForTarget(E.Target);
            if isa(overlay, 'matlabx.ui.axes.overlays.Box') && obj.hasBox(overlay.ID)
                % turn Hovered mode on for the box
                obj.startHoverById(overlay.ID);
            else % cursor target is anything else
                % turn off hovered state for the currently hovered box, if it exists
                obj.stopHover();
            end

        end

        function onPassiveUp(obj,~)
        %ONPASSIVEUP Commit or cancel box drag state on mouse release.

            if obj.Mode.PrimedForDrag
                % no longer primed for drag
                obj.setMode('PrimedForDrag',false);
                obj.clearDragStart();
                return
            end

            if obj.Mode.DragBox
                obj.stopDraggingBox(obj.activeBoxIdx());
            end
        end

    end

    %% Derived getters
    methods

        function n = get.nBoxes(obj)
        %GET.NBOXES Return number of valid Box overlays owned by this tool.
            if isempty(obj.BoxROI), n = 0; else, n = sum(isvalid(obj.BoxROI)); end
        end

    end


    %% Private Helpers (Box)
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
        %IDXOFID Return local BoxROI index for an ID.
            id = obj.normalizeId_(id);
            if strlength(id) == 0
                idx = [];
                return
            end

            idx = find(obj.BoxIds == id, 1, 'first');
        end

        function idx = activeBoxIdx(obj)
        %ACTIVEBOXIDX Return local index of manager-active Box overlay.
            idx = obj.idxOfId(obj.activeBoxId());
        end

        function idx = activeHoverIdx(obj)
        %ACTIVEHOVERIDX Return local index of manager-hovered Box overlay.
            idx = obj.idxOfId(obj.activeHoverId());
        end

        function TF = isValidBoxIdx(obj, idx)
        %ISVALIDBOXIDX True when idx addresses a valid local Box overlay.
            TF = ~isempty(idx) ...
                && isscalar(idx) ...
                && idx>=1 ...
                && idx<=numel(obj.BoxROI) ...
                && isvalid(obj.BoxROI(idx));
        end

        function TF = hasBox(obj,id)
        %HASBOX True when this tool owns a box with ID.
            id = obj.normalizeId_(id);
            TF = strlength(id) > 0 && ismember(id,obj.BoxIds);
        end

        function id = activeBoxId(obj)
        %ACTIVEBOXID Return active Box ID filtered to overlays owned by this tool.
            id = obj.Host.Overlays.getActiveID(Type="Box");
            if ~obj.hasBox(id)
                id = "";
            end
        end

        function id = activeHoverId(obj)
        %ACTIVEHOVERID Return hovered Box ID filtered to overlays owned by this tool.
            id = obj.Host.Overlays.getHoverID(Type="Box");
            if ~obj.hasBox(id)
                id = "";
            end
        end

        function ids = selectedBoxIds(obj)
        %SELECTEDBOXIDS Return selected Box IDs filtered to overlays owned by this tool.
            ids = obj.Host.Overlays.getSelectedIDs(Type="Box");
            ids = ids(ismember(ids, obj.BoxIds));
        end

        function tf = hasAnyBoxes(obj)
        %HASANYBOXES True when this tool owns at least one valid box.
            tf = any(isvalid(obj.BoxROI));
        end

        function tf = hasSelectedBoxes(obj)
        %HASSELECTEDBOXES True when this tool owns selected boxes.
            tf = ~isempty(obj.selectedBoxIds());
        end

        function refreshRequiresBoxes(obj, h)
        %REFRESHREQUIRESBOXES Enable menu item only when boxes exist.
            if isvalid(obj)
                h.Enable = matlab.lang.OnOffSwitchState(obj.hasAnyBoxes());
            end
        end

        function refreshRequiresSelection(obj, h)
        %REFRESHREQUIRESSELECTION Enable menu item only when selection exists.
            if isvalid(obj)
                h.Enable = matlab.lang.OnOffSwitchState(obj.hasSelectedBoxes());
            end
        end

        function deleteBoxById(obj, id)
        %DELETEBOXBYID Delete a box and emit BoxDeletedFcn.
            id = obj.normalizeId_(id);
            idx = obj.idxOfId(id);
            if ~obj.isValidBoxIdx(idx), return; end

            obj.deleteBoxByIdx(idx);

            if ~isempty(obj.BoxDeletedFcn)
                obj.BoxDeletedFcn(obj, struct('ID', id));
            end
        end

        function deleteBoxByIdx(obj, idx)
        %DELETEBOXBYIDX Delete a local box without emitting BoxDeletedFcn.
            if ~obj.isValidBoxIdx(idx)
                return
            end

            id = obj.BoxIds(idx);
            wasActive = obj.activeBoxId() == id;

            % Keep the tool-owned hover/drag modes coherent before deletion.
            if obj.activeHoverId() == id
                obj.setMode('HoverBox',false);
            end

            % The overlay manager owns active/hover/selected state. Removing the
            % overlay clears any manager state that points at this ID.
            obj.Host.Overlays.remove(id);
            obj.BoxROI(idx) = [];
            obj.BoxCenters(idx,:) = [];
            obj.BoxIds(idx) = [];

            if wasActive
                obj.emitActiveChanged("");
            end

            % Preserve the existing compatibility callback behavior.
            obj.emitSelectionChanged();

        end

        function boxClickedById(obj, id, E)
        %BOXCLICKEDBYID Apply Box click grammar to an existing box.
            id = obj.normalizeId_(id);
            if ~obj.hasBox(id), return; end

            switch E.MouseChord
                case "control+contextclick"
                    obj.deleteBoxById(id);
                    return

                case "alt+click"
                    obj.deactivateActive();

                case "shift+extendclick"
                    obj.toggleSelection(id, 'Emit', true);

                case "click"
                    obj.setActive(id);
                    obj.primeDrag(E);
            end
        end

        function primeDrag(obj, E)
        %PRIMEDRAG Mark active box as ready to drag on the next move event.
            if obj.Enabled && strlength(obj.activeBoxId()) > 0
                obj.DragStartFigurePoint = E.CurrentPointFigure;
                obj.setMode('PrimedForDrag', true);
            end
        end


        function setActive(obj, id)
        %SETACTIVE Make a box active and emit BoxActivatedFcn.
            id = obj.normalizeId_(id);
            if ~obj.isValidBoxIdx(obj.idxOfId(id)), return; end

            obj.Host.Overlays.setActive(id);
            obj.emitActiveChanged(id);

        end

        function deactivateActive(obj)
        %DEACTIVATEACTIVE Clear active box state and emit empty activation.
            if strlength(obj.activeBoxId()) == 0
                return
            end

            obj.setMode('PrimedForDrag', false);
            obj.setMode('DragBox', false);
            obj.clearDragStart();
            obj.Host.Overlays.clearActive();
            obj.emitActiveChanged("");
        end

        function emitActiveChanged(obj, id)
        %EMITACTIVECHANGED Emit BoxActivatedFcn if configured.
            if ~isempty(obj.BoxActivatedFcn)
                obj.BoxActivatedFcn(obj, struct('ID', obj.normalizeId_(id)));
            end
        end

        function addToSelection(obj, id, opts)
        %ADDTOSELECTION Select one box and optionally emit callback.
            arguments
                obj
                id
                opts.Emit (1,1) logical = false
            end

            obj.Host.Overlays.select(id);

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function removeFromSelection(obj, id, opts)
        %REMOVEFROMSELECTION Deselect one box and optionally emit callback.
            arguments
                obj
                id
                opts.Emit (1,1) logical = false
            end

            obj.Host.Overlays.deselect(id);

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function toggleSelection(obj, id, opts)
        %TOGGLESELECTION Toggle one box in the selected set.
            arguments
                obj
                id
                opts.Emit (1,1) logical = false
            end

            if ismember(id, obj.selectedBoxIds())
                obj.removeFromSelection(id, 'Emit', opts.Emit);
            else
                obj.addToSelection(id, 'Emit', opts.Emit);
            end
        end

        function emitSelectionChanged(obj)
        %EMITSELECTIONCHANGED Emit selected Box IDs if callback is configured.
            if isempty(obj.BoxSelectionChangedFcn), return; end
            obj.BoxSelectionChangedFcn(obj, struct('IDs', obj.selectedBoxIds()));
        end

        function dragBox(obj, idx)
        %DRAGBOX Move a box preview to the current cursor position.
            XY = obj.Host.cursorPosition;
            % exit if pixel is empty or box idx is invalid
            if isempty(XY) || ~obj.isValidBoxIdx(idx), return; end
            % the size of the box being dragged
            s = obj.BoxROI(idx).BoxSize;
            % clamp so box edge does not exit image boundary
            [cx,cy] = obj.clampCenter(XY, s);
            % update center coordinates
            obj.BoxROI(idx).Center = [cx cy];
            obj.BoxCenters(idx,:)  = [cx cy];
            % emit high-frequency preview (controller may ignore)
            if ~isempty(obj.BoxPreviewMovedFcn)
                ID = obj.BoxIds(idx);
                obj.BoxPreviewMovedFcn(obj, struct('ID', ID, 'CenterPx', [cx cy]));
            end
        end

        function startDraggingBox(obj,idx)
        %STARTDRAGGINGBOX Transition from primed to dragging state.
            % we are no longer PrimedForDrag
            obj.setMode('PrimedForDrag',false);
            obj.clearDragStart();
            if ~obj.isValidBoxIdx(idx)
                return
            end
            % we are now dragging
            obj.setMode('DragBox',true);
            % fire BoxMoveStartedFcn
            if ~isempty(obj.BoxMoveStartedFcn)
                ID = obj.BoxIds(idx);
                obj.BoxMoveStartedFcn(obj, struct('ID', ID));
            end
            % request Host update
            obj.Host.updateFromTool();
        end

        function stopDraggingBox(obj, idx)
        %STOPDRAGGINGBOX Commit final drag position and emit callback.
            if obj.isValidBoxIdx(idx)
                obj.dragBox(idx); % snap to final position before stopping drag
                if ~isempty(obj.BoxMoveCommittedFcn)
                    ID = obj.BoxIds(idx);
                    ctr  = obj.BoxCenters(idx,:);
                    obj.BoxMoveCommittedFcn(obj, struct('ID', ID, 'CenterPx', ctr));
                end
            end
            obj.setMode('DragBox',false);
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
        %STARTHOVERBYID Mark a box as hovered through the overlay manager.
            id = obj.normalizeId_(id);
            idx = obj.idxOfId(id);
            % idx is empty, return
            if ~obj.isValidBoxIdx(idx), return; end
            % we are already hovering on this box, return
            if id == obj.activeHoverId(), return; end

            % The manager flips Hovered off on the previous overlay and on for
            % this one; the overlay updates its own appearance.
            obj.Host.Overlays.setHover(id);
            obj.setMode('HoverBox', true);
        end

        function stopHover(obj)
        %STOPHOVER Clear hovered Box state through the overlay manager.
            % if HoverBox Mode is already off, return
            if ~obj.Mode.HoverBox, return; end
            % if hovered ID is empty, return
            if strlength(obj.activeHoverId()) == 0, return; end

            % The manager clears Hovered on the current overlay.
            obj.Host.Overlays.clearHover();
            obj.setMode('HoverBox', false);
        end

    end

    methods (Hidden=true)

        function [cX,cY] = clampCenter(obj, C, boxSize)
        %CLAMPCENTER Clamp requested box center to image bounds.
            W = obj.Host.ImageWidth;
            H = obj.Host.ImageHeight;
            C = matlabx.image.roi.clampBoxToImage(C,boxSize,[W, H]);
            cX = C(1);
            cY = C(2);
        end

    end


    %% Host-facing methods

    methods

        function addBox(obj, id, center_px, boxSize, opts)
        %ADDBOX Create a Box overlay owned by this tool.
            arguments
                obj
                id
                center_px
                boxSize = []
                opts.EdgeColor = [1 1 1]
                opts.FaceColor = [1 1 1]
                opts.Label (1,1) string =  ""
            end

            if isempty(boxSize)
                boxSize = obj.BoxSize;
            end

            [cx,cy] = obj.clampCenter(center_px, boxSize);
            next = obj.nBoxes + 1;

            obj.BoxROI(next) = obj.Host.Overlays.add("Box", ...
                "Center",[cx cy], ...
                "BoxSize", boxSize, ...
                "ID", string(id), ...
                "Label", opts.Label, ...
                "EdgeColor", opts.EdgeColor, ...
                "FaceColor", opts.FaceColor, ...
                "ActivateOnCreate", obj.ActivateOnCreate);


            obj.BoxCenters(end+1,:) = [cx cy];
            obj.BoxIds(end+1)       = string(id);
        end

        function removeBox(obj, id)
        %REMOVEBOX Remove one box by ID.
            idx = obj.idxOfId(id); if isempty(idx), return; end
            obj.deleteBoxByIdx(idx);
        end

        function clearBoxes(obj)
        %CLEARBOXES Remove all boxes owned by this tool.
            ids = obj.BoxIds;
            for i = numel(ids):-1:1
                obj.Host.Overlays.remove(ids(i));
            end

            obj.BoxROI = matlabx.ui.axes.overlays.Box.empty();
            obj.BoxCenters = zeros(0,2);
            obj.BoxIds = string.empty(1,0);
            obj.clearDragStart();
        end

        function setSelectedBoxIDs(obj, ids, opts)
        %SETSELECTEDBOXIDS Replace selected Box IDs.
            arguments
                obj
                ids
                opts.Emit (1,1) logical = false
            end

            ids = string(ids);
            ids = ids(ismember(ids, obj.BoxIds));
            obj.Host.Overlays.setSelected(ids(:).', Type="Box");
        
            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function ids = getSelectedBoxIDs(obj)
        %GETSELECTEDBOXIDS Return selected Box IDs.
            ids = obj.selectedBoxIds();
        end

        function clearBoxSelection(obj, opts)
        %CLEARBOXSELECTION Clear selected boxes.
            arguments
                obj
                opts.Emit (1,1) logical = false
            end

            obj.Host.Overlays.clearSelection(Type="Box");

            if opts.Emit
                obj.emitSelectionChanged();
            end
        end

        function selectAllBoxes(obj, opts)
        %SELECTALLBOXES Select all boxes owned by this tool.
            arguments
                obj
                opts.Emit (1,1) logical = true
            end

            obj.setSelectedBoxIDs(obj.BoxIds, Emit=opts.Emit);
        end

        function deleteSelectedBoxes(obj)
        %DELETESELECTEDBOXES Delete selected boxes owned by this tool.
            ids = obj.selectedBoxIds();
            for i = 1:numel(ids)
                obj.deleteBoxById(ids(i));
            end
        end

        function deleteAllBoxes(obj)
        %DELETEALLBOXES Delete all boxes owned by this tool.
            ids = obj.BoxIds;
            for i = numel(ids):-1:1
                obj.deleteBoxById(ids(i));
            end
        end

        function setActiveBoxID(obj,id)
        %SETACTIVEBOXID Public setter for active box ID.
            id = obj.normalizeId_(id);
            if strlength(id) == 0
                obj.deactivateActive();
            else
                obj.setActive(id);
            end
        end

        function setBoxLabelByID(obj, id, label)
        %SETBOXLABELBYID Set label text for one box.
            idx = obj.idxOfId(id);
            if isempty(idx), return; end
            if idx>=1 && idx<=numel(obj.BoxROI) && isvalid(obj.BoxROI(idx))
                set(obj.BoxROI(idx),'Label',label);
            end
        end

        function setBoxColorByID(obj, id, color)
        %SETBOXCOLORBYID Set edge and face color for one box.
            idx = obj.idxOfId(id);
            if isempty(idx), return; end
            if idx>=1 && idx<=numel(obj.BoxROI) && isvalid(obj.BoxROI(idx))
                set(obj.BoxROI(idx),'EdgeColor',color,'FaceColor',color);
            end
        end

        function setBoxesColorByIDs(obj, ids, color)
        %SETBOXESCOLORBYIDS Set edge and face color for multiple boxes.
            ids = string(ids);
            for i = 1:numel(ids)
                obj.setBoxColorByID(ids(i), color);
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
        %GETPREFERREDPOINTER Return pointer requested by current Box state.
            if obj.Mode.DragBox
                pointer = 'fleur';
            elseif obj.Mode.HoverBox
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

        % called at the beginning of superclass delete()
        function teardown(obj)
        %TEARDOWN Delete Box overlays during tool destruction.
            % Delete box overlays owned by this tool.
            try
                obj.clearBoxes();
            catch
            end
        end

    end

end
