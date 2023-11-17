function Scheme = CustomMaskMaker(InputImage,InputScheme,Inputcmap)
%%  CUSTOMMASKMAKER GUI for creating custom segmentation schemes
%
%   NOTES:
%       CustomMaskMaker was designed to facilitate the design of custom
%       segmentation schemes in Object-Oriented Polarization Software (OOPS),
%       but it can also be used independently.
%
%       If you use this function outside of OOPS, you will still need several
%       dependencies which are in various locations in the OOPS file structure.
%
%   See also CustomMask, CustomOperation, CustomImage
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

    try
        Colormaps_mat_file = load('Colormaps.mat');
        tempColormaps = Colormaps_mat_file.Colormaps;
        colormapNames = fieldnames(tempColormaps);
        Colormaps = struct();
        for colormapIdx = 1:numel(colormapNames)
            Colormaps.(colormapNames{colormapIdx}) = tempColormaps.(colormapNames{colormapIdx}).Map;
        end
    catch
        warning("Failed to load colormaps...");
    end

    % make some defaults just in case colormaps file couldn't be loaded
    Colormaps.Gray = gray;
    Colormaps.Jet = jet;
    Colormaps.Turbo = turbo;

    if isempty(Inputcmap)
        % set the default current colormap
        CurrentColormap = Colormaps.Turbo;
    else
        CurrentColormap = Inputcmap;
    end

    % this will hold an array with name-value pairs for the current image operation
    NamedParams = {};

    % make sure class of input image is double
    InputImage = im2double(InputImage);

    if isempty(InputScheme)
        % Create an instance of CustomMask
        Scheme = CustomMask('Custom',InputImage);
    else
        % Use the scheme that was included as input by user
        Scheme = InputScheme;
        Scheme.StartingImage = InputImage;
        Scheme.Execute();
    end

    % Create the main figure
    fHMaskMaker = uifigure("Name","Mask Maker",...
        "NumberTitle","off",...
        "Units","pixels",...
        "WindowStyle","normal",...
        "Position",[100 100 1200 600],...
        "Visible","off",...
        "AutoResizeChildren","off",...
        "HandleVisibility","On");

    % move main window to center of display
    movegui(fHMaskMaker,"center");

%% set up menu bar

    % edit menu
    EditMenu = uimenu(fHMaskMaker,'text','&Edit');
    % edit menu options
    EditMenuDeleteOperation = uimenu(EditMenu,'text','&Delete Operation');
    EditMenuDeleteOperation.Accelerator = 'D';
    EditMenuDeleteOperation.Callback = @DeleteOperation;

    % tools menu
    ToolsMenu = uimenu(fHMaskMaker,'text','Tools');
    % tools menu options
    ToolsMenuContrast = uimenu(ToolsMenu,'text','Contrast Tool');
    ToolsMenuContrast.Callback = @OpenContrastTool;

    ToolsMenuPixelRegion = uimenu(ToolsMenu,'text','Pixel Region Tool');
    ToolsMenuPixelRegion.Callback = @OpenPixelRegionTool;

    % colormaps menu
    ColormapsMenu = uimenu(fHMaskMaker,'Text','Colormaps');
    % colormaps options
    ColormapsFieldNames = fieldnames(Colormaps);
    for i = 1:numel(ColormapsFieldNames)
        ColormapsMenuOptions(i) = uimenu(ColormapsMenu,'Text',ColormapsFieldNames{i},'Callback',@ChangeColormap);
    end

    % call drawnow before placing grid
    drawnow
    pause(0.5)

%% main grid layout manager

    MainGrid = uigridlayout(fHMaskMaker,[2 3],'BackgroundColor','Black');
    MainGrid.ColumnWidth = {'0.5x',500,'1x'};
    MainGrid.RowHeight = {'1x','1x'};
    MainGrid.Padding = [5 5 5 5];
    MainGrid.RowSpacing = 5;
    MainGrid.ColumnSpacing = 5;

%% Left Panel

    % panel to hold image step selector
    OperationSelectorPanel = uipanel(MainGrid,"Title","Processing Steps","AutoResizeChildren","off");
    OperationSelectorPanel.Layout.Row = 1;
    OperationSelectorPanel.Layout.Column = 1;

    % grid in panel to hold image step selector
    OperationSelectorPanelGrid = uigridlayout(OperationSelectorPanel,[1 1]);
    OperationSelectorPanelGrid.ColumnWidth = {'1x'};
    OperationSelectorPanelGrid.RowHeight = {'1x'};
    OperationSelectorPanelGrid.Padding = [0 0 0 0];

    % operation step selector
    OperationSelector = uilistbox(OperationSelectorPanelGrid,...
        "Items",Scheme.OperationsTextDisplay,...
        "ItemsData",1:Scheme.nOperations,...
        "Value",1,...
        "Tag",'OperationSelector',...
        "ValueChangedFcn",@OperationSelectionChanged,...
        "Multiselect","off");

    % panel to hold image step selector
    ImageSelectorPanel = uipanel(MainGrid,"Title","Images","AutoResizeChildren","off");
    ImageSelectorPanel.Layout.Row = 2;
    ImageSelectorPanel.Layout.Column = 1;

    % grid in panel to hold image step selector
    ImageSelectorPanelGrid = uigridlayout(ImageSelectorPanel,[1 1]);
    ImageSelectorPanelGrid.ColumnWidth = {'1x'};
    ImageSelectorPanelGrid.RowHeight = {'1x'};
    ImageSelectorPanelGrid.Padding = [0 0 0 0];

    % image step selector
    ImageSelector = uilistbox(ImageSelectorPanelGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",1:Scheme.nImages,...
        "Value",1,...
        "Tag",'ImageSelector',...
        "ValueChangedFcn",@ImageSelectionChanged,...
        "Multiselect","off");

    % call drawnow and wait for a moment before continuing
    drawnow
    pause(1)

%% Center panel

    % panel to hold image display axes
    ImageDisplayPanel = uipanel(MainGrid,"AutoResizeChildren","Off");
    ImageDisplayPanel.Layout.Column = 2;
    ImageDisplayPanel.Layout.Row = [1 2];

    % image display axes
    ImageDisplayAxes = uiaxes(ImageDisplayPanel,...
        "Units","normalized",...
        "InnerPosition",[0 0 1 1],...
        "XTick",[],...
        "YTick",[],...
        "Tag","ImageDisplayAxes");

    % store the tag so we can reset after calling imshow()
    OriginalTag = ImageDisplayAxes.Tag;

    % create image object for currently displayed image (InputImage to start)
    hImage = imshow(InputImage,"Parent",ImageDisplayAxes);

    % set default colormap
    ImageDisplayAxes.Colormap = CurrentColormap;

    % restore axis props that were changed by imshow()
    ImageDisplayAxes.YDir = 'reverse';
    ImageDisplayAxes.PlotBoxAspectRatioMode = 'manual';
    ImageDisplayAxes.PlotBoxAspectRatio = [1 1 1];
    ImageDisplayAxes.XTick = [];
    ImageDisplayAxes.YTick = [];
    ImageDisplayAxes.Tag = OriginalTag;

    % create an empty custom toolbar for the axes
    tb = axtoolbar(ImageDisplayAxes,{});
    % clear all of the default interactions
    ImageDisplayAxes.Interactions = [];

    % add a custom toolbar button for pan/zoom to cursor behavior 
    btn = axtoolbarbtn(tb,'state');
    btn.Icon = 'MagnifyingGlassIcon.png';
    btn.ValueChangedFcn = @generalZoomToCursor;
    btn.Tag = ['ZoomToCursor',ImageDisplayAxes.Tag];
    btn.Tooltip = 'Zoom to cursor';

    % disable default interactivity for the axes
    disableDefaultInteractivity(ImageDisplayAxes);

%% Right panel

    NewOperationGrid = uigridlayout(MainGrid,[4,2],'BackgroundColor','Black');
    NewOperationGrid.Layout.Column = 3;
    NewOperationGrid.Layout.Row = [1 2];
    NewOperationGrid.RowHeight = {'1x','1x','1x',20};
    NewOperationGrid.ColumnWidth = {'1x','1x'};
    NewOperationGrid.Padding = [0 0 0 0];
    NewOperationGrid.RowSpacing = 5;

    OperationTypeSelectorPanel = uipanel(NewOperationGrid,...
        "Title","Operation Type");
    OperationTypeSelectorPanel.Layout.Row = 1;
    OperationTypeSelectorPanel.Layout.Column = [1 2];

    OperationTypeSelectorPanelGrid = uigridlayout(OperationTypeSelectorPanel,[1 1]);
    OperationTypeSelectorPanelGrid.Padding = [0 0 0 0];

    OperationTypeSelector = uilistbox(OperationTypeSelectorPanelGrid,...
        "Items",Scheme.OperationTypes,...
        "ValueChangedFcn",@OperationTypeChanged);
    
    OperationNameSelectorPanel = uipanel(NewOperationGrid,...
        "Title","Operation Name");
    OperationNameSelectorPanel.Layout.Row = 2;
    OperationNameSelectorPanel.Layout.Column = [1 2];

    OperationNameSelectorPanelGrid = uigridlayout(OperationNameSelectorPanel,[1 1]);
    OperationNameSelectorPanelGrid.Padding = [0 0 0 0];

    OperationNameSelector = uilistbox(OperationNameSelectorPanelGrid,...
        "Items",Scheme.MorphologicalOperations,...
        "ValueChangedFcn",@OperationNameChanged);

    OperationParamsPanel = uipanel(NewOperationGrid,...
        "Title","TopHat Options");
    OperationParamsPanel.Layout.Row = 3;
    OperationParamsPanel.Layout.Column = [1 2];

%% From here up until the nested functions are all graphics objects needed to adjust parameters of each operation

% general idea is that the 'Tag' property of objects will indicate the type of operation
%   ('MorphologicalOperations','ImageFilterOperations',etc.)
% the 'UserData' property will indicate the name of the operation
%   ('Open','Close','+','÷','AdjustContrast',etc.)
% 
% in this way, we can hide/show objects without having to call each of them by name
%   (there are some exceptions, such as operations that require a more complicated set of parameters)
% Also, Target labels and dropdowns are unique to each Operation 'Type'
% still, it should be straightforward to add new operations by following the general strategy below, and making the
%   corresponding adjustments to CustomMask.m and CustomOperation.m

