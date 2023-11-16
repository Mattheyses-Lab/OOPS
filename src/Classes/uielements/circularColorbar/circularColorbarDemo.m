function circBar = circularColorbarDemo()
%%  CIRCULARCOLORBARDEMO demo function to test the behavior of circularColorbar
%
%   See also CIRCULARCOLORBAR
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

%% set up figure, axes, and example image

% size of the example image
imageSize = 1000;

% get the "Hue" component, which increases CCW relative to the positive x-axis
[H,~,~] = makeHSVComponents(imageSize);

% display the image in a new figure window and store the axes handle
[~,hAx] = imshow3(H);

% set the colormap of the axes
hAx.Colormap = hsv;

% store the figure handle
hFig = hAx.Parent;

% force the figure window to stay on top of other windows
hFig.WindowStyle = 'alwaysontop';

%% calculate center and radius for lower right position

% space left between the circularColorbar and image boundaries
padding = 0.025*imageSize;

% inner and outer radii of the circularColorbar
outerRadius = 0.1*imageSize;
innerRadius = outerRadius/(pi/2);

% position coordinates to the center of the circularColorbar
centerX = imageSize-outerRadius-padding;
centerY = centerX;

%% create the colorbar

% create the circularColorbar in the axes
circBar = circularColorbar(hAx, ...
    'centerX',centerX, ...
    'centerY',centerY, ...
    'Colormap',vertcat(hsv,hsv), ...
    'innerRadius',innerRadius, ...
    'outerRadius',outerRadius, ...
    'nRepeats',1 ...
    );

end