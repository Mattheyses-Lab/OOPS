function [] = ThresholdLineMoved(source,ThresholdLevel)
% Once the threshold slider is moved to final position, this function will
% calculate the new mask of the currently selected image, update the display,
% then detect the new objects defined by the mask

    PODSData = guidata(source);

    Handles = PODSData.Handles;   
    
    % get main channel (currently selected) of current replicate
    MainReplicate = PODSData.CurrentImage(1);

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
        
            MainReplicate.bw = bw;
            MainReplicate.L = bwlabel(bw,4);
            MainReplicate.level = ThresholdLevel;

            % update the log
            UpdateLog3(source,'Updating object data...','append');
            % detect objects using the mask and label matrix
            MainReplicate.DetectObjects();
            % set ThresholdAdjusted flag
            MainReplicate.ThresholdAdjusted = true;
            % update mask display
            Handles.MaskImgH.CData = bw;
        case 'Intensity'
            IM = MainReplicate.EnhancedImg;
            IM = IM./max(max(IM));
            bw = IM > ThresholdLevel;
        
            % clear 10 px around image borders
            bw = ClearImageBorder(bw,10);    
            
            % remove objects < 10 px
            CC = bwconncomp(bw,4);
            S = regionprops(CC, 'Area');
            L = labelmatrix(CC);
            bw = ismember(L, find([S.Area] >= 10));
        
            MainReplicate.bw = bw;
            MainReplicate.L = bwlabel(bw,4);
            MainReplicate.level = ThresholdLevel;
            
            UpdateLog3(source,'Updating object data...','append');

            MainReplicate.DetectObjects();

            MainReplicate.ThresholdAdjusted = 1;
            % update mask display
            Handles.MaskImgH.CData = bw;

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
            MainReplicate.L = bwlabel(bw,4);
            MainReplicate.level = ThresholdLevel;

            UpdateLog3(source,'Refining mask...','append');
            
            UpdateLog3(source,'Updating object data...','append');

            MainReplicate.DetectObjects();

            MainReplicate.ThresholdAdjusted = 1;
            % update mask display
            Handles.MaskImgH.CData = bw;
        case 'AdaptiveFilament'
            bw = MainReplicate.EnhancedImg > ThresholdLevel;
            % clear 10 px around image borders
            bw = ClearImageBorder(bw,10);    
            % remove objects < 10 px
            CC = bwconncomp(bw,4);
            S = regionprops(CC, 'Area');
            L = labelmatrix(CC);
            bw = ismember(L, find([S.Area] >= 10));
            % set the mask
            MainReplicate.bw = bw;
            % set the level
            MainReplicate.level = ThresholdLevel;
            % update log
            UpdateLog3(source,'Refining mask...','append');
            % fill in gaps to remove diagonally connected pixels, keep only the pixels we added
            diagFill = bwmorph(full(MainReplicate.bw),'diag',1)-full(MainReplicate.bw);
            % now get an image with just the pixels that were originally connected
            diagFill = bwmorph(diagFill,'diag',1)-diagFill;
            % set those pixels to 0
            MainReplicate.bw(diagFill==1) = 0;
            % label individual branches
            [~,MainReplicate.L] = labelBranches(full(MainReplicate.bw));
            % update log again
            UpdateLog3(source,'Updating object data...','append');
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
    
    % update object selection listbox
    if MainReplicate.nObjects >= 1
        names = MainReplicate.ObjectNames();
        Handles.ObjectSelector.Items = names;
        Handles.ObjectSelector.ItemsData = 1:length(names);
        Handles.ObjectSelector.Value = MainReplicate.CurrentObjectIdx;
    else
        Handles.ObjectSelector.Items = {'No objects found...'};
    end    

    
    UpdateImages(source);
    UpdateSummaryDisplay(source,{'Group','Image','Object'});

end