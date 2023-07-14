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


    switch MainReplicate.MaskType
        case 'Default'
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
        case 'CustomScheme'

            customScheme = MainReplicate.CustomScheme;

            switch customScheme.ThreshType
                case 'Otsu'
                    bw = MainReplicate.EnhancedImg > ThresholdLevel;
                    % clear 10 px around image borders
                    bw = ClearImageBorder(bw,10);
                    % now check for and run any operations after the thresh step
                    if customScheme.ThreshStepIdx < customScheme.nOperations
                        customScheme.Operations(customScheme.ThreshStepIdx+1).Target.ImageData = bw;
                        customScheme.ExecuteFromStep(customScheme.ThreshStepIdx+1);
                        % if the output of the remaining steps is logical
                        if strcmp(customScheme.Images(end).ImageClass,'logical')
                            bw = customScheme.Images(end).ImageData;
                        end
                    end
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
                case 'Adaptive'
                    IM = MainReplicate.EnhancedImg;
                    % get adaptive threshold params
                    statistic = customScheme.Operations(customScheme.ThreshStepIdx).ParamsMap('Statistic');
                    neighborhoodSize = customScheme.Operations(customScheme.ThreshStepIdx).ParamsMap('NeighborhoodSize');
                    % build the adaptive mask
                    bw = imbinarize(IM,...
                        adaptthresh(IM,ThresholdLevel,...
                        "NeighborhoodSize",neighborhoodSize,...
                        "Statistic",statistic));
                    % clear 10 px around image borders
                    bw = ClearImageBorder(bw,10);
                    % now check for and run any operations after the thresh step
                    if customScheme.ThreshStepIdx < customScheme.nOperations
                        customScheme.Operations(customScheme.ThreshStepIdx+1).Target.ImageData = bw;
                        customScheme.ExecuteFromStep(customScheme.ThreshStepIdx+1);
                        % if the output of the remaining steps is logical
                        if strcmp(customScheme.Images(end).ImageClass,'logical')
                            bw = customScheme.Images(end).ImageData;
                        end
                    end
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
            end
    end
    
    UpdateLog3(source,'Done.','append');
    
    UpdateObjectListBox(source);
    
    UpdateImages(source);
    UpdateSummaryDisplay(source,{'Group','Image','Object'});

end