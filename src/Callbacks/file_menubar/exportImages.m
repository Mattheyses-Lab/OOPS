function exportImages(source,~)
% exportImages  Prompts user to select save options, then saves selected outputs for the current image selection.
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





    % handle to main data structure
    OOPSData = guidata(source);

    % currently selected images in the GUI
    cImage = OOPSData.CurrentImage;

    % number of images we are saving data for
    nImages = numel(cImage);

    % metadata to attach to the files
    softwareName = 'Object-Oriented Polarization Software (OOPS)';

    % the different output categories
    saveCategories = {...
        'Intensity';...
        'Order';...
        'Azimuth';...
        'Mask';...
        'Reference';...
        };

    % get subcategory display names for each output category
    subCategories = cellfun(@(parentCategory) getSubCategories(parentCategory),saveCategories,'UniformOutput',false);

%% build the save option selection figure

    % the main figure window
    imageSelectionFig = uifigure('Name','Export Images',...
        'Menubar','None',...
        'Position',[0 0 500 300],...
        'HandleVisibility','On',...
        'Visible','Off',...
        'CloseRequestFcn',@CloseAndCancel,...
        'Color',[0 0 0]);

    % the main gridlayout manager
    MainGrid = uigridlayout(imageSelectionFig,[2,1],...
        'BackgroundColor','Black',...
        'RowHeight',{'1x',20},...
        'ColumnWidth',{'1x'},...
        'RowSpacing',5,...
        'Padding',[5 5 5 5]);

    % panel to hold the selection tree grid
    SaveOptionsPanel = uipanel(MainGrid,...
        'Title','Image types',...
        'BackgroundColor',[0 0 0],...
        'ForegroundColor',[1 1 1],...
        'HighlightColor',[1 1 1],...
        'BorderColor',[1 1 1]);

    % gridlayout manager to hold selection tree
    SaveOptionsTreeGrid = uigridlayout(SaveOptionsPanel,[1,1],...
        'BackgroundColor','Black',...
        'Padding',[0 0 0 0]);

    % uitree to hold save options
    SaveOptionsTree = uitree(SaveOptionsTreeGrid,'checkbox',...
        'BackgroundColor',[0 0 0],...
        'FontColor',[1 1 1]);
    % the top level nodes (image type categories)
    for categoryIdx = 1:numel(saveCategories)
        categoryNodes(categoryIdx) = uitreenode(SaveOptionsTree,...
            'Text',[saveCategories{categoryIdx},' (color mode, bit depth, format, scaling)'],...
            'NodeData',saveCategories{categoryIdx});

        % pull out the cell array of subcategories (the image types in this category)
        imageTypes = subCategories{categoryIdx};

        % add a child node for each image type in the category
        for subCategoryIdx = 1:numel(imageTypes)
            subCategoryNodes(subCategoryIdx) = ...
                uitreenode(categoryNodes(categoryIdx),...
                'Text',imageTypes{subCategoryIdx},...
                'NodeData',imageTypes{subCategoryIdx});
        end
    end


    % grid to hold the buttons
    buttonGrid = uigridlayout(MainGrid,[1,2],...
        "BackgroundColor",[0 0 0],...
        "ColumnWidth",{'1x','1x'},...
        "RowHeight",{20},...
        "Padding",[0 0 0 0],...
        "ColumnSpacing",5);
    buttonGrid.Layout.Column = 1;
    buttonGrid.Layout.Row = 2;


    % button to cancel
    cancelButton = uibutton(buttonGrid,'Push',...
        'Text','Cancel',...
        'ButtonPushedFcn',@CloseAndCancel,...
        'BackgroundColor',[1 1 1],...
        'FontColor',[0 0 0],...
        'VerticalAlignment','center');
    cancelButton.Layout.Row = 1;
    cancelButton.Layout.Column = 1;

    % button to indicate completion, leads to selecting save directory
    continueButton = uibutton(buttonGrid,'Push',...
        'Text','Choose save directory',...
        'ButtonPushedFcn',@CloseAndContinue,...
        'BackgroundColor',[1 1 1],...
        'FontColor',[0 0 0],...
        'VerticalAlignment','center');
    continueButton.Layout.Row = 1;
    continueButton.Layout.Column = 2;

    % move the window to the center before showing it
    movegui(imageSelectionFig,'center')
    % now show it
    imageSelectionFig.Visible = 'On';
    % initialize save choices cell
    UserSaveChoices = {};

