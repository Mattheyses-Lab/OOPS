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

function jarFiles = findJarsContaining(paths,entryName)
%FINDJARSCONTAINING  Find JAR files containing a specified entry
%
%   jarFiles = matlabx.java.findJarsContaining(paths,entryName) searches
%   the supplied paths and returns JAR files containing the requested
%   archive entry.
%
%   Inputs
%       paths     - Collection of candidate file paths
%       entryName - Name of the JAR entry to locate
%
%   Output
%       jarFiles  - Matching JAR paths returned as a string array
%
%   See also matlabx.java.jarContainsEntry

    arguments
        paths
        entryName {mustBeTextScalar}
    end

    paths = string(paths);
    paths = paths(:);

    isJar = isfile(paths) & endsWith(paths,".jar",IgnoreCase=true);
    paths = paths(isJar);

    containsEntry = false(size(paths));

    for n = 1:numel(paths)
        containsEntry(n) = matlabx.java.jarContainsEntry( ...
            paths(n),entryName);
    end

    jarFiles = paths(containsEntry);
    jarFiles = matlabx.files.canonicalizePaths(jarFiles);
end