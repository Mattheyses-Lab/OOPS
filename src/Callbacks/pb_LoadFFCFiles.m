function [] = pb_LoadFFCFiles(source,~)

    OOPSData = guidata(source);
    Settings = OOPSData.Settings;
    GroupIndex = OOPSData.CurrentGroupIndex;
    InputFileType = Settings.InputFileType;

    FFCData = struct();
    
    % current group based on user selected group and channel idxs
    cGroup = OOPSData.Group(GroupIndex);

    %% This switch block should be its own function
    switch InputFileType
        %--------------------------.nd2 Files----------------------------------
        case '.nd2'

            uialert(OOPSData.Handles.fH,'Select .nd2 flat-field stack(s)','Load flat-field image stack(s)',...
                'Icon','',...
                'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));
            
            uiwait(OOPSData.Handles.fH);

            OOPSData.Handles.fH.Visible = 'Off';
            
            try
                [cal_files, calPath, ~] = uigetfile('*.nd2',...
                    'Select .nd2 flat-field stack(s)',...
                    'MultiSelect','on',OOPSData.Settings.LastDirectory);
            catch
                [cal_files, calPath, ~] = uigetfile('*.nd2',...
                    'Select .nd2 flat-field stack(s)',...
                    'MultiSelect','on');
            end

            OOPSData.Handles.fH.Visible = 'On';
            figure(OOPSData.Handles.fH);

            OOPSData.Settings.LastDirectory = calPath;
            
            if ~iscell(cal_files)
                if cal_files == 0
                    error('No background normalization files selected. Exiting...');
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
                cGroup.FFC_cal_shortname{i,1} = temp{1};
                cGroup.FFC_cal_fullname{i,1} = [calPath filename];

                if iscell(cal_files)
                    temp = bfopen(char(cGroup.FFC_cal_fullname{i,1}));
                else
                    temp = bfopen(char(cGroup.FFC_cal_fullname));
                end
                temp2 = temp{1,1};
                clear temp
                if i==1
                    h = size(temp2{1,1},1);
                    w = size(temp2{1,1},2);
                    UpdateLog3(source,['Calibration file dimensions are ' num2str(w) ' by ' num2str(h)],'append');
                end
                for j=1:4
                    cGroup.FFC_all_cal(:,:,j,i) = im2double(temp2{j,1})*65535;
                    % indexing example: FFCData.all_cal(row,col,pol,stack)
                end
            end
            %------------------------------.tif Files----------------------------------
            
        case '.tif'
            
            uialert(OOPSData.Handles.fH,'Select .tif flat-field stack(s)','Load flat-field image stack(s)',...
                'Icon','',...
                'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));
            
            uiwait(OOPSData.Handles.fH);

            OOPSData.Handles.fH.Visible = 'Off';

            try
                [cal_files, calPath, ~] = uigetfile('*.tif',...
                    'Select .tif flat-field stack(s)',...
                    'MultiSelect','on',OOPSData.Settings.LastDirectory);
            catch
                [cal_files, calPath, ~] = uigetfile('*.tif',...
                    'Select .tif flat-field stack(s)',...
                    'MultiSelect','on');
            end

            OOPSData.Handles.fH.Visible = 'On';

            OOPSData.Settings.LastDirectory = calPath;

            if(iscell(cal_files)==0)
                if(cal_files==0)
                    error('No background normalization files selected. Exiting...');
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
                cGroup.FFC_cal_shortname{i,1} = temp{1};
                clear temp
                cGroup.FFC_cal_fullname{i,1} = [calPath filename];
                if i == 1
                    if iscell(cal_files)
                        info = imfinfo(char(cGroup.FFC_cal_fullname{i,1}));
                    else
                        info = imfinfo(char(cGroup.FFC_cal_fullname));
                    end
                    h = info.Height;
                    w = info.Width;
                    fprintf(['Calibration file dimensions are ' num2str(w) ' by ' num2str(h) '\n'])
                end
                for j=1:4
                    try
                        cGroup.FFC_all_cal(:,:,j,i) = im2double(imread(char(cGroup.FFC_cal_fullname{i,1}),j))*65535; %convert to 32 bit
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
    cGroup.FFC_n_cal = size(cGroup.FFC_all_cal,4);
    cGroup.FFC_cal_average = sum(cGroup.FFC_all_cal,4)./cGroup.FFC_n_cal;
    cGroup.FFC_cal_norm = cGroup.FFC_cal_average/max(max(max(cGroup.FFC_cal_average)));
    cGroup.FFC_Height = h;
    cGroup.FFC_Width = w;
    cGroup.FFC_cal_size = size(cGroup.FFC_cal_norm);
    
%     % update main data structure with new data
%     cGroup.FFCData = FFCData;

    % test below
    cGroup.FFCLoaded = true;
    
    clear FFCData

    % if files tab is not current, invoke the callback we need to get there
    if ~strcmp(OOPSData.Settings.CurrentTab,'Files')
        feval(OOPSData.Handles.hTabFiles.Callback,OOPSData.Handles.hTabFiles,[]);
    end
    
    UpdateImages(source);
    UpdateSummaryDisplay(source);
    UpdateListBoxes(source);
    
end