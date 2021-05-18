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
            for i = 1:4
                Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(1,i);

                Handles.FFCImgH(i).Visible = 'Off';
                Handles.FFCAxH(i).Title.Visible = 'Off';

                Handles.RawIntensityImgH(i).Visible = 'Off';
                Handles.RawIntensityAxH(i).Title.Visible = 'Off';
            end

        case 'FFC'
            for i = 1:4
                Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(2,i);

                Handles.PolFFCImgH(i).Visible = 'Off';
                Handles.PolFFCAxH(i).Title.Visible = 'Off';

                Handles.RawIntensityImgH(i).Visible = 'Off';
                Handles.RawIntensityAxH(i).Title.Visible = 'Off';
            end

        case 'Generate Mask'
            Handles.MaskImgH.Visible = 'Off';
            Handles.MaskAxH.Title.Visible = 'Off';

            for i = 1:2
                Handles.MStepsImgH(i).Visible = 'Off';
                Handles.MStepsAxH(i).Title.Visible = 'Off';

                Handles.MStepsImgH(i+2).Visible = 'Off';
                Handles.MStepsAxH(i+2).Title.Visible = 'Off';

                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'View/Adjust Mask'
            Handles.AverageIntensityImgH.Visible = 'Off';
            Handles.AverageIntensityAxH.Title.Visible = 'Off';

            Handles.MaskImgH.Visible = 'Off';
            Handles.MaskAxH.Title.Visible = 'Off';

        case 'Order Factor'
            Handles.OrderFactorImgH.Visible = 'Off';
            Handles.OrderFactorAxH.Title.Visible = 'Off';

            Handles.AverageIntensityImgH.Visible = 'Off';
            Handles.AverageIntensityAxH.Title.Visible = 'Off';

        case 'Azimuth'
            Handles.AzimuthImgH.Visible = 'Off';
            Handles.AzimuthAxH.Title.Visible = 'Off';

            Handles.AverageIntensityImgH.Visible = 'Off';
            Handles.AverageIntensityAxH.Title.Visible = 'Off';

        case 'Anisotropy'
            Handles.AnisotropyImgH.Visible = 'Off';
            Handles.AnisotropyAxH.Title.Visible = 'Off';

            Handles.AverageIntensityImgH.Visible = 'Off';
            Handles.AverageIntensityAxH.Title.Visible = 'Off';

        case 'SB-Filtering'
            Handles.SBAverageIntensityImgH.Visible = 'Off';
            Handles.SBAverageIntensityAxH.Title.Visible = 'Off';

            Handles.SBMaskImgH.Visible = 'Off';
            Handles.SBMaskAxH.Title.Visible = 'Off';
    end

    switch NewTab
        case 'Files'
            for i = 1:4
                Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(2,i);

                Handles.RawIntensityAxH(i).Title.Visible = 'On';
                Handles.RawIntensityImgH(i).Visible = 'On';

                Handles.FFCImgH(i).Visible = 'On';
                Handles.FFCAxH(i).Title.Visible = 'On';

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

                Handles.RawIntensityImgH(i).Visible = 'On';
                Handles.RawIntensityAxH(i).Title.Visible = 'On';

                Handles.SmallPanels(1,i).Visible = 'On';
                Handles.SmallPanels(2,i).Visible = 'On';
            end
            Handles.ImgPanel1.Visible = 'Off';
            Handles.ImgPanel2.Visible = 'Off';

        case 'Generate Mask'
            Handles.MaskImgH.Visible = 'On';
            Handles.MaskAxH.Title.Visible = 'On';

            Handles.ImgPanel1.Visible = 'Off';
            Handles.ImgPanel2.Visible = 'On';

            for i = 1:2
                Handles.MStepsImgH(i).Visible = 'On';
                Handles.MStepsAxH(i).Title.Visible = 'On';

                Handles.MStepsImgH(i+2).Visible = 'On';
                Handles.MStepsAxH(i+2).Title.Visible = 'On';

                Handles.SmallPanels(1,i).Visible = 'On';
                Handles.SmallPanels(2,i).Visible = 'On';

                Handles.SmallPanels(1,i+2).Visible = 'Off';
                Handles.SmallPanels(2,i+2).Visible = 'Off';
            end

        case 'View/Adjust Mask'
            Handles.AverageIntensityImgH.Visible = 'On';
            Handles.AverageIntensityAxH.Title.Visible = 'On';

            Handles.MaskImgH.Visible = 'On';
            Handles.MaskAxH.Title.Visible = 'On';

            Handles.ImgPanel1.Visible = 'On';
            Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'Order Factor'
            Handles.OrderFactorImgH.Visible = 'On';
            Handles.OrderFactorAxH.Title.Visible = 'On';

            Handles.AverageIntensityImgH.Visible = 'On';
            Handles.AverageIntensityAxH.Title.Visible = 'On';

            Handles.ImgPanel2.Visible = 'On';
            Handles.ImgPanel1.Visible = 'On';

            for i = 1:4
                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'Azimuth'
            Handles.AzimuthImgH.Visible = 'On';
            Handles.AzimuthAxH.Title.Visible = 'On';

            Handles.AverageIntensityImgH.Visible = 'On';
            Handles.AverageIntensityAxH.Title.Visible = 'On';

            Handles.ImgPanel1.Visible = 'On';
            Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'Anisotropy'
            Handles.AnisotropyImgH.Visible = 'On';
            Handles.AnisotropyAxH.Title.Visible = 'On';

            Handles.AverageIntensityImgH.Visible = 'On';
            Handles.AverageIntensityAxH.Title.Visible = 'On';

            Handles.ImgPanel1.Visible = 'On';
            Handles.ImgPanel2.Visible = 'On';

            for i = 1:4
                Handles.SmallPanels(1,i).Visible = 'Off';
                Handles.SmallPanels(2,i).Visible = 'Off';
            end

        case 'SB-Filtering'
            Handles.SBAverageIntensityImgH.Visible = 'On';
            Handles.SBAverageIntensityAxH.Title.Visible = 'On';

            Handles.SBMaskImgH.Visible = 'On';
            Handles.SBMaskAxH.Title.Visible = 'On';

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