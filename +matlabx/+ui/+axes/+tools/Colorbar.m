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

classdef Colorbar < matlabx.ui.axes.AxesTool
% matlabx.ui.axes.tools.Colorbar
% when Enabled: 
%   Colorbar is Visible

    methods

        function obj = Colorbar(host)
            obj@matlabx.ui.axes.AxesTool(host, "Colorbar", ...
                'Tooltip','Show/Hide Colorbar', ...
                'AxesType',"image", ...
                'Icon',matlabx.internal.Paths.icons('ColorbarIcon.png'), ...
                'Priority',1);
        end

        % Toggled Enabled=true via toolbar button
        function onEnabled(obj)
            obj.Host.ColorbarVisible = 'on';
        end

        % Toggled Enabled=false via toolbar button
        function onDisabled(obj)
            if isvalid(obj.Host)
                obj.Host.ColorbarVisible = 'off';
            end
        end

        % Called AFTER installed from Host, use for any extra required startup actions
        function onInstall(obj)
            obj.Host.ToolbarButtons.Colorbar.Value = obj.Host.ColorbarVisible;
            obj.Enabled = obj.Host.ColorbarVisible;
        end

        % Called AFTER uninstalled from Host, use for any extra required cleanup actions
        function onUninstall(~), end

    end

    %% Teardown
    methods (Access = protected)

        % % called at the beginning of superclass delete()
        % function teardown(obj)
        %     % here is where you can perform any cleanup before object deletion
        % end

    end

end
