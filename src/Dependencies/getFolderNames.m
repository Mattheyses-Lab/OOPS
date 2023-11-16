function folderNames = getFolderNames(queryFolder)
%%  getFolderNames lists folder names in specified directory
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

    % get the contents of the queryFolder
    fList = dir(queryFolder);
    % extract list of non-hidden folder names (those that do not start with '.')
    folderNames = {fList([fList.isdir] & ~cellfun(@(x) strcmp('.',x(1)),{fList.name},'UniformOutput',true)).name};

end