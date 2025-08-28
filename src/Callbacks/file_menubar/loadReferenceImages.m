function loadReferenceImages(source,~)
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

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
    ['Select ',num2str(numel(cImage)),' reference images'],...
    'Load Reference Images',...
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
    [referenceFiles, referencePath, ~] = uigetfile(fileExtensions,...
        ['Select ',num2str(numel(cImage)),' reference images'],...
        'MultiSelect','on',...
        OOPSData.Settings.LastDirectory);
catch
    % get reference image files (single or multiple)
    [referenceFiles, referencePath, ~] = uigetfile(fileExtensions,...
        ['Select ',num2str(numel(cImage)),' reference images'],...
        'MultiSelect','on');
end


% show main window
OOPSData.Handles.fH.Visible = 'On';
% make it active
figure(OOPSData.Handles.fH);

if ~iscell(referenceFiles)
    if referenceFiles == 0 % if no files selected
        uialert(OOPSData.Handles.fH,'No files selected','Error'); return
    else % convert to cell array
        referenceFiles = {referenceFiles};
    end
end

% save recent directory
OOPSData.Settings.LastDirectory = referencePath;

% number of files selected
nFiles = numel(referenceFiles);

% ensure the proper number of reference images was selected
if numel(cImage) ~= nFiles
    uialert(OOPSData.Handles.fH,'Number of reference images must match the number of FPM stacks','Error'); 
    return
end

% update log
UpdateLog3(source,['Loading ' num2str(nFiles) ' reference images...'],'append');

% create progress dialog
hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Loading reference images');

% for each image
for i=1:nFiles

    % update the progress dialog
    hProgressDialog.Message = ['Loading reference images ',num2str(i),'/',num2str(nFiles)];
    hProgressDialog.Value = i/nFiles;

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
        assert(isequal([Height,Width],[cImage(i).Height,cImage(i).Width]),...
            'Reference image dimensions do not match polarization image dimensions')
    catch ME
        uialert(OOPSData.Handles.fH,ME.message,'Error'); return
    end

    % get the class of the input
    rawReferenceClass = class(rawReferenceImage);
    % get the range of values in the input stack using its class
    rawReferenceRange = getrangefromclass(rawReferenceImage);

    % add all the data to the OOPSImage
    cImage(i).rawReferenceClass = rawReferenceClass;
    cImage(i).rawReferenceRange = rawReferenceRange;
    cImage(i).rawReferenceFileName = rawReferenceFileName;
    cImage(i).rawReferenceFullName = rawReferenceFullName;
    cImage(i).rawReferenceShortName = rawReferenceShortName;
    cImage(i).rawReferenceFileType = rawReferenceFileType;
    cImage(i).rawReferenceImage = rawReferenceImage;

    referenceImageDouble = im2double(cImage(i).rawReferenceImage);
    cImage(i).ReferenceImage = referenceImageDouble./max(max(referenceImageDouble));


    %cImage(i).ReferenceImage = im2double(cImage(i).rawReferenceImage) .* cImage(i).rawReferenceRange(2);

    % update status flag
    cImage(i).ReferenceImageLoaded = true;

    % update log to display image dimensions
    UpdateLog3(source,['Dimensions of ', ...
        char(cImage(i).rawReferenceFileName), ...
        ' are ', num2str(Width), ...
        'x', num2str(Height)], ...
        'append');
end

OOPSData.Handles.ShowReferenceImageAverageIntensity.Visible = 'On';

UpdateImages(source);
UpdateSummaryDisplay(source);

% close the progress dialog
close(hProgressDialog);

% update log to indicate completion
UpdateLog3(source,'Done.','append');

end