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

function files = listFiles(location)
%LISTFILES  Lists files at a specified location
%
%   files = LISTFILES(location) returns the names of all files directly
%   contained within location.
%
%   Input
%     location : Path to an existing folder, specified as a string scalar
%                or character vector
%
%   Output
%     files    : Column string array containing file names
%
%   Example
%     files = matlabx.files.listFiles(pwd);

    files = matlabx.files.listContents(location);
end