function processFFC(source,~)
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

    % get data structure
    OOPSData = guidata(source);

    % number of selected images
    nImages = numel(OOPSData.CurrentImage);

    % update log to indicate # of images we are processing
    UpdateLog3(source,['Performing flat-field correction for ',num2str(nImages),' images'],'append');

    % create progress dialog
    hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Performing flat-field correction');

    % perform flat-field correction for each image
    for i = 1:nImages
        % get the next image
        cImage = OOPSData.CurrentImage(i);
        % update the progress dialog
        hProgressDialog.Message = ['Performing flat-field correction ',num2str(i),'/',num2str(nImages)];
        hProgressDialog.Value = i/nImages;
        % update log to indicate which image we are on
        UpdateLog3(source,['    ',cImage.rawFPMShortName,' (',num2str(i),'/',num2str(nImages),')'],'append');
        % perform the flat-field correction for this image
        cImage.FlatFieldCorrection();
    end

    % switch tabs if we are not already at the FFC tab
    if ~strcmp(OOPSData.Settings.CurrentTab,'FFC')
        feval(OOPSData.Handles.hTabFFC.Callback,OOPSData.Handles.hTabFFC,[]);
    else
        % update displayed images (tab switching will automatically update the display)
        UpdateImages(source);
    end

    % update display
    UpdateSummaryDisplay(source,{'Project','Group','Image'});

    % close the progress dialog
    close(hProgressDialog);

    % update log
    UpdateLog3(source,'Done.','append');
end