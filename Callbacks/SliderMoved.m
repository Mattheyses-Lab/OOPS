function [] = SliderMoved(source,event)

    PODSData = guidata(source);
    cGroupIdx = PODSData.CurrentGroupIndex;
    cImageIdx = PODSData.Group(cGroupIdx).CurrentImageIndex;
    
    rows = PODSData.Group(cGroupIdx).Replicate(cImageIdx).Height;
    cols = PODSData.Group(cGroupIdx).Replicate(cImageIdx).Width;
    
    if length(cImageIdx) > 1
        cImageIdx = cImageIdx(1);
    end    
    
    
    IM = PODSData.Group(cGroupIdx).Replicate(cImageIdx).MedianFilteredImg;
    IM = IM./max(max(IM));
    new_level = event.Value;
    bw = IM > new_level;
    
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
    
    
    
    
    PODSData.Group(cGroupIdx).Replicate(cImageIdx).bw = bw;
    
    [PODSData.Group(cGroupIdx).Replicate(cImageIdx).L,...
     PODSData.Group(cGroupIdx).Replicate(cImageIdx).BoundaryPixels4,...
     PODSData.Group(cGroupIdx).Replicate(cImageIdx).bwObjectProperties,...
     PODSData.Group(cGroupIdx).Replicate(cImageIdx).nObjects] = ObjectDetection3(PODSData.Group(cGroupIdx).Replicate(cImageIdx).bw);    
    
    % update PODSData w/new mask and threshold
    PODSData.Handles.MaskImgH.CData = bw;
    PODSData.Group(cGroupIdx).Replicate(cImageIdx).level = new_level;    

    guidata(source,PODSData);
    UpdateTables(source);
    UpdateLog3(source,'Refining Object Parameters...','append');
    ObjectExtraction(source,'Mask');
    
    try
        ObjectExtraction(source,'Order Factor');
    catch
        UpdateLog3(source,'No Order Factor Data Found...','append');
    end

end