%% nested callback executed when save button is pushed

    % callback for Btn to continue to choose save directory
    function [] = CloseAndContinue(~,~)
        if numel(SaveOptionsTree.CheckedNodes)>0
            % collect the selected options
            [UserSaveChoices{1:numel(SaveOptionsTree.CheckedNodes),1}] = deal(SaveOptionsTree.CheckedNodes.NodeData);
        end
        % delete the figure
        delete(imageSelectionFig)
    end

    % callback for cancel button
    function CloseAndCancel(~,~)
        % delete the figure
        delete(imageSelectionFig)
    end

%% ensure valid selection

    % wait until fig deleted (by 'X' or continue button)
    waitfor(imageSelectionFig);
    % then check for valid input
    if isempty(UserSaveChoices)
        UpdateLog3(source,'No options selected.','append');
        % turn main fig back on
        OOPSData.Handles.fH.Visible = 'On';
        return
    end

%% choose save directory

    uialert(OOPSData.Handles.fH,'Choose directory','Select export folder',...
        'Icon','',...
        'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));

    uiwait(OOPSData.Handles.fH);

    OOPSData.Handles.fH.Visible = 'Off';

    try
        pathname = uigetdir('*.mat','Choose directory',OOPSData.Settings.LastDirectory);
    catch
        pathname = uigetdir('*.mat','Choose directory');
    end

    OOPSData.Handles.fH.Visible = 'On';

    figure(OOPSData.Handles.fH);

    if ~pathname
        uialert(OOPSData.Handles.fH,'Invalid filename...','Error');
        return
    else
        OOPSData.Settings.LastDirectory = pathname;
    end

%% for each OOPSImage, write each image type specified by the user

    % save user-specified data for each currently selected image
    for i = 1:nImages

        if ismac || isunix
            pathSep = '/';
        elseif ispc
            pathSep = '\';
        end

        % name for the directory in which the output images for this image will be saved
        newDirName = [pathname,pathSep,cImage(i).rawFPMShortName];

        try
            % create the new directory
            mkdir(newDirName)
        catch
            % if unable to create directory, warn the user
            UpdateLog3(source,['Warning: Unable to create directory: ',newDirName],'append');
            % then continue to the next image
            continue
        end

        % base name for each exported image, including file path
        loc = [pathname,pathSep,cImage(i).rawFPMShortName,pathSep,cImage(i).rawFPMShortName];
        
        % % control for mac vs pc
        % if ismac || isunix
        %     newDirName = [pathname '/' cImage(i).rawFPMShortName];
        %     try
        %         % create a new folder in the specified directory with the short name of the image
        %         mkdir(newDirName)
        %     catch
        %         % if unable to create directory, warn the user
        %         UpdateLog3(source,['Warning: Unable to create directory: ',newDirName],'append');
        %         % then continue to the next image
        %         continue
        %     end
        %     loc = [pathname '/' cImage(i).rawFPMShortName '/' cImage(i).rawFPMShortName];
        % elseif ispc
        %     loc = [pathname '\' cImage(i).rawFPMShortName '\' cImage(i).rawFPMShortName];
        % end
        
        %% Intensity

        if any(strcmp(UserSaveChoices,'Average intensity (grayscale, 8-bit, TIFF, none)'))
            name = [loc '-average_intensity_8_bit.tif'];
            UpdateLog3(source,name,'append');
            IOut = im2uint8(cImage(i).ffcFPMAverage./65535);
            imwrite(IOut,OOPSData.Settings.IntensityColormap,name);                
        end

        if any(strcmp(UserSaveChoices,'Average intensity (grayscale, 16-bit, TIFF, none)'))
            name = [loc '-average_intensity_16_bit.tif'];
            UpdateLog3(source,name,'append');
            IOut = im2uint16(cImage(i).ffcFPMAverage./65535);
            write16BitTiff(IOut,name,'Software',softwareName);                
        end

        if any(strcmp(UserSaveChoices,'Average intensity (RGB, 24-bit, PNG, auto)'))
            name = [loc '-auto_scaled_average_intensity_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaxScaledAverageIntensityImageRGB;
            % dynamic range used to export the intensity image
            intensityDisplayRange = [0, max(max(cImage(i).ffcFPMAverage))];
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Intensity Display Range: ',intensityDisplayRangeChar]);                
        end

        if any(strcmp(UserSaveChoices,'Average intensity (RGB, 24-bit, PNG, user)'))
            name = [loc '-user_scaled_average_intensity_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledAverageIntensityImageRGB;
            % dynamic range used to export the intensity image
            intensityDisplayRange = cImage(i).PrimaryIntensityDisplayLimits.*cImage(i).averageIntensityRealLimits(2);
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Intensity Display Range: ',intensityDisplayRangeChar]);                
        end

        %% Order

        if any(strcmp(UserSaveChoices,'Order (grayscale, 32-bit, TIFF, none)'))
            name = [loc '-order_32_bit.tif'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).OrderImage;
            write32BitTiff(IOut,name,'Software',softwareName);            
        end

        if any(strcmp(UserSaveChoices,'Order (RGB, 24-bit, PNG, auto)'))
            name = [loc '-auto_scaled_order_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaxScaledOrderImageRGB;
            % dynamic range used to export the order image
            orderDisplayRange = [0 max(max(cImage(i).OrderImage))];
            % char vector to store the display range in the PNG 'comment' field
            orderDisplayRangeChar = makeDislpayRangeChar(round(orderDisplayRange,2));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Order Display Range: ',orderDisplayRangeChar]);            
        end

        if any(strcmp(UserSaveChoices,'Order (RGB, 24-bit, PNG, user)'))
            name = [loc '-user_scaled_order_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledOrderImageRGB;
            % dynamic range used to export the order image
            orderDisplayRange = cImage(i).OrderDisplayLimits;
            % char vector to store the display range in the PNG 'comment' field
            orderDisplayRangeChar = makeDislpayRangeChar(round(orderDisplayRange,2));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Order Display Range: ',orderDisplayRangeChar]);            
        end

        if any(strcmp(UserSaveChoices,'Order-intensity overlay (RGB, 24-bit, PNG, auto)'))
            name = [loc '-auto_scaled_order_intensity_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaxScaledOrderIntensityOverlayRGB;
            % dynamic range used to export the order image
            orderDisplayRange = [0 max(max(cImage(i).OrderImage))];
            % char vector to store the display range in the PNG 'comment' field
            orderDisplayRangeChar = makeDislpayRangeChar(round(orderDisplayRange,2));
            % dynamic range used to export the intensity image
            intensityDisplayRange = [0, max(max(cImage(i).ffcFPMAverage))];
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Order Display Range: ',orderDisplayRangeChar,' | ',...
                'Intensity Display Range: ',intensityDisplayRangeChar]);            
        end

        if any(strcmp(UserSaveChoices,'Order-intensity overlay (RGB, 24-bit, PNG, user)'))
            name = [loc '-user_scaled_order_intensity_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledOrderIntensityOverlayRGB;
            % dynamic range used to export the order image
            orderDisplayRange = cImage(i).OrderDisplayLimits;
            % char vector to store the display range in the PNG 'comment' field
            orderDisplayRangeChar = makeDislpayRangeChar(round(orderDisplayRange,2));
            % dynamic range used to export the intensity image
            intensityDisplayRange = cImage(i).PrimaryIntensityDisplayLimits.*cImage(i).averageIntensityRealLimits(2);
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Order Display Range: ',orderDisplayRangeChar,' | ',...
                'Intensity Display Range: ',intensityDisplayRangeChar]); 
        end

        if any(strcmp(UserSaveChoices,'Masked order (RGB, 24-bit, PNG, none)'))
            name = [loc '-masked_order_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaskedOrderImageRGB;
            imwrite(IOut,name,'Software',softwareName);         
        end

        %% Azimuth

        if any(strcmp(UserSaveChoices,'Azimuth (grayscale, 32-bit, TIFF, none)'))
            name = [loc '-azimuth_32_bit.tif'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).AzimuthImage;
            write32BitTiff(IOut,name,'Software',softwareName);
        end

        if any(strcmp(UserSaveChoices,'Azimuth (RGB, 24-bit, PNG, none)'))
            name = [loc '-azimuth_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).AzimuthRGB;
            imwrite(IOut,name,'Software',softwareName);
        end

        if any(strcmp(UserSaveChoices,'Azimuth-intensity overlay (RGB, 24-bit, PNG, auto)'))
            name = [loc '-auto_scaled_azimuth_intensity_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).AzimuthIntensityOverlayRGB;
            % dynamic range used to export the order image
            orderDisplayRange = [0 max(max(cImage(i).OrderImage))];
            % char vector to store the display range in the PNG 'comment' field
            orderDisplayRangeChar = makeDislpayRangeChar(round(orderDisplayRange,2));
            % dynamic range used to export the intensity image
            intensityDisplayRange = [0, max(max(cImage(i).ffcFPMAverage))];
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Order Display Range: ',orderDisplayRangeChar,' | ',...
                'Intensity Display Range: ',intensityDisplayRangeChar]);
        end

        if any(strcmp(UserSaveChoices,'Azimuth-intensity overlay (RGB, 24-bit, PNG, user)'))
            name = [loc '-user_scaled_azimuth_intensity_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledAzimuthIntensityOverlayRGB;
            % dynamic range used to export the order image
            orderDisplayRange = cImage(i).OrderDisplayLimits;
            % char vector to store the display range in the PNG 'comment' field
            orderDisplayRangeChar = makeDislpayRangeChar(round(orderDisplayRange,2));
            % dynamic range used to export the intensity image
            intensityDisplayRange = cImage(i).PrimaryIntensityDisplayLimits.*cImage(i).averageIntensityRealLimits(2);
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Order Display Range: ',orderDisplayRangeChar,' | ',...
                'Intensity Display Range: ',intensityDisplayRangeChar]);
        end

        if any(strcmp(UserSaveChoices,'Azimuth-order-intensity HSV overlay (RGB, 24-bit, PNG, auto)'))
            name = [loc '-auto_scaled_azimuth_order_intensity_HSV_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).AzimuthOrderIntensityHSV;
            % dynamic range used to export the order image
            orderDisplayRange = [0 max(max(cImage(i).OrderImage))];
            % char vector to store the display range in the PNG 'comment' field
            orderDisplayRangeChar = makeDislpayRangeChar(round(orderDisplayRange,2));
            % dynamic range used to export the intensity image
            intensityDisplayRange = [0, max(max(cImage(i).ffcFPMAverage))];
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Order Display Range: ',orderDisplayRangeChar,' | ',...
                'Intensity Display Range: ',intensityDisplayRangeChar]);
        end

        if any(strcmp(UserSaveChoices,'Azimuth-order-intensity HSV overlay (RGB, 24-bit, PNG, user)'))
            name = [loc '-user_scaled_azimuth_order_intensity_HSV_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledAzimuthOrderIntensityHSV;
            % dynamic range used to export the order image
            orderDisplayRange = cImage(i).OrderDisplayLimits;
            % char vector to store the display range in the PNG 'comment' field
            orderDisplayRangeChar = makeDislpayRangeChar(round(orderDisplayRange,2));
            % dynamic range used to export the intensity image
            intensityDisplayRange = cImage(i).PrimaryIntensityDisplayLimits.*cImage(i).averageIntensityRealLimits(2);
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Order Display Range: ',orderDisplayRangeChar,' | ',...
                'Intensity Display Range: ',intensityDisplayRangeChar]);
        end

        if any(strcmp(UserSaveChoices,'Masked azimuth (RGB, 24-bit, PNG, none)'))
            name = [loc '-masked_azimuth_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaskedAzimuthRGB;
            imwrite(IOut,name,'Software',softwareName);
        end

        %% Mask

        if any(strcmp(UserSaveChoices,'Mask (grayscale, 8-bit, TIFF, none)'))
            name = [loc '-mask_8_bit.tif'];
            UpdateLog3(source,name,'append');
            IOut = im2uint8(full(cImage(i).bw));
            Write8BitTiff(IOut,name,'Software',softwareName);
            % imwrite(IOut,name,'Software',softwareName);
        end

        if any(strcmp(UserSaveChoices,'Mask (RGB, 24-bit, PNG, none)'))
            name = [loc '-mask_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaskRGBImage;
            imwrite(IOut,name,'Software',softwareName);
        end

        %% Reference

        if any(strcmp(UserSaveChoices,'Reference (grayscale, 16-bit, TIFF, none)'))
            name = [loc '-reference_16_bit.tif'];
            UpdateLog3(source,name,'append');
            rawReferenceRange = getrangefromclass(cImage(i).rawReferenceImage);
            rawReferenceDouble = im2double(cImage(i).rawReferenceImage).*rawReferenceRange(2);
            IOut = im2uint16(rawReferenceDouble./65535);
            write16BitTiff(IOut,name,'Software',softwareName);
        end

        if any(strcmp(UserSaveChoices,'Reference (RGB, 24-bit, PNG, auto)'))
            name = [loc '-auto_scaled_reference_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).ReferenceImageRGB;
            % dynamic range used to export the reference image
            referenceDisplayRange = [min(min(cImage(i).rawReferenceImage)), max(max(cImage(i).rawReferenceImage))];
            % char vector to store the display range in the PNG 'comment' field
            referenceDisplayRangeChar = makeDislpayRangeChar(round(referenceDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Reference Display Range: ',referenceDisplayRangeChar]);
        end

        if any(strcmp(UserSaveChoices,'Reference (RGB, 24-bit, PNG, user)'))
            name = [loc '-user_scaled_reference_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledReferenceImageRGB;

            rawReferenceRange = getrangefromclass(cImage(i).rawReferenceImage);
            rawReferenceDouble = im2double(cImage(i).rawReferenceImage).*rawReferenceRange(2);

            userReferenceDisplayLimits = cImage(i).ReferenceIntensityDisplayLimits;
            lowerLim = userReferenceDisplayLimits(1).*max(max(rawReferenceDouble)) + min(min(rawReferenceDouble));
            upperLim = userReferenceDisplayLimits(2).*max(max(rawReferenceDouble));

            % dynamic range used to export the reference image
            referenceDisplayRange = [lowerLim, upperLim];
            % char vector to store the display range in the PNG 'comment' field
            referenceDisplayRangeChar = makeDislpayRangeChar(round(referenceDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Reference Display Range: ',referenceDisplayRangeChar]);
        end

        if any(strcmp(UserSaveChoices,'Intensity-reference composite (RGB, 24-bit, PNG, auto)'))
            name = [loc '-auto_scaled_intensity_reference_composite_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaxScaledAverageIntensityImageRGB + cImage(i).ReferenceImageRGB;
            % dynamic range used to export the reference image
            referenceDisplayRange = [min(min(cImage(i).rawReferenceImage)), max(max(cImage(i).rawReferenceImage))];
            % char vector to store the display range in the PNG 'comment' field
            referenceDisplayRangeChar = makeDislpayRangeChar(round(referenceDisplayRange));
            % dynamic range used to export the intensity image
            intensityDisplayRange = [0, max(max(cImage(i).ffcFPMAverage))];
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Intensity Display Range: ',intensityDisplayRangeChar,' | ',...
                'Reference Display Range: ',referenceDisplayRangeChar]);
        end

        if any(strcmp(UserSaveChoices,'Intensity-reference composite (RGB, 24-bit, PNG, user)'))
            name = [loc '-user_scaled_intensity_reference_composite_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledAverageIntensityReferenceCompositeRGB;

            rawReferenceRange = getrangefromclass(cImage(i).rawReferenceImage);
            rawReferenceDouble = im2double(cImage(i).rawReferenceImage).*rawReferenceRange(2);


            userReferenceDisplayLimits = cImage(i).ReferenceIntensityDisplayLimits;
            lowerLim = userReferenceDisplayLimits(1).*max(max(rawReferenceDouble)) + min(min(rawReferenceDouble));
            upperLim = userReferenceDisplayLimits(2).*max(max(rawReferenceDouble));

            % dynamic range used to export the reference image
            referenceDisplayRange = [lowerLim, upperLim];
            % char vector to store the display range in the PNG 'comment' field
            referenceDisplayRangeChar = makeDislpayRangeChar(round(referenceDisplayRange));
            % dynamic range used to export the intensity image
            intensityDisplayRange = cImage(i).PrimaryIntensityDisplayLimits.*cImage(i).averageIntensityRealLimits(2);
            % char vector to store the display range in the PNG 'comment' field
            intensityDisplayRangeChar = makeDislpayRangeChar(round(intensityDisplayRange));
            % write the image data
            imwrite(IOut,name,'Software',softwareName,...
                'Comment',['Intensity Display Range: ',intensityDisplayRangeChar,' | ',...
                'Reference Display Range: ',referenceDisplayRangeChar]);
        end

    end % end of main save loop

    % indicate completion
    UpdateLog3(source,'Done.','append');

%% nested helper function to list save options    

    function subCats = getSubCategories(categoryName)
        switch categoryName
            case 'Intensity'
                subCats = {...
                    'Average intensity (grayscale, 8-bit, TIFF, none)';...
                    'Average intensity (grayscale, 16-bit, TIFF, none)';...
                    'Average intensity (RGB, 24-bit, PNG, auto)';...
                    'Average intensity (RGB, 24-bit, PNG, user)'...
                    };
            case 'Order'
                subCats = {...
                    'Order (grayscale, 32-bit, TIFF, none)';...
                    'Order (RGB, 24-bit, PNG, auto)';...
                    'Order (RGB, 24-bit, PNG, user)';...
                    'Order-intensity overlay (RGB, 24-bit, PNG, auto)';...
                    'Order-intensity overlay (RGB, 24-bit, PNG, user)';...
                    'Masked order (RGB, 24-bit, PNG, none)'
                    };
            case 'Azimuth'
                subCats = {...
                    'Azimuth (grayscale, 32-bit, TIFF, none)';...
                    'Azimuth (RGB, 24-bit, PNG, none)';...
                    'Azimuth-intensity overlay (RGB, 24-bit, PNG, auto)';...
                    'Azimuth-intensity overlay (RGB, 24-bit, PNG, user)';...
                    'Azimuth-order-intensity HSV overlay (RGB, 24-bit, PNG, auto)';...
                    'Azimuth-order-intensity HSV overlay (RGB, 24-bit, PNG, user)';...
                    'Masked azimuth (RGB, 24-bit, PNG, none)'...
                    };
            case 'Mask'
                subCats = {...
                    'Mask (grayscale, 8-bit, TIFF, none)';...
                    'Mask (RGB, 24-bit, PNG, none)'...
                    };
            case 'Reference'
                subCats = {...
                    'Reference (grayscale, 16-bit, TIFF, none)';...
                    'Reference (RGB, 24-bit, PNG, auto)';...
                    'Reference (RGB, 24-bit, PNG, user)';...
                    'Intensity-reference composite (RGB, 24-bit, PNG, auto)';...
                    'Intensity-reference composite (RGB, 24-bit, PNG, user)';...
                    };
        end
    end

%% helper function to convert display range to a character vector for export

    function displayRangeChar = makeDislpayRangeChar(displayRange)
        displayRangeChar = ['[',num2str(displayRange(1)),',',num2str(displayRange(2)),']'];
    end

end