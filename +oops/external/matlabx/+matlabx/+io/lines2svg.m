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

function lines2svg(lines, opts)
%LINES2SVG Convert (x,y) line coordinates to svg
%
%   lines2svg(lines, opts)
%
%   INPUTS
%   ------
%   lines  : cell array of lines, each expressed as Nx2 array of (x,y) coordinates
%
%   OPTIONS (all optional except ViewBoxSize, name-value style)
%   ----------------------------------------
%   ViewBoxSize             : Size of the viewBox (W, H)
%   Filename                : output SVG filename (default = '')
%   IncludeCanvasBoundary   : include invisible viewBox path (default = false)
%   CanvasSize              : Size of the canvas (W, H)
%   StrokeWidth             : stroke width in SVG units (default = 0)
%   StrokeColor             : stroke color string (default = 'black')

arguments
    lines (1,:) cell

    opts.ViewBoxSize (1,2) double 
    opts.CanvasSize (1,2) double = [NaN, NaN]

    opts.Filename (1,:) char = ''

    opts.IncludeCanvasBoundary (1,1) logical = false

    opts.StrokeWidth (1,1) double {mustBeNonnegative} = 1
    opts.StrokeColor (1,:) char = 'black'
end

    fileTxt = {};

    % --- dimensions ---

    % viewBox size
    VB_size = opts.ViewBoxSize;

    % canvas size
    if any(isnan(opts.CanvasSize))
        canvasSize = VB_size;
    else
        canvasSize = opts.CanvasSize;
    end

    W = canvasSize(1);
    H = canvasSize(2);

    % SVG header
    addLine(sprintf('<?xml version="1.0" encoding="UTF-8"?>\n'));
    addLine(sprintf('<svg xmlns="http://www.w3.org/2000/svg" '));
    addLine(sprintf('width="%g" height="%g" viewBox="0 0 %g %g">\n', ...
                    W, H, VB_size(1), VB_size(2)));

    addLine(sprintf('<g fill="none" stroke="%s" stroke-width="%g">\n', ...
        opts.StrokeColor, opts.StrokeWidth));

    % Optional invisible canvas boundary
    if opts.IncludeCanvasBoundary
        addLine(sprintf('<path d="M 0 0 L %g 0 L %g %g L 0 %g Z" fill="none" stroke="none"/>\n', ...
                        W, W, H, H));
    end

    % Write lines
    for k = 1:numel(lines)

        nextLine = lines{k};
        if size(nextLine,1) < 3
            continue
        end

        x = nextLine(:,1);
        y = nextLine(:,2);

        % Begin path
        addLine(sprintf('<path d="M %g %g ', x(1), y(1)));

        for i = 2:length(x)
            addLine(sprintf('L %g %g ', x(i), y(i)));
        end

        addLine(sprintf('"/>\n'));

    end

    addLine(sprintf('</g>\n'));
    addLine(sprintf('</svg>'));

    % write file
    if ~isempty(opts.Filename)
        fid = fopen(opts.Filename, 'w');
        if fid < 0
            error('Could not open output file.');
        end

        for i = 1:numel(fileTxt)
            fprintf(fid, fileTxt{i});
        end

        fclose(fid);
    end

    function addLine(txt)
        fileTxt{end+1} = txt;
    end

end