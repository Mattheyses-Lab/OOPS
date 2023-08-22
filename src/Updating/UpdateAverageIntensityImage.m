function UpdateAverageIntensityImage(source)

    % main data structure
    OOPSData = guidata(source);
    
    % current image(s) selection
    cImage = OOPSData.CurrentImage;

    % if the current selection includes at least one image
    if ~isempty(cImage)
        % update the display according to the first image in the list
        cImage = cImage(1);
        EmptyImage = sparse(zeros(cImage.Height,cImage.Width));
    else
        EmptyImage = sparse(zeros(1024,1024));
    end

    % show or hide the AverageIntensity colorbar
    OOPSData.Handles.AverageIntensityCbar.Visible = OOPSData.Handles.ShowColorbarAverageIntensity.Value;

    try
        % get the user-defined display limits
        intensityDisplayLimits = cImage.PrimaryIntensityDisplayLimits.*cImage.averageIntensityRealLimits(2);
        % make avg intensity/reference composite RGB, if applicable
        if cImage.ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value
            % get the user-scaled intensity-reference overlay RGB image
            OOPSData.Handles.AverageIntensityImgH.CData = cImage.UserScaledAverageIntensityReferenceCompositeRGB;
        else % just show avg intensity
            OOPSData.Handles.AverageIntensityImgH.CData = cImage.UserScaledAverageIntensityImage;
        end
        % set the colorbar tick labels
        OOPSData.Handles.AverageIntensityCbar.TickLabels = round(linspace(intensityDisplayLimits(1),intensityDisplayLimits(2),11));
        % if ApplyMask state button set to true, apply current mask by setting AlphaData
        if OOPSData.Handles.ApplyMaskAverageIntensity.Value
            OOPSData.Handles.AverageIntensityImgH.AlphaData = cImage.bw;
        end
        % reset the default axes limits if zoom is not active
        if ~OOPSData.Settings.Zoom.Active
            OOPSData.Handles.AverageIntensityAxH.XLim = [0.5 cImage.Width+0.5];
            OOPSData.Handles.AverageIntensityAxH.YLim = [0.5 cImage.Height+0.5];
        end
    catch
        % set placeholders
        OOPSData.Handles.AverageIntensityImgH.CData = EmptyImage;
        OOPSData.Handles.AverageIntensityAxH.XLim = [0.5 size(EmptyImage,2)+0.5];
        OOPSData.Handles.AverageIntensityAxH.YLim = [0.5 size(EmptyImage,1)+0.5];
        OOPSData.Handles.AverageIntensityImgH.AlphaData = 1;
    end

end