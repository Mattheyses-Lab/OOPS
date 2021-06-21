function [] = SliderMoving(source,event)
    PODSData = guidata(source);
    cGroupIdx = PODSData.CurrentGroupIndex;
    cImageIdx = PODSData.Group(cGroupIdx).CurrentImageIndex;
    
    if length(cImageIdx) > 1
        cImageIdx = cImageIdx(1);
    end
    
    IM = PODSData.Group(cGroupIdx).Replicate(cImageIdx).MedianFilteredImg;
    IM = IM./max(max(IM));
    new_level = event.Value;
    bw = IM > new_level;
    
    CC = bwconncomp(bw,4)
    S = regionprops(CC, 'Area')
    L = labelmatrix(CC);
    bw = ismember(L, find([S.Area] >= 10));    

    PODSData.Handles.MaskImgH.CData = bw;
    
    PODSData.Group(cGroupIdx).Replicate(cImageIdx).bw = bw;
    PODSData.Group(cGroupIdx).Replicate(cImageIdx).level = new_level;    

    guidata(source,PODSData);
    UpdateTables(source);


end