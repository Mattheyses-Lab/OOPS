function GUIFontSizeChanged(source,~)
%%  GUIFONTSIZECHANGED Callback executed when user changes gui fontsize
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
    % store the FontSize in GUISettings structure
    OOPSData.Settings.GUISettings.FontSize = source.Value;
    % adjust the font size across the board for all non-custom objects
    fontsize(OOPSData.Handles.fH,OOPSData.Settings.GUIFontSize,'pixels');
    % now adjust the font size for the settings accordion
    OOPSData.Handles.SettingAccordion.FontSize = OOPSData.Settings.GUIFontSize;
    % adjust font size for some plots individually, as fontsize() apparently does not catch everything
    OOPSData.Handles.ScatterPlotAxH.FontSize = OOPSData.Settings.GUISettings.FontSize;
    % update the GUI summary display panel
    UpdateSummaryDisplay(source,{'Project'});

end