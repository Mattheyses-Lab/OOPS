function TabSelection(source,~)
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

    % current OOPSData structure
    OOPSData = guidata(source);
    
    % update GUI state to reflect new current/previous tabs
    OOPSData.Settings.PreviousTab = OOPSData.Settings.CurrentTab;
    OOPSData.Settings.CurrentTab = source.Text;
    
    % if ZoomToCursor is active, disable it before switching tabs
    if OOPSData.Settings.Zoom.Active
        % store the zoom properties so we can reactivate them after tab switching
        RestoreProps.freezeState = OOPSData.Settings.Zoom.Freeze;
        RestoreProps.XLimState = OOPSData.Settings.Zoom.DynamicAxes.XLim;
        RestoreProps.YLimState = OOPSData.Settings.Zoom.DynamicAxes.YLim;
        % unclick the currently pressed zoom toolbar button
        OOPSData.Settings.Zoom.CurrentButton.Value = 0;
        % invoke the callback as if user had just unchecked the button
        ZoomToCursor(OOPSData.Settings.Zoom.CurrentButton);
        % add the zoom properties to the zoom settings struct and set the restore flag
        OOPSData.Settings.Zoom.RestoreProps = RestoreProps;
        OOPSData.Settings.Zoom.Restore = true;
    end
    
    switch OOPSData.Settings.PreviousTab % the tab we are switching from
    
        case 'Files'
    
            for i = 1:4
    
                OOPSData.Handles.FFCImgH(i).Visible = 'Off';
                OOPSData.Handles.FFCAxH(i).Title.Visible = 'Off';
                OOPSData.Handles.FFCAxH(i).Toolbar.Visible = 'Off';
                OOPSData.Handles.FFCAxH(i).HitTest = 'Off';
    
                OOPSData.Handles.RawIntensityImgH(i).Visible = 'Off';
                OOPSData.Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                OOPSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
                OOPSData.Handles.RawIntensityAxH(i).HitTest = 'Off';
    
                OOPSData.Handles.SmallPanels(1,i).Visible = 'Off';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
        case 'FFC'
    
            for i = 1:4
    
                OOPSData.Handles.PolFFCImgH(i).Visible = 'Off';
                OOPSData.Handles.PolFFCAxH(i).Title.Visible = 'Off';
                OOPSData.Handles.PolFFCAxH(i).Toolbar.Visible = 'Off';
                OOPSData.Handles.PolFFCAxH(i).HitTest = 'Off';
    
                OOPSData.Handles.RawIntensityImgH(i).Visible = 'Off';
                OOPSData.Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                OOPSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
                OOPSData.Handles.RawIntensityAxH(i).HitTest = 'Off';
    
                OOPSData.Handles.SmallPanels(1,i).Visible = 'Off';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
        case 'Mask'
            % link large AvgIntensityAxH and MaskAxH
            linkaxes([OOPSData.Handles.AverageIntensityAxH,OOPSData.Handles.MaskAxH],'off');
    
            delete(OOPSData.Handles.ObjectBoxes);
            delete(OOPSData.Handles.SelectedObjectBoxes);
    
            OOPSData.Handles.AverageIntensityImgH.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.HitTest = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Visible = 'Off';
    
            OOPSData.Handles.MaskImgH.Visible = 'Off';
            OOPSData.Handles.MaskAxH.Title.Visible = 'Off';
            OOPSData.Handles.MaskAxH.Toolbar.Visible = 'Off';
            OOPSData.Handles.MaskAxH.HitTest = 'Off';
            OOPSData.Handles.MaskAxH.Visible = 'Off';

            OOPSData.Handles.AverageIntensityCbar.Visible = 'Off';
    
        case 'Order'
            % TEST in the line below
            linkaxes([OOPSData.Handles.AverageIntensityAxH,OOPSData.Handles.OrderAxH],'off');
    
            delete(OOPSData.Handles.ObjectBoxes);
            delete(OOPSData.Handles.SelectedObjectBoxes);
    
            OOPSData.Handles.OrderImgH.Visible = 'Off';
            OOPSData.Handles.OrderAxH.Title.Visible = 'Off';
            OOPSData.Handles.OrderAxH.Toolbar.Visible = 'Off';
            OOPSData.Handles.OrderAxH.HitTest = 'Off';
            OOPSData.Handles.OrderAxH.Visible = 'Off';
    
            OOPSData.Handles.AverageIntensityImgH.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.HitTest = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Visible = 'Off';
    
            OOPSData.Handles.ImgPanel1.Visible = 'Off';
    
            OOPSData.Handles.OrderCbar.Visible = 'Off';
            OOPSData.Handles.AverageIntensityCbar.Visible = 'Off';
    
        case 'Azimuth'
    
            linkaxes([OOPSData.Handles.AverageIntensityAxH,OOPSData.Handles.AzimuthAxH],'off');
    
            delete(OOPSData.Handles.AzimuthLines);
            delete(OOPSData.Handles.ObjectMidlinePlot);
    
            OOPSData.Handles.AzimuthColorbar.Visible = 'Off';

            OOPSData.Handles.AzimuthImgH.Visible = 'Off';
            OOPSData.Handles.AzimuthAxH.Title.Visible = 'Off';
            OOPSData.Handles.AzimuthAxH.Toolbar.Visible = 'Off';
            OOPSData.Handles.AzimuthAxH.HitTest = 'Off';
            OOPSData.Handles.AzimuthAxH.Visible = 'Off';
    
            OOPSData.Handles.AverageIntensityImgH.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.HitTest = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Visible = 'Off';

            OOPSData.Handles.AverageIntensityCbar.Visible = 'Off';
    
        case 'Plots'
    
            % hide the scatter plot
            OOPSData.Handles.ScatterPlotGrid.Visible = 'Off';
            delete(OOPSData.Handles.ScatterPlotAxH.Children)
    
            if isvalid(OOPSData.Handles.ScatterPlotAxH.Legend)
                OOPSData.Handles.ScatterPlotAxH.Legend.Visible = 'Off';
            end
            OOPSData.Handles.ScatterPlotAxH.Title.Visible = 'Off';
            OOPSData.Handles.ScatterPlotAxH.Toolbar.Visible = 'Off';
            OOPSData.Handles.ScatterPlotAxH.Visible = 'Off';
            OOPSData.Handles.ScatterPlotAxH.XAxis.Label.Visible = 'Off';
            OOPSData.Handles.ScatterPlotAxH.YAxis.Label.Visible = 'Off';
            OOPSData.Handles.ScatterPlotAxH.HitTest = 'Off';

            % hide the swarm plot
            OOPSData.Handles.SwarmPlot.Visible = 'Off';

        case 'Polar Plots'

            OOPSData.Handles.ImagePolarHistogram.Visible = 'Off';
            OOPSData.Handles.GroupPolarHistogram.Visible = 'Off';

        case 'Objects'
    
            % delete the object boundary plot
            delete(OOPSData.Handles.ObjectBoundaryPlot);
            % delete the object Azimuth lines
            delete(OOPSData.Handles.ObjectAzimuthLines);
            % delete the object midline plot
            delete(OOPSData.Handles.ObjectMidlinePlot);
            % delete the object intensity curves
            delete(OOPSData.Handles.ObjectIntensityPlotAxH.Children);
            % object intensity image
            OOPSData.Handles.ObjectPolFFCAxH.Title.Visible = 'Off';
            OOPSData.Handles.ObjectPolFFCImgH.Visible = 'Off';
            % object mask image
            OOPSData.Handles.ObjectMaskAxH.Title.Visible = 'Off';
            OOPSData.Handles.ObjectMaskImgH.Visible = 'Off';
            % object intensity image with azimuth lines overlay
            OOPSData.Handles.ObjectAzimuthOverlayAxH.Title.Visible = 'Off';
            OOPSData.Handles.ObjectAzimuthOverlayImgH.Visible = 'Off';
            % object Order image
            OOPSData.Handles.ObjectOrderAxH.Title.Visible = 'Off';
            OOPSData.Handles.ObjectOrderImgH.Visible = 'Off';
            % object intensity fit plot
            OOPSData.Handles.ObjectIntensityPlotAxH.Visible = 'Off';
            OOPSData.Handles.ObjectIntensityPlotAxH.HitTest = 'Off';
            % object stack-normalized intensity
            OOPSData.Handles.ObjectNormIntStackImgH.Visible = 'Off';
            OOPSData.Handles.ObjectNormIntStackAxH.Title.Visible = 'Off';
            % hide panels that were used by this tab
            OOPSData.Handles.ImgPanel2.Visible = 'Off';
    
            for i = 1:2
                OOPSData.Handles.SmallPanels(1,i).Visible = 'Off';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end

        otherwise % custom stats view

            linkaxes([OOPSData.Handles.AverageIntensityAxH,OOPSData.Handles.CustomStatAxH],'off');
    
            delete(OOPSData.Handles.ObjectBoxes);
            delete(OOPSData.Handles.SelectedObjectBoxes);
    
            OOPSData.Handles.CustomStatImgH.Visible = 'Off';
            OOPSData.Handles.CustomStatAxH.Title.Visible = 'Off';
            OOPSData.Handles.CustomStatAxH.Toolbar.Visible = 'Off';
            OOPSData.Handles.CustomStatAxH.HitTest = 'Off';
            OOPSData.Handles.CustomStatAxH.Visible = 'Off';
    
            OOPSData.Handles.AverageIntensityImgH.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
            OOPSData.Handles.AverageIntensityAxH.HitTest = 'Off';
            OOPSData.Handles.AverageIntensityAxH.Visible = 'Off';
    
            OOPSData.Handles.ImgPanel1.Visible = 'Off';
    
            OOPSData.Handles.CustomStatCbar.Visible = 'Off';
            OOPSData.Handles.AverageIntensityCbar.Visible = 'Off';
    end
    
    switch OOPSData.Settings.CurrentTab % the tab we are switching to
        case 'Files'
    
            for i = 1:4
    
                OOPSData.Handles.RawIntensityImgH(i).Visible = 'On';
                OOPSData.Handles.RawIntensityAxH(i).Title.Visible = 'On';
                OOPSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';
                OOPSData.Handles.RawIntensityAxH(i).HitTest = 'On';
    
                OOPSData.Handles.FFCImgH(i).Visible = 'On';
                OOPSData.Handles.FFCAxH(i).Title.Visible = 'On';
                OOPSData.Handles.FFCAxH(i).Toolbar.Visible = 'On';
                OOPSData.Handles.FFCAxH(i).HitTest = 'On';
    
                OOPSData.Handles.SmallPanels(1,i).Visible = 'On';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'On';
            end

            OOPSData.Handles.ImgPanel1.Visible = 'Off';
            OOPSData.Handles.ImgPanel2.Visible = 'Off';
    
        case 'FFC'
    
            for i = 1:4
    
                OOPSData.Handles.RawIntensityImgH(i).Visible = 'On';
                OOPSData.Handles.RawIntensityAxH(i).Title.Visible = 'On';
                OOPSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';
                OOPSData.Handles.RawIntensityAxH(i).HitTest = 'On';
    
                OOPSData.Handles.PolFFCImgH(i).Visible = 'On';
                OOPSData.Handles.PolFFCAxH(i).Title.Visible = 'On';
                OOPSData.Handles.PolFFCAxH(i).Toolbar.Visible = 'On';
                OOPSData.Handles.PolFFCAxH(i).HitTest = 'On';
    
                OOPSData.Handles.SmallPanels(1,i).Visible = 'On';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'On';
            end

            OOPSData.Handles.ImgPanel1.Visible = 'Off';
            OOPSData.Handles.ImgPanel2.Visible = 'Off';
    
        case 'Mask'
            OOPSData.Handles.ImgPanel1.Visible = 'On';
            OOPSData.Handles.ImgPanel2.Visible = 'On';
    
            OOPSData.Handles.AverageIntensityImgH.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.HitTest = 'On';
            OOPSData.Handles.AverageIntensityAxH.Visible = 'On';
    
            OOPSData.Handles.MaskImgH.Visible = 'On';
            OOPSData.Handles.MaskAxH.Title.Visible = 'On';
            OOPSData.Handles.MaskAxH.Toolbar.Visible = 'On';
            OOPSData.Handles.MaskAxH.HitTest = 'On';
            OOPSData.Handles.MaskAxH.Visible = 'On';

            % OOPSData.Handles.AverageIntensityCbar.Visible = 'On';
    
            for i = 1:4
                OOPSData.Handles.SmallPanels(1,i).Visible = 'Off';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
            try
                linkaxes([OOPSData.Handles.AverageIntensityAxH,OOPSData.Handles.MaskAxH],'xy');
            catch
                warning('Failed to link average intensity and mask axes');
            end
    
        case 'Order'
    
            OOPSData.Handles.OrderImgH.Visible = 'On';
            OOPSData.Handles.OrderAxH.Title.Visible = 'On';
            OOPSData.Handles.OrderAxH.Toolbar.Visible = 'On';
            OOPSData.Handles.OrderAxH.HitTest = 'On';
            OOPSData.Handles.OrderAxH.Visible = 'On';
    
            OOPSData.Handles.AverageIntensityImgH.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.HitTest = 'On';
            OOPSData.Handles.AverageIntensityAxH.Visible = 'On';
    
            OOPSData.Handles.ImgPanel2.Visible = 'On';
            OOPSData.Handles.ImgPanel1.Visible = 'On';
    
            for i = 1:4
                OOPSData.Handles.SmallPanels(1,i).Visible = 'Off';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
            try
                linkaxes([OOPSData.Handles.AverageIntensityAxH,OOPSData.Handles.OrderAxH],'xy');
            catch
                warning('Failed to link average intensity and order factor axes');
            end
    
        case 'Azimuth'
    
            OOPSData.Handles.AzimuthImgH.Visible = 'On';
            OOPSData.Handles.AzimuthAxH.Title.Visible = 'On';
            OOPSData.Handles.AzimuthAxH.Toolbar.Visible = 'On';
            OOPSData.Handles.AzimuthAxH.HitTest = 'On';
            OOPSData.Handles.AzimuthAxH.Visible = 'On';
    
            OOPSData.Handles.AverageIntensityImgH.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.HitTest = 'On';
            OOPSData.Handles.AverageIntensityAxH.Visible = 'On';
    
            OOPSData.Handles.ImgPanel1.Visible = 'On';
            OOPSData.Handles.ImgPanel2.Visible = 'On';

            % OOPSData.Handles.AverageIntensityCbar.Visible = 'On';
    
            for i = 1:4
                OOPSData.Handles.SmallPanels(1,i).Visible = 'Off';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
            try
                linkaxes([OOPSData.Handles.AverageIntensityAxH,OOPSData.Handles.AzimuthAxH],'xy');
            catch
                warning('Failed to link average intensity and azimuth axes')
            end
    
        case 'Plots'
    
            if isvalid(OOPSData.Handles.ScatterPlotAxH.Legend)
                OOPSData.Handles.ScatterPlotAxH.Legend.Visible = 'On';
            end
    
            OOPSData.Handles.ScatterPlotGrid.Visible = 'On';
            OOPSData.Handles.ScatterPlotAxH.Title.Visible = 'On';
            OOPSData.Handles.ScatterPlotAxH.Toolbar.Visible = 'On';
            OOPSData.Handles.ScatterPlotAxH.Visible = 'On';
            OOPSData.Handles.ScatterPlotAxH.XAxis.Label.Visible = 'On';
            OOPSData.Handles.ScatterPlotAxH.YAxis.Label.Visible = 'On';
            OOPSData.Handles.ScatterPlotAxH.HitTest = 'On';

            OOPSData.Handles.SwarmPlot.Visible = 'On';

            OOPSData.Handles.ImgPanel1.Visible = 'On';
            OOPSData.Handles.ImgPanel2.Visible = 'On';
    
            for i = 1:4
                OOPSData.Handles.SmallPanels(1,i).Visible = 'Off';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'Polar Plots'

            OOPSData.Handles.ImagePolarHistogram.Visible = 'On';
            OOPSData.Handles.ImgPanel1.Visible = 'On';

            OOPSData.Handles.GroupPolarHistogram.Visible = 'On';
            OOPSData.Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                OOPSData.Handles.SmallPanels(1,i).Visible = 'Off';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
        case 'Objects'
    
            % object intensity image
            OOPSData.Handles.ObjectPolFFCAxH.Title.Visible = 'On';
            OOPSData.Handles.ObjectPolFFCImgH.Visible = 'On';
    
            % object binary image
            OOPSData.Handles.ObjectMaskAxH.Title.Visible = 'On';
            OOPSData.Handles.ObjectMaskImgH.Visible = 'On';
    
            OOPSData.Handles.ObjectAzimuthOverlayAxH.Title.Visible = 'On';
            OOPSData.Handles.ObjectAzimuthOverlayImgH.Visible = 'On';
    
            OOPSData.Handles.ObjectOrderAxH.Title.Visible = 'On';
            OOPSData.Handles.ObjectOrderImgH.Visible = 'On';
    
            OOPSData.Handles.ObjectNormIntStackImgH.Visible = 'On';
            OOPSData.Handles.ObjectNormIntStackAxH.Title.Visible = 'On';
    
            OOPSData.Handles.ObjectIntensityPlotAxH.Visible = 'On';
            OOPSData.Handles.ObjectIntensityPlotAxH.HitTest = 'On';
    
            OOPSData.Handles.ImgPanel2.Visible = 'On';
    
            for i = 1:2
                OOPSData.Handles.SmallPanels(1,i).Visible = 'On';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'On';
            end
    
            OOPSData.Handles.ImgPanel1.Visible = 'Off';

        otherwise % custom stats view

            OOPSData.Handles.CustomStatImgH.Visible = 'On';
            OOPSData.Handles.CustomStatAxH.Title.Visible = 'On';
            OOPSData.Handles.CustomStatAxH.Toolbar.Visible = 'On';
            OOPSData.Handles.CustomStatAxH.HitTest = 'On';
            OOPSData.Handles.CustomStatAxH.Visible = 'On';
    
            OOPSData.Handles.AverageIntensityImgH.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
            OOPSData.Handles.AverageIntensityAxH.HitTest = 'On';
            OOPSData.Handles.AverageIntensityAxH.Visible = 'On';
    
            OOPSData.Handles.ImgPanel2.Visible = 'On';
            OOPSData.Handles.ImgPanel1.Visible = 'On';
    
            OOPSData.Handles.CustomStatCbar.Visible = 'On';
            OOPSData.Handles.AverageIntensityCbar.Visible = 'On';
    
            for i = 1:4
                OOPSData.Handles.SmallPanels(1,i).Visible = 'Off';
                OOPSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    
            try
                linkaxes([OOPSData.Handles.AverageIntensityAxH,OOPSData.Handles.CustomStatAxH],'xy');
            catch
                warning('Failed to link average intensity and custom stat axes');
            end

    end

    zoomableTabs = [{'Mask','Order','Azimuth'},OOPSData.Settings.CustomStatisticDisplayNames.'];

    % if the restore flag is set and the selected tab is zoomable
    if OOPSData.Settings.Zoom.Restore && ismember(OOPSData.Settings.CurrentTab,zoomableTabs)
        % set the button to active in the axes for which we will activate zoom (average intensity axes)
        OOPSData.Handles.ZoomToCursorAverageIntensity.Value = 1;
        % restore zoom on the average intensity axes (easiest for now as it is in all zoomable tabs)
        ZoomToCursor(OOPSData.Handles.ZoomToCursorAverageIntensity);
    end
    % now remove the restore properties and unset the restore flag
    OOPSData.Settings.Zoom.RestoreProps = [];
    OOPSData.Settings.Zoom.Restore = false;

    % % testing below
    UpdateIntensitySliders(source);

    % end testing
    UpdateImages(source);
    UpdateSummaryDisplay(source,{'Project'});
end