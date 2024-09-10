function CopyScatterPlotVector(source,~)
%%  COPYSCATTERPLOTVECTOR Context menu callback to copy the ScatterPlot to the clipboard as a vector graphic
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
    % update log to indicate plot is being copied
    UpdateLog3(source,'Copying...','append');
    % copy the SwarmPlot vector graphic to the clipboard
    OOPSData.Handles.GroupScatterPlot.copyplot();
    % update log to indicate completion
    UpdateLog3(source,'Scatter plot vector graphic copied to clipboard','append');

end