classdef Export < matlabx.ui.axes.PlotAxesTool
%EXPORT Push tool for exporting assembled PlotAxes graphics.

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

    methods
        function obj = Export(host)
        %EXPORT Create the plot-export push tool for one PlotAxes host.
            obj@matlabx.ui.axes.PlotAxesTool(host,"Export", ...
                Tooltip='Export plot', ...
                Icon=matlabx.internal.Paths.icons( ...
                    'ExportWhiteFGTransparentBG.svg'), ...
                Style='push');
        end

        function onPush(obj)
        %ONPUSH Ask the host to select and export a graphics file.
            obj.Host.chooseExportPlot();
        end

        function contributeContextMenu(obj,menu)
        %CONTRIBUTECONTEXTMENU Add the plot-export command.
            menu.addItem("Export","Export...",@(~,~) obj.onPush(), ...
                Owner=obj,Separator="on");
        end
    end
end
