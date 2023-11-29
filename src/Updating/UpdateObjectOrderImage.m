function UpdateObjectOrderImage(source)
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

% main data structure
OOPSData = guidata(source);
% current image(s) selection
cImage = OOPSData.CurrentImage;

% if the current selection includes at least one image
if ~isempty(cImage)
    % update the display according to the first image in the list
    cImage = cImage(1);
    EmptyImage = sparse(zeros(cImage.Height,cImage.Width));
else
    EmptyImage = sparse(zeros(1024,1024));
end

% show or hide the Order colorbar
OOPSData.Handles.ObjectOrderCbar.Visible = OOPSData.Handles.ShowColorbarObjectOrder.Value;

try
    % get the user-defined display limits
    orderDisplayLimits = cImage.OrderDisplayLimits;
    % set the image CData
    OOPSData.Handles.ObjectOrderImgH.CData = cImage.CurrentObject.UserScaledOrderSubImage;
    % set the colorbar tick labels
    OOPSData.Handles.ObjectOrderCbar.TickLabels = round(linspace(orderDisplayLimits(1),orderDisplayLimits(2),11),2);
catch
    disp('Warning: Error displaying object Order image...')
    % set placeholders
    OOPSData.Handles.ObjectOrderImgH.CData = EmptyImage;
    OOPSData.Handles.ObjectOrderAxH.XLim = [0.5 size(EmptyImage,2)+0.5];
    OOPSData.Handles.ObjectOrderAxH.YLim = [0.5 size(EmptyImage,1)+0.5];
    OOPSData.Handles.ObjectOrderCbar.TickLabels = 0:0.1:1;
end

end