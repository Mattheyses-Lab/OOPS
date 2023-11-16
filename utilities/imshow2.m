function hImg = imshow2(I)
%%  IMSHOW2 displays image in a figure/axes with some custom settings
%
%   NOTES:
%       always opens a new figure by default
%
%       makes the figure window size 600x600, particularly useful for small images
%
%       makes the image fill the window as much as possible while maintaining aspect ratio
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

fH = figure('Visible','off');

hImg = imshow(I);

hAx = hImg.Parent;
hAx.Units = 'normalized';
hAx.InnerPosition = [0 0 1 1];
hAx.Visible = 'off';

fH.Position = [200 200 800 800];

movegui(fH,'center');

fH.Visible = 'on';

end