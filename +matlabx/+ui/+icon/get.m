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

function file = get(varargin)
%GET Return a cached SVG icon with transparent surroundings.
%   file = matlabx.ui.icon.get(Shape="circle",Color=[0 0.4470 0.7410],Size=16)
%   returns a path suitable for a UI component's Icon property. Color is an
%   RGB triplet in [0,1]; Size is the positive integer canvas width/height.
%   The circle occupies 75 percent of the canvas diameter, preserving the
%   original swatch's two-pixel margin at Size=16. There is no border.
%
%   file = matlabx.ui.icon.get(name) resolves an encoded basename or path.
%   Only the basename is used; files are always generated in the local cache.
%   Encoded names cannot be combined with name-value overrides.
%
%   Colors are rounded to eight-bit RGB before rendering and cache lookup.
%   Files live beneath prefdir/matlabx/cache/icons and are disposable: a
%   missing file is recreated on the next call. Store rendering options in
%   application models, rather than persisting generated paths.

    % One positional argument is an encoded name or path. Otherwise forward
    % name-value options to encode, the single source of option validation.
    % Mixing an encoded name with overrides is deliberately unsupported.
    if numel(varargin) == 1
        options = matlabx.ui.icon.decode(varargin{1});
        pairs = namedargs2cell(options);
        name = matlabx.ui.icon.encode(pairs{:});
    else
        name = matlabx.ui.icon.encode(varargin{:});
        options = matlabx.ui.icon.decode(name);
    end
    hex = upper(string(sprintf('%02X%02X%02X',round(255*options.Color))));
    folder = matlabx.internal.Paths.prefRoot('cache','icons');
    file = fullfile(folder,name);
    if isfile(file)
        return;
    end

    if ~isfolder(folder)
        [ok,message] = mkdir(folder);
        if ~ok
            error('matlabx:ui:IconCacheWriteFailed','Could not create icon cache: %s',message);
        end
    end

    % Keep shape construction separate from file/cache handling. Additional
    % shapes can be dispatched here when there are callers for them.
    switch options.Shape
        case "circle"
            body = circleSVG(hex);
    end
    % A fixed viewBox preserves proportions independently of pixel size.
    svg = sprintf(['<svg xmlns="http://www.w3.org/2000/svg" ' ...
        'width="%.0f" height="%.0f" viewBox="0 0 16 16">\n' ...
        '%s\n</svg>\n'],options.Size,options.Size,body);

    % Write beside the destination and publish only after closing the file.
    % An interrupted write must not become a reusable partial cache entry.
    temporary = tempname(folder);
    cleanup = onCleanup(@() removeTemporary(temporary)); %#ok<NASGU>
    writeSVG(temporary,svg);
    [ok,message] = movefile(temporary,file,'f');
    if ~ok
        error('matlabx:ui:IconCacheWriteFailed','Could not publish icon: %s',message);
    end
end

function svg = circleSVG(hex)
%CIRCLESVG One closed filled circle, without a background or stroke.
    svg = sprintf('  <circle cx="8" cy="8" r="6" fill="#%s"/>',hex);
end

function writeSVG(file,svg)
%WRITESVG Close the stream before the caller publishes the cache entry.
    handle = fopen(file,'w');
    if handle < 0
        error('matlabx:ui:IconCacheWriteFailed','Could not create icon: %s',file);
    end
    cleanup = onCleanup(@() fclose(handle)); %#ok<NASGU>
    count = fprintf(handle,'%s',svg);
    [message,number] = ferror(handle);
    if number ~= 0 || count ~= numel(svg)
        error('matlabx:ui:IconCacheWriteFailed','Could not write icon %s: %s',file,message);
    end
end

function removeTemporary(file)
%REMOVETEMPORARY Clean up failed writes; successful moves leave nothing here.
    if isfile(file)
        delete(file);
    end
end