% the easiest way to add custom operations (which bypasses the need for creating new graphics objects) is as follows:
% 1. Add the operation name to the end of the cell array "SpecialOperations" in CustomMask.m
% 2. Add the operation code to CustomOperation.m
% 2a.   Locate the main switch block in the Execute() method
% 2b.   Scroll down to "case 'Special'"
% 2c.   In the switch block inside "case 'Special'", add a new statement: "case 'XXX'", 
%       where XXX is the name of your operation
% 3. Edit the new case statement
% 3a.   In the first line, get the target image data with: "I = obj.Target.ImageData;"
% 3b.   In the following lines, add whatever code defines your operation by working with 'I'
%           example, for a tophat filter: I = I - imopen(I);
% 3d.   In the final line, set the output data with: OutputImage = I;
% 4. When you next open CustomMaskMaker.m, your operation should appear in the OperationName listbox,
%    you just need to select it, select a target for the operation, and add it to your scheme

% contact willdean@uab.edu with any questions or for support in adding more complex operations with custom parameter objects

%% Morphological operation parameters

    % default structuring element
    SE = strel('disk',3,0);

    MorphologicalOptionsGrid = uigridlayout(OperationParamsPanel,[5,2],'Tag','MorphologicalOptionsGrid');
    MorphologicalOptionsGrid.RowHeight = {20,20,20,20,'1x'};
    MorphologicalOptionsGrid.ColumnWidth = {'1x','1x'};


    MorphologicalOptionsTargetLabel = uilabel(MorphologicalOptionsGrid,...
        "Text","Target image",...
        "Tag","MorphologicalTarget");
    MorphologicalOptionsTargetLabel.Layout.Row = 1;
    MorphologicalOptionsTargetLabel.Layout.Column = 1;

    MorphologicalOptionsTargetDropdown = uidropdown(MorphologicalOptionsGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",Scheme.Images,...
        "Value",Scheme.Images(1),...
        "Tag","MorphologicalTarget");
    MorphologicalOptionsTargetDropdown.Layout.Row = 1;
    MorphologicalOptionsTargetDropdown.Layout.Column = 2;

    % shape
    MorphologicalOptionsSEShapeLabel = uilabel(MorphologicalOptionsGrid,...
        "Text",'SE shape');
    MorphologicalOptionsSEShapeLabel.Layout.Row = 2;
    MorphologicalOptionsSEShapeLabel.Layout.Column = 1;

    MorphologicalOptionsSEShapeDropdown = uidropdown(MorphologicalOptionsGrid,...
        "Items",{'Diamond','Disk','Octagon','Line','Rectangle'},...
        "Value",'Disk',...
        "ValueChangedFcn",@MorphologicalOptionsSEShapeChanged);
    MorphologicalOptionsSEShapeDropdown.Layout.Row = 2;
    MorphologicalOptionsSEShapeDropdown.Layout.Column = 2;    

    % radius
    MorphologicalOptionsRadiusLabel = uilabel(MorphologicalOptionsGrid,...
        "Text","Radius (positive integer)",...
        "Tag",'MorphologicalOperations');
    MorphologicalOptionsRadiusLabel.Layout.Row = 3;
    MorphologicalOptionsRadiusLabel.Layout.Column = 1;

    MorphologicalOptionsRadiusEditfield = uieditfield(MorphologicalOptionsGrid,...
        "Value",num2str(3),...
        "ValueChangedFcn",@UpdateSE,...
        "Tag",'MorphologicalOperations');
    MorphologicalOptionsRadiusEditfield.Layout.Row = 3;
    MorphologicalOptionsRadiusEditfield.Layout.Column = 2;

    % length
    MorphologicalOptionsLengthLabel = uilabel(MorphologicalOptionsGrid,...
        "Text","Line length (positive scalar)",...
        "Tag",'MorphologicalOperations',...
        "Visible","off");
    MorphologicalOptionsLengthLabel.Layout.Row = 3;
    MorphologicalOptionsLengthLabel.Layout.Column = 1;

    MorphologicalOptionsLengthEditfield = uieditfield(MorphologicalOptionsGrid,...
        "Value",num2str(3),...
        "ValueChangedFcn",@UpdateSE,...
        "Tag",'MorphologicalOperations',...
        "Visible","off");
    MorphologicalOptionsLengthEditfield.Layout.Row = 3;
    MorphologicalOptionsLengthEditfield.Layout.Column = 2;

    % degrees
    MorphologicalOptionsDegreesLabel = uilabel(MorphologicalOptionsGrid,...
        "Text","Line angle (CCW from positive x-axis)",...
        "Tag",'MorphologicalOperations',...
        "Visible","off");
    MorphologicalOptionsDegreesLabel.Layout.Row = 4;
    MorphologicalOptionsDegreesLabel.Layout.Column = 1;

    MorphologicalOptionsDegreesEditfield = uieditfield(MorphologicalOptionsGrid,...
        "Value",num2str(0),...
        "ValueChangedFcn",@UpdateSE,...
        "Tag",'MorphologicalOperations',...
        "Visible","off");
    MorphologicalOptionsDegreesEditfield.Layout.Row = 4;
    MorphologicalOptionsDegreesEditfield.Layout.Column = 2;

    % rectangle height
    MorphologicalOptionsHeightLabel = uilabel(MorphologicalOptionsGrid,...
        "Text","Rectangle height (pixels, positive integer)",...
        "Tag",'MorphologicalOperations',...
        "Visible","off");
    MorphologicalOptionsHeightLabel.Layout.Row = 3;
    MorphologicalOptionsHeightLabel.Layout.Column = 1;

    MorphologicalOptionsHeightEditfield = uieditfield(MorphologicalOptionsGrid,...
        "Value",num2str(3),...
        "ValueChangedFcn",@UpdateSE,...
        "Tag",'MorphologicalOperations',...
        "Visible","off");
    MorphologicalOptionsHeightEditfield.Layout.Row = 3;
    MorphologicalOptionsHeightEditfield.Layout.Column = 2;

    % rectangle width
    MorphologicalOptionsWidthLabel = uilabel(MorphologicalOptionsGrid,...
        "Text","Rectangle width (pixels, positive integer)",...
        "Tag",'MorphologicalOperations',...
        "Visible","off");
    MorphologicalOptionsWidthLabel.Layout.Row = 4;
    MorphologicalOptionsWidthLabel.Layout.Column = 1;

    MorphologicalOptionsWidthEditfield = uieditfield(MorphologicalOptionsGrid,...
        "Value",num2str(3),...
        "ValueChangedFcn",@UpdateSE,...
        "Tag",'MorphologicalOperations',...
        "Visible","off");
    MorphologicalOptionsWidthEditfield.Layout.Row = 4;
    MorphologicalOptionsWidthEditfield.Layout.Column = 2;    

    % n lines to approximate
    MorphologicalOptionsnLabel = uilabel(MorphologicalOptionsGrid,...
        "Text","n lines to approximate shape",...
        "Tag",'MorphologicalOperations');
    MorphologicalOptionsnLabel.Layout.Row = 4;
    MorphologicalOptionsnLabel.Layout.Column = 1;

    MorphologicalOptionsnDropdown = uidropdown(MorphologicalOptionsGrid,...
        "Items",{'0','4','6','8'},...
        "Value",num2str(0),...
        "ValueChangedFcn",@UpdateSE,...
        "Tag",'MorphologicalOperations');    
    MorphologicalOptionsnDropdown.Layout.Row = 4;
    MorphologicalOptionsnDropdown.Layout.Column = 2;


    SEImageAxes = uiaxes(MorphologicalOptionsGrid,...
        "Units","normalized",...
        "InnerPosition",[0 0 1 1],...
        "XTick",[],...
        "YTick",[],...
        "Tag",'MorphologicalOptions',...
        'XColor',[1 1 1],...
        'YColor',[1 1 1],...
        'Box','on');
    SEImageAxes.Layout.Row = 5;
    SEImageAxes.Layout.Column = [1 2];


    SEImgH = imshow(SE.Neighborhood,"Parent",SEImageAxes);
    
    % restore axis props that were changed by imshow()
    SEImageAxes.YDir = 'reverse';
    SEImageAxes.PlotBoxAspectRatioMode = 'manual';
    SEImageAxes.PlotBoxAspectRatio = [1 1 1];
    SEImageAxes.XTick = [];
    SEImageAxes.YTick = [];
    SEImageAxes.Tag = 'MorphologicalOperations';

    disableDefaultInteractivity(SEImageAxes);
    axtoolbar(SEImageAxes,{});

    AddOperationButton = uibutton(NewOperationGrid,...
        "Text","Add to scheme",...
        "ButtonPushedFcn",@AddOperationToScheme);
    AddOperationButton.Layout.Row = 4;
    AddOperationButton.Layout.Column = 1;

    EditOperationButton = uibutton(NewOperationGrid,...
        "Text","Edit operation",...
        "Enable","off",...
        "ButtonPushedFcn",@EditOperation);
    EditOperationButton.Layout.Row = 4;
    EditOperationButton.Layout.Column = 2;

