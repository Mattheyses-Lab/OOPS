function [] = pb_LoadFPMFiles(source,event)

    % main data structure
    PODSData = guidata(source);
    % GUI settings structure
    Settings = PODSData.Settings;
    % group that we will be loading data for
    GroupIndex = PODSData.CurrentGroupIndex;
    % nuber of emission channels we will be loading data for
    %nChannels = PODSData.nChannels;
    % user-selected input file type (.nd2 or .tif)
    InputFileType = PODSData.Settings.InputFileType;
    
    %for ChIdx = 1:nChannels
        
        cGroup = PODSData.Group(GroupIndex);
    
        switch InputFileType
%--------------------------------------------------------------------------    
            case '.nd2'
                % msg box with instructions
                uiwait(msgbox(['Select .nd2 polarization stack(s)']));
                % get FPM files (single or multiple)
                [Pol_files, PolPath, ~] = uigetfile('*.nd2',['Select .nd2 polarization stack(s)'],'MultiSelect','on');
                % make PODSGUI active figure
                figure(PODSData.Handles.fH);

                if(iscell(Pol_files) == 0)
                    if(Pol_files==0)
                        error('No files selected. Exiting...');
                        return
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
                    
                    UpdateLog3(source,['Dimensions of ' char(cGroup.Replicate(i+n).pol_shortname) ' are ' num2str(cGroup.Replicate(i+n).Width) ' by ' num2str(cGroup.Replicate(i+n).Height)],'append');

                    % add each pol slice to 3D image matrix
                    for j=1:4
                        cGroup.Replicate(i+n).pol_rawdata(:,:,j) = im2double(temp2{j,1})*65535;
                    end
                    
                    cGroup.Replicate(i+n).FilesLoaded = 1;
                    cGroup.Replicate(i+n).RawPolAvg = mean(cGroup.Replicate(i+n).pol_rawdata,3);
                end
%--------------------------------------------------------------------------    
            case '.tif'
                uiwait(msgbox(['Select .tif polarization stack(s)']));

                [Pol_files, PolPath, ~] = uigetfile('*.tif',['Select .tif polarization stack(s)'],'MultiSelect','on');

                if(iscell(Pol_files) == 0)
                    if(Pol_files==0)
                        error('No files selected. Exiting...');
                        return
                    end
                end 

                UpdateLog3(source,'Opening FPM images...','append');

                % check how many image stacks were selected
                if iscell(Pol_files)
                    [~,n_Pol] = size(Pol_files);
                elseif ischar(Pol_files)
                    n_Pol = 1;
                end

                for i=1:n_Pol
                    % new PODSImage object
                    cGroup.Replicate(i) = PODSImage(cGroup);

                    if iscell(Pol_files)
                        cGroup.Replicate(i).filename = Pol_files{1,i};
                    else
                        cGroup.Replicate(i).filename = Pol_files;
                    end
                    temp = strsplit(cGroup.Replicate(i).filename, '.');
                    cGroup.Replicate(i).pol_shortname = temp{1};
                    cGroup.Replicate(i).pol_fullname = [PolPath cGroup.Replicate(i).filename];

                    info = imfinfo(char(cGroup.Replicate(i).pol_fullname));
                    cGroup.Replicate(i).Height = info.Height;
                    cGroup.Replicate(i).Width = info.Width;
                    UpdateLog3(source,['Dimensions of ' char(cGroup.Replicate(i).pol_shortname) ' are ' num2str(cGroup.Replicate(i).Width) ' by ' num2str(cGroup.Replicate(i).Height)],'append');

                    for j=1:4
                        cGroup.Replicate(i).pol_rawdata(:,:,j) = im2double(imread(char(cGroup.Replicate(i).pol_fullname),j))*65535;
                    end
                end
        end
       
    %end

    % set current image to first image of channel 1, by default
    PODSData.Group(GroupIndex).CurrentImageIndex = 1;
    
    % update gui with new PODSData
    guidata(source,PODSData);
    
    if ~strcmp(PODSData.Settings.CurrentTab,'Files')
        feval(PODSData.Handles.hTabFiles.Callback,PODSData.Handles.hTabFiles,[]);
    end
    
    UpdateListBoxes(source);
    UpdateImages(source);
    UpdateTables(source);
    

end