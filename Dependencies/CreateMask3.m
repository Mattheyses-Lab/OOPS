function [] = CreateMask3(source,event)

    PODSData = guidata(source);
    cGroupIndex = PODSData.CurrentGroupIndex;
    
    cImageIndex = PODSData.Group(cGroupIndex).CurrentImageIndex;
    cReplicate = PODSData.Group(cGroupIndex).Replicate;
    
    
    if length(cImageIndex) > 1
        first = cImageIndex(1);
        last = cImageIndex(end);
    else
        first = cImageIndex;
        last = cImageIndex;
    end
    
    
    
    for i = first:last

        UpdateLog3(source,'Averaging Intensity Images...','append');
        cReplicate(i).Pol_ImAvg = mean(cReplicate(i).pol_ffc,3);

        % normalize to maximum intensity
        cReplicate(i).I = cReplicate(i).Pol_ImAvg./max(max(cReplicate(i).Pol_ImAvg));

        % use disk-shaped structuring element to calculate BG
        UpdateLog3(source,'Identifying Punctate Structures...','append');
        cReplicate(i).BGImg = imopen(cReplicate(i).I,strel('disk',5));

        % subtract BG
        UpdateLog3(source,'Subtracting Background...','append');
        cReplicate(i).BGSubtractedImg = cReplicate(i).I - cReplicate(i).BGImg;

        % median filter BG-subtracted image
        UpdateLog3(source,'Median Filtering...','append');
        cReplicate(i).MedianFilteredImg = medfilt2(cReplicate(i).BGSubtractedImg);

        % get threshold level with graythresh()
        UpdateLog3(source,'Finding Threshold...','append');
        [cReplicate(i).level,~] = graythresh(cReplicate(i).MedianFilteredImg);

        % binarize median-filtered image at level determined above
        UpdateLog3(source,'Binarizing Image...','append');
        cReplicate(i).bw = imbinarize(cReplicate(i).MedianFilteredImg,cReplicate(i).level);

        % remove small objects
        UpdateLog3(source,'Removing Objects with Area < 10 px...','append');
        cReplicate(i).bw = bwareaopen(cReplicate(i).bw, 10);
        cReplicate(i).dimensions = size(cReplicate(i).bw);
        cReplicate(i).cols = cReplicate(i).dimensions(1,2);
        cReplicate(i).rows = cReplicate(i).dimensions(1,1);

        % set 10 border px on all sides to 0, this is to speed up local BG
        % detection later on
        cReplicate(i).bw(1:10,1:end) = 0;
        cReplicate(i).bw(1:end,1:10) = 0;
        cReplicate(i).bw(cReplicate(i).rows-9:end,1:end) = 0;
        cReplicate(i).bw(1:end,cReplicate(i).cols-9:end) = 0;

    %     CC = bwconncomp(data.bw,4)
    %     S = regionprops(CC, 'Area')
    %     L = labelmatrix(CC);
    %     data.bw = ismember(L, find([S.Area] >= 10));

        [cReplicate(i).L,...
         cReplicate(i).BoundaryPixels4,...
         cReplicate(i).BoundaryPixels8,...
         cReplicate(i).bwObjectProperties,...
         cReplicate(i).nObjects] = ObjectDetection3(cReplicate(i).bw);

        UpdateLog3(source,['Threshold set to ' num2str(cReplicate(i).level)], 'append');
        UpdateLog3(source,['Generated mask representing ' num2str(cReplicate(i).nObjects) ' objects.'],'append');

        cReplicate(i).autothresh = 1;

    end
    
    PODSData.Group(cGroupIndex).Replicate = cReplicate;
    
    Handles = PODSData.Handles;
    
    % update axes with image info from first replicate in the batch
    Handles.MStepsIntensityImage.CData = PODSData.Group(cGroupIndex).Replicate(first).I;
    
    Handles.MStepsBackgroundImage.CData = PODSData.Group(cGroupIndex).Replicate(first).BGImg;
    
    Handles.MStepsBGSubtractedImage.CData = PODSData.Group(cGroupIndex).Replicate(first).BGSubtractedImg;
    Handles.MStepsBGSubtracted.CLim = [min(min(Handles.MStepsBGSubtractedImage.CData)) max(max(Handles.MStepsBGSubtractedImage.CData))];
    
    
    Handles.MStepsMedianFilteredImage.CData = PODSData.Group(cGroupIndex).Replicate(first).MedianFilteredImg;
    
    
    Handles.MaskImage.CData = PODSData.Group(cGroupIndex).Replicate(first).bw;
    Handles.AverageIntensityImgH.CData = PODSData.Group(cGroupIndex).Replicate(first).I;
    
    
    ChangePODSTab(source,'Generate Mask');
    
    PODSData.Handles = Handles;
    guidata(source,PODSData);

end