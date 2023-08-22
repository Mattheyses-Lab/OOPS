function changeActiveImage(source,~)
    % handle to the main data structure
    OOPSData = guidata(source);
    % index of the current group
    CurrentGroupIndex = OOPSData.CurrentGroupIndex;
    % handle(s) to the currently selected image(s)
    SelectedImages = deal([source.SelectedNodes(:).NodeData]);
    % set current image(s) in group based on idx of image(s) selected in the uitree
    OOPSData.Group(CurrentGroupIndex).CurrentImageIndex = [SelectedImages(:).SelfIdx];
    % update display of images, object selector, summary, custom stat images
    UpdateIntensitySliders(source);
    UpdateImages(source,[{'Files','FFC','Mask','Order','Azimuth','Objects','Polar Plots'},OOPSData.Settings.CustomStatisticDisplayNames.']);
    UpdateObjectListBox(source);
    UpdateThresholdSlider(source);
    UpdateSummaryDisplay(source,{'Image','Object'});
end