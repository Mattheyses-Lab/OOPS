function processFPMStats(source,~)
    % get handle to the data structure
    OOPSData = guidata(source);
    
    % number of selected images
    nImages = length(OOPSData.CurrentImage);
    % update log to indicate # of images we are processing
    UpdateLog3(source,['Computing order statistics statistics for ',num2str(nImages),' images'],'append');
    % counter to track progress
    Counter = 1;
    % start a timer
    tic
    % compute pixel-by-pixel FPM stats for each selected image
    for cImage = OOPSData.CurrentImage
        % update log to indicate which image we are on
        UpdateLog3(source,['    ',cImage.rawFPMShortName,' (',num2str(Counter),'/',num2str(nImages),')'],'append');
        % compute the FPM stats
        cImage.FindOrderFactor();
    
        % testing below - additional FPM stats
        cImage.ComputeFPMStats();
        % end testing
        % increment the counter
        Counter = Counter+1;
    end
    % end the timer and save the time
    timeElapsed = toc;
    % change to the Order Factor 'tab' if not there already
    if ~strcmp(OOPSData.Settings.CurrentTab,'Order Factor')
        feval(OOPSData.Handles.hTabOrderFactor.Callback,OOPSData.Handles.hTabOrderFactor,[]);
    else
        % update displayed images (tab switching will automatically update the display)
        UpdateImages(source);
    end
    % update summary table
    UpdateSummaryDisplay(source,{'Group','Image','Object'});
    % update log with time elapsed
    UpdateLog3(source,['Time elapsed: ',num2str(timeElapsed),' seconds'],'append');
    % update log to indicate we are done
    UpdateLog3(source,'Done.','append');

end