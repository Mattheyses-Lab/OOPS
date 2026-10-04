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

classdef ImageAxesToolManager < handle
%IMAGEAXESTOOLMANAGER Tool loading, installation, toolbar, and routing helper.
%
%   ImageAxes exposes a compact Tools property. Assigning tool names installs
%   those tools; reading Tools returns the installed tool-object struct. This
%   manager owns the state and lifecycle mechanics behind that API.
%
%   Terminology:
%       Loaded tool
%           A tool object exists in memory and can be installed later. Loaded tools
%           do not necessarily have toolbar buttons or receive routed events.
%       Installed tool
%           A loaded tool is active in the host, has a toolbar button if
%           appropriate, can contribute hotkeys, and can receive routed events.
%
%   The manager keeps lifecycle bookkeeping, toolbar wiring, and event-routing
%   lookup out of ImageAxes while preserving the tool-owned install/uninstall
%   hooks in AxesTool subclasses.

    properties (SetAccess=private)
        Host matlabx.ui.axes.ImageAxes
        Tools struct = struct()
    end

    properties (Access=private)
        LoadedTools
        InstalledTools
    end

    methods
        function obj = ImageAxesToolManager(host)
        %IMAGEAXESTOOLMANAGER Create a manager for one ImageAxes host.
            obj.Host = host;
            obj.LoadedTools = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.InstalledTools = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end

        function register(obj, tool)
        %REGISTER Add an installed tool to manager and host state.
            if ~isvalid(tool)
                warning('Failed to register tool. Invalid handle.')
                return
            end

            obj.addToolbarButton(tool);
            obj.Tools.(char(tool.Name)) = tool;
            obj.InstalledTools(char(tool.Name)) = tool;
            obj.Host.registerToolHotkeys(tool);
            obj.contributeContextMenu(tool);
        end

        function unregister(obj, tool)
        %UNREGISTER Remove an installed tool while keeping it loaded.
            if ~obj.InstalledTools.isKey(char(tool.Name))
                warning('Failed to unregister tool. "%s" tool is not currently registered.', tool.Name)
                return
            end

            obj.Host.HotkeyRegistry.removeOwner(tool);
            obj.removeContextMenuContributions(tool);
            obj.removeToolbarButton(tool);
            obj.Tools = rmfield(obj.Tools, char(tool.Name));
            obj.InstalledTools.remove(char(tool.Name));
        end

        function loadAll(obj)
        %LOADALL Load every concrete tool class in matlabx.ui.axes.tools.
            obj.loadMany(obj.Host.getToolNames());
        end

        function unloadAll(obj)
        %UNLOADALL Unload every currently loaded tool.
            if isempty(obj.LoadedTools)
                return
            end

            toolNames = obj.LoadedTools.keys;
            obj.unloadMany(toolNames);
        end

        function loadMany(obj, toolNames)
        %LOADMANY Load a list of tool names.
            if isempty(toolNames)
                return
            end

            toolNames = obj.normalizeToolNames(toolNames);
            for i = 1:numel(toolNames)
                obj.load(toolNames{i});
            end
        end

        function unloadMany(obj, toolNames)
        %UNLOADMANY Unload a list of tool names.
            if isempty(toolNames)
                return
            end

            toolNames = obj.normalizeToolNames(toolNames);
            for i = 1:numel(toolNames)
                obj.unload(toolNames{i});
            end
        end

        function load(obj, name)
        %LOAD Construct a tool object and keep it available for installation.
            name = char(name);

            if obj.LoadedTools.isKey(name)
                warning('Failed to load tool. "%s" tool already loaded.', name)
                return
            end

            obj.LoadedTools(name) = matlabx.ui.axes.tools.(name)(obj.Host);
        end

        function unload(obj, name)
        %UNLOAD Delete a loaded tool, uninstalling it first if needed.
            name = char(name);

            if ~obj.LoadedTools.isKey(name)
                warning('Failed to unload tool. "%s" tool is not loaded.', name)
                return
            end

            tool = obj.getLoaded(name);
            if tool.Installed
                obj.uninstall(tool.Name);
            end

            delete(tool)
            obj.LoadedTools.remove(name);
        end

        function installMany(obj, toolNames)
        %INSTALLMANY Install a list of loaded tool names.
            if isempty(toolNames)
                return
            end

            toolNames = obj.normalizeToolNames(toolNames);
            for i = 1:numel(toolNames)
                obj.install(toolNames{i});
            end
        end

        function install(obj, name)
        %INSTALL Make a loaded tool active in the host.
            tool = obj.getLoaded(name);

            if isempty(tool)
                warning('Failed to install tool. "%s" tool is not loaded.', name)
                return
            end

            if obj.InstalledTools.isKey(char(tool.Name))
                warning('Failed to install tool. "%s" tool is already installed.', name)
                return
            end

            if ~ismember(tool.AxesType, ["image", "both"])
                warning('Failed to install tool. "%s" tool is for "%s" axes, not image axes.', ...
                    char(name), char(tool.AxesType))
                return
            end

            tool.install();
        end

        function uninstall(obj, name)
        %UNINSTALL Remove a tool from active host registries.
            tool = obj.getLoaded(name);

            if isempty(tool)
                warning('Failed to uninstall tool. "%s" tool is not loaded.', name)
                return
            end

            if ~obj.InstalledTools.isKey(char(tool.Name))
                warning('Failed to uninstall tool. "%s" tool is already uninstalled.', name)
                return
            end

            tool.uninstall();
        end

        function uninstallMany(obj, toolNames)
        %UNINSTALLMANY Uninstall a list of tool names.
            if isempty(toolNames)
                return
            end

            toolNames = obj.normalizeToolNames(toolNames);
            for i = 1:numel(toolNames)
                obj.uninstall(toolNames{i});
            end
        end

        function enable(obj, name)
        %ENABLE Enable an installed state tool by name.
            tool = obj.getInstalled(name);
            if isempty(tool)
                return
            end

            tool.enable();
        end

        function disable(obj, name)
        %DISABLE Disable an installed state tool by name.
            tool = obj.getInstalled(name);
            if isempty(tool)
                return
            end

            tool.disable();
        end

        function tf = enabled(obj, name)
        %ENABLED Return true when an installed tool is enabled.
            tool = obj.getInstalled(name);
            tf = ~isempty(tool) && isvalid(tool) && tool.Enabled;
        end

        function toggle(obj, toolState, name)
        %TOGGLE Enable or disable a state tool from a toolbar value.
            switch toolState
                case true
                    obj.enable(name);
                case false
                    obj.disable(name);
            end
        end

        function push(obj, name)
        %PUSH Execute a push-style installed tool.
            obj.run(name);
        end

        function run(obj, name)
        %RUN Invoke an installed tool's push action.
            tool = obj.getInstalled(name);
            if isempty(tool)
                return
            end

            tool.push();
        end

        function disableActiveExclusive(obj)
        %DISABLEACTIVEEXCLUSIVE Disable the host's active exclusive tool.
            existingExclusive = obj.Host.ActiveExclusiveTool;

            if isempty(existingExclusive)
                return
            end

            obj.disable(existingExclusive.Name);
        end

        function tool = getInstalled(obj, name)
        %GETINSTALLED Return an installed tool by name, or empty if missing.
            name = char(name);
            tool = [];

            if ~isempty(obj.InstalledTools) && isKey(obj.InstalledTools, name)
                tool = obj.InstalledTools(name);
            end
        end

        function tool = getLoaded(obj, name)
        %GETLOADED Return a loaded tool by name, or empty if missing.
            name = char(name);
            tool = [];

            if ~isempty(obj.LoadedTools) && isKey(obj.LoadedTools, name)
                tool = obj.LoadedTools(name);
            end
        end

        function tool = getPriorityInterceptor(obj, eventType)
        %GETPRIORITYINTERCEPTOR Highest-priority enabled active interceptor.
            toolsCell = obj.installedToolValues();

            if isempty(toolsCell)
                tool = [];
                return
            end

            idx = cellfun(@(t) t.Enabled & t.("Intercepts" + eventType), toolsCell, 'UniformOutput', true);

            if ~any(idx)
                tool = [];
                return
            end

            tools = obj.prioritySortCell(toolsCell(idx));
            tool = tools{1};
        end

        function toolsCell = getPriorityPassiveInterceptors(obj, eventType)
        %GETPRIORITYPASSIVEINTERCEPTORS Installed passive interceptors.
            toolsCell = obj.installedToolValues();

            if isempty(toolsCell)
                return
            end

            idx = cellfun(@(t) t.("PassivelyIntercepts" + eventType), toolsCell, 'UniformOutput', true);

            if ~any(idx)
                toolsCell = {};
                return
            end

            toolsCell = obj.prioritySortCell(toolsCell(idx));
        end

        function toolsCell = prioritySort(obj)
        %PRIORITYSORT Return installed tools sorted by descending priority.
            toolsCell = obj.prioritySortCell(obj.installedToolValues());
        end

        function notifyHostEnter(obj, E)
        %NOTIFYHOSTENTER Forward host-boundary enter events to installed tools.
            obj.notifyHostBoundary("onHostEnter", E);
        end

        function notifyHostLeave(obj, E)
        %NOTIFYHOSTLEAVE Forward host-boundary leave events to installed tools.
            obj.notifyHostBoundary("onHostLeave", E);
        end

        function toolsCell = prioritySortCell(~, toolsCell)
        %PRIORITYSORTCELL Sort a cell array of tools by descending priority.
            if isempty(toolsCell)
                return
            end

            priority = cellfun(@(t) t.Priority, toolsCell, 'UniformOutput', true);
            [~, sortIdx] = sort(priority, 'descend');
            toolsCell = toolsCell(sortIdx);
        end

        function names = getInstalledNames(obj)
        %GETINSTALLEDNAMES Return installed tool names.
            names = obj.InstalledTools.keys;
        end

        function setInstalledNames(obj, newToolNames)
        %SETINSTALLEDNAMES Replace the host's installed-tool set.
            newToolNames = obj.normalizeToolNames(newToolNames);
            oldToolNames = obj.getInstalledNames();
            toolsToAdd = setdiff(newToolNames, oldToolNames, 'stable');
            toolsToRemove = setdiff(oldToolNames, newToolNames, 'stable');

            for i = 1:numel(toolsToAdd)
                if ~obj.LoadedTools.isKey(toolsToAdd{i})
                    obj.load(toolsToAdd{i});
                end

                obj.install(toolsToAdd{i});
            end

            obj.uninstallMany(toolsToRemove);
        end

        function addToolbarButton(obj, tool)
        %ADDTOOLBARBUTTON Create a MATLAB axes toolbar button for an installed tool.
            host = obj.Host;

            switch tool.Style
                case 'push'
                    host.ToolbarButtons.(tool.Name) = axtoolbarbtn(host.mainAxes.Toolbar, 'push', ...
                        'Tooltip', tool.Tooltip, ...
                        'Icon', tool.Icon, ...
                        'ButtonPushedFcn', @(~,~) host.onToolPush(tool.Name));
                case 'state'
                    host.ToolbarButtons.(tool.Name) = axtoolbarbtn(host.mainAxes.Toolbar, 'state', ...
                        'Tooltip', tool.Tooltip, ...
                        'Icon', tool.Icon, ...
                        'ValueChangedFcn', @(btn,~) host.onToolToggle(btn.Value, tool.Name));
            end

            host.mainAxes.Toolbar.reset;
        end

        function removeToolbarButton(obj, tool)
        %REMOVETOOLBARBUTTON Delete the toolbar button associated with a tool.
            host = obj.Host;

            if ~isfield(host.ToolbarButtons, tool.Name)
                return
            end

            tbButton = host.ToolbarButtons.(tool.Name);

            if ~isvalid(tbButton)
                return
            end

            delete(tbButton)
            host.ToolbarButtons = rmfield(host.ToolbarButtons, tool.Name);
            host.mainAxes.Toolbar.reset;
        end

        function contributeContextMenu(obj, tool)
        %CONTRIBUTECONTEXTMENU Let a tool add owner-scoped context-menu items.
            if isempty(obj.Host.ContextMenuManager)
                return
            end

            tool.contributeContextMenu(obj.Host.ContextMenuManager);
            obj.Host.ContextMenuManager.refresh();
        end

        function removeContextMenuContributions(obj, tool)
        %REMOVECONTEXTMENUCONTRIBUTIONS Remove menu items owned by a tool.
            if isempty(obj.Host.ContextMenuManager)
                return
            end

            obj.Host.ContextMenuManager.removeOwner(tool);
        end
    end

    methods (Access=private)
        function notifyHostBoundary(obj, methodName, E)
        %NOTIFYHOSTBOUNDARY Call a host-boundary hook on installed tools.
            toolsCell = obj.prioritySort();
            for i = 1:numel(toolsCell)
                tool = toolsCell{i};
                if isempty(tool) || ~isvalid(tool)
                    continue
                end

                try
                    tool.(methodName)(E);
                catch err
                    warning('ImageAxesToolManager:HostBoundaryHookError', ...
                        'Error in %s.%s: %s', class(tool), methodName, err.message);
                end
            end
        end

        function toolsCell = installedToolValues(obj)
        %INSTALLEDTOOLVALUES Return installed tools as a cell array.
            if isempty(obj.InstalledTools)
                toolsCell = {};
            else
                toolsCell = obj.InstalledTools.values;
            end
        end

        function names = normalizeToolNames(~, names)
        %NORMALIZETOOLNAMES Convert user tool declarations to a cellstr row.
            if isempty(names)
                names = {};
                return
            end

            names = cellstr(string(names));
            names = reshape(names, 1, []);
            names(cellfun(@isempty, names)) = [];
        end
    end
end
