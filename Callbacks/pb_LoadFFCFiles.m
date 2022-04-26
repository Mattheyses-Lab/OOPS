function [] = pb_LoadFFCFiles(source,event)
    %calls LoadFFCFiles(), which loads .nd2 FFC files using bfopen()
    %displays images in upper panel of 'Files' tab
    PODSData = guidata(source);
    Settings = PODSData.Settings;
    GroupIndex = PODSData.CurrentGroupIndex;
    nChannels = PODSData.nChannels;
    %ImageIndex = PODSData.Group(GroupIndex).CurrentImageIndex;
    InputFileType = Settings.InputFileType;

    FFCData = struct();

for ChIdx = 1:nChannels
    
    % current group based on user selected group and channel idxs
    cGroup = PODSData.Group(GroupIndex,ChIdx);

    %% This switch block should be its own function
    switch InputFileType
        %--------------------------.nd2 Files----------------------------------
        case '.nd2'

            uiwait(msgbox(['Select .nd2 flat-field stack(s) for Channel:' cGroup.ChannelName]));

            [cal_files, calPath, ~] = uigetfile('*.nd2',['Select .nd2 flat-field stack(s) for Channel:' cGroup.ChannelName],'MultiSelect','on');

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
                clear temp
                if i==1
                    h = size(temp2{1,1},1);
                    w = size(temp2{1,1},2);
                    UpdateLog3(source,['Calibration file dimensions are ' num2str(w) ' by ' num2str(h)],'append');
                end
                for j=1:4
                    FFCData.all_cal(:,:,j,i) = im2double(temp2{j,1})*65535;
                    % indexing example:
                    % FFCData.all_cal(row,col,pol,stack)
                end
            end
            %------------------------------.tif Files----------------------------------
            
        case '.tif'
            uiwait(msgbox(['Select .tif flat-field stack(s) for Channel:' cGroup.ChannelName]));

            [cal_files, calPath, ~] = uigetfile('*.tif',['Select .nd2 flat-field stack(s) for Channel:' cGroup.ChannelName],'MultiSelect','on');

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
    
    clear FFCData
end

%     % update image objects with loaded data FROM FIRST CHANNEL
%     PODSData.Handles.FFCImage0.CData = PODSData.Group(GroupIndex,1).FFCData.cal_norm(:,:,1);
%     PODSData.Handles.FFCAxH(1).XLim = [1,w];
%     PODSData.Handles.FFCAxH(1).YLim = [1,h];
%     PODSData.Handles.FFCImage45.CData = PODSData.Group(GroupIndex,1).FFCData.cal_norm(:,:,2);
%     PODSData.Handles.FFCAxH(2).XLim = [1,w];
%     PODSData.Handles.FFCAxH(2).YLim = [1,h];    
%     PODSData.Handles.FFCImage90.CData = PODSData.Group(GroupIndex,1).FFCData.cal_norm(:,:,3);
%     PODSData.Handles.FFCAxH(3).XLim = [1,w];
%     PODSData.Handles.FFCAxH(3).YLim = [1,h];    
%     PODSData.Handles.FFCImage135.CData = PODSData.Group(GroupIndex,1).FFCData.cal_norm(:,:,4);
%     PODSData.Handles.FFCAxH(4).XLim = [1,w];
%     PODSData.Handles.FFCAxH(4).YLim = [1,h]; 
    
    % if files tab is not current, invoke the callback we need to get there
    if ~strcmp(PODSData.Settings.CurrentTab,'Files')
        feval(PODSData.Handles.hTabFiles.Callback,PODSData.Handles.hTabFiles,[]);
    end    

    UpdateTables(source);    
end