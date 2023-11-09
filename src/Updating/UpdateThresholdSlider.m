function UpdateThresholdSlider(source)

    OOPSData = guidata(source);
    
    cImage = OOPSData.CurrentImage;

    if numel(cImage)>1
        cImage = cImage(1);
    end

    if isempty(cImage)
        % testing - make invisible
        set([OOPSData.Handles.ThreshAxH,...
            OOPSData.Handles.ThreshBar,...
            OOPSData.Handles.CurrentThresholdLine],...
            'Visible','off');
        % end testing

        % prevent interaction with thresh slider
        OOPSData.Handles.ThreshAxH.HitTest = 'Off';
        % set threshold panel title to indicate no image is selected
        OOPSData.Handles.ImageOperationsPanel.Title = 'No image selected';
        % set the data on our threshold slider axes
        OOPSData.Handles.ThreshBar.BinCounts = zeros(1,256);
        % set thresh line to 0
        OOPSData.Handles.CurrentThresholdLine.Value = 0;
        % don't display a label
        OOPSData.Handles.CurrentThresholdLine.Label = '';
        return
    end

    OOPSData.Handles.ImageOperationsPanel.Title = cImage.ThreshPanelTitle();

    if cImage.ManualThreshEnabled
        % testing - make invisible
        set([OOPSData.Handles.ThreshAxH,...
            OOPSData.Handles.ThreshBar,...
            OOPSData.Handles.CurrentThresholdLine],...
            'Visible','on');
        % end testing


        % enable the threshold slider
        OOPSData.Handles.ThreshAxH.HitTest = 'On';
        % calculate and display bin counts for the intensity hist plot
        [cImage.IntensityHistPlot,cImage.IntensityBinCenters] = histcounts(cImage.EnhancedImg,OOPSData.Handles.ThreshBar.BinEdges);
        OOPSData.Handles.ThreshBar.BinCounts = cImage.IntensityHistPlot;

        OOPSData.Handles.CurrentThresholdLine.Value = cImage.level;
        OOPSData.Handles.CurrentThresholdLine.Label = {[cImage.ThreshStatisticName,' = ',num2str(OOPSData.Handles.CurrentThresholdLine.Value)]};
    else
        % testing - make invisible
        set([OOPSData.Handles.ThreshAxH,...
            OOPSData.Handles.ThreshBar,...
            OOPSData.Handles.CurrentThresholdLine],...
            'Visible','off');
        % end testing


        OOPSData.Handles.ThreshAxH.HitTest = 'Off';
        % set the data on our threshold slider axes
        OOPSData.Handles.ThreshBar.BinCounts = zeros(1,256);
        % set thresh line to 0
        OOPSData.Handles.CurrentThresholdLine.Value = 0;
        % don't display a label
        OOPSData.Handles.CurrentThresholdLine.Label = '';
        return
    end

end