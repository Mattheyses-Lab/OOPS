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

classdef Zoom < matlabx.ui.axes.AxesTool
%ZOOM Zoom/cursor-follow navigation tool for matlabx.ui.axes.ImageAxes.
%
%   When enabled:
%       meta-click           increase zoom
%       meta-contextclick    decrease zoom
%       space                toggle cursor-follow navigation
%       scroll wheel    increase/decrease zoom
%
%   Zoom is intentionally non-exclusive so it can coexist with interaction
%   tools such as Box or DrawRectangle. Its toggle hotkey is contributed to
%   the host hotkey registry when the tool is installed.

    properties
        ScrollEventsPerZoomStep (1,1) double {mustBeInteger, mustBePositive} = 1
        ScrollZoomFactor (1,1) double {mustBeGreaterThan(ScrollZoomFactor,1)} = 1.3
    end

    properties (Access=private)
        ScrollEventCount (1,1) double {mustBeNonnegative, mustBeInteger} = 0
        LastScrollDirection (1,1) double {mustBeMember(LastScrollDirection,[-1,0,1])} = 0
        PreviousViewportBoxVisible (1,1) matlab.lang.OnOffSwitchState = "off"
    end

    %% Lifecycle
    methods

        function obj = Zoom(host)
            obj@matlabx.ui.axes.AxesTool(host,"Zoom", ...
                'Tooltip',          'Zoom/Follow Cursor', ...
                'AxesType',         "both", ...
                'Icon',             matlabx.internal.Paths.icons('ZoomIcon.png'), ...
                'Priority',         1, ...
                'ToggleHotkey',     matlabx.keyboard.hotkey("z", "Modifiers", ["shift","meta"]), ...
                'IsExclusive',      false, ...
                'InterceptsMove',   false, ...
                'InterceptsDown',   true, ...
                'InterceptsScroll', true, ...
                'InterceptsKeyPress',    true);
        end

        function onEnabled(obj)
        %ONENABLED  Enable Zoom when toolbar button is enabled.
            obj.ScrollEventCount = 0;
            obj.LastScrollDirection = 0;

            % The viewport box is ImageAxes-owned state. Zoom temporarily turns it
            % on while active, then restores the user's previous preference when it
            % is disabled.
            obj.PreviousViewportBoxVisible = obj.Host.ViewportBoxVisible;
            obj.Host.ViewportBoxVisible = "on";
            obj.Host.enableZoom();
        end

        function onDisabled(obj)
        %ONDISABLED  Disable Zoom when toolbar button is disabled.
            obj.ScrollEventCount = 0;
            obj.LastScrollDirection = 0;
            if isvalid(obj.Host)
                obj.Host.disableZoom();
                obj.Host.ViewportBoxVisible = obj.PreviousViewportBoxVisible;
            end
        end

        function contributeContextMenu(obj, menu)
        %CONTRIBUTECONTEXTMENU Add Zoom commands to the host context menu.
            menu.addSubmenu( ...
                "Zoom", ...
                "Zoom", ...
                "Owner", obj);

            menu.addSubmenu( ...
                "Zoom.Level", ...
                "Level", ...
                "Parent", "Zoom", ...
                "Owner", obj);

            factors = obj.Host.getZoomFactors();
            for i = 1:numel(factors)
                factor = factors(i);
                menu.addItem( ...
                    "Zoom.Level." + obj.zoomFactorId(factor), ...
                    obj.zoomFactorLabel(factor), ...
                    @(h,~) obj.onZoomLevelMenuSelected(h, factor), ...
                    "Parent", "Zoom.Level", ...
                    "Owner", obj, ...
                    "Checked", matlab.lang.OnOffSwitchState(obj.isCurrentZoomFactor(factor)), ...
                    "UserData", factor, ...
                    "RefreshFcn", @(h) obj.refreshZoomLevelMenuItem(h, factor));
            end

            menu.addItem( ...
                "Zoom.FollowCursor", ...
                "Follow Cursor", ...
                @(h,~) obj.onFollowCursorMenuSelected(h), ...
                "Parent", "Zoom", ...
                "Owner", obj, ...
                "Checked", matlab.lang.OnOffSwitchState(obj.Host.FollowCursorEnabled), ...
                "RefreshFcn", @(h) obj.refreshFollowCursorMenuItem(h));

            menu.addItem( ...
                "Zoom.Help", ...
                "Help...", ...
                @(~,~) obj.Host.openToolHelpWindow(obj), ...
                "Parent", "Zoom", ...
                "Owner", obj, ...
                "Separator", "on");
        end

    end

    %% Help
    methods
        function summary = getHelpSummary(~)
        %GETHELPSUMMARY Return a one-line Zoom description.
            summary = "Zoom and cursor-follow navigation for ImageAxes.";
        end

        function usage = getUsageHelp(~)
        %GETUSAGEHELP Return short Zoom usage notes.
            usage = [ ...
                "Enable Zoom to inspect a smaller viewport of the image."; ...
                "Scroll, modifier-click, or use zoom hotkeys to change magnification around the cursor."; ...
                "Follow Cursor pans the zoomed viewport as the cursor moves across the image."];
        end

        function B = getBindingHelp(obj)
        %GETBINDINGHELP Return Zoom click/key binding descriptions.
            B = struct( ...
                "ToggleTool", obj.ToggleHotkey, ...
                "ZoomInAtCursor", "meta+click, mouse-wheel up, meta+equal", ...
                "ZoomOutAtCursor", "meta+contextclick, mouse-wheel down, meta+hyphen", ...
                "ToggleFollowCursor", "space", ...
                "DisableZoom", "escape");
        end

        function notes = getNotesHelp(~)
        %GETNOTESHELP Return additional Zoom behavior notes.
            notes = [ ...
                "Context-menu level changes and programmatic zoom-factor changes are center-anchored."; ...
                "Click, key, and scroll zoom changes are cursor-anchored when the cursor is over the image."; ...
                "Zoom temporarily shows the ImageAxes viewport box, then restores the prior ViewportBoxVisible setting when disabled."];
        end
    end

    %% Context menu callbacks
    methods (Access=private)
        function onFollowCursorMenuSelected(obj, h)
        %ONFOLLOWCURSORMENUSELECTED Toggle cursor-follow from context menu.
            obj.Host.toggleFollowCursorEnabled();
            obj.refreshFollowCursorMenuItem(h);
        end

        function onZoomLevelMenuSelected(obj, h, factor)
        %ONZOOMLEVELMENUSELECTED Enable zoom and set a supported zoom factor.
            if ~obj.Enabled
                obj.enable();
            end

            obj.Host.setZoomFactor(factor);
            obj.refreshZoomLevelMenuGroup(h.Parent);
        end

        function refreshFollowCursorMenuItem(obj, h)
        %REFRESHFOLLOWCURSORMENUITEM Sync Follow Cursor checked state.
            if isvalid(obj.Host)
                h.Checked = matlab.lang.OnOffSwitchState(obj.Host.FollowCursorEnabled);
            end
        end

        function refreshZoomLevelMenuItem(obj, h, factor)
        %REFRESHZOOMLEVELMENUITEM Sync one zoom-level checked state.
            if isvalid(obj.Host)
                h.Checked = matlab.lang.OnOffSwitchState(obj.isCurrentZoomFactor(factor));
            end
        end

        function refreshZoomLevelMenuGroup(obj, levelMenu)
        %REFRESHZOOMLEVELMENUGROUP Sync checked state for all level items.
            items = levelMenu.Children;
            for i = 1:numel(items)
                factor = items(i).UserData;
                if isnumeric(factor) && isscalar(factor)
                    obj.refreshZoomLevelMenuItem(items(i), factor);
                end
            end
        end

        function tf = isCurrentZoomFactor(obj, factor)
        %ISCURRENTZOOMFACTOR True when factor matches the host zoom factor.
            tf = abs(obj.Host.ZoomFactor - factor) < 1e-10;
        end
    end

    methods (Static, Access=private)
        function label = zoomFactorLabel(factor)
        %ZOOMFACTORLABEL Return a compact display label for a zoom factor.
            if abs(factor - round(factor)) < 1e-10
                label = sprintf('%gx', round(factor));
            else
                label = sprintf('%.3gx', factor);
            end
        end

        function id = zoomFactorId(factor)
        %ZOOMFACTORID Return a stable id suffix for a zoom factor.
            id = "x" + replace(string(sprintf('%.12g', factor)), ".", "p");
        end
    end

    %% Active event hooks (only when Enabled==true && IsInterceptor==true)
    methods

        function onDown(obj, E)

            obj.printStatus(sprintf('%s.onDown()', obj.Name));

            H = obj.Host;
            if isempty(H.cursorPositionStatic)
                return
            end

            switch E.MouseChord
                case "meta+click"
                    H.increaseZoom();
                    E.stop();
                case "meta+contextclick"
                    H.decreaseZoom();
                    E.stop();
            end

        end

        function onScroll(obj, E)
            obj.printStatus(sprintf('%s.onScroll()', obj.Name));

            H = obj.Host;
            if isempty(H.cursorPositionStatic)
                return
            end

            scrollDirection = sign(E.VerticalScrollCount);

            if scrollDirection == 0
                return
            end

            if scrollDirection ~= obj.LastScrollDirection
                obj.ScrollEventCount = 0;
                obj.LastScrollDirection = scrollDirection;
            end

            obj.ScrollEventCount = obj.ScrollEventCount + 1;
            if obj.ScrollEventCount < obj.ScrollEventsPerZoomStep
                return
            end

            obj.ScrollEventCount = 0;

            % Adjust zoom level continuously based on scroll direction.
            if scrollDirection < 0
                H.stepZoomContinuousAtCursor(1, obj.ScrollZoomFactor);
            elseif scrollDirection > 0
                H.stepZoomContinuousAtCursor(-1, obj.ScrollZoomFactor);
            end
        end

        function onKeyPress(obj, E)
            obj.printStatus(sprintf('%s.onKeyPress()', obj.Name));

            switch E.Hotkey
                case "meta+equal"
                    obj.Host.increaseZoom();
                case "meta+hyphen"
                    obj.Host.decreaseZoom();
                case "space"
                    obj.Host.toggleFollowCursorEnabled();
                case "escape"
                    obj.disable();
            end

        end

    end

    %% Host display helpers
    methods

        function pointer = getPreferredPointer(obj)
            if obj.Enabled
                pointer = 'crosshair';
            else
                pointer = '';
            end
        end

        function str = getLabelString(obj)
            % Return char vector with info on zoom level.
            switch obj.Enabled
                case true
                    str = 'Zoom: on';
                case false
                    str = 'Zoom: off';
            end
        end

    end
end
