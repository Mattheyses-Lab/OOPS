function UpdateImageTree(source)

    PODSData = guidata(source);
    CurrentGroup = PODSData.CurrentGroup;
    
    % if we have at least one replicate
    if CurrentGroup.nReplicates >= 1
        Replicate = CurrentGroup.CurrentImage;
        % delete previous nodes
        delete(PODSData.Handles.ImageTree.Children);
        % make new nodes
        for i = 1:CurrentGroup.nReplicates
            uitreenode(PODSData.Handles.ImageTree,...
                'Text',CurrentGroup.Replicate(i).pol_shortname,...
                'NodeData',CurrentGroup.Replicate(i),...
                'ContextMenu',PODSData.Handles.ImageContextMenu);
        end
        PODSData.Handles.ImageTree.SelectedNodes = PODSData.Handles.ImageTree.Children(CurrentGroup.CurrentImageIndex);
        UpdateObjectListBox(source);
    else
        % make sure tree contains no nodes
        delete(PODSData.Handles.ImageTree.Children);
        UpdateObjectListBox(source);
    end


end