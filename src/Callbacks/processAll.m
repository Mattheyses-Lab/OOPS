function processAll(source,~)

    % get data structure
    OOPSData = guidata(source);

    % total number of images in the project
    nImages = OOPSData.nImages;

    % number of groups in the project
    nGroups = OOPSData.nGroups;

    % create progress dialog
    hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Performing flat-field correction');

    % track the progress through each step
    processCounter = 0;

    % total number of processing steps to perform
    nProcesses = nImages*3;

    for groupIdx = 1:nGroups
        % get the next group
        cGroup = OOPSData.Group(groupIdx);
        % number of images in this group
        nGroupImages = cGroup.nReplicates;
        %% perform flat-field correction for each image in the group
        for imageIdx = 1:nGroupImages
            % increment the progress counter
            processCounter = processCounter + 1;
            % get the next image
            cImage = cGroup.Replicate(imageIdx);
            % update the progress dialog
            hProgressDialog.Message = ['Performing flat-field correction ',...
                '(Group ',num2str(groupIdx),'/',num2str(nGroups),...
                ', Image ',num2str(imageIdx),'/',num2str(nGroupImages),')'];
            hProgressDialog.Value = processCounter/nProcesses;
            % perform the flat-field correction for this image if not done
            if ~cImage.FFCDone
                cImage.FlatFieldCorrection();
            end
        end
        %% build mask for each image in the group
        for imageIdx = 1:nGroupImages
            % increment the progress counter
            processCounter = processCounter + 1;
            % get the next image
            cImage = cGroup.Replicate(imageIdx);
            % update the progress dialog
            hProgressDialog.Message = ['Segmenting image and detecting objects ',...
                '(Group ',num2str(groupIdx),'/',num2str(nGroups),...
                ', Image ',num2str(imageIdx),'/',num2str(nGroupImages),')'];
            hProgressDialog.Value = processCounter/nProcesses;
            % perform the flat-field correction for this image
            cImage.BuildMask();
        end
        %% compute pixel-by-pixel FPM stats for each selected image
        for imageIdx = 1:nGroupImages
            % increment the progress counter
            processCounter = processCounter + 1;
            % get the next image
            cImage = cGroup.Replicate(imageIdx);
            % update the progress dialog
            hProgressDialog.Message = ['Calculating order and orientation statistics ',...
                '(Group ',num2str(groupIdx),'/',num2str(nGroups),...
                ', Image ',num2str(imageIdx),'/',num2str(nGroupImages),')'];
            hProgressDialog.Value = processCounter/nProcesses;
            % perform the flat-field correction for this image
            if ~cImage.FPMStatsDone
                cImage.FindFPMStatistics();
            end
        end
    end

    % change to the Order Factor 'tab' if not there already
    if ~strcmp(OOPSData.Settings.CurrentTab,'Order')
        feval(OOPSData.Handles.hTabOrder.Callback,OOPSData.Handles.hTabOrder,[]);
    else
        % update displayed images (tab switching will automatically update the display)
        UpdateImages(source);
    end

    % update display
    UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});

    % update the intensity sliders
    UpdateIntensitySliders(source)

    % close the progress dialog
    close(hProgressDialog);

    % update log
    UpdateLog3(source,'Done.','append');

end