%% Binarize operation parameters

    % default options for binarization operations ('Adaptive')
    %   {Sensitivity, NeighborhoodSize, Statistic}
    BinarizeOptions = {0.5,7,'mean'};

    BinarizeOptionsGrid = uigridlayout(OperationParamsPanel,[4 2],...
        'Tag','BinarizeOptionsGrid',...
        'Visible','Off');
    BinarizeOptionsGrid.RowHeight = {20,20,20,20};
    BinarizeOptionsGrid.ColumnWidth = {'1x','1x'};

    % target
    BinarizeOptionsTargetLabel = uilabel(BinarizeOptionsGrid,...
        "Text","Target image",...
        "Visible","off",...
        "Tag","BinarizeTarget");
    BinarizeOptionsTargetLabel.Layout.Row = 1;
    BinarizeOptionsTargetLabel.Layout.Column = 1;

    BinarizeOptionsTargetDropdown = uidropdown(BinarizeOptionsGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",Scheme.Images,...
        "Value",Scheme.Images(1),...
        "Visible","off",...
        "Tag","BinarizeTarget");
    BinarizeOptionsTargetDropdown.Layout.Row = 1;
    BinarizeOptionsTargetDropdown.Layout.Column = 2;

    % neighborhood size
    BinarizeOptionsNeighborhoodSizeLabel = uilabel(BinarizeOptionsGrid,...
        "Text","Neighborhood size (positive odd integer)",...
        "Tag",'BinarizeOperations',...
        "Visible","off",...
        "UserData",{'Adaptive'});
    BinarizeOptionsNeighborhoodSizeLabel.Layout.Row = 2;
    BinarizeOptionsNeighborhoodSizeLabel.Layout.Column = 1;

    BinarizeOptionsNeighborhoodSizeEditfield = uieditfield(BinarizeOptionsGrid,...
        "Value",num2str(7),...
        "Tag",'BinarizeOperations',...
        "ValueChangedFcn",@UpdateBinarizeOptions,...
        "Visible","off",...
        "UserData",{'Adaptive'});
    BinarizeOptionsNeighborhoodSizeEditfield.Layout.Row = 2;
    BinarizeOptionsNeighborhoodSizeEditfield.Layout.Column = 2;

    % statistic for adaptive threshold
    BinarizeOptionsStatisticLabel = uilabel(BinarizeOptionsGrid,...
        "Text","Statistic",...
        "Tag",'BinarizeOperations',...
        "UserData",{'Adaptive'});
    BinarizeOptionsStatisticLabel.Layout.Row = 3;
    BinarizeOptionsStatisticLabel.Layout.Column = 1;

    BinarizeOptionsStatisticDropdown = uidropdown(BinarizeOptionsGrid,...
        "Items",{'mean','median','gaussian'},...
        "Value",'mean',...
        "ValueChangedFcn",@UpdateBinarizeOptions,...
        "Tag",'BinarizeOperations',...
        "UserData",{'Adaptive'});    
    BinarizeOptionsStatisticDropdown.Layout.Row = 3;
    BinarizeOptionsStatisticDropdown.Layout.Column = 2;

    % neighborhood size
    BinarizeOptionsSensitivityLabel = uilabel(BinarizeOptionsGrid,...
        "Text","Sensitivity (number in range [0 1])",...
        "Tag",'BinarizeOperations',...
        "Visible","off",...
        "UserData",{'Adaptive'});
    BinarizeOptionsSensitivityLabel.Layout.Row = 4;
    BinarizeOptionsSensitivityLabel.Layout.Column = 1;

    BinarizeOptionsSensitivityEditfield = uieditfield(BinarizeOptionsGrid,...
        "Value",num2str(0.5),...
        "Tag",'BinarizeOperations',...
        "ValueChangedFcn",@UpdateBinarizeOptions,...
        "Visible","off",...
        "UserData",{'Adaptive'});
    BinarizeOptionsSensitivityEditfield.Layout.Row = 4;
    BinarizeOptionsSensitivityEditfield.Layout.Column = 2;

%% ImageFilter parameters

    ImageFilterOptions = {3};

    % grid to hold the options
    ImageFilterOptionsGrid = uigridlayout(OperationParamsPanel,[3 2],...
        'Tag','ImageFilterOptionsGrid',...
        'Visible','Off');
    ImageFilterOptionsGrid.RowHeight = {20,20,20,20};
    ImageFilterOptionsGrid.ColumnWidth = {'fit','1x'};

    % target
    ImageFilterOptionsTargetLabel = uilabel(ImageFilterOptionsGrid,...
        "Text","Target image",...
        "Visible","off",...
        "Tag","ImageFilterTarget");
    ImageFilterOptionsTargetLabel.Layout.Row = 1;
    ImageFilterOptionsTargetLabel.Layout.Column = 1;

    ImageFilterOptionsTargetDropdown = uidropdown(ImageFilterOptionsGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",Scheme.Images,...
        "Value",Scheme.Images(1),...
        "Visible","off",...
        "Tag","ImageFilterTarget");
    ImageFilterOptionsTargetDropdown.Layout.Row = 1;
    ImageFilterOptionsTargetDropdown.Layout.Column = 2;

    % neighborhood size
    ImageFilterOptionsFilterSizeLabel = uilabel(ImageFilterOptionsGrid,...
        "Text","Filter size (positive #)",...
        "Tag",'ImageFilterOperations',...
        "Visible","off",...
        "UserData",{'Median','Gaussian','Average','Wiener','Bilateral','LaplacianOfGaussian'});
    ImageFilterOptionsFilterSizeLabel.Layout.Row = 2;
    ImageFilterOptionsFilterSizeLabel.Layout.Column = 1;

    ImageFilterOptionsFilterSizeEditfield = uieditfield(ImageFilterOptionsGrid,...
        "Value",num2str(7),...
        "Tag",'ImageFilterOperations',...
        "ValueChangedFcn",@UpdateImageFilterOptions,...
        "Visible","off",...
        "UserData",{'Median','Gaussian','Average','Wiener','Bilateral','LaplacianOfGaussian'});
    ImageFilterOptionsFilterSizeEditfield.Layout.Row = 2;
    ImageFilterOptionsFilterSizeEditfield.Layout.Column = 2;

    % sigma for gaussian filter
    ImageFilterOptionsSigmaLabel = uilabel(ImageFilterOptionsGrid,...
        "Text","Sigma",...
        "Tag",'ImageFilterOperations',...
        "Visible","off",...
        "UserData",{'Gaussian','LaplacianOfGaussian'});
    ImageFilterOptionsSigmaLabel.Layout.Row = 3;
    ImageFilterOptionsSigmaLabel.Layout.Column = 1;

    ImageFilterOptionsSigmaEditfield = uieditfield(ImageFilterOptionsGrid,...
        "Value",num2str(1),...
        "Tag",'ImageFilterOperations',...
        "ValueChangedFcn",@UpdateImageFilterOptions,...
        "Visible","off",...
        "UserData",{'Gaussian','LaplacianOfGaussian'});
    ImageFilterOptionsSigmaEditfield.Layout.Row = 3;
    ImageFilterOptionsSigmaEditfield.Layout.Column = 2;

    % spatial sigma for bilateral filter
    ImageFilterOptionsSpatialSigmaLabel = uilabel(ImageFilterOptionsGrid,...
        "Text","Spatial sigma (positive #)",...
        "Tag",'ImageFilterOperations',...
        "Visible","off",...
        "UserData",{'Bilateral'});
    ImageFilterOptionsSpatialSigmaLabel.Layout.Row = 3;
    ImageFilterOptionsSpatialSigmaLabel.Layout.Column = 1;

    ImageFilterOptionsSpatialSigmaEditfield = uieditfield(ImageFilterOptionsGrid,...
        "Value",num2str(1),...
        "Tag",'ImageFilterOperations',...
        "ValueChangedFcn",@UpdateImageFilterOptions,...
        "Visible","off",...
        "UserData",{'Bilateral'});
    ImageFilterOptionsSpatialSigmaEditfield.Layout.Row = 3;
    ImageFilterOptionsSpatialSigmaEditfield.Layout.Column = 2;

    % degree of smoothing for non-local means filter
    ImageFilterOptionsDegreeOfSmoothingLabel = uilabel(ImageFilterOptionsGrid,...
        "Text","Degree of smoothing (positive #)",...
        "Tag",'ImageFilterOperations',...
        "Visible","off",...
        "UserData",{'NonLocalMeans'});
    ImageFilterOptionsDegreeOfSmoothingLabel.Layout.Row = 2;
    ImageFilterOptionsDegreeOfSmoothingLabel.Layout.Column = 1;

    ImageFilterOptionsDegreeOfSmoothingEditfield = uieditfield(ImageFilterOptionsGrid,...
        "Value",num2str(0.02),...
        "Tag",'ImageFilterOperations',...
        "ValueChangedFcn",@UpdateImageFilterOptions,...
        "Visible","off",...
        "UserData",{'NonLocalMeans'});
    ImageFilterOptionsDegreeOfSmoothingEditfield.Layout.Row = 2;
    ImageFilterOptionsDegreeOfSmoothingEditfield.Layout.Column = 2;

    % search window size for non-local means filter
    ImageFilterOptionsSearchWindowSizeLabel = uilabel(ImageFilterOptionsGrid,...
        "Text","Search window size (positive, odd)",...
        "Tag",'ImageFilterOperations',...
        "Visible","off",...
        "UserData",{'NonLocalMeans'});
    ImageFilterOptionsSearchWindowSizeLabel.Layout.Row = 3;
    ImageFilterOptionsSearchWindowSizeLabel.Layout.Column = 1;

    ImageFilterOptionsSearchWindowSizeEditfield = uieditfield(ImageFilterOptionsGrid,...
        "Value",num2str(21),...
        "Tag",'ImageFilterOperations',...
        "ValueChangedFcn",@UpdateImageFilterOptions,...
        "Visible","off",...
        "UserData",{'NonLocalMeans'});
    ImageFilterOptionsSearchWindowSizeEditfield.Layout.Row = 3;
    ImageFilterOptionsSearchWindowSizeEditfield.Layout.Column = 2;

    % comparison window size for non-local means filter
    ImageFilterOptionsComparisonWindowSizeLabel = uilabel(ImageFilterOptionsGrid,...
        "Text","Comparison window size (positive, odd)",...
        "Tag",'ImageFilterOperations',...
        "Visible","off",...
        "UserData",{'NonLocalMeans'});
    ImageFilterOptionsComparisonWindowSizeLabel.Layout.Row = 4;
    ImageFilterOptionsComparisonWindowSizeLabel.Layout.Column = 1;

    ImageFilterOptionsComparisonWindowSizeEditfield = uieditfield(ImageFilterOptionsGrid,...
        "Value",num2str(5),...
        "Tag",'ImageFilterOperations',...
        "ValueChangedFcn",@UpdateImageFilterOptions,...
        "Visible","off",...
        "UserData",{'NonLocalMeans'});
    ImageFilterOptionsComparisonWindowSizeEditfield.Layout.Row = 4;
    ImageFilterOptionsComparisonWindowSizeEditfield.Layout.Column = 2;

