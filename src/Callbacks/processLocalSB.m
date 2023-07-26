function processLocalSB(source,~)

    % get handle to the data structure
    OOPSData = guidata(source);

    % number of selected images
    nImages = numel(OOPSData.CurrentImage);

    % update log to indicate # of images we are processing
    UpdateLog3(source,['Detecting Local S/B for ',num2str(nImages),' images'],'append');

    % create progress dialog
    hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Calculating local S/B');

    for i = 1:nImages
        cImage = OOPSData.CurrentImage(i);
        % update the progress dialog
        hProgressDialog.Message = ['Calculating local S/B ',num2str(i),'/',num2str(nImages)];
        hProgressDialog.Value = i/nImages;
        % update log to indicate which image we are on
        UpdateLog3(source,['    ',cImage.rawFPMShortName,' (',num2str(i),'/',num2str(nImages),')'],'append');
        % detect local S/B for one image
        cImage.FindLocalSB();
        % log update to indicate we are done with this image
        UpdateLog3(source,['        Local S/B detected for ',num2str(cImage.nObjects),' objects...'],'append');
    end

    % update summary table
    UpdateSummaryDisplay(source,{'Group','Image','Object'});

    % close the progress dialog
    close(hProgressDialog);

    % update log to indicate we are done
    UpdateLog3(source,'Done.','append');    

end