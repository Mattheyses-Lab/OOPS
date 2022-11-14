function [] = pb_LoadFFCFiles(source,~)

    PODSData = guidata(source);
    Settings = PODSData.Settings;
    GroupIndex = PODSData.CurrentGroupIndex;
    InputFileType = Settings.InputFileType;

    FFCData = struct();
    
    % current group based on user selected group and channel idxs
    cGroup = PODSData.Group(GroupIndex);

    %% This switch block should be its own function
    switch InputFileType
        %--------------------------.nd2 Files----------------------------------
        case '.nd2'

            uialert(PODSData.Handles.fH,'Select .nd2 flat-field stack(s)','Load flat-field image stack(s)',...
                'Icon','',...
                'CloseFcn',@(o,e) uiresume(PODSData.Handles.fH));
            
            uiwait(PODSData.Handles.fH);

            PODSData.Handles.fH.Visible = 'Off';
            
            try
                [cal_files, calPath, ~] = uigetfile('*.nd2',...
                    'Select .nd2 flat-field stack(s)',...
                    'MultiSelect','on',PODSData.Settings.LastDirectory);
            catch
                [cal_files, calPath, ~] = uigetfile('*.nd2',...
                    'Select .nd2 flat-field stack(s)',...
                    'MultiSelect','on');
            end

            PODSData.Handles.fH.Visible = 'On';
            figure(PODSData.Handles.fH);

            PODSData.Settings.LastDirectory = calPath;
            
            if ~iscell(cal_files)
                if cal_files == 0
                    warning('No background normalization files selected. Proceeding anyway');
                end
            end

            UpdateLog3(source,'Opening FFC images...','append');

            % determine how many FFC stacks were loaded
            % cal_files will be a cell array if number of stacks > 1
            if iscell(cal_files)
                [~,n_cal] = size(cal_files);
            elseif ischar(cal_files)
                n_cal = 1;
            end

            for i=1:n_cal
                if iscell(cal_files)
                    filename = cal_files{1,i};
                else
                    filename = cal_files;
                end

                temp = strsplit(filename,'.');
                FFCData.cal_shortname{i,1} = temp{1};
                FFCData.cal_fullname{i,1} = [calPath filename];

                if iscell(cal_files)
                    temp = bfopen(char(FFCData(1).cal_fullname{i,1}));
                else
                    temp = bfopen(char(FFCData(1).cal_fullname));
                end
                temp2 = temp{1,1};
                clear temp
                if i==1
                    h = size(temp2{1,1},1);
                    w = size(temp2{1,1},2);
                    UpdateLog3(source,['Calibration file dimensions are ' num2str(w) ' by ' num2str(h)],'append');
                end
                for j=1:4
                    FFCData.all_cal(:,:,j,i) = im2double(temp2{j,1})*65535;
                    % indexing example: FFCData.all_cal(row,col,pol,stack)
                end
            end
            %------------------------------.tif Files----------------------------------
            
        case '.tif'
            
            uialert(PODSData.Handles.fH,'Select .tif flat-field stack(s)','Load flat-field image stack(s)',...
                'Icon','',...
                'CloseFcn',@(o,e) uiresume(PODSData.Handles.fH));
            
            uiwait(PODSData.Handles.fH);

            PODSData.Handles.fH.Visible = 'Off';

            try
                [cal_files, calPath, ~] = uigetfile('*.tif',...
                    'Select .tif flat-field stack(s)',...
                    'MultiSelect','on',PODSData.Settings.LastDirectory);
            catch
                [cal_files, calPath, ~] = uigetfile('*.tif',...
                    'Select .tif flat-field stack(s)',...
                    'MultiSelect','on');
            end

            PODSData.Handles.fH.Visible = 'On';

            PODSData.Settings.LastDirectory = calPath;

            if(iscell(cal_files)==0)
                if(cal_files==0)
                    warning('No background normalization files selected. Proceeding anyway');
                end
            end

            if iscell(cal_files)
                [~,n_cal] = size(cal_files);
            elseif ischar(cal_files)
                n_cal = 1;
            end

            for i=1:n_cal
                if iscell(cal_files)
                    filename = cal_files{1,i};
                else
                    filename = cal_files;
                end
                temp = strsplit(filename,'.');
                FFCData.cal_shortname{i,1} = temp{1};
                clear temp
                FFCData.cal_fullname{i,1} = [calPath filename];
                if i == 1
                    if iscell(cal_files)
                        info = imfinfo(char(FFCData(i).cal_fullname{i,1}));
                    else
                        info = imfinfo(char(FFCData(i).cal_fullname));
                    end
                    h = info.Height;
                    w = info.Width;
                    fprintf(['Calibration file dimensions are ' num2str(w) ' by ' num2str(h) '\n'])
                end
                for j=1:4
                    try
                        FFCData.all_cal(:,:,j,i) = im2double(imread(char(FFCData(1).cal_fullname{i,1}),j))*65535; %convert to 32 bit
                    catch
                        error('Correction files may not all be the same size')
                    end
                end
            end
            
    end % end file-type switch block
    
    
    %average all FFC stacks, result is average stack where each image in
    %the stack is an average of all images collected at a specific
    %excitation polarization
    %normalize resulting average stack by dividing by max value within
    %stack (across all images)    
    FFCData.n_cal = size(FFCData.all_cal,4);
    FFCData.cal_average = sum(FFCData(1).all_cal,4)./FFCData.n_cal;
    FFCData.cal_norm = FFCData.cal_average/max(max(max(FFCData.cal_average)));
    FFCData.Height = h;
    FFCData.Width = w;    
    
    % update main data structure with new data
    cGroup.FFCData = FFCData;

    % test below
    cGroup.FFCLoaded = true;
    
    clear FFCData

    % if files tab is not current, invoke the callback we need to get there
    if ~strcmp(PODSData.Settings.CurrentTab,'Files')
        feval(PODSData.Handles.hTabFiles.Callback,PODSData.Handles.hTabFiles,[]);
    end
    
    UpdateImages(source);
    UpdateSummaryDisplay(source);
    UpdateListBoxes(source);
    
end