%% ContrastEnhancement operation parameters

    % default ContrastEnhancementOptions for EnhanceFibers operation
    %   {FiberWidth}
    ContrastEnhancementOptions = {4};

    % grid to hold the options
    ContrastEnhancementOptionsGrid = uigridlayout(OperationParamsPanel,[4 2],...
        'Tag','ContrastEnhancementOptionsGrid',...
        'Visible','Off');
    ContrastEnhancementOptionsGrid.RowHeight = {20,20,20,20};
    ContrastEnhancementOptionsGrid.ColumnWidth = {'1x','1x'};
    
    % target
    ContrastEnhancementOptionsTargetLabel = uilabel(ContrastEnhancementOptionsGrid,...
        "Text","Target image",...
        "Visible","off",...
        "Tag","ContrastEnhancementTarget");
    ContrastEnhancementOptionsTargetLabel.Layout.Row = 1;
    ContrastEnhancementOptionsTargetLabel.Layout.Column = 1;
    
    ContrastEnhancementOptionsTargetDropdown = uidropdown(ContrastEnhancementOptionsGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",Scheme.Images,...
        "Value",Scheme.Images(1),...
        "Visible","off",...
        "Tag","ContrastEnhancementTarget");
    ContrastEnhancementOptionsTargetDropdown.Layout.Row = 1;
    ContrastEnhancementOptionsTargetDropdown.Layout.Column = 2;

    % FiberWidth (EnhanceFibers)
    ContrastEnhancementOptionsFiberWidthLabel = uilabel(ContrastEnhancementOptionsGrid,...
        "Text","Fiber width (positive integer)",...
        "Tag",'ContrastEnhancementOperations',...
        "Visible","off",...
        "UserData",{'EnhanceFibers'});
    ContrastEnhancementOptionsFiberWidthLabel.Layout.Row = 2;
    ContrastEnhancementOptionsFiberWidthLabel.Layout.Column = 1;

    ContrastEnhancementOptionsFiberWidthEditfield = uieditfield(ContrastEnhancementOptionsGrid,...
        "Value",num2str(4),...
        "Tag",'ContrastEnhancementOperations',...
        "ValueChangedFcn",@UpdateContrastEnhancementOptions,...
        "Visible","off",...
        "UserData",{'EnhanceFibers'});
    ContrastEnhancementOptionsFiberWidthEditfield.Layout.Row = 2;
    ContrastEnhancementOptionsFiberWidthEditfield.Layout.Column = 2;

    % Sigma (Flatfield)
    ContrastEnhancementOptionsSigmaLabel = uilabel(ContrastEnhancementOptionsGrid,...
        "Text","Sigma (positive number)",...
        "Tag",'ContrastEnhancementOperations',...
        "Visible","off",...
        "UserData",{'Flatfield'});
    ContrastEnhancementOptionsSigmaLabel.Layout.Row = 2;
    ContrastEnhancementOptionsSigmaLabel.Layout.Column = 1;

    ContrastEnhancementOptionsSigmaEditfield = uieditfield(ContrastEnhancementOptionsGrid,...
        "Value",num2str(30),...
        "Tag",'ContrastEnhancementOperations',...
        "ValueChangedFcn",@UpdateContrastEnhancementOptions,...
        "Visible","off",...
        "UserData",{'Flatfield'});
    ContrastEnhancementOptionsSigmaEditfield.Layout.Row = 2;
    ContrastEnhancementOptionsSigmaEditfield.Layout.Column = 2;

    % FilterSize (Flatfield)
    ContrastEnhancementOptionsFilterSizeLabel = uilabel(ContrastEnhancementOptionsGrid,...
        "Text","FilterSize (positive odd integer)",...
        "Tag",'ContrastEnhancementOperations',...
        "Visible","off",...
        "UserData",{'Flatfield'});
    ContrastEnhancementOptionsFilterSizeLabel.Layout.Row = 3;
    ContrastEnhancementOptionsFilterSizeLabel.Layout.Column = 1;

    ContrastEnhancementOptionsFilterSizeEditfield = uieditfield(ContrastEnhancementOptionsGrid,...
        "Value",num2str(129),...
        "Tag",'ContrastEnhancementOperations',...
        "ValueChangedFcn",@UpdateContrastEnhancementOptions,...
        "Visible","off",...
        "UserData",{'Flatfield'});
    ContrastEnhancementOptionsFilterSizeEditfield.Layout.Row = 3;
    ContrastEnhancementOptionsFilterSizeEditfield.Layout.Column = 2;

%% Special operation parameters

    SpecialOptions = {};

    % grid to hold the options
    SpecialOptionsGrid = uigridlayout(OperationParamsPanel,[2 2],...
        'Tag','SpecialOptionsGrid',...
        'Visible','Off');
    SpecialOptionsGrid.RowHeight = {20, 20};
    SpecialOptionsGrid.ColumnWidth = {'1x','1x'};

    % target
    SpecialOptionsTargetLabel = uilabel(SpecialOptionsGrid,...
        "Text","Target image",...
        "Visible","off",...
        "Tag","SpecialTarget");
    SpecialOptionsTargetLabel.Layout.Row = 1;
    SpecialOptionsTargetLabel.Layout.Column = 1;

    SpecialOptionsTargetDropdown = uidropdown(SpecialOptionsGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",Scheme.Images,...
        "Value",Scheme.Images(1),...
        "Visible","off",...
        "Tag","SpecialTarget");
    SpecialOptionsTargetDropdown.Layout.Row = 1;
    SpecialOptionsTargetDropdown.Layout.Column = 2;

    % Rotating line length (rotating max open)
    RotatingLineLengthLabel = uilabel(SpecialOptionsGrid,...
        "Text","Rotating line length (positive integer)",...
        "Tag",'SpecialOperations',...
        "Visible","off",...
        "UserData",{'RotatingMaxOpen','BWRotatingMaxOpen','BWRotatingMaxOpenAndClose'});
    RotatingLineLengthLabel.Layout.Row = 2;
    RotatingLineLengthLabel.Layout.Column = 1;

    RotatingLineLengthEditfield = uieditfield(SpecialOptionsGrid,...
        "Value",num2str(20),...
        "Tag","SpecialOperations",...
        "ValueChangedFcn",@UpdateSpecialOptions,...
        "Visible","off",...
        "UserData",{'RotatingMaxOpen','BWRotatingMaxOpen','BWRotatingMaxOpenAndClose'});
    RotatingLineLengthEditfield.Layout.Row = 2;
    RotatingLineLengthEditfield.Layout.Column = 2;    

    % object area (bwareaopen)
    BWAreaLabel = uilabel(SpecialOptionsGrid,...
        "Text","Minimum area (positive integer)",...
        "Tag",'SpecialOperations',...
        "Visible","off",...
        "UserData",{'BWAreaOpen'});
    BWAreaLabel.Layout.Row = 2;
    BWAreaLabel.Layout.Column = 1;

    BWAreaEditfield = uieditfield(SpecialOptionsGrid,...
        "Value",num2str(20),...
        "Tag","SpecialOperations",...
        "ValueChangedFcn",@UpdateSpecialOptions,...
        "Visible","off",...
        "UserData",{'BWAreaOpen'});
    BWAreaEditfield.Layout.Row = 2;
    BWAreaEditfield.Layout.Column = 2;

    % blind deconvolution
    SpecialOptionsFilterSizeLabel = uilabel(SpecialOptionsGrid,...
        "Text","Filter size",...
        "Tag",'SpecialOperations',...
        "Visible","off",...
        "UserData",{'BlindDeconvolution'});
    SpecialOptionsFilterSizeLabel.Layout.Row = 2;
    SpecialOptionsFilterSizeLabel.Layout.Column = 1;

    SpecialOptionsFilterSizeEditfield = uieditfield(SpecialOptionsGrid,...
        "Value",num2str(20),...
        "Tag","SpecialOperations",...
        "ValueChangedFcn",@UpdateSpecialOptions,...
        "Visible","off",...
        "UserData",{'BlindDeconvolution'});
    SpecialOptionsFilterSizeEditfield.Layout.Row = 2;
    SpecialOptionsFilterSizeEditfield.Layout.Column = 2;

%% Arithmetic operations

    ArithmeticOptions = {};

    % grid to hold the options
    ArithmeticOptionsGrid = uigridlayout(OperationParamsPanel,[3 2],...
        'Tag','ArithmeticOptionsGrid',...
        'Visible','Off');
    ArithmeticOptionsGrid.RowHeight = {20,20,20};
    ArithmeticOptionsGrid.ColumnWidth = {'1x','1x'};

    % target 1
    ArithmeticOptionsTargetLabel1 = uilabel(ArithmeticOptionsGrid,...
        "Text","Target image 1",...
        "Visible","off",...
        "Tag","ArithmeticTarget");
    ArithmeticOptionsTargetLabel1.Layout.Row = 1;
    ArithmeticOptionsTargetLabel1.Layout.Column = 1;

    ArithmeticOptionsTargetDropdown1 = uidropdown(ArithmeticOptionsGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",Scheme.Images,...
        "Value",Scheme.Images(1),...
        "Visible","off",...
        "Tag","ArithmeticTarget");
    ArithmeticOptionsTargetDropdown1.Layout.Row = 1;
    ArithmeticOptionsTargetDropdown1.Layout.Column = 2;

    % label to display the arithemtic operation (+,-,*,÷,etc.)
    ArithmeticOptionsOperationLabel = gobjects(numel(Scheme.ArithmeticOperations),1);
    for i = 1:numel(Scheme.ArithmeticOperations)
        ArithmeticOptionsOperationLabel(i,1) = uilabel(ArithmeticOptionsGrid,...
            "Text",Scheme.ArithmeticOperations{i},...
            "Visible","off",...
            "Tag","ArithmeticOperations",...
            "UserData",Scheme.ArithmeticOperations(i),...
            "HorizontalAlignment","center");
        ArithmeticOptionsOperationLabel(i,1).Layout.Row = 2;
        ArithmeticOptionsOperationLabel(i,1).Layout.Column = 2;
    end

    % target 2
    ArithmeticOptionsTargetLabel2 = uilabel(ArithmeticOptionsGrid,...
        "Text","Target image 2",...
        "Visible","off",...
        "Tag","ArithmeticTarget");
    ArithmeticOptionsTargetLabel2.Layout.Row = 3;
    ArithmeticOptionsTargetLabel2.Layout.Column = 1;

    ArithmeticOptionsTargetDropdown2 = uidropdown(ArithmeticOptionsGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",Scheme.Images,...
        "Value",Scheme.Images(1),...
        "Visible","off",...
        "Tag","ArithmeticTarget");
    ArithmeticOptionsTargetDropdown2.Layout.Row = 3;
    ArithmeticOptionsTargetDropdown2.Layout.Column = 2;

