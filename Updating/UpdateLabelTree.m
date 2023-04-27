function UpdateLabelTree(source)

    OOPSData = guidata(source);

    % delete previous label tree nodes
    delete(OOPSData.Handles.LabelTree.Children);
    
    for i = 1:numel(OOPSData.Settings.ObjectLabels)
        uitreenode(OOPSData.Handles.LabelTree,...
            'Text',OOPSData.Settings.ObjectLabels(i).Name,...
            'NodeData',OOPSData.Settings.ObjectLabels(i),...
            'ContextMenu',OOPSData.Handles.LabelContextMenu,...
            'Icon',makeRGBColorSquare(OOPSData.Settings.ObjectLabels(i).Color,10));
    end

end