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

function folderNames = getFolderNames(queryPath)
%%GETFOLDERNAMES  Returns cell array of folder names at the specified path

% make sure the queryPath points to a valid directory
if ~isfolder(queryPath)
    folderNames = {};
    return
end
% get the contents of the queryPath
fList = dir(queryPath);
% extract list of non-hidden folder names (those that do not start with '.')
folderNames = {fList([fList.isdir] & ~cellfun(@(x) strcmp('.',x(1)),{fList.name},'UniformOutput',true)).name};

end