%% EdgeDetection operations

    EdgeDetectionOptions = {};

    % grid to hold the options
    EdgeDetectionOptionsGrid = uigridlayout(OperationParamsPanel,[1 1],...
        'Tag','EdgeDetectionOptionsGrid',...
        'Visible','Off');
    EdgeDetectionOptionsGrid.RowHeight = {20};
    EdgeDetectionOptionsGrid.ColumnWidth = {'1x','1x'};

    % target
    EdgeDetectionOptionsTargetLabel = uilabel(EdgeDetectionOptionsGrid,...
        "Text","Target image",...
        "Visible","off",...
        "Tag","EdgeDetectionTarget");
    EdgeDetectionOptionsTargetLabel.Layout.Row = 1;
    EdgeDetectionOptionsTargetLabel.Layout.Column = 1;

    EdgeDetectionOptionsTargetDropdown = uidropdown(EdgeDetectionOptionsGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",Scheme.Images,...
        "Value",Scheme.Images(1),...
        "Visible","off",...
        "Tag","EdgeDetectionTarget");
    EdgeDetectionOptionsTargetDropdown.Layout.Row = 1;
    EdgeDetectionOptionsTargetDropdown.Layout.Column = 2;

%% bwmorph operations

    bwmorphOptions = {};

    % grid to hold the options
    bwmorphOptionsGrid = uigridlayout(OperationParamsPanel,[2 2],...
        'Tag','bwmorphOptionsGrid',...
        'Visible','Off');
    bwmorphOptionsGrid.RowHeight = {20, 20};
    bwmorphOptionsGrid.ColumnWidth = {'1x','1x'};

    % target
    bwmorphOptionsTargetLabel = uilabel(bwmorphOptionsGrid,...
        "Text","Target image",...
        "Visible","off",...
        "Tag","bwmorphTarget");
    bwmorphOptionsTargetLabel.Layout.Row = 1;
    bwmorphOptionsTargetLabel.Layout.Column = 1;

    bwmorphOptionsTargetDropdown = uidropdown(bwmorphOptionsGrid,...
        "Items",Scheme.ImagesTextDisplay,...
        "ItemsData",Scheme.Images,...
        "Value",Scheme.Images(1),...
        "Visible","off",...
        "Tag","bwmorphTarget");
    bwmorphOptionsTargetDropdown.Layout.Row = 1;
    bwmorphOptionsTargetDropdown.Layout.Column = 2;

    % target
    bwmorphOptionsNLabel = uilabel(bwmorphOptionsGrid,...
        "Text","n",...
        "Visible","off",...
        "Tag","bwmorphOperations",...
        "UserData",CustomMask.bwmorphOperations);
    bwmorphOptionsNLabel.Layout.Row = 2;
    bwmorphOptionsNLabel.Layout.Column = 1;

    bwmorphOptionsNEditfield = uieditfield(bwmorphOptionsGrid,...
        'numeric',...
        "Limits",[1 Inf],...
        "Value",Inf,...
        "Tag","bwmorphOperations",...
        "ValueChangedFcn",@UpdatebwmorphOptions,...
        "Visible","off",...
        "UserData",CustomMask.bwmorphOperations);
    bwmorphOptionsNEditfield.Layout.Row = 2;
    bwmorphOptionsNEditfield.Layout.Column = 2;

%% cleaning up, getting ready to start


    set(findobj(fHMaskMaker,'type','uilabel'),'FontColor',[1 1 1]);
    set(findobj(fHMaskMaker,'type','uilistbox'),'FontColor',[1 1 1],'BackgroundColor',[0 0 0]);
    %set(findobj(fHMaskMaker,'type','uipanel'),'ForegroundColor',[0 0 0]);
    set(findobj(fHMaskMaker,'type','uigridlayout'),'BackgroundColor',[0 0 0]);


    fHMaskMaker.SizeChangedFcn = @MainWindowSizeChanged;
    fHMaskMaker.Visible = 'On';

