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

function names = list()
%LIST  Lists the available matlabx shortcut functions.
%
%   names = matlabx.shortcuts.list() returns the names of all MATLAB
%   function files in the matlabx shortcuts directory.
%
%   Output
%     names : Column string array containing shortcut function names
%
%   Example
%     names = matlabx.shortcuts.list();

    files = matlabx.files.listFiles(matlabx.internal.Paths.shortcuts());

    isFunction = endsWith(files,".m",IgnoreCase=true);
    names = erase(files(isFunction),".m");

    names = sort(names);
end