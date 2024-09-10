function AdjustCustomDisplayLimits(source,~)
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
    
    % the main data structure
    OOPSData = guidata(source);

    % get the name of the custom statistic corresponding to this slider
    cStatName = source.Tag;
    
    if isempty(OOPSData.CurrentImage)
        source.Value = [0 1];
        return
    else
        cImage = OOPSData.CurrentImage(1);
    end
    
    if ~cImage.FPMStatsDone
        source.Value = cImage.([cStatName,'DisplayRange']);
        return
    end

    % this function will be called whether the user adjusts the slider or if the slider value is changed programatically
    % only disable autoscale behavior if user adjusted the slider
    if source.isSliding
        OOPSData.Handles.ScaleToMaxCustomStat.Value = false;
    end
    
    cImage.([cStatName,'DisplayLimits']) = source.Value;
    
    % get the stat
    cStatIdx = ismember(OOPSData.Settings.CurrentTab,OOPSData.Settings.CustomStatisticDisplayNames);
    
    % if not found
    if ~cStatIdx
        return
    else
        cStat = OOPSData.Settings.CustomStatistics(cStatIdx);
    end
    
    if strcmp(OOPSData.Settings.CurrentTab,cStat.StatisticDisplayName)
        UpdateCustomStatImage(source);
    end
    
    drawnow limitrate

end