%% Nested callback and accessory functions

    function ImageSelectionChanged(~,~)
        Scheme.CurrentImageIdx = ImageSelector.Value;
        OperationSelector.Value = ImageSelector.Value;
        Scheme.CurrentOperationIdx = ImageSelector.Value;
        
        UpdateMainImage();
        UpdateDisplayWithSelectedOperation();
    end

    function UpdateDisplayWithSelectedOperation()
        if Scheme.CurrentOperationIdx==1
            return
        end

        EditOperationButton.Enable = Scheme.CurrentOperationIdx~=1;

        CurrentOp = Scheme.CurrentOperation;
        PreviousOperationType = OperationTypeSelector.Value;
        %PreviousOperationName = OperationNameSelector.Value;
        NewOperationType = CurrentOp.OperationType;
        NewOperationName = CurrentOp.OperationName;
        OperationTypeSelector.Value = NewOperationType;
        % hide the previous options grid
        PreviousTypeGrid = findobj(fHMaskMaker,'Tag',[PreviousOperationType,'OptionsGrid']);
        PreviousTypeGrid.Visible = 'Off';
        % show the options grid for newly selected OperationType
        CurrentTypeGrid = findobj(fHMaskMaker,'Tag',[NewOperationType,'OptionsGrid']);
        CurrentTypeGrid.Visible = 'On';
        % hide previous operation Target options
        PreviousTargetObjects = findobj(fHMaskMaker,'Tag',[PreviousOperationType,'Target']);
        set(PreviousTargetObjects,'Visible','Off');
        % show previous operation Target options
        CurrentTargetObjects = findobj(fHMaskMaker,'Tag',[NewOperationType,'Target']);
        set(CurrentTargetObjects,'Visible','On');

        % change items in OperationNameSelector selector to the subtypes of the selected operation in OperationTypeSelector
        OperationNameSelector.Items = Scheme.([NewOperationType,'Operations']);
        % change the value of the OperationNameSelector
        OperationNameSelector.Value = NewOperationName;
        % invoke the OperationNameSelector ValueChangedFcn callback
        OperationNameChanged(OperationNameSelector);

        switch CurrentOp.OperationType
            case 'Morphological'

                MorphologicalOptionsSEShapeDropdown.Value = CurrentOp.ParamsMap('Shape');
                % update display based on selected shape
                MorphologicalOptionsSEShapeChanged(MorphologicalOptionsSEShapeDropdown);
                MorphologicalOptionsTargetDropdown.Value = CurrentOp.Target;

                switch MorphologicalOptionsSEShapeDropdown.Value
                    case 'Diamond'
                        MorphologicalOptionsRadiusEditfield.Value = num2str(CurrentOp.ParamsMap('Radius'));
                        SE = strel(CurrentOp.ParamsMap('Shape'),CurrentOp.ParamsMap('Radius'));
                        NamedParams = {...
                            'Shape',CurrentOp.ParamsMap('Shape'),...
                            'Radius',CurrentOp.ParamsMap('Radius')...
                            };
                    case 'Disk'
                        MorphologicalOptionsRadiusEditfield.Value = num2str(CurrentOp.ParamsMap('Radius'));
                        MorphologicalOptionsnDropdown.Value = num2str(CurrentOp.ParamsMap('n'));
                        SE = strel(CurrentOp.ParamsMap('Shape'),CurrentOp.ParamsMap('Radius'),CurrentOp.ParamsMap('n'));
                        NamedParams = {...
                            'Shape',CurrentOp.ParamsMap('Shape'),...
                            'Radius',CurrentOp.ParamsMap('Radius'),...
                            'n',CurrentOp.ParamsMap('n')...
                            };
                    case 'Octagon'
                        MorphologicalOptionsRadiusEditfield.Value = num2str(CurrentOp.ParamsMap('Radius'));
                        SE = strel(CurrentOp.ParamsMap('Shape'),CurrentOp.ParamsMap('Radius'));
                        NamedParams = {...
                            'Shape',CurrentOp.ParamsMap('Shape'),...
                            'Radius',CurrentOp.ParamsMap('Radius')...
                            };
                    case 'Line'
                        MorphologicalOptionsLengthEditfield.Value = num2str(CurrentOp.ParamsMap('Length'));
                        MorphologicalOptionsDegreesEditfield.Value = num2str(CurrentOp.ParamsMap('Angle'));
                        SE = strel(CurrentOp.ParamsMap('Shape'),CurrentOp.ParamsMap('Length'),CurrentOp.ParamsMap('Angle'));
                        NamedParams = {...
                            'Shape',CurrentOp.ParamsMap('Shape'),...
                            'Length',CurrentOp.ParamsMap('Length'),...
                            'Angle',CurrentOp.ParamsMap('Angle')...
                            };
                    case 'Rectangle'
                        MorphologicalOptionsHeightEditfield.Value = num2str(CurrentOp.ParamsMap('Height'));
                        MorphologicalOptionsWidthEditfield.Value = num2str(CurrentOp.ParamsMap('Width'));
                        SE = strel(CurrentOp.ParamsMap('Shape'),[CurrentOp.ParamsMap('Height') CurrentOp.ParamsMap('Width')]);
                        NamedParams = {...
                            'Shape',CurrentOp.ParamsMap('Shape'),...
                            'Height',CurrentOp.ParamsMap('Height'),...
                            'Width',CurrentOp.ParamsMap('Width')...
                            };

                end

                UpdateSE();

            case 'ImageFilter'

                ImageFilterOptionsTargetDropdown.Value = CurrentOp.Target;

                switch NewOperationName
                    case {'Median','Average','Wiener'}
                        FilterSize = CurrentOp.ParamsMap('FilterSize');
                        ImageFilterOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                        ImageFilterOptions = {FilterSize};
                        NamedParams = {...
                            'FilterSize',FilterSize...
                            };
                    case {'Gaussian','LaplacianOfGaussian'}
                        FilterSize = CurrentOp.ParamsMap('FilterSize');
                        Sigma = CurrentOp.ParamsMap('Sigma');
                        ImageFilterOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                        ImageFilterOptionsSigmaEditfield.Value = num2str(Sigma);
                        ImageFilterOptions = {FilterSize,Sigma};
                        NamedParams = {...
                            'FilterSize',FilterSize,...
                            'Sigma',Sigma...
                            };
                    case 'Bilateral'
                        FilterSize = CurrentOp.ParamsMap('FilterSize');
                        SpatialSigma = CurrentOp.ParamsMap('SpatialSigma');
                        ImageFilterOptions = {FilterSize,SpatialSigma};
                        ImageFilterOptionsSpatialSigmaEditfield.Value = num2str(SpatialSigma);
                        NamedParams = {...
                            'FilterSize',FilterSize,...
                            'SpatialSigma',SpatialSigma...
                            };
                    case 'NonLocalMeans'
                        DegreeOfSmoothing = CurrentOp.ParamsMap('DegreeOfSmoothing');
                        SearchWindowSize = CurrentOp.ParamsMap('SearchWindowSize');
                        ComparisonWindowSize = CurrentOp.ParamsMap('ComparisonWindowSize');
                        ImageFilterOptions = {DegreeOfSmoothing,SearchWindowSize,ComparisonWindowSize};
                        ImageFilterOptionsDegreeOfSmoothingEditfield.Value = num2str(DegreeOfSmoothing);
                        ImageFilterOptionsSearchWindowSizeEditfield.Value = num2str(SearchWindowSize);
                        ImageFilterOptionsComparisonWindowSizeEditfield.Value = num2str(ComparisonWindowSize);
                        NamedParams = {...
                            'DegreeOfSmoothing',DegreeOfSmoothing,...
                            'SearchWindowSize',SearchWindowSize,...
                            'ComparisonWindowSize',ComparisonWindowSize
                            };
                end

            case 'ContrastEnhancement'

                ContrastEnhancementOptionsTargetDropdown.Value = CurrentOp.Target;

                switch NewOperationName
                    case 'EnhanceFibers'
                        FiberWidth = CurrentOp.ParamsMap('FiberWidth');
                        ContrastEnhancementOptions = {FiberWidth};
                        ContrastEnhancementOptionsFiberWidthEditfield.Value = num2str(FiberWidth);
                        NamedParams = {...
                            'FiberWidth',FiberWidth...
                            };
                    case 'Flatfield'
                        Sigma = CurrentOp.ParamsMap('Sigma');
                        FilterSize = CurrentOp.ParamsMap('FilterSize');
                        ContrastEnhancementOptions = {Sigma,FilterSize};
                        ContrastEnhancementOptionsSigmaEditfield.Value = num2str(Sigma);
                        ContrastEnhancementOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                        NamedParams = {...
                            'Sigma',Sigma,...
                            'FilterSize',FilterSize...
                            };
                    otherwise
                        ContrastEnhancementOptions = {};
                        NamedParams = {};
                end

            case 'Binarize'

                BinarizeOptionsTargetDropdown.Value = CurrentOp.Target;

                switch NewOperationName

                    case 'Otsu'
                        BinarizeOptions = {};
                        NamedParams = {};
                    case 'Adaptive'
                        Sensitivity = CurrentOp.ParamsMap('Sensitivity');
                        NeighborhoodSize = CurrentOp.ParamsMap('NeighborhoodSize');
                        Statistic = CurrentOp.ParamsMap('Statistic');
                        BinarizeOptionsSensitivityEditfield.Value = num2str(Sensitivity);
                        BinarizeOptionsNeighborhoodSizeEditfield.Value = num2str(NeighborhoodSize);
                        BinarizeOptionsStatisticDropdown.Value = Statistic;
                        BinarizeOptions = {Sensitivity,NeighborhoodSize,Statistic};
                        NamedParams = {...
                            'Sensitivity',Sensitivity,...
                            'NeighborhoodSize',NeighborhoodSize,...
                            'Statistic',Statistic...
                            };
                end

            case 'Arithmetic'

                ArithmeticOptionsTargetDropdown1.Value = CurrentOp.Target(1);
                ArithmeticOptionsTargetDropdown2.Value = CurrentOp.Target(2);
                NamedParams = {};
                ArithmeticOptions = {};


            case 'Special'

                SpecialOptionsTargetDropdown.Value = CurrentOp.Target;

                switch NewOperationName
                    case {'RotatingMaxOpen','BWRotatingMaxOpen','BWRotatingMaxOpenAndClose'}
                        RotatingLineLength = CurrentOp.ParamsMap('RotatingLineLength');
                        RotatingLineLengthEditfield.Value = num2str(RotatingLineLength);
                        SpecialOptions = {RotatingLineLength};
                        NamedParams = {...
                            'RotatingLineLength',RotatingLineLength...
                            };
                    case 'BWAreaOpen'
                        BWArea = CurrentOp.ParamsMap('BWArea');
                        BWAreaEditfield.Value = num2str(BWArea);
                        SpecialOptions = {BWArea};
                        NamedParams = {...
                            'BWArea',BWArea,...
                            };
                    case 'BlindDeconvolution'
                        FilterSize = CurrentOp.ParamsMap('FilterSize');
                        SpecialOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                        SpecialOptions = {FilterSize};
                        NamedParams = {...
                            'FilterSize',FilterSize,...
                            };
                    otherwise
                        SpecialOptions = {};
                        NamedParams = {};
                end

            case 'EdgeDetection'

                EdgeDetectionOptionsTargetDropdown.Value = CurrentOp.Target;
                EdgeDetectionOptions = {};
                NamedParams = {};

            case 'bwmorph'

                bwmorphOptionsTargetDropdown.Value = CurrentOp.Target;
                n = CurrentOp.ParamsMap('n');
                bwmorphOptionsNEditfield.Value = n;
                bwmorphOptions = {n};
                NamedParams = {'n',n};

        end
    end

    function OperationSelectionChanged(~,~)
        Scheme.CurrentOperationIdx = OperationSelector.Value;
        ImageSelector.Value = OperationSelector.Value;
        Scheme.CurrentImageIdx = OperationSelector.Value;

        UpdateMainImage();
        UpdateDisplayWithSelectedOperation();
    end

    function UpdateMainImage()
        hImage.CData = Scheme.CurrentImage.ImageData;
        switch Scheme.CurrentImage.ImageClass
            case 'double'
                ImageDisplayAxes.Colormap = CurrentColormap;
            case 'logical'
                ImageDisplayAxes.Colormap = gray;
        end
    end

    function DeleteOperation(~,~)
        % as long as the current operation isn't the first one (input)
        if Scheme.CurrentOperation ~= Scheme.Operations(1)
            % then we will delete the currently selected operation
            Scheme.DeleteOperation(Scheme.CurrentOperation);
            % weird bug as of R2021b where – when certain listbox Items are deleted –
            % the listbox becomes non-functional until another GUI object is clicked.
            % workaround for now is to delete and redraw the listboxes after each call
            % to DeleteOperation()
            % delete the image selector listbox
            delete(ImageSelector)
            % redraw image step selector
            ImageSelector = uilistbox(ImageSelectorPanelGrid,...
                "Items",Scheme.ImagesTextDisplay,...
                "ItemsData",1:Scheme.nImages,...
                "Value",Scheme.CurrentImageIdx,...
                "Tag",'ImageSelector',...
                "ValueChangedFcn",@ImageSelectionChanged,...
                "Multiselect","off",...
                "BackgroundColor",[0 0 0],...
                "FontColor",[1 1 1]);
            % delete the operation selector listbox
            delete(OperationSelector)
            % redraw operation step selector
            OperationSelector = uilistbox(OperationSelectorPanelGrid,...
                "Items",Scheme.OperationsTextDisplay,...
                "ItemsData",1:Scheme.nOperations,...
                "Value",Scheme.CurrentOperationIdx,...
                "Tag",'OperationSelector',...
                "ValueChangedFcn",@OperationSelectionChanged,...
                "Multiselect","off",...
                "BackgroundColor",[0 0 0],...
                "FontColor",[1 1 1]);
            % update image display
            UpdateMainImage();
            % update target dropdowns
            UpdateTargetDropdowns();
            % update display with new selected operation
            UpdateDisplayWithSelectedOperation();
        end
    end

    function UpdateTargetDropdowns()

        MorphologicalOptionsTargetDropdown.Items = Scheme.ImagesTextDisplay;
        MorphologicalOptionsTargetDropdown.ItemsData = Scheme.Images;
        MorphologicalOptionsTargetDropdown.Value = Scheme.Images(end);

        BinarizeOptionsTargetDropdown.Items = Scheme.ImagesTextDisplay;
        BinarizeOptionsTargetDropdown.ItemsData = Scheme.Images;
        BinarizeOptionsTargetDropdown.Value = Scheme.Images(end);

        ImageFilterOptionsTargetDropdown.Items = Scheme.ImagesTextDisplay;
        ImageFilterOptionsTargetDropdown.ItemsData = Scheme.Images;
        ImageFilterOptionsTargetDropdown.Value = Scheme.Images(end);

        ArithmeticOptionsTargetDropdown1.Items = Scheme.ImagesTextDisplay;
        ArithmeticOptionsTargetDropdown1.ItemsData = Scheme.Images;
        ArithmeticOptionsTargetDropdown1.Value = Scheme.Images(end);

        ArithmeticOptionsTargetDropdown2.Items = Scheme.ImagesTextDisplay;
        ArithmeticOptionsTargetDropdown2.ItemsData = Scheme.Images;
        ArithmeticOptionsTargetDropdown2.Value = Scheme.Images(end);        

        ContrastEnhancementOptionsTargetDropdown.Items = Scheme.ImagesTextDisplay;
        ContrastEnhancementOptionsTargetDropdown.ItemsData = Scheme.Images;
        ContrastEnhancementOptionsTargetDropdown.Value = Scheme.Images(end);

        SpecialOptionsTargetDropdown.Items = Scheme.ImagesTextDisplay;
        SpecialOptionsTargetDropdown.ItemsData = Scheme.Images;
        SpecialOptionsTargetDropdown.Value = Scheme.Images(end);

        EdgeDetectionOptionsTargetDropdown.Items = Scheme.ImagesTextDisplay;
        EdgeDetectionOptionsTargetDropdown.ItemsData = Scheme.Images;
        EdgeDetectionOptionsTargetDropdown.Value = Scheme.Images(end);

        bwmorphOptionsTargetDropdown.Items = Scheme.ImagesTextDisplay;
        bwmorphOptionsTargetDropdown.ItemsData = Scheme.Images;
        bwmorphOptionsTargetDropdown.Value = Scheme.Images(end);
    end

    function OpenContrastTool(~,~)
        imcontrast(hImage);
    end

    function OpenPixelRegionTool(~,~)
        impixelregion(hImage);
    end

    function ChangeColormap(source,~)
        CurrentColormap = Colormaps.(source.Text);
        ImageDisplayAxes.Colormap = CurrentColormap;
    end

    function OperationTypeChanged(source,event)
        % hide the previous options grid
        PreviousTypeGrid = findobj(fHMaskMaker,'Tag',[event.PreviousValue,'OptionsGrid']);
        PreviousTypeGrid.Visible = 'Off';
        % show the options grid for newly selected OperationType
        CurrentTypeGrid = findobj(fHMaskMaker,'Tag',[event.Value,'OptionsGrid']);
        CurrentTypeGrid.Visible = 'On';
        % hide previous operation Target options
        PreviousTargetObjects = findobj(fHMaskMaker,'Tag',[event.PreviousValue,'Target']);
        set(PreviousTargetObjects,'Visible','Off');
        % hide previous operation Target options
        CurrentTargetObjects = findobj(fHMaskMaker,'Tag',[event.Value,'Target']);
        set(CurrentTargetObjects,'Visible','On');
        % change items in OperationNameSelector selector to the subtypes of the selected operation in OperationTypeSelector
        OperationNameSelector.Items = Scheme.([source.Value,'Operations']);
        % invoke the OperationNameSelector ValueChangedFcn callback
        OperationNameChanged(OperationNameSelector);
    end

    function OperationNameChanged(source,~)

        % change the title of the options panel
        OperationParamsPanel.Title = [source.Value,' Options'];

        % hide/show graphics objects based on selected operation
        switch OperationTypeSelector.Value
            % case {'test'}
            %     % hide all operation parameters for currently seleted operation type (indicated by Tag property)
            %     set(findobj(fHMaskMaker,"Tag",[OperationTypeSelector.Value,'Operations']),"Visible","off");
            %     % turn back on objects for the specific selected operation (indicated by UserData property)
            %     set(findobj(fHMaskMaker,"UserData",OperationNameSelector.Value),"Visible","on");
            % case 'test2'
            %     % hide all operation parameters for currently seleted operation type (indicated by Tag property)
            %     set(findobj(fHMaskMaker,"Tag",[OperationTypeSelector.Value,'Operations']),"Visible","off");
            %     % turn back on objects used by all image filter operations (indicated by UserData property)
            %     set(findobj(fHMaskMaker,"UserData",[OperationTypeSelector.Value,'ALL']),"Visible","on");
            %     % turn back on objects for the specific selected operation (indicated by UserData property)
            %     set(findobj(fHMaskMaker,"UserData",OperationNameSelector.Value),"Visible","on");
            case {'Special','ImageFilter','ContrastEnhancement','Binarize','Arithmetic','bwmorph'}
                % get all objects associated with the operation type specified by OperationTypeSelector.Value
                OperationTypeObjects = findobj(fHMaskMaker,"Tag",[OperationTypeSelector.Value,'Operations']);
                % set Visibiity to 'off'
                set(OperationTypeObjects,'Visible','Off');
                % for each object associated with the selected operation type
                for j = 1:numel(OperationTypeObjects)
                    % check if the associated operation name (in UserData) matches the object
                    if ismember(OperationNameSelector.Value,OperationTypeObjects(j).UserData)
                        % if so, make it visible
                        OperationTypeObjects(j).Visible = 'On';
                    end
                end
        end

    end

    function UpdateContrastEnhancementOptions(~,~)
        
        switch OperationNameSelector.Value
            case 'EnhanceFibers'
                FiberWidth = round(str2double(ContrastEnhancementOptionsFiberWidthEditfield.Value));
                ContrastEnhancementOptionsFiberWidthEditfield.Value = num2str(FiberWidth);
                ContrastEnhancementOptions = {FiberWidth};
                NamedParams = {'FiberWidth',FiberWidth};
            case 'Flatfield'
                ffSigma = abs(str2double(ContrastEnhancementOptionsSigmaEditfield.Value));
                FilterSize = str2double(ContrastEnhancementOptionsFilterSizeEditfield.Value);
                if ~rem(FilterSize,2)
                    FilterSize = FilterSize+1;
                end
                ContrastEnhancementOptionsSigmaEditfield.Value = num2str(ffSigma);
                ContrastEnhancementOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                ContrastEnhancementOptions = {ffSigma,FilterSize};
                NamedParams = {'Sigma',ffSigma,'FilterSize',FilterSize};
            otherwise
                ContrastEnhancementOptions = {};
                NamedParams = {};
        end
                
    end

    function UpdateBinarizeOptions(~,~)

        switch OperationNameSelector.Value
            case 'Otsu'
                BinarizeOptions = {};
                NamedParams = {};
            case 'Adaptive'
                NeighborhoodSize = uint16(str2double(BinarizeOptionsNeighborhoodSizeEditfield.Value));
                if ~rem(NeighborhoodSize,2)
                    NeighborhoodSize = NeighborhoodSize+1;
                    BinarizeOptionsNeighborhoodSizeEditfield.Value = num2str(NeighborhoodSize);
                end

                Statistic = BinarizeOptionsStatisticDropdown.Value;

                Sensitivity = str2double(BinarizeOptionsSensitivityEditfield.Value);
                if Sensitivity > 1
                    Sensitivity = 1;
                    BinarizeOptionsSensitivityEditfield.Value = num2str(Sensitivity);
                end

                BinarizeOptions = {Sensitivity,NeighborhoodSize,Statistic};
                NamedParams = {...
                    'Sensitivity',Sensitivity,...
                    'NeighborhoodSize',NeighborhoodSize,...
                    'Statistic',Statistic...
                    };
        end
    end

    function UpdateImageFilterOptions(~,~)

        switch OperationNameSelector.Value
            case {'Median','Average','Wiener'}
                FilterSize = round(str2double(ImageFilterOptionsFilterSizeEditfield.Value));
                ImageFilterOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                ImageFilterOptions = {FilterSize};
                NamedParams = {'FilterSize',FilterSize};
            case {'Gaussian','LaplacianOfGaussian'}
                FilterSize = round(str2double(ImageFilterOptionsFilterSizeEditfield.Value));
                ImageFilterOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                ImageFilterOptions = {FilterSize};
                Sigma = abs(str2double(ImageFilterOptionsSigmaEditfield.Value));
                ImageFilterOptions{2} = Sigma;
                NamedParams = {'FilterSize',FilterSize,'Sigma',Sigma};
            case 'Bilateral'
                FilterSize = round(str2double(ImageFilterOptionsFilterSizeEditfield.Value));
                ImageFilterOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                if ~rem(FilterSize,2)
                    FilterSize = FilterSize + 1;
                    ImageFilterOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                end
                ImageFilterOptions = {FilterSize};
                SpatialSigma = abs(str2double(ImageFilterOptionsSpatialSigmaEditfield.Value));
                ImageFilterOptions{2} = SpatialSigma;
                NamedParams = {'FilterSize',FilterSize,'SpatialSigma',SpatialSigma};
            case 'NonLocalMeans'
                DegreeOfSmoothing = str2double(ImageFilterOptionsDegreeOfSmoothingEditfield.Value);
                SearchWindowSize = str2double(ImageFilterOptionsSearchWindowSizeEditfield.Value);
                ComparisonWindowSize = str2double(ImageFilterOptionsComparisonWindowSizeEditfield.Value);
                ImageFilterOptions = {DegreeOfSmoothing,SearchWindowSize,ComparisonWindowSize};
                NamedParams = {...
                    'DegreeOfSmoothing',DegreeOfSmoothing,...
                    'SearchWindowSize',SearchWindowSize,...
                    'ComparisonWindowSize',ComparisonWindowSize
                    };
        end
    end

    function UpdateEdgeDetectionOptions(~,~)
        EdgeDetectionOptions = {};
        NamedParams = {};
    end

    function UpdatebwmorphOptions(~,~)
        n = bwmorphOptionsNEditfield.Value;
        bwmorphOptions = {n};
        NamedParams = {'n',n};
    end

    function UpdateArithmeticOptions(~,~)
        ArithmeticOptions = {};
        NamedParams = {};
    end

    function UpdateSpecialOptions(~,~)

        switch OperationNameSelector.Value
            case {'RotatingMaxOpen','BWRotatingMaxOpen','BWRotatingMaxOpenAndClose'}
                RotatingLineLength = round(str2double(RotatingLineLengthEditfield.Value));
                RotatingLineLengthEditfield.Value = num2str(RotatingLineLength);
                SpecialOptions = {RotatingLineLength};
                NamedParams = {...
                    'RotatingLineLength',RotatingLineLength...
                    };
            case 'BWAreaOpen'
                BWArea = round(abs(str2double(BWAreaEditfield.Value)));
                BWAreaEditfield.Value = num2str(BWArea);
                SpecialOptions = {BWArea};
                NamedParams = {...
                    'BWArea',BWArea,...
                    };
            case 'BlindDeconvolution'
                FilterSize = round(abs(str2double(SpecialOptionsFilterSizeEditfield.Value)));
                SpecialOptionsFilterSizeEditfield.Value = num2str(FilterSize);
                SpecialOptions = {FilterSize};
                NamedParams = {...
                    'FilterSize',FilterSize,...
                    };
            otherwise
                SpecialOptions = {};
                NamedParams = {};
        end

    end

    function UpdateSE(~,~)

        Shape = MorphologicalOptionsSEShapeDropdown.Value;
        
        switch Shape
            case 'Diamond'
                Radius = str2double(MorphologicalOptionsRadiusEditfield.Value);
                SE = strel(Shape,Radius);
                NamedParams = {'Shape','Diamond','Radius',Radius};
            case 'Disk'
                Radius = str2double(MorphologicalOptionsRadiusEditfield.Value);
                n = str2double(MorphologicalOptionsnDropdown.Value);
                SE = strel(Shape,Radius,n);
                NamedParams = {'Shape','Disk','Radius',Radius,'n',n};
            case 'Octagon'
                Radius = 3*round(str2double(MorphologicalOptionsRadiusEditfield.Value)/3);
                SE = strel(Shape,Radius);
                NamedParams = {'Shape','Octagon','Radius',Radius};
            case 'Line'
                Length = abs(str2double(MorphologicalOptionsLengthEditfield.Value));
                Angle = abs(str2double(MorphologicalOptionsDegreesEditfield.Value));
                SE = strel(Shape,Length,Angle);
                NamedParams = {'Shape','Line','Length',Length,'Angle',Angle};
            case 'Rectangle'
                Height = str2double(MorphologicalOptionsHeightEditfield.Value);
                Width = str2double(MorphologicalOptionsWidthEditfield.Value);
                SE = strel(Shape,[Height Width]);
                NamedParams = {'Shape','Rectangle','Height',Height,'Width',Width};
        end

        SEImgH.CData = SE.Neighborhood;

    end

