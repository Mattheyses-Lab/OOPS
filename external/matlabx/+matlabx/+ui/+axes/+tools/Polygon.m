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
%   PolygonDeletedFcn receives data.ID for deletions requested through this tool.
%   Activation and selection callbacks also reflect manager/rectangle selection.

    properties
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
        %REMOVEPOLYGON Delete one polygon and notify the application.
            overlay = obj.Host.Overlays.get(id);
            if ~isa(overlay, 'matlabx.ui.axes.overlays.Polygon'), return; end
            id = overlay.ID;
            obj.Host.Overlays.remove(id);
            if ~isempty(obj.PolygonDeletedFcn)
                obj.PolygonDeletedFcn(obj, struct('ID', id));
            end
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
            if strlength(id) > 0, obj.removePolygon(id); end
        end

        function deleteSelectedPolygons(obj)
            ids = obj.getSelectedPolygonIDs();
            for i = 1:numel(ids), obj.removePolygon(ids(i)); end
        end

        function deleteAllPolygons(obj)
            ids = obj.Host.Overlays.ids(Type="Polygon");
            for i = 1:numel(ids), obj.removePolygon(ids(i)); end
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
                "All loops of a polygon, including holes, belong to one region."; ...
                "Deleting a polygon does not modify the image mask."; ...
                "Removing this tool preserves polygon overlays."];
        end
    end

    methods (Access=private)
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
