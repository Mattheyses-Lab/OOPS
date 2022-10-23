function [] = ThresholdLineMoving(source,ThresholdLevel)

    PODSData = guidata(source);

    MainReplicate = PODSData.CurrentImage(1);

    rows = MainReplicate.Height;
    cols = MainReplicate.Width;

    switch PODSData.Settings.MaskType
        case 'Legacy'
            IM = MainReplicate.EnhancedImg;
            IM = IM./max(max(IM));
            bw = IM > ThresholdLevel;
            
            % clear 10 px around image borders
            bw(1:10,1:end) = 0;
            bw(1:end,1:10) = 0;
            bw(rows-9:end,1:end) = 0;
            bw(1:end,cols-9:end) = 0;
        
            % remove object smaller than 10 px
            CC = bwconncomp(bw,4);
            S = regionprops(CC, 'Area');
            L = labelmatrix(CC);
            bw = ismember(L, find([S.Area] >= 10));    
        
            MainReplicate.bw = bw;
            MainReplicate.level = ThresholdLevel;
            MainReplicate.ObjectDetectionDone = false;
        
            PODSData.Handles.MaskImgH.CData = bw;

        case 'Intensity'
            IM = MainReplicate.EnhancedImg;
            IM = IM./max(max(IM));
            bw = IM > ThresholdLevel;
        
            % clear 10 px around image borders
            bw(1:10,1:end) = 0;
            bw(1:end,1:10) = 0;
            bw(rows-9:end,1:end) = 0;
            bw(1:end,cols-9:end) = 0;    
            
            % remove objects < 10 px
            CC = bwconncomp(bw,4);
            S = regionprops(CC, 'Area');
            L = labelmatrix(CC);
            bw = ismember(L, find([S.Area] >= 10));
        
            MainReplicate.bw = bw;
            MainReplicate.level = ThresholdLevel;

            MainReplicate.ObjectDetectionDone = false;
            % update mask display
            PODSData.Handles.MaskImgH.CData = bw;
        case 'Adaptive'
            IM = MainReplicate.I;

            bw = imbinarize(IM,adaptthresh(IM,ThresholdLevel,"NeighborhoodSize",3,"Statistic","gaussian"));

            % clear 10 px around image borders
            bw(1:10,1:end) = 0;
            bw(1:end,1:10) = 0;
            bw(rows-9:end,1:end) = 0;
            bw(1:end,cols-9:end) = 0;

            % remove objects < 10 px
            CC = bwconncomp(bw,4);
            S = regionprops(CC, 'Area');
            L = labelmatrix(CC);
            bw = ismember(L, find([S.Area] >= 10));

            MainReplicate.bw = bw;
            MainReplicate.level = ThresholdLevel;

            MainReplicate.ObjectDetectionDone = false;
            % update mask display
            PODSData.Handles.MaskImgH.CData = bw;


    end

    UpdateSummaryDisplay(source,{'Group','Image'});

end