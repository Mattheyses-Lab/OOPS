function UpdateIntensitySliders(source)
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

    OOPSData = guidata(source);
    
    cImage = OOPSData.CurrentImage;

    if ~isempty(cImage)
        cImage = cImage(1);
    else
        OOPSData.Handles.PrimaryIntensitySlider.Value = [0 1];
        OOPSData.Handles.PrimaryIntensitySlider.HitTest = 'Off';
        OOPSData.Handles.ReferenceIntensitySlider.Value = [0 1];
        OOPSData.Handles.ReferenceIntensitySlider.HitTest = 'Off';
        OOPSData.Handles.OrderSlider.Value = [0 1];
        OOPSData.Handles.OrderSlider.HitTest = 'Off';
        return
    end

    OOPSData.Handles.PrimaryIntensitySlider.HitTest = 'On';

    % only enable reference limits slider if reference image is loaded
    OOPSData.Handles.ReferenceIntensitySlider.HitTest = cImage.ReferenceImageLoaded;

    % only enable order limits slider if FPM stats are done
    OOPSData.Handles.OrderSlider.HitTest = cImage.FPMStatsDone;



    try
        OOPSData.Handles.PrimaryIntensitySlider.Value = cImage.PrimaryIntensityDisplayLimits;
    catch
        OOPSData.Handles.PrimaryIntensitySlider.Value = [0 1];
    end

    try
        OOPSData.Handles.ReferenceIntensitySlider.Value = cImage.ReferenceIntensityDisplayLimits;
    catch
        OOPSData.Handles.ReferenceIntensitySlider.Value = [0 1];
    end

    try
        if OOPSData.Handles.ScaleToMaxOrder.Value
            if cImage.FPMStatsDone
                cImage.OrderDisplayLimits = [0 max(cImage.OrderImage,[],"all")];
            else
                cImage.OrderDisplayLimits = [0 1];
            end
            OOPSData.Handles.OrderSlider.Value = cImage.OrderDisplayLimits;

            OOPSData.Handles.ScaleToMaxOrder.Value = true;
            OOPSData.Handles.ScaleToMaxObjectOrder.Value = true;
            OOPSData.Handles.ScaleToMaxAzimuth.Value = true;
        else
            OOPSData.Handles.OrderSlider.Value = cImage.OrderDisplayLimits;
        end
    catch
        OOPSData.Handles.OrderSlider.Value = [0 1];
    end


    for i = 1:numel(OOPSData.Settings.CustomStatistics)

        thisStatistic = OOPSData.Settings.CustomStatistics(i);

        statName = thisStatistic.StatisticName;
        statDisplayName = thisStatistic.StatisticDisplayName;

        % enable or disable this custom slider depending on whether its tab is active
        OOPSData.Handles.([statName,'Slider']).HitTest = cImage.FPMStatsDone;

        try
            if OOPSData.Handles.ScaleToMaxCustomStat.Value && strcmp(OOPSData.Settings.CurrentTab,statDisplayName)
                if cImage.FPMStatsDone
                    cImage.([statName,'DisplayLimits']) = [0 max(cImage.([statName,'Image']),[],"all")];
                else
                    cImage.([statName,'DisplayLimits']) = cImage.([statName,'DisplayRange']);
                end
                OOPSData.Handles.([statName,'Slider']).Value = cImage.([statName,'DisplayLimits']);
    
                OOPSData.Handles.ScaleToMaxCustomStat.Value = true;
            else
                OOPSData.Handles.([statName,'Slider']).Value = cImage.([statName,'DisplayLimits']);
            end
        catch
            OOPSData.Handles.([statName,'Slider']).Value = OOPSData.Handles.([statName,'Slider']).Limits;
        end

    end





end