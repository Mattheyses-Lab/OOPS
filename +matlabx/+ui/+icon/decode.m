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

function options = decode(name)
%DECODE Recover rendering options from an encoded icon basename or path.
%   options = matlabx.ui.icon.decode("v1-circle-0072BD-16.svg") returns
%   Shape, Color (eight-bit RGB divided by 255), and Size. No file is read.
%   Directory components are ignored, including Windows separators when
%   decoding a path saved on another platform. Only canonical MATLABX names
%   are accepted; arbitrary SVG filenames/content cannot be decoded.

    arguments
        name (1,1) string {mustBeNonzeroLengthText}
    end

    [~,stem,extension] = fileparts(replace(name,"\","/"));
    basename = stem + extension;
    tokens = regexp(char(basename), ...
        '^v([0-9]+)-([a-z]+)-([0-9A-F]{6})-([1-9][0-9]*)\.svg$', ...
        'tokens','once');
    if isempty(tokens)
        error('matlabx:ui:InvalidIconName','Invalid encoded icon name: %s',basename);
    end
    if ~strcmp(tokens{1},'1')
        error('matlabx:ui:UnsupportedIconVersion','Unsupported icon version: %s',tokens{1});
    end
    if ~strcmp(tokens{2},'circle')
        error('matlabx:ui:UnsupportedIconShape','Unsupported icon shape: %s',tokens{2});
    end
    sizeValue = str2double(tokens{4});
    % Reject overflow and sizes rounded by decimal-to-double conversion.
    % This ensures accepted names can be re-encoded without changing them.
    if ~isfinite(sizeValue) || ~strcmp(sprintf('%.0f',sizeValue),tokens{4})
        error('matlabx:ui:InvalidIconName','Invalid icon size in: %s',basename);
    end
    rgb = hex2dec(reshape(tokens{3},2,3).').'/255;
    options = struct('Shape',string(tokens{2}),'Color',rgb,'Size',sizeValue);
end
