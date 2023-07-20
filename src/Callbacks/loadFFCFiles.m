function loadFFCFiles(source,~)

    % main data structure
    OOPSData = guidata(source);
    % group that we will be loading data for
    GroupIndex = OOPSData.CurrentGroupIndex;
    % get the current group into which we will load the image files
    cGroup = OOPSData.Group(GroupIndex);

    % add code to clear any previously loaded FFC data



    % end code to clear any previously loaded FFC data
    
    % alert box to indicate required action, closing will resume interaction on main window
    uialert(OOPSData.Handles.fH,...
        'Select .nd2 or .tif polarization stack(s)',...
        'Load flat-field image stack(s)',...
        'Icon','',...
        'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));
    % prevent interaction with the main window until we finish
    uiwait(OOPSData.Handles.fH);
    % hide main window
    OOPSData.Handles.fH.Visible = 'Off';
    
    % try to get files from the most recent directory, otherwise just use default
    try
        [FFCFiles, FFCPath, ~] = uigetfile('*.nd2',...
            'Select .nd2 or .tif flat-field stack(s)',...
            'MultiSelect','on',OOPSData.Settings.LastDirectory);
    catch
        [FFCFiles, FFCPath, ~] = uigetfile('*.nd2',...
            'Select .nd2 or .tif flat-field stack(s)',...
            'MultiSelect','on');
    end
    
    % save accessed directory
    OOPSData.Settings.LastDirectory = FFCPath;
    % show main window
    OOPSData.Handles.fH.Visible = 'On';
    % make OOPSGUI active figure
    figure(OOPSData.Handles.fH);
    
    if ~iscell(FFCFiles)
        % if no files selected
        if FFCFiles == 0
            % throw error
            error('No files selected');
        else
            % otherwise convert to cell array
            FFCFiles = {FFCFiles};
        end
    end
    
    % check how many image stacks were selected
    nFFCFiles = numel(FFCFiles);

    % update log
    UpdateLog3(source,['Opening ',num2str(nFFCFiles),' FFC images...'],'append');
    
    % preallocate some variables
    FFC_cal_shortname = cell(nFFCFiles,1);
    FFC_cal_fullname = cell(nFFCFiles,1);
    
    for i=1:nFFCFiles

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

        if nSlices ~= 4
            error('LoadFFCData:incorrectSize', ...
                ['Error while loading ', ...
                FFC_cal_fullname{i,1}, ...
                '\nFile must be a stack of four images'])
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
        else
            % throw error if dimensions of this image stack do not match those of the first one
            assert(size(rawFFCStack,1)==Height,'Dimensions of FFC files do not match');
            assert(size(rawFFCStack,2)==Width,'Dimensions of FFC files do not match');
        end

        % add this stack to our 4D array of stacks, convert to double with the same values
        rawFFCStacks(:,:,:,i) = im2double(rawFFCStack).*rawFFCRange(2);
    
        % update log to display image dimensions
        UpdateLog3(source,['Dimensions of ', ...
            FFC_cal_fullname{i,1}, ...
            ' are ', num2str(Width), ...
            ' by ', num2str(Height)], ...
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

    % update log to indicate completion
    UpdateLog3(source,'Done.','append');

    % if files tab is not current, invoke the callback we need to get there
    if ~strcmp(OOPSData.Settings.CurrentTab,'Files')
        feval(OOPSData.Handles.hTabFiles.Callback,OOPSData.Handles.hTabFiles,[]);
    end
    
    UpdateImages(source);
    UpdateSummaryDisplay(source);
    
end