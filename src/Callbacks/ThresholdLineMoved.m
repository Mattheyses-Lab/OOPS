function [] = ThresholdLineMoved(source,ThresholdLevel)
% Once the threshold slider is moved to final position, this function will
% calculate the new mask of the currently selected image, update the display,
% then detect the new objects defined by the mask

    OOPSData = guidata(source);

    Handles = OOPSData.Handles;   
    
    % get main channel (currently selected) of current replicate
    MainReplicate = OOPSData.CurrentImage(1);

    rows = MainReplicate.Height;
    cols = MainReplicate.Width;

    switch MainReplicate.MaskName
        case 'Legacy'
            bw = MainReplicate.EnhancedImg > ThresholdLevel;
            % clear 10 px around image borders
            bw = ClearImageBorder(bw,10);    
            % remove objects < 10 px
            CC = bwconncomp(bw,4);
            S = regionprops(CC, 'Area');
            L = labelmatrix(CC);
            bw = ismember(L, find([S.Area] >= 10));
            % set the mask, label matrix, and threshold level
            MainReplicate.bw = bw;
            MainReplicate.L = bwlabel(bw,4);
            MainReplicate.level = ThresholdLevel;
            % update the log
            UpdateLog3(source,'Refining mask and updating object data...','append');
            % detect objects using the mask and label matrix
            MainReplicate.DetectObjects();
            % set ThresholdAdjusted flag
            MainReplicate.ThresholdAdjusted = true;
            % update mask display
            Handles.MaskImgH.CData = bw;
        case 'Adaptive'
            IM = MainReplicate.I;
            % build the mask with an adaptive threshold
            bw = imbinarize(IM,adaptthresh(IM,ThresholdLevel,"NeighborhoodSize",3,"Statistic","gaussian"));
            % clear 10 px around image borders
            bw = ClearImageBorder(bw,10);    
            % remove objects < 10 px
            CC = bwconncomp(bw,4);
            S = regionprops(CC, 'Area');
            L = labelmatrix(CC);
            bw = ismember(L, find([S.Area] >= 10));
            % set the mask, label matrix, and threshold level
            MainReplicate.bw = bw;
            MainReplicate.L = bwlabel(bw,4);
            MainReplicate.level = ThresholdLevel;
            % update the log
            UpdateLog3(source,'Refining mask and updating object data...','append');
            % detect objects
            MainReplicate.DetectObjects();
            % threshold has been adjusted
            MainReplicate.ThresholdAdjusted = 1;
            % update mask display
            Handles.MaskImgH.CData = bw;
        otherwise
            return
    end
    
    UpdateLog3(source,'Done.','append');
    
    UpdateObjectListBox(source);

    % % update object selection listbox
    % if MainReplicate.nObjects >= 1
    %     names = MainReplicate.ObjectNames();
    %     Handles.ObjectSelector.Items = names;
    %     Handles.ObjectSelector.ItemsData = 1:length(names);
    %     Handles.ObjectSelector.Value = MainReplicate.CurrentObjectIdx;
    % else
    %     Handles.ObjectSelector.Items = {'No objects found...'};
    % end    

    
    UpdateImages(source);
    UpdateSummaryDisplay(source,{'Group','Image','Object'});

end