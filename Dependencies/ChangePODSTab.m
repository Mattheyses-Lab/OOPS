function [] = ChangePODSTab(source,NewTab)

    % get PODSData
    PODSData = guidata(source);
    Handles = PODSData.Handles;

    % figure out what the old tab was
    OldTab = PODSData.Settings.CurrentTab;
    
    % Update PODSData Settings to reflect new tab choice
    PODSData.Settings.CurrentTab = NewTab;
    PODSData.Settings.PreviousTab = OldTab;

    switch OldTab
        case 'Files'
            try  
                linkaxes(FFCAxH,'off');
                linkaxes(RawIntensityAxH,'off');             
            catch
                
            end
            
            
            for i = 1:4
                Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(1,i);

                Handles.FFCImgH(i).Visible = 'Off';
                Handles.FFCAxH(i).Title.Visible = 'Off';
                Handles.FFCAxH(i).Toolbar.Visible = 'Off';

                Handles.RawIntensityImgH(i).Visible = 'Off';
                Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
            end
            
            
            

        case 'FFC'
            for i = 1:4
                Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(2,i);

                Handles.PolFFCImgH(i).Visible = 'Off';
                Handles.PolFFCAxH(i).Title.Visible = 'Off';
                Handles.PolFFCAxH(i).Toolbar.Visible = 'Off';

                Handles.RawIntensityImgH(i).Visible = 'Off';
                Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
            end

        case 'Generate Mask'
            try
                linkaxes([Handles.MStepsAxH,Handles.MaskAxH],'off');
            catch
                % do nothing
            end
            
            Handles.MaskImgH.Visible = 'Off';
            Handles.MaskAxH.Title.Visible = 'Off';
            Handles.MaskAxH.Toolbar.Visible = 'Off';

            for i = 1:2
                Handles.MStepsImgH(i).Visible = 'Off';
                Handles.MStepsAxH(i).Title.Visible = 'Off';
                Handles.MStepsAxH(i).Toolbar.Visible = 'Off';

                Handles.MStepsImgH(i+2).Visible = 'Off';
                Handles.MStepsAxH(i+2).Title.Visible = 'Off';
                Handles.MStepsAxH(i+2).Toolbar.Visible = 'Off';

                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end
            
            if ~strcmp(NewTab,'View/Adjust Mask')
                Handles.ThreshSlider.Visible = 'Off';
                Handles.ThreshAxH.Visible = 'Off';
                Handles.FilterSelectorDropDown.Visible = 'Off';
                Handles.FilterSelectorTitle.Visible = 'Off';
                Handles.SESizeBox.Visible = 'Off';
                Handles.SESizeBoxTitle.Visible = 'Off';
                Handles.SELinesBox.Visible = 'Off';
                Handles.SELinesBoxTitle.Visible = 'Off';
                Handles.ThreshBar.Visible = 'Off';         
            end  

        case 'View/Adjust Mask'
            try
                linkaxes([Handles.AverageIntensityAxH,Handles.MaskAxH],'off');
            catch
                % do nothing
            end
            
            Handles.AverageIntensityImgH.Visible = 'Off';
            Handles.AverageIntensityAxH.Title.Visible = 'Off';
            Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
            
            Handles.MaskImgH.Visible = 'Off';
            Handles.MaskAxH.Title.Visible = 'Off';
            Handles.MaskAxH.Toolbar.Visible = 'Off';

            if ~strcmp(NewTab,'Generate Mask')
                Handles.ThreshSlider.Visible = 'Off';
                Handles.ThreshAxH.Visible = 'Off';
                Handles.FilterSelectorDropDown.Visible = 'Off';
                Handles.FilterSelectorTitle.Visible = 'Off';
                Handles.SESizeBox.Visible = 'Off';
                Handles.SESizeBoxTitle.Visible = 'Off';
                Handles.SELinesBox.Visible = 'Off';
                Handles.SELinesBoxTitle.Visible = 'Off';
                Handles.ThreshBar.Visible = 'Off';
            end
            
            

        case 'Order Factor'
            Handles.OrderFactorImgH.Visible = 'Off';
            Handles.OrderFactorAxH.Title.Visible = 'Off';
            Handles.OrderFactorAxH.Toolbar.Visible = 'Off';

            Handles.AverageIntensityImgH.Visible = 'Off';
            Handles.AverageIntensityAxH.Title.Visible = 'Off';
            Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
            
            Handles.OFCbar.Visible = 'Off';

        case 'Azimuth'
            Handles.AzimuthImgH.Visible = 'Off';
            Handles.AzimuthAxH.Title.Visible = 'Off';
            Handles.AzimuthAxH.Toolbar.Visible = 'Off';

            Handles.AverageIntensityImgH.Visible = 'Off';
            Handles.AverageIntensityAxH.Title.Visible = 'Off';
            Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';

        case 'Anisotropy'
            Handles.AnisotropyImgH.Visible = 'Off';
            Handles.AnisotropyAxH.Title.Visible = 'Off';
            Handles.AnisotropyAxH.Toolbar.Visible = 'Off';

            Handles.AverageIntensityImgH.Visible = 'Off';
            Handles.AverageIntensityAxH.Title.Visible = 'Off';
            Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';

        case 'SB-Filtering'
            Handles.SBAverageIntensityImgH.Visible = 'Off';
            Handles.SBAverageIntensityAxH.Title.Visible = 'Off';
            Handles.SBAverageIntensityAxH.Toolbar.Visible = 'Off';

            Handles.SBMaskImgH.Visible = 'Off';
            Handles.SBMaskAxH.Title.Visible = 'Off';
            Handles.SBMaskAxH.Toolbar.Visible = 'Off';
    end

    switch NewTab
        case 'Files'
            for i = 1:4
                Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(2,i);
                
                Handles.RawIntensityImgH(i).Visible = 'On';
                Handles.RawIntensityAxH(i).Title.Visible = 'On';
                Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';

                Handles.FFCImgH(i).Visible = 'On';
                Handles.FFCAxH(i).Title.Visible = 'On';
                Handles.FFCAxH(i).Toolbar.Visible = 'On';

                Handles.SmallPanels(1,i).Visible = 'On';
                Handles.SmallPanels(2,i).Visible = 'On';
            end
            Handles.ImgPanel1.Visible = 'Off';
            Handles.ImgPanel2.Visible = 'Off';

        case 'FFC'
            for i = 1:4
                Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(1,i);

                Handles.PolFFCImgH(i).Visible = 'On';
                Handles.PolFFCAxH(i).Title.Visible = 'On';
                Handles.PolFFCAxH(i).Toolbar.Visible = 'On';

                Handles.RawIntensityImgH(i).Visible = 'On';
                Handles.RawIntensityAxH(i).Title.Visible = 'On';
                Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';

                Handles.SmallPanels(1,i).Visible = 'On';
                Handles.SmallPanels(2,i).Visible = 'On';
            end
            Handles.ImgPanel1.Visible = 'Off';
            Handles.ImgPanel2.Visible = 'Off';

        case 'Generate Mask'
            

            Handles.MaskImgH.Visible = 'On';
            Handles.MaskAxH.Title.Visible = 'On';
            Handles.MaskAxH.Toolbar.Visible = 'On';

            Handles.ImgPanel1.Visible = 'Off';
            Handles.ImgPanel2.Visible = 'On';

            for i = 1:2
                Handles.MStepsImgH(i).Visible = 'On';
                Handles.MStepsAxH(i).Title.Visible = 'On';
                Handles.MStepsAxH(i).Toolbar.Visible = 'On';

                Handles.MStepsImgH(i+2).Visible = 'On';
                Handles.MStepsAxH(i+2).Title.Visible = 'On';
                Handles.MStepsAxH(i+2).Toolbar.Visible = 'On';

                Handles.SmallPanels(1,i).Visible = 'On';
                Handles.SmallPanels(2,i).Visible = 'On';

                Handles.SmallPanels(1,i+2).Visible = 'Off';
                Handles.SmallPanels(2,i+2).Visible = 'Off';
            end
            if ~strcmp(OldTab,'View/Adjust Mask')
                Handles.ThreshSlider.Visible = 'On';
                Handles.ThreshBar.Visible = 'On';
                Handles.FilterSelectorDropdown.Visible = 'On';
                Handles.FilterSelectorTitle.Visible = 'On';
                Handles.SESizeBox.Visible = 'On';
                Handles.SESizeBoxTitle.Visible = 'On';
                Handles.SELinesBox.Visible = 'On';
                Handles.SELinesBoxTitle.Visible = 'On';
            end
            
            linkaxes([Handles.MStepsAxH,Handles.MaskAxH],'xy');
            
            
            

        case 'View/Adjust Mask'
            linkaxes([Handles.AverageIntensityAxH,Handles.MaskAxH],'xy');
            
            Handles.AverageIntensityImgH.Visible = 'On';
            Handles.AverageIntensityAxH.Title.Visible = 'On';
            Handles.AverageIntensityAxH.Toolbar.Visible = 'On';

            Handles.MaskImgH.Visible = 'On';
            Handles.MaskAxH.Title.Visible = 'On';
            Handles.MaskAxH.Toolbar.Visible = 'On';

            Handles.ImgPanel1.Visible = 'On';
            Handles.ImgPanel2.Visible = 'On';
            
            Handles.ThreshSlider.Visible = 'On';           
            Handles.ThreshBar.Visible = 'On';

            for i = 1:4
                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end
            
            if ~strcmp(OldTab,'Generate Mask')
                Handles.ThreshSlider.Visible = 'On';
                Handles.ThreshBar.Visible = 'On';
                Handles.FilterSelectorDropdown.Visible = 'On';
                Handles.FilterSelectorTitle.Visible = 'On';
                Handles.SESizeBox.Visible = 'On';
                Handles.SESizeBoxTitle.Visible = 'On';
                Handles.SELinesBox.Visible = 'On';
                Handles.SELinesBoxTitle.Visible = 'On';
            end            
            
            

        case 'Order Factor'
            Handles.OrderFactorImgH.Visible = 'On';
            Handles.OrderFactorAxH.Title.Visible = 'On';
            Handles.OrderFactorAxH.Toolbar.Visible = 'On';

            Handles.AverageIntensityImgH.Visible = 'On';
            Handles.AverageIntensityAxH.Title.Visible = 'On';
            Handles.AverageIntensityAxH.Toolbar.Visible = 'On';

            Handles.ImgPanel2.Visible = 'On';
            Handles.ImgPanel1.Visible = 'On';
            
            Handles.OFCbar.Visible = 'On';            

            for i = 1:4
                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'Azimuth'
            Handles.AzimuthImgH.Visible = 'On';
            Handles.AzimuthAxH.Title.Visible = 'On';
            Handles.AzimuthAxH.Toolbar.Visible = 'On';

            Handles.AverageIntensityImgH.Visible = 'On';
            Handles.AverageIntensityAxH.Title.Visible = 'On';
            Handles.AverageIntensityAxH.Toolbar.Visible = 'On';

            Handles.ImgPanel1.Visible = 'On';
            Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'Anisotropy'
            Handles.AnisotropyImgH.Visible = 'On';
            Handles.AnisotropyAxH.Title.Visible = 'On';
            Handles.AnisotropyAxH.Toolbar.Visible = 'On';

            Handles.AverageIntensityImgH.Visible = 'On';
            Handles.AverageIntensityAxH.Title.Visible = 'On';
            Handles.AverageIntensityAxH.Toolbar.Visible = 'On';

            Handles.ImgPanel1.Visible = 'On';
            Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'SB-Filtering'
            Handles.SBAverageIntensityImgH.Visible = 'On';
            Handles.SBAverageIntensityAxH.Title.Visible = 'On';
            Handles.SBAverageIntensityAxH.Toolbar.Visible = 'On';

            Handles.SBMaskImgH.Visible = 'On';
            Handles.SBMaskAxH.Title.Visible = 'On';
            Handles.SBMaskAxH.Toolbar.Visible = 'On';

            Handles.ImgPanel1.Visible = 'On';
            Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end
    end
    
    PODSData.Handles = Handles;
    guidata(source,PODSData);


end