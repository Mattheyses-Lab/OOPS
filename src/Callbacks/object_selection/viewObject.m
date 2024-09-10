function viewObject(source,~,clickedObjectIdx)
%%  VIEWOBJECT MenuSelectedFcn callback for context menu attached to patch objects showing object boundaries
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
    % get the handle to the active image in the GUI
    CurrentImage = OOPSData.CurrentImage(1);
    % change the active object
    CurrentImage.CurrentObjectIdx = clickedObjectIdx;
    % update the summary display if the summary type is 'Object'
    UpdateSummaryDisplay(source,{'Object'});
    % update the object selection listbox
    UpdateObjectListBox(source);
    % switch to the 'Objects' view
    feval(OOPSData.Handles.hTabObjects.Callback,OOPSData.Handles.hTabObjects,[]);

end