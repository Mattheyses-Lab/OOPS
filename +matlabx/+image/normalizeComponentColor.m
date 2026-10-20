function [name, rgb] = normalizeComponentColor(value)
%NORMALIZECOMPONENTCOLOR Normalize a component color name or RGB triplet.
%
%   [NAME, RGB] = matlabx.image.normalizeComponentColor(VALUE) returns a
%   canonical component color name and its display RGB value. Gray, grey,
%   grays, greys, grayscale, greyscale, and white all canonicalize to
%   "gray", whose display tint is [1 1 1].

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

    if ischar(value) || isstring(value)
        name = string(value);
        if ~isscalar(name)
            error('matlabx:image:InvalidComponentColor', ...
                'Component color must be a text scalar or 1-by-3 RGB triplet.');
        end

        name = lower(strtrim(name));
        if ismember(name, ["grey","grays","greys","grayscale","greyscale","white"])
            name = "gray";
        end

        names = matlabx.image.componentColorNames();
        if ~ismember(name, names)
            error('matlabx:image:InvalidComponentColor', ...
                'Component color "%s" must be one of: %s.', ...
                char(name), strjoin(cellstr(names), ', '));
        end
    else
        validateattributes(value, {'numeric'}, ...
            {'real','finite','size',[1 3],'>=',0,'<=',1}, mfilename, 'value');
        rgb = double(value);
        if isequal(rgb, [1 1 1])
            name = "gray";
            return
        end
        name = lower(matlabx.colors.names.fromRGB(rgb, "Palette", "MATLAB"));
        names = matlabx.image.componentColorNames();
        if ~ismember(name, names)
            error('matlabx:image:InvalidComponentColor', ...
                'RGB component color must match one of: %s.', ...
                strjoin(cellstr(names), ', '));
        end
        return
    end

    if name == "gray"
        rgb = [1 1 1];
    else
        rgb = matlabx.colors.names.toRGB(name, "Palette", "MATLAB");
    end
end
