% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

function [file, location, indx] = uigetimagefile(filter, title, defname, opts)
%UIGETIMAGE Open file selection dialog for image files.
%
%   [file, location, indx] = UIGETIMAGE()
%   opens a file selection dialog for common image file types.
%
%   [file, location, indx] = UIGETIMAGE(filter)
%   uses the specified filter, similar to UIGETFILE.
%
%   [file, location, indx] = UIGETIMAGE(filter, title)
%   also specifies the dialog title.
%
%   [file, location, indx] = UIGETIMAGE(filter, title, defname)
%   also specifies the default file or path.
%
%   [file, location, indx] = UIGETIMAGE(..., MultiSelect='on')
%   enables multi-file selection.
%
% Inputs
%   filter   - File filter, same general forms accepted by UIGETFILE:
%              "*.*"
%              "*.tif"
%              {"*.tif;*.tiff","TIFF files"; "*.png","PNG files"}
%              [] or "" to use default common image filters
%
%   title    - Dialog title text
%
%   defname  - Default file/path
%
% Name-Value Inputs
%   MultiSelect - "on" or "off" (default: "off")
%
% Outputs
%   file      - Selected file name(s), or 0 if canceled
%   location  - Selected folder, or 0 if canceled
%   indx      - Index of selected filter, or 0 if canceled

    arguments
        filter = []
        title (1,1) string = "Select image file"
        defname = ""
        opts.MultiSelect (1,1) matlab.lang.OnOffSwitchState = "off"
    end
    
    % % Default filter: Bio-Formats
    % load the Bio-Formats library into the MATLAB environment
    % so we can call uigetfile with filters for all extensions
    % supported by Bio-Formats
    if bfCheckJavaPath()
        defaultFilter = bfGetFileExtensions();
        % remove invalid file filters ('*.')
        defaultFilter = defaultFilter(~ismember(defaultFilter(:,1),'*.'),:);
    else
        defaultFilter = {'*'};
    end

    if isempty(filter) || isequal(filter,"")
        filter = defaultFilter;
    end
    
    % open file selection dialog
    [file, location, indx] = uigetfile( ...
        filter, ...
        char(title), ...
        defname, ...
        'MultiSelect', opts.MultiSelect);
    
    % no files selected -> return
    if isequal(file, 0), return; end

    % --- Validate selected file(s) are image files ---
    validExt = string(defaultFilter(1,1));
    validExt = strip(strsplit(validExt,';'),'left','*');
    
    % convert to string array
    files = string(file);
    
    % get idx of any non-image files, error if any
    bad = ~ismember(arrayfun(@matlabx.files.getExtension, files), validExt);
    
    if any(bad)
        error('uigetimagefile:UnsupportedFormat', ...
            'All selected files must be supported by Bio-Formats. Invalid selection(s): %s', ...
            strjoin(files(bad), ', '));
    end

end