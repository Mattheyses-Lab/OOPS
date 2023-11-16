function UpdateCustomStatImage(source)
%
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

    % main data structure
    OOPSData = guidata(source);
    % current image(s) selection
    cImage = OOPSData.CurrentImage;

    % if the current selection includes at least one image
    if ~isempty(cImage)
        % update the display according to the first image in the list
        cImage = cImage(1);
        EmptyImage = sparse(zeros(cImage.Height,cImage.Width));
    else
        EmptyImage = sparse(zeros(1024,1024));
    end


    % get the idx of the custom stat to display based on the selected menu option
    statIdx = ismember(OOPSData.Settings.CurrentTab,OOPSData.Settings.CustomStatisticDisplayNames);
    % get the stat
    thisStat = OOPSData.Settings.CustomStatistics(statIdx);
    % get the name of the variable holding the stat
    statName = thisStat.StatisticName;
    % get the display name of the stat
    statDisplayName = thisStat.StatisticDisplayName;
    % get the output range of the stat
    statRange = thisStat.StatisticRange;
    
    % set the title of the axes/image
    OOPSData.Handles.CustomStatAxH.Title.String = statDisplayName;
    
    OOPSData.Handles.CustomStatAxH.UserData = thisStat;
    
    % show or hide the CustomStat colorbar
    OOPSData.Handles.CustomStatCbar.Visible = OOPSData.Handles.ShowColorbarCustomStat.Value;


    try
        customStatDisplayLimits = cImage.([statName,'DisplayLimits']);

        % set the image CData
        if OOPSData.Handles.ShowAsOverlayCustomStat.Value
            OOPSData.Handles.CustomStatImgH.CData = cImage.(['UserScaled',statName,'IntensityOverlayRGB']);
        else
            OOPSData.Handles.CustomStatImgH.CData = cImage.(['UserScaled',statName,'Image']);
        end
        % set the colorbar tick labels
        OOPSData.Handles.CustomStatCbar.TickLabels = round(linspace(customStatDisplayLimits(1),customStatDisplayLimits(2),11),2);
        % if ApplyMask toolbar state button set to true...
        if OOPSData.Handles.ApplyMaskCustomStat.Value
            % ...then apply current mask by setting image AlphaData
            OOPSData.Handles.CustomStatImgH.AlphaData = cImage.bw;
        end
        % reset the default axes limits if zoom is not active
        if ~OOPSData.Settings.Zoom.Active
            OOPSData.Handles.CustomStatAxH.XLim = [0.5 cImage.Width+0.5];
            OOPSData.Handles.CustomStatAxH.YLim = [0.5 cImage.Height+0.5];
        end
    catch
        disp('Warning: Error displaying CustomStat image...')
        % set placeholders
        OOPSData.Handles.CustomStatImgH.CData = EmptyImage;
        OOPSData.Handles.CustomStatAxH.XLim = [0.5 size(EmptyImage,2)+0.5];
        OOPSData.Handles.CustomStatAxH.YLim = [0.5 size(EmptyImage,1)+0.5];
        OOPSData.Handles.CustomStatCbar.TickLabels = round(linspace(statRange(1),statRange(2),11),2);
        OOPSData.Handles.CustomStatImgH.AlphaData = 1;
    end


end