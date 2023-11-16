function changeActiveImage(source,~)
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

    % handle to the main data structure
    OOPSData = guidata(source);
    % index of the current group
    CurrentGroupIndex = OOPSData.CurrentGroupIndex;
    % handle(s) to the currently selected image(s)
    SelectedImages = deal([source.SelectedNodes(:).NodeData]);
    % set current image(s) in group based on idx of image(s) selected in the uitree
    OOPSData.Group(CurrentGroupIndex).CurrentImageIndex = [SelectedImages(:).SelfIdx];
    % update display of images, object selector, summary, custom stat images
    UpdateIntensitySliders(source);
    UpdateImages(source,[{'Files','FFC','Mask','Order','Azimuth','Objects','Polar Plots'},OOPSData.Settings.CustomStatisticDisplayNames.']);
    UpdateObjectListBox(source);
    UpdateThresholdSlider(source);
    UpdateSummaryDisplay(source,{'Image','Object'});
end