function [] = ThresholdLineMoved(source,ThresholdLevel)
% Once the threshold slider is moved to final position, this function will
% calculate the new mask of the currently selected image, update the display,
% then detect the new objects defined by the mask

    PODSData = guidata(source);
    cGroupIdx = PODSData.CurrentGroupIndex;
    cImageIdx = PODSData.Group(cGroupIdx).CurrentImageIndex;
    Handles = PODSData.Handles;
    
    if length(cImageIdx) > 1
        cImageIdx = cImageIdx(1);
    end    
    
    % get main channel (currently selected) of current replicate
    MainReplicate = PODSData.CurrentImage(1);
    
    rows = MainReplicate.Height;
    cols = MainReplicate.Width;

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
    MainReplicate.L = bwlabel(bw,4);
    MainReplicate.level = ThresholdLevel;
    
    UpdateLog3(source,'Updating Object Data...','append');
    delete(MainReplicate.Object);
    MainReplicate.DetectObjects();
    %MainReplicate.ObjectDetectionDone = true;
    
    MainReplicate.ThresholdAdjusted = 1;
    % update mask display
    Handles.MaskImgH.CData = bw;
    
    UpdateLog3(source,'Done.','append');
    
    % update object selection listbox
    if MainReplicate.nObjects >= 1
        names = MainReplicate.ObjectNames();
        Handles.ObjectSelector.Items = names;
        Handles.ObjectSelector.ItemsData = [1:length(names)];
        Handles.ObjectSelector.Value = MainReplicate.CurrentObjectIdx;
    else
        Handles.ObjectSelector.Items = {'No objects found...'};
    end    

    %guidata(source,PODSData);
    UpdateImages(source);
    UpdateTables(source);

end