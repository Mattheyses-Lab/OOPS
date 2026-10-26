classdef Polygon < matlabx.ui.axes.AxesTool
%POLYGON Draw, inspect, and manage polygon overlays.
%
%   Enable the tool and click successive image positions to draw a polygon;
%   click the first vertex to close it or press Escape to cancel. The tool also
%   controls existing Polygon overlays in the host registry and keeps no
%   duplicate overlay list. Removing the tool leaves completed overlays intact.
%   By default, PolygonDeletedFcn receives data.ID after each tool deletion.
%   With PolygonsDeleteRequestedFcn installed, one data.IDs request is sent
%   instead and the application owns deletion and overlay reconciliation.
%   Activation and selection callbacks also reflect manager/rectangle selection.

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

    properties
        % Drawing and preview behavior.
        ActivateOnCreate (1,1) logical = true
        DrawingEdgeColor (1,3) double {mustBeBetween(DrawingEdgeColor,0,1)} = [1 1 1]
        DrawingLineWidth (1,1) double {mustBePositive} = 1
        DrawingMarkerStyle (1,:) char = 's'
        DrawingMarkerSize (1,1) double {mustBePositive} = 4
        DrawingStartMarkerSize (1,1) double {mustBePositive} = 6
        DrawingMarkerLineWidth (1,1) double {mustBePositive} = 0.5
        DrawingMarkerEdgeColor (1,3) double {mustBeBetween(DrawingMarkerEdgeColor,0,1)} = [0 0 0]
        DrawingMarkerFaceColor (1,3) double {mustBeBetween(DrawingMarkerFaceColor,0,1)} = [1 1 1]
        DragStartThresholdPx (1,1) double {mustBeNonnegative} = 3

        % Notification after a completed polygon enters the overlay manager.
        PolygonCreatedFcn = []
        PolygonMoveStartedFcn = []
        PolygonPreviewMovedFcn = []
        PolygonMoveCommittedFcn = []
        % Optional application-owned deletion. Called once with data.IDs;
        % no overlays/state are changed by the tool when this is installed.
        % The application reconciles accepted deletions using Overlays.removeMany.
        PolygonsDeleteRequestedFcn = []
        % Legacy notification after each optimistic deletion; used only when
        % PolygonsDeleteRequestedFcn is empty.
        PolygonDeletedFcn = []
        PolygonActivatedFcn = []
        PolygonSelectionChangedFcn = []
    end

    properties (Access=private, Transient, NonCopyable)
        OverlayListeners event.listener = event.listener.empty()
        DrawingLine = []
        DrawingStartMarker = []
    end

    properties (Access=private)
        DrawingVertices (:,2) double = zeros(0,2)
        DrawingCursor (1,2) double = [NaN NaN]
        DrawingStartHovered (1,1) logical = false
        HoverPart (1,1) string = ""
        PendingDragPart (1,1) string = ""
        PendingVertexIndex (1,1) double = NaN
        DragStartFigurePoint (1,2) double = [NaN NaN]
        DragStartCursor (1,2) double = [NaN NaN]
        DragStartVertices (:,2) double = zeros(0,2)
        DeactivateOnClickRelease (1,1) logical = false
    end

    methods
        function obj = Polygon(host)
            obj@matlabx.ui.axes.AxesTool(host, "Polygon", ...
                'Tooltip', 'Draw polygon', ...
                'AxesType', "image", 'Style', 'state', ...
                'Icon', matlabx.internal.Paths.icons('DrawPolygonWhiteFGTransparentBG.svg'), ...
                'Priority', 10, ...
                'IsExclusive', true, ...
                'InterceptsDown', true, ...
                'InterceptsMove', true, ...
                'InterceptsUp', true, ...
                'InterceptsKeyPress', true, ...
                'PassivelyInterceptsDown', true, ...
                'PassivelyInterceptsMove', true);
        end

        function onInstall(obj)
            obj.addMode('DrawingPolygon');
            obj.addMode('PrimedForDrag');
            obj.addMode('DragPolygon');
            obj.addMode('DragVertex');
            obj.addMode('HoverPolygon');
            obj.addMode('HoverVertex');
            obj.OverlayListeners(1) = addlistener(obj.Host.Overlays, 'ActiveChanged', ...
                @(~,~) obj.emitActiveChanged());
            obj.OverlayListeners(2) = addlistener(obj.Host.Overlays, 'SelectionChanged', ...
                @(~,~) obj.emitSelectionChanged());
        end

        function onUninstall(obj)
            obj.cancelDrawing();
            obj.clearDragModes();
            obj.clearHover();
            obj.removeMode('DrawingPolygon');
            obj.removeMode('PrimedForDrag');
            obj.removeMode('DragPolygon');
            obj.removeMode('DragVertex');
            obj.removeMode('HoverPolygon');
            obj.removeMode('HoverVertex');
            delete(obj.OverlayListeners(isvalid(obj.OverlayListeners)));
            obj.OverlayListeners = event.listener.empty();
        end

        function onDisabled(obj)
        %ONDISABLED Cancel unfinished geometry when drawing is turned off.
            obj.cancelDrawing();
            obj.clearDragModes();
        end

        function contributeContextMenu(obj, menu)
            menu.addSubmenu("Polygon", "Polygon", "Owner", obj);
            menu.addItem("Polygon.SelectAll", "Select All", ...
                @(~,~) obj.selectAllPolygons(), "Parent", "Polygon", "Owner", obj);
            menu.addItem("Polygon.ClearSelection", "Clear Selection", ...
                @(~,~) obj.clearPolygonSelection(), "Parent", "Polygon", "Owner", obj);
            menu.addItem("Polygon.ClearActive", "Clear Active", ...
                @(~,~) obj.setActivePolygonID(""), "Parent", "Polygon", "Owner", obj);
            menu.addItem("Polygon.DeleteActive", "Delete Active", ...
                @(~,~) obj.deleteActivePolygon(), "Parent", "Polygon", "Owner", obj, ...
                "Separator", "on");
            menu.addItem("Polygon.DeleteSelected", "Delete Selected", ...
                @(~,~) obj.deleteSelectedPolygons(), "Parent", "Polygon", "Owner", obj);
            menu.addItem("Polygon.DeleteAll", "Delete All", ...
                @(~,~) obj.deleteAllPolygons(), "Parent", "Polygon", "Owner", obj);
            menu.addItem("Polygon.Help", "Help...", ...
                @(~,~) obj.Host.openToolHelpWindow(obj), ...
                "Parent", "Polygon", "Owner", obj, "Separator", "on");
        end

        function onDown(obj, E)
        %ONDOWN Start, extend, or close a polygon from plain image clicks.
            if E.MouseChord ~= "click"
                return
            end

            if obj.Mode.DrawingPolygon && obj.isDrawingStartTarget(E.Target)
                if size(obj.DrawingVertices,1) >= 3
                    obj.finishDrawing();
                end
                E.stop();
                return
            end

            if ~isempty(obj.Host.Overlays.overlayForTarget(E.Target))
                return
            end

            xy = obj.Host.cursorPosition;
            if isempty(xy)
                return
            end

            if ~obj.Mode.DrawingPolygon
                obj.startDrawing(xy);
            elseif isempty(obj.DrawingVertices) || ~isequal(xy, obj.DrawingVertices(end,:))
                obj.DrawingVertices(end+1,:) = xy;
                obj.DrawingCursor = xy;
                obj.updateDrawingPreview();
            end
            E.stop();
        end

        function onMove(obj, E)
        %ONMOVE Update polygon drawing or geometry dragging.
            if obj.Mode.DrawingPolygon
                % Use the same pickable start marker for both closure and pointer
                % feedback so the circle appears precisely where a click closes.
                obj.DrawingStartHovered = size(obj.DrawingVertices,1) >= 3 ...
                    && obj.isDrawingStartTarget(E.Target);
                xy = obj.Host.cursorPosition;
                if isempty(xy)
                    return
                end
                obj.DrawingCursor = xy;
                obj.updateDrawingPreview();
                E.stop();
                return
            end

            if obj.Mode.PrimedForDrag
                if ~obj.hasExceededDragThreshold(E)
                    return
                end
                obj.DeactivateOnClickRelease = false;
                obj.startDragging();
                obj.dragActivePolygon();
                return
            end

            if obj.isDragging()
                obj.dragActivePolygon();
            end
        end

        function onUp(obj, ~)
        %ONUP Resolve a click or commit a polygon geometry edit.
            if obj.Mode.PrimedForDrag
                obj.clearDragModes();
                if obj.DeactivateOnClickRelease
                    obj.DeactivateOnClickRelease = false;
                    obj.setActivePolygonID("");
                end
                return
            end

            if obj.isDragging()
                id = obj.Host.Overlays.getActiveID(Type="Polygon");
                overlay = obj.polygonForID(id);
                obj.clearDragModes();
                if ~isempty(overlay) && ~isempty(obj.PolygonMoveCommittedFcn)
                    obj.PolygonMoveCommittedFcn(obj, ...
                        struct('ID', id, 'Vertices', overlay.Vertices));
                end
            end
        end

        function onKeyPress(obj, E)
        %ONKEYPRESS Cancel an unfinished polygon with Escape.
            if obj.Mode.DrawingPolygon && E.Hotkey == "escape"
                obj.cancelDrawing();
                E.stop();
            end
        end

        function onPassiveDown(obj, E)
            %ONPASSIVEDOWN Handle clicks on polygons before active drawing tools.
            overlay = obj.Host.Overlays.overlayForTarget(E.Target);
            if isempty(overlay)
                if E.MouseChord == "click" && ~obj.Enabled ...
                        && ~obj.Host.toolEnabled("RectangleSelect")
                    obj.setActivePolygonID("");
                end
                return
            end
            if ~isa(overlay, 'matlabx.ui.axes.overlays.Polygon'), return; end
            [part, vertexIndex] = obj.hitPartForEvent(E, overlay);
            switch E.MouseChord
                case "click"
                    wasActive = obj.Host.Overlays.getActiveID(Type="Polygon") == overlay.ID;
                    obj.DeactivateOnClickRelease = obj.Enabled && wasActive;
                    if ~obj.Enabled && wasActive
                        obj.setActivePolygonID("");
                    else
                        obj.setActivePolygonID(overlay.ID);
                    end
                    if obj.Enabled
                        obj.primeDrag(part, vertexIndex, E);
                    end
                case "shift+extendclick"
                    obj.Host.Overlays.toggleSelected(overlay.ID);
                case "alt+click"
                    obj.setActivePolygonID("");
                case "control+contextclick"
                    obj.removePolygon(overlay.ID);
                case "contextclick"
                    % Overlay context clicks intentionally suppress the axes
                    % context menu, matching the other editable overlay tools.
                    E.markHandled();
                otherwise
                    return
            end
            E.stop();
        end

        function onPassiveMove(obj, E)
            %ONPASSIVEMOVE Update polygon hover independently of active tools.
            if obj.Mode.DrawingPolygon || obj.Mode.PrimedForDrag || obj.isDragging()
                obj.clearHover();
                return
            end
            overlay = obj.Host.Overlays.overlayForTarget(E.Target);
            if isa(overlay, 'matlabx.ui.axes.overlays.Polygon')
                obj.Host.Overlays.setHover(overlay.ID);
                [part, ~] = obj.hitPartForEvent(E, overlay);
                obj.HoverPart = part;
                obj.setMode('HoverPolygon', part == "body");
                obj.setMode('HoverVertex', part == "vertex");
            else
                obj.clearHover();
            end
        end

        function onHostLeave(obj, ~)
        %ONHOSTLEAVE Clear hover state when the pointer leaves ImageAxes.
            obj.DrawingStartHovered = false;
            obj.clearHover();
        end

        function pointer = getPreferredPointer(obj)
        %GETPREFERREDPOINTER Show closure feedback over the first vertex.
            if obj.DrawingStartHovered
                pointer = 'circle';
            elseif obj.Mode.DragPolygon
                pointer = 'fleur';
            elseif obj.Mode.DragVertex
                pointer = 'circle';
            elseif obj.Mode.HoverVertex
                pointer = 'circle';
            elseif obj.Mode.HoverPolygon
                pointer = 'hand';
            elseif obj.Enabled
                pointer = 'crosshair';
            else
                pointer = '';
            end
        end

        function overlay = addPolygon(obj, id, vertices, varargin)
        %ADDPOLYGON Add geometry with the same options as overlays.Polygon.
            overlay = obj.Host.Overlays.add("Polygon", ...
                "ID", string(id), "Vertices", vertices, varargin{:});
        end

        function removePolygon(obj, id)
        %REMOVEPOLYGON Request deletion, or delete optimistically in legacy mode.
            obj.requestDeletion(id);
        end

        function selectAllPolygons(obj)
            obj.Host.Overlays.setSelected(obj.Host.Overlays.ids(Type="Polygon"), Type="Polygon");
        end

        function clearPolygonSelection(obj)
            obj.Host.Overlays.clearSelection(Type="Polygon");
        end

        function ids = getSelectedPolygonIDs(obj)
            ids = obj.Host.Overlays.getSelectedIDs(Type="Polygon");
        end

        function setSelectedPolygonIDs(obj, ids)
            obj.Host.Overlays.setSelected(ids, Type="Polygon");
        end

        function setActivePolygonID(obj, id)
            if strlength(string(id)) == 0
                if strlength(obj.Host.Overlays.getActiveID(Type="Polygon")) > 0
                    obj.Host.Overlays.clearActive();
                end
            elseif isa(obj.Host.Overlays.get(id), 'matlabx.ui.axes.overlays.Polygon')
                obj.Host.Overlays.setActive(id);
            end
        end

        function deleteActivePolygon(obj)
            id = obj.Host.Overlays.getActiveID(Type="Polygon");
            obj.requestDeletion(id);
        end

        function deleteSelectedPolygons(obj)
            ids = obj.getSelectedPolygonIDs();
            obj.requestDeletion(ids);
        end

        function deleteAllPolygons(obj)
            ids = obj.Host.Overlays.ids(Type="Polygon");
            obj.requestDeletion(ids);
        end

        function summary = getHelpSummary(~)
            summary = "Draw, activate, select, and delete polygon overlays.";
        end

        function usage = getUsageHelp(~)
            usage = ["Enable Polygon and click the image to place successive vertices."; ...
                "Click the first vertex after placing at least three vertices to close the polygon."; ...
                "Press Escape to cancel an unfinished polygon."; ...
                "Click an existing polygon to toggle its active state."; ...
                "Enable RectangleSelect to select polygon centroids with a marquee."; ...
                "Existing polygon interaction remains available while the drawing tool is disabled."];
        end

        function B = getBindingHelp(obj)
            B = struct("ToggleTool", obj.ToggleHotkey, ...
                "AddVertex", "click image background while Polygon is enabled", ...
                "CompletePolygon", "click the first vertex after placing three vertices", ...
                "CancelDrawing", "escape", ...
                "Activate", "click polygon to toggle active state; drag to edit", ...
                "DeactivateOnBackground", "click overlay-free image background", ...
                "ToggleSelection", "shift+extendclick polygon", ...
                "Deactivate", "alt+click polygon", ...
                "DeletePolygon", "control+contextclick polygon", ...
                "Translate", "click-drag polygon body", ...
                "MoveVertex", "click-drag a vertex handle");
        end

        function notes = getNotesHelp(~)
            notes = ["Active and selected are separate states."; ...
                "Each polygon displays one closed loop supplied by the application."; ...
                "Deleting a polygon does not modify the image mask."; ...
                "When configured, the application handles deletion requests before overlays change."; ...
                "Removing this tool preserves polygon overlays."];
        end
    end

    methods (Access=private)
        function startDrawing(obj, xy)
        %STARTDRAWING Begin a tool-owned polygon preview at one vertex.
            obj.cancelDrawing();
            obj.DrawingVertices = xy;
            obj.DrawingCursor = xy;
            obj.setMode('DrawingPolygon', true);

            obj.DrawingLine = line(obj.Host.getAxes(), ...
                'XData', xy(1), 'YData', xy(2), ...
                'Color', obj.DrawingEdgeColor, ...
                'LineWidth', obj.DrawingLineWidth, ...
                'Marker', obj.DrawingMarkerStyle, ...
                'MarkerSize', obj.DrawingMarkerSize, ...
                'MarkerEdgeColor', obj.DrawingMarkerEdgeColor, ...
                'MarkerFaceColor', obj.DrawingMarkerFaceColor, ...
                'MarkerIndices', 1, ...
                'HitTest', 'off', 'PickableParts', 'none', ...
                'Tag', 'PolygonDrawingPreview');

            % A separate pickable first marker provides a stable close target
            % whose hit area follows MATLAB's screen-space marker behavior.
            obj.DrawingStartMarker = line(obj.Host.getAxes(), ...
                'XData', xy(1), 'YData', xy(2), ...
                'LineStyle', 'none', ...
                'Marker', obj.DrawingMarkerStyle, ...
                'MarkerSize', obj.DrawingStartMarkerSize, ...
                'MarkerEdgeColor', obj.DrawingMarkerEdgeColor, ...
                'MarkerFaceColor', obj.DrawingMarkerFaceColor, ...
                'LineWidth', obj.DrawingMarkerLineWidth, ...
                'HitTest', 'on', 'PickableParts', 'all', ...
                'Tag', 'PolygonDrawingStart');
        end

        function updateDrawingPreview(obj)
        %UPDATEDRAWINGPREVIEW Draw committed vertices plus the cursor edge.
            if isempty(obj.DrawingLine) || ~isgraphics(obj.DrawingLine)
                return
            end
            vertices = obj.DrawingVertices;
            if all(isfinite(obj.DrawingCursor))
                vertices(end+1,:) = obj.DrawingCursor;
            end
            committed = 1:size(obj.DrawingVertices,1);
            set(obj.DrawingLine, ...
                'XData', vertices(:,1), 'YData', vertices(:,2), ...
                'Color', obj.DrawingEdgeColor, ...
                'LineWidth', obj.DrawingLineWidth, ...
                'Marker', obj.DrawingMarkerStyle, ...
                'MarkerSize', obj.DrawingMarkerSize, ...
                'MarkerEdgeColor', obj.DrawingMarkerEdgeColor, ...
                'MarkerFaceColor', obj.DrawingMarkerFaceColor, ...
                'MarkerIndices', committed);
        end

        function finishDrawing(obj)
        %FINISHDRAWING Commit the preview as one managed Polygon overlay.
            vertices = obj.DrawingVertices;
            if size(vertices,1) < 3
                return
            end

            obj.cancelDrawing();
            id = matlabx.utils.text.uniqueID();
            obj.addPolygon(id, vertices, 'ActivateOnCreate', obj.ActivateOnCreate);
            if ~isempty(obj.PolygonCreatedFcn)
                obj.PolygonCreatedFcn(obj, struct('ID', id, 'Vertices', vertices));
            end
        end

        function cancelDrawing(obj)
        %CANCELDRAWING Remove unfinished preview graphics and reset state.
            if obj.isMode('DrawingPolygon')
                obj.setMode('DrawingPolygon', false);
            end
            if ~isempty(obj.DrawingLine) && isgraphics(obj.DrawingLine)
                delete(obj.DrawingLine);
            end
            if ~isempty(obj.DrawingStartMarker) && isgraphics(obj.DrawingStartMarker)
                delete(obj.DrawingStartMarker);
            end
            obj.DrawingLine = [];
            obj.DrawingStartMarker = [];
            obj.DrawingVertices = zeros(0,2);
            obj.DrawingCursor = [NaN NaN];
            obj.DrawingStartHovered = false;
        end

        function tf = isDrawingStartTarget(obj, target)
        %ISDRAWINGSTARTTARGET True when target is the preview's first marker.
            tf = ~isempty(obj.DrawingStartMarker) ...
                && isgraphics(obj.DrawingStartMarker) ...
                && isequal(target, obj.DrawingStartMarker);
        end

        function [part, vertexIndex] = hitPartForEvent(obj, E, overlay)
        %HITPARTFOREVENT Classify a polygon hit as its body or nearest vertex.
            part = "body";
            vertexIndex = NaN;
            tag = "";
            try
                tag = string(E.Target.Tag);
            catch
            end
            if tag ~= "OverlayPolygonHandle"
                return
            end

            vertices = overlay.Vertices;
            if size(vertices,1) > 1 && isequal(vertices(1,:), vertices(end,:))
                vertices(end,:) = [];
            end
            if isempty(vertices)
                return
            end
            xy = obj.Host.cursorPosition;
            if isempty(xy)
                try
                    xy = E.CurrentAxes.CurrentPoint(1,1:2);
                catch
                    return
                end
            end
            [~, vertexIndex] = min(hypot(vertices(:,1)-xy(1), vertices(:,2)-xy(2)));
            part = "vertex";
        end

        function primeDrag(obj, part, vertexIndex, E)
        %PRIMEDRAG Store edit intent until motion crosses the pixel threshold.
            id = obj.Host.Overlays.getActiveID(Type="Polygon");
            overlay = obj.polygonForID(id);
            xy = obj.Host.cursorPosition;
            if isempty(overlay) || isempty(xy)
                return
            end
            obj.PendingDragPart = string(part);
            obj.PendingVertexIndex = vertexIndex;
            obj.DragStartFigurePoint = E.CurrentPointFigure;
            obj.DragStartCursor = xy;
            obj.DragStartVertices = overlay.Vertices;
            obj.setMode('PrimedForDrag', true);
        end

        function startDragging(obj)
        %STARTDRAGGING Convert a primed edit into translation or vertex motion.
            obj.setMode('PrimedForDrag', false);
            if obj.PendingDragPart == "vertex" && isfinite(obj.PendingVertexIndex)
                obj.setMode('DragVertex', true);
            else
                obj.setMode('DragPolygon', true);
            end
            id = obj.Host.Overlays.getActiveID(Type="Polygon");
            if ~isempty(obj.PolygonMoveStartedFcn)
                obj.PolygonMoveStartedFcn(obj, struct('ID', id));
            end
        end

        function dragActivePolygon(obj)
        %DRAGACTIVEPOLYGON Translate the loop or move its selected vertex.
            id = obj.Host.Overlays.getActiveID(Type="Polygon");
            overlay = obj.polygonForID(id);
            xy = obj.Host.cursorPosition;
            if isempty(overlay) || isempty(xy) || isempty(obj.DragStartVertices)
                return
            end

            vertices = obj.DragStartVertices;
            if obj.Mode.DragPolygon
                delta = obj.clampTranslationDelta(vertices, xy - obj.DragStartCursor);
                vertices = vertices + delta;
            elseif obj.Mode.DragVertex
                idx = obj.PendingVertexIndex;
                if ~isfinite(idx) || idx < 1 || idx > size(vertices,1)
                    return
                end
                point = obj.clampPointToImage(xy);
                explicitlyClosed = size(vertices,1) > 1 ...
                    && isequal(vertices(1,:), vertices(end,:));
                vertices(idx,:) = point;
                if explicitlyClosed && idx == 1
                    vertices(end,:) = point;
                end
            end

            overlay.Vertices = vertices;
            if ~isempty(obj.PolygonPreviewMovedFcn)
                obj.PolygonPreviewMovedFcn(obj, ...
                    struct('ID', id, 'Vertices', vertices));
            end
        end

        function tf = hasExceededDragThreshold(obj, E)
        %HASEXCEEDEDDRAGTHRESHOLD Test figure-pixel motion from mouse-down.
            if any(isnan(obj.DragStartFigurePoint)) || any(isnan(E.CurrentPointFigure))
                tf = true;
                return
            end
            delta = E.CurrentPointFigure - obj.DragStartFigurePoint;
            tf = hypot(delta(1),delta(2)) >= obj.DragStartThresholdPx;
        end

        function tf = isDragging(obj)
        %ISDRAGGING True while polygon translation or vertex editing is active.
            tf = obj.Mode.DragPolygon || obj.Mode.DragVertex;
        end

        function clearDragModes(obj)
        %CLEARDRAGMODES Reset polygon edit modes and captured geometry.
            obj.setModeIfPresent('PrimedForDrag', false);
            obj.setModeIfPresent('DragPolygon', false);
            obj.setModeIfPresent('DragVertex', false);
            obj.PendingDragPart = "";
            obj.PendingVertexIndex = NaN;
            obj.DragStartFigurePoint = [NaN NaN];
            obj.DragStartCursor = [NaN NaN];
            obj.DragStartVertices = zeros(0,2);
        end

        function overlay = polygonForID(obj, id)
        %POLYGONFORID Return a valid managed Polygon or empty.
            overlay = obj.Host.Overlays.get(id);
            if ~isa(overlay,'matlabx.ui.axes.overlays.Polygon') || ~isvalid(overlay)
                overlay = [];
            end
        end

        function point = clampPointToImage(obj, point)
        %CLAMPPOINTTOIMAGE Keep one vertex inside image coordinates.
            point = [min(max(point(1),1),obj.Host.ImageWidth), ...
                min(max(point(2),1),obj.Host.ImageHeight)];
        end

        function delta = clampTranslationDelta(obj, vertices, delta)
        %CLAMPTRANSLATIONDELTA Keep all translated vertices inside the image.
            delta(1) = min(max(delta(1),1-min(vertices(:,1))), ...
                obj.Host.ImageWidth-max(vertices(:,1)));
            delta(2) = min(max(delta(2),1-min(vertices(:,2))), ...
                obj.Host.ImageHeight-max(vertices(:,2)));
        end

        function setModeIfPresent(obj, modeName, value)
        %SETMODEIFPRESENT Update a registered mode during normal or teardown flow.
            if obj.isMode(modeName)
                obj.setMode(modeName, value);
            end
        end

        function requestDeletion(obj, ids)
        %REQUESTDELETION Single entry point for clicks and batch menu actions.
            ids = unique(matlabx.ui.axes.ImageAxesOverlayManager.normalizeIds(ids), "stable");
            % Ignore stale IDs and other overlay families before notifying the
            % app. Empty requests are no-ops, not empty application callbacks.
            keep = false(size(ids));
            for i = 1:numel(ids)
                overlay = obj.Host.Overlays.get(ids(i));
                keep(i) = isa(overlay, 'matlabx.ui.axes.overlays.Polygon') && isvalid(overlay);
            end
            ids = ids(keep);
            if isempty(ids), return; end

            if ~isempty(obj.PolygonsDeleteRequestedFcn)
                % This callback owns the decision AND model update. Do not clear
                % selection or delete anything first. Intentionally do not catch
                % exceptions: failure must never fall back to optimistic removal.
                % Changes made by the callback itself cannot be rolled back here.
                obj.PolygonsDeleteRequestedFcn(obj, struct('IDs', ids));
                return
            end

            % Preserve legacy sequencing: remove one, notify one, then continue.
            % An old callback may reconcile other IDs, so recheck each overlay.
            % Never call removePolygon here; it routes back to this helper.
            for i = 1:numel(ids)
                obj.removePolygonOptimistically(ids(i));
            end
        end

        function removePolygonOptimistically(obj, id)
        %REMOVEPOLYGONOPTIMISTICALLY Legacy deletion and per-ID notification.
            overlay = obj.Host.Overlays.get(id);
            if ~isa(overlay, 'matlabx.ui.axes.overlays.Polygon') || ~isvalid(overlay)
                return
            end
            obj.Host.Overlays.remove(id);
            if ~isempty(obj.PolygonDeletedFcn)
                obj.PolygonDeletedFcn(obj, struct('ID', id));
            end
        end

        function clearHover(obj)
            if strlength(obj.Host.Overlays.getHoverID(Type="Polygon")) > 0
                obj.Host.Overlays.clearHover();
            end
            obj.HoverPart = "";
            obj.setModeIfPresent('HoverPolygon', false);
            obj.setModeIfPresent('HoverVertex', false);
        end

        function emitActiveChanged(obj)
            if ~isempty(obj.PolygonActivatedFcn)
                obj.PolygonActivatedFcn(obj, ...
                    struct('ID', obj.Host.Overlays.getActiveID(Type="Polygon")));
            end
        end

        function emitSelectionChanged(obj)
            if ~isempty(obj.PolygonSelectionChangedFcn)
                obj.PolygonSelectionChangedFcn(obj, struct('IDs', obj.getSelectedPolygonIDs()));
            end
        end
    end
end
