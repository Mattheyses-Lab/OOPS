function UpdateImageOperationDisplay(source)

    OOPSData = guidata(source);
    
    OOPSData.Handles.ThreshSliderGrid.Visible = 'Off';
    OOPSData.Handles.IntensitySlidersGrid.Visible = 'Off';

    cImage = OOPSData.CurrentImage;

    if numel(cImage)>1; cImage = cImage(1); end

    switch OOPSData.Settings.CurrentImageOperation
    
        case 'Mask Threshold'
            OOPSData.Handles.ThreshSliderGrid.Visible = 'On';
            
            if isempty(cImage)
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
    
        case 'Intensity Display'
            OOPSData.Handles.IntensitySlidersGrid.Visible = 'On';
            OOPSData.Handles.ImageOperationsPanel.Title = 'Adjust intensity display limits';

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

end