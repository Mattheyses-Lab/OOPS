function loadMaskImages(source,~)

% determine what type of label matrices to build from the loaded masks
labelType = source.Tag;


% main data structure
OOPSData = guidata(source);

% current image(s) selection
cImage = OOPSData.CurrentImage;

% ensure the proper number of reference images was selected
if isempty(cImage)
    uialert(OOPSData.Handles.fH,'Load FPM stacks first','Error'); return
end

% alert dialog indicate required action
uialert(OOPSData.Handles.fH,...
    ['Select ',num2str(numel(cImage)),' mask images'],...
    'Load Mask Images',...
    'Icon','',...
    'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));
% call uiwait() on the main figure window
uiwait(OOPSData.Handles.fH);
% hide main window
OOPSData.Handles.fH.Visible = 'Off';

% load the Bio-Formats library into the MATLAB environment
% so we can call uigetfile with filters for all extensions
% supported by Bio-Formats
if bfCheckJavaPath()
    fileExtensions = bfGetFileExtensions();
else
    fileExtensions = {'*'};
end

try
    % get reference image files (single or multiple)
    [maskFiles, maskPath, ~] = uigetfile(fileExtensions,...
        ['Select ',num2str(numel(cImage)),' mask images'],...
        'MultiSelect','on',...
        OOPSData.Settings.LastDirectory);
catch
    % get reference image files (single or multiple)
    [maskFiles, maskPath, ~] = uigetfile(fileExtensions,...
        ['Select ',num2str(numel(cImage)),' mask images'],...
        'MultiSelect','on');
end


% show main window
OOPSData.Handles.fH.Visible = 'On';
% make it active
figure(OOPSData.Handles.fH);

if ~iscell(maskFiles)
    if maskFiles == 0 % if no files selected
        uialert(OOPSData.Handles.fH,'No files selected','Error'); return
    else % convert to cell array
        maskFiles = {maskFiles};
    end
end

% save recent directory
OOPSData.Settings.LastDirectory = maskPath;

% number of files selected
nFiles = numel(maskFiles);

% ensure the proper number of reference images was selected
if numel(cImage) ~= nFiles
    uialert(OOPSData.Handles.fH,'Number of mask images must match the number of FPM stacks','Error'); 
    return
end

% update log
UpdateLog3(source,['Opening ' num2str(nFiles) ' mask images...'],'append');

% create progress dialog
hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Loading mask images');

% for each image
for i=1:nFiles

    % update the progress dialog
    hProgressDialog.Message = ['Loading mask images and constructing objects ',num2str(i),'/',num2str(nFiles)];
    hProgressDialog.Value = i/nFiles;

    % get the name of this file
    rawMaskFileName = maskFiles{1,i};
    % split on the '.'
    filenameSplit = strsplit(rawMaskFileName,'.');
    % get the 'short' filename (without path and extension)
    rawMaskShortName = filenameSplit{1};
    % get the 'full' filename (with path and extension)
    rawMaskFullName = [maskPath rawMaskFileName];
    % get the file extension
    rawMaskFileType = filenameSplit{2};
    % open the image with bioformats
    bfData = bfopen(char(rawMaskFullName));
    % get the image info (pixel values and filename) from the first element of the bf cell array
    imageInfo = bfData{1,1};
    % get the image data
    rawMaskImage = imageInfo{1,1};
    % get the dimensions of the reference image
    [Height,Width] = size(rawMaskImage);
    % check for valid image dimensions
    try
        assert(isequal([Height,Width],[cImage(i).Height,cImage(i).Width]),...
            'Mask image dimensions do not match polarization image dimensions')
    catch ME
        uialert(OOPSData.Handles.fH,ME.message,'Error'); return
    end
    % get the class of the input
    rawMaskClass = class(rawMaskImage);

    % create the mask image
    bw = ClearImageBorder(imbinarize(rawMaskImage),10);

    % create label matrix from the mask
    switch labelType
        case '4conn'
            L = bwlabel(bw,4);
        case 'branches'
            [~,L] = labelBranches(bw);
    end

    % store mask image and label matrix
    cImage(i).bw = bw;
    cImage(i).L = L;

    % detect the object using mask and label matrix
    cImage(i).DetectObjects();
    % indicates mask was generated automatically or uploaded
    cImage(i).ThresholdAdjusted = false;
    % a mask exists for this replicate
    cImage(i).MaskDone = true;
    % store the type/name of the mask used
    cImage(i).MaskName = rawMaskShortName;
    cImage(i).MaskType = 'CustomUpload';

    % store info about the loaded file
    cImage(i).rawMaskClass = rawMaskClass;
    cImage(i).rawMaskFileName = rawMaskFileName;
    cImage(i).rawMaskFullName = rawMaskFullName;
    cImage(i).rawMaskShortName = rawMaskShortName;
    cImage(i).rawMaskFileType = rawMaskFileType;
    cImage(i).MaskImageLoaded = true;

    % update log to display image dimensions
    UpdateLog3(source,['Dimensions of ', ...
        char(cImage(i).rawMaskFileName), ...
        ' are ', num2str(Width), ...
        'x', num2str(Height)], ...
        'append');
end

UpdateImages(source);
UpdateSummaryDisplay(source);

% close the progress dialog
close(hProgressDialog);

% update log to indicate completion
UpdateLog3(source,'Done.','append');

end