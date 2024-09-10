function loadFFCImages(source,~)
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
    % group that we will be loading data for
    GroupIndex = OOPSData.CurrentGroupIndex;
    % get the current group into which we will load the image files
    cGroup = OOPSData.Group(GroupIndex);
    
    % alert box to indicate required action, closing will resume interaction on main window
    uialert(OOPSData.Handles.fH,...
        'Select flat-field stack(s)',...
        'Load FFC data',...
        'Icon','',...
        'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));
    % prevent interaction with the main window until we finish
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

    % try to get files from the most recent directory, otherwise just use default
    try
        [FFCFiles, FFCPath, ~] = uigetfile(fileExtensions,...
            'Select flat-field stack(s)',...
            'MultiSelect','on',...
            OOPSData.Settings.LastDirectory);
    catch
        [FFCFiles, FFCPath, ~] = uigetfile(fileExtensions,...
            'Select flat-field stack(s)',...
            'MultiSelect','on');
    end
    

    % show main window
    OOPSData.Handles.fH.Visible = 'On';
    % make OOPSGUI active figure
    figure(OOPSData.Handles.fH);
    
    if ~iscell(FFCFiles)
        if FFCFiles == 0 % if no files selected
            uialert(OOPSData.Handles.fH,'No files selected','Error'); return
        else % convert to cell array
            FFCFiles = {FFCFiles};
        end
    end

    % save accessed directory
    OOPSData.Settings.LastDirectory = FFCPath;

    % check how many image stacks were selected
    nFFCFiles = numel(FFCFiles);

    % preallocate some variables
    FFC_cal_shortname = cell(nFFCFiles,1);
    FFC_cal_fullname = cell(nFFCFiles,1);

    % update log
    UpdateLog3(source,['Loading ',num2str(nFFCFiles),' flat-field stacks...'],'append');
    
    % create progress dialog
    hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Loading flat-field stacks');

    
    for i=1:nFFCFiles

        % update the progress dialog
        hProgressDialog.Message = ['Loading flat-field stacks ',num2str(i),'/',num2str(nFFCFiles)];
        hProgressDialog.Value = i/nFFCFiles;        

        % get the name of this file
        filename = FFCFiles{1,i};
        % split on the '.'
        filenameSplit = strsplit(filename,'.');
        % get the 'short' filename (without path and extension)
        FFC_cal_shortname{i,1} = filenameSplit{1};
        % get the 'full' filename (with path and extension)
        FFC_cal_fullname{i,1} = [FFCPath filename];

        % open the image with bioformats
        bfData = bfopen(char(FFC_cal_fullname{i,1}));
        % get the image info (pixel values and filename) from the first element of the bf cell array
        imageInfo = bfData{1,1};

        % make sure this is a 4-image stack
        nSlices = length(imageInfo(:,1));

        try
            if nSlices ~= 4
                error('loadFFCData:incorrectSize', ...
                    ['Error while loading ', ...
                    FFC_cal_fullname{i,1}, ...
                    '\nFile must be a stack of four images']);
            end
        catch ME
            uialert(OOPSData.Handles.fH,ME.message,'Error');
            return
        end

        % from the bfdata cell array of image data, concatenate slices along 3rd dim and convert to matrix
        rawFFCStack = cell2mat(reshape(imageInfo(1:4,1),1,1,4));
        % get the metadata structure from the fourth element of the bf cell array
        %omeMeta = bfData{1,4}; % currently not used so leave commented

        % get the range of values in the input stack using its class
        rawFFCRange = getrangefromclass(rawFFCStack);

        % if this is this first file
        if i == 1
            % get the height and width of the input stack
            [Height,Width] = size(rawFFCStack,[1 2]);
            % preallocate the 4D matrix which will hold the FFC stacks
            rawFFCStacks = zeros(Height,Width,4,nFFCFiles);
        else % ensure dimensions of all FFC files match
            try
                assert(isequal(size(rawFFCStack,[1 2]),[Height,Width]),'Dimensions of flat-field images do not match');
            catch ME
                uialert(OOPSData.Handles.fH,ME.message,'Error'); return
            end
        end

        % add this stack to our 4D array of stacks, convert to double with the same values
        rawFFCStacks(:,:,:,i) = im2double(rawFFCStack).*rawFFCRange(2);
    
        % update log to display image dimensions
        UpdateLog3(source,['Dimensions of ', ...
            FFCFiles{1,i}, ...
            ' are ', num2str(Width), ...
            'x', num2str(Height)], ...
            'append');
    end

    % add short and full filenames to this OOPSGroup
    cGroup.FFC_cal_shortname = FFC_cal_shortname;
    cGroup.FFC_cal_fullname = FFC_cal_fullname;
    % store height and width of the FFC files
    cGroup.FFC_Height = Height;
    cGroup.FFC_Width = Width;

    UpdateLog3(source,'Averaging and normalizing the input...','append');

    % average the raw input stacks along the fourth dimension
    FFC_cal_average = sum(rawFFCStacks,4)./nFFCFiles;
    % normalize to the maximum value across all pixels/images in the average stack
    cGroup.FFC_cal_norm = FFC_cal_average/max(FFC_cal_average,[],"all");

    % indicate that at least one FFC file has been loaded
    cGroup.FFCLoaded = true;

    % reset the FFCDone status flag for any existing images
    for imageIdx = 1:cGroup.nReplicates
        cGroup.Replicate(imageIdx).FFCDone = false;
    end

    % if files tab is not current, invoke the callback we need to get there
    if ~strcmp(OOPSData.Settings.CurrentTab,'Files')
        feval(OOPSData.Handles.hTabFiles.Callback,OOPSData.Handles.hTabFiles,[]);
    else
        % update displayed images (tab switching will automatically update the display)
        UpdateImages(source);
    end
    
    % update display
    UpdateSummaryDisplay(source);

    % close the progress dialog
    close(hProgressDialog);

    % update log
    UpdateLog3(source,'Done.','append');    
end