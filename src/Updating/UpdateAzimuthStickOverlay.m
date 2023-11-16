function UpdateAzimuthStickOverlay(source)
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

    % handle to the main data structure
    OOPSData = guidata(source);

    % current image(s) selection
    cImage = OOPSData.CurrentImage;

    % if the current selection includes at least one image
    if ~isempty(cImage)
        % update the display according to the first image in the list
        cImage = cImage(1);
    end

    % delete any existing azimuth sticks
    try
        delete(OOPSData.Handles.AzimuthLines);
    catch
        disp('Warning: Could not delete Azimuth lines')
    end


    try

        if OOPSData.Settings.AzimuthObjectMask
            LineMask = cImage.bw;
        else
            LineMask = true(size(cImage.bw));
        end

        LineScaleDown = OOPSData.Settings.AzimuthScaleDownFactor;
        
        if LineScaleDown > 1
            ScaleDownMask = makeSpacedCheckerboard(size(LineMask),LineScaleDown);
            LineMask = LineMask & logical(ScaleDownMask);
        end
        
        [y,x] = find(LineMask==1);
        theta = cImage.AzimuthImage(LineMask);
        rho = cImage.OrderImage(LineMask);
        
        ColorMode = OOPSData.Settings.AzimuthColorMode;
        LineWidth = OOPSData.Settings.AzimuthLineWidth;
        LineAlpha = OOPSData.Settings.AzimuthLineAlpha;
        LineScale = OOPSData.Settings.AzimuthLineScale;
        
        switch ColorMode
            case 'Magnitude'
                Colormap = OOPSData.Settings.OrderColormap;
            case 'Direction'
                Colormap = repmat(OOPSData.Settings.AzimuthColormap,2,1);
            case 'Mono'
                Colormap = [1 1 1];
        end
        
        OOPSData.Handles.AzimuthLines = QuiverPatch2(OOPSData.Handles.AverageIntensityAxH,...
            x,...
            y,...
            theta,...
            rho,...
            ColorMode,...
            Colormap,...
            LineWidth,...
            LineAlpha,...
            LineScale);

    catch
        disp('Warning: Error displaying azimuth sticks')
    end

end