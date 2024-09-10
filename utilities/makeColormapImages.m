function makeColormapImages()
% MAKECOLORMAPIMAGES  Saves an image for each colormap in OOPS/assets/colormaps to OOPS/assets/colormap_images
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

% main path (the path to the directory 'OOPS')
mainPath = OOPSSettings.getMainPath();

% get path separator based on os
if ismac || isunix; pathSep = '/'; elseif ispc; pathSep = '\'; end

% location where colormap images will be saved
saveDirectory = strjoin({mainPath,'assets','colormap_images'},pathSep);

% call OOPSSettings to load colormapsStruct, which is a struct
% in which each field contains a customColormap object made from 
% one of the colormaps in OOPS/assets/colormaps
colormapsStruct = OOPSSettings.reloadColormaps();

% fields of the colormaps struct are the names of each colormap
colormapNames = fieldnames(colormapsStruct);

% save each colormap
for i = 1:numel(colormapNames)
    % name of this colormap
    mapName = colormapNames{i};
    % get the colormap RGB image data
    mapImage = colormapsStruct.(mapName).colormapImage([50,256],'r');
    % write the image data as a PNG
    imwrite(mapImage,[saveDirectory,pathSep,mapName,'.png']);
end

end


