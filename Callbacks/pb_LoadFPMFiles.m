function [] = pb_LoadFPMFiles(source,~)

    % main data structure
    PODSData = guidata(source);
    % group that we will be loading data for
    GroupIndex = PODSData.CurrentGroupIndex;
    % user-selected input file type (.nd2 or .tif)
    InputFileType = PODSData.Settings.InputFileType;
    % get the current group into which we will load the image files
    cGroup = PODSData.Group(GroupIndex);
    
    switch InputFileType
        %--------------------------------------------------------------------------
        case '.nd2'
            % alert box to indicate required action, closing will resume interaction on main window
            uialert(PODSData.Handles.fH,'Select .nd2 polarization stack(s)','Load FPM Data',...
                'Icon','',...
                'CloseFcn',@(o,e) uiresume(PODSData.Handles.fH));
            % prevent interaction with the main window until we finish
            uiwait(PODSData.Handles.fH);
            % hide main window
            PODSData.Handles.fH.Visible = 'Off';
            % try to get files from the most recent directory,
            % otherwise, just use default
            try
                [Pol_files, PolPath, ~] = uigetfile('*.nd2',...
                    'Select .nd2 polarization stack(s)',...
                    'MultiSelect','on',...
                    PODSData.Settings.LastDirectory);
            catch
                [Pol_files, PolPath, ~] = uigetfile('*.nd2',...
                    'Select .nd2 polarization stack(s)',...
                    'MultiSelect','on');
            end

            % save accessed directory
            PODSData.Settings.LastDirectory = PolPath;
            % show main window
            PODSData.Handles.fH.Visible = 'On';
            % make PODSGUI active figure
            figure(PODSData.Handles.fH);
            
            if(iscell(Pol_files) == 0)
                if(Pol_files==0)
                    error('No files selected. Exiting...');
                end
            end

            % check how many image stacks were selected
            if iscell(Pol_files)
                [~,n_Pol] = size(Pol_files);
            elseif ischar(Pol_files)
                n_Pol = 1;
            end

            % Update Log Window
            UpdateLog3(source,['Opening ' num2str(n_Pol) ' FPM images...'],'append');
            % get the current number of images in this group
            n = cGroup.nReplicates;
            
            % for each stack (set of 4 polarization images)
            for i=1:n_Pol
                % new PODSImage object
                cGroup.Replicate(i+n) = PODSImage(cGroup);
                
                if iscell(Pol_files)
                    cGroup.Replicate(i+n).filename = Pol_files{1,i};
                else
                    cGroup.Replicate(i+n).filename = Pol_files;
                end

                temp = strsplit(cGroup.Replicate(i+n).filename,'.');
                cGroup.Replicate(i+n).pol_shortname = temp{1};
                cGroup.Replicate(i+n).pol_fullname = [PolPath cGroup.Replicate(i+n).filename];
                temp = bfopen(char(cGroup.Replicate(i+n).pol_fullname));
                temp2 = temp{1,1};

                cGroup.Replicate(i+n).Height = size(temp2{1,1},1);
                cGroup.Replicate(i+n).Width = size(temp2{1,1},2);

                UpdateLog3(source,['Dimensions of '...
                    char(cGroup.Replicate(i+n).pol_shortname)...
                    ' are '...
                    num2str(cGroup.Replicate(i+n).Width)...
                    ' by ' num2str(cGroup.Replicate(i+n).Height)]...
                    ,'append');
                % add each pol slice to 3D image matrix
                for j=1:4
                    cGroup.Replicate(i+n).pol_rawdata(:,:,j) = im2double(temp2{j,1})*65535;
                end
                % update to know we have loaded image data
                cGroup.Replicate(i+n).FilesLoaded = true;
                % get the average raw image
                cGroup.Replicate(i+n).RawPolAvg = mean(cGroup.Replicate(i+n).pol_rawdata,3);
                % if no FFC files have been loaded, calculate the average intensity images from the raw data
                if ~cGroup.FFCLoaded
                    % simulated FFC data
                    cGroup.Replicate(i+n).pol_ffc = cGroup.Replicate(i+n).pol_rawdata;
                    % average FFC intensity
                    cGroup.Replicate(i+n).Pol_ImAvg = cGroup.Replicate(i+n).RawPolAvg;
                    % normalized average FFC intensity (normalized to max)
                    cGroup.Replicate(i+n).I = cGroup.Replicate(i+n).Pol_ImAvg./max(max(cGroup.Replicate(i+n).Pol_ImAvg));
                    % done with FFC
                    cGroup.Replicate(i+n).FFCDone = true;
                end
            end
            %--------------------------------------------------------------------------
        case '.tif'
            % alert box to indicate required action
            uialert(PODSData.Handles.fH,'Select .tif polarization stack(s)','Load FPM Data',...
                'Icon','',...
                'CloseFcn',@(o,e) uiresume(PODSData.Handles.fH));
            % prevent interaction with main window until we finish
            uiwait(PODSData.Handles.fH);            
            % hide main window
            PODSData.Handles.fH.Visible = 'Off';            
            % try to get files from the most recent directory,
            % otherwise, just use default
            try
                [Pol_files, PolPath, ~] = uigetfile('*.tif',...
                    'Select .tif polarization stack(s)',...
                    'MultiSelect','on',...
                    PODSData.Settings.LastDirectory);
            catch
                [Pol_files, PolPath, ~] = uigetfile('*.tif',...
                    'Select .tif polarization stack(s)',...
                    'MultiSelect','on');
            end
            % save accessed directory
            PODSData.Settings.LastDirectory = PolPath;
            % hide main window
            PODSData.Handles.fH.Visible = 'On';
            % make PODSGUI active figure
            figure(PODSData.Handles.fH);            
            % if no files selected, throw error
            if(iscell(Pol_files) == 0)
                if(Pol_files==0)
                    error('No files selected. Exiting...');
                end
            end
            % update status log
            UpdateLog3(source,'Opening FPM images...','append');
            % check how many image stacks were selected
            if iscell(Pol_files)
                [~,n_Pol] = size(Pol_files);
            elseif ischar(Pol_files)
                n_Pol = 1;
            end
            % get the current number of images in this group
            n = cGroup.nReplicates;
            % for each file, add a new replicate to the group
            for i=1:n_Pol
                % new PODSImage object
                cGroup.Replicate(i+n) = PODSImage(cGroup);
                
                if iscell(Pol_files)
                    cGroup.Replicate(i+n).filename = Pol_files{1,i+n};
                else
                    cGroup.Replicate(i+n).filename = Pol_files;
                end
                temp = strsplit(cGroup.Replicate(i+n).filename, '.');
                cGroup.Replicate(i+n).pol_shortname = temp{1};
                cGroup.Replicate(i+n).pol_fullname = [PolPath cGroup.Replicate(i+n).filename];
                
                info = imfinfo(char(cGroup.Replicate(i+n).pol_fullname));
                cGroup.Replicate(i+n).Height = info.Height;
                cGroup.Replicate(i+n).Width = info.Width;
                UpdateLog3(source,['Dimensions of ' char(cGroup.Replicate(i+n).pol_shortname) ' are ' num2str(cGroup.Replicate(i+n).Width) ' by ' num2str(cGroup.Replicate(i+n).Height)],'append');
                
                % add the image data to the replicate object
                for j=1:4
                    cGroup.Replicate(i+n).pol_rawdata(:,:,j) = im2double(imread(char(cGroup.Replicate(i+n).pol_fullname),j))*65535;
                end
                % update to know we have loaded image data
                cGroup.Replicate(i+n).FilesLoaded = true;
                % get the average raw image
                cGroup.Replicate(i+n).RawPolAvg = mean(cGroup.Replicate(i+n).pol_rawdata,3);
                % if no FFC files have been loaded, calculate the average intensity images from the raw data
                if ~cGroup.FFCLoaded
                    % simulated FFC data
                    cGroup.Replicate(i+n).pol_ffc = cGroup.Replicate(i+n).pol_rawdata;
                    % average FFC intensity
                    cGroup.Replicate(i+n).Pol_ImAvg = cGroup.Replicate(i+n).RawPolAvg;
                    % normalized average FFC intensity (normalized to max)
                    cGroup.Replicate(i+n).I = cGroup.Replicate(i+n).Pol_ImAvg./max(max(cGroup.Replicate(i+n).Pol_ImAvg));
                    % done with FFC
                    cGroup.Replicate(i+n).FFCDone = true;
                end
            end
            
    end

    cGroup.FPMFilesLoaded = true;
    
    % update log to indicate completion
    UpdateLog3(source,'Done.','append');
    % set current image to first image of channel 1, by default
    PODSData.Group(GroupIndex).CurrentImageIndex = 1;
    % if no FFC files loaded, simulate them with a matrix of ones
    if ~cGroup.FFCLoaded
        UpdateLog3(source,'Warning: No FFC files found. Simulating them with matrix of ones...','append');
        FFCData = struct();
        FFCData.all_cal = ones(size(PODSData.CurrentImage.pol_rawdata));
        FFCData.n_cal = 1;
        FFCData.cal_average = sum(FFCData(1).all_cal,4)./FFCData.n_cal;
        FFCData.cal_norm = FFCData.cal_average/max(max(max(FFCData.cal_average)));
        FFCData.Height = PODSData.CurrentImage.Height;
        FFCData.Width = PODSData.CurrentImage.Width;
        cGroup.FFCData = FFCData;
        % update log to indicate completion
        UpdateLog3(source,'Done.','append');
    end
    
    % if 'Files' isn't the current 'tab', switch to it
    if ~strcmp(PODSData.Settings.CurrentTab,'Files')
        feval(PODSData.Handles.hTabFiles.Callback,PODSData.Handles.hTabFiles,[]);
    end
    
    %UpdateListBoxes(source);
    UpdateImageTree(source);
    UpdateImages(source);
    UpdateSummaryDisplay(source);
    
end