function [] = LoadReferenceImages(source,event)
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

cGroup = PODSData.Group(GroupIndex);

switch InputFileType
    %--------------------------------------------------------------------------
    case '.nd2'
        % msg box with instructions
        uiwait(msgbox(['Select .nd2 reference images']));
        % get reference image files (single or multiple)
        [Pol_files, PolPath, ~] = uigetfile('*.nd2',['Select .nd2 reference images'],'MultiSelect','on');
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
        UpdateLog3(source,['Opening ' num2str(n_Pol) ' reference images...'],'append');
        
        n = cGroup.nReplicates;
        
        if n~=n_Pol
            error('Number of references images must match the number of polarization stacks...');
        end
        
        % for each image
        for i=1:n_Pol
            
            if iscell(Pol_files)
                Filename = Pol_files{1,i};
            else
                Filename = Pol_files;
            end
            
            temp = strsplit(Filename,'.');
            ShortName = temp{1};
            FullName = [PolPath Filename];
            temp = bfopen(char(FullName));
            temp2 = temp{1,1};
            
            Height = size(temp2{1,1},1);
            Width = size(temp2{1,1},2);
            
            if Height~=cGroup.Replicate(i).Height | Width~=cGroup.Replicate(i).Width
                error('Reference image dimensions do not match polarization image dimensions...')
            end
            
            cGroup.Replicate(i).ReferenceImage(:,:,1) = im2double(temp2{1,1})*65535;
            cGroup.Replicate(i).ReferenceImageLoaded = true;
        end
        %--------------------------------------------------------------------------
    case '.tif'
        
        % do nothing for now
        
end
    
Handles.ShowReferenceImageAverageIntensity.Visible = 'On';

UpdateImages(source);
UpdateTables(source);
UpdateListBoxes(source);


end