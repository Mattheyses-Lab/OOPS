function [] = SliderMoved(source,event)

    PODSData = guidata(source);
    cGroupIdx = PODSData.CurrentGroupIndex;
    cImageIdx = PODSData.Group(cGroupIdx).CurrentImageIndex;
    Handles = PODSData.Handles;
    
    if length(cImageIdx) > 1
        cImageIdx = cImageIdx(1);
    end    
    
    % get current replicate
    cReplicate = PODSData.Group(cGroupIdx).Replicate(cImageIdx);
    rows = cReplicate.Height;
    cols = cReplicate.Width;

    IM = cReplicate.MedianFilteredImg;
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
    bw = sparse(ismember(L, find([S.Area] >= 10)));

    cReplicate.bw = bw;
    cReplicate.L = bwlabel(full(bw),4);
    
    UpdateLog3(source,'Refining objects...','append');
    cReplicate.Object = DetectObjects(cReplicate);
    cReplicate.ObjectDetectionDone = true;
    UpdateLog3(source,'Done.','append');
    
    cReplicate.ThresholdAdjusted = 1;
    
    % update object selection listbox
    if cReplicate.nObjects >= 1
        names = cReplicate.ObjectNames();
        Handles.ObjectSelector.Items = names;
        Handles.ObjectSelector.ItemsData = [1:length(names)];
        Handles.ObjectSelector.Value = cReplicate.CurrentObjectIdx;
    else
        Handles.ObjectSelector.Items = {'No objects found...'};
    end

%% current
%     for i = 1:cReplicate(first).nObjects
%         obj = cReplicate(first).Object(i);
%         plot(obj.Perimeter8Conn(:,2)+obj.XAdjust,...
%                  obj.Perimeter8Conn(:,1)+obj.YAdjust,...
%                  'g','LineWidth',1,...
%                  'Parent',obj.LineGroup);        
% 
%         obj.LineGroup.Parent = Handles.AverageIntensityAxH;
%     end
    
    % update PODSData w/new mask and threshold
    Handles.MaskImgH.CData = bw;
    cReplicate.level = new_level;
    
    PODSData.Handles = Handles;
    PODSData.Group(cGroupIdx).Replicate(cImageIdx) = cReplicate;

    guidata(source,PODSData);
    UpdateTables(source);

end