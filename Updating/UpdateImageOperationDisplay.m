function UpdateImageOperationDisplay(source)

    PODSData = guidata(source);
    
    PODSData.Handles.ThreshSliderGrid.Visible = 'Off';
    PODSData.Handles.IntensitySlidersGrid.Visible = 'Off';

    cImage = PODSData.CurrentImage;

    if numel(cImage)>1; cImage = cImage(1); end

    switch PODSData.Settings.CurrentImageOperation
    
        case 'Mask Threshold'
            PODSData.Handles.ThreshSliderGrid.Visible = 'On';
            
            if isempty(cImage)
                PODSData.Handles.ImageOperationsPanel.Title = 'No image selected';
                % build histogram from random data
                [BinCtrs,HistPlot] = BuildHistogram(rand(1024,1024));
                PODSData.Handles.ThreshBar.XData = BinCtrs;
                PODSData.Handles.ThreshBar.YData = HistPlot;
                % set thresh line to 0
                PODSData.Handles.CurrentThresholdLine.Value = 0;
                % don't display a label
                PODSData.Handles.CurrentThresholdLine.Label = '';
                return
            end

            PODSData.Handles.ImageOperationsPanel.Title = cImage.ThreshPanelTitle();

            if cImage.ManualThreshEnabled
                PODSData.Handles.ThreshAxH.HitTest = 'On';
                [cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.EnhancedImg);
                PODSData.Handles.ThreshBar.XData = cImage.IntensityBinCenters;
                PODSData.Handles.ThreshBar.YData = cImage.IntensityHistPlot;
                PODSData.Handles.CurrentThresholdLine.Value = cImage.level;
                PODSData.Handles.CurrentThresholdLine.Label = {[cImage.ThreshStatisticName,' = ',num2str(PODSData.Handles.CurrentThresholdLine.Value)]};
            else
                PODSData.Handles.ThreshAxH.HitTest = 'Off';
                % build histogram from random data
                [BinCtrs,HistPlot] = BuildHistogram(rand(1024,1024));
                PODSData.Handles.ThreshBar.XData = BinCtrs;
                PODSData.Handles.ThreshBar.YData = HistPlot;
                % set thresh line to 0
                PODSData.Handles.CurrentThresholdLine.Value = 0;
                % don't display a label
                PODSData.Handles.CurrentThresholdLine.Label = '';
                return
            end
    
            % try
            %     [cImage.IntensityBinCenters,cImage.IntensityHistPlot] = BuildHistogram(cImage.EnhancedImg);
            %     PODSData.Handles.ThreshBar.XData = cImage.IntensityBinCenters;
            %     PODSData.Handles.ThreshBar.YData = cImage.IntensityHistPlot;
            %     PODSData.Handles.CurrentThresholdLine.Value = cImage.level;
            %     PODSData.Handles.CurrentThresholdLine.Label = {[cImage.ThreshStatisticName,' = ',num2str(PODSData.Handles.CurrentThresholdLine.Value)]};
            % catch
            %     % build histogram from random data
            %     [BinCtrs,HistPlot] = BuildHistogram(rand(1024,1024));
            %     PODSData.Handles.ThreshBar.XData = BinCtrs;
            %     PODSData.Handles.ThreshBar.YData = HistPlot;
            %     % set thresh line to 0
            %     PODSData.Handles.CurrentThresholdLine.Value = 0;
            %     % don't display a label
            %     PODSData.Handles.CurrentThresholdLine.Label = '';
            %     return
            % end
    
        case 'Intensity Display'
            PODSData.Handles.IntensitySlidersGrid.Visible = 'On';
            PODSData.Handles.ImageOperationsPanel.Title = 'Adjust intensity display limits';
            try
                PODSData.Handles.PrimaryIntensitySlider.Value = cImage.PrimaryIntensityDisplayLimits;
            catch
                PODSData.Handles.PrimaryIntensitySlider.Value = [0 1];
            end
    
            try
                PODSData.Handles.ReferenceIntensitySlider.Value = cImage.ReferenceIntensityDisplayLimits;
            catch
                PODSData.Handles.ReferenceIntensitySlider.Value = [0 1];
            end
    end

end