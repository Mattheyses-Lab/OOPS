function TabSelection(source,~)

    % current PODSData structure
    PODSData = guidata(source);
    
    % update GUI state to reflect new current/previous tabs
    PODSData.Settings.PreviousTab = PODSData.Settings.CurrentTab;
    PODSData.Settings.CurrentTab = source.Text;
    
    % if ZoomToCursor is active, disable it before switching tabs
    if PODSData.Settings.Zoom.Active
        % store the zoom properties so we can reactivate them after tab switching
        RestoreProps.freezeState = PODSData.Settings.Zoom.Freeze;
        RestoreProps.XLimState = PODSData.Settings.Zoom.DynamicAxes.XLim;
        RestoreProps.YLimState = PODSData.Settings.Zoom.DynamicAxes.YLim;
        % unclick the currently pressed zoom toolbar button
        PODSData.Settings.Zoom.CurrentButton.Value = 0;
        % invoke the callback as if user had just unchecked the button
        ZoomToCursor(PODSData.Settings.Zoom.CurrentButton);
        % add the zoom properties to the zoom settings struct and set the restore flag
        PODSData.Settings.Zoom.RestoreProps = RestoreProps;
        PODSData.Settings.Zoom.Restore = true;
    end
    
    % indicate tab selection in log
    UpdateLog3(source,[PODSData.Settings.CurrentTab,' Tab Selected'],'append');
    
    switch PODSData.Settings.PreviousTab % the tab we are switching from
    
        case 'Files'
    
            for i = 1:4
    
                PODSData.Handles.FFCImgH(i).Visible = 'Off';
                PODSData.Handles.FFCAxH(i).Title.Visible = 'Off';
                PODSData.Handles.FFCAxH(i).Toolbar.Visible = 'Off';
                PODSData.Handles.FFCAxH(i).HitTest = 'Off';
    
                PODSData.Handles.RawIntensityImgH(i).Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).HitTest = 'Off';
    
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
        case 'FFC'
    
            for i = 1:4
    
                PODSData.Handles.PolFFCImgH(i).Visible = 'Off';
                PODSData.Handles.PolFFCAxH(i).Title.Visible = 'Off';
                PODSData.Handles.PolFFCAxH(i).Toolbar.Visible = 'Off';
                PODSData.Handles.PolFFCAxH(i).HitTest = 'Off';
    
                PODSData.Handles.RawIntensityImgH(i).Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).HitTest = 'Off';
    
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
        case 'Mask'
            % link large AvgIntensityAxH and MaskAxH
            linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.MaskAxH],'off');
    
            delete(PODSData.Handles.ObjectBoxes);
            delete(PODSData.Handles.SelectedObjectBoxes);
    
            PODSData.Handles.AverageIntensityImgH.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.HitTest = 'Off';
            PODSData.Handles.AverageIntensityAxH.Visible = 'Off';
    
            PODSData.Handles.MaskImgH.Visible = 'Off';
            PODSData.Handles.MaskAxH.Title.Visible = 'Off';
            PODSData.Handles.MaskAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.MaskAxH.HitTest = 'Off';
            PODSData.Handles.MaskAxH.Visible = 'Off';
    
        case 'Order Factor'
            % TEST in the line below
            linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.OrderFactorAxH],'off');
    
            delete(PODSData.Handles.ObjectBoxes);
            delete(PODSData.Handles.SelectedObjectBoxes);
    
            PODSData.Handles.OrderFactorImgH.Visible = 'Off';
            PODSData.Handles.OrderFactorAxH.Title.Visible = 'Off';
            PODSData.Handles.OrderFactorAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.OrderFactorAxH.HitTest = 'Off';
            PODSData.Handles.OrderFactorAxH.Visible = 'Off';
    
            PODSData.Handles.AverageIntensityImgH.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.HitTest = 'Off';
            PODSData.Handles.AverageIntensityAxH.Visible = 'Off';
    
            PODSData.Handles.ImgPanel1.Visible = 'Off';
    
            PODSData.Handles.OFCbar.Visible = 'Off';
    
        case 'Azimuth'
    
            linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.AzimuthAxH],'off');
    
            delete(PODSData.Handles.AzimuthLines);
            delete(PODSData.Handles.ObjectMidlinePlot);
    
            set(PODSData.Handles.PhaseBarComponents,'Visible','Off');
    
            PODSData.Handles.AzimuthImgH.Visible = 'Off';
            PODSData.Handles.AzimuthAxH.Title.Visible = 'Off';
            PODSData.Handles.AzimuthAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.AzimuthAxH.HitTest = 'Off';
            PODSData.Handles.AzimuthAxH.Visible = 'Off';
    
            PODSData.Handles.AverageIntensityImgH.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.HitTest = 'Off';
            PODSData.Handles.AverageIntensityAxH.Visible = 'Off';
    
        case 'Plots'
    
            % hide the scatter plot
            PODSData.Handles.ScatterPlotGrid.Visible = 'Off';
            delete(PODSData.Handles.ScatterPlotAxH.Children)
    
            if isvalid(PODSData.Handles.ScatterPlotAxH.Legend)
                PODSData.Handles.ScatterPlotAxH.Legend.Visible = 'Off';
            end
            PODSData.Handles.ScatterPlotAxH.Title.Visible = 'Off';
            PODSData.Handles.ScatterPlotAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.ScatterPlotAxH.Visible = 'Off';
            PODSData.Handles.ScatterPlotAxH.XAxis.Label.Visible = 'Off';
            PODSData.Handles.ScatterPlotAxH.YAxis.Label.Visible = 'Off';
            PODSData.Handles.ScatterPlotAxH.HitTest = 'Off';

            % hide the swarm plot
            PODSData.Handles.SwarmPlotGrid.Visible = 'Off';
            delete(PODSData.Handles.SwarmPlotAxH.Children)
    
            PODSData.Handles.SwarmPlotAxH.Title.Visible = 'Off';
            PODSData.Handles.SwarmPlotAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.SwarmPlotAxH.Visible = 'Off';
            PODSData.Handles.SwarmPlotAxH.XAxis.Label.Visible = 'Off';
            PODSData.Handles.SwarmPlotAxH.YAxis.Label.Visible = 'Off';
            PODSData.Handles.SwarmPlotAxH.HitTest = 'Off';
    
        case 'View Objects'
    
            % delete the object boundary plot
            delete(PODSData.Handles.ObjectBoundaryPlot);

            % delete the object Azimuth lines
            delete(PODSData.Handles.ObjectAzimuthLines);

            % delete the object midline plot
            delete(PODSData.Handles.ObjectMidlinePlot);
    
            % delete the object intensity curves
            delete(PODSData.Handles.ObjectIntensityPlotAxH.Children);
    
            % object intensity image
            PODSData.Handles.ObjectPolFFCAxH.Title.Visible = 'Off';
            PODSData.Handles.ObjectPolFFCImgH.Visible = 'Off';
    
            % object mask image
            PODSData.Handles.ObjectMaskAxH.Title.Visible = 'Off';
            PODSData.Handles.ObjectMaskImgH.Visible = 'Off';
    
            % object intensity image with azimuth lines overlay
            PODSData.Handles.ObjectAzimuthOverlayAxH.Title.Visible = 'Off';
            PODSData.Handles.ObjectAzimuthOverlayImgH.Visible = 'Off';
    
            % object OF image
            PODSData.Handles.ObjectOFAxH.Title.Visible = 'Off';
            PODSData.Handles.ObjectOFImgH.Visible = 'Off';
    
            % object intensity fit plot
            PODSData.Handles.ObjectIntensityPlotAxH.Visible = 'Off';
            PODSData.Handles.ObjectIntensityPlotAxH.Title.Visible = 'Off';
    
            % object stack-normalized intensity
            PODSData.Handles.ObjectNormIntStackImgH.Visible = 'Off';
            PODSData.Handles.ObjectNormIntStackAxH.Title.Visible = 'Off';
    
            % hide panels that were used by this tab
            PODSData.Handles.ImgPanel2.Visible = 'Off';
    
            for i = 1:2
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
    end
    
    switch PODSData.Settings.CurrentTab % the tab we are switching to
        case 'Files'
    
            for i = 1:4
    
                PODSData.Handles.RawIntensityImgH(i).Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).Title.Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).HitTest = 'On';
    
                PODSData.Handles.FFCImgH(i).Visible = 'On';
                PODSData.Handles.FFCAxH(i).Title.Visible = 'On';
                PODSData.Handles.FFCAxH(i).Toolbar.Visible = 'On';
                PODSData.Handles.FFCAxH(i).HitTest = 'On';
    
                PODSData.Handles.SmallPanels(1,i).Visible = 'On';
                PODSData.Handles.SmallPanels(2,i).Visible = 'On';
            end

            PODSData.Handles.ImgPanel1.Visible = 'Off';
            PODSData.Handles.ImgPanel2.Visible = 'Off';
    
        case 'FFC'
    
            for i = 1:4
    
                PODSData.Handles.RawIntensityImgH(i).Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).Title.Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).HitTest = 'On';
    
                PODSData.Handles.PolFFCImgH(i).Visible = 'On';
                PODSData.Handles.PolFFCAxH(i).Title.Visible = 'On';
                PODSData.Handles.PolFFCAxH(i).Toolbar.Visible = 'On';
                PODSData.Handles.PolFFCAxH(i).HitTest = 'On';
    
                PODSData.Handles.SmallPanels(1,i).Visible = 'On';
                PODSData.Handles.SmallPanels(2,i).Visible = 'On';
            end

            PODSData.Handles.ImgPanel1.Visible = 'Off';
            PODSData.Handles.ImgPanel2.Visible = 'Off';
    
        case 'Mask'
            PODSData.Handles.ImgPanel1.Visible = 'On';
            PODSData.Handles.ImgPanel2.Visible = 'On';
    
            PODSData.Handles.AverageIntensityImgH.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.HitTest = 'On';
            PODSData.Handles.AverageIntensityAxH.Visible = 'On';
    
            PODSData.Handles.MaskImgH.Visible = 'On';
            PODSData.Handles.MaskAxH.Title.Visible = 'On';
            PODSData.Handles.MaskAxH.Toolbar.Visible = 'On';
            PODSData.Handles.MaskAxH.HitTest = 'On';
            PODSData.Handles.MaskAxH.Visible = 'On';
    
            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
            try
                linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.MaskAxH],'xy');
            catch
                warning('Failed to link average intensity and mask axes');
            end
    
        case 'Order Factor'
    
            PODSData.Handles.OrderFactorImgH.Visible = 'On';
            PODSData.Handles.OrderFactorAxH.Title.Visible = 'On';
            PODSData.Handles.OrderFactorAxH.Toolbar.Visible = 'On';
            PODSData.Handles.OrderFactorAxH.HitTest = 'On';
            PODSData.Handles.OrderFactorAxH.Visible = 'On';
    
            PODSData.Handles.AverageIntensityImgH.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.HitTest = 'On';
            PODSData.Handles.AverageIntensityAxH.Visible = 'On';
    
            PODSData.Handles.ImgPanel2.Visible = 'On';
            PODSData.Handles.ImgPanel1.Visible = 'On';
    
            PODSData.Handles.OFCbar.Visible = 'On';
    
            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
            try
                linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.OrderFactorAxH],'xy');
            catch
                warning('Failed to link average intensity and order factor axes');
            end
    
        case 'Azimuth'
    
            PODSData.Handles.AzimuthImgH.Visible = 'On';
            PODSData.Handles.AzimuthAxH.Title.Visible = 'On';
            PODSData.Handles.AzimuthAxH.Toolbar.Visible = 'On';
            PODSData.Handles.AzimuthAxH.HitTest = 'On';
            PODSData.Handles.AzimuthAxH.Visible = 'On';
    
            set(PODSData.Handles.PhaseBarComponents,'Visible','On');
    
            PODSData.Handles.AverageIntensityImgH.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.HitTest = 'On';
            PODSData.Handles.AverageIntensityAxH.Visible = 'On';
    
            PODSData.Handles.ImgPanel1.Visible = 'On';
            PODSData.Handles.ImgPanel2.Visible = 'On';
    
            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
            try
                linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.AzimuthAxH],'xy');
            catch
                warning('Failed to link average intensity and azimuth axes')
            end
    
        case 'Plots'
    
            if isvalid(PODSData.Handles.ScatterPlotAxH.Legend)
                PODSData.Handles.ScatterPlotAxH.Legend.Visible = 'On';
            end
    
            PODSData.Handles.ScatterPlotGrid.Visible = 'On';
            PODSData.Handles.ScatterPlotAxH.Title.Visible = 'On';
            PODSData.Handles.ScatterPlotAxH.Toolbar.Visible = 'On';
            PODSData.Handles.ScatterPlotAxH.Visible = 'On';
            PODSData.Handles.ScatterPlotAxH.XAxis.Label.Visible = 'On';
            PODSData.Handles.ScatterPlotAxH.YAxis.Label.Visible = 'On';
            PODSData.Handles.ScatterPlotAxH.HitTest = 'On';

            PODSData.Handles.SwarmPlotGrid.Visible = 'On';
            PODSData.Handles.SwarmPlotAxH.Visible = 'On';
            PODSData.Handles.SwarmPlotAxH.Title.Visible = 'On';
            PODSData.Handles.SwarmPlotAxH.Toolbar.Visible = 'On';
            PODSData.Handles.SwarmPlotAxH.XAxis.Label.Visible = 'On';
            PODSData.Handles.SwarmPlotAxH.YAxis.Label.Visible = 'On';
            PODSData.Handles.SwarmPlotAxH.HitTest = 'On';

            PODSData.Handles.ImgPanel1.Visible = 'On';
            PODSData.Handles.ImgPanel2.Visible = 'On';
    
            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
        case 'View Objects'
    
            % object intensity image
            PODSData.Handles.ObjectPolFFCAxH.Title.Visible = 'On';
            PODSData.Handles.ObjectPolFFCImgH.Visible = 'On';
    
            % object binary image
            PODSData.Handles.ObjectMaskAxH.Title.Visible = 'On';
            PODSData.Handles.ObjectMaskImgH.Visible = 'On';
    
            PODSData.Handles.ObjectAzimuthOverlayAxH.Title.Visible = 'On';
            PODSData.Handles.ObjectAzimuthOverlayImgH.Visible = 'On';
    
            PODSData.Handles.ObjectOFAxH.Title.Visible = 'On';
            PODSData.Handles.ObjectOFImgH.Visible = 'On';
    
            PODSData.Handles.ObjectNormIntStackImgH.Visible = 'On';
            PODSData.Handles.ObjectNormIntStackAxH.Title.Visible = 'On';
    
            PODSData.Handles.ObjectIntensityPlotAxH.Visible = 'On';
            PODSData.Handles.ObjectIntensityPlotAxH.Title.Visible = 'On';
    
            PODSData.Handles.ImgPanel2.Visible = 'On';
    
            for i = 1:2
                PODSData.Handles.SmallPanels(1,i).Visible = 'On';
                PODSData.Handles.SmallPanels(2,i).Visible = 'On';
            end
    
            PODSData.Handles.ImgPanel1.Visible = 'Off';

    end

    % if the restore flag is set and the selected tab is zoomable
    if PODSData.Settings.Zoom.Restore && ismember(PODSData.Settings.CurrentTab,{'Mask','Order Factor','Azimuth'})
        % set the button to active in the axes for which we will activate zoom (average intensity axes)
        PODSData.Handles.ZoomToCursorAverageIntensity.Value = 1;
        % restore zoom on the average intensity axes (easiest for now as it is in all zoomable tabs)
        ZoomToCursor(PODSData.Handles.ZoomToCursorAverageIntensity);
    end
    % now remove the restore properties and unset the restore flag
    PODSData.Settings.Zoom.RestoreProps = [];
    PODSData.Settings.Zoom.Restore = false;

    UpdateImages(source);
    UpdateSummaryDisplay(source,{'Project'});
end