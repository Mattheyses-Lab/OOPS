function setupObjectBoxesContextMenus(source,~)
%%  SETUPOBJECTBOXESCONTEXTMENUS ContextMenuOpeningFcn callback to set up children menu callbacks
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

%% get the location of the clicked point and the idx of the object closest to it

    % get the main data structure
    OOPSData = guidata(source);
    % get the last clicked UI component (should be a patch object in an axes)
    clickedObject = gco;
    % get its parent axes
    hAx = ancestor(clickedObject,'axes');
    % get (x,y) coordinates of most recent cursor position on axes
    CurrentPoint = hAx.CurrentPoint(1,1:2);
    % get the handle to the active image in the GUI
    CurrentImage = OOPSData.CurrentImage(1);
    % get the idx of the object closest to the clicked point
    ObjIdx = CurrentImage.findNearestObject(CurrentPoint);

%% set up child uimenu callbacks 

    % make sure to pass the correct axes to the MenuSelectedFcn of each menu option
    OOPSData.Handles.ObjectBoxesContextMenu_View.MenuSelectedFcn = @(o,e) viewObject(o,e,ObjIdx);
    OOPSData.Handles.ObjectBoxesContextMenu_Delete.MenuSelectedFcn = @(o,e) deleteObject(o,e,ObjIdx);

end