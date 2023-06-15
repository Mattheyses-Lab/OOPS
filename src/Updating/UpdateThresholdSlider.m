function UpdateThresholdSlider(source)

    OOPSData = guidata(source);
    
    cImage = OOPSData.CurrentImage;

    if numel(cImage)>1
        cImage = cImage(1);
    end

    if isempty(cImage)
        % prevent interaction with thresh slider
        OOPSData.Handles.ThreshAxH.HitTest = 'Off';

        OOPSData.Handles.ImageOperationsPanel.Title = 'No image selected';
        % get histogram counts from random data
        [~,HistPlot] = BuildHistogram(rand(1024,1024));
        % set the data on our threshold slider axes
        OOPSData.Handles.ThreshBar.YData = HistPlot;
        % set thresh line to 0
        OOPSData.Handles.CurrentThresholdLine.Value = 0;
        % don't display a label
        OOPSData.Handles.CurrentThresholdLine.Label = '';
        return
    end

    OOPSData.Handles.ImageOperationsPanel.Title = cImage.ThreshPanelTitle();

    if cImage.ManualThreshEnabled
        OOPSData.Handles.ThreshAxH.HitTest = 'On';
        [cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.EnhancedImg);
        %OOPSData.Handles.ThreshBar.XData = cImage.IntensityBinCenters;

        OOPSData.Handles.ThreshBar.YData = cImage.IntensityHistPlot;
        OOPSData.Handles.CurrentThresholdLine.Value = cImage.level;
        OOPSData.Handles.CurrentThresholdLine.Label = {[cImage.ThreshStatisticName,' = ',num2str(OOPSData.Handles.CurrentThresholdLine.Value)]};
    else
        OOPSData.Handles.ThreshAxH.HitTest = 'Off';
        % get histogram counts from random data
        [~,HistPlot] = BuildHistogram(rand(1024,1024));
        % set the data on our threshold slider axes
        OOPSData.Handles.ThreshBar.YData = HistPlot;
        % set thresh line to 0
        OOPSData.Handles.CurrentThresholdLine.Value = 0;
        % don't display a label
        OOPSData.Handles.CurrentThresholdLine.Label = '';
        return
    end

end