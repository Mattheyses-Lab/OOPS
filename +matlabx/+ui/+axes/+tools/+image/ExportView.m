classdef ExportView < matlabx.ui.axes.ImageAxesTool
%EXPORTVIEW Push tool for exporting the current ImageAxes view.
%
%   ExportView delegates file selection and rendering to its ImageAxes host.
%   The tool owns no export state or dialogs.

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
        function obj = ExportView(host)
        %EXPORTVIEW Create the export push tool for one ImageAxes host.
            obj@matlabx.ui.axes.ImageAxesTool(host,"ExportView", ...
                'Tooltip','Export current view', ...
                'Icon',matlabx.internal.Paths.icons('ExportWhiteFGTransparentBG.svg'), ...
                'Style','push', ...
                'Priority',1);
        end

        function onPush(obj)
        %ONPUSH Ask the host to choose and export an output file.
            obj.Host.chooseExportView();
        end

        function contributeContextMenu(obj,menu)
        %CONTRIBUTECONTEXTMENU Add the export command to the host menu.
            menu.addItem( ...
                "ExportView", ...
                "Export View...", ...
                @(~,~) obj.onPush(), ...
                "Owner",obj, ...
                "Separator","on");
        end
    end
end
