function [] = ThresholdLineMoving(source,ThresholdLevel)
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

    MainReplicate = OOPSData.CurrentImage(1);

    rows = MainReplicate.Height;
    cols = MainReplicate.Width;


    switch MainReplicate.MaskType
        case 'Default'
            switch MainReplicate.MaskName
                case 'Legacy'
                    %IM = MainReplicate.EnhancedImg;
        
                    bw = MainReplicate.EnhancedImg > ThresholdLevel;
                    
                    % clear 10 px around image borders
                    bw(1:10,1:end) = 0;
                    bw(1:end,1:10) = 0;
                    bw(rows-9:end,1:end) = 0;
                    bw(1:end,cols-9:end) = 0;
                
                    % remove objects < 10 px
                    CC = bwconncomp(bw,4);
                    S = regionprops(CC, 'Area');
                    L = labelmatrix(CC);
                    bw = ismember(L, find([S.Area] >= 10));
        
                
                    MainReplicate.bw = bw;
                    MainReplicate.level = ThresholdLevel;
                    MainReplicate.ObjectDetectionDone = false;
                
                    %OOPSData.Handles.MaskImgH.CData = bw;

                    updateTempAlphaData(bw);

                case 'Adaptive'
                    IM = MainReplicate.I;
        
                    bw = imbinarize(IM,adaptthresh(IM,ThresholdLevel,"NeighborhoodSize",3,"Statistic","gaussian"));
        
                    % clear 10 px around image borders
                    bw = ClearImageBorder(bw,10);
        
                    % remove objects < 10 px
                    CC = bwconncomp(bw,4);
                    S = regionprops(CC, 'Area');
                    L = labelmatrix(CC);
                    bw = ismember(L, find([S.Area] >= 10));
        
                    MainReplicate.bw = bw;
                    MainReplicate.level = ThresholdLevel;
        
                    MainReplicate.ObjectDetectionDone = false;
                    % update mask display
                    %OOPSData.Handles.MaskImgH.CData = bw;

                    updateTempAlphaData(bw);

                otherwise
                    return
            end
        case 'CustomScheme'

            customScheme = MainReplicate.CustomScheme;

            switch customScheme.ThreshType
                case 'Otsu'
                    bw = MainReplicate.EnhancedImg > ThresholdLevel;
                    
                    % clear 10 px around image borders
                    bw(1:10,1:end) = 0;
                    bw(1:end,1:10) = 0;
                    bw(rows-9:end,1:end) = 0;
                    bw(1:end,cols-9:end) = 0;

                    MainReplicate.bw = bw;
                    MainReplicate.level = ThresholdLevel;
                    MainReplicate.ObjectDetectionDone = false;
                
                    %OOPSData.Handles.MaskImgH.CData = bw;

                    updateTempAlphaData(bw);

                case 'Adaptive'
                    IM = MainReplicate.EnhancedImg;

                    statistic = customScheme.Operations(customScheme.ThreshStepIdx).ParamsMap('Statistic');
                    neighborhoodSize = customScheme.Operations(customScheme.ThreshStepIdx).ParamsMap('NeighborhoodSize');
        
                    bw = imbinarize(IM,...
                        adaptthresh(IM,ThresholdLevel,...
                        "NeighborhoodSize",neighborhoodSize,...
                        "Statistic",statistic));
        
                    % clear 10 px around image borders
                    bw = ClearImageBorder(bw,10);
        
                    MainReplicate.bw = bw;
                    MainReplicate.level = ThresholdLevel;
        
                    MainReplicate.ObjectDetectionDone = false;
                    % update mask display
                    %OOPSData.Handles.MaskImgH.CData = bw;

                    updateTempAlphaData(bw);
            end

    end

    UpdateSummaryDisplay(source,{'Group','Image','DataOnly'});

    function updateTempAlphaData(alphaData)
        switch OOPSData.Settings.CurrentTab
            case {'Files','FFC','Objects','Plots','Polar Plots'}
                return
            case 'Mask'
                OOPSData.Handles.MaskImgH.CData = alphaData;
            case 'Order'
                if OOPSData.Handles.ApplyMaskOrder.Value
                    OOPSData.Handles.OrderImgH.AlphaData = alphaData;
                end
            case 'Azimuth'
                if OOPSData.Handles.ApplyMaskAzimuth.Value
                    OOPSData.Handles.AzimuthImgH.AlphaData = alphaData;
                end
            otherwise
                if OOPSData.Handles.ApplyMaskCustomStat.Value
                    OOPSData.Handles.CustomStatImgH.AlphaData = alphaData;
                end
        end
    end

end