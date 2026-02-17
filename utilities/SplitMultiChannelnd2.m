function SplitMultiChannelnd2()
%% SPLITMULTICHANNELND2     Splits multi-channel .nd2 image(s) into single channel .tif images
%
%   USAGE
%       Type the following into the command window:
%           >> SplitMultiChannelnd2()
%
%       Function will prompt user to select multi-channel .nd2 image(s)
%
%       After selection, the function will:
%           - Read each file
%           - Determine the number of channels in the file
%           - Create new folder(s) for each channel (Channel 1, Channel 2, etc.)
%           - Save the data for each individual channel into the corresponding folder
%               - Original image name will be appended to specify the channel
%               - e.g. a 2-channel image, ExampleImage.nd2, will be split into separate images:
%               path/Channel 1/ExampleImage_C1.tif and path/Channel 2/ExampleImage_C2.tif, where
%               'path' is the location of the images originally selected by the user

    [files, filePath, ~] = uigetfile('*.nd2','Select multi-Channel .nd2 image(s)','MultiSelect','on');
    
    if iscell(files)
        [~,nFiles] = size(files);
    elseif ischar(files)
        nFiles = 1;
    end
    
    for i=1:nFiles
    
        if iscell(files)
            filename = files{1,i};
        else
            filename = files;
        end
    
        % path to the image
        fullName = [filePath filename];
    
        % open the image
        DataStructure = bfopen(char(fullName));
        ImageInfo = DataStructure{1,1};
    
        % number of channels
        nChannels = size(ImageInfo,1);
    
        % file name without extension
        nameSplit = strsplit(filename,'.');
    
        % base name which we will append to for the new images
        baseName = nameSplit{1};
    
        % save each channel as separate Tiff image in a new folder placed into the same directory as the original data
        for c = 1:nChannels
    
            % name of the new folder (Channel 1, Channel 2, etc.)
            folderName = sprintf('Channel %d',c);
    
            % % path to the new folder
            newPath = fullfile(filePath, folderName);

            if ~exist(newPath, 'dir')
                mkdir(newPath);
            end

            imageName = fullfile(newPath, [baseName, sprintf('_C%d.tif',c)]);

            % update status message in the command window
            fprintf('Saving image %d/%d, channel %d/%d: %s\n',i,nFiles,c,nChannels,imageName);
    
            % write image data to a new Tiff object and save it at newPath
            write16BitTiff(ImageInfo{c,1},imageName);

            fprintf('Done.\n');
    
        end
    
    end

end