%% Edit the currently selected operation

    function EditOperation(~,~)
        % type of CustomOperation we need to make
        OperationType = OperationTypeSelector.Value;
        % name of specific operation we need to make
        OperationName = OperationNameSelector.Value;

        CurrentOperationIdx = find(Scheme.CurrentOperation==Scheme.Operations);

        switch OperationType
            case 'Morphological'
                Target = MorphologicalOptionsTargetDropdown.Value;
                if isValidEditTarget(Target)
                    UpdateSE();
                    Scheme.EditOperation(CurrentOperationIdx,OperationType,OperationName,Target,{SE},NamedParams{:});
                end
            case 'Binarize'
                Target = BinarizeOptionsTargetDropdown.Value;
                if isValidEditTarget(Target)
                    UpdateBinarizeOptions();
                    Scheme.EditOperation(CurrentOperationIdx,OperationType,OperationName,Target,BinarizeOptions,NamedParams{:});
                end
            case 'ImageFilter'
                Target = ImageFilterOptionsTargetDropdown.Value;
                if isValidEditTarget(Target)
                    UpdateImageFilterOptions();
                    Scheme.EditOperation(CurrentOperationIdx,OperationType,OperationName,Target,ImageFilterOptions,NamedParams{:});
                end
            case 'Arithmetic'
                Target(1) = ArithmeticOptionsTargetDropdown1.Value;
                Target(2) = ArithmeticOptionsTargetDropdown2.Value;
                if isValidEditTarget(Target(1)) && isValidEditTarget(Target(2))
                    UpdateArithmeticOptions();
                    Scheme.EditOperation(CurrentOperationIdx,OperationType,OperationName,Target,ArithmeticOptions,NamedParams{:});
                end
            case 'ContrastEnhancement'
                Target = ContrastEnhancementOptionsTargetDropdown.Value;
                if isValidEditTarget(Target)
                    UpdateContrastEnhancementOptions();
                    Scheme.EditOperation(CurrentOperationIdx,OperationType,OperationName,Target,ContrastEnhancementOptions,NamedParams{:});
                end
            case 'Special'
                Target = SpecialOptionsTargetDropdown.Value;
                if isValidEditTarget(Target)
                    UpdateSpecialOptions();
                    Scheme.EditOperation(CurrentOperationIdx,OperationType,OperationName,Target,SpecialOptions,NamedParams{:});
                end
            case 'EdgeDetection'
                Target = EdgeDetectionOptionsTargetDropdown.Value;
                if isValidEditTarget(Target)
                    UpdateEdgeDetectionOptions();
                    Scheme.EditOperation(CurrentOperationIdx,OperationType,OperationName,Target,EdgeDetectionOptions,NamedParams{:});
                end
            case 'bwmorph'
                Target = bwmorphOptionsTargetDropdown.Value;
                if isValidEditTarget(Target)
                    UpdatebwmorphOptions();
                    Scheme.EditOperation(CurrentOperationIdx,OperationType,OperationName,Target,bwmorphOptions,NamedParams{:});
                end
        end

        try
            % execute the step that we just added
            Scheme.ExecuteFromStep(CurrentOperationIdx);
        catch ME
            uialert(fHMaskMaker,ME.message,'Error');
        end

        Scheme.CurrentImageIdx = CurrentOperationIdx;
        Scheme.CurrentOperationIdx = CurrentOperationIdx;

        % update various listboxes
        ImageSelector.Items = Scheme.ImagesTextDisplay;
        ImageSelector.ItemsData = 1:Scheme.nImages;
        ImageSelector.Value = CurrentOperationIdx;

        OperationSelector.Items = Scheme.OperationsTextDisplay;
        OperationSelector.ItemsData = 1:Scheme.nOperations;
        OperationSelector.Value = CurrentOperationIdx;

        % update image display
        UpdateMainImage();

    end

    function TF = isValidEditTarget(Target)
    % check if a given Target image is valid to edit the current operation
    % to be valid, the Target must be an existing image in the scheme with 
    % an idx < idx of the operation targeting it
        % find the idx of the currently selected Target in the scheme
        TargetIdx = find(Target==Scheme.Images);
        % find the index of the currently selected image (or operation, should be the same)
        ImageIdx = ImageSelector.Value;
        % return true if the target idx is less than the image idx, false otherwise
        TF = TargetIdx < ImageIdx;
    end

