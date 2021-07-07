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
    
    % for each selected image
    for i = 1:length(cImageIndex)
        ii = cImageIndex(i);
        
        UpdateLog3(source,[chartab,'Image ',num2str(i),' of ',num2str(length(cImageIndex)),'...'],'append');
        
        UpdateLog3(source,[chartab,chartab,'Averaging Intensity Images...'],'append');
        cReplicate(ii).Pol_ImAvg = mean(cReplicate(ii).pol_ffc,3);

        % normalize to maximum intensity
        cReplicate(ii).I = cReplicate(ii).Pol_ImAvg./max(max(cReplicate(ii).Pol_ImAvg));

        % use disk-shaped structuring element to calculate BG
        UpdateLog3(source,[chartab,chartab,'Identifying Punctate Structures...'],'append');
        cReplicate(ii).BGImg = imopen(cReplicate(ii).I,strel('disk',str2num(cReplicate(ii).SESize),str2num(cReplicate(ii).SELines)));

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
        % initial threshold guess using graythresh()
        UpdateLog3(source,[chartab,chartab,'Finding Threshold...'],'append');
        
        [cReplicate(ii).level,~] = graythresh(cReplicate(ii).MedianFilteredImg);

        
%% Set the max nObjects to 500 by increasing the threshold until nObjects <= 500        
        nObjects = 500;
        notfirst = logical(0);
        
        while nObjects >= 500
            
            if notfirst
                cReplicate(ii).level = cReplicate(ii).level*2;
                UpdateLog3(source,[chartab,chartab,'Too many objects, adjusting thresh and trying again...'],'append');
            end
            notfirst = logical(1);

            % binarize median-filtered image at level determined above
            UpdateLog3(source,[chartab,chartab,'Binarizing Image...'],'append');
            cReplicate(ii).bw = imbinarize(cReplicate(ii).MedianFilteredImg,cReplicate(ii).level);

            % set 10 border px on all sides to 0, this is to speed up local BG
            % detection later on
            cReplicate(ii).bw(1:10,1:end) = 0;
            cReplicate(ii).bw(1:end,1:10) = 0;
            cReplicate(ii).bw(cReplicate(ii).Height-9:end,1:end) = 0;
            cReplicate(ii).bw(1:end,cReplicate(ii).Width-9:end) = 0;        

            % remove small objects
            UpdateLog3(source,[chartab,chartab,'Removing Objects with Area < 10 px...'],'append');
            %cReplicate(ii).bw = bwareaopen(full(cReplicate(ii).bw), 10);
            CC = bwconncomp(cReplicate(ii).bw,4)
            S = regionprops(CC, 'Area')
            L = labelmatrix(CC);
            cReplicate(ii).bw = sparse(ismember(L, find([S.Area] >= 10)));

            % generate new label matrix
            cReplicate(ii).L = sparse(bwlabel(full(cReplicate(ii).bw),4));

            % get nObjects from label matrix
            nObjects = max(max(cReplicate(ii).L));
        
        end

        %cReplicate(ii).Object = DetectObjects(cReplicate(ii));
        
        % test
        cReplicate(ii).Object = DetectObjects(cReplicate(ii));
        cReplicate(ii).ObjectDetectionDone = true;
        
        cReplicate(ii).CurrentObjectIdx = 1;
        
        UpdateLog3(source,[chartab,chartab,'Threshold set to ' num2str(cReplicate(ii).level)], 'append');
        UpdateLog3(source,[chartab,chartab,'Generated mask representing ' num2str(cReplicate(ii).nObjects) ' objects.'],'append');

        cReplicate(ii).ThresholdAdjusted = 0;
        
        cReplicate(ii).MaskDone = 1;

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

    % add replicates back to PODSData
    PODSData.Group(cGroupIndex).Replicate = cReplicate;   

    PODSData.Handles = Handles;
    guidata(source,PODSData);
    ChangePODSTab(source,'View/Adjust Mask');
    UpdateLog3(source,'Done.','append');

end