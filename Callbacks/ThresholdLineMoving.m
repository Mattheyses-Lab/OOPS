function [] = ThresholdLineMoving(source,ThreshLevel)

    PODSData = guidata(source);

    MainReplicate = PODSData.CurrentImage(1);

    rows = MainReplicate.Height;
    cols = MainReplicate.Width;    

    IM = MainReplicate.EnhancedImg;
    IM = IM./max(max(IM));
    bw = IM > ThreshLevel;
    
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
    MainReplicate.level = ThreshLevel;
    MainReplicate.ObjectDetectionDone = false;

%     delete(MainReplicate.Object);
%     MainReplicate.DetectObjects();

    PODSData.Handles.MaskImgH.CData = bw;
  
    UpdateTables(source);

end