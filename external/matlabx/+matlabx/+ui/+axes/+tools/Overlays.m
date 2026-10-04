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

classdef Overlays < matlabx.ui.axes.AxesTool
%OVERLAYS Toolbar toggle for ImageAxes.OverlaysVisible.

    properties (Access=private, Transient, NonCopyable)
        StateListener event.listener = event.listener.empty()
    end

    methods
        function obj = Overlays(host)
            obj@matlabx.ui.axes.AxesTool(host, "Overlays", ...
                'Tooltip', 'Show/Hide Overlays', ...
                'AxesType', "image", ...
                'Icon', matlabx.internal.Paths.icons('EyeWhiteFGTransparentBG.svg'));
        end

        function onEnabled(obj)
            obj.Host.OverlaysVisible = 'on';
        end

        function onDisabled(obj)
            if isvalid(obj.Host)
                obj.Host.OverlaysVisible = 'off';
            end
        end

        function onInstall(obj)
            obj.StateListener = addlistener(obj.Host, 'OverlaysVisible', ...
                'PostSet', @(~,~) obj.syncState());
            obj.syncState();
        end

        function onUninstall(obj)
            delete(obj.StateListener(isvalid(obj.StateListener)));
            obj.StateListener = event.listener.empty();
        end
    end

    methods (Access=private)
        function syncState(obj)
        %SYNCSTATE Reflect property/menu changes without triggering another toggle.
            obj.Enabled = logical(obj.Host.OverlaysVisible);
            obj.Host.ToolbarButtons.Overlays.Value = obj.Enabled;
        end
    end
end
