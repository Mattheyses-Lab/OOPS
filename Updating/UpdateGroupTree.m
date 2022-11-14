function UpdateGroupTree(source)
    % get the main data structure
    PODSData = guidata(source);
    % if we have at least one replicate
    if PODSData.nGroups >= 1
        % delete previous nodes
        delete(PODSData.Handles.GroupTree.Children);
        % allocate array for new nodes
        PODSData.Handles.GroupNodes = gobjects(PODSData.nGroups,1);
        % build new nodes (one per group)
        for i = 1:PODSData.nGroups
            % get group data
            CurrentGroup = PODSData.Group(i);
            % build the node
            PODSData.Handles.GroupNodes(i) = uitreenode(PODSData.Handles.GroupTree,...
                'Text',CurrentGroup.GroupName,...
                'NodeData',CurrentGroup,...
                'Icon',makeRGBColorSquare(CurrentGroup.Color,10),...
                'ContextMenu',PODSData.Handles.GroupContextMenu);
        end
        % decide which node is selected based on PODSData.CurrentGroup
        PODSData.Handles.GroupTree.SelectedNodes = PODSData.Handles.GroupTree.Children(PODSData.CurrentGroupIndex);
    else
        % make sure tree contains no nodes if we have no groups
        delete(PODSData.Handles.GroupTree.Children);
    end
end