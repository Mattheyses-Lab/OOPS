function AdjustOrderDisplayLimits(source,~)
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

    % the main data structure
    OOPSData = guidata(source);
    
    if isempty(OOPSData.CurrentImage)
        source.Value = [0 1];
        return
    end
    
    if ~OOPSData.CurrentImage(1).FPMStatsDone
        source.Value = [0 1];
        return
    end

    % this function will be called whether the user adjusts the slider or if the slider value is changed programatically
    % only disable autoscale behavior if user adjusted the slider
    if source.isSliding
        OOPSData.Handles.ScaleToMaxOrder.Value = false;
        OOPSData.Handles.ScaleToMaxObjectOrder.Value = false;
        OOPSData.Handles.ScaleToMaxAzimuth.Value = false;
    end

    % set the Order display limits using the slider value
    OOPSData.CurrentImage(1).OrderDisplayLimits = source.Value;

    % update image display if necessary
    switch OOPSData.Settings.CurrentTab
        case 'Order'
            UpdateOrderImage(source);
        case 'Azimuth'
            if OOPSData.Handles.ShowAzimuthHSVOverlayAzimuth.Value
                UpdateAzimuthImage(source);
            end
        case 'Objects'
            UpdateObjectOrderImage(source);
    end
    
    drawnow limitrate

end