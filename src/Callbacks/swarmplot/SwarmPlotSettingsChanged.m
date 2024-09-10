function SwarmPlotSettingsChanged(source,~,doFullUpdate)
%%  SWARMPLOTSETTINGSCHANGED Callbacks for various components controlling appearance of the SwarmPlot
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

    % get the main data structure
    OOPSData = guidata(source);
    % set the value of the property specified by the 'Tag' property of the component invoking the callback
    OOPSData.Settings.SwarmPlotSettings.(source.Tag) = source.Value;

    if doFullUpdate
        % update the whole plot
        UpdateSwarmChart(source);
    else
        % only update the specified property
        OOPSData.Handles.SwarmPlot.(source.Tag) = source.Value; 
    end

end