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

function [files,folders] = listContents(location)
%LISTCONTENTS  Lists files and folders at a specified location
%
%   [files,folders] = LISTCONTENTS(location) returns the names of all files
%   and folders directly contained within location. The special directory
%   entries "." and ".." are excluded.
%
%   Input
%     location : Path to an existing folder, specified as a string scalar
%                or character vector
%
%   Outputs
%     files    : Column string array containing file names
%     folders  : Column string array containing folder names
%
%   Example
%     [files,folders] = listContents(pwd);

    arguments
        location (1,1) string {mustBeFolder}
    end

    contents = dir(location);

    names = string({contents.name})';
    isFolder = [contents.isdir]';

    isSpecial = names == "." | names == "..";

    files = names(~isFolder);
    folders = names(isFolder & ~isSpecial);
end