%% Add a new operation to the scheme

    function AddOperationToScheme(~,~)
        % type of CustomOperation we need to make
        OperationType = OperationTypeSelector.Value;
        % name of specific operation we need to make
        OperationName = OperationNameSelector.Value;

        switch OperationType
            case 'Morphological'
                Target = MorphologicalOptionsTargetDropdown.Value;
                UpdateSE();
                Scheme.AddOperation(OperationType,OperationName,Target,{SE},NamedParams{:});
            case 'Binarize'
                Target = BinarizeOptionsTargetDropdown.Value;
                UpdateBinarizeOptions();
                Scheme.AddOperation(OperationType,OperationName,Target,BinarizeOptions,NamedParams{:});
            case 'ImageFilter'
                Target = ImageFilterOptionsTargetDropdown.Value;
                UpdateImageFilterOptions();
                Scheme.AddOperation(OperationType,OperationName,Target,ImageFilterOptions,NamedParams{:});
            case 'Arithmetic'
                Target(1) = ArithmeticOptionsTargetDropdown1.Value;
                Target(2) = ArithmeticOptionsTargetDropdown2.Value;
                UpdateArithmeticOptions();
                Scheme.AddOperation(OperationType,OperationName,Target,ArithmeticOptions,NamedParams{:});
            case 'ContrastEnhancement'
                Target = ContrastEnhancementOptionsTargetDropdown.Value;
                UpdateContrastEnhancementOptions();
                Scheme.AddOperation(OperationType,OperationName,Target,ContrastEnhancementOptions,NamedParams{:});
            case 'Special'
                Target = SpecialOptionsTargetDropdown.Value;
                UpdateSpecialOptions();
                Scheme.AddOperation(OperationType,OperationName,Target,SpecialOptions,NamedParams{:});
            case 'EdgeDetection'
                Target = EdgeDetectionOptionsTargetDropdown.Value;
                UpdateEdgeDetectionOptions();
                Scheme.AddOperation(OperationType,OperationName,Target,EdgeDetectionOptions,NamedParams{:});
            case 'bwmorph'
                Target = bwmorphOptionsTargetDropdown.Value;
                UpdatebwmorphOptions();
                Scheme.AddOperation(OperationType,OperationName,Target,bwmorphOptions,NamedParams{:});
        end

        try
            % execute the step that we just added
            Scheme.ExecuteStep(Scheme.nOperations);
        catch ME
            uialert(fHMaskMaker,ME.message,'Error');
        end

        Scheme.CurrentImageIdx = Scheme.nImages;
        Scheme.CurrentOperationIdx = Scheme.nOperations;

        % update various listboxes
        ImageSelector.Items = Scheme.ImagesTextDisplay;
        ImageSelector.ItemsData = 1:Scheme.nImages;
        ImageSelector.Value = Scheme.nImages;

        OperationSelector.Items = Scheme.OperationsTextDisplay;
        OperationSelector.ItemsData = 1:Scheme.nOperations;
        OperationSelector.Value = Scheme.nOperations;

        % update image display
        UpdateMainImage();

        % update target dropdowns
        UpdateTargetDropdowns();        

    end

    function MorphologicalOptionsSEShapeChanged(source,~)

        Shape = source.Value;

        MorphologicalOptionsObjects = findobj(fHMaskMaker,"Tag",'MorphologicalOperations');

        set(MorphologicalOptionsObjects,"Visible","Off");

        switch Shape
            case 'Diamond'
                MorphologicalOptionsRadiusLabel.Visible = "on";
                MorphologicalOptionsRadiusEditfield.Visible = "on";
            case 'Disk'
                MorphologicalOptionsRadiusLabel.Visible = "on";
                MorphologicalOptionsRadiusEditfield.Visible = "on";

                MorphologicalOptionsnLabel.Visible = "on";
                MorphologicalOptionsnDropdown.Visible = "on";
            case 'Octagon'
                MorphologicalOptionsRadiusLabel.Visible = "on";
                MorphologicalOptionsRadiusEditfield.Visible = "on";
            case 'Line'
                MorphologicalOptionsLengthLabel.Visible = "on";
                MorphologicalOptionsLengthEditfield.Visible = "on";

                MorphologicalOptionsDegreesLabel.Visible = "on";
                MorphologicalOptionsDegreesEditfield.Visible = "on";                
            case 'Rectangle'
                MorphologicalOptionsHeightLabel.Visible = "on";
                MorphologicalOptionsHeightEditfield.Visible = "on";

                MorphologicalOptionsWidthLabel.Visible = "on";
                MorphologicalOptionsWidthEditfield.Visible = "on";
        end

        % update the SE data and display new SE image
        UpdateSE();

    end

    function MainWindowSizeChanged(~,~)
        %Height = fHMaskMaker.InnerPosition(4);
        MainGrid.ColumnWidth{2} = round(fHMaskMaker.InnerPosition(4)-10);
        %drawnow limitrate
        drawnow
        %ImageDisplayAxes.InnerPosition = [0 0 1 1];
    end

end