function UpdateIntensitySliders(source)

    OOPSData = guidata(source);
    
    cImage = OOPSData.CurrentImage;

    if numel(cImage)>1 
        cImage = cImage(1);
    end

    if isempty(cImage)
        OOPSData.Handles.PrimaryIntensitySlider.Value = [0 1];
        OOPSData.Handles.PrimaryIntensitySlider.HitTest = 'Off';
        OOPSData.Handles.ReferenceIntensitySlider.Value = [0 1];
        OOPSData.Handles.ReferenceIntensitySlider.HitTest = 'Off';
        return
    end

    OOPSData.Handles.PrimaryIntensitySlider.HitTest = 'On';
    OOPSData.Handles.ReferenceIntensitySlider.HitTest = 'On';

    try
        OOPSData.Handles.PrimaryIntensitySlider.Value = cImage.PrimaryIntensityDisplayLimits;
    catch
        OOPSData.Handles.PrimaryIntensitySlider.Value = [0 1];
    end

    try
        OOPSData.Handles.ReferenceIntensitySlider.Value = cImage.ReferenceIntensityDisplayLimits;
    catch
        OOPSData.Handles.ReferenceIntensitySlider.Value = [0 1];
    end

end