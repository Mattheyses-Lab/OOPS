function UpdateAzimuthImage(source)

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

    try
        % set the image CData
        if OOPSData.Handles.ShowAzimuthHSVOverlayAzimuth.Value
            OOPSData.Handles.AzimuthImgH.CData = cImage.UserScaledAzimuthOrderIntensityHSV;
        elseif OOPSData.Handles.ShowAsOverlayAzimuth.Value
            OOPSData.Handles.AzimuthImgH.CData = cImage.UserScaledAzimuthIntensityOverlayRGB;
        else
            OOPSData.Handles.AzimuthImgH.CData = cImage.AzimuthImage;
            OOPSData.Handles.AzimuthAxH.CLim = [-pi,pi]; % very important to set for proper display colors
        end
        % reset the default axes limits if zoom is not active
        if ~OOPSData.Settings.Zoom.Active
            OOPSData.Handles.AzimuthAxH.XLim = [0.5 cImage.Width+0.5];
            OOPSData.Handles.AzimuthAxH.YLim = [0.5 cImage.Height+0.5];
        end
        % if ApplyMask state button set to true, apply current mask by setting AlphaData
        if OOPSData.Handles.ApplyMaskAzimuth.Value
            OOPSData.Handles.AzimuthImgH.AlphaData = cImage.bw;
        end
    catch
        % set placeholders in case display fails
        OOPSData.Handles.AzimuthImgH.CData = EmptyImage;
        OOPSData.Handles.AzimuthAxH.XLim = [0.5 size(EmptyImage,2)+0.5];
        OOPSData.Handles.AzimuthAxH.YLim = [0.5 size(EmptyImage,1)+0.5];
        OOPSData.Handles.AzimuthImgH.AlphaData = 1;
    end

    % set(OOPSData.Handles.PhaseBarComponents,'Visible',OOPSData.Handles.ShowColorbarAzimuth.Value);
    OOPSData.Handles.AzimuthColorbar.Visible = OOPSData.Handles.ShowColorbarAzimuth.Value;

    % set the azimuth image colormap
    OOPSData.Handles.AzimuthAxH.Colormap = repmat(OOPSData.Settings.AzimuthColormap,2,1);

end