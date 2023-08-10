function UpdateIntensitySliders(source)

    OOPSData = guidata(source);

    cImage = OOPSData.CurrentImage;

    if ~isempty(cImage)
        cImage = cImage(1);
    else
        OOPSData.Handles.PrimaryIntensitySlider.Value = [0 1];
        OOPSData.Handles.PrimaryIntensitySlider.HitTest = 'Off';
        OOPSData.Handles.ReferenceIntensitySlider.Value = [0 1];
        OOPSData.Handles.ReferenceIntensitySlider.HitTest = 'Off';
        OOPSData.Handles.OrderSlider.Value = [0 1];
        OOPSData.Handles.OrderSlider.HitTest = 'Off';
        return
    end

    OOPSData.Handles.PrimaryIntensitySlider.HitTest = 'On';
    OOPSData.Handles.ReferenceIntensitySlider.HitTest = 'On';
    OOPSData.Handles.OrderSlider.HitTest = 'On';

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

    try
        OOPSData.Handles.OrderSlider.Value = cImage.OrderDisplayLimits;
    catch
        OOPSData.Handles.OrderSlider.Value = [0 1];
    end

end