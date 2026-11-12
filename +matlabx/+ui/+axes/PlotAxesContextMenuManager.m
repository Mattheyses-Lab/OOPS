classdef PlotAxesContextMenuManager < handle
%PLOTAXESCONTEXTMENUMANAGER Own PlotAxes menus and tool contributions.
%
%   The manager keeps the PlotAxes built-in menu configurable while giving
%   installed PlotAxesTool objects an owner-scoped contribution API. Removing
%   a tool removes only the items contributed by that tool.

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

    properties (SetAccess=private)
        % PlotAxes host whose menu state is represented.
        Host matlabx.ui.axes.PlotAxes
        % MATLAB context-menu graphics object assigned to the hosted axes.
        Menu matlab.ui.container.ContextMenu
    end

    properties (Access=private)
        % Handles for the currently constructed built-in items.
        BuiltinUI struct = struct()
        % Owner-scoped tool/application menu entries keyed by normalized id.
        Items struct = struct()
        % Stable insertion order for contributed entries.
        ItemOrder_ (1,:) string = string.empty(1,0)
        % Requested built-in root items in display order.
        BuiltinItems_ (1,:) string = ["Display","ResetView","Status"]
    end

    methods
        function obj = PlotAxesContextMenuManager(host,parentFigure)
        %PLOTAXESCONTEXTMENUMANAGER Create the host-owned context menu.
            obj.Host = host;
            obj.Menu = uicontextmenu(parentFigure);
            obj.Menu.ContextMenuOpeningFcn = @(~,~) obj.refresh();
            obj.Host.ContextMenu = obj.Menu;
            obj.rebuild();
        end

        function rebuild(obj)
        %REBUILD Recreate built-ins while retaining contributed entries.
            obj.clearBuiltins();
            S = struct();
            for i = 1:numel(obj.BuiltinItems_)
                switch obj.BuiltinItems_(i)
                    case "Display"
                        S = obj.buildDisplayMenu(S,obj.Menu);
                    case "ResetView"
                        S.ResetView = uimenu(obj.Menu, ...
                            "Text","Reset View", ...
                            "MenuSelectedFcn",@(~,~) obj.Host.resetView());
                    case "Status"
                        S.Status = uimenu(obj.Menu, ...
                            "Text","Status...", ...
                            "MenuSelectedFcn",@(~,~) obj.Host.openStatusWindow());
                    case "Toolbar"
                        S = obj.buildToolbarMenu(S,obj.Menu);
                    case "Grid"
                        S = obj.buildGridMenu(S,obj.Menu);
                    case "Box"
                        S = obj.buildBoxMenu(S,obj.Menu);
                    case "Title"
                        S = obj.buildTitleMenu(S,obj.Menu);
                end
            end
            obj.BuiltinUI = S;
            obj.orderRootMenus();
            obj.refresh();
        end

        function refresh(obj)
        %REFRESH Synchronize checked state and contributed refresh callbacks.
            if isfield(obj.BuiltinUI,"Toolbar")
                obj.BuiltinUI.Toolbar.Checked = obj.Host.ToolbarVisible;
            end
            if isfield(obj.BuiltinUI,"Grid")
                obj.BuiltinUI.Grid.Checked = obj.Host.GridVisible;
            end
            if isfield(obj.BuiltinUI,"Box")
                obj.BuiltinUI.Box.Checked = obj.Host.BoxVisible;
            end
            if isfield(obj.BuiltinUI,"Title")
                obj.BuiltinUI.Title.Checked = obj.Host.TitleVisible;
            end

            names = fieldnames(obj.Items);
            for i = 1:numel(names)
                entry = obj.Items.(names{i});
                if isvalid(entry.Handle) && ~isempty(entry.RefreshFcn)
                    entry.RefreshFcn(entry.Handle);
                end
            end
        end

        function openAt(obj,xy)
        %OPENAT Refresh and open the menu at figure pixel coordinates.
            obj.refresh();
            open(obj.Menu,xy(1),xy(2));
        end

        function items = getBuiltinItems(obj)
        %GETBUILTINITEMS Return enabled built-in menu item names.
            items = obj.BuiltinItems_;
        end

        function setBuiltinItems(obj,items)
        %SETBUILTINITEMS Replace the configured built-in menu roots.
            obj.BuiltinItems_ = obj.validateBuiltinItems(items);
            obj.rebuild();
        end

        function h = addSubmenu(obj,id,label,opts)
        %ADDSUBMENU Add or replace an owner-scoped contributed submenu.
            arguments
                obj
                id (1,1) string
                label (1,1) string
                opts.Parent = ""
                opts.Owner = []
                opts.Separator matlab.lang.OnOffSwitchState = "off"
                opts.Enabled matlab.lang.OnOffSwitchState = "on"
                opts.Visible matlab.lang.OnOffSwitchState = "on"
                opts.RefreshFcn = []
            end
            obj.removeItem(id);
            parent = obj.getParentMenu(opts.Parent);
            field = obj.idToFieldName(id);
            h = uimenu(parent,"Text",label,"Separator",opts.Separator, ...
                "Enable",opts.Enabled,"Visible",opts.Visible);
            obj.Items.(field) = obj.makeEntry( ...
                h,opts.Owner,opts.RefreshFcn,opts.Parent);
            obj.ItemOrder_(end+1) = string(field);
            obj.orderRootMenus();
        end

        function h = addItem(obj,id,label,callback,opts)
        %ADDITEM Add or replace an owner-scoped contributed command.
            arguments
                obj
                id (1,1) string
                label (1,1) string
                callback (1,1) function_handle
                opts.Parent = ""
                opts.Owner = []
                opts.Separator matlab.lang.OnOffSwitchState = "off"
                opts.Checked matlab.lang.OnOffSwitchState = "off"
                opts.Enabled matlab.lang.OnOffSwitchState = "on"
                opts.Visible matlab.lang.OnOffSwitchState = "on"
                opts.UserData = []
                opts.RefreshFcn = []
            end
            obj.removeItem(id);
            parent = obj.getParentMenu(opts.Parent);
            field = obj.idToFieldName(id);
            h = uimenu(parent,"Text",label,"MenuSelectedFcn",callback, ...
                "Separator",opts.Separator,"Checked",opts.Checked, ...
                "Enable",opts.Enabled,"Visible",opts.Visible, ...
                "UserData",opts.UserData);
            obj.Items.(field) = obj.makeEntry( ...
                h,opts.Owner,opts.RefreshFcn,opts.Parent);
            obj.ItemOrder_(end+1) = string(field);
            obj.orderRootMenus();
        end

        function removeItem(obj,id)
        %REMOVEITEM Delete one contributed entry by id.
            field = obj.idToFieldName(id);
            if ~isfield(obj.Items,field), return; end
            h = obj.Items.(field).Handle;
            if isvalid(h), delete(h); end
            obj.Items = rmfield(obj.Items,field);
            obj.ItemOrder_(obj.ItemOrder_ == string(field)) = [];
        end

        function removeOwner(obj,owner)
        %REMOVEOWNER Delete every contribution belonging to one owner.
            names = fieldnames(obj.Items);
            for i = numel(names):-1:1
                if obj.ownersMatch(obj.Items.(names{i}).Owner,owner)
                    obj.removeItem(names{i});
                end
            end
        end

        function clear(obj)
        %CLEAR Delete all menu graphics and contribution records.
            if isvalid(obj.Menu), delete(obj.Menu.Children); end
            obj.BuiltinUI = struct();
            obj.Items = struct();
            obj.ItemOrder_ = string.empty(1,0);
        end
    end

    methods (Static)
        function items = availableBuiltinItems()
        %AVAILABLEBUILTINITEMS Return valid PlotAxes built-in menu tokens.
            items = ["Display","Toolbar","Grid","Box","Title","ResetView","Status"];
        end

        function items = validateBuiltinItems(items)
        %VALIDATEBUILTINITEMS Validate and canonicalize built-in menu tokens.
            items = reshape(string(items),1,[]);
            available = matlabx.ui.axes.PlotAxesContextMenuManager.availableBuiltinItems();
            for i = 1:numel(items)
                match = strcmpi(items(i),available);
                if ~any(match)
                    error('PlotAxesContextMenuManager:InvalidBuiltinItem', ...
                        '"%s" is not a valid PlotAxes context menu item.',items(i));
                end
                items(i) = available(find(match,1));
            end
            items = unique(items,"stable");
        end
    end

    methods (Access=private)
        function S = buildDisplayMenu(obj,S,parent)
        %BUILDDISPLAYMENU Add the grouped display-state submenu.
            S.Display = uimenu(parent,"Text","Display");
            S = obj.buildToolbarMenu(S,S.Display);
            S = obj.buildGridMenu(S,S.Display);
            S = obj.buildBoxMenu(S,S.Display);
            S = obj.buildTitleMenu(S,S.Display);
        end

        function S = buildToolbarMenu(obj,S,parent)
        %BUILDTOOLBARMENU Add the toolbar visibility command.
            S.Toolbar = uimenu(parent,"Text","Show Toolbar", ...
                "MenuSelectedFcn",@(~,~) obj.Host.toggleToolbar(), ...
                "Checked",obj.Host.ToolbarVisible);
        end

        function S = buildGridMenu(obj,S,parent)
        %BUILDGRIDMENU Add the major-grid visibility command.
            S.Grid = uimenu(parent,"Text","Show Grid", ...
                "MenuSelectedFcn",@(~,~) obj.Host.toggleGrid(), ...
                "Checked",obj.Host.GridVisible);
        end

        function S = buildBoxMenu(obj,S,parent)
        %BUILDBOXMENU Add the axes-box visibility command.
            S.Box = uimenu(parent,"Text","Show Box", ...
                "MenuSelectedFcn",@(~,~) obj.Host.toggleBox(), ...
                "Checked",obj.Host.BoxVisible);
        end

        function S = buildTitleMenu(obj,S,parent)
        %BUILDTITLEMENU Add the axes-title visibility command.
            S.Title = uimenu(parent,"Text","Show Title", ...
                "MenuSelectedFcn",@(~,~) obj.Host.toggleTitle(), ...
                "Checked",obj.Host.TitleVisible);
        end

        function clearBuiltins(obj)
        %CLEARBUILTINS Delete built-ins without touching contributions.
            values = struct2cell(obj.BuiltinUI);
            for i = 1:numel(values)
                if isgraphics(values{i}), delete(values{i}); end
            end
            obj.BuiltinUI = struct();
        end

        function orderRootMenus(obj)
        %ORDERROOTMENUS Keep built-ins above contributed root entries.
            position = 1;
            roots = struct2cell(obj.BuiltinUI);
            for i = 1:numel(roots)
                h = roots{i};
                if isgraphics(h) && isequal(h.Parent,obj.Menu)
                    h.Position = position;
                    position = position + 1;
                end
            end
            for i = 1:numel(obj.ItemOrder_)
                field = char(obj.ItemOrder_(i));
                if ~isfield(obj.Items,field), continue; end
                entry = obj.Items.(field);
                if strlength(string(entry.ParentId)) == 0 && isvalid(entry.Handle)
                    entry.Handle.Position = position;
                    position = position + 1;
                end
            end
        end

        function parent = getParentMenu(obj,parentId)
        %GETPARENTMENU Resolve a root or contributed submenu parent.
            if strlength(string(parentId)) == 0
                parent = obj.Menu;
                return
            end
            field = obj.idToFieldName(parentId);
            if ~isfield(obj.Items,field)
                error('PlotAxesContextMenuManager:MissingParent', ...
                    'Context menu parent "%s" does not exist.',string(parentId));
            end
            parent = obj.Items.(field).Handle;
        end
    end

    methods (Static, Access=private)
        function entry = makeEntry(handle,owner,refreshFcn,parentId)
        %MAKEENTRY Package one contributed handle and its ownership metadata.
            entry = struct("Handle",handle,"Owner",owner, ...
                "RefreshFcn",refreshFcn,"ParentId",string(parentId));
        end

        function field = idToFieldName(id)
        %IDTOFIELDNAME Convert an arbitrary contribution id to a struct field.
            field = matlab.lang.makeValidName(char(string(id)));
        end

        function tf = ownersMatch(a,b)
        %OWNERSMATCH Compare handle or value owner tokens safely.
            if isempty(a) || isempty(b)
                tf = isempty(a) && isempty(b);
                return
            end
            try
                tf = isequal(a,b);
            catch
                tf = false;
            end
        end
    end
end
