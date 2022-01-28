function [] = CreateMask3(source,event)

    PODSData = guidata(source);
    % currently selected Group index
    cGroupIndex = PODSData.CurrentGroupIndex;   
    % get currently selected image(s)
    MainReplicate = PODSData.CurrentImage;

for ChIdx = 1:PODSData.nChannels
    
    % all replicate(s) for each channel
    cReplicate = PODSData.Group(cGroupIndex,ChIdx).Replicate;
    
    cImageIndex = PODSData.Group(cGroupIndex,ChIdx).CurrentImageIndex;
    
    chartab = '    ';
    UpdateLog3(source,['Building mask(s) for ',num2str(length(cImageIndex)),' images in Channel:',cReplicate(cImageIndex(1)).ChannelName,'...'],'append');    

    % for each selected image
    for i = 1:length(cImageIndex)
    disp('Main masking loop (time elapsed per loop):')
    tic        
        
        ii = cImageIndex(i);
        
        % update log with status of masking
        UpdateLog3(source,[chartab,'Image ',num2str(i),' of ',num2str(length(cImageIndex)),'...'],'append');
        
        % average the polarization stack
        cReplicate(ii).Pol_ImAvg = mean(cReplicate(ii).pol_ffc,3);
        % normalize to maximum intensity
        cReplicate(ii).I = cReplicate(ii).Pol_ImAvg./max(max(cReplicate(ii).Pol_ImAvg));
        % use disk-shaped structuring element to calculate BG
        cReplicate(ii).BGImg = imopen(cReplicate(ii).I,strel('disk',PODSData.Settings.SESize,PODSData.Settings.SELines));
        % subtract BG
        cReplicate(ii).BGSubtractedImg = cReplicate(ii).I - cReplicate(ii).BGImg;
        % median filter BG-subtracted image
        cReplicate(ii).MedianFilteredImg = medfilt2(cReplicate(ii).BGSubtractedImg);
        
%% Intensity Distribution Histogram
        % scale to 0-1
        cReplicate(ii).MedianFilteredImg = cReplicate(ii).MedianFilteredImg./max(max(cReplicate(ii).MedianFilteredImg));
        % get bin centers and counts
        [cReplicate(ii).IntensityBinCenters,...
         cReplicate(ii).IntensityHistPlot] = BuildHistogram(cReplicate(ii).MedianFilteredImg);
        % initial threshold guess using graythresh()        
        [cReplicate(ii).level,~] = graythresh(cReplicate(ii).MedianFilteredImg);

%% Build mask, for main channel only
        if ChIdx == MainReplicate(ii).SelfChannelIdx % if on primary channel, calculate mask and detect objects

            nObjects = 500;
            notfirst = logical(0);
            % Set the max nObjects to 500 by increasing the threshold until nObjects <= 500
            while nObjects >= 500

                % on loop iterations 2:n, double the threshold until nObjects < 500
                if notfirst
                    cReplicate(ii).level = cReplicate(ii).level*2;
                    UpdateLog3(source,[chartab,chartab,'Too many objects, adjusting thresh and trying again...'],'append');
                end
                notfirst = logical(1);

                % binarize median-filtered image at level determined above
                cReplicate(ii).bw = sparse(imbinarize(cReplicate(ii).MedianFilteredImg,cReplicate(ii).level));

                % set 10 border px on all sides to 0, this is to speed up local BG
                % detection later on
                cReplicate(ii).bw(1:10,1:end) = 0;
                cReplicate(ii).bw(1:end,1:10) = 0;
                cReplicate(ii).bw(cReplicate(ii).Height-9:end,1:end) = 0;
                cReplicate(ii).bw(1:end,cReplicate(ii).Width-9:end) = 0;        

                % remove small objects
                CC = bwconncomp(full(cReplicate(ii).bw),4);
                S = regionprops(CC, 'Area');
                L = labelmatrix(CC);
                cReplicate(ii).bw = sparse(ismember(L, find([S.Area] >= 10)));
                clear CC S L

                % generate new label matrix
                cReplicate(ii).L = sparse(bwlabel(full(cReplicate(ii).bw),4));

                % get nObjects from label matrix
                nObjects = max(max(full(cReplicate(ii).L)));

            end
            % update log with masking output
            UpdateLog3(source,[chartab,chartab,'Threshold set to ' num2str(cReplicate(ii).level)], 'append');        
            UpdateLog3(source,[chartab,chartab,'Building new objects for currently selected Channel (',cReplicate(ii).ChannelName,')...'],'append');
            
            % delete old objects for current replicate...
            delete(cReplicate(ii).Object);
            % ...so we can detect the new ones (requires bw and L to be computed previously)
            cReplicate(ii).DetectObjects;
            % done with object detection for now
            cReplicate(ii).ObjectDetectionDone = true;
            % current object will be the first object by default
            cReplicate(ii).CurrentObjectIdx = 1;
            % indicates mask was generated automatically
            cReplicate(ii).ThresholdAdjusted = 0;
            % a mask exists for this replicate
            cReplicate(ii).MaskDone = 1;            
            
            UpdateLog3(source,[chartab,chartab,num2str(cReplicate(ii).nObjects) ' objects detected.'],'append');
        end
        
    % end main loop timer    
    toc
    end % end iteration through images in channel

end % end iteration through channels

if PODSData.nChannels > 1
    %% Build objects from masks
    for ChIdx = 1:PODSData.nChannels

        % all replicate(s) for each channel
        cReplicate = PODSData.Group(cGroupIndex,ChIdx).Replicate;

        cImageIndex = PODSData.Group(cGroupIndex,ChIdx).CurrentImageIndex;

        for i = 1:length(cImageIndex)

            ii = cImageIndex(i);

            UpdateLog3(source,[chartab,'Image ',num2str(i),' of ',num2str(length(cImageIndex)),'...'],'append');

            if ChIdx ~= MainReplicate(ii).SelfChannelIdx
                UpdateLog3(source,[chartab,chartab,'Building objects for Channel:',cReplicate(ii).ChannelName,' from objects in Channel:',MainReplicate(ii).ChannelName,'...'],'append');
                cReplicate(ii).bw = MainReplicate(ii).bw;
                cReplicate(ii).L = MainReplicate(ii).L;
                % delete old objects for current replicate...
                delete(cReplicate(ii).Object);
                % ...so we can detect the new ones (requires bw and L to be computed previously)
                cReplicate(ii).DetectObjects;
                % done with object detection for now
                cReplicate(ii).ObjectDetectionDone = true;
                % current object will be the first object by default
                cReplicate(ii).CurrentObjectIdx = 1;
                % indicates mask was generated automatically
                cReplicate(ii).ThresholdAdjusted = 0;
                % a mask exists for this replicate
                cReplicate(ii).MaskDone = 1;
                % update log
                UpdateLog3(source,[chartab,chartab,num2str(cReplicate(ii).nObjects),'objects copied to Channel:',cReplicate(ii).ChannelName,'...'],'append');
            else
                UpdateLog3(source,[chartab,chartab,num2str(cReplicate(ii).nObjects) ' objects already detected for Channel:',cReplicate(ii).ChannelName],'append'); 
            end
        end
    end
end
    
    % invoke callback to change tab
    if ~strcmp(PODSData.Settings.CurrentTab,'View/Adjust Mask')
        feval(PODSData.Handles.hTabViewAdjustMask.Callback,PODSData.Handles.hTabViewAdjustMask,[]);
    end   

    UpdateLog3(source,'Done.','append');
    UpdateTables(source);
    UpdateImages(source);
    

end