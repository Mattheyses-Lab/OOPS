function UpdateAzimuthStickOverlay(source)

    % handle to the main data structure
    OOPSData = guidata(source);

    % current image(s) selection
    cImage = OOPSData.CurrentImage;

    % if the current selection includes at least one image
    if ~isempty(cImage)
        % update the display according to the first image in the list
        cImage = cImage(1);
    end

    % delete any existing azimuth sticks
    try
        delete(OOPSData.Handles.AzimuthLines);
    catch
        disp('Warning: Could not delete Azimuth lines')
    end


    try

        if OOPSData.Settings.AzimuthObjectMask
            LineMask = cImage.bw;
        else
            LineMask = true(size(cImage.bw));
        end

        LineScaleDown = OOPSData.Settings.AzimuthScaleDownFactor;
        
        if LineScaleDown > 1
            ScaleDownMask = makeSpacedCheckerboard(size(LineMask),LineScaleDown);
            LineMask = LineMask & logical(ScaleDownMask);
        end
        
        [y,x] = find(LineMask==1);
        theta = cImage.AzimuthImage(LineMask);
        rho = cImage.OrderImage(LineMask);
        
        ColorMode = OOPSData.Settings.AzimuthColorMode;
        LineWidth = OOPSData.Settings.AzimuthLineWidth;
        LineAlpha = OOPSData.Settings.AzimuthLineAlpha;
        LineScale = OOPSData.Settings.AzimuthLineScale;
        
        switch ColorMode
            case 'Magnitude'
                Colormap = OOPSData.Settings.OrderColormap;
            case 'Direction'
                Colormap = repmat(OOPSData.Settings.AzimuthColormap,2,1);
            case 'Mono'
                Colormap = [1 1 1];
        end
        
        OOPSData.Handles.AzimuthLines = QuiverPatch2(OOPSData.Handles.AverageIntensityAxH,...
            x,...
            y,...
            theta,...
            rho,...
            ColorMode,...
            Colormap,...
            LineWidth,...
            LineAlpha,...
            LineScale);

    catch
        disp('Warning: Error displaying azimuth sticks')
    end

end