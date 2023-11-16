function UpdateImageTree(source)
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

    OOPSData = guidata(source);

    if OOPSData.nGroups >= 1
        CurrentGroup = OOPSData.CurrentGroup;
    else
        % make sure tree contains no nodes
        delete(OOPSData.Handles.ImageTree.Children);
        UpdateObjectListBox(source);
        return
    end
    
    % if we have at least one replicate
    if CurrentGroup.nReplicates >= 1
        % delete previous nodes
        delete(OOPSData.Handles.ImageTree.Children);
        % make new nodes
        for i = 1:CurrentGroup.nReplicates
            uitreenode(OOPSData.Handles.ImageTree,...
                'Text',CurrentGroup.Replicate(i).rawFPMShortName,...
                'NodeData',CurrentGroup.Replicate(i),...
                'ContextMenu',OOPSData.Handles.ImageContextMenu);
        end
        OOPSData.Handles.ImageTree.SelectedNodes = OOPSData.Handles.ImageTree.Children(CurrentGroup.CurrentImageIndex);
        UpdateObjectListBox(source);
    else
        % make sure tree contains no nodes
        delete(OOPSData.Handles.ImageTree.Children);
        UpdateObjectListBox(source);
    end

end