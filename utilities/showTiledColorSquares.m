function showTiledColorSquares(colors)
%%  SHOWTILEDCOLORSQUARES opens a new window and plots a tiled image of the user-specified colors
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

nColors = size(colors,1);

colorSquares = cell(nColors,1);

for i = 1:nColors
    colorSquares{i} = makeRGBColorSquare(colors(i,:),25);
end

tiledColorSquares = imtile(colorSquares,...
    'ThumbnailSize',[25 25],...
    'BorderSize',1,...
    'BackgroundColor',[0 0 0],...
    'GridSize',[NaN NaN]);

imshow2(tiledColorSquares);

end