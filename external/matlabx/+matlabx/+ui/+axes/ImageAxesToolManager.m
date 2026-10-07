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
            obj.validateTool(tool);
            existing = obj.getInstalled(tool.Name);
            if ~isempty(existing)
                if existing == tool
                    return;
                end
                error('matlabx:ui:ToolNameConflict', ...
                    'A different tool named "%s" is already installed.',tool.Name);
            end

            % Publish identity before contributions so failure cleanup can
            % remove everything through the ordinary unregister path.
            obj.Tools.(char(tool.Name)) = tool;
            obj.InstalledTools(char(tool.Name)) = tool;
            try
                if tool.ContributeToolbar
                    obj.addToolbarButton(tool);
                end
                obj.Host.registerToolHotkeys(tool);
                if tool.ContributeContextMenu
                    obj.contributeContextMenu(tool);
                end
            catch exception
                obj.unregister(tool);
                rethrow(exception);
            end
        end

        function unregister(obj, tool)
        %UNREGISTER Remove this exact installation without deleting its owner.
            existing = obj.getInstalled(tool.Name);
            if isempty(existing) || existing ~= tool
                return;
            end
            obj.Host.HotkeyRegistry.removeOwner(tool);
            obj.removeContextMenuContributions(tool);
            obj.removeToolbarButton(tool);
            obj.Tools = rmfield(obj.Tools, char(tool.Name));
            obj.InstalledTools.remove(char(tool.Name));
        end

        function uninstallAll(obj)
        %UNINSTALLALL Release contributions while host graphics still exist.
        %   Only LoadedTools owns objects. InstalledTools also holds borrowed
        %   application objects, which must never be deleted by this manager.
            tools = obj.installedToolValues();
            for k = 1:numel(tools)
                if isvalid(tools{k})
                    try
                        tools{k}.uninstall();
                    catch exception
                        warning('matlabx:ui:ToolUninstallFailed','%s',exception.message);
                    end
                end
            end
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
        %INSTALL Install a loaded built-in name or an application-owned object.
            if isa(name,'matlabx.ui.axes.AxesTool')
                tool = name;
                obj.validateTool(tool);
            else
                mustBeTextScalar(name);
                tool = obj.getLoaded(name);
                if isempty(tool)
                    warning('Failed to install tool. "%s" tool is not loaded.', name)
                    return;
                end
            end
            % AxesTool.install calls register for both ownership cases. Object
            % inputs are deliberately never added to the owning LoadedTools map.
            tool.install();
        end

        function uninstall(obj, name)
        %UNINSTALL Accept an installed name or the exact supplied instance.
            if isa(name,'matlabx.ui.axes.AxesTool')
                if ~isscalar(name)
                    error('matlabx:ui:InvalidTool','Tool must be scalar.');
                end
                if ~isvalid(name)
                    return;
                end
                obj.validateTool(name);
                tool = obj.getInstalled(name.Name);
                if isempty(tool) || tool ~= name
                    return;
                end
            else
                mustBeTextScalar(name);
                tool = obj.getInstalled(name);
            end
            if ~isempty(tool)
                tool.uninstall();
            end
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
                        'Value', tool.Enabled, ...
                        'ValueChangedFcn', @(btn,~) host.onToolToggle(btn.Value, tool.Name));
            end

            % below commented - errors in R2026
            %host.mainAxes.Toolbar.reset;
        end

        function removeToolbarButton(obj, tool)
        %REMOVETOOLBARBUTTON Delete the toolbar button associated with a tool.
            host = obj.Host;

            if ~isfield(host.ToolbarButtons, tool.Name)
                return
            end

            tbButton = host.ToolbarButtons.(tool.Name);

            if isvalid(tbButton)
                delete(tbButton);
            end
            host.ToolbarButtons = rmfield(host.ToolbarButtons, tool.Name);
            % below commented - errors in R2026
            %host.mainAxes.Toolbar.reset;
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
        function validateTool(obj,tool)
        %VALIDATETOOL Keep host identity and installed-name ownership explicit.
            if ~isa(tool,'matlabx.ui.axes.AxesTool') || ~isscalar(tool) || ~isvalid(tool)
                error('matlabx:ui:InvalidTool','Expected a valid scalar AxesTool.');
            end
            if isempty(tool.Host) || ~isvalid(tool.Host) || tool.Host ~= obj.Host
                error('matlabx:ui:ToolHostMismatch', ...
                    'Tool must be constructed for the receiving ImageAxes.');
            end
            if ~isvarname(char(tool.Name))
                error('matlabx:ui:InvalidToolName','Tool Name must be a valid MATLAB identifier.');
            end
            if ~ismember(tool.AxesType,["image","both"])
                error('matlabx:ui:ToolAxesTypeMismatch','Tool must support image axes.');
            end
        end

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
