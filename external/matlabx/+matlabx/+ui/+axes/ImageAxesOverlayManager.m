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
        %REMOVE Delete and unregister an overlay by ID.
            id = obj.normalizeId(id);
            if ~obj.has(id)
                return
            end

            overlay = obj.get(id);
            wasActive = obj.ActiveID == id;
            wasHover = obj.HoverID == id;
            wasSelected = any(obj.SelectedIDs == id);

            % State is manager-owned, so removal also clears any state pointing
            % at this overlay before its graphics disappear.
            obj.clearStateForID(id);
            obj.Registry.remove(char(id));

            if isvalid(overlay)
                delete(overlay);
            end

            notify(obj, 'OverlayRemoved');
            if wasActive
                notify(obj, 'ActiveChanged');
            end
            if wasHover
                notify(obj, 'HoverChanged');
            end
            if wasSelected
                notify(obj, 'SelectionChanged');
            end
        end

        function clear(obj)
        %CLEAR Delete all overlays and reset active/hover/selection state.
            ids = obj.ids();
            for i = numel(ids):-1:1
                obj.remove(ids(i));
            end

            obj.ActiveID = "";
            obj.HoverID = "";
            obj.SelectedIDs = string.empty(1,0);
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
        %SETSELECTED Replace selected overlay IDs.
            arguments
                obj
                ids
                opts.Type (1,1) string = ""
            end

            ids = obj.normalizeIds(ids);
            ids = ids(arrayfun(@(id) obj.has(id), ids));
            ids = obj.filterIDsByType(ids, opts.Type);

            % A type-filtered replacement should only modify selection for that
            % overlay family, leaving other future overlay types untouched.
            old = obj.getSelectedIDs(Type=opts.Type);
            for i = 1:numel(old)
                if obj.has(old(i))
                    overlay = obj.get(old(i));
                    overlay.Selected = false;
                end
            end

            if strlength(opts.Type) > 0
                keep = obj.SelectedIDs(~ismember(obj.SelectedIDs, old));
                obj.SelectedIDs = [keep, unique(ids, "stable")];
            else
                obj.SelectedIDs = unique(ids, "stable");
            end

            for i = 1:numel(ids)
                overlay = obj.get(ids(i));
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

        function deselect(obj, id)
        %DESELECT Remove one overlay from the selected set.
            id = obj.normalizeId(id);
            obj.SelectedIDs(obj.SelectedIDs == id) = [];
            if obj.has(id)
                overlay = obj.get(id);
                overlay.Selected = false;
            end
            notify(obj, 'SelectionChanged');
        end

        function toggleSelected(obj, id)
        %TOGGLESELECTED Toggle selected state for one overlay.
            id = obj.normalizeId(id);
            if any(obj.SelectedIDs == id)
                obj.deselect(id);
            else
                obj.select(id);
            end
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

            candidateIDs = obj.idsForTypes(opts.Type);
            keep = false(size(candidateIDs));

            for i = 1:numel(candidateIDs)
                overlay = obj.get(candidateIDs(i));
                keep(i) = isvalid(overlay) && overlay.isInsideRectangle(rect);
            end

            ids = candidateIDs(keep);
        end

        function refreshVisibility(obj)
        %REFRESHVISIBILITY Sync overlay visibility to current C/Z/T view.
            vals = obj.Registry.values;
            for i = 1:numel(vals)
                overlay = vals{i};
                if ~isvalid(overlay)
                    continue
                end

                visible = overlay.appliesToView( ...
                    obj.Host.C, obj.Host.Z, obj.Host.T, obj.Host.ShowComposite);
                overlay.setViewVisible(matlab.lang.OnOffSwitchState(visible));
            end
        end
    end

    methods (Access=private)
        function clearStateForID(obj, id)
        %CLEARSTATEFORID Remove one ID from active/hover/selection state.
            if obj.has(id)
                overlay = obj.get(id);
                if isvalid(overlay)
                    overlay.Active = false;
                    overlay.Hovered = false;
                    overlay.Selected = false;
                end
            end

            if obj.ActiveID == id
                obj.ActiveID = "";
            end
            if obj.HoverID == id
                obj.HoverID = "";
            end
            obj.SelectedIDs(obj.SelectedIDs == id) = [];
        end

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
