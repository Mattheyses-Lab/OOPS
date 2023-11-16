function UpdateThresholdSlider(source)
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

% currently selected image(s)
cImage = OOPSData.CurrentImage;

% use the first if multiple selected
if numel(cImage)>1
    cImage = cImage(1);
end

% no image is selected
if isempty(cImage)
    % hide the threshold slider
    set([OOPSData.Handles.ThreshAxH,...
        OOPSData.Handles.ThreshBar,...
        OOPSData.Handles.CurrentThresholdLine],...
        'Visible','off');
    % disable the threshold slider
    OOPSData.Handles.ThreshAxH.HitTest = 'Off';
    % set threshold panel title to indicate no image is selected
    OOPSData.Handles.ImageOperationsPanel.Title = 'No image selected';
    % set the data on our threshold slider axes
    OOPSData.Handles.ThreshBar.BinCounts = zeros(1,256);
    % set thresh line to 0
    OOPSData.Handles.CurrentThresholdLine.Value = 0;
    % don't display a label
    OOPSData.Handles.CurrentThresholdLine.Label = '';
    return
end

% set the panel title
OOPSData.Handles.ImageOperationsPanel.Title = cImage.ThreshPanelTitle;

if cImage.ManualThreshEnabled
    % show the threshold slider
    set([OOPSData.Handles.ThreshAxH,...
        OOPSData.Handles.ThreshBar,...
        OOPSData.Handles.CurrentThresholdLine],...
        'Visible','on');
    % enable the threshold slider
    OOPSData.Handles.ThreshAxH.HitTest = 'On';
    % calculate and display bin counts for the intensity hist plot
    [cImage.IntensityHistPlot,cImage.IntensityBinCenters] = histcounts(cImage.EnhancedImg,OOPSData.Handles.ThreshBar.BinEdges);
    OOPSData.Handles.ThreshBar.BinCounts = cImage.IntensityHistPlot;
    % set line position
    OOPSData.Handles.CurrentThresholdLine.Value = cImage.level;
    % set line label
    OOPSData.Handles.CurrentThresholdLine.Label = {[cImage.ThreshStatisticName,' = ',num2str(OOPSData.Handles.CurrentThresholdLine.Value)]};
else
    % hide the threshold slider
    set([OOPSData.Handles.ThreshAxH,...
        OOPSData.Handles.ThreshBar,...
        OOPSData.Handles.CurrentThresholdLine],...
        'Visible','off');
    % disable the threshold slider
    OOPSData.Handles.ThreshAxH.HitTest = 'Off';
    % set the data on our threshold slider axes
    OOPSData.Handles.ThreshBar.BinCounts = zeros(1,256);
    % set thresh line to 0
    OOPSData.Handles.CurrentThresholdLine.Value = 0;
    % don't display a label
    OOPSData.Handles.CurrentThresholdLine.Label = '';
    return
end

end