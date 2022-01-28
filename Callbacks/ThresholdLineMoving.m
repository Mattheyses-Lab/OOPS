function [] = ThresholdLineMoving(source,ThreshLevel)

    PODSData = guidata(source);

    MainReplicate = PODSData.CurrentImage(1);
    
    IM = MainReplicate.MedianFilteredImg;
    IM = IM./max(max(IM));
    bw = IM > ThreshLevel;
    
    CC = bwconncomp(bw,4);
    S = regionprops(CC, 'Area');
    L = labelmatrix(CC);
    bw = ismember(L, find([S.Area] >= 10));    

    PODSData.Handles.MaskImgH.CData = bw;
    
    MainReplicate.bw = bw;
    MainReplicate.level = ThreshLevel;
    MainReplicate.ObjectDetectionDone = false;

    UpdateTables(source);

end