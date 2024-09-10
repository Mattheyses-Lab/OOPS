function processLocalSB(source,~)
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

    % get handle to the data structure
    OOPSData = guidata(source);

    % number of selected images
    nImages = numel(OOPSData.CurrentImage);

    % update log to indicate # of images we are processing
    UpdateLog3(source,['Detecting Local S/B for ',num2str(nImages),' images'],'append');

    % create progress dialog
    hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Calculating local S/B');

    for i = 1:nImages
        cImage = OOPSData.CurrentImage(i);
        % update the progress dialog
        hProgressDialog.Message = ['Calculating local S/B ',num2str(i),'/',num2str(nImages)];
        hProgressDialog.Value = i/nImages;
        % update log to indicate which image we are on
        UpdateLog3(source,['    ',cImage.rawFPMShortName,' (',num2str(i),'/',num2str(nImages),')'],'append');
        % detect local S/B for one image
        cImage.FindLocalSB();
        % log update to indicate we are done with this image
        UpdateLog3(source,['        Local S/B detected for ',num2str(cImage.nObjects),' objects...'],'append');
    end

    % update summary table
    UpdateSummaryDisplay(source,{'Group','Image','Object'});

    % close the progress dialog
    close(hProgressDialog);

    % update log to indicate we are done
    UpdateLog3(source,'Done.','append');    

end