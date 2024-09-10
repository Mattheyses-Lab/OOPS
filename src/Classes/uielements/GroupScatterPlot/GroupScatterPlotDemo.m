function ScatterChart = GroupScatterPlotDemo()
% GROUPSCATTERPLOT  Simple demo to plot some data using GroupScatterPlot
%
%   An instance of this class defines an individual Image
%   belonging to its Parent OOPSGroup.
%
%   See also GroupScatterPlot, ScatterPlot
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

%% load and format some test data

    flowerData = load('fisheriris.mat');

    speciesList = unique(flowerData.species);

    % one scatter per species
    nScatters = numel(speciesList);

    % preallocate data cells
    XData = cell(nScatters,1); % sepal length
    YData = cell(nScatters,1); % sepal width

    % define some data tips categories (1 for X value, 1 for Y value)
    dataTipLabels = {'sepal length','sepal width','species'};

    % preallocate datatip data cell (one cell per scatter)
    dtNames = cell(nScatters,1);
    % preallocate datatip data cell (one cell per scatter)
    dtData = cell(nScatters,1);

    % for each scatter
    for i=1:nScatters

        % collect data

        % get the next species
        thisSpecies = speciesList{i};
        % find the data rows corresponding to this species
        speciesIdx = find(ismember(flowerData.species,thisSpecies));
        % extract the XData (sepal length, column 1) and YData (sepal width, column 2)
        XData{i} = flowerData.meas(speciesIdx,1);
        YData{i} = flowerData.meas(speciesIdx,2);

        % set data tip info

        % add datatip names and values for each dataset (we will have one of these cells per scatter)
        dtNames{i} = dataTipLabels;
        % preallocate cell array of datatip values for each label (we will have one of these cells per scatter)
        dataTipValues = cell(1,numel(dtNames{i}));

        % add the data tip values (we need a separate value for each data point for each of the categories)
        dataTipValues{1,1} = XData{i}; % sepal lengths
        dataTipValues{1,2} = YData{i}; % sepal widths
        dataTipValues{1,3} = flowerData.species(speciesIdx); % species names

        % add the set of datatip values for each label to the cell in dtData for this scatter
        dtData{i} = dataTipValues;
    end

    % horizontally concatenate datatip names and values to create the datatip cell passed into GroupScatterPlot
    dtCell = [dtNames,dtData];    
    

    %% marker face color


    % % use different colors for each set of points
    % MarkerFaceColor = [1 0 0;0 1 0;0 0 1];
    % % CData set to empty
    % CData = {};
    % % CLim set to default
    % CLim = [0 1];


    % % use the Y-value of the points to set the marker face color
    % CData = YData;
    % % set MarkerFaceColor to 'flat' to use CData
    % MarkerFaceColor = {'flat'};
    % % set the CLim to span the data range
    % CLim = [min(cell2mat(YData)) max(cell2mat(YData))];


    % use color order of axes to decide marker colors
    CData = {};
    % set MarkerFaceColor to 'auto' to use axes ColorOrder to set marker face colors
    MarkerFaceColor = {'auto'};
    % CLim can be anything if CData is empty
    CLim = [0 1];


    %% marker edge color

    % single color for all marker edges
    MarkerEdgeColor = [0 0 0];

    % use a similar strategy used for MarkerFaceColor above to adjust marker edge colors

    %% hull face color

    % % multiple colors for hull faces
    % HullFaceColor = [1 0 0;0 1 0;0 0 1];

    % % single color for all hull faces
    % HullFaceColor = [1 1 1];

    % auto colors
    HullFaceColor = [];

    %% hull edge color

    % edge colors matching group colors (when CData is an nScattersx1 cell array of RGB triplets
    %HullEdgeColor = cell2mat(CData);

    % random hull edge colors for each group
    %HullEdgeColor = cell2mat(cellfun(@(x) rand(1,3),cell(nScatters,1),'UniformOutput',false));

    % single color for all hull edges
    HullEdgeColor = [0 0 0];


    %% create the components with the specified properties

    % create a figure to hold the component
    fig = uifigure("HandleVisibility","on",...
        "Name","Group Scatter Plot Demo",...
        "WindowStyle","alwaysontop",...
        "Visible","off");

    ScatterChart = GroupScatterPlot(...
        "Parent",fig,...
        "Title",'Group Scatter Plot Demo',...
        "XData",XData,...
        "YData",YData,...
        "BackgroundColor",[1 1 1],...
        "ForegroundColor",[0 0 0],...
        "FontColor",[0 0 0],...
        "Position",[0 0 1 1],...
        "DataTipCell",dtCell,...
        "XLabel",'Sepal length',...
        "YLabel",'Sepal width',...
        "MarkerEdgeColor",MarkerEdgeColor,...
        "MarkerFaceColor",MarkerFaceColor,...
        "MarkerSize",25,...
        "CData",CData,...
        "CLim",CLim,...
        "HullVisible","on",...
        "HullType","concave",...
        "HullLineWidth",1,...
        "HullFaceColor",HullFaceColor,...
        "HullEdgeColor",HullEdgeColor,...
        "ColorByDensity",false,...
        "LegendVisible",true,...
        "GroupNames",speciesList);

    fig.Visible = "on";

end