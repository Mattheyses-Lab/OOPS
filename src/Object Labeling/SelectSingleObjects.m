function SelectSingleObjects(source,~)
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

% get (X,Y) of most recent cursor position on axes
CurrentPoint = source.Parent.CurrentPoint(1,1:2);

% store this handle so we can use it to update after deleting an object box
hAx = source.Parent;

OOPSData = guidata(source);

CurrentImage = OOPSData.CurrentImage(1);

x = round(CurrentPoint(1));
y = round(CurrentPoint(2));

ObjIdx = full(CurrentImage.L(y,x));

if ObjIdx==0
    return
end


if strcmp(OOPSData.Handles.fH.SelectionType,'extend')
    CurrentImage.CurrentObjectIdx = ObjIdx;
    UpdateSummaryDisplay(hAx,{'Object'});
    UpdateObjectListBox(hAx);
else
    CurrentImage.Object(ObjIdx).InvertSelection();
end

UpdateImages(source);

end