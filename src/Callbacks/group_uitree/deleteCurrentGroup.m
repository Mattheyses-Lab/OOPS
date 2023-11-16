function deleteCurrentGroup(source,~,fH)
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

    OOPSData = guidata(source);
    SelectedNode = fH.CurrentObject;
    cGroup = SelectedNode.NodeData;
    UpdateLog3(fH,['Deleting [Group:',cGroup.GroupName,']...'],'append');
    delete(SelectedNode)
    OOPSData.DeleteGroup(cGroup)
    UpdateImageTree(source);
    UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});
    UpdateLog3(fH,'Done.','append');
end