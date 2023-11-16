function ScreenSize = GetMaximizedScreenSize()
%% GetMaximizedScreenSize  Determine the currently drawable screen size.
%
%   Necessary workaround because the value given by get(0,'MonitorPositions') does not account for launcher bars
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

% create a temporary figure set to fill the entire usable screen
% keep invisible so it doesn't flash
TempFig = uifigure('Visible','Off','Units','Normalized','Position',[0 0 1 1]);
TempFig.WindowState = 'Maximized';

% change units to pixels
TempFig.Units = 'Pixels';
% ScreenSize comes from Postition property of temporary figure window
ScreenSize = TempFig.Position;
% close the figure
close(TempFig)
end