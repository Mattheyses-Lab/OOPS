function [] = UpdateImages(source)
    %% Get relevant variables needed to update image data
    
    % get main data structure
    PODSData = guidata(source);
    
    % get gui handles
    Handles = PODSData.Handles;
    
    % get current group index
    cGroupIndex = PODSData.CurrentGroupIndex;
    % get current replicate index within group
    cImageIndex = PODSData.Group(cGroupIndex).CurrentImageIndex;
    
    trueImageIndex = cImageIndex;
    
    if length(cImageIndex) > 1
        cImageIndex = cImageIndex(1);
    end
    
    % get current replicate data structure
    Replicate = PODSData.Group(cGroupIndex).Replicate(cImageIndex);
    % get FFCData for current group
    FFCData = PODSData.Group(cGroupIndex).FFCData
    
    % empty image to serve as a placeholder when image has not been
    % computed for (cGroup,cImage)
    EmptyImage = zeros(1024,1024);
    
%% Update CData of gui image objects to reflect user-specified group/image change 
%% Flat-Field Images
    try
        Handles.FFCImage0.CData = FFCData.cal_norm(:,:,1);
        Handles.FFCImage45.CData = FFCData.cal_norm(:,:,2);
        Handles.FFCImage90.CData = FFCData.cal_norm(:,:,3);
        Handles.FFCImage135.CData = FFCData.cal_norm(:,:,4);
    catch
        UpdateLog3(source,'WARNING: No FFC Images found for this group, try loading them now','append');
        Handles.FFCImage0.CData = EmptyImage;
        Handles.FFCImage45.CData = EmptyImage;
        Handles.FFCImage90.CData = EmptyImage;
        Handles.FFCImage135.CData = EmptyImage;
    end
    
%% FPM (experimental) Images
    try
        Handles.RawImage0.CData = Replicate.pol_rawdata_normalizedbystack(:,:,1);
        Handles.RawImage45.CData = Replicate.pol_rawdata_normalizedbystack(:,:,2);
        Handles.RawImage90.CData = Replicate.pol_rawdata_normalizedbystack(:,:,3);
        Handles.RawImage135.CData = Replicate.pol_rawdata_normalizedbystack(:,:,4);        
    catch
        Handles.RawImage0.CData = EmptyImage;
        Handles.RawImage45.CData = EmptyImage;
        Handles.RawImage90.CData = EmptyImage;
        Handles.RawImage135.CData = EmptyImage;
    end

%% Flat-Field Corrected Images
    try
        Handles.PolFFCImage0.CData = Replicate.pol_ffc_normalizedbystack(:,:,1);
        Handles.PolFFCImage45.CData = Replicate.pol_ffc_normalizedbystack(:,:,2);
        Handles.PolFFCImage90.CData = Replicate.pol_ffc_normalizedbystack(:,:,3);
        Handles.PolFFCImage135.CData = Replicate.pol_ffc_normalizedbystack(:,:,4);        
    catch
        Handles.PolFFCImage0.CData = EmptyImage;
        Handles.PolFFCImage45.CData = EmptyImage;
        Handles.PolFFCImage90.CData = EmptyImage;
        Handles.PolFFCImage135.CData = EmptyImage;        
    end
    
%% Masking Steps
    try
        Handles.MStepsIntensityImage.CData = Replicate.I;
        Handles.MStepsBackgroundImage.CData = Replicate.BGImg;
        
        Handles.MStepsBGSubtractedImage.CData = Replicate.BGSubtractedImg;
        Handles.MStepsBGSubtracted.CLim = [min(min(Replicate.BGSubtractedImg)) max(max(Replicate.BGSubtractedImg))];
        
        Handles.MStepsMedianFilteredImage.CData = Replicate.MedianFilteredImg;
        Handles.MStepsMedianFiltered.CLim = [min(min(Replicate.MedianFilteredImg)) max(max(Replicate.MedianFilteredImg))];
        
        Handles.SESizeBox.Value = Replicate.SESize;
        Handles.SELinesBox.Value = Replicate.SELines;
    catch
        Handles.MStepsIntensityImage.CData = EmptyImage;
        Handles.MStepsBackgroundImage.CData = EmptyImage;
        Handles.MStepsBGSubtractedImage.CData = EmptyImage;
        Handles.MStepsMedianFilteredImage.CData = EmptyImage;        
    end    
    
%% Mask Properties

    if length(trueImageIndex) > 1
        Handles.SESizeBox.Value = '';
        Handles.SELinesBox.Value = '';
    else
        try
            Handles.SESizeBox.Value = Replicate.SESize;
            Handles.SELinesBox.Value = Replicate.SELines;        
        catch
            Handles.SESizeBox.Value = 5;
            Handles.SELinesBox.Value = 4;
        end
    end
    
%% Mask
    try
        Handles.MaskImage.CData = Replicate.bw;
    catch
        Handles.MaskImage.CData = EmptyImage;
    end
    
%% Thresh Slider
    try
        Handles.ThreshSlider.Value = Replicate.level;
    catch
        Handles.ThreshSlider.Value = 0.5;
    end    
    
%% Intensity Distribution Plot
    try
        Handles.ThreshBar.XData = Replicate.IntensityBinCenters;
        Handles.ThreshBar.YData = Replicate.IntensityHistPlot;
    catch
        UpdateLog3(source,'WARNING: NO INTENSITY DISTRIBUTION INFORMATION FOUND','append');
    end
    
%% Average Intensity
    try
        Handles.AverageIntensityImage.CData = Replicate.I;
    catch
        Handles.AverageIntensityImage.CData = EmptyImage;
    end    
    
%% Order Factor
    try
        Handles.OrderFactorImage.CData = Replicate.masked_OF_image;
    catch
        Handles.OrderFactorImage.CData = EmptyImage;
    end  
    

    
    % update local PODSData structure with updated Handles
    PODSData.Handles = Handles;
    % update guidata with updated PODSData structure
    guidata(source,PODSData);
    

end