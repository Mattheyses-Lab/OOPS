function exportImages(source,~)
% exportImages  Prompts user to select save options, then saves selected outputs for the current image selection.

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
        'Mask'...
        };

    % get subcategory display names for each output category
    subCategories = cellfun(@(parentCategory) getSubCategories(parentCategory),saveCategories,'UniformOutput',false);

%% build the save option selection figure

    % the main figure window
    imageSelectionFig = uifigure('Name','Select images to export',...
        'Menubar','None',...
        'Position',[0 0 300 300],...
        'HandleVisibility','On',...
        'Visible','Off',...
        'CloseRequestFcn',@ContinueToSave);

    % the main gridlayout manager
    MainGrid = uigridlayout(imageSelectionFig,[2,1],...
        'BackgroundColor','Black',...
        'RowHeight',{'1x',20},...
        'ColumnWidth',{'1x'});

    % panel to hold the selection tree grid
    SaveOptionsPanel = uipanel(MainGrid,...
        'Title','Image types');

    % gridlayout manager to hold selection tree
    SaveOptionsTreeGrid = uigridlayout(SaveOptionsPanel,[1,1],...
        'BackgroundColor','Black',...
        'Padding',[0 0 0 0]);

    % uitree to hold save options
    SaveOptionsTree = uitree(SaveOptionsTreeGrid,'checkbox');
    % the top level nodes (image type categories)
    for categoryIdx = 1:numel(saveCategories)
        categoryNodes(categoryIdx) = uitreenode(SaveOptionsTree,...
            'Text',[saveCategories{categoryIdx},' (type, bit depth, format, scaling)'],...
            'NodeData',saveCategories{categoryIdx});

        % pull out the cell array of subcategories (the image types in this category)
        imageTypes = subCategories{categoryIdx};

        % add a child node for each image type in the category
        for subCategoryIdx = 1:numel(imageTypes)
            subCategoryNodes(subCategoryIdx) = ...
                uitreenode(categoryNodes(categoryIdx),'Text',imageTypes{subCategoryIdx},'NodeData',imageTypes{subCategoryIdx});
        end
    end

    % button to indicate completion, leads to selecting save directory
    uibutton(MainGrid,'Push',...
        'Text','Save',...
        'ButtonPushedFcn',@ContinueToSave);

    % move the window to the center before showing it
    movegui(imageSelectionFig,'center')
    % now show it
    imageSelectionFig.Visible = 'On';
    % initialize save choices cell
    UserSaveChoices = {};

