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

classdef ExternalAxesTool < matlabx.ui.axes.AxesTool
    properties
        Installs = 0
        Uninstalls = 0
        Enables = 0
        Disables = 0
        Menu = []
        FailInstall = false
        GraphicsAliveAtUninstall = false
    end
    methods
        function obj = ExternalAxesTool(host)
            obj@matlabx.ui.axes.AxesTool(host,"ExternalTool", ...
                'Tooltip','External test tool', ...
                'Icon',matlabx.internal.Paths.icons('QuestionMark.png'), ...
                'ToggleHotkey',"shift+j");
        end
        function contributeContextMenu(obj,menu)
            obj.Menu = menu.addItem("ExternalTool.Action","External action", ...
                @(~,~) obj.enable(),'Owner',obj);
        end
        function onInstall(obj)
            obj.Installs = obj.Installs + 1;
            if obj.FailInstall
                error('test:InstallFailed','Requested install failure');
            end
        end
        function onUninstall(obj)
            obj.Uninstalls = obj.Uninstalls + 1;
            obj.GraphicsAliveAtUninstall = isgraphics(obj.Host.getAxes());
        end
        function onEnabled(obj), obj.Enables = obj.Enables + 1; end
        function onDisabled(obj), obj.Disables = obj.Disables + 1; end
    end
end
