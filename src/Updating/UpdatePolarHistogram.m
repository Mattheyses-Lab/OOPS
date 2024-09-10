function UpdatePolarHistogram(source)
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
        % get the first image in the list in case multiple are selected
        cImage = cImage(1);
        % get the polar data for the current image
        polarData = deg2rad([cImage.Object(:).(OOPSData.Settings.PolarHistogramVariable)]);
        polarData(isnan(polarData)) = [];
        polarData(polarData<0) = polarData(polarData<0)+pi;
        % get the polar data for the current group
        groupPolarData = deg2rad(OOPSData.CurrentGroup.GetAllObjectData(OOPSData.Settings.PolarHistogramVariable));
        groupPolarData(isnan(groupPolarData)) = [];
        groupPolarData(groupPolarData<0) = groupPolarData(groupPolarData<0)+pi;
    else
        polarData = [];
        groupPolarData = [];
    end

    % set properties of image polar histogram
    set(OOPSData.Handles.ImagePolarHistogram,...
        'polarData',[polarData,polarData+pi],...
        'wedgeColors',OOPSData.Settings.AzimuthColormap,...
        'nBins',OOPSData.Settings.PolarHistogramnBins,...
        'CircleColor',OOPSData.Settings.PolarHistogramCircleColor,...
        'CircleBackgroundColor',OOPSData.Settings.PolarHistogramCircleBackgroundColor,...
        'WedgeFaceColor',OOPSData.Settings.PolarHistogramWedgeFaceColor,...
        'WedgeEdgeColorMode',OOPSData.Settings.PolarHistogramWedgeEdgeColorMode,...
        'WedgeLineWidth',OOPSData.Settings.PolarHistogramWedgeLineWidth,...
        'WedgeEdgeColor',OOPSData.Settings.PolarHistogramWedgeEdgeColor,...
        'rGridlinesLineWidth',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
        'thetaGridlinesLineWidth',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
        'rGridlinesColor',OOPSData.Settings.PolarHistogramGridlinesColor,...
        'thetaGridlinesColor',OOPSData.Settings.PolarHistogramGridlinesColor,...
        'thetaLabelsColor',OOPSData.Settings.PolarHistogramLabelsColor,...
        'BackgroundColor',OOPSData.Settings.PolarHistogramBackgroundColor,...
        'Title',['Image - Object ',OOPSData.Settings.expandVariableName(OOPSData.Settings.PolarHistogramVariable)]);

    % set properties of group polar histogram
    set(OOPSData.Handles.GroupPolarHistogram,...
        'polarData',[groupPolarData,groupPolarData+pi],...
        'wedgeColors',OOPSData.Settings.AzimuthColormap,...
        'nBins',OOPSData.Settings.PolarHistogramnBins,...
        'CircleColor',OOPSData.Settings.PolarHistogramCircleColor,...
        'CircleBackgroundColor',OOPSData.Settings.PolarHistogramCircleBackgroundColor,...
        'WedgeFaceColor',OOPSData.Settings.PolarHistogramWedgeFaceColor,...
        'WedgeEdgeColorMode',OOPSData.Settings.PolarHistogramWedgeEdgeColorMode,...
        'WedgeLineWidth',OOPSData.Settings.PolarHistogramWedgeLineWidth,...
        'WedgeEdgeColor',OOPSData.Settings.PolarHistogramWedgeEdgeColor,...
        'rGridlinesLineWidth',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
        'thetaGridlinesLineWidth',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
        'rGridlinesColor',OOPSData.Settings.PolarHistogramGridlinesColor,...
        'thetaGridlinesColor',OOPSData.Settings.PolarHistogramGridlinesColor,...
        'thetaLabelsColor',OOPSData.Settings.PolarHistogramLabelsColor,...
        'BackgroundColor',OOPSData.Settings.PolarHistogramBackgroundColor,...
        'Title',['Group - Object ',OOPSData.Settings.expandVariableName(OOPSData.Settings.PolarHistogramVariable)]);

end