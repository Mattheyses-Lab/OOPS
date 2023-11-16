function SelectObjectsInROI(source,ROI)
% currently working for freehand and rectangular ROIs
% should work with any MATLAB ROI object, but untested
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

% get data structure
OOPSData = guidata(source);
% get active image
CurrentImage = OOPSData.CurrentImage(1);
% initialize array of object centroid coordinates
Centroids = zeros(2,CurrentImage.nObjects);
% get x-, and y-coordinates for each centroid
[Centroids(1,:)] = deal([CurrentImage.Object.CentroidX]);
[Centroids(2,:)] = deal([CurrentImage.Object.CentroidY]);
% determine which object centroids are within the ROI
SelectedStatus = inROI(ROI,Centroids(1,:),Centroids(2,:)).';
% invert the selection status of objects in the ROI
CurrentImage.Object(SelectedStatus).InvertSelection();

end