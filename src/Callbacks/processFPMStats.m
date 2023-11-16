function processFPMStats(source,~)
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
    UpdateLog3(source,['Computing FPM statistics statistics for ',num2str(nImages),' images'],'append');

    % start a timer
    tic

    % testing below - progress dialog
    hProgressDialog = uiprogressdlg(OOPSData.Handles.fH,"Message",'Calculating order and orientation statistics');

    % compute pixel-by-pixel FPM stats for each selected image
    for i = 1:nImages
        cImage = OOPSData.CurrentImage(i);
        % update the progress dialog
        hProgressDialog.Message = ['Calculating order and orientation statistics ',num2str(i),'/',num2str(nImages)];
        hProgressDialog.Value = i/nImages;
        % update log to indicate which image we are on
        UpdateLog3(source,['    ',cImage.rawFPMShortName,' (',num2str(i),'/',num2str(nImages),')'],'append');
        % compute any custom FPM statistics
        cImage.FindFPMStatistics();
    end
    % end the timer and save the time
    timeElapsed = toc;

    % change to the Order 'tab' if not there already
    if ~strcmp(OOPSData.Settings.CurrentTab,'Order')
        feval(OOPSData.Handles.hTabOrder.Callback,OOPSData.Handles.hTabOrder,[]);
    else
        % update displayed images (tab switching will automatically update the display)
        UpdateImages(source);
    end

    % update summary table
    UpdateSummaryDisplay(source,{'Group','Image','Object'});
    % update the intensity sliders
    UpdateIntensitySliders(source)

    % update log with time elapsed
    UpdateLog3(source,['Time elapsed: ',num2str(timeElapsed),' seconds'],'append');

    % close the progress dialog
    close(hProgressDialog);

    % update log to indicate we are done
    UpdateLog3(source,'Done.','append');

end