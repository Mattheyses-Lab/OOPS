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

    chartab = '    ';
    UpdateLog3(source,'Building mask(s)...','append');
    
    for i = 1:length(cImageIndex)
        ii = cImageIndex(i);
        
        UpdateLog3(source,[chartab,'Image ',num2str(i),' of ',num2str(length(cImageIndex)),'...'],'append');
        
        DiskSize = str2num(cReplicate(ii).SESize);
        DiskLines = str2num(cReplicate(ii).SELines);
        
        UpdateLog3(source,[chartab,chartab,'Averaging Intensity Images...'],'append');
        cReplicate(ii).Pol_ImAvg = mean(cReplicate(ii).pol_ffc,3);

        % normalize to maximum intensity
        cReplicate(ii).I = cReplicate(ii).Pol_ImAvg./max(max(cReplicate(ii).Pol_ImAvg));

        % use disk-shaped structuring element to calculate BG
        UpdateLog3(source,[chartab,chartab,'Identifying Punctate Structures...'],'append');
        cReplicate(ii).BGImg = imopen(cReplicate(ii).I,strel('disk',DiskSize,DiskLines));

        % subtract BG
        UpdateLog3(source,[chartab,chartab,'Subtracting Background...'],'append');
        cReplicate(ii).BGSubtractedImg = cReplicate(ii).I - cReplicate(ii).BGImg;
        
        % median filter BG-subtracted image
        UpdateLog3(source,[chartab,chartab,'Median Filtering...'],'append');
        cReplicate(ii).MedianFilteredImg = medfilt2(cReplicate(ii).BGSubtractedImg);
        
%% Intensity Distribution Histogram
        % scale to 0-1
        cReplicate(ii).MedianFilteredImg = cReplicate(ii).MedianFilteredImg./max(max(cReplicate(ii).MedianFilteredImg));
        UpdateLog3(source,[chartab,chartab,'Building Intensity Distribution Histogram...'],'append');
        
        % get bin centers and counts
        [cReplicate(ii).IntensityBinCenters,...
         cReplicate(ii).IntensityHistPlot] = BuildHistogram(cReplicate(ii).MedianFilteredImg);
%%        
        % get threshold level with graythresh()
        UpdateLog3(source,[chartab,chartab,'Finding Threshold...'],'append');
        [cReplicate(ii).level,~] = graythresh(cReplicate(ii).MedianFilteredImg);

        % binarize median-filtered image at level determined above
        UpdateLog3(source,[chartab,chartab,'Binarizing Image...'],'append');
        cReplicate(ii).bw = imbinarize(cReplicate(ii).MedianFilteredImg,cReplicate(ii).level);

        % remove small objects
        UpdateLog3(source,[chartab,chartab,'Removing Objects with Area < 10 px...'],'append');
        cReplicate(ii).bw = bwareaopen(cReplicate(ii).bw, 10);
        
        % image size
        cReplicate(ii).dimensions = size(cReplicate(ii).bw);
        cReplicate(ii).cols = cReplicate(ii).dimensions(1,2);
        cReplicate(ii).rows = cReplicate(ii).dimensions(1,1);

        % set 10 border px on all sides to 0, this is to speed up local BG
        % detection later on
        cReplicate(ii).bw(1:10,1:end) = 0;
        cReplicate(ii).bw(1:end,1:10) = 0;
        cReplicate(ii).bw(cReplicate(ii).rows-9:end,1:end) = 0;
        cReplicate(ii).bw(1:end,cReplicate(ii).cols-9:end) = 0;

    %     CC = bwconncomp(data.bw,4)
    %     S = regionprops(CC, 'Area')
    %     L = labelmatrix(CC);
    %     data.bw = ismember(L, find([S.Area] >= 10));

        % detect objects
        [cReplicate(ii).L,...
         cReplicate(ii).BoundaryPixels4,...
         cReplicate(ii).bwObjectProperties,...
         cReplicate(ii).nObjects] = ObjectDetection3(cReplicate(ii).bw);
     
     
%         % generate the new objects
%         for j = 1:cReplicate(ii).nObjects
%             cReplicate(ii).Object(j) = PODSObject(bwObjectProperties(j,:));
%             cReplicate(ii).Object(j).Name = ['Object ',num2str(j)];
%             cReplicate(ii).Object(j).OriginalIdx = j;
%             cReplicate(ii).Object(j).GroupName = PODSData.Group(cGroupIndex).GroupName;
%         end

        
        UpdateLog3(source,[chartab,chartab,'Threshold set to ' num2str(cReplicate(ii).level)], 'append');
        UpdateLog3(source,[chartab,chartab,'Generated mask representing ' num2str(cReplicate(ii).nObjects) ' objects.'],'append');

        cReplicate(ii).autothresh = 1;

    end
    
    % add replicates back to PODSData
    PODSData.Group(cGroupIndex).Replicate = cReplicate;
    
    % get gui handles
    Handles = PODSData.Handles;
    
    %% update axes with image info from first replicate in the batch
    
    % Average Intensity Image - Small
    Handles.MStepsIntensityImage.CData = PODSData.Group(cGroupIndex).Replicate(first).I;
    
    % background image
    Handles.MStepsBackgroundImage.CData = PODSData.Group(cGroupIndex).Replicate(first).BGImg;
    
    % BG-subtracted image
    Handles.MStepsBGSubtractedImage.CData = PODSData.Group(cGroupIndex).Replicate(first).BGSubtractedImg;
    Handles.MStepsBGSubtracted.CLim = [min(min(Handles.MStepsBGSubtractedImage.CData)) max(max(Handles.MStepsBGSubtractedImage.CData))];
    
    % Median-Filtered Image
    Handles.MStepsMedianFilteredImage.CData = PODSData.Group(cGroupIndex).Replicate(first).MedianFilteredImg;
    Handles.MStepsMedianFiltered.CLim = [min(min(Handles.MStepsMedianFilteredImage.CData)) max(max(Handles.MStepsMedianFilteredImage.CData))];
    
    % Binary Mask
    Handles.MaskImage.CData = PODSData.Group(cGroupIndex).Replicate(first).bw;
    
    % Average Intensity Image - Large
    Handles.AverageIntensityImgH.CData = PODSData.Group(cGroupIndex).Replicate(first).I;
    
    % Intensity Distribution Plot
    Handles.ThreshBar.XData = PODSData.Group(cGroupIndex).Replicate(first).IntensityBinCenters;
    Handles.ThreshBar.YData = PODSData.Group(cGroupIndex).Replicate(first).IntensityHistPlot;
    
    % Update thresh slider
    Handles.ThreshSlider.Value = PODSData.Group(cGroupIndex).Replicate(first).level;
    
    
    PODSData.Handles = Handles;
    guidata(source,PODSData);
    ChangePODSTab(source,'Generate Mask');
    UpdateLog3(source,'Calculating object properties...','append');
    
    
    
    
    ObjectExtraction(source,'Mask');
    
    
    
end