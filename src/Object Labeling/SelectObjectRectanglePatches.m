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

%% get the location of the clicked point and the object corresponding to it
    % get (x,y) coordinates of most recent cursor position on axes
    CurrentPoint = source.Parent.CurrentPoint(1,1:2);
    % store this handle so we can use it to update after deleting an object box
    hAx = source.Parent;
    % get the main data structure
    OOPSData = guidata(source);
    % get the handle to the active image in the GUI
    CurrentImage = OOPSData.CurrentImage(1);
    % round the (x,y) coordinates of the clicked point
    x = round(CurrentPoint(1));
    y = round(CurrentPoint(2));

    % using the label matrix, find the label closest to the clicked point
    % binary distance transform of the binarized label image, 
    % each element in idx is the linear idx of the closest non-zero pixel
    [~,idx] = bwdist(full(CurrentImage.L)~=0);
    % use the closest idx to the clicked point to find the corresponding object
    ObjIdx = full(CurrentImage.L(idx(y,x)));

%% depending on the type of click, either select/deselect the object, or make it active in the GUI
% we could add more functionality here by including alternate click types (double-click, etc.)
    % if shift-click
    if strcmp(OOPSData.Handles.fH.SelectionType,'extend')
        % change the active object
        CurrentImage.CurrentObjectIdx = ObjIdx;
        % update the summary display if the summary type is 'Object'
        UpdateSummaryDisplay(hAx,{'Object'});
        % update the object selection listbox
        UpdateObjectListBox(hAx);
    else
        % invert the selection status of the object corresponding to the clicked patch
        CurrentImage.Object(ObjIdx).InvertSelection();
        % swap faces between selected and unselected patch objects
        tempFace = OOPSData.Handles.ObjectBoxes.Faces(ObjIdx,:);
        OOPSData.Handles.ObjectBoxes.Faces(ObjIdx,:) = OOPSData.Handles.SelectedObjectBoxes.Faces(ObjIdx,:);
        OOPSData.Handles.SelectedObjectBoxes.Faces(ObjIdx,:) = tempFace;
    end
end