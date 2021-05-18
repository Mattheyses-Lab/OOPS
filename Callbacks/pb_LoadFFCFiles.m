function [] = pb_LoadFFCFiles(source,event)
    %calls LoadFFCFiles(), which loads .nd2 FFC files using bfopen()
    %displays images in upper panel of 'Files' tab
    PODSData = guidata(source);
    Settings = PODSData.Settings;
    GroupIndex = PODSData.CurrentGroupIndex;
    ImageIndex = PODSData.Group(GroupIndex).CurrentImageIndex;
    InputFileType = Settings.InputFileType;

    % get structure for current image (selected by user)
    data = PODSData.Group(GroupIndex).FFCData;

    %% This switch block should be its own function
    switch InputFileType
        %--------------------------.nd2 Files----------------------------------
        case '.nd2'
            uiwait(msgbox('Please select flat field correction .nd2 files'));

            [cal_files, calPath, ~] = uigetfile('*.nd2','Select cal files','MultiSelect','on');

            if(iscell(cal_files)==0)
                if(cal_files==0)
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
                data.cal_shortname{i,1} = temp{1};
                data.cal_fullname{i,1} = [calPath filename];

                if iscell(cal_files)
                    temp = bfopen(char(data(1).cal_fullname{i,1}));
                else
                    temp = bfopen(char(data(1).cal_fullname));
                end
                temp2 = temp{1,1};
                if i==1
                    h = size(temp2{1,1},1);
                    w = size(temp2{1,1},2);
                    UpdateLog3(source,['Calibration file dimensions are ' num2str(w) ' by ' num2str(h)],'append');
                end
                for j=1:4
                    data.all_cal(:,:,j,i) = im2double(temp2{j,1})*65535;
                    % indexing example:
                    % data(1).all_cal(row,col,pol,stack)
                end
            end
            %------------------------------.tif Files----------------------------------
        case '.tif'
            uiwait(msgbox('Please select flat field correction .tif files'));

            [cal_files, calPath, ~] = uigetfile('*.tif','Select cal files','MultiSelect','on');

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
                data.cal_shortname{i,1} = temp{1};
                data.cal_fullname{i,1} = [calPath filename];
                if i == 1
                    if iscell(cal_files)
                        info = imfinfo(char(data(i).cal_fullname{i,1}));
                    else
                        info = imfinfo(char(data(i).cal_fullname));
                    end
                    h = info.Height;
                    w = info.Width;
                    fprintf(['Calibration file dimensions are ' num2str(w) ' by ' num2str(h) '\n'])
                end
                for j=1:4
                    try
                        data.all_cal(:,:,j,i) = im2double(imread(char(data(1).cal_fullname{i,1}),j))*65535; %convert to 32 bit
                    catch
                        error('Correction files may not all be the same size')
                    end
                end
            end
    end

    %average all FFC stacks, result is average stack where each image in
    %the stack is an average of all images collected at a specific
    %excitation polarization
    %normalize resulting average stack by dividing by max value within
    %stack (across all images)
    data.n_cal = size(data.all_cal,4);
    data.cal_average = sum(data(1).all_cal,4)./data.n_cal;
    data.cal_norm = data.cal_average/max(max(max(data.cal_average)));

    % update main data structure with new data
    PODSData.Group(GroupIndex).FFCData = data;

    % update image objects with loaded data
    PODSData.Handles.FFCImage0.CData = data.cal_norm(:,:,1);
    PODSData.Handles.FFCImage45.CData = data.cal_norm(:,:,2);
    PODSData.Handles.FFCImage90.CData = data.cal_norm(:,:,3);
    PODSData.Handles.FFCImage135.CData = data.cal_norm(:,:,4);

    % update main data structure
    guidata(source,PODSData);
    UpdateTables(source);    
end