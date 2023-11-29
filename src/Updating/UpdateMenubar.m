function UpdateMenubar(source)
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

% hide or show top level menus based on project status
OOPSData.Handles.hTabMenu.Enable = OOPSData.GUIProjectStarted;
OOPSData.Handles.hProcessMenu.Enable = OOPSData.GUIProjectStarted;
OOPSData.Handles.hSummaryMenu.Enable = OOPSData.GUIProjectStarted;
OOPSData.Handles.hObjectsMenu.Enable = OOPSData.GUIProjectStarted;
OOPSData.Handles.hPlotMenu.Enable = OOPSData.GUIProjectStarted;

% hide or show File menu options based on project status
set(OOPSData.Handles.hFileMenu.Children,'Enable',OOPSData.GUIProjectStarted);

% 'New project' and 'Load project' are always enables
OOPSData.Handles.hNewProject.Enable = 'On';
OOPSData.Handles.hLoadProject.Enable = 'On';

end