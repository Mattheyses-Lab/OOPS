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

classdef AxesTool < handle
%AXESTOOL Base class for tools hosted by matlabx.ui.axes.ImageAxes.
%
%   AxesTool subclasses can add toolbar actions, interactive modes,
%   overlays, and host-event listeners to an ImageAxes instance.
%
%   Tool styles
%   -----------
%   push
%       Toolbar clicks call onPush().
%
%   state
%       Toolbar clicks toggle Enabled and call onEnabled()/onDisabled().
%
%   Figure-event routing
%   --------------------
%   ImageAxes receives normalized figure-level HubEvent objects from
%   matlabx.ui.interaction.FigureEventHub. Installed tools can participate in
%   routing in two ways:
%
%   Interceptor
%       An Enabled tool with InterceptsDown/Move/Up/Scroll/KeyPress/KeyRelease=true for an
%       event kind. The Host routes the event to the highest-priority
%       matching interceptor by calling onDown(), onMove(), etc.
%
%   PassiveInterceptor
%       An Installed tool with PassivelyInterceptsDown/Move/Up/Scroll/KeyPress/KeyRelease=true
%       for an event kind. The Host routes the event to every matching passive
%       interceptor, in priority order, before the active interceptor by calling
%       onPassiveDown(), onPassiveMove(), etc. Passive interceptors are useful
%       for persistent overlays or event observation that must continue even
%       while the tool is disabled. Simple tool toggle shortcuts should use
%       ToggleHotkey, which the Host registers when the tool is installed.
%
%   A tool can call E.stop() to prevent the active interceptor and downstream
%   Host behavior from receiving the event.
%
%   Tool hotkeys
%   ------------
%   ToggleHotkey declares the keypress that toggles or runs a tool while it is
%   installed. Prefer matlabx.keyboard.hotkey(...) for declarations:
%
%       ToggleHotkey = matlabx.keyboard.hotkey("z", "Modifiers", ["shift","meta"])
%
%   Tool help
%   ---------
%   getHelpInfo() returns a small struct used by host UI such as context-menu
%   Help commands. Subclasses can override getHelpSummary(), getUsageHelp(),
%   getBindingHelp(), and getNotesHelp() to document their interactive behavior
%   without requiring a fully declarative binding system.
%
%   Host notifications
%   ------------------
%   Host notifications are opt-in. For example, pass
%   ListenToRenderSourceChanged=true and override onHostRenderSourceChanged()
%   to react when the selected source plane/composite changes.
%
%   Tools may also override onHostEnter(E) and onHostLeave(E) to clean up
%   transient interaction state when the pointer crosses the host ImageAxes
%   boundary. These hooks are distinct from FigureEventHub onEnter/onLeave:
%   they mean "entered/left my host", not "this tool claimed hover."


    properties (SetAccess=protected)
        Host                                                    % axes.ImageAxes
        Name (1,1) string = ""                                  % name of the tool
        AxesType (1,1) string {mustBeMember(AxesType, ["image", "plot", "both"])} = "both"
        Tooltip (1,:) = ''                                      % tooltip for toolbar buttons
        Icon (1,:) char = matlabx.internal.Paths.icons('QuestionMark.png')   % icon for toolbar buttons, question mark by default
        ToggleHotkey (1,1) string = ""

        Style (1,:) char {mustBeMember(Style,{'push','state'})} = 'state'

        Priority (1,1) double = 1               % priority for event routing to tools, highest priority claims event
        IsExclusive (1,1) logical = false       % enabling tool will disable tools with Enabled=true && IsExclusive=true

        InterceptsDown (1,1) logical = false      % this tool actively receives 'Down' events when Enabled=true
        InterceptsMove (1,1) logical = false      % this tool actively receives 'Move' events when Enabled=true
        InterceptsUp (1,1) logical = false        % this tool actively receives 'Up' events when Enabled=true
        InterceptsScroll (1,1) logical = false    % this tool actively receives 'Scroll' events when Enabled=true
        InterceptsKeyPress (1,1) logical = false       % this tool actively receives 'KeyPress' events when Enabled=true
        InterceptsKeyRelease (1,1) logical = false     % this tool actively receives 'KeyRelease' events when Enabled=true

        PassivelyInterceptsDown (1,1) logical = false     % this tool passively receives 'Down' events
        PassivelyInterceptsMove (1,1) logical = false     % this tool passively receives 'Move' events
        PassivelyInterceptsUp (1,1) logical = false       % this tool passively receives 'Up' events
        PassivelyInterceptsScroll (1,1) logical = false   % this tool passively receives 'Scroll' events
        PassivelyInterceptsKeyPress (1,1) logical = false      % this tool passively receives 'KeyPress' events
        PassivelyInterceptsKeyRelease (1,1) logical = false    % this tool passively receives 'KeyRelease' events

        ListenToRenderSourceChanged (1,1) logical = false % listen to Host RenderSourceChanged events

        L event.listener                        % listens to host events
    end

    properties (Dependent)
        IsInterceptor (1,1) logical     % this tool actively receives at least one type of event when Enabled=true
        IsPassiveInterceptor (1,1) logical      % this tool passively receives at least one type of event
    end

    properties (SetAccess=protected)
        Enabled (1,1) logical = false       % true/false (set by toggling toolbar buttons)
        Installed (1,1) logical = false     % true/false (whether the tool is installed in the Host)
        Mode struct = struct()              % tool-owned logical states for subclasses
    end

    % special properties for development/debugging purposes
    properties (Access=protected)
        PrintStatusUpdates (1,1) logical = false
    end

    methods
        function obj = AxesTool(host, name, varargin)
            obj.Host = host;
            obj.Name = string(name);

            % print status update
            obj.printStatus(sprintf('Loading "%s" tool...', obj.Name));

            p = inputParser;
            p.addParameter('Tooltip', '', @(x)ischar(x));
            p.addParameter('AxesType', "both", @(x)(isstring(x)&&isscalar(x)) || ischar(x));
            p.addParameter('Icon', 'QuestionMark.png', @(x)ischar(x));
            p.addParameter('ToggleHotkey', "", @(x)isstring(x)&&isscalar(x));
            p.addParameter('Style', 'state', @(x)ischar(x));
            p.addParameter('Priority', 1, @(x)isnumeric(x)&&isscalar(x));
            p.addParameter('IsExclusive', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('InterceptsDown', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('InterceptsMove', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('InterceptsUp', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('InterceptsScroll', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('InterceptsKeyPress', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('InterceptsKeyRelease', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('PassivelyInterceptsDown', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('PassivelyInterceptsMove', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('PassivelyInterceptsUp', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('PassivelyInterceptsScroll', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('PassivelyInterceptsKeyPress', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('PassivelyInterceptsKeyRelease', false, @(x)islogical(x)&&isscalar(x));
            p.addParameter('ListenToRenderSourceChanged', false, @(x)islogical(x)&&isscalar(x));

            p.parse(varargin{:});

            obj.Tooltip = p.Results.Tooltip;
            obj.AxesType = p.Results.AxesType;
            obj.Icon = p.Results.Icon;
            obj.ToggleHotkey = p.Results.ToggleHotkey;
            obj.Style = p.Results.Style;
            obj.Priority = p.Results.Priority;
            obj.IsExclusive = p.Results.IsExclusive;
            obj.InterceptsDown = p.Results.InterceptsDown;
            obj.InterceptsMove = p.Results.InterceptsMove;
            obj.InterceptsUp = p.Results.InterceptsUp;
            obj.InterceptsScroll = p.Results.InterceptsScroll;
            obj.InterceptsKeyPress = p.Results.InterceptsKeyPress;
            obj.InterceptsKeyRelease = p.Results.InterceptsKeyRelease;
            obj.PassivelyInterceptsDown = p.Results.PassivelyInterceptsDown;
            obj.PassivelyInterceptsMove = p.Results.PassivelyInterceptsMove;
            obj.PassivelyInterceptsUp = p.Results.PassivelyInterceptsUp;
            obj.PassivelyInterceptsScroll = p.Results.PassivelyInterceptsScroll;
            obj.PassivelyInterceptsKeyPress = p.Results.PassivelyInterceptsKeyPress;
            obj.PassivelyInterceptsKeyRelease = p.Results.PassivelyInterceptsKeyRelease;
            obj.ListenToRenderSourceChanged = p.Results.ListenToRenderSourceChanged;

            obj.configureHostEventListeners();

            obj.printStatus(sprintf('"%s" tool loaded', obj.Name));
        end

        % Lifecycle toggles (host calls these)
        function push(obj) % "push" tools only
            % forward to subclass hook
            obj.onPush();
        end

        function enable(obj) % "state" tools only
            % if already enabled, exit
            if obj.Enabled, return; end
            % if tool is exclusive
            if obj.IsExclusive
                % disable active exclusive tool
                obj.Host.disableActiveExclusive;
                % set this tool as the active exclusive tool
                obj.Host.ActiveExclusiveTool = obj;
            end
            % set Enabled status
            obj.Enabled = true;
            % ensure that toolbar button (if valid) reflects Enabled status correctly
            if isvalid(obj.Host.ToolbarButtons.(obj.Name))
                obj.Host.ToolbarButtons.(obj.Name).Value = obj.Enabled;
            end
            % forward to subclass hook
            obj.onEnabled();
        end

        function disable(obj) % "state" tools only
            % if already disabled, exit
            if ~obj.Enabled, return; end
            % if tool is exclusive
            if obj.IsExclusive
                % set the active exclusive tool to empty
                obj.Host.ActiveExclusiveTool = [];
            end
            % set Enabled status
            obj.Enabled = false;
            % ensure that toolbar button (if valid) reflects Enabled status correctly
            if isvalid(obj.Host.ToolbarButtons.(obj.Name))
                obj.Host.ToolbarButtons.(obj.Name).Value = obj.Enabled;
            end
            % forward to subclass hook
            obj.onDisabled();
        end

        function install(obj)
            % indicate status in command window
            obj.printStatus(sprintf('Installing "%s" tool...', obj.Name));

            % register with the Host
            obj.Host.registerTool(obj);

            % set Installed status
            obj.Installed = true;
            % forward to subclass hook
            obj.onInstall();

            % indicate status in command window
            obj.printStatus(sprintf('"%s" tool installed', obj.Name));
        end


        function uninstall(obj)
            % indicate status in command window
            obj.printStatus(sprintf('Uninstalling "%s" tool...', obj.Name));

            % make sure tool is disabled before uninstalling
            obj.disable();
            % remove self from Host registry
            obj.Host.unregisterTool(obj);

            % set Installed status
            obj.Installed = false;
            % forward to subclass hook
            obj.onUninstall();

            % indicate status in command window
            obj.printStatus(sprintf('"%s" tool uninstalled', obj.Name));
        end

        % Hooks for subclasses (no-ops by default)
        function onPush(~),       end
        function onEnabled(~),    end
        function onDisabled(~),   end
        function onInstall(~),    end
        function onUninstall(~),  end
        function onDelete(~),     end

        % Pointer routing (only active Interceptors get these)
        function onDown(~,~,~),     end
        function onMove(~,~,~),     end
        function onUp(~,~,~),       end
        function onScroll(~,~,~),   end
        function onKeyPress(~,~,~),      end
        function onKeyRelease(~,~,~),    end

        % Pointer routing (only PassiveInterceptors get these)
        function onPassiveDown(~,~,~),   end
        function onPassiveMove(~,~,~),   end
        function onPassiveUp(~,~,~),     end
        function onPassiveScroll(~,~,~), end
        function onPassiveKeyPress(~,~,~),    end
        function onPassiveKeyRelease(~,~,~),  end

        % Adjust pointer shape (override in subclass to set pointer - if empty, Host will set)
        function pointer = getPreferredPointer(~), pointer = ''; end

        % Add to info label (override in subclass to include text in image info label)
        function str = getLabelString(~), str = ''; end

        % Optional host notification hooks
        function onHostAxesChanged(~,~),   end   % e.g., XLim/YLim/CLim changed
        function onHostRenderSourceChanged(~,~),  end   % rendered source plane/composite changed
        function onHostEnter(~,~), end
        function onHostLeave(~,~), end

        % Optional context-menu contribution hook
        function contributeContextMenu(~,~), end

        function S = getHelpInfo(obj)
            %GETHELPINFO Return user-facing help information for this tool.
            S = struct( ...
                "Name", obj.Name, ...
                "Class", string(class(obj)), ...
                "Style", string(obj.Style), ...
                "Summary", obj.getHelpSummary(), ...
                "Usage", obj.getUsageHelp(), ...
                "Bindings", obj.getBindingHelp(), ...
                "Notes", obj.getNotesHelp());
        end

        function summary = getHelpSummary(obj)
            %GETHELPSUMMARY Return a one-line description for getHelpInfo.
            summary = string(obj.Tooltip);
        end

        function usage = getUsageHelp(~)
            %GETUSAGEHELP Return short usage notes for getHelpInfo.
            usage = strings(1,0);
        end

        function B = getBindingHelp(obj)
            %GETBINDINGHELP Return click/key binding descriptions for getHelpInfo.
            toggleHotkey = obj.ToggleHotkey;
            if strlength(toggleHotkey) == 0
                toggleHotkey = "none";
            end

            B = struct("ToggleTool", toggleHotkey);
        end

        function notes = getNotesHelp(~)
            %GETNOTESHELP Return optional additional notes for getHelpInfo.
            notes = strings(1,0);
        end

    end

    %% derived getters
    methods

        function value = get.IsInterceptor(obj)
            value = obj.InterceptsDown || obj.InterceptsMove || obj.InterceptsUp || ...
                obj.InterceptsScroll || obj.InterceptsKeyPress || obj.InterceptsKeyRelease;
        end

        function value = get.IsPassiveInterceptor(obj)
            value = obj.PassivelyInterceptsDown || obj.PassivelyInterceptsMove || ...
                obj.PassivelyInterceptsUp || obj.PassivelyInterceptsScroll || ...
                obj.PassivelyInterceptsKeyPress || obj.PassivelyInterceptsKeyRelease;
        end

    end


    %% private helper methods

    methods(Access=protected)

        function addMode(obj, modeName)
        %ADDMODE Add a false-valued logical mode owned by this tool.
            modeName = char(modeName);

            if isfield(obj.Mode, modeName)
                warning('Could not add mode. "%s" mode already exists.', modeName)
                return
            end

            obj.Mode.(modeName) = false;
        end

        function setMode(obj, modeName, modeState)
        %SETMODE Set one tool-owned logical mode.
            modeName = char(modeName);

            if ~isfield(obj.Mode, modeName)
                warning('Could not set mode state. "%s" mode does not exist.', modeName)
                return
            end

            obj.Mode.(modeName) = logical(modeState);
        end

        function removeMode(obj, modeName)
        %REMOVEMODE Remove a tool-owned mode.
            modeName = char(modeName);

            if ~isfield(obj.Mode, modeName)
                warning('Could not remove mode. "%s" mode does not exist.', modeName)
                return
            end

            obj.Mode = rmfield(obj.Mode, modeName);
        end

        function tf = isMode(obj, modeName)
        %ISMODE Return true when a named tool-owned mode exists.
            tf = isfield(obj.Mode, char(modeName));
        end

        function configureHostEventListeners(obj)
        %CONFIGUREHOSTEVENTLISTENERS Attach optional host notification listeners.
            obj.L = event.listener.empty;

            if obj.ListenToRenderSourceChanged
                obj.L(end+1) = addlistener( ...
                    obj.Host, ...
                    'RenderSourceChanged', ...
                    @(~,evt) obj.onHostRenderSourceChanged(evt));
            end
        end

        function printStatus(obj,status)
        %PRINTSTATUS Emit a debug log message for this tool.
            matlabx.Log.DEBUG( ...
                strip(string(status)), ...
                "Source", class(obj), ...
                "Tag", obj.Host.Name, ...
                "AlsoPrint", obj.PrintStatusUpdates);
        end

    end


    %% teardown

    methods (Access = {?matlabx.ui.axes.AxesTool, ?matlabx.ui.axes.ImageAxes, ?matlabx.ui.axes.ImageAxesToolManager})

        % subclass delete() will be called before this runs
        function delete(obj)
            obj.printStatus(sprintf('Unloading "%s" tool...', obj.Name));

            % perform tool-specific teardown if needed (i.e. if subclass implements teardown())
            obj.teardown();

            % remove listeners first
            if ~isempty(obj.L), delete(obj.L(isvalid(obj.L))); end
            % replace listener property with empty array of event.listener
            obj.L = event.listener.empty;

            % if tool is installed
            if obj.Installed
                % uninstall before deletion
                obj.uninstall();
            end

            obj.printStatus(sprintf('"%s" tool unloaded', obj.Name));
        end

    end


    methods (Access = protected)

        % teardown hook for subclasses, implement to perform any needed cleanup before tool deletion
        function teardown(~)
        %TEARDOWN Hook for subclasses that need deletion cleanup.
        end

    end





end
