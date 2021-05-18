function [] = pb_LoadFPMFiles(source,event)

    PODSData = guidata(source);
    Settings = PODSData.Settings;
    GroupIndex = PODSData.CurrentGroupIndex;
    ImageIndex = PODSData.Group(GroupIndex).CurrentImageIndex;
    InputFileType = PODSData.Settings.InputFileType;    

    % data will hold all replicates within Group(CurrentGroup)
    data = PODSData.Group(GroupIndex).Replicate;
    
    % number of replicates already existing
    n = PODSData.Group(GroupIndex).nReplicates;
    
    switch InputFileType
%--------------------------------------------------------------------------    
        case '.nd2'

            uiwait(msgbox('Please select polarization stack .nd2 files'));

            [Pol_files, PolPath, ~] = uigetfile('*.nd2','Select Polarization sequences','MultiSelect','on');

            if(iscell(Pol_files) == 0)
                if(Pol_files==0)
                    msg = 'No files selected. Exiting...';
                    error(msg);
                end
            end 
            
            % check how many image stacks were selected
            if iscell(Pol_files)
                [~,n_Pol] = size(Pol_files);
            elseif ischar(Pol_files)
                n_Pol = 1;
            end 

            % Update Summary Log Window
            UpdateLog3(source,['Opening ' num2str(n_Pol) ' FPM images...'],'append');

            % for each stack (set of 4 polarization images)
            for i=1:n_Pol 

                if iscell(Pol_files)
                    filename = Pol_files{1,i};
                else
                    filename = Pol_files;
                end

                temp = strsplit(filename,'.');
                data(i+n).pol_shortname = temp{1};
                data(i+n).pol_fullname = [PolPath filename];
                temp = bfopen(char(data(i+n).pol_fullname));
                temp2 = temp{1,1};

                % on first loop run
                if i==1
                    data(i+n).h = size(temp2{1,1},1);
                    data(i+n).w = size(temp2{1,1},2);
                    UpdateLog3(source,['Dimensions of ' char(data(i+n).pol_shortname) ' are ' num2str(data(i+n).w) ' by ' num2str(data(i+n).h)],'append');
                end

                % add each pol slice to 3D image matrix
                for j=1:4
                    data(i+n).pol_rawdata(:,:,j) = im2double(temp2{j,1})*65535;
                end
                data(i+n).pol_rawdata_normalizedbystack = data(i+n).pol_rawdata./(max(max(max(data(i+n).pol_rawdata))));                
            end
%--------------------------------------------------------------------------    
        case '.tif'

            uiwait(msgbox('Please select polarization stack .tif files'));

            [Pol_files, PolPath, ~] = uigetfile('*.tif','Select Polarization sequences','MultiSelect','on');

            if(iscell(Pol_files) == 0)
                if(Pol_files==0)
                    msg = 'No files selected. Exiting...';
                    error(msg);
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
                if iscell(Pol_files)
                    filename = Pol_files{1,i};
                else
                    filename = Pol_files;
                end
                temp = strsplit(filename, '.');
                data(i+n).pol_shortname = temp{1};
                data(i+n).pol_fullname = [PolPath filename];

                if i == 1
                    info = imfinfo(char(data(i+n).pol_fullname));
                    data(i+n).h = info.Height;
                    data(i+n).w = info.Width;
                    UpdateLog3(source,['Dimensions of ' char(data(i+n).pol_shortname) ' are ' num2str(data(i+n).w) ' by ' num2str(data(i+n).h)],'append');
                end
                for j=1:4
                    data(i+n).pol_rawdata(:,:,j) = im2double(imread(char(data(i+n).pol_fullname),j))*65535;
                end
                data(i+n).pol_rawdata_normalizedbystack = data(i+n).pol_rawdata./(max(max(max(data(i+n).pol_rawdata))));
            end

    end
    
    % new number of replicates in group
    new_n = n_Pol + n;
    
    % update structure with new image data
    PODSData.Group(GroupIndex).Replicate = data;
    
    % new cell array of image names
    ImageNames = {};
    [ImageNames{1:new_n,1}] = deal(PODSData.Group(GroupIndex).Replicate.pol_shortname);
    
    % add ImageNames to data group structure
    PODSData.Group(GroupIndex).ImageNames = ImageNames;
    
    % add nReplicates to Group structure
    PODSData.Group(GroupIndex).nReplicates = new_n;
    
    % update display with first image loaded
    PODSData.Handles.RawImage0.CData = data(n+1).pol_rawdata_normalizedbystack(:,:,1);
    PODSData.Handles.RawImage45.CData = data(n+1).pol_rawdata_normalizedbystack(:,:,2);
    PODSData.Handles.RawImage90.CData = data(n+1).pol_rawdata_normalizedbystack(:,:,3);
    PODSData.Handles.RawImage135.CData = data(n+1).pol_rawdata_normalizedbystack(:,:,4);
    
    % set image name list box values to image names
    PODSData.Handles.ImageListBox.Items = ImageNames;
    % set ItemsValue of image name listbox so we can index it
    PODSData.Handles.ImageListBox.ItemsData = [1:new_n];
    
    
    
    
    
    % normalize raw data by dividing all pixels in all images by maximum
    % pixel value across the 4 images. Not used for calculations, but
    % useful for showing images side by side when you want intensity
    % differences within a stack to be visible to user


    guidata(source,PODSData);
    UpdateTables(source);




end