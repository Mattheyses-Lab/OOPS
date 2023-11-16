function [demoImagesPath,demoImages]=getDemoImages()
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

    pth = fileparts(which('cameraman.tif'));
    D = dir(pth);
    C = {'.tif';'.jp';'.png';'.bmp'};
    idx = false(size(D));
    for ii = 1:length(C)
        idx = idx | (arrayfun(@(x) any(strfind(x.name,C{ii})),D));
    end
    D = D(idx);
    demoImages = cell(numel(D),1);
    for ii = 1:numel(D)
        demoImages{ii} = D(ii).name;
        fprintf('%s\n',D(ii).name)
    end

    demoImagesPath = pth;
end