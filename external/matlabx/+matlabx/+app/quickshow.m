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
        opts.ComponentColorMode (1,:) char {mustBeMember(opts.ComponentColorMode,{'luts','colors'})} = 'luts'
    end

    validateTools(opts.Tools);

    if ~isfield(opts,'Colormap') || isempty(opts.Colormap)
        opts.Colormap = gray(256);
    end

    if isnan(opts.Size) && isempty(opts.Units)
        opts.Size = 500;
        opts.Units = 'pixels';
    elseif isnan(opts.Size) || isempty(opts.Units)
        error('matlabx:app:quickshow:InvalidSizeOrUnits',...
            'To set figure Size or Units, you must provide both as input arguments');
    end

    % convert size to pixels
    switch opts.Units
        case "inches"
            opts.Size = opts.Size * matlabx.UICal.pixelsPerInch();
        case "points"
            opts.Size = opts.Size * matlabx.UICal.pixelsPerPoint();
    end
    

    fig = uifigure(...
        "WindowStyle",          opts.WindowStyle,...
        "Position",             [0 0 opts.Size opts.Size],...
        "Units",                "pixels",...
        "Visible",              "off",...
        "AutoResizeChildren",   "off",...
        "Name",                 opts.Title);

    if isa(I,"matlabx.image.Image5D")
        ax = matlabx.ui.axes.ImageAxes(fig,...
            "Tools",             opts.Tools,...
            "ImageData",            I,...
            "ComponentColorMode",   opts.ComponentColorMode,...
            "Units",                "normalized",...
            "Position",             [0 0 1 1],...
            "Name",                 opts.Title);
    else
        ax = matlabx.ui.axes.ImageAxes(fig,...
            "Tools",             opts.Tools,...
            "CData",                I,...
            "ComponentColorMode",   opts.ComponentColorMode,...
            "Units",                "normalized",...
            "Position",             [0 0 1 1],...
            "Colormap",             opts.Colormap,...
            "Name",                 opts.Title);
    end

    panelTopChromePx = matlabx.UICal.panelChromeHeight(ax.FontSize,"FontUnits","pixels");
    fig.Position(4) = fig.Position(3) + panelTopChromePx;


    movegui(fig,opts.Location)

    drawnow

    fig.Visible = opts.Visible;

end

function validateTools(toolNames)
%VALIDATETOOLS Check requested ImageAxes tools against available tool classes.
    available = string(matlabx.ui.axes.ImageAxes.getToolNames());
    requested = string(toolNames);
    invalid = requested(~ismember(requested, available));

    if ~isempty(invalid)
        error('matlabx:app:quickshow:InvalidTool', ...
            'Unknown ImageAxes tool(s): %s. Available tools are: %s.', ...
            strjoin(invalid, ', '), strjoin(available, ', '));
    end
end
