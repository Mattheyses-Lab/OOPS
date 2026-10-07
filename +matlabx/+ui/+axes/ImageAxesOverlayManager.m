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

classdef ImageAxesOverlayManager < handle
%IMAGEAXESOVERLAYMANAGER Registry and state manager for ImageAxes overlays.
%
%   The manager owns overlay lifetime and cross-overlay state such as active,
%   hovered, and selected IDs. Tools remain controllers: they decide when to
%   create, drag, select, activate, or delete overlays.

    properties (SetAccess=private)
        Host matlabx.ui.axes.ImageAxes
    end

    properties (Access=private)
        Registry
        ActiveID (1,1) string = ""
        HoverID (1,1) string = ""
        SelectedIDs (1,:) string = string.empty(1,0)
    end

    events
        OverlayAdded
        OverlayRemoved
        ActiveChanged
        SelectionChanged
        HoverChanged
    end

    methods
        function obj = ImageAxesOverlayManager(host)
        %IMAGEAXESOVERLAYMANAGER Create an overlay manager for one host.
            obj.Host = host;
            obj.Registry = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function overlay = add(obj, typeOrOverlay, varargin)
        %ADD Add an existing overlay or construct one by short type name.
            % Accept either a fully constructed overlay object or a simple type
            % name such as "Box". The latter resolves to
            % matlabx.ui.axes.overlays.Box and forwards name-value arguments.
            if isa(typeOrOverlay, "matlabx.ui.axes.ImageAxesOverlay")
                overlay = typeOrOverlay;
            else
                typeName = string(typeOrOverlay);
                className = obj.overlayClassName(typeName);
                overlay = feval(className, obj.Host, varargin{:});
            end

            id = obj.normalizeId(overlay.ID);
            if strlength(id) == 0
                error('ImageAxesOverlayManager:InvalidID', ...
                    'Overlay ID must be a nonempty text scalar.');
            end

            if obj.Registry.isKey(char(id))
                error('ImageAxesOverlayManager:DuplicateID', ...
                    'Overlay ID "%s" already exists.', id);
            end

            % Register before refreshVisibility so C/Z/T visibility can include
            % this new overlay immediately.
            obj.Registry(char(id)) = overlay;
            overlay.refresh();
            obj.refreshVisibility();
            notify(obj, 'OverlayAdded');

            if overlay.ActivateOnCreate
                obj.setActive(id);
            end
        end

        function remove(obj, id)
        %REMOVE Delete one overlay using the same notification path as a batch.
            obj.removeMany(obj.normalizeId(id));
        end

        function removeMany(obj, ids)
        %REMOVEMANY Delete overlays and publish their final shared state.
        %
        %   Duplicate/missing IDs are ignored. Surviving overlays retain their
        %   state and selection order. This is a graphics/registry operation:
        %   it never invokes a tool's application deletion-request callback.
        %
        %   OverlayRemoved fires once per removed ID for compatibility, in
        %   request order, after the ENTIRE batch is removed. It retains its
        %   existing empty event payload. ActiveChanged, HoverChanged, and
        %   SelectionChanged then fire at most once each, only when affected.
        %   Listeners should query the manager for the completed batch state.

            ids = unique(obj.normalizeIds(ids), "stable");
            ids = ids(arrayfun(@(id) obj.has(id), ids));
            if isempty(ids), return; end

            activeChanged = any(ismember(obj.ActiveID, ids));
            hoverChanged = any(ismember(obj.HoverID, ids));
            selectedRemoved = ismember(obj.SelectedIDs, ids);
            selectionChanged = any(selectedRemoved);

            % Keep handles locally while detaching the entire batch. Clear the
            % manager's references before deleting graphics, since destruction
            % itself can run user listeners. No manager event is emitted yet.
            overlays = cell(1, numel(ids));
            for i = 1:numel(ids)
                overlays{i} = obj.get(ids(i));
            end
            if activeChanged, obj.ActiveID = ""; end
            if hoverChanged, obj.HoverID = ""; end
            obj.SelectedIDs(selectedRemoved) = [];
            obj.Registry.remove(cellstr(ids));

            % Do not repaint doomed overlays by clearing their appearance
            % flags first. They are no longer registered and are being deleted.
            for i = 1:numel(overlays)
                if isvalid(overlays{i})
                    delete(overlays{i});
                end
            end

            % Retain legacy removal notification counts, but coalesce shared
            % state notifications so applications reconcile selection once.
            for i = 1:numel(ids)
                notify(obj, 'OverlayRemoved');
            end
            if activeChanged, notify(obj, 'ActiveChanged'); end
            if hoverChanged, notify(obj, 'HoverChanged'); end
            if selectionChanged, notify(obj, 'SelectionChanged'); end
        end

        function clear(obj)
        %CLEAR Remove all overlays with the same final-state batch semantics.
            obj.removeMany(obj.ids());
        end

        function overlay = get(obj, id)
        %GET Return overlay by ID, or [] if not found.
            id = obj.normalizeId(id);
            if ~obj.has(id)
                overlay = [];
                return
            end

            overlay = obj.Registry(char(id));
        end

        function tf = has(obj, id)
        %HAS True when an overlay with ID exists.
            id = obj.normalizeId(id);
            tf = strlength(id) > 0 && obj.Registry.isKey(char(id));
        end

        function ids = ids(obj, opts)
        %IDS Return registered overlay IDs, optionally filtered by Type.
            arguments
                obj
                opts.Type (1,1) string = ""
            end

            ids = string(obj.Registry.keys);
            ids = obj.filterIDsByType(ids, opts.Type);
        end

        function overlays = all(obj, opts)
        %ALL Return registered overlay objects as a cell array.
            arguments
                obj
                opts.Type (1,1) string = ""
            end

            ids = obj.ids(Type=opts.Type);
            overlays = cell(1, numel(ids));
            for i = 1:numel(ids)
                overlays{i} = obj.get(ids(i));
            end
        end

        function overlay = overlayForTarget(obj, h)
        %OVERLAYFORTARGET Return the overlay that owns a graphics target.
            overlay = [];

            if isempty(h)
                return
            end

            try
                id = getappdata(h, "matlabxOverlayID");
                if ~isempty(id) && obj.has(id)
                    overlay = obj.get(id);
                    return
                end
            catch
            end

            vals = obj.Registry.values;
            for i = 1:numel(vals)
                candidate = vals{i};
                if isvalid(candidate) && candidate.containsGraphics(h)
                    overlay = candidate;
                    return
                end
            end
        end

        function setActive(obj, id)
        %SETACTIVE Make one overlay active and clear prior active state.
            id = obj.normalizeId(id);
            if strlength(id) > 0 && ~obj.has(id)
                return
            end

            if obj.ActiveID == id
                return
            end

            if strlength(obj.ActiveID) > 0 && obj.has(obj.ActiveID)
                overlay = obj.get(obj.ActiveID);
                overlay.Active = false;
            end

            obj.ActiveID = id;

            if strlength(id) > 0
                overlay = obj.get(id);
                overlay.Active = true;
            end

            notify(obj, 'ActiveChanged');
        end

        function clearActive(obj)
        %CLEARACTIVE Clear active overlay state.
            obj.setActive("");
        end

        function id = getActiveID(obj, opts)
        %GETACTIVEID Return the active overlay ID, optionally filtered by Type.
            arguments
                obj
                opts.Type (1,1) string = ""
            end

            id = obj.ActiveID;
            if strlength(opts.Type) > 0 && ~obj.idMatchesType(id, opts.Type)
                id = "";
            end
        end

        function setHover(obj, id)
        %SETHOVER Make one overlay hovered and clear prior hover state.
            id = obj.normalizeId(id);
            if strlength(id) > 0 && ~obj.has(id)
                return
            end

            if obj.HoverID == id
                return
            end

            if strlength(obj.HoverID) > 0 && obj.has(obj.HoverID)
                overlay = obj.get(obj.HoverID);
                overlay.Hovered = false;
            end

            obj.HoverID = id;

            if strlength(id) > 0
                overlay = obj.get(id);
                overlay.Hovered = true;
            end

            notify(obj, 'HoverChanged');
        end

        function clearHover(obj)
        %CLEARHOVER Clear hover overlay state.
            obj.setHover("");
        end

        function id = getHoverID(obj, opts)
        %GETHOVERID Return the hovered overlay ID, optionally filtered by Type.
            arguments
                obj
                opts.Type (1,1) string = ""
            end

            id = obj.HoverID;
            if strlength(opts.Type) > 0 && ~obj.idMatchesType(id, opts.Type)
                id = "";
            end
        end

        function setSelected(obj, ids, opts)
        %SETSELECTED Replace membership, optionally within one overlay type.
        %   Retained IDs keep their order and appearance. New IDs are appended
        %   in request order. Unchanged membership produces no notification;
        %   a real change produces exactly one SelectionChanged notification.
            arguments
                obj
                ids
                opts.Type (1,1) string = ""
            end

            ids = unique(obj.normalizeIds(ids), "stable");
            ids = ids(arrayfun(@(id) obj.has(id), ids));
            ids = obj.filterIDsByType(ids, opts.Type);

            % Compare membership only. Reordering the same IDs must not repaint
            % retained overlays or trigger application reconciliation.
            old = obj.getSelectedIDs(Type=opts.Type);
            removed = old(~ismember(old, ids));
            added = ids(~ismember(ids, old));
            if isempty(removed) && isempty(added), return; end

            % Preserve all survivors in their existing order (including other
            % overlay types), then append additions in stable request order.
            % Publish IDs before appearance setters, which can run listeners.
            obj.SelectedIDs = [obj.SelectedIDs(~ismember(obj.SelectedIDs, removed)), added];
            for i = 1:numel(removed)
                overlay = obj.get(removed(i));
                if ~isempty(overlay) && isvalid(overlay)
                    overlay.Selected = false;
                end
            end
            for i = 1:numel(added)
                overlay = obj.get(added(i));
                overlay.Selected = true;
            end

            notify(obj, 'SelectionChanged');
        end

        function select(obj, id)
        %SELECT Add one overlay to the selected set.
            id = obj.normalizeId(id);
            if strlength(id) == 0 || ~obj.has(id) || any(obj.SelectedIDs == id)
                return
            end

            obj.SelectedIDs(end+1) = id;
            overlay = obj.get(id);
            overlay.Selected = true;
            notify(obj, 'SelectionChanged');
        end

        function deselect(obj, ids)
        %DESELECT Remove one or more overlays in one selection transaction.
        %   Missing, duplicate, and already-unselected IDs are harmless. The
        %   differential setSelected path updates visuals once per affected
        %   overlay and emits at most one SelectionChanged notification.
            ids = unique(obj.normalizeIds(ids), "stable");
            final = obj.SelectedIDs(~ismember(obj.SelectedIDs, ids));
            obj.setSelected(final);
        end

        function toggleSelected(obj, ids)
        %TOGGLESELECTED Toggle one or more overlays in one transaction.
        %   Surviving selections retain their order. Newly selected IDs are
        %   appended in stable request order. Each valid ID is toggled once.
            ids = unique(obj.normalizeIds(ids), "stable");
            ids = ids(arrayfun(@(id) obj.has(id), ids));
            remove = ids(ismember(ids, obj.SelectedIDs));
            add = ids(~ismember(ids, obj.SelectedIDs));
            final = [obj.SelectedIDs(~ismember(obj.SelectedIDs, remove)), add];
            obj.setSelected(final);
        end

        function clearSelection(obj, opts)
        %CLEARSELECTION Clear selected overlays, optionally filtered by Type.
            arguments
                obj
                opts.Type (1,1) string = ""
            end

            obj.setSelected(string.empty(1,0), Type=opts.Type);
        end

        function ids = getSelectedIDs(obj, opts)
        %GETSELECTEDIDS Return selected overlay IDs, optionally filtered by Type.
            arguments
                obj
                opts.Type (1,1) string = ""
            end

            ids = obj.filterIDsByType(obj.SelectedIDs, opts.Type);
        end

        function ids = idsInsideRectangle(obj, rect, opts)
        %IDSINSIDERECTANGLE Return overlay IDs whose selection point is inside rect.
        %
        %   RECT is [xmin xmax ymin ymax] in image data coordinates. Type can
        %   be "all", "", a scalar type such as "Point", or a string vector.
            arguments
                obj
                rect (1,4) double
                opts.Type (1,:) string = ""
            end

            if obj.Host.OverlaysVisible == "off"
                ids = string.empty(1,0);
                return
            end

            candidateIDs = obj.idsForTypes(opts.Type);
            keep = false(size(candidateIDs));

            for i = 1:numel(candidateIDs)
                overlay = obj.get(candidateIDs(i));
                keep(i) = isvalid(overlay) && overlay.isInsideRectangle(rect);
            end

            ids = candidateIDs(keep);
        end

        function selectInsideRectangle(obj, rect, opts)
        %SELECTINSIDERECTANGLE Apply one batched rectangle-selection update.
        %   Mode is "replace", "toggle", or "remove". Type accepts the same
        %   scalar/vector filters as idsInsideRectangle. Restricted replace
        %   preserves selected overlays outside the requested types.
            arguments
                obj
                rect (1,4) double
                opts.Mode (1,1) string {mustBeMember(opts.Mode, ...
                    ["replace","toggle","remove"])} = "replace"
                opts.Type (1,:) string = ""
            end

            enclosed = obj.idsInsideRectangle(rect, Type=opts.Type);
            switch opts.Mode
                case "toggle"
                    obj.toggleSelected(enclosed);
                case "remove"
                    obj.deselect(enclosed);
                case "replace"
                    current = obj.getSelectedIDs();
                    targeted = obj.filterIDsByType(current, opts.Type);
                    survivors = current(~ismember(current, targeted));
                    obj.setSelected([survivors, enclosed]);
            end
        end

        function refreshVisibility(obj)
        %REFRESHVISIBILITY Combine host visibility with current C/Z/T applicability.
            vals = obj.Registry.values;
            for i = 1:numel(vals)
                overlay = vals{i};
                if ~isvalid(overlay)
                    continue
                end

                visible = obj.Host.OverlaysVisible == "on" && overlay.appliesToView( ...
                    obj.Host.C, obj.Host.Z, obj.Host.T, obj.Host.ShowComposite);
                overlay.setViewVisible(matlab.lang.OnOffSwitchState(visible));
            end
        end
    end

    methods (Access=private)
        function ids = filterIDsByType(obj, ids, typeName)
        %FILTERIDSBYTYPE Keep only IDs whose overlays match typeName.
            ids = obj.normalizeIds(ids);
            typeName = string(typeName);
            if isempty(typeName) || any(typeName == "") || any(strcmpi(typeName, "all"))
                return
            end

            keep = false(size(ids));
            for i = 1:numel(ids)
                keep(i) = any(arrayfun(@(t) obj.idMatchesType(ids(i), t), typeName));
            end
            ids = ids(keep);
        end

        function ids = idsForTypes(obj, typeNames)
        %IDSFORTYPES Return registered IDs filtered by scalar/vector type names.
            typeNames = string(typeNames);
            if isempty(typeNames) || any(typeNames == "") || any(strcmpi(typeNames, "all"))
                ids = obj.ids();
                return
            end

            ids = string.empty(1,0);
            for i = 1:numel(typeNames)
                ids = [ids, obj.ids(Type=typeNames(i))]; %#ok<AGROW>
            end
            ids = unique(ids, "stable");
        end

        function tf = idMatchesType(obj, id, typeName)
        %IDMATCHESTYPE True when id exists and its overlay Type matches.
            id = obj.normalizeId(id);
            typeName = string(typeName);
            tf = false;

            if strlength(id) == 0 || strlength(typeName) == 0 || ~obj.has(id)
                return
            end

            overlay = obj.get(id);
            tf = isvalid(overlay) && strcmpi(overlay.Type, typeName);
        end
    end

    methods (Static)
        function id = normalizeId(id)
        %NORMALIZEID Convert input to a scalar string ID.
            id = string(id);
            if isempty(id)
                id = "";
            else
                id = id(1);
            end
        end

        function ids = normalizeIds(ids)
        %NORMALIZEIDS Convert input to a row string array.
            ids = string(ids);
            ids = ids(:).';
        end

        function className = overlayClassName(typeName)
        %OVERLAYCLASSNAME Resolve short overlay names to class names.
            typeName = string(typeName);
            if contains(typeName, ".")
                className = char(typeName);
            else
                className = char("matlabx.ui.axes.overlays." + typeName);
            end
        end
    end
end
