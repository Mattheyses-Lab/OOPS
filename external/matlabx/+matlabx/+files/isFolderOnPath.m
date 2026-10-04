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

function tf = isFolderOnPath(folder)
%ISFOLDERONPATH  Determine whether a folder is on the MATLAB search path
%
%   tf = matlabx.files.isFolderOnPath(folder) returns true when the
%   specified folder is present on the MATLAB search path.
%
%   Input
%       folder - Folder path
%
%   Output
%       tf     - True when the folder is on the MATLAB search path

    arguments
        folder {mustBeTextScalar}
    end

    pathFolders = string(strsplit(path,pathsep));
    pathFolders = pathFolders(strlength(pathFolders) > 0);

    tf = any(matlabx.files.isSamePath(pathFolders,folder));
end