%% nested callback executed when save button is pushed

    % callback for Btn to close fig
    function [] = ContinueToSave(~,~)
        if numel(SaveOptionsTree.CheckedNodes)>0
            % collect the selected options
            [UserSaveChoices{1:numel(SaveOptionsTree.CheckedNodes),1}] = deal(SaveOptionsTree.CheckedNodes.NodeData);
        end
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
        
        % control for mac vs pc
        if ismac || isunix
            loc = [pathname '/' cImage.rawFPMShortName];
        elseif ispc
            loc = [pathname '\' cImage.rawFPMShortName];
        end
        
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

        if any(strcmp(UserSaveChoices,'Average intensity (RGB, 8-bit, PNG, auto)'))
            name = [loc '-auto_scaled_average_intensity_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaxScaledAverageIntensityImageRGB;
            imwrite(IOut,name,'Software',softwareName);                
        end

        if any(strcmp(UserSaveChoices,'Average intensity (RGB, 8-bit, PNG, user)'))
            name = [loc '-user_scaled_average_intensity_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledAverageIntensityImageRGB;
            imwrite(IOut,name,'Software',softwareName);                
        end

        %% Order

        if any(strcmp(UserSaveChoices,'Order (grayscale, 32-bit, TIFF, none)'))
            name = [loc '-order_32_bit.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).OrderImage;
            write32BitTiff(IOut,name,'Software',softwareName);            
        end

        if any(strcmp(UserSaveChoices,'Order (RGB, 8-bit, PNG, auto)'))
            name = [loc '-auto_scaled_order_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaxScaledOrderImageRGB;
            imwrite(IOut,name,'Software',softwareName);            
        end

        if any(strcmp(UserSaveChoices,'Order (RGB, 8-bit, PNG, user)'))
            name = [loc '-user_scaled_order_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledOrderImageRGB;
            imwrite(IOut,name,'Software',softwareName);            
        end

        if any(strcmp(UserSaveChoices,'Order-intensity overlay (RGB, 8-bit, PNG, auto)'))
            name = [loc '-auto_scaled_order_intensity_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaxScaledOrderIntensityOverlayRGB;
            imwrite(IOut,name,'Software',softwareName);            
        end

        if any(strcmp(UserSaveChoices,'Order-intensity overlay (RGB, 8-bit, PNG, user)'))
            name = [loc '-user_scaled_order_intensity_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledOrderIntensityOverlayRGB;
            imwrite(IOut,name,'Software',softwareName);    
        end

        if any(strcmp(UserSaveChoices,'Masked order (RGB, 8-bit, PNG, none)'))
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

        if any(strcmp(UserSaveChoices,'Azimuth (RGB, 8-bit, PNG, none)'))
            name = [loc '-azimuth_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).AzimuthRGB;
            imwrite(IOut,name,'Software',softwareName);
        end

        if any(strcmp(UserSaveChoices,'Azimuth-intensity overlay (RGB, 8-bit, PNG, auto)'))
            name = [loc '-auto_scaled_azimuth_intensity_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).AzimuthIntensityOverlayRGB;
            imwrite(IOut,name,'Software',softwareName);
        end

        if any(strcmp(UserSaveChoices,'Azimuth-intensity overlay (RGB, 8-bit, PNG, user)'))
            name = [loc '-user_scaled_azimuth_intensity_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledAzimuthIntensityOverlayRGB;
            imwrite(IOut,name,'Software',softwareName);
        end

        if any(strcmp(UserSaveChoices,'Azimuth-order-intensity HSV overlay (RGB, 8-bit, PNG, auto)'))
            name = [loc '-auto_scaled_azimuth_order_intensity_HSV_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).AzimuthOrderIntensityHSV;
            imwrite(IOut,name,'Software',softwareName);
        end

        if any(strcmp(UserSaveChoices,'Azimuth-order-intensity HSV overlay (RGB, 8-bit, PNG, user)'))
            name = [loc '-user_scaled_azimuth_order_intensity_HSV_overlay_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).UserScaledAzimuthOrderIntensityHSV;
            imwrite(IOut,name,'Software',softwareName);
        end

        if any(strcmp(UserSaveChoices,'Masked azimuth (RGB, 8-bit, PNG, none)'))
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

        if any(strcmp(UserSaveChoices,'Mask (RGB, 8-bit, PNG, none)'))
            name = [loc '-mask_RGB.png'];
            UpdateLog3(source,name,'append');
            IOut = cImage(i).MaskRGBImage;
            imwrite(IOut,name,'Software',softwareName);
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
                    'Average intensity (RGB, 8-bit, PNG, auto)';...
                    'Average intensity (RGB, 8-bit, PNG, user)'...
                    };
            case 'Order'
                subCats = {...
                    'Order (grayscale, 32-bit, TIFF, none)';...
                    'Order (RGB, 8-bit, PNG, auto)';...
                    'Order (RGB, 8-bit, PNG, user)';...
                    'Order-intensity overlay (RGB, 8-bit, PNG, auto)';...
                    'Order-intensity overlay (RGB, 8-bit, PNG, user)';...
                    'Masked order (RGB, 8-bit, PNG, none)'
                    };
            case 'Azimuth'
                subCats = {...
                    'Azimuth (grayscale, 32-bit, TIFF, none)';...
                    'Azimuth (RGB, 8-bit, PNG, none)';...
                    'Azimuth-intensity overlay (RGB, 8-bit, PNG, auto)';...
                    'Azimuth-intensity overlay (RGB, 8-bit, PNG, user)';...
                    'Azimuth-order-intensity HSV overlay (RGB, 8-bit, PNG, auto)';...
                    'Azimuth-order-intensity HSV overlay (RGB, 8-bit, PNG, user)';...
                    'Masked azimuth (RGB, 8-bit, PNG, none)'...
                    };
            case 'Mask'
                subCats = {...
                    'Mask (grayscale, 8-bit, TIFF, none)';...
                    'Mask (RGB, 8-bit, PNG, none)'...
                    };
        end
    end

end