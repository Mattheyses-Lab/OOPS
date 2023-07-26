function editGroupColor(source,~,fH)
    OOPSData = guidata(source);
    SelectedNode = fH.CurrentObject;
    cGroup = SelectedNode.NodeData;
    cGroup.Color = uisetcolor();
    figure(fH);
    SelectedNode.Icon = makeRGBColorSquare(cGroup.Color,1);
    if strcmp(OOPSData.Settings.CurrentTab,'Plots')
        UpdateImages(source);
    end
end