classdef CopyGraphics < matlabx.ui.axes.PlotAxesTool
%COPYGRAPHICS Push tool for copying PlotAxes content as vector graphics.

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
        function obj = CopyGraphics(host)
        %COPYGRAPHICS Create the vector-copy push tool for one PlotAxes host.
            obj@matlabx.ui.axes.PlotAxesTool(host,"CopyGraphics", ...
                Tooltip='Copy plot as vector graphics', ...
                Icon=matlabx.internal.Paths.icons( ...
                    'CopyWhiteFGTransparentBG.svg'), ...
                Style='push');
        end

        function onPush(obj)
        %ONPUSH Copy the assembled axes content to the system clipboard.
            obj.Host.copyPlot(ContentType="vector");
        end

        function contributeContextMenu(obj,menu)
        %CONTRIBUTECONTEXTMENU Add the vector-copy command.
            menu.addItem("CopyGraphics","Copy", ...
                @(~,~) obj.onPush(),Owner=obj);
        end
    end
end
