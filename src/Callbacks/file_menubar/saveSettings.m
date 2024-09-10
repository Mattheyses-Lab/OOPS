function saveSettings(source,~)
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

    % the main data structure
    OOPSData = guidata(source);

    % get path settings directory
    if ismac || isunix
        settingsPath = [OOPSData.Settings.MainPath,'/user_settings/'];
    elseif ispc
        settingsPath = [OOPSData.Settings.MainPath,'\user_settings\'];
    end

    % base name of the different settings files (no extension)
    settingsFiles = {...
        'ColormapsSettings',...
        'PalettesSettings',...
        'ScatterPlotSettings',...
        'SwarmPlotSettings',...
        'AzimuthDisplaySettings',...
        'PolarHistogramSettings',...
        'ObjectIntensityProfileSettings',...
        'ObjectAzimuthDisplaySettings',...
        'ObjectSelectionSettings',...
        'ClusterSettings',...
        'MaskSettings',...
        'GUISettings'};

    % update log
    UpdateLog3(source,'Saving settings...','append');

    % save each settings struct to a separate MAT-file
    for i = 1:numel(settingsFiles)
        settingsName = settingsFiles{i};
        tempStruct.(settingsName) = OOPSData.Settings.(settingsName);
        save([settingsPath,settingsName,'.mat'],'-struct','tempStruct');
        clear tempStruct
    end
    
    % update log to indicate completion
    UpdateLog3(source,'Done.','append');

end