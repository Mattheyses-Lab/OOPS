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

classdef DisplayLimits < matlabx.ui.axes.AxesTool
%DISPLAYLIMITS Open the ImageAxes display-limits adjustment window.
%
%   DisplayLimits is a push-style toolbar tool. It does not own the slider
%   dialog or display-limit state; it simply asks its ImageAxes host to open
%   the host-owned display-limits window.

    methods
        function obj = DisplayLimits(host)
        %DISPLAYLIMITS Create the DisplayLimits tool for one ImageAxes host.
            obj@matlabx.ui.axes.AxesTool(host, "DisplayLimits", ...
                'Tooltip', 'Adjust display limits', ...
                'AxesType', "image", ...
                'Icon', matlabx.internal.Paths.icons('Slider.png'), ...
                'Style', 'push', ...
                'Priority', 1);
        end

        function onPush(obj)
        %ONPUSH Ask the host to open its display-limits adjustment window.
            obj.Host.openDisplayLimitsWindow();
        end
    end
end
