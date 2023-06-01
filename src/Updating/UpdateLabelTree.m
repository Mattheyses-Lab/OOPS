function UpdateLabelTree(source)

    OOPSData = guidata(source);

    % delete previous label tree nodes
    delete(OOPSData.Handles.LabelTree.Children);
    
    for i = 1:numel(OOPSData.Settings.ObjectLabels)
        uitreenode(OOPSData.Handles.LabelTree,...
            'Text',OOPSData.Settings.ObjectLabels(i).Name,...
            'NodeData',OOPSData.Settings.ObjectLabels(i),...
            'ContextMenu',OOPSData.Handles.LabelContextMenu,...
            'Icon',makeRGBColorSquare(OOPSData.Settings.ObjectLabels(i).Color,5));
    end

    %% update style configurations

    % testing below
    % % remove any previously added styles
    % removeStyle(OOPSData.Handles.LabelTree);
    % % get the list of child nodes
    % labelTreeNodes = OOPSData.Handles.LabelTree.Children;
    % % add styles for each node
    % for nodeIdx = 1:numel(labelTreeNodes)
    %     % get the next node
    %     thisNode = labelTreeNodes(nodeIdx);
    %     % define its style
    %     thisNodeStyle = uistyle('BackgroundColor',thisNode.NodeData.Color,'FontColor',getBWContrastColor(thisNode.NodeData.Color));
    %     % add the style to the node
    %     addStyle(OOPSData.Handles.LabelTree,thisNodeStyle,"node",labelTreeNodes(nodeIdx));
    % end
    % end testing

end