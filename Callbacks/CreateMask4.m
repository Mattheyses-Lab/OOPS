function [] = CreateMask4(source,~)

PODSData = guidata(source);

chartab = '    ';

nImages = length(PODSData.CurrentImage);

UpdateLog3(source,['Building mask(s) for ',num2str(nImages),' images...'],'append');

MaskMode = 'Legacy8';

i = 1;

switch MaskMode
    % DO NOT EDIT - this is the original masking strategy
    case 'Legacy'
        % main masking loop, iterates through each selected image
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
            cImage.EnhancedImg = medfilt2(cImage.BGSubtractedImg);

            %% Intensity Distribution Histogram
            % scale to 0-1
            cImage.EnhancedImg = cImage.EnhancedImg./max(max(cImage.EnhancedImg));

            % initial threshold guess using graythresh()
            [cImage.level,~] = graythresh(cImage.EnhancedImg);

            %% Build mask
            nObjects = 500;
            notfirst = false;
            % Set the max nObjects to 500 by increasing the threshold until nObjects <= 500
            while nObjects >= 500

                % on loop iterations 2:n, double the threshold until nObjects < 500
                if notfirst
                    cImage.level = cImage.level*2;
                    UpdateLog3(source,[chartab,chartab,'Too many objects, adjusting thresh and trying again...'],'append');
                end
                notfirst = true;

                % binarize median-filtered image at level determined above
                cImage.bw = sparse(imbinarize(cImage.EnhancedImg,cImage.level));

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
            %cImage.deleteObjects();
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
    % variant of the Legacy strategy, but using 8-connected objects
    case 'Legacy8'
        % main masking loop, iterates through each selected image
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
            cImage.EnhancedImg = medfilt2(cImage.BGSubtractedImg);

            %% Intensity Distribution Histogram
            % scale to 0-1
            cImage.EnhancedImg = cImage.EnhancedImg./max(max(cImage.EnhancedImg));

            % initial threshold guess using graythresh()
            [cImage.level,~] = graythresh(cImage.EnhancedImg);

            %% Build mask
            nObjects = 500;
            notfirst = false;
            % Set the max nObjects to 500 by increasing the threshold until nObjects <= 500
            while nObjects >= 500

                % on loop iterations 2:n, double the threshold until nObjects < 500
                if notfirst
                    cImage.level = cImage.level*2;
                    UpdateLog3(source,[chartab,chartab,'Too many objects, adjusting thresh and trying again...'],'append');
                end
                notfirst = true;

                % binarize median-filtered image at level determined above
                cImage.bw = sparse(imbinarize(cImage.EnhancedImg,cImage.level));

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
                cImage.L = sparse(bwlabel(full(cImage.bw),8));

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
    case 'Filament'
        SE = strel('disk',2,0);
        % main masking loop, iterates through each selected image
        for cImage = PODSData.CurrentImage
            disp('Main masking loop (time elapsed per loop):')
            tic
            % UPDATE LOG
            UpdateLog3(source,[chartab,cImage.pol_shortname,' (',num2str(i),'/',num2str(nImages),')'],'append');
            % MORPHOLOGICAL OPENING
            cImage.BGImg = imopen(cImage.I,SE);
            % SUBTRACT OPENED IMAGE
            cImage.BGSubtractedImg = cImage.I - cImage.BGImg;

            cImage.EnhancedImg = imadjust(cImage.BGSubtractedImg);
            % GUESS THRESHOLD WITH OTSU'S METHOD
            [cImage.level,~] = graythresh(cImage.EnhancedImg);
            % ADAPTIVE THRESHOLD
            AdaptiveThreshLevel = adaptthresh(cImage.EnhancedImg,0.15,...
                'Statistic','gaussian',...
                'NeighborhoodSize',3);

            %% Build mask

            % BINARIZE
            cImage.bw = sparse(imbinarize(cImage.EnhancedImg,AdaptiveThreshLevel));

            % CLEAR 10 PX BORDER
            cImage.bw = ClearImageBorder(cImage.bw,10);

            % FILTER OBJECTS WITH AREA < 100 PX
            CC = bwconncomp(full(cImage.bw),4);
            S = regionprops(CC, 'Area','Eccentricity');
            L = labelmatrix(CC);
            cImage.bw = sparse(ismember(L, find([S.Area] >= 50 & [S.Eccentricity] > 0.9)));
            clear CC S L

            % BUILD 8-CONNECTED LABEL MATRIX
            cImage.L = sparse(bwlabel(full(cImage.bw),8));

            % update log with masking output
            UpdateLog3(source,[chartab,chartab,'Threshold set to ' num2str(cImage.level)], 'append');
            UpdateLog3(source,[chartab,chartab,'Building new objects...'],'append');

            %% BUILD NEW OBJECTS
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
            % always has to be redone after object detection
            cImage.LocalSBDone = false;
            % update log
            UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');
            % end main loop timer
            toc
            % increment loop counter
            i = i+1;
        end % end iteration through images
    case 'New'
        SE = strel('disk',3,0);
        % main masking loop, iterates through each selected image
        for cImage = PODSData.CurrentImage
            disp('Main masking loop (time elapsed per loop):')
            tic
            % UPDATE LOG
            UpdateLog3(source,[chartab,cImage.pol_shortname,' (',num2str(i),'/',num2str(nImages),')'],'append');
            % MORPHOLOGICAL OPENING
            cImage.BGImg = imopen(cImage.I,SE);
            % SUBTRACT OPENED IMAGE
            cImage.BGSubtractedImg = cImage.I - cImage.BGImg;

            cImage.EnhancedImg = imadjust(cImage.BGSubtractedImg);
            % GUESS THRESHOLD WITH OTSU'S METHOD
            [cImage.level,~] = graythresh(cImage.EnhancedImg);
            % ADAPTIVE THRESHOLD
            AdaptiveThreshLevel = adaptthresh(cImage.EnhancedImg,0.15,...
                'Statistic','gaussian',...
                'NeighborhoodSize',3);

            %% Build mask

            % BINARIZE
            cImage.bw = sparse(imbinarize(cImage.EnhancedImg,AdaptiveThreshLevel));

            % CLEAR 10 PX BORDER
            cImage.bw = ClearImageBorder(cImage.bw,10);

            % FILTER OBJECTS WITH AREA < 100 PX
            CC = bwconncomp(full(cImage.bw),4);
            S = regionprops(CC, 'Area','Eccentricity');
            L = labelmatrix(CC);
            cImage.bw = sparse(ismember(L, find([S.Area] >= 10)));
            clear CC S L

            % BUILD 8-CONNECTED LABEL MATRIX
            cImage.L = sparse(bwlabel(full(cImage.bw),8));

            % update log with masking output
            UpdateLog3(source,[chartab,chartab,'Threshold set to ' num2str(cImage.level)], 'append');
            UpdateLog3(source,[chartab,chartab,'Building new objects...'],'append');

            %% BUILD NEW OBJECTS
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
            % always has to be redone after object detection
            cImage.LocalSBDone = false;
            % update log
            UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');
            % end main loop timer
            toc
            % increment loop counter
            i = i+1;
        end % end iteration through images        
end









% invoke callback to change tab
if ~strcmp(PODSData.Settings.CurrentTab,'View/Adjust Mask')
    feval(PODSData.Handles.hTabViewAdjustMask.Callback,PODSData.Handles.hTabViewAdjustMask,[]);
end

UpdateLog3(source,'Done.','append');
UpdateTables(source);
UpdateImages(source);
    
end