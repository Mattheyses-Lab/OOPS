function processLocalSB(source,~)
    % get handle to the data structure
    OOPSData = guidata(source);

    % number of selected images
    nImages = length(OOPSData.CurrentImage);
    % update log to indicate # of images we are processing
    UpdateLog3(source,['Detecting Local S/B for ',num2str(nImages),' images'],'append');
    % counter to track which image we're on
    Counter = 1;
    for cImage = OOPSData.CurrentImage
        % update log to indicate which image we are on
        UpdateLog3(source,['    ',cImage.rawFPMShortName,' (',num2str(Counter),'/',num2str(nImages),')'],'append');
        % detect local S/B for one image
        cImage.FindLocalSB();
        % log update to indicate we are done with this image
        UpdateLog3(source,['        Local S/B detected for ',num2str(cImage.nObjects),' objects...'],'append');
        % increment counter
        Counter = Counter+1;
    end
    % update log to indicate we are done
    UpdateLog3(source,'Done.','append');
    % update summary table
    UpdateSummaryDisplay(source,{'Group','Image','Object'});

end