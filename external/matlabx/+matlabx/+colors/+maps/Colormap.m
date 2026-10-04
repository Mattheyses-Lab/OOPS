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

classdef Colormap < handle
    % Represents a single colormap source with lazy-loaded data.
    %
    % Path is either a MAT-file path or a virtual builtin path of the form
    % "builtin:<name>". Builtin paths are evaluated at runtime by calling the
    % corresponding MATLAB colormap function.
    properties (SetAccess=immutable)
        Name     string
        Category string
        Path     string
    end
    properties (Access=private)
        MapCache double = []
    end

    methods
        function this = Colormap(name, category, path)
            this.Name     = string(name);
            this.Category = string(category);
            this.Path     = string(path);
        end

        function M = getMap(this)
            % Lazy load Nx3 colormap data; cache after first load.
            if ~isempty(this.MapCache)
                M = this.MapCache;
                return
            end

            if startsWith(this.Path, "builtin:")
                name = extractAfter(this.Path, "builtin:");
                M = feval(char(name), 256);
                validateattributes(M, {'double','single'}, {'2d','ncols',3}, mfilename, 'colormap');
                assert(all(isfinite(M(:))), 'Colormap contains NaN/Inf: %s', this.Path);
                this.MapCache = double(M);
                M = this.MapCache;
                return
            end

            mf = matfile(this.Path);
            vars = who(mf);
            M = [];
            if any(strcmp(vars,'Cmap'))
                M = mf.Cmap;
            else
                % fallback: first numeric N-by-3 variable
                for i = 1:numel(vars)
                    tmp = mf.(vars{i});
                    if isnumeric(tmp) && ismatrix(tmp) && size(tmp,2) == 3
                        M = tmp; break
                    end
                end
            end
            validateattributes(M, {'double','single'}, {'2d','ncols',3}, mfilename, 'colormap');
            assert(all(isfinite(M(:))), 'Colormap contains NaN/Inf: %s', this.Path);
            this.MapCache = double(M);
            M = this.MapCache;
        end
    end
end
