function [] = TabSelection(source,~)

    % current PODSData structure
    PODSData = guidata(source);
    
    % update GUI state to reflect new current/previous tabs
    PODSData.Settings.PreviousTab = PODSData.Settings.CurrentTab;
    PODSData.Settings.CurrentTab = source.Text;
    
    % if ZoomToCursor is active, disable it before switching tabs
    if PODSData.Settings.Zoom.Active
        PODSData.Settings.Zoom.CurrentButton.Value = 0;
        ZoomToCursor(PODSData.Settings.Zoom.CurrentButton);
    end
    
    % indicate tab selection in log
    UpdateLog3(source,[PODSData.Settings.CurrentTab,' Tab Selected'],'append');
    
    switch PODSData.Settings.PreviousTab % the tab we are switching from
    
        case 'Files'
%             try
%                 linkaxes(PODSData.Handles.FFCAxH,'off');
%                 linkaxes(PODSData.Handles.RawIntensityAxH,'off');
%             catch
%                 % do nothing
%             end
    
            for i = 1:4
                %PODSData.Handles.RawIntensityAxH(i).Parent = PODSData.Handles.SmallPanels(1,i);
    
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
                %PODSData.Handles.RawIntensityAxH(i).Parent = PODSData.Handles.SmallPanels(2,i);
    
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
    
        case 'Generate Mask'
            try
                linkaxes([PODSData.Handles.MStepsAxH,PODSData.Handles.MaskAxH],'off');
            catch
                % do nothing
            end
    
            PODSData.Handles.MaskImgH.Visible = 'Off';
            PODSData.Handles.MaskAxH.Title.Visible = 'Off';
            PODSData.Handles.MaskAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.MaskAxH.HitTest = 'Off';
    
            % hide masking steps and small panels
            for i = 1:2
                PODSData.Handles.MStepsImgH(i).Visible = 'Off';
                PODSData.Handles.MStepsAxH(i).Title.Visible = 'Off';
                PODSData.Handles.MStepsAxH(i).Toolbar.Visible = 'Off';
                PODSData.Handles.MStepsAxH(i).HitTest = 'Off';
    
                PODSData.Handles.MStepsImgH(i+2).Visible = 'Off';
                PODSData.Handles.MStepsAxH(i+2).Title.Visible = 'Off';
                PODSData.Handles.MStepsAxH(i+2).Toolbar.Visible = 'Off';
                PODSData.Handles.MStepsAxH(i+2).HitTest = 'Off';
    
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
    
            delete(PODSData.Handles.ScatterPlotAxH.Children)
    
            if isvalid(PODSData.Handles.ScatterPlotAxH.Legend)
                PODSData.Handles.ScatterPlotAxH.Legend.Visible = 'Off';
            end
            PODSData.Handles.ScatterPlotAxH.Title.Visible = 'Off';
            PODSData.Handles.ScatterPlotAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.ScatterPlotAxH.Visible = 'Off';
    
            % hide the swarm plot
            delete(PODSData.Handles.SwarmPlotAxH.Children)
    
            PODSData.Handles.SwarmPlotAxH.Title.Visible = 'Off';
            PODSData.Handles.SwarmPlotAxH.Toolbar.Visible = 'Off';
            PODSData.Handles.SwarmPlotAxH.Visible = 'Off';
    
        case 'View Objects'
    
            %                 % delete the object OF contour plot
            %                 delete(data.Handles.hObjectOFContour);
    
            % delete the object Azimuth lines
            delete(PODSData.Handles.ObjectAzimuthLines);
    
            % delete the object intensity curves
            delete(PODSData.Handles.ObjectIntensityPlotAxH.Children);
    
            % object intensity image
            PODSData.Handles.ObjectPolFFCAxH.Title.Visible = 'Off';
            PODSData.Handles.ObjectPolFFCImgH.Visible = 'Off';
    
            % object mask image
            PODSData.Handles.ObjectMaskAxH.Title.Visible = 'Off';
            PODSData.Handles.ObjectMaskImgH.Visible = 'Off';
    
            PODSData.Handles.ObjectAzimuthOverlayAxH.Title.Visible = 'Off';
            PODSData.Handles.ObjectAzimuthOverlayImgH.Visible = 'Off';
    
            PODSData.Handles.ObjectOFAxH.Title.Visible = 'Off';
            PODSData.Handles.ObjectOFImgH.Visible = 'Off';
    
            PODSData.Handles.ObjectIntensityPlotAxH.Visible = 'Off';
            PODSData.Handles.ObjectIntensityPlotAxH.Title.Visible = 'Off';
    
            PODSData.Handles.ObjectNormIntStackImgH.Visible = 'Off';
            PODSData.Handles.ObjectNormIntStackAxH.Title.Visible = 'Off';
    
            PODSData.Handles.ImgPanel2.Visible = 'Off';
    
            for i = 1:2
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
    end
    
    switch PODSData.Settings.CurrentTab % the tab we are switching to
        case 'Files'
    
            for i = 1:4
                %PODSData.Handles.RawIntensityAxH(i).Parent = PODSData.Handles.SmallPanels(2,i);
    
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
                %PODSData.Handles.RawIntensityAxH(i).Parent = PODSData.Handles.SmallPanels(1,i);
    
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
    
        case 'Generate Mask'
    
            PODSData.Handles.MaskImgH.Visible = 'On';
            PODSData.Handles.MaskAxH.Title.Visible = 'On';
            PODSData.Handles.MaskAxH.Toolbar.Visible = 'On';
    
            PODSData.Handles.ImgPanel1.Visible = 'Off';
            PODSData.Handles.ImgPanel2.Visible = 'On';
    
            for i = 1:2
                PODSData.Handles.MStepsImgH(i).Visible = 'On';
                PODSData.Handles.MStepsAxH(i).Title.Visible = 'On';
                PODSData.Handles.MStepsAxH(i).Toolbar.Visible = 'On';
                PODSData.Handles.MStepsAxH(i).HitTest = 'On';
    
                PODSData.Handles.MStepsImgH(i+2).Visible = 'On';
                PODSData.Handles.MStepsAxH(i+2).Title.Visible = 'On';
                PODSData.Handles.MStepsAxH(i+2).Toolbar.Visible = 'On';
                PODSData.Handles.MStepsAxH(i+2).HitTest = 'On';
    
                PODSData.Handles.SmallPanels(1,i).Visible = 'On';
                PODSData.Handles.SmallPanels(2,i).Visible = 'On';
    
                PODSData.Handles.SmallPanels(1,i+2).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i+2).Visible = 'Off';
            end
    
            linkaxes([PODSData.Handles.MStepsAxH,PODSData.Handles.MaskAxH],'xy');
    
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
                % do nothing
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
    
            linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.OrderFactorAxH],'xy');
    
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
    
            linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.AzimuthAxH],'xy');
    
        case 'Plots'
    
            if isvalid(PODSData.Handles.ScatterPlotAxH.Legend)
                PODSData.Handles.ScatterPlotAxH.Legend.Visible = 'On';
            end
    
            PODSData.Handles.ScatterPlotAxH.Title.Visible = 'On';
            PODSData.Handles.ScatterPlotAxH.Toolbar.Visible = 'On';
            PODSData.Handles.ScatterPlotAxH.Visible = 'On';
    
            PODSData.Handles.SwarmPlotAxH.Visible = 'On';
            PODSData.Handles.SwarmPlotAxH.Title.Visible = 'On';
            PODSData.Handles.SwarmPlotAxH.Toolbar.Visible = 'On';
    
            PODSData.Handles.ImgPanel1.Visible = 'On';
            PODSData.Handles.ImgPanel2.Visible = 'On';
    
            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
%         case 'Filtered Order Factor'
%     
%             PODSData.Handles.AverageIntensityImgH.Visible = 'On';
%             PODSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
%             PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
%             PODSData.Handles.AverageIntensityAxH.HitTest = 'On';
%     
%             PODSData.Handles.FilteredOFImgH.Visible = 'On';
%             PODSData.Handles.FilteredOFAxH.Title.Visible = 'On';
%             PODSData.Handles.FilteredOFAxH.Toolbar.Visible = 'On';
%             PODSData.Handles.FilteredOFAxH.HitTest = 'On';
%     
%             PODSData.Handles.OFCbar2.Visible = 'On';
%     
%             PODSData.Handles.ImgPanel1.Visible = 'On';
%             PODSData.Handles.ImgPanel2.Visible = 'On';
%     
%             for i = 1:4
%                 PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
%                 PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
%             end
    
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

    UpdateImages(source);
    UpdateSummaryDisplay(source,{'Project'});
end