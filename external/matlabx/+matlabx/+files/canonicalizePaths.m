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

function pathsOut = canonicalizePaths(pathsIn)
%CANONICALIZEPATHS  Convert multiple paths to canonical form
%
%   pathsOut = matlabx.files.canonicalizePaths(pathsIn) converts each
%   supplied file or folder path to its canonical absolute representation.
%
%   Input
%       pathsIn  - Collection of file or folder paths
%
%   Output
%       pathsOut - Canonical paths returned as a string array
%
%   See also matlabx.files.canonicalPath

    pathsOut = string(pathsIn);

    for n = 1:numel(pathsOut)
        if strlength(pathsOut(n)) > 0
            pathsOut(n) = matlabx.files.canonicalPath(pathsOut(n));
        end
    end
end