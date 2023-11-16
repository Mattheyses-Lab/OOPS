function UpdateGroupTree(source)
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
    % if we have at least one replicate
    if OOPSData.nGroups >= 1
        % delete previous nodes
        delete(OOPSData.Handles.GroupTree.Children);
        % allocate array for new nodes
        OOPSData.Handles.GroupNodes = gobjects(OOPSData.nGroups,1);
        % build new nodes (one per group)
        for i = 1:OOPSData.nGroups
            % get group data
            CurrentGroup = OOPSData.Group(i);
            % build the node
            OOPSData.Handles.GroupNodes(i) = uitreenode(OOPSData.Handles.GroupTree,...
                'Text',CurrentGroup.GroupName,...
                'NodeData',CurrentGroup,...
                'ContextMenu',OOPSData.Handles.GroupContextMenu,...
                'Icon',makeRGBColorSquare(CurrentGroup.Color,5));
        end
        % decide which node is selected based on OOPSData.CurrentGroup
        OOPSData.Handles.GroupTree.SelectedNodes = OOPSData.Handles.GroupTree.Children(OOPSData.CurrentGroupIndex);


        %% update style configurations
    
        % testing below
        % % remove any previously added styles
        % removeStyle(OOPSData.Handles.GroupTree);
        % % get the list of child nodes
        % groupTreeNodes = OOPSData.Handles.GroupTree.Children;
        % % add styles for each node
        % for nodeIdx = 1:numel(groupTreeNodes)
        %     % get the next node
        %     thisNode = groupTreeNodes(nodeIdx);
        %     % define its style
        %     thisNodeStyle = uistyle('BackgroundColor',thisNode.NodeData.Color,'FontColor',getBWContrastColor(thisNode.NodeData.Color));
        %     % add the style to the node
        %     addStyle(OOPSData.Handles.GroupTree,thisNodeStyle,"node",groupTreeNodes(nodeIdx));
        % end
        % end testing

    else
        % make sure tree contains no nodes if we have no groups
        delete(OOPSData.Handles.GroupTree.Children);
    end
end