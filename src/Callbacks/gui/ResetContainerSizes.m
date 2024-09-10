function ResetContainerSizes(source,~)
%%  RESETCONTAINERSIZES Callback executed when user changes gui window size
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
    % calculate the size of small images
    SmallWidth = round((source.InnerPosition(3)*0.38)/2);
    % update grid size to match new image sizes
    set(OOPSData.Handles.MainGrid,...
        'RowHeight',{'1x',SmallWidth,SmallWidth,'1x'},...
        'ColumnWidth',{'1x',SmallWidth,SmallWidth,SmallWidth,SmallWidth});
    % update the display
    drawnow

end