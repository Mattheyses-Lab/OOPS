function loadReferenceImages(source,~)
% main data structure
OOPSData = guidata(source);
% idx to the group that we will be loading data for
GroupIndex = OOPSData.CurrentGroupIndex;

% the group we will be loading data for
cGroup = OOPSData.Group(GroupIndex);

uialert(OOPSData.Handles.fH,'Select .nd2 reference images',...
    'Load Reference Images',...
    'Icon','',...
    'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));
% call uiwait() on the main figure window
uiwait(OOPSData.Handles.fH);
% hide main window
OOPSData.Handles.fH.Visible = 'Off';

try
    % get reference image files (single or multiple)
    [referenceFiles, referencePath, ~] = uigetfile({'*.nd2','*.tif'},...
        'Select .nd2 reference images',...
        'MultiSelect','on',...
        OOPSData.Settings.LastDirectory);
catch
    % get reference image files (single or multiple)
    [referenceFiles, referencePath, ~] = uigetfile({'*.nd2','*.tif'},...
        'Select .nd2 reference images',...
        'MultiSelect','on');
end

% save recent directory
OOPSData.Settings.LastDirectory = referencePath;
% show main window
OOPSData.Handles.fH.Visible = 'On';
% make it active
figure(OOPSData.Handles.fH);

if ~iscell(referenceFiles)
    % if no files selected
    if referenceFiles == 0
        % throw error
        error('No files selected');
    else
        % otherwise convert to cell array
        referenceFiles = {referenceFiles};
    end
end

% number of files loaded
nFiles = numel(referenceFiles);

n = cGroup.nReplicates;

if n~=nFiles
    msg = 'Number of reference images must match the number of polarization stacks...';
    uialert(OOPSData.Handles.fH,msg,'Error');
    return
end

% Update Log Window
UpdateLog3(source,['Opening ' num2str(nFiles) ' reference images...'],'append');

% for each image
for i=1:nFiles
    % get the name of this file
    rawReferenceFileName = referenceFiles{1,i};
    % split on the '.'
    filenameSplit = strsplit(rawReferenceFileName,'.');
    % get the 'short' filename (without path and extension)
    rawReferenceShortName = filenameSplit{1};
    % get the 'full' filename (with path and extension)
    rawReferenceFullName = [referencePath rawReferenceFileName];
    % get the file extension
    rawReferenceFileType = filenameSplit{2};
    % open the image with bioformats
    bfData = bfopen(char(rawReferenceFullName));
    % get the image info (pixel values and filename) from the first element of the bf cell array
    imageInfo = bfData{1,1};
    % get the image data
    rawReferenceImage = imageInfo{1,1};
    % get the dimensions of the reference image
    [Height,Width] = size(rawReferenceImage);
    % check for valid image dimensions
    try
        if Height~=cGroup.Replicate(i).Height || Width~=cGroup.Replicate(i).Width
            error(['Error loading reference images' newline 'Reference image dimensions do not match polarization image dimensions']);
        end
    catch ME
        report = getReport(ME);
        uialert(OOPSData.Handles.fH,report,'Error');
        return
    end
    % get the class of the input
    rawReferenceClass = class(rawReferenceImage);

    % add all the data to the OOPSImage
    cGroup.Replicate(i).rawReferenceImage = rawReferenceImage;
    cGroup.Replicate(i).ReferenceImage = im2double(cGroup.Replicate(i).rawReferenceImage);
    cGroup.Replicate(i).rawReferenceClass = rawReferenceClass;
    cGroup.Replicate(i).rawReferenceFileName = rawReferenceFileName;
    cGroup.Replicate(i).rawReferenceFullName = rawReferenceFullName;
    cGroup.Replicate(i).rawReferenceShortName = rawReferenceShortName;
    cGroup.Replicate(i).rawReferenceFileType = rawReferenceFileType;
    cGroup.Replicate(i).ReferenceImageLoaded = true;
    cGroup.Replicate(i).ReferenceImageEnhanced = EnhanceGrayScale(cGroup.Replicate(i).ReferenceImage);
end


UpdateLog3(source,'Done.','append');
    
OOPSData.Handles.ShowReferenceImageAverageIntensity.Visible = 'On';

UpdateImages(source);
UpdateSummaryDisplay(source);
UpdateListBoxes(source);


end