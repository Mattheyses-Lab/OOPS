function [] = pb_LoadFFCFiles(source,event)
    %calls LoadFFCFiles(), which loads .nd2 FFC files using bfopen()
    %displays images in upper panel of 'Files' tab
    PODSData = guidata(source);
    Settings = PODSData.Settings;
    GroupIndex = PODSData.CurrentGroupIndex;
    ImageIndex = PODSData.Group(GroupIndex).CurrentImageIndex;
    InputFileType = Settings.InputFileType;

    FFCData = struct();

    %% This switch block should be its own function
    switch InputFileType
        %--------------------------.nd2 Files----------------------------------
        case '.nd2'
            uiwait(msgbox('Please select flat field correction .nd2 files'));

            [cal_files, calPath, ~] = uigetfile('*.nd2','Select cal files','MultiSelect','on');

            figure(PODSData.Handles.fH);
            
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
                if i==1
                    h = size(temp2{1,1},1);
                    w = size(temp2{1,1},2);
                    UpdateLog3(source,['Calibration file dimensions are ' num2str(w) ' by ' num2str(h)],'append');
                end
                for j=1:4
                    FFCData.all_cal(:,:,j,i) = im2double(temp2{j,1})*65535;
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
                FFCData.cal_shortname{i,1} = temp{1};
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
    end

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
    PODSData.Group(GroupIndex).FFCData = FFCData;

    % update image objects with loaded data
    PODSData.Handles.FFCImage0.CData = FFCData.cal_norm(:,:,1);
    PODSData.Handles.FFCAxH(1).XLim = [1,w];
    PODSData.Handles.FFCAxH(1).YLim = [1,h];
    PODSData.Handles.FFCImage45.CData = FFCData.cal_norm(:,:,2);
    PODSData.Handles.FFCAxH(2).XLim = [1,w];
    PODSData.Handles.FFCAxH(2).YLim = [1,h];    
    PODSData.Handles.FFCImage90.CData = FFCData.cal_norm(:,:,3);
    PODSData.Handles.FFCAxH(3).XLim = [1,w];
    PODSData.Handles.FFCAxH(3).YLim = [1,h];    
    PODSData.Handles.FFCImage135.CData = FFCData.cal_norm(:,:,4);
    PODSData.Handles.FFCAxH(4).XLim = [1,w];
    PODSData.Handles.FFCAxH(4).YLim = [1,h]; 
    

    % update main data structure
    guidata(source,PODSData);
    
    if ~strcmp(PODSData.Settings.CurrentTab,'Files')
        ChangePODSTab(source,'Files');
    end    
    
    UpdateTables(source);    
end