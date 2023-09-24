function UpdateThresholdSlider(source)

    OOPSData = guidata(source);
    
    cImage = OOPSData.CurrentImage;

    if numel(cImage)>1
        cImage = cImage(1);
    end

    if isempty(cImage)
        % prevent interaction with thresh slider
        OOPSData.Handles.ThreshAxH.HitTest = 'Off';
        % set threshold panel title to indicate no image is selected
        OOPSData.Handles.ImageOperationsPanel.Title = 'No image selected';
        % % get histogram counts from empty data
        % [~,HistPlot] = BuildHistogram([]);
        % % set the data on our threshold slider axes
        % OOPSData.Handles.ThreshBar.YData = HistPlot;
        OOPSData.Handles.ThreshBar.BinCounts = zeros(1,256);






        % set thresh line to 0
        OOPSData.Handles.CurrentThresholdLine.Value = 0;
        % don't display a label
        OOPSData.Handles.CurrentThresholdLine.Label = '';
        return
    end

    OOPSData.Handles.ImageOperationsPanel.Title = cImage.ThreshPanelTitle();

    if cImage.ManualThreshEnabled
        % enable the threshold slider
        OOPSData.Handles.ThreshAxH.HitTest = 'On';

        %[cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.EnhancedImg);
        %OOPSData.Handles.ThreshBar.YData = cImage.IntensityHistPlot;

        [cImage.IntensityHistPlot,cImage.IntensityBinCenters] = histcounts(cImage.EnhancedImg,OOPSData.Handles.ThreshBar.BinEdges);
        OOPSData.Handles.ThreshBar.BinCounts = cImage.IntensityHistPlot;




        OOPSData.Handles.CurrentThresholdLine.Value = cImage.level;
        OOPSData.Handles.CurrentThresholdLine.Label = {[cImage.ThreshStatisticName,' = ',num2str(OOPSData.Handles.CurrentThresholdLine.Value)]};
    else
        OOPSData.Handles.ThreshAxH.HitTest = 'Off';
        % % get histogram counts from empty data
        % [~,HistPlot] = BuildHistogram([]);
        % % set the data on our threshold slider axes
        % OOPSData.Handles.ThreshBar.YData = HistPlot;

        OOPSData.Handles.ThreshBar.BinCounts = zeros(1,256);


        % set thresh line to 0
        OOPSData.Handles.CurrentThresholdLine.Value = 0;
        % don't display a label
        OOPSData.Handles.CurrentThresholdLine.Label = '';
        return
    end

end