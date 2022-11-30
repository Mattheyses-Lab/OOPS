function UpdateLabelTree(source)

    PODSData = guidata(source);

    % delete previous label tree nodes
    delete(PODSData.Handles.LabelTree.Children);
    
    for i = 1:numel(PODSData.Settings.ObjectLabels)
        uitreenode(PODSData.Handles.LabelTree,...
            'Text',PODSData.Settings.ObjectLabels(i).Name,...
            'NodeData',PODSData.Settings.ObjectLabels(i),...
            'ContextMenu',PODSData.Handles.LabelContextMenu,...
            'Icon',makeRGBColorSquare(PODSData.Settings.ObjectLabels(i).Color,10));
    end

end