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

function pathOut = canonicalPath(pathIn)
%CANONICALPATH  Return the canonical absolute form of a path
%
%   pathOut = matlabx.files.canonicalPath(pathIn) returns the canonical
%   absolute representation of the specified file or folder path.
%
%   Symbolic links, relative path components, and redundant separators are
%   resolved where supported by the operating system.
%
%   Input
%       pathIn  - File or folder path, specified as a string scalar or
%                 character vector
%
%   Output
%       pathOut - Canonical absolute path, returned as a string scalar

    arguments
        pathIn {mustBeTextScalar}
    end

    file = java.io.File(char(pathIn));
    pathOut = string(file.getCanonicalPath());
end