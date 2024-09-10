function SelectObjectRectanglePatches(source,~)
%% SELECTOBJECTRECTANGLEPATCHES ButtonDownFcn callback for ractangle patch objects showing expanded object bounding boxes
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

    % right-click - do nothing because the context menu will open
    if strcmp(OOPSData.Handles.fH.SelectionType,'alt')
        return
    end

    % get the handle to the active image in the GUI
    CurrentImage = OOPSData.CurrentImage(1);
    % get the idx of the object closest to the clicked point
    ObjIdx = CurrentImage.findNearestObject(source.Parent.CurrentPoint(1,1:2));

%% depending on the type of click, either select/deselect the object, or make it active in the GUI

    % if shift-click
    if strcmp(OOPSData.Handles.fH.SelectionType,'extend')
        % change the active object
        CurrentImage.CurrentObjectIdx = ObjIdx;
        % update the summary display if the summary type is 'Object'
        UpdateSummaryDisplay(source,{'Object'});
        % update the object selection listbox
        UpdateObjectListBox(source);
    else
        % invert the selection status of the object corresponding to the clicked patch
        CurrentImage.Object(ObjIdx).InvertSelection();
        % swap faces between selected and unselected patch objects
        tempFace = OOPSData.Handles.ObjectBoxes.Faces(ObjIdx,:);
        OOPSData.Handles.ObjectBoxes.Faces(ObjIdx,:) = OOPSData.Handles.SelectedObjectBoxes.Faces(ObjIdx,:);
        OOPSData.Handles.SelectedObjectBoxes.Faces(ObjIdx,:) = tempFace;
    end

end