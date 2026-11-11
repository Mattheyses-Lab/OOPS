classdef ExternalPlotAxesTool < matlabx.ui.axes.PlotAxesTool
%EXTERNALPLOTAXESTOOL Application-owned PlotAxes tool used by lifecycle tests.

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

    properties
        Enables (1,1) double = 0
        Disables (1,1) double = 0
        Installs (1,1) double = 0
        Uninstalls (1,1) double = 0
        Menu = []
    end

    methods
        function obj = ExternalPlotAxesTool(host)
        %EXTERNALPLOTAXESTOOL Create the test tool for one PlotAxes host.
            obj@matlabx.ui.axes.PlotAxesTool(host,"ExternalPlotTool", ...
                Tooltip='External plot test tool',Style='state');
        end

        function onEnabled(obj)
        %ONENABLED Count enabled lifecycle calls.
            obj.Enables = obj.Enables + 1;
        end

        function onDisabled(obj)
        %ONDISABLED Count disabled lifecycle calls.
            obj.Disables = obj.Disables + 1;
        end

        function onInstall(obj)
        %ONINSTALL Count installation lifecycle calls.
            obj.Installs = obj.Installs + 1;
        end

        function onUninstall(obj)
        %ONUNINSTALL Count uninstallation lifecycle calls.
            obj.Uninstalls = obj.Uninstalls + 1;
        end

        function contributeContextMenu(obj,menu)
        %CONTRIBUTECONTEXTMENU Add one owner-scoped test command.
            obj.Menu = menu.addItem("ExternalPlotTool", ...
                "External Plot Tool",@(~,~) [],Owner=obj);
        end
    end
end
