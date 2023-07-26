function changeActiveObject(source,~)
    OOPSData = guidata(source);
    cImage = OOPSData.CurrentImage;
    cImage.CurrentObjectIdx = source.Value;
    UpdateSummaryDisplay(source,{'Object'});
    UpdateImages(source,{'Objects'});
end