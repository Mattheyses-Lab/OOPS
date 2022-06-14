function [] = LoadReferenceImages(source,~)
% main data structure
PODSData = guidata(source);
% group that we will be loading data for
GroupIndex = PODSData.CurrentGroupIndex;
% user-selected input file type (.nd2 or .tif)
InputFileType = PODSData.Settings.InputFileType;

cGroup = PODSData.Group(GroupIndex);

switch InputFileType
    %--------------------------------------------------------------------------
    case '.nd2'
        
        uialert(PODSData.Handles.fH,'Select .nd2 reference images','Load Reference Images',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(PODSData.Handles.fH));
        
        uiwait(PODSData.Handles.fH);
        % hide main window
        PODSData.Handles.fH.Visible = 'Off';
        % get reference image files (single or multiple)
        [Pol_files, PolPath, ~] = uigetfile('*.nd2',...
            'Select .nd2 reference images',...
            'MultiSelect','on',...
            PODSData.Settings.LastDirectory);

        PODSData.Settings.LastDirectory = PolPath;

        % show main window
        PODSData.Handles.fH.Visible = 'On';

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
            
            FullName = [PolPath Filename];
            temp = bfopen(char(FullName));
            temp2 = temp{1,1};
            
            Height = size(temp2{1,1},1);
            Width = size(temp2{1,1},2);
            
            try
                if Height~=cGroup.Replicate(i).Height || Width~=cGroup.Replicate(i).Width
                    error(['Error loading reference images' newline 'Reference image dimensions do not match polarization image dimensions']);
                end
            catch ME
                report = getReport(ME);
                uialert(PODSData.fH,report,'Error');
                return
            end
            
            cGroup.Replicate(i).ReferenceImage(:,:,1) = im2double(temp2{1,1})*65535;
            cGroup.Replicate(i).ReferenceImageLoaded = true;
            
            cGroup.Replicate(i).ReferenceImageEnhanced = EnhanceGrayScale(cGroup.Replicate(i).ReferenceImage);
        end
        %--------------------------------------------------------------------------
    case '.tif'
        
        % do nothing for now
        
end

UpdateLog3(source,'Done.','append');
    
PODSData.Handles.ShowReferenceImageAverageIntensity.Visible = 'On';

UpdateImages(source);
UpdateTables(source);
UpdateListBoxes(source);


end