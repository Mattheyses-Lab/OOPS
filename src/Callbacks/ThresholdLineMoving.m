function [] = ThresholdLineMoving(source,ThresholdLevel)

    OOPSData = guidata(source);

    MainReplicate = OOPSData.CurrentImage(1);

    rows = MainReplicate.Height;
    cols = MainReplicate.Width;

    switch MainReplicate.MaskName
        case 'Legacy'
            %IM = MainReplicate.EnhancedImg;

            bw = MainReplicate.EnhancedImg > ThresholdLevel;
            
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
        
            OOPSData.Handles.MaskImgH.CData = bw;
        case 'Adaptive'
            IM = MainReplicate.I;

            bw = imbinarize(IM,adaptthresh(IM,ThresholdLevel,"NeighborhoodSize",3,"Statistic","gaussian"));

            % clear 10 px around image borders
            bw = ClearImageBorder(bw,10);

            % remove objects < 10 px
            CC = bwconncomp(bw,4);
            S = regionprops(CC, 'Area');
            L = labelmatrix(CC);
            bw = ismember(L, find([S.Area] >= 10));

            MainReplicate.bw = bw;
            MainReplicate.level = ThresholdLevel;

            MainReplicate.ObjectDetectionDone = false;
            % update mask display
            OOPSData.Handles.MaskImgH.CData = bw;
        otherwise
            return
    end

    UpdateSummaryDisplay(source,{'Group','Image','DataOnly'});

end