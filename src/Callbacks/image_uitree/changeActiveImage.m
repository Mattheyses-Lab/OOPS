function changeActiveImage(source,~)
    OOPSData = guidata(source);
    CurrentGroupIndex = OOPSData.CurrentGroupIndex;
    SelectedImages = deal([source.SelectedNodes(:).NodeData]);
    OOPSData.Group(CurrentGroupIndex).CurrentImageIndex = [SelectedImages(:).SelfIdx];
    % update display of images, object selector, summary
    UpdateImages(source,{'Files','FFC','Mask','Order Factor','Azimuth','Objects','Polar Plots'});
    UpdateObjectListBox(source);
    UpdateThresholdSlider(source);
    UpdateIntensitySliders(source);
    UpdateSummaryDisplay(source,{'Image','Object'});
end