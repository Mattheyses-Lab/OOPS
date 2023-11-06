function UpdateLabelTree(source)

    % the main data structure
    OOPSData = guidata(source);

    % delete existing label tree nodes
    delete(OOPSData.Handles.LabelTree.Children);
    
    % build new nodes
    for i = 1:numel(OOPSData.Settings.ObjectLabels)
        uitreenode(OOPSData.Handles.LabelTree,...
            'Text',OOPSData.Settings.ObjectLabels(i).Name,...
            'NodeData',OOPSData.Settings.ObjectLabels(i),...
            'ContextMenu',OOPSData.Handles.LabelContextMenu,...
            'Icon',makeRGBColorSquare(OOPSData.Settings.ObjectLabels(i).Color,5));
    end

end