function [] = ThresholdLineMoved(source,ThresholdLevel)
% Once the threshold slider is moved to final position, this function will
% calculate the new mask of the currently selected image, update the display,
% then detect the new objects defined by the mask
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

% currently selected image (first if multiple selected)
MainReplicate = OOPSData.CurrentImage(1);

switch MainReplicate.MaskType
    case 'Default'
        switch MainReplicate.MaskName
            case 'Puncta'
                % binarize at new threshold level
                bw = MainReplicate.EnhancedImg > ThresholdLevel;
                % clear 10 px around image borders
                bw = ClearImageBorder(bw,10);    
                % remove objects < 10 px
                CC = bwconncomp(bw,4);
                S = regionprops(CC, 'Area');
                L = labelmatrix(CC);
                bw = ismember(L, find([S.Area] >= 10));
                % store the mask and threshold level
                MainReplicate.bw = bw;
                MainReplicate.level = ThresholdLevel;
                % construct 4-connected label matrix
                MainReplicate.L = bwlabel(bw,4);
                % update log
                UpdateLog3(source,'Refining mask and updating object data...','append');
                % detect objects using the mask and label matrix
                MainReplicate.DetectObjects();
                % update ThresholdAdjusted status flag
                MainReplicate.ThresholdAdjusted = true;
                % update image AlphaData
                updateTempAlphaData(bw);
            case 'Adaptive'
                % get the image to segment
                IM = MainReplicate.EnhancedImg;
                % binarize the image with an adaptive local threshold
                bw = imbinarize(IM,adaptthresh(IM,ThresholdLevel,"NeighborhoodSize",3,"Statistic","gaussian"));
                % clear 10 px around the border
                bw = ClearImageBorder(bw,10);    
                % remove objects < 10 px
                CC = bwconncomp(bw,4);
                S = regionprops(CC, 'Area');
                L = labelmatrix(CC);
                bw = ismember(L, find([S.Area] >= 10));
                % store the mask and adaptive threshold sensitivity
                MainReplicate.bw = bw;
                MainReplicate.level = ThresholdLevel;
                % construct 4-connected label matrix
                MainReplicate.L = bwlabel(bw,4);
                % update the log
                UpdateLog3(source,'Refining mask and updating object data...','append');
                % detect objects using the mask and label matrix
                MainReplicate.DetectObjects();
                % update ThresholdAdjusted status flag
                MainReplicate.ThresholdAdjusted = 1;
                % update image AlphaData
                updateTempAlphaData(bw);
            otherwise
                return
        end
    case 'CustomScheme'
        % get the segmentation scheme
        customScheme = MainReplicate.CustomScheme;

        switch customScheme.ThreshType
            case 'Otsu'
                % binarize at new threshold level
                bw = MainReplicate.EnhancedImg > ThresholdLevel;
                % clear 10 px around the border
                bw = ClearImageBorder(bw,10);
                % now check for and run any operations after the thresh step
                if customScheme.ThreshStepIdx < customScheme.nOperations
                    customScheme.Operations(customScheme.ThreshStepIdx+1).Target.ImageData = bw;
                    customScheme.ExecuteFromStep(customScheme.ThreshStepIdx+1);
                    % if the output of the remaining steps is logical
                    if strcmp(customScheme.Images(end).ImageClass,'logical')
                        bw = customScheme.Images(end).ImageData;
                    end
                end
                % store the mask and threshold level
                MainReplicate.bw = bw;
                MainReplicate.level = ThresholdLevel;
                % construct 4-connected label matrix
                MainReplicate.L = bwlabel(bw,4);
                % update log
                UpdateLog3(source,'Refining mask and updating object data...','append');
                % detect objects using the mask and label matrix
                MainReplicate.DetectObjects();
                % update ThresholdAdjusted status flag
                MainReplicate.ThresholdAdjusted = 1;
                % update image AlphaData
                updateTempAlphaData(bw);
            case 'Adaptive'
                % get the image to segment
                IM = MainReplicate.EnhancedImg;
                % get adaptive threshold params
                statistic = customScheme.Operations(customScheme.ThreshStepIdx).ParamsMap('Statistic');
                neighborhoodSize = customScheme.Operations(customScheme.ThreshStepIdx).ParamsMap('NeighborhoodSize');
                % binarize the image with an adaptive local threshold
                bw = imbinarize(IM,...
                    adaptthresh(IM,ThresholdLevel,...
                    "NeighborhoodSize",neighborhoodSize,...
                    "Statistic",statistic));
                % clear 10 px around the border
                bw = ClearImageBorder(bw,10);
                % now check for and run any operations after the thresh step
                if customScheme.ThreshStepIdx < customScheme.nOperations
                    customScheme.Operations(customScheme.ThreshStepIdx+1).Target.ImageData = bw;
                    customScheme.ExecuteFromStep(customScheme.ThreshStepIdx+1);
                    % if the output of the remaining steps is logical
                    if strcmp(customScheme.Images(end).ImageClass,'logical')
                        bw = customScheme.Images(end).ImageData;
                    end
                end
                % store the mask and adaptive threshold sensitivity
                MainReplicate.bw = bw;
                MainReplicate.level = ThresholdLevel;
                % construct 4-connected label matrix
                MainReplicate.L = bwlabel(bw,4);
                % update log
                UpdateLog3(source,'Refining mask and updating object data...','append');
                % detect objects using the mask and label matrix
                MainReplicate.DetectObjects();
                % update ThresholdAdjusted status flag
                MainReplicate.ThresholdAdjusted = 1;
                % update image AlphaData
                updateTempAlphaData(bw);
        end
end

% update display
UpdateObjectListBox(source);
UpdateImages(source);
UpdateSummaryDisplay(source,{'Group','Image','Object'});
UpdateLabelTree(source);
UpdateLog3(source,'Done.','append');


    %% nested function to update image AlphaData

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