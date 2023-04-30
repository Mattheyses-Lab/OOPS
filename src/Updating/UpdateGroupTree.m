function UpdateGroupTree(source)
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
                'Icon',makeRGBColorSquare(CurrentGroup.Color,10),...
                'ContextMenu',OOPSData.Handles.GroupContextMenu);
        end
        % decide which node is selected based on OOPSData.CurrentGroup
        OOPSData.Handles.GroupTree.SelectedNodes = OOPSData.Handles.GroupTree.Children(OOPSData.CurrentGroupIndex);
    else
        % make sure tree contains no nodes if we have no groups
        delete(OOPSData.Handles.GroupTree.Children);
    end
end