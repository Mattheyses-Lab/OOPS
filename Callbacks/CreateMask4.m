function [] = CreateMask4(source,event)

    PODSData = guidata(source);
    
    chartab = '    ';

    nImages = length(PODSData.CurrentImage);
    
    UpdateLog3(source,['Building mask(s) for ',num2str(nImages),' images...'],'append');
    
    i = 1;
    % for each selected image
    for cImage = PODSData.CurrentImage
        disp('Main masking loop (time elapsed per loop):')
        tic
        % update log with status of masking
        UpdateLog3(source,[chartab,cImage.pol_shortname,' (',num2str(i),'/',num2str(nImages),')'],'append');
        % use disk-shaped structuring element to calculate BG
        cImage.BGImg = imopen(cImage.I,strel('disk',PODSData.Settings.SESize,PODSData.Settings.SELines));
        % subtract BG
        cImage.BGSubtractedImg = cImage.I - cImage.BGImg;
        % median filter BG-subtracted image
        cImage.MedianFilteredImg = medfilt2(cImage.BGSubtractedImg);
        
        %% Intensity Distribution Histogram
        % scale to 0-1
        cImage.MedianFilteredImg = cImage.MedianFilteredImg./max(max(cImage.MedianFilteredImg));
        % get bin centers and counts
%         [cImage.IntensityBinCenters,...
%             cImage.IntensityHistPlot] = BuildHistogram(cImage.MedianFilteredImg);
        % initial threshold guess using graythresh()
        [cImage.level,~] = graythresh(cImage.MedianFilteredImg);
        
        %% Build mask
        nObjects = 500;
        notfirst = logical(0);
        % Set the max nObjects to 500 by increasing the threshold until nObjects <= 500
        while nObjects >= 500
            
            % on loop iterations 2:n, double the threshold until nObjects < 500
            if notfirst
                cImage.level = cImage.level*2;
                UpdateLog3(source,[chartab,chartab,'Too many objects, adjusting thresh and trying again...'],'append');
            end
            notfirst = logical(1);
            
            % binarize median-filtered image at level determined above
            cImage.bw = sparse(imbinarize(cImage.MedianFilteredImg,cImage.level));
            
            % set 10 border px on all sides to 0, this is to speed up local BG
            % detection later on
            cImage.bw(1:10,1:end) = 0;
            cImage.bw(1:end,1:10) = 0;
            cImage.bw(cImage.Height-9:end,1:end) = 0;
            cImage.bw(1:end,cImage.Width-9:end) = 0;
            
            % remove small objects
            CC = bwconncomp(full(cImage.bw),4);
            S = regionprops(CC, 'Area');
            L = labelmatrix(CC);
            cImage.bw = sparse(ismember(L, find([S.Area] >= 10)));
            clear CC S L
            
            % generate new label matrix
            cImage.L = sparse(bwlabel(full(cImage.bw),4));
            
            % get nObjects from label matrix
            nObjects = max(max(full(cImage.L)));
            
        end
        % update log with masking output
        UpdateLog3(source,[chartab,chartab,'Threshold set to ' num2str(cImage.level)], 'append');
        UpdateLog3(source,[chartab,chartab,'Building new objects...'],'append');
        
        % delete old objects for current replicate...
        delete(cImage.Object);
        % ...so we can detect the new ones (requires bw and L to be computed previously)
        cImage.DetectObjects();
        % current object will be the first object by default
        cImage.CurrentObjectIdx = 1;
        % indicates mask was generated automatically
        cImage.ThresholdAdjusted = 0;
        % a mask exists for this replicate
        cImage.MaskDone = 1;
        
        cImage.LocalSBDone = false;
        
        UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');
        
        % end main loop timer
        toc

        % increment loop counter
        i = i+1;
    end % end iteration through images

    % invoke callback to change tab
    if ~strcmp(PODSData.Settings.CurrentTab,'View/Adjust Mask')
        feval(PODSData.Handles.hTabViewAdjustMask.Callback,PODSData.Handles.hTabViewAdjustMask,[]);
    end   

    UpdateLog3(source,'Done.','append');
    UpdateTables(source);
    UpdateImages(source);
    

end