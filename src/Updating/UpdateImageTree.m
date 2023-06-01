function UpdateImageTree(source)

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