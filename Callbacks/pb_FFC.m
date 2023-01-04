function pb_FFC(source,~)
    % get data structure
    PODSData = guidata(source);
    % number of selected images
    nImages = length(PODSData.CurrentImage);
    % update log to indicate # of images we are processing
    UpdateLog3(source,['Performing flat-field correction for ',num2str(nImages),' images'],'append');
    % counter to track progress
    Counter = 1;
    % perform flat-field correction for each image
    for cImage = PODSData.CurrentImage
        % update log to indicate which image we are on
        UpdateLog3(source,['    ',cImage.pol_shortname,' (',num2str(Counter),'/',num2str(nImages),')'],'append');
        % perform the flat-field correction for this image
        cImage.FlatFieldCorrection;
        % increment the counter
        Counter = Counter+1;
    end
    % switch tabs if we are not already at the FFC tab
    if ~strcmp(PODSData.Settings.CurrentTab,'FFC')
        feval(PODSData.Handles.hTabFFC.Callback,PODSData.Handles.hTabFFC,[]);
    else
        % update displayed images (tab switching will automatically update the display)
        UpdateImages(source);
    end
    % update the summary display
    UpdateSummaryDisplay(source,{'Project','Group','Image'});
    % update the log
    UpdateLog3(source,'Done.','append');
end