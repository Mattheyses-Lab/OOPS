function loadFPMImages(source,~)

    % main data structure
    OOPSData = guidata(source);
    % group that we will be loading data for
    GroupIndex = OOPSData.CurrentGroupIndex;
    % get the current group into which we will load the image files
    cGroup = OOPSData.Group(GroupIndex);
    
    % alert box to indicate required action, closing will resume interaction on main window
    uialert(OOPSData.Handles.fH,...
        'Select FPM stack(s)',...
        'Load FPM Data',...
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
        [FPMFiles, FPMPath, ~] = uigetfile(fileExtensions,...
            'Select FPM stack(s)',...
            'MultiSelect','on',...
            OOPSData.Settings.LastDirectory);
    catch
        [FPMFiles, FPMPath, ~] = uigetfile(fileExtensions,...
            'Select FPM stack(s)',...
            'MultiSelect','on');
    end


    % show main window
    OOPSData.Handles.fH.Visible = 'On';
    % make OOPSGUI active figure
    figure(OOPSData.Handles.fH);

    if ~iscell(FPMFiles)
        if FPMFiles == 0 % if no files selected
            uialert(OOPSData.Handles.fH,'No files selected','Error'); return
        else % convert to cell array
            FPMFiles = {FPMFiles};
        end
    end

    % save accessed directory
    OOPSData.Settings.LastDirectory = FPMPath;    

    % check how many image stacks were selected
    nFiles = numel(FPMFiles);

    % update log
    UpdateLog3(source,['Opening ',num2str(nFiles),' FPM stacks...'],'append');

    % create progress dialog
    hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Loading FPM stacks');

    % for each file (stack of 4 polarization images)
    for i=1:nFiles

        % update the progress dialog
        hProgressDialog.Message = ['Loading FPM stacks ',num2str(i),'/',num2str(nFiles)];
        hProgressDialog.Value = i/nFiles;

        % get the name of this file
        rawFPMFileName = FPMFiles{1,i};
        % split on the '.'
        filenameSplit = strsplit(rawFPMFileName,'.');
        % get the 'short' filename (without path and extension)
        rawFPMShortName = filenameSplit{1};
        % get the 'full' filename (with path and extension)
        rawFPMFullName = [FPMPath rawFPMFileName];
        % get the file extension
        rawFPMFileType = filenameSplit{2};

        % open the image with bioformats
        bfData = bfopen(char(rawFPMFullName));
        % get the image info (pixel values and filename) from the first element of the bf cell array
        imageInfo = bfData{1,1};

        % make sure this is a 4-image stack
        nSlices = length(imageInfo(:,1));

        % check for correct input dimensions
        try
            assert(nSlices==4,'Error while loading %s\nFile must be a stack of four images',rawFPMFullName)
        catch ME
            uialert(OOPSData.Handles.fH,ME.message,'Error'); return
        end

        % from the bfdata cell array of image data, concatenate slices along 3rd dim and convert to matrix
        rawFPMStack = cell2mat(reshape(imageInfo(1:4,1),1,1,4));
        % get the metadata structure from the fourth element of the bf cell array
        omeMeta = bfData{1,4};

        % determine the class/type of the input data
        rawFPMClass = class(rawFPMStack);
        % get the range of values in the input stack using its class
        rawFPMRange = getrangefromclass(rawFPMStack);
        % try and get the pixel dimensions from the metadata
        try
            rawFPMPixelSize = omeMeta.getPixelsPhysicalSizeX(0).value();
        catch
            rawFPMPixelSize = NaN;
            warning('Unable to detect pixel size.')
        end

        % new OOPSImage object
        cGroup.Replicate(end+1) = OOPSImage(cGroup);
        % store the handle to the new OOPSImage in a separate variable for readability below
        cImage = cGroup.Replicate(end);


        % determine the height (number of rows) of the input data
        Height = size(rawFPMStack,1);
        % determine the width (number of rows) of the input data
        Width = size(rawFPMStack,2);

        % ensure all image dimensions match those of the first image in the group
        if cImage.SelfIdx ~= 1
            try
                assert(isequal([Height,Width],size(rawFPMStack,[1 2])),'All FPM images must have the same dimensions');
            catch ME
                uialert(OOPSData.Handles.fH,ME.message,'Error'); return
            end
        end

        % store the Height
        cImage.Height = Height;
        % store the Width
        cImage.Width = Width;
        % store the name of this file (without path, with extension)
        cImage.rawFPMFileName = rawFPMFileName;
        % store the 'short' filename (without path and extension)
        cImage.rawFPMShortName = rawFPMShortName;
        % store the 'full' filename (with path and extension)
        cImage.rawFPMFullName = rawFPMFullName;
        % store the file extension
        cImage.rawFPMFileType = rawFPMFileType;
        % try and get the pixel dimensions from the metadata
        cImage.rawFPMPixelSize = rawFPMPixelSize;
        % determine the class/type of the input data
        cImage.rawFPMClass = rawFPMClass;
        % get the range of values in the input stack using its class
        cImage.rawFPMRange = rawFPMRange;
        % add the raw image data to this OOPSImage
        cImage.rawFPMStack = rawFPMStack;

        % update to know we have loaded image data
        cImage.FilesLoaded = true;
        % get the average raw image stack
        cImage.rawFPMAverage = mean(im2double(cImage.rawFPMStack),3) .* cImage.rawFPMRange(2);

        % if no FFC files have been loaded, calculate the average intensity images from the raw data
        if ~cGroup.FFCLoaded
            % simulated FFC data
            cImage.ffcFPMStack = im2double(cImage.rawFPMStack);
            % average FFC intensity
            cImage.ffcFPMAverage = cImage.rawFPMAverage;
            % normalized average FFC intensity (normalized to max)
            cImage.I = cImage.ffcFPMAverage./max(max(cImage.ffcFPMAverage));
            % done with FFC
            cImage.FFCDone = true;
        end

        % update log to display image dimensions
        UpdateLog3(source,['Dimensions of ', ...
            char(cImage.rawFPMFileName), ...
            ' are ', num2str(cImage.Width), ...
            'x', num2str(cImage.Height)], ...
            'append');
    end

    % indicate that at least one FPM file has been loaded
    cGroup.FPMFilesLoaded = true;

    % set current image to first image of channel 1, by default
    OOPSData.Group(GroupIndex).CurrentImageIndex = 1;
    % if no FFC files loaded, simulate them with a matrix of ones
    if ~cGroup.FFCLoaded
        UpdateLog3(source,'Warning: No FFC files found. Load them now if you wish to perform flat-field correction.','append');
        cGroup.FFC_cal_norm = ones(size(OOPSData.CurrentImage.rawFPMStack));
        cGroup.FFC_Height = OOPSData.CurrentImage.Height;
        cGroup.FFC_Width = OOPSData.CurrentImage.Width;
    end

    % if 'Files' isn't the current 'tab', switch to it
    if ~strcmp(OOPSData.Settings.CurrentTab,'Files')
        feval(OOPSData.Handles.hTabFiles.Callback,OOPSData.Handles.hTabFiles,[]);
    else
        % update displayed images (tab switching will automatically update the display)
        UpdateImages(source);
    end

    % update display
    UpdateImageTree(source);
    UpdateSummaryDisplay(source);

    % close the progress dialog
    close(hProgressDialog);

    % update log to indicate completion
    UpdateLog3(source,'Done.','append');    
end