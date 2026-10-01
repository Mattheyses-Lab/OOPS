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

function bw2svg(BW, opts)
%BW2SVG Convert binary image component outlines to SVG.
%
%   bw2svg(BW, opts)
%
%   INPUTS
%   ------
%   BW  : 2D logical binary image
%
%   OPTIONS (all optional, name-value style)
%   ----------------------------------------
%   Filename            : output SVG filename (default = '')
%   Connectivity        : 4 or 8 (default = 4)
%   TraceStyle          : 'pixelcenter' or 'pixeledge' (default = 'pixelcenter')
%   IncludeImageBounds  : include invisible image boundary path (default = false)
%   StrokeWidth         : stroke width in SVG units (default = 0)
%   StrokeColor         : stroke color string (default = 'black')
%   Fill                : fill color string (default = 'none')
%   Scale               : scale factor applied to coordinates (default = 1)
%
%   NOTES
%   -----
%   Coordinates are exported using pixel-edge origin at (0,0).
%   Subtracts 0.5 from MATLAB row/col indices so that pixel edges
%   align with integer SVG coordinates.

arguments
    BW (:,:) logical
    opts.Filename (1,:) char = ''
    opts.Connectivity (1,1) double {mustBeMember(opts.Connectivity,[4,8])} = 4
    opts.TraceStyle (1,:) char {mustBeMember(opts.TraceStyle,{'pixelcenter','pixeledge'})} = 'pixelcenter'
    opts.IncludeImageBounds (1,1) logical = false
    opts.StrokeWidth (1,1) double {mustBeNonnegative} = 1
    opts.StrokeColor (1,:) char = 'black'
    opts.Fill (1,:) char = 'none'
    opts.Scale (1,1) double {mustBePositive} = 1
end

    fileTxt = {};

    % dimensions
    [H, W] = size(BW);
    S = opts.Scale;

    % boundaries
    B = bwboundaries(BW, opts.Connectivity, 'noholes', ...
                     'TraceStyle', opts.TraceStyle);

    % SVG header
    addLine(sprintf('<?xml version="1.0" encoding="UTF-8"?>\n'));
    addLine(sprintf('<svg xmlns="http://www.w3.org/2000/svg" '));
    addLine(sprintf('width="%g" height="%g" viewBox="0 0 %g %g">\n', ...
                    W*S, H*S, W*S, H*S));

    addLine(sprintf('<g fill="%s" stroke="%s" stroke-width="%g">\n', ...
                    opts.Fill, opts.StrokeColor, opts.StrokeWidth*S));

    % Optional invisible image boundary
    if opts.IncludeImageBounds
        addLine(sprintf('<path d="M 0 0 L %g 0 L %g %g L 0 %g Z" fill="none" stroke="none"/>\n', ...
                        W*S, W*S, H*S, H*S));
    end

    % Write boundaries
    for k = 1:numel(B)

        boundary = B{k};
        if size(boundary,1) < 3
            continue
        end

        % Convert to SVG coords (pixel-edge origin)
        x = (boundary(:,2) - 0.5) * S;
        y = (boundary(:,1) - 0.5) * S;

        % Begin path
        addLine(sprintf('<path d="M %g %g ', x(1), y(1)));

        for i = 2:length(x)
            addLine(sprintf('L %g %g ', x(i), y(i)));
        end

        addLine(sprintf('Z"/>\n'));
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