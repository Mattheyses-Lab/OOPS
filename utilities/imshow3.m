function [hImg,hAx] = imshow3(I)
%%  IMSHOW3 displays image in a uifigure/uiaxes with some custom settings
%
%   NOTES:
%       always opens a new figure by default
%
%       makes the figure window size 750x750, particularly useful for small images
%
%       makes the image fill the window as much as possible while maintaining aspect ratio
%       
%       forces the figure window to remain on top
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

% create the uifigure to hold our image axes
fH = uifigure('Visible','off','HandleVisibility','on','AutoResizeChildren','Off','WindowStyle','alwaysontop');
fH.Position = [50 50 800 800];

% create an axes to hold our image object
hAx = uiaxes(fH,"InnerPosition",[0 0 1 1],...
    "Units","normalized",...
    "Visible","off");

% call imshow to display the image
hImg = imshow(I,'Parent',hAx);

% restore some props potentially screwed up by imshow()
hAx.YDir = 'reverse';
hAx.PlotBoxAspectRatio = [1 1 1];
hAx.InnerPosition = [0 0 1 1];

% show the figure
fH.Visible = 'on';

end