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

function [ax,fig] = quickshow(I,opts)
%QUICKSHOW  Shortcut for matlabx.app.quickshow
%
%   See also MATLABX.APP.QUICKSHOW

    arguments
        I
        opts.Colormap (256,3) double
        opts.Title (1,:) char = 'Viewer'
        opts.Tools (1,:) cell = matlabx.ui.axes.ImageAxes.getDefaultTools()
        opts.WindowStyle (1,:) char {mustBeMember(opts.WindowStyle,{'normal','alwaysontop'})} = 'alwaysontop'
        opts.Visible (1,1) matlab.lang.OnOffSwitchState = "on"
        opts.Size (1,1) double = 500
        opts.Units (1,:) char = 'pixels'
        opts.Location (1,:) char {mustBeMember(opts.Location,...
            {'center','north','south','east','west','northeast','northwest','southeast','southwest'})} = 'center'
    end

    keyValueCell = matlabx.struct.toKeyValueCell(opts);
    [ax,fig] = matlabx.app.quickshow(I,keyValueCell{:});

end
