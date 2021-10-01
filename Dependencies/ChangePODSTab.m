function [] = ChangePODSTab(source,NewTab)

    PODSData = guidata(source);
    % previous tab will become tab that was current before tab change
    PODSData.Settings.PreviousTab = PODSData.Settings.CurrentTab;
    % update current tab
    PODSData.Settings.CurrentTab = NewTab;
    
    UpdateLog3(source,[NewTab, ' Tab Selected'],'append');

    switch PODSData.Settings.PreviousTab
        
        case 'Files'
            try
                linkaxes(PODSData.Handles.FFCAxH,'off');
                linkaxes(PODSData.Handles.RawIntensityAxH,'off');
            catch
                % do nothing
            end

            for i = 1:4
                PODSData.Handles.RawIntensityAxH(i).Parent = PODSData.Handles.SmallPanels(1,i);

                PODSData.Handles.FFCImgH(i).Visible = 'Off';
                PODSData.Handles.FFCAxH(i).Title.Visible = 'Off';
                PODSData.Handles.FFCAxH(i).Toolbar.Visible = 'Off';

                PODSData.Handles.RawIntensityImgH(i).Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
            end

        case 'FFC'

            for i = 1:4
                PODSData.Handles.RawIntensityAxH(i).Parent = PODSData.Handles.SmallPanels(2,i);

                PODSData.Handles.PolFFCImgH(i).Visible = 'Off';
                PODSData.Handles.PolFFCAxH(i).Title.Visible = 'Off';
                PODSData.Handles.PolFFCAxH(i).Toolbar.Visible = 'Off';

                PODSData.Handles.RawIntensityImgH(i).Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                PODSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
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

            if ~strcmp(NewTab,'View/Adjust Mask')
                PODSData.Handles.ThreshSlider.Visible = 'Off';
                %ThreshAxH.Visible = 'Off';
                PODSData.Handles.FilterSelectorDropDown.Visible = 'Off';
                PODSData.Handles.FilterSelectorTitle.Visible = 'Off';
                PODSData.Handles.SESizeBox.Visible = 'Off';
                PODSData.Handles.SESizeBoxTitle.Visible = 'Off';
                PODSData.Handles.SELinesBox.Visible = 'Off';
                PODSData.Handles.SELinesBoxTitle.Visible = 'Off';
                PODSData.Handles.ThreshBar.Visible = 'Off';
            end

            % hide masking steps and small panels
            for i = 1:2
                PODSData.Handles.MStepsImgH(i).Visible = 'Off';
                PODSData.Handles.MStepsAxH(i).Title.Visible = 'Off';
                PODSData.Handles.MStepsAxH(i).Toolbar.Visible = 'Off';

                PODSData.Handles.MStepsImgH(i+2).Visible = 'Off';
                PODSData.Handles.MStepsAxH(i+2).Title.Visible = 'Off';
                PODSData.Handles.MStepsAxH(i+2).Toolbar.Visible = 'Off';

                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'View/Adjust Mask'
            % link large AvgIntensityAxH and MaskAxH
            try
                linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.MaskAxH],'off');
            catch
                % do nothing
            end

            PODSData.Handles.AverageIntensityImgH.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';

            if ~strcmp(NewTab,'Generate Mask')
                PODSData.Handles.ThreshSlider.Visible = 'Off';
                PODSData.Handles.FilterSelectorDropDown.Visible = 'Off';
                PODSData.Handles.FilterSelectorTitle.Visible = 'Off';
                PODSData.Handles.SESizeBox.Visible = 'Off';
                PODSData.Handles.SESizeBoxTitle.Visible = 'Off';
                PODSData.Handles.SELinesBox.Visible = 'Off';
                PODSData.Handles.SELinesBoxTitle.Visible = 'Off';
                PODSData.Handles.ThreshBar.Visible = 'Off';
            end

            PODSData.Handles.MaskImgH.Visible = 'Off';
            PODSData.Handles.MaskAxH.Title.Visible = 'Off';
            PODSData.Handles.MaskAxH.Toolbar.Visible = 'Off';

        case 'Order Factor'
            PODSData.Handles.OrderFactorImgH.Visible = 'Off';
            PODSData.Handles.OrderFactorAxH.Title.Visible = 'Off';
            PODSData.Handles.OrderFactorAxH.Toolbar.Visible = 'Off';

            PODSData.Handles.AverageIntensityImgH.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';

            PODSData.Handles.OFCbar.Visible = 'Off';

        case 'Azimuth'
            PODSData.Handles.AzimuthImgH.Visible = 'Off';
            PODSData.Handles.AzimuthAxH.Title.Visible = 'Off';
            PODSData.Handles.AzimuthAxH.Toolbar.Visible = 'Off';

            PODSData.Handles.AverageIntensityImgH.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';

        case 'Anisotropy'
            PODSData.Handles.AnisotropyImgH.Visible = 'Off';
            PODSData.Handles.AnisotropyAxH.Title.Visible = 'Off';
            PODSData.Handles.AnisotropyAxH.Toolbar.Visible = 'Off';

            PODSData.Handles.AverageIntensityImgH.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';

        case 'Filtered Order Factor'
            PODSData.Handles.SBAverageIntensityImgH.Visible = 'Off';
            PODSData.Handles.SBAverageIntensityAxH.Title.Visible = 'Off';
            PODSData.Handles.SBAverageIntensityAxH.Toolbar.Visible = 'Off';

            PODSData.Handles.FilteredOFImgH.Visible = 'Off';
            PODSData.Handles.FilteredOFAxH.Title.Visible = 'Off';
            PODSData.Handles.FilteredOFAxH.Toolbar.Visible = 'Off';
            
            PODSData.Handles.OFCbar2.Visible = 'Off';
              
    end

    switch PODSData.Settings.CurrentTab
        case 'Files'
            for i = 1:4
                PODSData.Handles.RawIntensityAxH(i).Parent = PODSData.Handles.SmallPanels(2,i);

                PODSData.Handles.RawIntensityImgH(i).Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).Title.Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';

                PODSData.Handles.FFCImgH(i).Visible = 'On';
                PODSData.Handles.FFCAxH(i).Title.Visible = 'On';
                PODSData.Handles.FFCAxH(i).Toolbar.Visible = 'On';

                PODSData.Handles.SmallPanels(1,i).Visible = 'On';
                PODSData.Handles.SmallPanels(2,i).Visible = 'On';
            end
            PODSData.Handles.ImgPanel1.Visible = 'Off';
            PODSData.Handles.ImgPanel2.Visible = 'Off';

        case 'FFC'
            for i = 1:4
                PODSData.Handles.RawIntensityAxH(i).Parent = PODSData.Handles.SmallPanels(1,i);

                PODSData.Handles.RawIntensityImgH(i).Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).Title.Visible = 'On';
                PODSData.Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';

                PODSData.Handles.PolFFCImgH(i).Visible = 'On';
                PODSData.Handles.PolFFCAxH(i).Title.Visible = 'On';
                PODSData.Handles.PolFFCAxH(i).Toolbar.Visible = 'On';

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

            if ~strcmp(PODSData.Settings.PreviousTab,'View/Adjust Mask')
                PODSData.Handles.ThreshSlider.Visible = 'On';
                %ThreshAxH.Visible = 'On';
                PODSData.Handles.ThreshBar.Visible = 'On';
                PODSData.Handles.FilterSelectorDropDown.Visible = 'On';
                PODSData.Handles.FilterSelectorTitle.Visible = 'On';
                PODSData.Handles.SESizeBox.Visible = 'On';
                PODSData.Handles.SESizeBoxTitle.Visible = 'On';
                PODSData.Handles.SELinesBox.Visible = 'On';
                PODSData.Handles.SELinesBoxTitle.Visible = 'On';

            end

            for i = 1:2
                PODSData.Handles.MStepsImgH(i).Visible = 'On';
                PODSData.Handles.MStepsAxH(i).Title.Visible = 'On';
                PODSData.Handles.MStepsAxH(i).Toolbar.Visible = 'On';

                PODSData.Handles.MStepsImgH(i+2).Visible = 'On';
                PODSData.Handles.MStepsAxH(i+2).Title.Visible = 'On';
                PODSData.Handles.MStepsAxH(i+2).Toolbar.Visible = 'On';

                PODSData.Handles.SmallPanels(1,i).Visible = 'On';
                PODSData.Handles.SmallPanels(2,i).Visible = 'On';

                PODSData.Handles.SmallPanels(1,i+2).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i+2).Visible = 'Off';
            end

            linkaxes([PODSData.Handles.MStepsAxH,PODSData.Handles.MaskAxH],'xy');

        case 'View/Adjust Mask'
            PODSData.Handles.AverageIntensityImgH.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';

            PODSData.Handles.MaskImgH.Visible = 'On';
            PODSData.Handles.MaskAxH.Title.Visible = 'On';
            PODSData.Handles.MaskAxH.Toolbar.Visible = 'On';

            PODSData.Handles.ImgPanel1.Visible = 'On';
            PODSData.Handles.ImgPanel2.Visible = 'On';

            if ~strcmp(PODSData.Settings.PreviousTab,'Generate Mask')
                PODSData.Handles.ThreshSlider.Visible = 'On';
                %ThreshAxH.Visible = 'On';
                PODSData.Handles.ThreshBar.Visible = 'On';
                PODSData.Handles.FilterSelectorDropDown.Visible = 'On';
                PODSData.Handles.FilterSelectorTitle.Visible = 'On';
                PODSData.Handles.SESizeBox.Visible = 'On';
                PODSData.Handles.SESizeBoxTitle.Visible = 'On';
                PODSData.Handles.SELinesBox.Visible = 'On';
                PODSData.Handles.SELinesBoxTitle.Visible = 'On';

            end

            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
            linkaxes([PODSData.Handles.AverageIntensityAxH,PODSData.Handles.MaskAxH],'xy');

        case 'Order Factor'
            PODSData.Handles.OrderFactorImgH.Visible = 'On';
            PODSData.Handles.OrderFactorAxH.Title.Visible = 'On';
            PODSData.Handles.OrderFactorAxH.Toolbar.Visible = 'On';

            PODSData.Handles.AverageIntensityImgH.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';

            PODSData.Handles.ImgPanel2.Visible = 'On';
            PODSData.Handles.ImgPanel1.Visible = 'On';

            PODSData.Handles.OFCbar.Visible = 'On';

            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'Azimuth'
            PODSData.Handles.AzimuthImgH.Visible = 'On';
            PODSData.Handles.AzimuthAxH.Title.Visible = 'On';
            PODSData.Handles.AzimuthAxH.Toolbar.Visible = 'On';

            PODSData.Handles.AverageIntensityImgH.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';

            PODSData.Handles.ImgPanel1.Visible = 'On';
            PODSData.Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'Anisotropy'
            PODSData.Handles.AnisotropyImgH.Visible = 'On';
            PODSData.Handles.AnisotropyAxH.Title.Visible = 'On';
            PODSData.Handles.AnisotropyAxH.Toolbar.Visible = 'On';

            PODSData.Handles.AverageIntensityImgH.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Title.Visible = 'On';
            PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'On';

            PODSData.Handles.ImgPanel1.Visible = 'On';
            PODSData.Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'Filtered Order Factor'
            PODSData.Handles.SBAverageIntensityImgH.Visible = 'On';
            PODSData.Handles.SBAverageIntensityAxH.Title.Visible = 'On';
            PODSData.Handles.SBAverageIntensityAxH.Toolbar.Visible = 'On';

            PODSData.Handles.FilteredOFImgH.Visible = 'On';
            PODSData.Handles.FilteredOFAxH.Title.Visible = 'On';
            PODSData.Handles.FilteredOFAxH.Toolbar.Visible = 'On';
            
            PODSData.Handles.OFCbar2.Visible = 'On';

            PODSData.Handles.ImgPanel1.Visible = 'On';
            PODSData.Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                PODSData.Handles.SmallPanels(1,i).Visible = 'Off';
                PODSData.Handles.SmallPanels(2,i).Visible = 'Off';
            end
    end
    
    UpdateTables(source);

end