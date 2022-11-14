function [] = CreateMask4(source,~)

PODSData = guidata(source);

chartab = '    ';

nImages = length(PODSData.CurrentImage);

UpdateLog3(source,['Building mask(s) for ',num2str(nImages),' images...'],'append');

MaskType = PODSData.Settings.MaskType;
MaskName = PODSData.Settings.MaskName;

i = 1;

switch MaskType
    case 'Default'
        switch MaskName
            % DO NOT EDIT - this is the original masking strategy used in BJ Paper (Dean & Mattheyses, 2022)
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
                    % scale so that max intensity is 1
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
                        cImage.bw = ClearImageBorder(cImage.bw,10);
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
                    % detect objects from the mask
                    cImage.DetectObjects();
                    % indicates mask was generated automatically
                    cImage.ThresholdAdjusted = 0;
                    % a mask exists for this replicate
                    cImage.MaskDone = 1;
                    % store the name of the mask used
                    cImage.MaskName = MaskName;
                    % update log
                    UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');
                    % end main loop timer
                    toc
                    % increment loop counter
                    i = i+1;
                end % end iteration through images
            case 'FilamentEdge'
                SE = strel('disk',2,0);
                % main masking loop, iterates through each selected image
                for cImage = PODSData.CurrentImage
                    disp('Main masking loop (time elapsed per loop):')
                    tic
                    % UPDATE LOG
                    UpdateLog3(source,[chartab,cImage.pol_shortname,' (',num2str(i),'/',num2str(nImages),')'],'append');

                    %% Enhance and find threshold
                    I = cImage.I;
                    % MORPHOLOGICAL OPENING
                    cImage.BGImg = imopen(I,SE);
                    % SUBTRACT OPENED IMAGE
                    cImage.BGSubtractedImg = I - cImage.BGImg;

                    cImage.EnhancedImg = medfilt2(cImage.EnhancedImg./max(max(cImage.EnhancedImg)));

                    %% test

                    I = cImage.I;
                    %             I = imflatfield(imtophat(I,strel('disk',3,0)),30,'FilterSize',129);

                    C = maxhessiannorm(I,4);
                    I = fibermetric(I,4,'StructureSensitivity',0.5*C);

                    % initialize super open image
                    I_superopen = zeros(size(I),'like',I);
                    % max opening with rotating line segment
                    % lower length will pick up smaller objects
                    for phi = 1:180
                        SEline = strel('line',40,phi);
                        I_superopen = max(I_superopen,imopen(I,SEline));
                    end

                    I = I_superopen;
                    cImage.EnhancedImg = I;

                    temp = ClearImageBorder(I,10);

                    %% Detect edges
                    IEdges = edge(temp,'zerocross',0);
                    % mask is the edge pixels
                    cImage.bw = sparse(IEdges);

                    %% uncomment below to fill in mask
                    % BUILD 8-CONNECTED LABEL MATRIX
                    cImage.L = sparse(bwlabel(full(cImage.bw),8));
                    % fill in outlines and recreate mask
                    bwtemp = zeros(size(cImage.bw));
                    bwempty = zeros(size(cImage.bw));
                    props = regionprops(full(cImage.L),full(cImage.bw),...
                        {'FilledImage',...
                        'SubarrayIdx'});
                    for obj_idx = 1:max(max(full(cImage.L)))
                        bwempty(props(obj_idx).SubarrayIdx{:}) = props(obj_idx).FilledImage;
                        bwtemp = bwtemp | bwempty;
                        bwempty(:) = 0;
                    end

                    cImage.bw = sparse(bwtemp);
                    %% end fill

                    % remove small objects one final time
                    CC = bwconncomp(full(cImage.bw),8);
                    S = regionprops(CC, 'Area','Eccentricity','Circularity');
                    L = labelmatrix(CC);
                    cImage.bw = sparse(ismember(L, find([S.Area] >= 5 & ...
                        [S.Eccentricity] > 0.5 & ...
                        [S.Circularity] < 0.5)));

                    cImage.L = sparse(bwlabel(full(cImage.bw),8));

                    % update log with masking output
                    UpdateLog3(source,[chartab,chartab,'Threshold set to ' num2str(cImage.level)], 'append');
                    UpdateLog3(source,[chartab,chartab,'Building new objects...'],'append');

                    %% BUILD NEW OBJECTS
                    % delete old objects for current replicate...
                    delete(cImage.Object);
                    % ...so we can detect the new ones (requires bw and L to be computed previously)
                    cImage.DetectObjects();
                    % indicates mask was generated automatically
                    cImage.ThresholdAdjusted = 0;
                    % a mask exists for this replicate
                    cImage.MaskDone = 1;
                    % store the name of the mask used
                    cImage.MaskName = MaskName;
                    % update log
                    UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');
                    % end main loop timer
                    toc
                    % increment loop counter
                    i = i+1;
                end % end iteration through images
            case 'Filament' % BEST FILAMENT SO FAR %
                SE = strel('disk',2,0);
                % main masking loop, iterates through each selected image
                for cImage = PODSData.CurrentImage
                    disp('Main masking loop (time elapsed per loop):')
                    tic
                    % UPDATE LOG
                    UpdateLog3(source,[chartab,cImage.pol_shortname,' (',num2str(i),'/',num2str(nImages),')'],'append');

                    % the default neighborhood size
                    nhoodsize = 2*floor(size(cImage.I)/16)+1;

                    % MORPHOLOGICAL OPENING
                    cImage.BGImg = imopen(cImage.I,SE);
                    % SUBTRACT OPENED IMAGE
                    cImage.BGSubtractedImg = cImage.I - cImage.BGImg;

                    I = cImage.BGSubtractedImg;

                    cImage.EnhancedImg = Scale0To1(medfilt2(I));

                    I = cImage.EnhancedImg;

                    I = imflatfield(I,30,"FilterSize",129);

                    C = maxhessiannorm(I,6);
                    I = fibermetric(I,6,"ObjectPolarity","bright","StructureSensitivity",0.5*C);

                    % initialize super open image
                    I_superopen = zeros(size(I),'like',I);
                    % max opening with rotating line segment
                    % lower length will pick up smaller objects
                    for phi = 1:180
                        SEline = strel('line',40,phi);
                        I_superopen = max(I_superopen,imopen(I,SEline));
                    end

                    I = I_superopen;

                    cImage.EnhancedImg = imadjust(imflatfield(I,30,"FilterSize",nhoodsize));

                    % GUESS THRESHOLD WITH OTSU'S METHOD
                    [cImage.level,~] = graythresh(cImage.EnhancedImg);
                    % ADAPTIVE THRESHOLD

                    AdaptiveThreshLevel = adaptthresh(cImage.EnhancedImg,cImage.level,...
                        'Statistic','gaussian',...
                        'NeighborhoodSize',nhoodsize);

                    %% Build mask

                    % BINARIZE
                    cImage.bw = sparse(imbinarize(cImage.EnhancedImg,AdaptiveThreshLevel));

                    % CLEAR 10 PX BORDER
                    cImage.bw = ClearImageBorder(cImage.bw,10);

                    BW = false(size(cImage.bw));

                    for k = 1:1:180
                        SEline = strel('line',20,k);
                        %SEline2 = strel('line',10,k);
                        BWtemp = imopen(full(cImage.bw),SEline);
                        % FILTER SLIGHTLY LARGER OBJECTS
                        CC = bwconncomp(BWtemp,4);
                        S = regionprops(CC, 'Area','Eccentricity','Circularity');
                        L = labelmatrix(CC);
                        BWtemp = sparse(ismember(L, find([S.Area] >= 40 & ...
                            [S.Eccentricity] > 0.8 & ...
                            [S.Circularity] < 0.5)));

                        %BWtemp = imclose(full(BWtemp),SEline2);

                        BW = BW+BWtemp;
                    end

                    cImage.bw = BW;

                    % dilation followed by erosion
                    %cImage.bw = imclose(full(cImage.bw),strel('disk',1,0));

                    % CLEAR 10 PX BORDER
                    cImage.bw = ClearImageBorder(cImage.bw,10);

                    % remove small objects one final time
                    CC = bwconncomp(full(cImage.bw),4);
                    S = regionprops(CC, 'Area','Eccentricity','Circularity');
                    L = labelmatrix(CC);
                    cImage.bw = sparse(ismember(L, find([S.Area] >= 40 & ...
                        [S.Eccentricity] > 0.8 & ...
                        [S.Circularity] < 0.5)));

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
                    % indicates mask was generated automatically
                    cImage.ThresholdAdjusted = 0;
                    % a mask exists for this replicate
                    cImage.MaskDone = 1;
                    % store the name of the mask used
                    cImage.MaskName = MaskName;
                    % update log
                    UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');
                    % end main loop timer
                    toc
                    % increment loop counter
                    i = i+1;
                end % end iteration through images
            case 'Intensity'
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

                    %%testing
                    %cImage.EnhancedImg = cImage.I;

                    % initial threshold guess using graythresh()
                    [cImage.level,~] = graythresh(cImage.EnhancedImg);

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

                    % update log with masking output
                    UpdateLog3(source,[chartab,chartab,'Threshold set to ' num2str(cImage.level)], 'append');
                    UpdateLog3(source,[chartab,chartab,'Building new objects...'],'append');

                    % ...so we can detect the new ones (requires bw and L to be computed previously)
                    cImage.DetectObjects();
                    % current object will be the first object by default
                    cImage.CurrentObjectIdx = 1;
                    % indicates mask was generated automatically
                    cImage.ThresholdAdjusted = 0;
                    % a mask exists for this replicate
                    cImage.MaskDone = 1;
                    % store the name of the mask used
                    cImage.MaskName = MaskName;

                    UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');

                    % end main loop timer
                    toc

                    % increment loop counter
                    i = i+1;
                end % end iteration through images
            case 'Adaptive'
                % main masking loop, iterates through each selected image
                for cImage = PODSData.CurrentImage
                    disp('Main masking loop (time elapsed per loop):')
                    tic
                    % UPDATE LOG
                    UpdateLog3(source,[chartab,cImage.pol_shortname,' (',num2str(i),'/',num2str(nImages),')'],'append');

                    % use disk-shaped structuring element to calculate BG
                    cImage.BGImg = imopen(cImage.I,strel('disk',PODSData.Settings.SESize,PODSData.Settings.SELines));
                    % subtract BG
                    cImage.BGSubtractedImg = cImage.I - cImage.BGImg;
                    % median filter BG-subtracted image
                    cImage.EnhancedImg = medfilt2(cImage.BGSubtractedImg);

                    cImage.EnhancedImg = cImage.EnhancedImg./max(max(cImage.EnhancedImg));

                    % GUESS THRESHOLD WITH OTSU'S METHOD
                    [cImage.level,~] = graythresh(cImage.I);

                    %% testing
                    %cImage.level = cImage.level*6;
                    %% end testing

                    %% Build mask
                    cImage.bw = sparse(imbinarize(cImage.I,adaptthresh(cImage.I,cImage.level,'Statistic','Gaussian','NeighborhoodSize',3)));

                    % CLEAR 10 PX BORDER
                    cImage.bw = ClearImageBorder(cImage.bw,10);

                    % FILTER OBJECTS WITH AREA < 10 PX
                    CC = bwconncomp(full(cImage.bw),4);
                    S = regionprops(CC, 'Area');
                    L = labelmatrix(CC);
                    cImage.bw = sparse(ismember(L, find([S.Area] >=10)));
                    clear CC S L

                    % BUILD 4-CONNECTED LABEL MATRIX
                    cImage.L = sparse(bwlabel(full(cImage.bw),4));

                    % update log with masking output
                    UpdateLog3(source,[chartab,chartab,'Threshold set to ' num2str(cImage.level)], 'append');
                    UpdateLog3(source,[chartab,chartab,'Building new objects...'],'append');

                    %% BUILD NEW OBJECTS
                    % ...so we can detect the new ones (requires bw and L to be computed previously)
                    cImage.DetectObjects();
                    % indicates mask was generated automatically
                    cImage.ThresholdAdjusted = 0;
                    % a mask exists for this replicate
                    cImage.MaskDone = 1;
                    % store the name of the mask used
                    cImage.MaskName = MaskName;
                    % update log
                    UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');
                    % end main loop timer
                    toc
                    i = i+1;
                end % end iteration through images
        end

    case 'CustomScheme'
        % get idx to user-defined mask scheme by searching through list of scheme names for a match
        SchemeIdx = find(ismember(PODSData.Settings.SchemeNames,MaskName));
        % load the scheme into struct() S -> should have single fieldname matching 'MaskName'
        S = load(PODSData.Settings.SchemePaths{SchemeIdx});
        % extract the scheme into a new var
        CustomScheme = S.(MaskName);
        % clear the struct
        clear S
        % make sure no residual image data stored in scheme (CustomMask object)
        CustomScheme.ClearImageData();
        % apply the scheme in a loop for each selected image
        for cImage = PODSData.CurrentImage
            disp('Main masking loop (time elapsed per loop):')
            tic
            % UPDATE LOG
            UpdateLog3(source,[chartab,cImage.pol_shortname,' (',num2str(i),'/',num2str(nImages),')'],'append');
            % set cImage.I to starting/input image of the scheme
            CustomScheme.StartingImage = cImage.I;
            % execute the scheme
            CustomScheme.Execute();
            % get the final output image (should be a logical mask image)
            cImage.bw = sparse(CustomScheme.Images(end).ImageData);
            % use the mask to build the label matrix
            cImage.L = sparse(bwlabel(full(cImage.bw),4));
            %% BUILD NEW OBJECTS
            % ...so we can detect the new ones (requires bw and L to be computed previously)
            cImage.DetectObjects();
            % indicates mask was generated automatically
            cImage.ThresholdAdjusted = 0;
            % a mask exists for this replicate
            cImage.MaskDone = 1;
            % store the name of the mask used
            cImage.MaskName = MaskName;
            % update log
            UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');
            % end loop timer
            toc
            i = i+1;
            % clear the data once more
            CustomScheme.ClearImageData();
        end
        clear CustomScheme
end


% invoke callback to change tab
if ~strcmp(PODSData.Settings.CurrentTab,'Mask')
    feval(PODSData.Handles.hTabMask.Callback,PODSData.Handles.hTabMask,[]);
end

UpdateLog3(source,'Done.','append');
UpdateSummaryDisplay(source);
UpdateObjectListBox(source);
UpdateImages(source);
    
end