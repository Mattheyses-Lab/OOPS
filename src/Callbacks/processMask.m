function processMask(source,~)

OOPSData = guidata(source);

chartab = '    ';

nImages = numel(OOPSData.CurrentImage);

UpdateLog3(source,['Building mask(s) for ',num2str(nImages),' images...'],'append');

% create progress dialog
hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Segmenting image and detecting objects');

tic

for i = 1:nImages
    % update the progress dialog
    hProgressDialog.Message = ['Segmenting image and detecting objects ',num2str(i),'/',num2str(nImages)];
    hProgressDialog.Value = i/nImages;

    % get the next image
    cImage = OOPSData.CurrentImage(i);
    % update log
    UpdateLog3(source,[chartab,cImage.rawFPMShortName,' (',num2str(i),'/',num2str(nImages),')'],'append');

    % buld the mask for the image
    cImage.BuildMask();

    % update log
    UpdateLog3(source,[chartab,chartab,num2str(cImage.nObjects) ' objects detected.'],'append');
end

elapsedTime = toc;

UpdateLog3(source,['Total time elapsed: ',num2str(elapsedTime),' s'],'append');

% change to the Mask 'tab' if not there already
if ~strcmp(OOPSData.Settings.CurrentTab,'Mask')
    feval(OOPSData.Handles.hTabMask.Callback,OOPSData.Handles.hTabMask,[]);
else
    % update displayed images (tab switching will automatically update the display)
    UpdateImages(source);
end

% update various display elements
UpdateSummaryDisplay(source);
UpdateObjectListBox(source);
UpdateThresholdSlider(source);

% close the progress dialog
close(hProgressDialog);

UpdateLog3(source,'Done.','append');
    
end