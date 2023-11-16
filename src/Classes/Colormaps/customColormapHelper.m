function ColormapsObjects = customColormapHelper(Colormaps)
% Colormaps is a struct where each fieldname is the name of a colormap, each variable is a 256x3 array of RGB values
% for each colormap, this function will output a struct where each variable is a customColormap object with the same name
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

ColormapsObjects = struct();

colormapNames = fieldnames(Colormaps);

for i = 1:numel(colormapNames)
    name = colormapNames{i};
    map = Colormaps.(name);
    newCustomColormap = customColormap("Map",map,"Name",name);
    ColormapsObjects.(name) = newCustomColormap;
end


end