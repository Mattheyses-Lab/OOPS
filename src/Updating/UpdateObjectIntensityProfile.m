function UpdateObjectIntensityProfile(source)
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
end

try
    % get handle to the current object
    cObject = cImage.CurrentObject;
    % get padded object mask sub image
    paddedSubImage = cObject.paddedSubImage;
    % get padded subarray idx
    paddedSubarrayIdx = cObject.paddedSubarrayIdx;
catch
    disp('Warning: Error retrieving object data')
end

if any(isvalid(OOPSData.Handles.ObjectIntensityPlotAxH.Children))
    delete(OOPSData.Handles.ObjectIntensityPlotAxH.Children);
end

try
    % initialize pixel-normalized intensity stack for curve fitting
    PaddedObjPixelNormIntensity = zeros([size(paddedSubImage),4]);
    % get pixel-normalized intensity stack for curve fitting
    PaddedObjPixelNormIntensity(:) = cObject.Parent.ffcFPMPixelNorm(paddedSubarrayIdx{:},:);
    % calculate and plot object intensity curve fits
    OOPSData.Handles.ObjectIntensityPlotAxH = PlotObjectIntensityProfile(...
        [0,pi/4,pi/2,3*(pi/4)],...
        PaddedObjPixelNormIntensity,...
        paddedSubImage,...
        OOPSData.Handles.ObjectIntensityPlotAxH,...
        OOPSData.Settings.ObjectIntensityProfileFitLineColor,...
        OOPSData.Settings.ObjectIntensityProfilePixelLinesColor,...
        OOPSData.Settings.ObjectIntensityProfileAnnotationsColor,...
        OOPSData.Settings.ObjectIntensityProfileAzimuthLinesColor);
catch
    disp('Warning: Error displaying object sinusoidal intensity fit curves');
end

% set background color
OOPSData.Handles.ObjectIntensityPlotAxH.Color = OOPSData.Settings.ObjectIntensityProfileBackgroundColor;
OOPSData.Handles.ImgPanel2.BackgroundColor = OOPSData.Settings.ObjectIntensityProfileBackgroundColor;

% set foreground color
OOPSData.Handles.ObjectIntensityPlotAxH.XAxis.Color = OOPSData.Settings.ObjectIntensityProfileForegroundColor;
OOPSData.Handles.ObjectIntensityPlotAxH.YAxis.Color = OOPSData.Settings.ObjectIntensityProfileForegroundColor;


end