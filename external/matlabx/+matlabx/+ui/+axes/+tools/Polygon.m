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

classdef Polygon < matlabx.ui.axes.AxesTool
%POLYGON Inspect and manage existing polygon overlays without editing geometry.
%
%   This tool controls all Polygon overlays in the host registry. It keeps no
%   duplicate overlay list. Removing the tool leaves the overlays intact.
%   By default, PolygonDeletedFcn receives data.ID after each tool deletion.
%   With PolygonsDeleteRequestedFcn installed, one data.IDs request is sent
%   instead and the application owns deletion and overlay reconciliation.
%   Activation and selection callbacks also reflect manager/rectangle selection.

    properties
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
    end

    methods
        function obj = Polygon(host)
            obj@matlabx.ui.axes.AxesTool(host, "Polygon", ...
                'Tooltip', 'Polygon regions (help)', ...
                'AxesType', "image", 'Style', 'push', ...
                'Icon', matlabx.internal.Paths.icons('SelectionWhiteFGTransparentBG.svg'), ...
                'Priority', 10, ...
                'PassivelyInterceptsDown', true, ...
                'PassivelyInterceptsMove', true);
        end

        function onInstall(obj)
            obj.OverlayListeners(1) = addlistener(obj.Host.Overlays, 'ActiveChanged', ...
                @(~,~) obj.emitActiveChanged());
            obj.OverlayListeners(2) = addlistener(obj.Host.Overlays, 'SelectionChanged', ...
                @(~,~) obj.emitSelectionChanged());
        end

        function onUninstall(obj)
            obj.clearHover();
            delete(obj.OverlayListeners(isvalid(obj.OverlayListeners)));
            obj.OverlayListeners = event.listener.empty();
        end

        function onPush(obj)
            obj.Host.openToolHelpWindow(obj);
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

        function onPassiveDown(obj, E)
            % Let marquee selection start even when the press hits a polygon.
            if obj.rectangleSelectionEnabled(), return; end
            overlay = obj.Host.Overlays.overlayForTarget(E.Target);
            if ~isa(overlay, 'matlabx.ui.axes.overlays.Polygon'), return; end
            switch E.MouseChord
                case "click"
                    obj.setActivePolygonID(overlay.ID);
                case "shift+extendclick"
                    obj.Host.Overlays.toggleSelected(overlay.ID);
                case "alt+click"
                    obj.setActivePolygonID("");
                case "control+contextclick"
                    obj.removePolygon(overlay.ID);
                otherwise
                    return
            end
            E.stop();
        end

        function onPassiveMove(obj, E)
            if obj.rectangleSelectionEnabled()
                obj.clearHover();
                return
            end
            overlay = obj.Host.Overlays.overlayForTarget(E.Target);
            if isa(overlay, 'matlabx.ui.axes.overlays.Polygon')
                obj.Host.Overlays.setHover(overlay.ID);
            else
                obj.clearHover();
            end
        end

        function onHostLeave(obj, ~), obj.clearHover(); end

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
            summary = "Activate, select, and delete polygon regions supplied by your app.";
        end

        function usage = getUsageHelp(~)
            usage = ["Click a polygon to activate it; use the context menu for batch actions."; ...
                "Enable RectangleSelect to select polygon centroids with a marquee."; ...
                "The toolbar button opens this help; polygon interaction is available while installed."];
        end

        function B = getBindingHelp(~)
            B = struct("Activate", "click polygon", ...
                "ToggleSelection", "shift+extendclick polygon", ...
                "Deactivate", "alt+click polygon", ...
                "DeletePolygon", "control+contextclick polygon");
        end

        function notes = getNotesHelp(~)
            notes = ["Active and selected are separate states. Geometry cannot be dragged or edited."; ...
                "Each polygon displays one closed loop supplied by the application."; ...
                "Deleting a polygon does not modify the image mask."; ...
                "When configured, the application handles deletion requests before overlays change."; ...
                "Removing this tool preserves polygon overlays."];
        end
    end

    methods (Access=private)
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

        function tf = rectangleSelectionEnabled(obj)
            tools = obj.Host.Tools;
            tf = isfield(tools, 'RectangleSelect') && tools.RectangleSelect.Enabled;
        end

        function clearHover(obj)
            if strlength(obj.Host.Overlays.getHoverID(Type="Polygon")) > 0
                obj.Host.Overlays.clearHover();
            end
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
