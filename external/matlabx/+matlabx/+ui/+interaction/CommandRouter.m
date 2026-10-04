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

classdef CommandRouter < matlab.ui.componentcontainer.ComponentContainer
%COMMANDROUTER  Non-UI FigureEventHub registrant for hotkeys/commands.

    properties
        Enabled (1,1) logical = true
        HotkeyFcnDict dictionary = dictionary(string.empty(1,0), function_handle.empty(1,0))
    end

    properties (Access=private)
        Hub matlabx.ui.interaction.FigureEventHub
        RouterId double = NaN
    end

    methods (Access=protected)

        function setup(obj)
            % Hide -> this component will run in the background
            obj.Visible = 'off';

            % Get ancestor figure
            fig = ancestor(obj, 'Figure');

            % Register with FigureEventHub
            obj.Hub = matlabx.ui.interaction.FigureEventHub.ensure(fig);
            obj.RouterId = obj.Hub.register(obj, ...
                'Priority', 100, ...
                'CaptureDuringDrag', false);
        end

        function update(~)
        end

    end

    methods

        function delete(obj)
            if ~isnan(obj.RouterId) && ~isempty(obj.Hub) && isvalid(obj.Hub)
                obj.Hub.unregister(obj.RouterId);
            end
        end

        % FigureEventHub hook: decide if we claim this event
        function tf = matches(obj, E)
            tf = ...
                obj.Enabled && ...
                E.isKeyPressEvent() && ...
                strlength(E.Key) > 0 && ...
                isKey(obj.HotkeyFcnDict, E.Key);
        end

        % % FigureEventHub hook: handle claimed event
        % function onKeyPress(obj, E)
        %     key = E.Key;
        %     if isKey(obj.HotkeyFcnDict, key)
        %         func = obj.HotkeyFcnDict(key);
        %         func(obj, key);
        %         E.markHandled();
        %     end
        % end

        % FigureEventHub hook: handle claimed event
        function onKeyPress(obj, E)
            key = E.Key;
            if isKey(obj.HotkeyFcnDict, key)
                func = obj.HotkeyFcnDict(key);
                func(obj, key);
                E.markHandled();
            end
        end



        % No-ops so FigureEventHub doesn't error
        function onDown(~, ~),      end
        function onUp(~, ~),        end
        function onMove(~, ~),      end
        function onScroll(~, ~),    end
        function onKeyRelease(~, ~), end
        function onEnter(~, ~),     end
        function onLeave(~, ~),     end

    end

    methods

        function addHotkey(obj, key, fun)
            key = lower(string(key));

            if ~(isscalar(key) && strlength(key) > 0)
                error('Hotkey must be a nonempty string scalar.');
            end

            if ~(isa(fun, 'function_handle') && isscalar(fun))
                error('Hotkey callback must be a scalar function handle.');
            end

            obj.HotkeyFcnDict(key) = fun;
        end

        function removeHotkey(obj, key)
            key = lower(string(key));

            if ~(isscalar(key) && strlength(key) > 0)
                error('Hotkey must be a nonempty string scalar.');
            end

            if isKey(obj.HotkeyFcnDict, key)
                % remove(obj.HotkeyFcnDict, key);
                obj.HotkeyFcnDict = obj.HotkeyFcnDict.remove(key);
            end
        end

    end

end
