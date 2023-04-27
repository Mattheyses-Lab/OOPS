function [] = LoadReferenceImages(source,~)
% main data structure
OOPSData = guidata(source);
% idx to the group that we will be loading data for
GroupIndex = OOPSData.CurrentGroupIndex;
% user-selected input file type (.nd2 or .tif)
InputFileType = OOPSData.Settings.InputFileType;

cGroup = OOPSData.Group(GroupIndex);

switch InputFileType
    %--------------------------------------------------------------------------
    case '.nd2'
        
        uialert(OOPSData.Handles.fH,'Select .nd2 reference images','Load Reference Images',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));
        % call uiwait() on the main figure window
        uiwait(OOPSData.Handles.fH);
        % hide main window
        OOPSData.Handles.fH.Visible = 'Off';

        try
            % get reference image files (single or multiple)
            [Pol_files, PolPath, ~] = uigetfile('*.nd2',...
                'Select .nd2 reference images',...
                'MultiSelect','on',...
                OOPSData.Settings.LastDirectory);
        catch
            % get reference image files (single or multiple)
            [Pol_files, PolPath, ~] = uigetfile('*.nd2',...
                'Select .nd2 reference images',...
                'MultiSelect','on');
        end

        % save recent directory
        OOPSData.Settings.LastDirectory = PolPath;

        % show main window
        OOPSData.Handles.fH.Visible = 'On';
        % make it active
        figure(OOPSData.Handles.fH);

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
        
        n = cGroup.nReplicates;
        
        if n~=n_Pol
            msg = 'Number of reference images must match the number of polarization stacks...';
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        end

        % Update Log Window
        UpdateLog3(source,['Opening ' num2str(n_Pol) ' reference images...'],'append');
        
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
                uialert(OOPSData.Handles.fH,report,'Error');
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
    
OOPSData.Handles.ShowReferenceImageAverageIntensity.Visible = 'On';

UpdateImages(source);
UpdateSummaryDisplay(source);
UpdateListBoxes(source);


end