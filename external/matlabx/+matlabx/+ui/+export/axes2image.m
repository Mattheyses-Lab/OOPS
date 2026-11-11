function axes2image(ax,filename,opts)
%AXES2IMAGE Export the current content of a UIAxes as a raster image.
%
%   matlabx.ui.export.axes2image(AX,FILENAME) exports the current axes view,
%   including graphics children and the current axes limits. Name-value
%   options control the output size, resolution, background, and toolbar.

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

    arguments
        ax                          (1,1) matlab.ui.control.UIAxes
        filename                    (1,1) string {mustBeNonzeroLengthText}
        opts.Units                  (1,1) string = "inches"
        opts.Width                  (1,1) double {mustBePositive} = 7
        opts.Height                 (1,1) double {mustBePositive} = 7
        opts.BackgroundColor        (1,3) double {mustBeBetween(opts.BackgroundColor,0,1)} = [0 0 0]
        opts.PreserveAspectRatio    (1,1) matlab.lang.OnOffSwitchState = "on"
        opts.Resolution             (1,1) double {mustBePositive} = 600
        opts.HideToolbar            (1,1) logical = true
    end

    toolbar = ax.Toolbar;
    if opts.HideToolbar && ~isempty(toolbar) && isvalid(toolbar)
        toolbarVisible = toolbar.Visible;
        toolbarCleanup = onCleanup(@() restoreToolbar_(toolbar,toolbarVisible));
        toolbar.Visible = 'off';
    end

    exportgraphics(ax,filename, ...
        "ContentType","image", ...
        "Units",opts.Units, ...
        "Width",opts.Width, ...
        "Height",opts.Height, ...
        "Colorspace","rgb", ...
        "Padding",0, ...
        "PreserveAspectRatio",char(opts.PreserveAspectRatio), ...
        "BackgroundColor",opts.BackgroundColor, ...
        "Resolution",opts.Resolution);
end

function restoreToolbar_(toolbar,visible)
%RESTORETOOLBAR_ Restore toolbar visibility when the export scope ends.
    if ~isempty(toolbar) && isvalid(toolbar)
        toolbar.Visible = visible;
    end
end
