function changeActiveGroup(source,~)
    OOPSData = guidata(source);
    OOPSData.CurrentGroupIndex = source.SelectedNodes(1).NodeData.SelfIdx;
    % update display of image tree, images, and summary
    UpdateImageTree(source);
    UpdateImages(source);
    UpdateThresholdSlider(source);
    UpdateIntensitySliders(source);
    UpdateSummaryDisplay(source,{'Group','Image','Object'});
end