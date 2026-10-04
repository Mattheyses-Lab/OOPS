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

function tf = isSamePath(pathA, pathB)
%ISSAMEPATH  Determine whether two paths refer to the same location
%
%   tf = matlabx.files.isSamePath(pathA,pathB) compares canonical forms of
%   the supplied paths using platform-appropriate case sensitivity.
%
%   Either input may be a string array when the other input is scalar.
%
%   Inputs
%       pathA - First file or folder path
%       pathB - Second file or folder path
%
%   Output
%       tf    - Logical comparison result

    pathA = matlabx.files.canonicalizePaths(pathA);
    pathB = matlabx.files.canonicalizePaths(pathB);

    if ispc
        tf = strcmpi(pathA,pathB);
    else
        tf = strcmp(pathA,pathB);
    end
end