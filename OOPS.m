function OOPS()
%%  OOPS Primary driver for the Object-Oriented Polarization Software (OOPS) GUI
%
%   NOTES:
%
%       Before starting, make sure all relevant files are reachable on the MATLAB PATH.
%       (all files in the directory containing "OOPS.m", including all subdirectories
%
%   USAGE:
%
%       Run the function to open the GUI by typing the following into the command window:
%           >> OOPS
%
%----------------------------------------------------------------------------------------------------------------------------

%% start the parallel pool

% try to start the parallel pool 
try
    parpool("threads");
catch
    warning("Unable to create parallel pool...")
end

%% set up the data structure

% create an instance of OOPSProject - this object will hold ALL project data and GUI settings
OOPSData = OOPSProject();

%% set up the main window

% struct to hold graphics objects
OOPSData.Handles = struct();
% create the uifigure (main gui window)
OOPSData.Handles.fH = uifigure('Name','OOPS GUI',...
    'numbertitle','off',...
    'units','pixels',...
    'Position',OOPSData.Settings.ScreenSize,...
    'Visible','Off',...
    'Color','white',...
    'HandleVisibility','on',...
    'AutoResizeChildren','off',...
    'SizeChangedFcn',@ResetContainerSizes);

%% set some defaults to save time and improve readability

% panel properties
set(OOPSData.Handles.fH,'defaultUipanelFontName',OOPSData.Settings.DefaultFont);
set(OOPSData.Handles.fH,'defaultUipanelFontWeight','Bold');
set(OOPSData.Handles.fH,'defaultUipanelBackgroundColor','Black');
set(OOPSData.Handles.fH,'defaultUipanelForegroundColor','White');
set(OOPSData.Handles.fH,'defaultUipanelAutoResizeChildren','Off');

% text properties
set(OOPSData.Handles.fH,'defaultTextFontName',OOPSData.Settings.DefaultFont);
set(OOPSData.Handles.fH,'defaultTextFontWeight','bold');

% turn off any warnings that do not adversely affect computation
warning('off','MATLAB:polyshape:repairedBySimplify');

%% CHECKPOINT

disp('Setting up menubar...')

%% File Menu Button - Create a new project, load files, etc...

OOPSData.Handles.hFileMenu = uimenu(OOPSData.Handles.fH,'Text','File');
% Options for File Menu Button
OOPSData.Handles.hNewProject = uimenu(OOPSData.Handles.hFileMenu,'Text','&New project','Callback',@newProject);
OOPSData.Handles.hNewProject.Accelerator = 'N';
% menu for loading existing project
OOPSData.Handles.hLoadProject = uimenu(OOPSData.Handles.hFileMenu,'Text','Load project','Callback',@loadProject);
OOPSData.Handles.hSaveProject = uimenu(OOPSData.Handles.hFileMenu,'Text','Save project','Callback',@saveProject);
% load files
OOPSData.Handles.hLoadFFCFiles = uimenu(OOPSData.Handles.hFileMenu,'Text','Load FFC stacks','Separator','On','Callback',@loadFFCImages);
OOPSData.Handles.hLoadFPMFiles = uimenu(OOPSData.Handles.hFileMenu,'Text','Load FPM stacks','Callback',@loadFPMImages);
OOPSData.Handles.hLoadReferenceImages = uimenu(OOPSData.Handles.hFileMenu,'Text','Load reference images','Callback',@loadReferenceImages);
OOPSData.Handles.hLoadMaskImages = uimenu(OOPSData.Handles.hFileMenu,'Text','Load mask images');
OOPSData.Handles.hLoadMaskImages_4conn = uimenu(OOPSData.Handles.hLoadMaskImages,'Text','Label 4-connected objects','Callback',@loadMaskImages,'Tag','4conn');
OOPSData.Handles.hLoadMaskImages_branches = uimenu(OOPSData.Handles.hLoadMaskImages,'Text','Label branches','Callback',@loadMaskImages,'Tag','branches');
% save data
OOPSData.Handles.hSaveImageData = uimenu(OOPSData.Handles.hFileMenu,'Text','Export images','Separator','On','Callback',@exportImages);
OOPSData.Handles.hSaveObjectData = uimenu(OOPSData.Handles.hFileMenu,'Text','Export object data','Callback',@SaveObjectData);
% segmentation schemes
OOPSData.Handles.hNewSegmentationScheme = uimenu(OOPSData.Handles.hFileMenu,'Text','New segmentation scheme','Separator','On','Callback',@BuildNewScheme);
% save settings
OOPSData.Handles.hSaveSettings = uimenu(OOPSData.Handles.hFileMenu,'Text','Save settings','Separator','on','Callback',@saveSettings);

%% View Menu Button - changes view of GUI to different 'tabs'

OOPSData.Handles.hTabMenu = uimenu(OOPSData.Handles.fH,'Text','View');
% Tabs for 'View'
OOPSData.Handles.hTabFiles = uimenu(OOPSData.Handles.hTabMenu,'Text','Files','MenuSelectedFcn',@TabSelection,'tag','hTabFiles');
OOPSData.Handles.hTabFFC = uimenu(OOPSData.Handles.hTabMenu,'Text','FFC','MenuSelectedFcn',@TabSelection,'tag','hTabFFC');
OOPSData.Handles.hTabMask = uimenu(OOPSData.Handles.hTabMenu,'Text','Mask','MenuSelectedFcn',@TabSelection,'tag','hTabMask');
OOPSData.Handles.hTabOrder = uimenu(OOPSData.Handles.hTabMenu,'Text','Order','MenuSelectedFcn',@TabSelection,'tag','hTabOrder');
OOPSData.Handles.hTabAzimuth = uimenu(OOPSData.Handles.hTabMenu,'Text','Azimuth','MenuSelectedFcn',@TabSelection,'tag','hTabAzimuth');
OOPSData.Handles.hTabPlots = uimenu(OOPSData.Handles.hTabMenu,'Text','Plots','MenuSelectedFcn',@TabSelection,'tag','hTabPlots');
OOPSData.Handles.hTabPolarPlots = uimenu(OOPSData.Handles.hTabMenu,'Text','Polar Plots','MenuSelectedFcn',@TabSelection,'tag','hTabPolarPlots');
OOPSData.Handles.hTabObjects = uimenu(OOPSData.Handles.hTabMenu,'Text','Objects','MenuSelectedFcn',@TabSelection,'tag','hTabObjects');

% add a View option for each custom statistic
for i = 1:numel(OOPSData.Settings.CustomStatistics)
    % get the next statistic
    thisStatistic = OOPSData.Settings.CustomStatistics(i);
    % create a tab for it, add a separator above the first one
    OOPSData.Handles.(['hTab',thisStatistic.StatisticName]) = uimenu(OOPSData.Handles.hTabMenu,...
        'Text',thisStatistic.StatisticDisplayName,...
        'MenuSelectedFcn',@TabSelection,...
        'tag',thisStatistic.StatisticName,...
        'Separator',i==1);
end

%% Process Menu Button - allows user to perform FFC, generate mask, and generate output images

OOPSData.Handles.hProcessMenu = uimenu(OOPSData.Handles.fH,'Text','Process');
% Process Operations
OOPSData.Handles.hProcessFFC = uimenu(OOPSData.Handles.hProcessMenu,'Text','Flat-field correction','MenuSelectedFcn',@processFFC);
OOPSData.Handles.hProcessMask = uimenu(OOPSData.Handles.hProcessMenu,'Text','Build mask','MenuSelectedFcn',@processMask);
OOPSData.Handles.hProcessOrder = uimenu(OOPSData.Handles.hProcessMenu,'Text','Calculate FPM statistics','MenuSelectedFcn',@processFPMStats);
OOPSData.Handles.hProcessAll = uimenu(OOPSData.Handles.hProcessMenu,'Text','All','Separator','on','MenuSelectedFcn',@processAll);

%% Summary Menu Button

OOPSData.Handles.hSummaryMenu = uimenu(OOPSData.Handles.fH,'Text','Summary');
% Summary choices
OOPSData.Handles.hSumaryAll = uimenu(OOPSData.Handles.hSummaryMenu,'Text','Project','MenuSelectedFcn',@ShowSummaryTable);

%% Objects Menu Button

OOPSData.Handles.hObjectsMenu = uimenu(OOPSData.Handles.fH,'Text','Objects');
% select objects by property
OOPSData.Handles.hSelectObjectsByProperty = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Select by property','MenuSelectedFcn',@mbSelectObjectsByProperty);
% delete selected objects
OOPSData.Handles.hDeleteSelectedObjects = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Delete selected objects');
OOPSData.Handles.hDeleteSelectedObjects_InProject = uimenu(OOPSData.Handles.hDeleteSelectedObjects,'Text','In project','MenuSelectedFcn',@mbDeleteSelectedObjects,'Tag','Project');
OOPSData.Handles.hDeleteSelectedObjects_InProject.Accelerator = 'D';
OOPSData.Handles.hDeleteSelectedObjects_InGroup = uimenu(OOPSData.Handles.hDeleteSelectedObjects,'Text','In group','MenuSelectedFcn',@mbDeleteSelectedObjects,'Tag','Group');
OOPSData.Handles.hDeleteSelectedObjects_InImage = uimenu(OOPSData.Handles.hDeleteSelectedObjects,'Text','In image','MenuSelectedFcn',@mbDeleteSelectedObjects,'Tag','Image');
% clear selection status
OOPSData.Handles.hClearSelection = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Clear selection');
OOPSData.Handles.hClearSelection_InProject = uimenu(OOPSData.Handles.hClearSelection,'Text','In project','MenuSelectedFcn',@mbClearSelection,'Tag','Project');
OOPSData.Handles.hClearSelection_InGroup = uimenu(OOPSData.Handles.hClearSelection,'Text','In group','MenuSelectedFcn',@mbClearSelection,'Tag','Group');
OOPSData.Handles.hClearSelection_InImage = uimenu(OOPSData.Handles.hClearSelection,'Text','In image','MenuSelectedFcn',@mbClearSelection,'Tag','Image');

OOPSData.Handles.hkMeansClustering = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Label with k-means clustering','MenuSelectedFcn',@mbObjectkmeansClustering);
OOPSData.Handles.hShowObjectImagesByLabel = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Show object images by label','MenuSelectedFcn',@mbShowObjectImagesByLabel);

%% Plot Menu Button

OOPSData.Handles.hPlotMenu = uimenu(OOPSData.Handles.fH,'Text','Plot');
% Plot options
OOPSData.Handles.hPlotGroupScatterPlotMatrix = uimenu(OOPSData.Handles.hPlotMenu,'Text','Group scatter plot matrix','MenuSelectedFcn',@PlotGroupScatterPlotMatrix);
OOPSData.Handles.hPlotObjectIntensityProfile = uimenu(OOPSData.Handles.hPlotMenu,'Text','Object intensity profile','MenuSelectedFcn',@xPlotObjectIntensityProfile);
OOPSData.Handles.hPlotFullAzimuthQuiver = uimenu(OOPSData.Handles.hPlotMenu,'Text','Azimuth stick plot','MenuSelectedFcn',@PlotFullAzimuthQuiver);
% Show images
OOPSData.Handles.hPlot_Images = uimenu(OOPSData.Handles.hPlotMenu,'Text','Images');
% options for 'Images'
OOPSData.Handles.hPlot_Images_OrderImageRGB = uimenu(OOPSData.Handles.hPlot_Images,'Text','Order','Tag','OrderImageRGB','MenuSelectedFcn',@ShowImage);
OOPSData.Handles.hPlot_Images_MaskedOrderImageRGB = uimenu(OOPSData.Handles.hPlot_Images,'Text','Masked Order','Tag','MaskedOrderImageRGB','MenuSelectedFcn',@ShowImage);
OOPSData.Handles.hPlot_Images_OrderIntensityOverlayRGB = uimenu(OOPSData.Handles.hPlot_Images,'Text','Order-intensity overlay','Tag','OrderIntensityOverlayRGB','MenuSelectedFcn',@ShowImage);
OOPSData.Handles.hPlot_Images_UserScaledOrderIntensityOverlayRGB = uimenu(OOPSData.Handles.hPlot_Images,'Text','User-scaled Order-intensity overlay','Tag','UserScaledOrderIntensityOverlayRGB','MenuSelectedFcn',@ShowImage);
OOPSData.Handles.hPlot_Images_AzimuthRGB = uimenu(OOPSData.Handles.hPlot_Images,'Text','Azimuth','Tag','AzimuthRGB','MenuSelectedFcn',@ShowImage);
OOPSData.Handles.hPlot_Images_MaskedAzimuthRGB = uimenu(OOPSData.Handles.hPlot_Images,'Text','Masked azimuth','Tag','MaskedAzimuthRGB','MenuSelectedFcn',@ShowImage);
OOPSData.Handles.hPlot_Images_AzimuthOrderIntensityOverlayHSV = uimenu(OOPSData.Handles.hPlot_Images,'Text','Azimuth-Order-intensity HSV','Tag','AzimuthOrderIntensityHSV','MenuSelectedFcn',@ShowImage);
OOPSData.Handles.hPlot_Images_MaskRGBImage = uimenu(OOPSData.Handles.hPlot_Images,'Text','Mask','Tag','MaskRGBImage','MenuSelectedFcn',@ShowImage);
OOPSData.Handles.hPlot_Images_ObjectLabelImageRGB = uimenu(OOPSData.Handles.hPlot_Images,'Text','Object labels','Tag','ObjectLabelImageRGB','MenuSelectedFcn',@ShowImage);

%% draw the menu bar objects and pause for more predictable performance

drawnow
pause(0.5)

%% CHECKPOINT

disp('Setting up grid layout manager...')

%% Set up the MainGrid uigridlayout manager

pos = OOPSData.Handles.fH.Position;

% width of the large plots
largeWidth = round(pos(3)*0.38);

% and the small plots
smallWidth = round(largeWidth/2);
% sheight = smallWidth;

% main grid for managing layout
OOPSData.Handles.MainGrid = uigridlayout(OOPSData.Handles.fH,[4,5],...
    "BackgroundColor",[0 0 0],...
    "RowHeight",{'1x',smallWidth,smallWidth,'1x'},...
    "ColumnWidth",{'1x',smallWidth,smallWidth,smallWidth,smallWidth},...
    "RowSpacing",0,...
    "ColumnSpacing",0,...
    "Padding",[0 0 0 0]);

%% CHECKPOINT

disp('Setting up summary tables...')

%% Create the non-image panels (Summary, Selector, Settings, Log)

% panel to show project summary
OOPSData.Handles.AppInfoPanel = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off',...
    'Title','Project Summary',...
    'Scrollable','off',...
    'BackgroundColor',[0 0 0]);
OOPSData.Handles.AppInfoPanel.Layout.Row = 3;
OOPSData.Handles.AppInfoPanel.Layout.Column = 1;

OOPSData.Handles.ProjectSummaryPanelGrid = uigridlayout(OOPSData.Handles.AppInfoPanel,[2,1],...
    "RowHeight",{'fit','1x'},...
    "RowSpacing",0,...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    "Visible","off");

OOPSData.Handles.AppInfoSelector = uilistbox(...
    'parent',OOPSData.Handles.ProjectSummaryPanelGrid,...
    'Visible','Off',...
    'enable','on',...
    'tag','AppInfoSelector',...
    'Items',{'Project','Group','Image','Object'},...
    'BackgroundColor',[1 1 1],...
    'FontColor',[0 0 0],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'MultiSelect','Off',...
    'ValueChangedFcn',@ChangeSummaryDisplay);
OOPSData.Handles.AppInfoSelector.Layout.Row = 1;

%% Summary table for current project/group/image/object

% summary table for the project
OOPSData.Handles.ProjectSummaryTableGrid = uigridlayout(OOPSData.Handles.ProjectSummaryPanelGrid,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Scrollable','on',...
    'RowHeight',{'fit'},...
    'Visible','off');
OOPSData.Handles.ProjectSummaryTableGrid.Layout.Row = 2;
OOPSData.Handles.ProjectSummaryTable = uitable(OOPSData.Handles.ProjectSummaryTableGrid,...
    "BackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "ForegroundColor",OOPSData.Settings.GUIForegroundColor,...
    "FontName",OOPSData.Settings.DefaultFont,...
    "Visible","off");

%% CHECKPOINT

disp('Setting up settings panels...')

%% set up main settings panel

OOPSData.Handles.SettingsPanel = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off',...
    'Title','Settings');
OOPSData.Handles.SettingsPanel.Layout.Row = [1 2];
OOPSData.Handles.SettingsPanel.Layout.Column = 1;

% grid to fill the settings panel and hold the settings accordion
OOPSData.Handles.SettingsPanelGrid = uigridlayout(OOPSData.Handles.SettingsPanel,...
    [1,1],...
    "ColumnWidth",{'1x'},...
    "RowHeight",{'1x'},...
    "Padding",[0 0 0 0],...
    "BackgroundColor",OOPSData.Settings.GUIBackgroundColor);

% settings accordion - custom ui component
OOPSData.Handles.SettingsAccordion = uiaccordion(OOPSData.Handles.SettingsPanelGrid,...
    "BackgroundColor",OOPSData.Settings.GUIBackgroundColor);

%% set up some variables used broadly by multiple settings objects

% default matlab colors and colornames
[colorNames,colorCodes] = colornames('MATLAB');
colorNames = colorNames';
colorCodesCell = mat2cell(colorCodes,ones(size(colorCodes,1),1),3)';

%% CHECKPOINT

disp('Setting up colormaps settings...')

%% colormaps settings

ColormapNames = fieldnames(OOPSData.Settings.Colormaps);
ImageTypeFields = fieldnames(OOPSData.Settings.ColormapsSettings);
nImageTypes = length(ImageTypeFields);
ImageTypeFullNames = ImageTypeFields;
ImageTypeColormapsNames = cell(nImageTypes,1);
ImageTypeColormaps = cell(nImageTypes,1);
for k = 1:nImageTypes
    ImageTypeColormapsNames{k,1} = OOPSData.Settings.ColormapsSettings.(ImageTypeFields{k}).Name;
    ImageTypeColormaps{k,1} = OOPSData.Settings.ColormapsSettings.(ImageTypeFields{k}).Map;
end

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Colormaps",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.ColormapsSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(1).Pane;

set(OOPSData.Handles.ColormapsSettingsGrid,...
    "BackgroundColor",[0 0 0],...
    "Padding",[5 5 5 5],...
    "RowSpacing",5,...
    "ColumnSpacing",5,...
    "RowHeight",{20,30,'1x'},...
    "ColumnWidth",{'fit','1x'})

% colormap type 
OOPSData.Handles.ColormapsImageTypeLabel = uilabel(...
    'Parent',OOPSData.Handles.ColormapsSettingsGrid,...
    'Text','Colormap type',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ColormapsImageTypeLabel.Layout.Row = 1;
OOPSData.Handles.ColormapsImageTypeLabel.Layout.Column = 1;

OOPSData.Handles.ColormapsImageTypeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ColormapsSettingsGrid,...
    'Items',ImageTypeFullNames,...
    'ItemsData',ImageTypeFields,...
    'Value',ImageTypeFields{1},...
    'Tag','ImageTypeSelectBox',...
    'ValueChangedFcn',@ImageTypeSelectionChanged,...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.ColormapsImageTypeDropdown.Layout.Row = 1;
OOPSData.Handles.ColormapsImageTypeDropdown.Layout.Column = 2;

% panel to hold example colormap axes
OOPSData.Handles.ExampleColormapPanel = uipanel(OOPSData.Handles.ColormapsSettingsGrid);
OOPSData.Handles.ExampleColormapPanel.Layout.Row = 2;
OOPSData.Handles.ExampleColormapPanel.Layout.Column = [1 2];

% axes to hold example colorbar
OOPSData.Handles.ExampleColormapAx = uiaxes(OOPSData.Handles.ExampleColormapPanel,...
    'Visible','Off',...
    'XTick',[],...
    'YTick',[],...
    'Units','Normalized',...
    'InnerPosition',[0 0 1 1]);
OOPSData.Handles.ExampleColormapAx.Toolbar.Visible = 'Off';
disableDefaultInteractivity(OOPSData.Handles.ExampleColormapAx);

% create image to show example colorbar for colormap switching
OOPSData.Handles.ExampleColorbar = image(OOPSData.Handles.ExampleColormapAx,...
    'CData',repmat(1:256,50,1),...
    'CDataMapping','direct');

% set display limits to show full cbarimage without extra borders
OOPSData.Handles.ExampleColormapAx.YLim = [0.5 50.5];
OOPSData.Handles.ExampleColormapAx.XLim = [0.5 256.5];
% set the colormap of the axes holding our example image
OOPSData.Handles.ExampleColormapAx.Colormap = OOPSData.Settings.ColormapsSettings.(ImageTypeFields{1}).Map;  

% colormap selector
OOPSData.Handles.ColormapsPanel = uipanel(OOPSData.Handles.ColormapsSettingsGrid,...
    'Title','Colormaps',...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.ColormapsPanel.Layout.Row = 3;
OOPSData.Handles.ColormapsPanel.Layout.Column = [1 2];

OOPSData.Handles.ColormapsPanelGrid = uigridlayout(OOPSData.Handles.ColormapsPanel,...
    [1,1],...
    "RowHeight",{200},...
    "Padding",[0 0 0 0]);

OOPSData.Handles.ColormapsSelector = uilistbox(OOPSData.Handles.ColormapsPanelGrid,...
    'Items',ColormapNames,...
    'Value',OOPSData.Settings.ColormapsSettings.(ImageTypeFields{1}).Name,...
    'Tag','ColormapSelectBox',...
    'ValueChangedFcn',@ColormapSelectionChanged,...
    'FontName',OOPSData.Settings.DefaultFont);

% add icon styles to each item in the colormap selector listbox to give a colormap preview
colormapIconStyles = matlab.ui.style.Style;
colormapIconStyles = repmat(colormapIconStyles,numel(OOPSData.Handles.ColormapsSelector.Items),1);
for colormapIdx = 1:numel(OOPSData.Handles.ColormapsSelector.Items)
    colormapIconStyles(colormapIdx).Icon = OOPSData.Settings.Colormaps.(OOPSData.Handles.ColormapsSelector.Items{colormapIdx}).colormapImage([10,256],'r');
    addStyle(OOPSData.Handles.ColormapsSelector,colormapIconStyles(colormapIdx),"item",colormapIdx);
end

%% CHECKPOINT

disp('Setting up azimuth display settings...')

%% azimuth display settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Azimuth display",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.AzimuthDisplaySettingsGrid = OOPSData.Handles.SettingsAccordion.Items(2).Pane;

set(OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'BackgroundColor','Black',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20,20,20,20},...
    'ColumnWidth',{'fit','1x'});

OOPSData.Handles.AzimuthLineAlphaLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Line alpha',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthLineAlphaLabel.Layout.Row = 1;
OOPSData.Handles.AzimuthLineAlphaLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthLineAlphaDropdown = uidropdown(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
    'ItemsData',{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1},...
    'Value',OOPSData.Settings.AzimuthLineAlpha,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','LineAlpha',...
    'ValueChangedFcn',@AzimuthDisplaySettingsChanged);
OOPSData.Handles.AzimuthLineAlphaDropdown.Layout.Row = 1;
OOPSData.Handles.AzimuthLineAlphaDropdown.Layout.Column = 2;

OOPSData.Handles.AzimuthLineWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Line width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthLineWidthLabel.Layout.Row = 2;
OOPSData.Handles.AzimuthLineWidthLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthLineWidthDropdown = uidropdown(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'1','2','3','4','5','6','7','8','9','10'},...
    'ItemsData',{1,2,3,4,5,6,7,8,9,10},...
    'Value',OOPSData.Settings.AzimuthLineWidth,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','LineWidth',...
    'ValueChangedFcn',@AzimuthDisplaySettingsChanged);
OOPSData.Handles.AzimuthLineWidthDropdown.Layout.Row = 2;
OOPSData.Handles.AzimuthLineWidthDropdown.Layout.Column = 2;

OOPSData.Handles.AzimuthLineScaleLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Line scale factor',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthLineScaleLabel.Layout.Row = 3;
OOPSData.Handles.AzimuthLineScaleLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthLineScaleEditfield = uieditfield(...
    'numeric',...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Value',OOPSData.Settings.AzimuthLineScale,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','LineScale',...
    'ValueChangedFcn',@AzimuthDisplaySettingsChanged);
OOPSData.Handles.AzimuthLineScaleEditfield.Layout.Row = 3;
OOPSData.Handles.AzimuthLineScaleEditfield.Layout.Column = 2;

OOPSData.Handles.AzimuthLineScaleDownLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Number of lines to show',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthLineScaleDownLabel.Layout.Row = 4;
OOPSData.Handles.AzimuthLineScaleDownLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthLineScaleDownDropdown = uidropdown(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'All','Half','Quarter'},...
    'ItemsData',{1,2,4},...
    'Value',OOPSData.Settings.AzimuthScaleDownFactor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','ScaleDownFactor',...
    'ValueChangedFcn',@AzimuthDisplaySettingsChanged);
OOPSData.Handles.AzimuthLineScaleDownDropdown.Layout.Row = 4;
OOPSData.Handles.AzimuthLineScaleDownDropdown.Layout.Column = 2;
OOPSData.Handles.AzimuthLineScaleDownDropdown.ItemsData = [1 2 4];

OOPSData.Handles.AzimuthColorModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Line color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthColorModeDropdownLabel.Layout.Row = 5;
OOPSData.Handles.AzimuthColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthColorModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'Direction','Magnitude','Mono'},...
    'Value',OOPSData.Settings.AzimuthColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','ColorMode',...
    'ValueChangedFcn',@AzimuthDisplaySettingsChanged);
OOPSData.Handles.AzimuthColorModeDropdown.Layout.Row = 5;
OOPSData.Handles.AzimuthColorModeDropdown.Layout.Column = 2;

OOPSData.Handles.AzimuthObjectMaskDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Object mask',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthObjectMaskDropdownLabel.Layout.Row = 6;
OOPSData.Handles.AzimuthObjectMaskDropdownLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthObjectMaskDropdown = uidropdown(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'on','off'},...
    'ItemsData',{true,false},...
    'Value',OOPSData.Settings.AzimuthObjectMask,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','ObjectMask',...
    'ValueChangedFcn',@AzimuthObjectMaskChanged);
OOPSData.Handles.AzimuthObjectMaskDropdown.Layout.Row = 6;
OOPSData.Handles.AzimuthObjectMaskDropdown.Layout.Column = 2;

%% CHECKPOINT

disp('Setting up polar histogram settings...')

%% PolarHistogram settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Polar histogram",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.PolarHistogramSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(3).Pane;

set(OOPSData.Handles.PolarHistogramSettingsGrid,...
    'BackgroundColor','Black',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20,20,20,20,20,20,20,20,20,20,20,20},...
    'ColumnWidth',{'fit','1x'},...
    'Scrollable','on');

% variable to plot
OOPSData.Handles.PolarHistogramVariableLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Variable',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramVariableLabel.Layout.Row = 1;
OOPSData.Handles.PolarHistogramVariableLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramVariableDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',OOPSData.Settings.ObjectPolarPlotVariablesLong,...
    'ItemsData',OOPSData.Settings.ObjectPolarPlotVariables,...
    'Value',OOPSData.Settings.PolarHistogramVariable,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramVariableChanged);
OOPSData.Handles.PolarHistogramVariableDropdown.Layout.Row = 1;
OOPSData.Handles.PolarHistogramVariableDropdown.Layout.Column = 2;

% nBins
OOPSData.Handles.PolarHistogramnBinsLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Number of bins',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramnBinsLabel.Layout.Row = 2;
OOPSData.Handles.PolarHistogramnBinsLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramnBinsDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'12','24','48','96'},...
    'ItemsData',{12,24,48,96},...
    'Value',OOPSData.Settings.PolarHistogramnBins,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramnBinsChanged);
OOPSData.Handles.PolarHistogramnBinsDropdown.Layout.Row = 2;
OOPSData.Handles.PolarHistogramnBinsDropdown.Layout.Column = 2;

% wedge face alpha
OOPSData.Handles.PolarHistogramWedgeFaceAlphaLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Face alpha',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeFaceAlphaLabel.Layout.Row = 3;
OOPSData.Handles.PolarHistogramWedgeFaceAlphaLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeFaceAlphaDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
    'ItemsData',{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1},...
    'Value',OOPSData.Settings.PolarHistogramWedgeFaceAlpha,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramWedgeFaceAlphaChanged);
OOPSData.Handles.PolarHistogramWedgeFaceAlphaDropdown.Layout.Row = 3;
OOPSData.Handles.PolarHistogramWedgeFaceAlphaDropdown.Layout.Column = 2;

% wedge face color
OOPSData.Handles.PolarHistogramWedgeFaceColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Face color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeFaceColorLabel.Layout.Row = 4;
OOPSData.Handles.PolarHistogramWedgeFaceColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeFaceColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'flat','interp'},...
    'Value',OOPSData.Settings.PolarHistogramWedgeFaceColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramWedgeFaceColorChanged);
OOPSData.Handles.PolarHistogramWedgeFaceColorDropdown.Layout.Row = 4;
OOPSData.Handles.PolarHistogramWedgeFaceColorDropdown.Layout.Column = 2;

% wedge line width
OOPSData.Handles.PolarHistogramWedgeLineWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Wedge line width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeLineWidthLabel.Layout.Row = 5;
OOPSData.Handles.PolarHistogramWedgeLineWidthLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeLineWidthEditfield = uieditfield(...
    OOPSData.Handles.PolarHistogramSettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.PolarHistogramWedgeLineWidth,...
    'Limits',[0 10],...
    'ValueDisplayFormat','%.1f points',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramWedgeLineWidthChanged);
OOPSData.Handles.PolarHistogramWedgeLineWidthEditfield.Layout.Row = 5;
OOPSData.Handles.PolarHistogramWedgeLineWidthEditfield.Layout.Column = 2;

% wedge edge color mode
OOPSData.Handles.PolarHistogramWedgeEdgeColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Edge color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeEdgeColorLabel.Layout.Row = 6;
OOPSData.Handles.PolarHistogramWedgeEdgeColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeEdgeColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'flat','interp'},...
    'Value',OOPSData.Settings.PolarHistogramWedgeEdgeColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramWedgeEdgeColorChanged);
OOPSData.Handles.PolarHistogramWedgeEdgeColorDropdown.Layout.Row = 6;
OOPSData.Handles.PolarHistogramWedgeEdgeColorDropdown.Layout.Column = 2;

% wedge line color
OOPSData.Handles.PolarHistogramWedgeLineColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Edge color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeLineColorLabel.Layout.Row = 7;
OOPSData.Handles.PolarHistogramWedgeLineColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeLineColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.PolarHistogramWedgeLineColor},...
    'Value',OOPSData.Settings.PolarHistogramWedgeLineColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@PolarHistogramWedgeLineColorChanged});
OOPSData.Handles.PolarHistogramWedgeLineColorDropdown.Layout.Row = 7;
OOPSData.Handles.PolarHistogramWedgeLineColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.PolarHistogramWedgeLineColorDropdown);

% gridline colors
OOPSData.Handles.PolarHistogramGridlinesColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Gridlines color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramGridlinesColorLabel.Layout.Row = 8;
OOPSData.Handles.PolarHistogramGridlinesColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramGridlinesColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Gray','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],[.9 .9 .9],OOPSData.Settings.PolarHistogramGridlinesColor},...
    'Value',OOPSData.Settings.PolarHistogramGridlinesColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@PolarHistogramGridlinesColorChanged});
OOPSData.Handles.PolarHistogramGridlinesColorDropdown.Layout.Row = 8;
OOPSData.Handles.PolarHistogramGridlinesColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.PolarHistogramGridlinesColorDropdown);

% label colors
OOPSData.Handles.PolarHistogramLabelsColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Labels color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramLabelsColorLabel.Layout.Row = 9;
OOPSData.Handles.PolarHistogramLabelsColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramLabelsColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.PolarHistogramLabelsColor},...
    'Value',OOPSData.Settings.PolarHistogramLabelsColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@PolarHistogramLabelsColorChanged});
OOPSData.Handles.PolarHistogramLabelsColorDropdown.Layout.Row = 9;
OOPSData.Handles.PolarHistogramLabelsColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.PolarHistogramLabelsColorDropdown);

% gridline line widths
OOPSData.Handles.PolarHistogramGridlinesLineWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Gridlines line width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramGridlinesLineWidthLabel.Layout.Row = 10;
OOPSData.Handles.PolarHistogramGridlinesLineWidthLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramGridlinesLineWidthEditfield = uieditfield(...
    OOPSData.Handles.PolarHistogramSettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
    'Limits',[0 10],...
    'ValueDisplayFormat','%.1f points',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramGridlinesLineWidthChanged);
OOPSData.Handles.PolarHistogramGridlinesLineWidthEditfield.Layout.Row = 10;
OOPSData.Handles.PolarHistogramGridlinesLineWidthEditfield.Layout.Column = 2;

% circle background color
OOPSData.Handles.PolarHistogramCircleBackgroundColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Circle background color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramCircleBackgroundColorLabel.Layout.Row = 11;
OOPSData.Handles.PolarHistogramCircleBackgroundColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramCircleBackgroundColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.PolarHistogramCircleBackgroundColor},...
    'Value',OOPSData.Settings.PolarHistogramCircleBackgroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@PolarHistogramCircleBackgroundColorChanged});
OOPSData.Handles.PolarHistogramCircleBackgroundColorDropdown.Layout.Row = 11;
OOPSData.Handles.PolarHistogramCircleBackgroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.PolarHistogramCircleBackgroundColorDropdown);

% circle color
OOPSData.Handles.PolarHistogramCircleColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Circle line color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramCircleColorLabel.Layout.Row = 12;
OOPSData.Handles.PolarHistogramCircleColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramCircleColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.PolarHistogramCircleColor},...
    'Value',OOPSData.Settings.PolarHistogramCircleColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@PolarHistogramCircleColorChanged});
OOPSData.Handles.PolarHistogramCircleColorDropdown.Layout.Row = 12;
OOPSData.Handles.PolarHistogramCircleColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.PolarHistogramCircleColorDropdown);

% background color
OOPSData.Handles.PolarHistogramBackgroundColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Background color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramBackgroundColorLabel.Layout.Row = 13;
OOPSData.Handles.PolarHistogramBackgroundColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramBackgroundColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.PolarHistogramBackgroundColor},...
    'Value',OOPSData.Settings.PolarHistogramBackgroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@PolarHistogramBackgroundColorChanged});
OOPSData.Handles.PolarHistogramBackgroundColorDropdown.Layout.Row = 13;
OOPSData.Handles.PolarHistogramBackgroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.PolarHistogramBackgroundColorDropdown);

%% CHECKPOINT

disp('Setting up scatterplot settings...')

%% ScatterPlot settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Scatterplot",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.ScatterPlotSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(4).Pane;

set(OOPSData.Handles.ScatterPlotSettingsGrid,...
    'BackgroundColor','Black',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20,20,20,20,20,20,20},...
    'ColumnWidth',{'fit','1x'});

% X-axis variable
OOPSData.Handles.ScatterPlotXVarDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Text','X-axis variable',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ScatterPlotXVarDropdownLabel.Layout.Row = 1;
OOPSData.Handles.ScatterPlotXVarDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotXVarDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Items',OOPSData.Settings.ObjectPlotVariablesLong,...
    'ItemsData',OOPSData.Settings.ObjectPlotVariables,...
    'Value',OOPSData.Settings.ScatterPlotXVariable,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@ScatterPlotVariablesChanged,...
    'Tag','XVariable');
OOPSData.Handles.ScatterPlotXVarDropdown.Layout.Row = 1;
OOPSData.Handles.ScatterPlotXVarDropdown.Layout.Column = 2;

% Y-axis variable
OOPSData.Handles.ScatterPlotYVarDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Text','Y-axis variable',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ScatterPlotYVarDropdownLabel.Layout.Row = 2;
OOPSData.Handles.ScatterPlotYVarDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotYVarDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Items',OOPSData.Settings.ObjectPlotVariablesLong,...
    'ItemsData',OOPSData.Settings.ObjectPlotVariables,...
    'Value',OOPSData.Settings.ScatterPlotYVariable,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@ScatterPlotVariablesChanged,...
    'Tag','YVariable');
OOPSData.Handles.ScatterPlotYVarDropdown.Layout.Row = 2;
OOPSData.Handles.ScatterPlotYVarDropdown.Layout.Column = 2;

% marker size
OOPSData.Handles.ScatterPlotMarkerSizeLabel = uilabel(...
    'Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Text','Marker size',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ScatterPlotMarkerSizeLabel.Layout.Row = 3;
OOPSData.Handles.ScatterPlotMarkerSizeLabel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotMarkerSizeEditfield = uieditfield(...
    OOPSData.Handles.ScatterPlotSettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.ScatterPlotMarkerSize,...
    'Limits',[1 100],...
    'RoundFractionalValues','on',...
    'ValueDisplayFormat','%.0f points',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@ScatterPlotMarkerSizeChanged);
OOPSData.Handles.ScatterPlotMarkerSizeEditfield.Layout.Row = 3;
OOPSData.Handles.ScatterPlotMarkerSizeEditfield.Layout.Column = 2;

% color mode
OOPSData.Handles.ScatterPlotColorModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Text','Color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ScatterPlotColorModeDropdownLabel.Layout.Row = 4;
OOPSData.Handles.ScatterPlotColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotColorModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Items',{'Density','Group','Label'},...
    'ItemsData',{'Density','Group','Label'},...
    'Value',OOPSData.Settings.ScatterPlotColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',{@ScatterPlotColorModeChanged});
OOPSData.Handles.ScatterPlotColorModeDropdown.Layout.Row = 4;
OOPSData.Handles.ScatterPlotColorModeDropdown.Layout.Column = 2;

% marker face alpha
OOPSData.Handles.ScatterPlotMarkerFaceAlphaLabel = uilabel(...
    'Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Text','Marker face alpha',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ScatterPlotMarkerFaceAlphaLabel.Layout.Row = 5;
OOPSData.Handles.ScatterPlotMarkerFaceAlphaLabel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotMarkerFaceAlphaDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Items',{'0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
    'ItemsData',{0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1},...
    'Value',OOPSData.Settings.ScatterPlotMarkerFaceAlpha,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@ScatterPlotMarkerFaceAlphaChanged);
OOPSData.Handles.ScatterPlotMarkerFaceAlphaDropdown.Layout.Row = 5;
OOPSData.Handles.ScatterPlotMarkerFaceAlphaDropdown.Layout.Column = 2;

% background color
OOPSData.Handles.ScatterPlotBackgroundColorDropdownLabel = uilabel('Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Text','Background color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ScatterPlotBackgroundColorDropdownLabel.Layout.Row = 6;
OOPSData.Handles.ScatterPlotBackgroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotBackgroundColorDropdown = uidropdown('Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.ScatterPlotBackgroundColor},...
    'Value',OOPSData.Settings.ScatterPlotBackgroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@ScatterPlotBackgroundColorChanged});
OOPSData.Handles.ScatterPlotBackgroundColorDropdown.Layout.Row = 6;
OOPSData.Handles.ScatterPlotBackgroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.ScatterPlotBackgroundColorDropdown);

% foreground color
OOPSData.Handles.ScatterPlotForegroundColorDropdownLabel = uilabel('Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Text','Foreground color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ScatterPlotForegroundColorDropdownLabel.Layout.Row = 7;
OOPSData.Handles.ScatterPlotForegroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotForegroundColorDropdown = uidropdown('Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.ScatterPlotForegroundColor},...
    'Value',OOPSData.Settings.ScatterPlotForegroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@ScatterPlotForegroundColorChanged});
OOPSData.Handles.ScatterPlotForegroundColorDropdown.Layout.Row = 7;
OOPSData.Handles.ScatterPlotForegroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.ScatterPlotForegroundColorDropdown);

% legend visible
OOPSData.Handles.ScatterPlotLegendVisibleDropdownLabel = uilabel('Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Text','Legend',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ScatterPlotLegendVisibleDropdownLabel.Layout.Row = 8;
OOPSData.Handles.ScatterPlotLegendVisibleDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotLegendVisibleDropdown = uidropdown('Parent',OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Items',{'On','Off'},...
    'ItemsData',{true,false},...
    'Value',OOPSData.Settings.ScatterPlotLegendVisible,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@ScatterPlotLegendVisibleChanged);
OOPSData.Handles.ScatterPlotLegendVisibleDropdown.Layout.Row = 8;
OOPSData.Handles.ScatterPlotLegendVisibleDropdown.Layout.Column = 2;

%% CHECKPOINT

disp('Setting up swarmplot settings...')

%% SwarmPlot settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Swarmplot",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.SwarmPlotSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(5).Pane;

set(OOPSData.Handles.SwarmPlotSettingsGrid,...
    'BackgroundColor','Black',...
    'Scrollable','on',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',repmat({20},18,1),...
    'ColumnWidth',{'fit','1x'});

% variable
OOPSData.Handles.SwarmPlotYVarDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Y-axis variable',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotYVarDropdownLabel.Layout.Row = 1;
OOPSData.Handles.SwarmPlotYVarDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotYVarDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',OOPSData.Settings.ObjectPlotVariablesLong,...
    'ItemsData',OOPSData.Settings.ObjectPlotVariables,...
    'Value',OOPSData.Settings.SwarmPlotYVariable,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotYVariableChanged);
OOPSData.Handles.SwarmPlotYVarDropdown.Layout.Row = 1;
OOPSData.Handles.SwarmPlotYVarDropdown.Layout.Column = 2;

% grouping type
OOPSData.Handles.SwarmPlotGroupingTypeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Grouping type',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotGroupingTypeDropdownLabel.Layout.Row = 2;
OOPSData.Handles.SwarmPlotGroupingTypeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotGroupingTypeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Group','Label','Both'},...
    'ItemsData',{'Group','Label','Both'},...
    'Value',OOPSData.Settings.SwarmPlotGroupingType,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotGroupingTypeChanged);
OOPSData.Handles.SwarmPlotGroupingTypeDropdown.Layout.Row = 2;
OOPSData.Handles.SwarmPlotGroupingTypeDropdown.Layout.Column = 2;

% color mode
OOPSData.Handles.SwarmPlotColorModeDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotColorModeDropdownLabel.Layout.Row = 3;
OOPSData.Handles.SwarmPlotColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotColorModeDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Magnitude','Group','Label'},...
    'ItemsData',{'Magnitude','Group','Label'},...
    'Value',OOPSData.Settings.SwarmPlotColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotColorModeChanged);
OOPSData.Handles.SwarmPlotColorModeDropdown.Layout.Row = 3;
OOPSData.Handles.SwarmPlotColorModeDropdown.Layout.Column = 2;

% background color
OOPSData.Handles.SwarmPlotBackgroundColorDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Background color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotBackgroundColorDropdownLabel.Layout.Row = 4;
OOPSData.Handles.SwarmPlotBackgroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotBackgroundColorDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.SwarmPlotBackgroundColor},...
    'Value',OOPSData.Settings.SwarmPlotBackgroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@SwarmPlotBackgroundColorChanged});
OOPSData.Handles.SwarmPlotBackgroundColorDropdown.Layout.Row = 4;
OOPSData.Handles.SwarmPlotBackgroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.SwarmPlotBackgroundColorDropdown);

% foreground color
OOPSData.Handles.SwarmPlotForegroundColorDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Foreground color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotForegroundColorDropdownLabel.Layout.Row = 5;
OOPSData.Handles.SwarmPlotForegroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotForegroundColorDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.SwarmPlotForegroundColor},...
    'Value',OOPSData.Settings.SwarmPlotForegroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@SwarmPlotForegroundColorChanged});
OOPSData.Handles.SwarmPlotForegroundColorDropdown.Layout.Row = 5;
OOPSData.Handles.SwarmPlotForegroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.SwarmPlotForegroundColorDropdown);

% marker size
OOPSData.Handles.SwarmPlotMarkerSizeLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Marker size',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotMarkerSizeLabel.Layout.Row = 6;
OOPSData.Handles.SwarmPlotMarkerSizeLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotMarkerSizeEditfield = uieditfield(...
    OOPSData.Handles.SwarmPlotSettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.SwarmPlotMarkerSize,...
    'Limits',[1 100],...
    'RoundFractionalValues','on',...
    'ValueDisplayFormat','%.0f points',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotMarkerSizeChanged);
OOPSData.Handles.SwarmPlotMarkerSizeEditfield.Layout.Row = 6;
OOPSData.Handles.SwarmPlotMarkerSizeEditfield.Layout.Column = 2;

% marker face alpha
OOPSData.Handles.SwarmPlotMarkerFaceAlphaLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Marker face alpha',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotMarkerFaceAlphaLabel.Layout.Row = 7;
OOPSData.Handles.SwarmPlotMarkerFaceAlphaLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotMarkerFaceAlphaDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'0','0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
    'ItemsData',{0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1},...
    'Value',OOPSData.Settings.SwarmPlotMarkerFaceAlpha,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotMarkerFaceAlphaChanged);
OOPSData.Handles.SwarmPlotMarkerFaceAlphaDropdown.Layout.Row = 7;
OOPSData.Handles.SwarmPlotMarkerFaceAlphaDropdown.Layout.Column = 2;

% error bars color mode
OOPSData.Handles.SwarmPlotErrorBarsColorModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Error bars color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotErrorBarsColorModeDropdownLabel.Layout.Row = 8;
OOPSData.Handles.SwarmPlotErrorBarsColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotErrorBarsColorModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'auto','Custom'},...
    'Value',OOPSData.Settings.SwarmPlotErrorBarsColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotErrorBarsColorModeChanged,...
    'Tag','ViolinEdgeColorMode');
OOPSData.Handles.SwarmPlotErrorBarsColorModeDropdown.Layout.Row = 8;
OOPSData.Handles.SwarmPlotErrorBarsColorModeDropdown.Layout.Column = 2;

% error bars color
OOPSData.Handles.SwarmPlotErrorBarsColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Error bars color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotErrorBarsColorDropdownLabel.Layout.Row = 9;
OOPSData.Handles.SwarmPlotErrorBarsColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotErrorBarsColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',[colorNames, 'Custom'],...
    'ItemsData',[colorCodesCell, OOPSData.Settings.SwarmPlotErrorBarsColor],...
    'Value',OOPSData.Settings.SwarmPlotErrorBarsColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@SwarmPlotErrorBarsColorChanged});
OOPSData.Handles.SwarmPlotErrorBarsColorDropdown.Layout.Row = 9;
OOPSData.Handles.SwarmPlotErrorBarsColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.SwarmPlotErrorBarsColorDropdown);

% error bars visible
OOPSData.Handles.SwarmPlotErrorBarsVisibleDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Error bars',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotErrorBarsVisibleDropdownLabel.Layout.Row = 10;
OOPSData.Handles.SwarmPlotErrorBarsVisibleDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotErrorBarsVisibleDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'On','Off'},...
    'ItemsData',{true,false},...
    'Value',OOPSData.Settings.SwarmPlotErrorBarsVisible,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotErrorBarsVisibleChanged);
OOPSData.Handles.SwarmPlotErrorBarsVisibleDropdown.Layout.Row = 10;
OOPSData.Handles.SwarmPlotErrorBarsVisibleDropdown.Layout.Column = 2;

% violin edge color mode
OOPSData.Handles.SwarmPlotViolinEdgeColorModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Violin edge color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotViolinEdgeColorModeDropdownLabel.Layout.Row = 11;
OOPSData.Handles.SwarmPlotViolinEdgeColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotViolinEdgeColorModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'auto','Custom'},...
    'Value',OOPSData.Settings.SwarmPlotViolinEdgeColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotViolinEdgeColorModeChanged,...
    'Tag','ViolinEdgeColorMode');
OOPSData.Handles.SwarmPlotViolinEdgeColorModeDropdown.Layout.Row = 11;
OOPSData.Handles.SwarmPlotViolinEdgeColorModeDropdown.Layout.Column = 2;

% violin edge color
OOPSData.Handles.SwarmPlotViolinEdgeColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Violin edge color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotViolinEdgeColorDropdownLabel.Layout.Row = 12;
OOPSData.Handles.SwarmPlotViolinEdgeColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotViolinEdgeColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',[colorNames, 'Custom'],...
    'ItemsData',[colorCodesCell, OOPSData.Settings.SwarmPlotViolinEdgeColor],...
    'Value',OOPSData.Settings.SwarmPlotViolinEdgeColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@SwarmPlotViolinEdgeColorChanged});
OOPSData.Handles.SwarmPlotViolinEdgeColorDropdown.Layout.Row = 12;
OOPSData.Handles.SwarmPlotViolinEdgeColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.SwarmPlotViolinEdgeColorDropdown);


% violin face color mode
OOPSData.Handles.SwarmPlotViolinFaceColorModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Violin face color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotViolinFaceColorModeDropdownLabel.Layout.Row = 13;
OOPSData.Handles.SwarmPlotViolinFaceColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotViolinFaceColorModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'auto','Custom'},...
    'Value',OOPSData.Settings.SwarmPlotViolinFaceColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotViolinFaceColorModeChanged,...
    'Tag','ViolinFaceColorMode');
OOPSData.Handles.SwarmPlotViolinFaceColorModeDropdown.Layout.Row = 13;
OOPSData.Handles.SwarmPlotViolinFaceColorModeDropdown.Layout.Column = 2;

% violin face color
OOPSData.Handles.SwarmPlotViolinFaceColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Violin face color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotViolinFaceColorDropdownLabel.Layout.Row = 14;
OOPSData.Handles.SwarmPlotViolinFaceColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotViolinFaceColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',[colorNames, 'Custom'],...
    'ItemsData',[colorCodesCell, OOPSData.Settings.SwarmPlotViolinFaceColor],...
    'Value',OOPSData.Settings.SwarmPlotViolinFaceColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@SwarmPlotViolinFaceColorChanged});
OOPSData.Handles.SwarmPlotViolinFaceColorDropdown.Layout.Row = 14;
OOPSData.Handles.SwarmPlotViolinFaceColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.SwarmPlotViolinFaceColorDropdown);

% violins visible
OOPSData.Handles.SwarmPlotViolinsVisibleDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Show violin outlines',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotViolinsVisibleDropdownLabel.Layout.Row = 15;
OOPSData.Handles.SwarmPlotViolinsVisibleDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotViolinsVisibleDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'On','Off'},...
    'ItemsData',{true,false},...
    'Value',OOPSData.Settings.SwarmPlotViolinsVisible,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotViolinsVisibleChanged);
OOPSData.Handles.SwarmPlotViolinsVisibleDropdown.Layout.Row = 15;
OOPSData.Handles.SwarmPlotViolinsVisibleDropdown.Layout.Column = 2;

% marker edge color mode
OOPSData.Handles.SwarmPlotMarkerEdgeColorModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Marker edge color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotMarkerEdgeColorModeDropdownLabel.Layout.Row = 16;
OOPSData.Handles.SwarmPlotMarkerEdgeColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotMarkerEdgeColorModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'auto','Custom'},...
    'Value',OOPSData.Settings.SwarmPlotMarkerEdgeColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotMarkerEdgeColorModeChanged,...
    'Tag','MarkerEdgeColorMode');
OOPSData.Handles.SwarmPlotMarkerEdgeColorModeDropdown.Layout.Row = 16;
OOPSData.Handles.SwarmPlotMarkerEdgeColorModeDropdown.Layout.Column = 2;

% marker edge color
OOPSData.Handles.SwarmPlotMarkerEdgeColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Marker edge color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotMarkerEdgeColorDropdownLabel.Layout.Row = 17;
OOPSData.Handles.SwarmPlotMarkerEdgeColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotMarkerEdgeColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',[colorNames, 'Custom'],...
    'ItemsData',[colorCodesCell, OOPSData.Settings.SwarmPlotMarkerEdgeColor],...
    'Value',OOPSData.Settings.SwarmPlotMarkerEdgeColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@SwarmPlotMarkerEdgeColorChanged});
OOPSData.Handles.SwarmPlotMarkerEdgeColorDropdown.Layout.Row = 17;
OOPSData.Handles.SwarmPlotMarkerEdgeColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.SwarmPlotMarkerEdgeColorDropdown);

% points visible
OOPSData.Handles.SwarmPlotPointsVisibleDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Show all points',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotPointsVisibleDropdownLabel.Layout.Row = 18;
OOPSData.Handles.SwarmPlotPointsVisibleDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotPointsVisibleDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'On','Off'},...
    'ItemsData',{true,false},...
    'Value',OOPSData.Settings.SwarmPlotPointsVisible,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotPointsVisibleChanged);
OOPSData.Handles.SwarmPlotPointsVisibleDropdown.Layout.Row = 18;
OOPSData.Handles.SwarmPlotPointsVisibleDropdown.Layout.Column = 2;

% x jitter width
OOPSData.Handles.SwarmPlotXJitterWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','X jitter width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotXJitterWidthLabel.Layout.Row = 19;
OOPSData.Handles.SwarmPlotXJitterWidthLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotXJitterWidthEditfield = uieditfield(...
    'numeric',...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Value',OOPSData.Settings.SwarmPlotXJitterWidth,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','XJitterWidth',...
    'ValueChangedFcn',@SwarmPlotXJitterWidthChanged);
OOPSData.Handles.SwarmPlotXJitterWidthEditfield.Layout.Row = 19;
OOPSData.Handles.SwarmPlotXJitterWidthEditfield.Layout.Column = 2;

%% CHECKPOINT

disp('Setting up label settings...')

%% Label settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Labels",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.LabelSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(6).Pane;

set(OOPSData.Handles.LabelSettingsGrid,...
    'BackgroundColor','Black',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{'1x'},...
    'ColumnWidth',{'1x'});

% setting up x-axis variable selection
OOPSData.Handles.LabelListBoxPanel = uipanel(OOPSData.Handles.LabelSettingsGrid,...
    'Title','Object labels');
OOPSData.Handles.LabelListBoxPanel.Layout.Row = 1;
OOPSData.Handles.LabelListBoxPanel.Layout.Column = 1;

OOPSData.Handles.LabelGrid = uigridlayout(OOPSData.Handles.LabelListBoxPanel,[1,1]);
OOPSData.Handles.LabelGrid.Padding = [0 0 0 0];

OOPSData.Handles.LabelTree = uitree(OOPSData.Handles.LabelGrid,...
    'NodeTextChangedFcn',@LabelTreeNodeTextChanged,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','bold',...
    'Interruptible','off',...
    'Editable','on',...
    'Multiselect','On');

% context menu for individual labels
OOPSData.Handles.LabelContextMenu = uicontextmenu(OOPSData.Handles.fH);
OOPSData.Handles.LabelContextMenu_ApplyLabelToSelectedObjects = uimenu(OOPSData.Handles.LabelContextMenu,'Text','Apply label to selected objects','MenuSelectedFcn',{@ApplyLabelToSelectedObjects,OOPSData.Handles.fH});
OOPSData.Handles.LabelContextMenu_SelectLabeledObjects = uimenu(OOPSData.Handles.LabelContextMenu,'Text','Select objects with selected label(s)','MenuSelectedFcn',{@SelectLabeledObjects,OOPSData.Handles.fH});
OOPSData.Handles.LabelContextMenu_Delete = uimenu(OOPSData.Handles.LabelContextMenu,'Text','Delete label(s)','MenuSelectedFcn',{@DeleteLabel,OOPSData.Handles.fH});
OOPSData.Handles.LabelContextMenu_DeleteLabelAndObjects = uimenu(OOPSData.Handles.LabelContextMenu,'Text','Delete label(s) and objects','MenuSelectedFcn',{@DeleteLabelAndObjects,OOPSData.Handles.fH});
OOPSData.Handles.LabelContextMenu_ChangeColor = uimenu(OOPSData.Handles.LabelContextMenu,'Text','Change label color','MenuSelectedFcn',{@EditLabelColor,OOPSData.Handles.fH});
OOPSData.Handles.LabelContextMenu_MergeLabels = uimenu(OOPSData.Handles.LabelContextMenu,'Text','Merge selected labels','MenuSelectedFcn',{@MergeLabels,OOPSData.Handles.fH});
OOPSData.Handles.LabelContextMenu_AddNewLabel = uimenu(OOPSData.Handles.LabelContextMenu,'Text','New label','MenuSelectedFcn',@AddNewLabel);

defaultLabelTreeNode = uitreenode(OOPSData.Handles.LabelTree,...
    'Text',OOPSData.Settings.ObjectLabels(1).Name,...
    'NodeData',OOPSData.Settings.ObjectLabels(1),...
    'ContextMenu',OOPSData.Handles.LabelContextMenu,...
    'Icon',makeRGBColorSquare(OOPSData.Settings.ObjectLabels(1).Color,5));

%% CHECKPOINT

disp('Setting up display limits settings...')

%% Intensity display limits

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Display limits",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.IntensityDisplayLimitsSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(7).Pane;

set(OOPSData.Handles.IntensityDisplayLimitsSettingsGrid,...
    'BackgroundColor','Black',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',0,...
    'RowHeight',repmat({'1x'},1,3+numel(OOPSData.Settings.CustomStatistics)),...
    'ColumnWidth',{'1x'});

OOPSData.Handles.PrimaryIntensitySlider = RangeSlider(...
    'Parent',OOPSData.Handles.IntensityDisplayLimitsSettingsGrid,...
    'Visible','On',...
    'Limits',[0 1],...
    'Value',[0 1],...
    'Knob1Color',[1 1 1],...
    'Knob1EdgeColor',[0 0 0],...
    'Knob2Color',[1 1 1],...
    'Knob2EdgeColor',[0 0 0],...
    'RangeColor',[1 1 1],...
    'MidLineColor','#A9A9A9',...
    'Title','Primary channel intensity',...
    'TitleColor',[1 1 1],...
    'BackgroundColor','Black',...
    'LabelColor','White',...
    'LabelBGColor','none',...
    'TickColor','White');
OOPSData.Handles.PrimaryIntensitySlider.Layout.Row = 1;
OOPSData.Handles.PrimaryIntensitySlider.ValueChangedFcn = @AdjustPrimaryChannelIntensity;

OOPSData.Handles.ReferenceIntensitySlider = RangeSlider(...
    'Parent',OOPSData.Handles.IntensityDisplayLimitsSettingsGrid,...
    'Visible','On',...
    'Limits',[0 1],...
    'Value',[0 1],...
    'Knob1Color',[1 1 1],...
    'Knob1EdgeColor',[0 0 0],...
    'Knob2Color',[1 1 1],...
    'Knob2EdgeColor',[0 0 0],...
    'RangeColor',[1 1 1],...
    'MidLineColor','#A9A9A9',...
    'Title','Reference channel intensity',...
    'TitleColor',[1 1 1],...
    'BackgroundColor','Black',...
    'LabelColor','White',...
    'LabelBGColor','none',...
    'TickColor','White');
OOPSData.Handles.ReferenceIntensitySlider.Layout.Row = 2;
OOPSData.Handles.ReferenceIntensitySlider.ValueChangedFcn = @AdjustReferenceChannelIntensity;

OOPSData.Handles.OrderSlider = RangeSlider(...
    'Parent',OOPSData.Handles.IntensityDisplayLimitsSettingsGrid,...
    'Visible','On',...
    'Limits',[0 1],...
    'Value',[0 1],...
    'Knob1Color',[1 1 1],...
    'Knob1EdgeColor',[0 0 0],...
    'Knob2Color',[1 1 1],...
    'Knob2EdgeColor',[0 0 0],...
    'RangeColor',[1 1 1],...
    'MidLineColor','#A9A9A9',...
    'Title','Order',...
    'TitleColor',[1 1 1],...
    'BackgroundColor','Black',...
    'LabelColor','White',...
    'LabelBGColor','none',...
    'TickColor','White');
OOPSData.Handles.OrderSlider.Layout.Row = 3;
OOPSData.Handles.OrderSlider.ValueChangedFcn = @AdjustOrderDisplayLimits;

% add a slider for each custom statistic
for i = 1:numel(OOPSData.Settings.CustomStatistics)
    % get the next statistic
    thisStatistic = OOPSData.Settings.CustomStatistics(i);
    % the relevant properties of the statistic
    statName = thisStatistic.StatisticName;
    statDisplayName = thisStatistic.StatisticDisplayName;
    statRange = thisStatistic.StatisticRange;
    % create the slider
    OOPSData.Handles.([statName,'Slider']) = RangeSlider(...
        'Parent',OOPSData.Handles.IntensityDisplayLimitsSettingsGrid,...
        'Visible','On',...
        'Limits',statRange,...
        'Value',statRange,...
        'Knob1Color',[1 1 1],...
        'Knob1EdgeColor',[0 0 0],...
        'Knob2Color',[1 1 1],...
        'Knob2EdgeColor',[0 0 0],...
        'RangeColor',[1 1 1],...
        'MidLineColor','#A9A9A9',...
        'Title',statDisplayName,...
        'TitleColor',[1 1 1],...
        'BackgroundColor','Black',...
        'LabelColor','White',...
        'LabelBGColor','none',...
        'TickColor','White',...
        'Tag',statName);
    OOPSData.Handles.([statName,'Slider']).Layout.Row = i+3;
    OOPSData.Handles.([statName,'Slider']).ValueChangedFcn = @AdjustCustomDisplayLimits;
end

%% CHECKPOINT

disp('Setting up palettes settings...')

%% Palettes settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Palettes",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

PaletteNames = fieldnames(OOPSData.Settings.Palettes);
PaletteTypeFields = fieldnames(OOPSData.Settings.PalettesSettings);
nPaletteTypes = length(PaletteTypeFields);
PaletteTypeFullNames = PaletteTypeFields;
PaletteTypePaletteNames = cell(nPaletteTypes,1);
PaletteTypePalettes = cell(nPaletteTypes,1);
for k = 1:nPaletteTypes
    PaletteTypePaletteNames{k,1} = OOPSData.Settings.PalettesSettings.(PaletteTypeFields{k}).Name;
    PaletteTypePalettes{k,1} = OOPSData.Settings.PalettesSettings.(PaletteTypeFields{k}).Colors;
end

% get the pane of the palette settings accordion item
OOPSData.Handles.PalettesSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(8).Pane;

set(OOPSData.Handles.PalettesSettingsGrid,...
    'BackgroundColor','Black',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    "RowHeight",{20,30,'1x'},...
    "ColumnWidth",{'fit','1x'});

% palette type 
OOPSData.Handles.PalettesTypeLabel = uilabel(...
    'Parent',OOPSData.Handles.PalettesSettingsGrid,...
    'Text','Palette type',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PalettesTypeLabel.Layout.Row = 1;
OOPSData.Handles.PalettesTypeLabel.Layout.Column = 1;

OOPSData.Handles.PalettesTypeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PalettesSettingsGrid,...
    'Items',PaletteTypeFullNames,...
    'ItemsData',PaletteTypeFields,...
    'Value',PaletteTypeFields{1},...
    'Tag','PaletteTypeSelectBox',...
    'ValueChangedFcn',@PaletteTypeSelectionChanged,...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.PalettesTypeDropdown.Layout.Row = 1;
OOPSData.Handles.PalettesTypeDropdown.Layout.Column = 2;

% panel to hold example palette axes
OOPSData.Handles.ExamplePalettePanel = uipanel(OOPSData.Handles.PalettesSettingsGrid);
OOPSData.Handles.ExamplePalettePanel.Layout.Row = 2;
OOPSData.Handles.ExamplePalettePanel.Layout.Column = [1 2];

% axes to hold example palette
OOPSData.Handles.ExamplePaletteAx = uiaxes(OOPSData.Handles.ExamplePalettePanel,...
    'Visible','Off',...
    'XTick',[],...
    'YTick',[],...
    'Units','Normalized',...
    'InnerPosition',[0 0 1 1]);
OOPSData.Handles.ExamplePaletteAx.Toolbar.Visible = 'Off';
disableDefaultInteractivity(OOPSData.Handles.ExamplePaletteAx);

% create image to show example colorbar for palette switching
OOPSData.Handles.ExamplePalette = image(OOPSData.Handles.ExamplePaletteAx,...
    'CData',repmat(1:256,50,1),...
    'CDataMapping','scaled');

% set display limits to show full palette without extra borders
OOPSData.Handles.ExamplePaletteAx.YLim = [0.5 50.5];
OOPSData.Handles.ExamplePaletteAx.XLim = [0.5 256.5];
% set the colormap of the axes holding our example palette image
OOPSData.Handles.ExamplePaletteAx.Colormap = OOPSData.Settings.PalettesSettings.(PaletteTypeFields{1}).Colors;  

% palette selector
OOPSData.Handles.PalettesPanel = uipanel(OOPSData.Handles.PalettesSettingsGrid,...
    'Title','Palettes',...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.PalettesPanel.Layout.Row = 3;
OOPSData.Handles.PalettesPanel.Layout.Column = [1 2];

OOPSData.Handles.PalettesPanelGrid = uigridlayout(OOPSData.Handles.PalettesPanel,...
    [1,1],...
    "RowHeight",{200},...
    "Padding",[0 0 0 0]);

OOPSData.Handles.PalettesSelector = uilistbox(OOPSData.Handles.PalettesPanelGrid,...
    'Items',PaletteNames,...
    'Value',OOPSData.Settings.PalettesSettings.(PaletteTypeFields{1}).Name,...
    'Tag','PaletteSelectBox',...
    'ValueChangedFcn',@PaletteSelectionChanged,...
    'FontName',OOPSData.Settings.DefaultFont);

%% CHECKPOINT

disp('Setting up object intensity profile settings...')

%% Object intensity profile settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Object intensity profile",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.ObjectIntensityProfileSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(9).Pane;

set(OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'BackgroundColor','Black',...
    'Scrollable','on',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20,20,20,20,20},...
    'ColumnWidth',{'fit','1x'});

% background color
OOPSData.Handles.ObjectIntensityProfileBackgroundColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Text','Background color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectIntensityProfileBackgroundColorDropdownLabel.Layout.Row = 1;
OOPSData.Handles.ObjectIntensityProfileBackgroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectIntensityProfileBackgroundColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.ObjectIntensityProfileBackgroundColor},...
    'Value',OOPSData.Settings.ObjectIntensityProfileBackgroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@ObjectIntensityProfileBackgroundColorChanged});
OOPSData.Handles.ObjectIntensityProfileBackgroundColorDropdown.Layout.Row = 1;
OOPSData.Handles.ObjectIntensityProfileBackgroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.ObjectIntensityProfileBackgroundColorDropdown);

% foreground color
OOPSData.Handles.ObjectIntensityProfileForegroundColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Text','Foreground color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectIntensityProfileForegroundColorDropdownLabel.Layout.Row = 2;
OOPSData.Handles.ObjectIntensityProfileForegroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectIntensityProfileForegroundColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.ObjectIntensityProfileForegroundColor},...
    'Value',OOPSData.Settings.ObjectIntensityProfileForegroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@ObjectIntensityProfileForegroundColorChanged});
OOPSData.Handles.ObjectIntensityProfileForegroundColorDropdown.Layout.Row = 2;
OOPSData.Handles.ObjectIntensityProfileForegroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.ObjectIntensityProfileForegroundColorDropdown);

% fit line color
OOPSData.Handles.ObjectIntensityProfileFitLineColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Text','Fit line color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectIntensityProfileFitLineColorDropdownLabel.Layout.Row = 3;
OOPSData.Handles.ObjectIntensityProfileFitLineColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectIntensityProfileFitLineColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.ObjectIntensityProfileFitLineColor},...
    'Value',OOPSData.Settings.ObjectIntensityProfileFitLineColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@ObjectIntensityProfileFitLineColorChanged});
OOPSData.Handles.ObjectIntensityProfileFitLineColorDropdown.Layout.Row = 3;
OOPSData.Handles.ObjectIntensityProfileFitLineColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.ObjectIntensityProfileFitLineColorDropdown);

% pixel lines color
OOPSData.Handles.ObjectIntensityProfilePixelLinesColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Text','Pixel lines color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectIntensityProfilePixelLinesColorDropdownLabel.Layout.Row = 4;
OOPSData.Handles.ObjectIntensityProfilePixelLinesColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectIntensityProfilePixelLinesColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.ObjectIntensityProfilePixelLinesColor},...
    'Value',OOPSData.Settings.ObjectIntensityProfilePixelLinesColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@ObjectIntensityProfilePixelLinesColorChanged});
OOPSData.Handles.ObjectIntensityProfilePixelLinesColorDropdown.Layout.Row = 4;
OOPSData.Handles.ObjectIntensityProfilePixelLinesColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.ObjectIntensityProfilePixelLinesColorDropdown);

% annotation lines color
OOPSData.Handles.ObjectIntensityProfileAnnotationsColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Text','Annotations color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectIntensityProfileAnnotationsColorDropdownLabel.Layout.Row = 5;
OOPSData.Handles.ObjectIntensityProfileAnnotationsColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectIntensityProfileAnnotationsColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.ObjectIntensityProfileAnnotationsColor},...
    'Value',OOPSData.Settings.ObjectIntensityProfileAnnotationsColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@ObjectIntensityProfileAnnotationsColorChanged});
OOPSData.Handles.ObjectIntensityProfileAnnotationsColorDropdown.Layout.Row = 5;
OOPSData.Handles.ObjectIntensityProfileAnnotationsColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.ObjectIntensityProfileAnnotationsColorDropdown);

% annotation lines color
OOPSData.Handles.ObjectIntensityProfileAzimuthLinesColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Text','Azimuth lines color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectIntensityProfileAzimuthLinesColorDropdownLabel.Layout.Row = 6;
OOPSData.Handles.ObjectIntensityProfileAzimuthLinesColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectIntensityProfileAzimuthLinesColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectIntensityProfileSettingsGrid,...
    'Items',{'Black','White','Custom'},...
    'ItemsData',{[0 0 0],[1 1 1],OOPSData.Settings.ObjectIntensityProfileAzimuthLinesColor},...
    'Value',OOPSData.Settings.ObjectIntensityProfileAzimuthLinesColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@ObjectIntensityProfileAzimuthLinesColorChanged});
OOPSData.Handles.ObjectIntensityProfileAzimuthLinesColorDropdown.Layout.Row = 6;
OOPSData.Handles.ObjectIntensityProfileAzimuthLinesColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.ObjectIntensityProfileAzimuthLinesColorDropdown);

%% CHECKPOINT

disp('Setting up object azimuth settings...')

%% Object azimuth lines

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Object azimuth display",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid = OOPSData.Handles.SettingsAccordion.Items(10).Pane;

set(OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'BackgroundColor','Black',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20,20,20,20},...
    'ColumnWidth',{'fit','1x'});

OOPSData.Handles.ObjectAzimuthLineAlphaLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Text','Line alpha',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectAzimuthLineAlphaLabel.Layout.Row = 1;
OOPSData.Handles.ObjectAzimuthLineAlphaLabel.Layout.Column = 1;

OOPSData.Handles.ObjectAzimuthLineAlphaDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Items',{'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
    'ItemsData',{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1},...
    'Value',OOPSData.Settings.ObjectAzimuthLineAlpha,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','LineAlpha',...
    'ValueChangedFcn',@ObjectAzimuthDisplaySettingsChanged);
OOPSData.Handles.ObjectAzimuthLineAlphaDropdown.Layout.Row = 1;
OOPSData.Handles.ObjectAzimuthLineAlphaDropdown.Layout.Column = 2;

OOPSData.Handles.ObjectAzimuthLineWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Text','Line width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectAzimuthLineWidthLabel.Layout.Row = 2;
OOPSData.Handles.ObjectAzimuthLineWidthLabel.Layout.Column = 1;

OOPSData.Handles.ObjectAzimuthLineWidthDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Items',{'1','2','3','4','5','6','7','8','9','10'},...
    'ItemsData',{1,2,3,4,5,6,7,8,9,10},...
    'Value',OOPSData.Settings.ObjectAzimuthLineWidth,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','LineWidth',...
    'ValueChangedFcn',@ObjectAzimuthDisplaySettingsChanged);
OOPSData.Handles.ObjectAzimuthLineWidthDropdown.Layout.Row = 2;
OOPSData.Handles.ObjectAzimuthLineWidthDropdown.Layout.Column = 2;

OOPSData.Handles.ObjectAzimuthLineScaleLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Text','Line scale factor',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectAzimuthLineScaleLabel.Layout.Row = 3;
OOPSData.Handles.ObjectAzimuthLineScaleLabel.Layout.Column = 1;

OOPSData.Handles.ObjectAzimuthLineScaleEditfield = uieditfield(...
    'numeric',...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Value',OOPSData.Settings.ObjectAzimuthLineScale,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','LineScale',...
    'ValueChangedFcn',@ObjectAzimuthDisplaySettingsChanged);
OOPSData.Handles.ObjectAzimuthLineScaleEditfield.Layout.Row = 3;
OOPSData.Handles.ObjectAzimuthLineScaleEditfield.Layout.Column = 2;

OOPSData.Handles.ObjectAzimuthLineScaleDownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Text','Number of lines to show',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectAzimuthLineScaleDownLabel.Layout.Row = 4;
OOPSData.Handles.ObjectAzimuthLineScaleDownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectAzimuthLineScaleDownDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Items',{'All','Half','Quarter'},...
    'ItemsData',{1,2,4},...
    'Value',OOPSData.Settings.ObjectAzimuthScaleDownFactor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','ScaleDownFactor',...
    'ValueChangedFcn',@ObjectAzimuthDisplaySettingsChanged);
OOPSData.Handles.ObjectAzimuthLineScaleDownDropdown.Layout.Row = 4;
OOPSData.Handles.ObjectAzimuthLineScaleDownDropdown.Layout.Column = 2;
OOPSData.Handles.ObjectAzimuthLineScaleDownDropdown.ItemsData = [1 2 4];

OOPSData.Handles.ObjectAzimuthColorModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Text','Line color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectAzimuthColorModeDropdownLabel.Layout.Row = 5;
OOPSData.Handles.ObjectAzimuthColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectAzimuthColorModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectAzimuthDisplaySettingsGrid,...
    'Items',{'Direction','RelativeDirection','Magnitude','Mono'},...
    'Value',OOPSData.Settings.ObjectAzimuthColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','ColorMode',...
    'ValueChangedFcn',@ObjectAzimuthDisplaySettingsChanged);
OOPSData.Handles.ObjectAzimuthColorModeDropdown.Layout.Row = 5;
OOPSData.Handles.ObjectAzimuthColorModeDropdown.Layout.Column = 2;

%% CHECKPOINT

disp('Setting up object selection settings...')

%% Object selection settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Object selection",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor" ,OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.ObjectSelectionSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(11).Pane;

set(OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'BackgroundColor','Black',...
    'Scrollable','on',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20,20,20,20},...
    'ColumnWidth',{'fit','1x'});

% box type
OOPSData.Handles.ObjectSelectionBoxTypeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'Text','Box type',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectSelectionBoxTypeDropdownLabel.Layout.Row = 1;
OOPSData.Handles.ObjectSelectionBoxTypeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectSelectionBoxTypeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'Items',{'Box','Boundary'},...
    'Value',OOPSData.Settings.ObjectSelectionBoxType,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@ObjectSelectionSettingsChanged,...
    'Tag','BoxType');
OOPSData.Handles.ObjectSelectionBoxTypeDropdown.Layout.Row = 1;
OOPSData.Handles.ObjectSelectionBoxTypeDropdown.Layout.Column = 2;

% color mode
OOPSData.Handles.ObjectSelectionColorModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'Text','Color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectSelectionColorModeDropdownLabel.Layout.Row = 2;
OOPSData.Handles.ObjectSelectionColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectSelectionColorModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'Items',{'Label','Custom'},...
    'Value',OOPSData.Settings.ObjectSelectionColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@ObjectSelectionSettingsChanged,...
    'Tag','ColorMode');
OOPSData.Handles.ObjectSelectionColorModeDropdown.Layout.Row = 2;
OOPSData.Handles.ObjectSelectionColorModeDropdown.Layout.Column = 2;

OOPSData.Handles.ObjectSelectionColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'Text','Color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectSelectionColorDropdownLabel.Layout.Row = 3;
OOPSData.Handles.ObjectSelectionColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ObjectSelectionColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'Items',[colorNames, 'Custom'],...
    'ItemsData',[colorCodesCell, OOPSData.Settings.ObjectSelectionColor],...
    'Value',OOPSData.Settings.ObjectSelectionColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@ObjectSelectionColorChanged});
OOPSData.Handles.ObjectSelectionColorDropdown.Layout.Row = 3;
OOPSData.Handles.ObjectSelectionColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.ObjectSelectionColorDropdown);

% line width
OOPSData.Handles.ObjectSelectionLineWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'Text','Line width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectSelectionLineWidthLabel.Layout.Row = 4;
OOPSData.Handles.ObjectSelectionLineWidthLabel.Layout.Column = 1;

OOPSData.Handles.ObjectSelectionLineWidthEditfield = uieditfield(...
    OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.ObjectSelectionLineWidth,...
    'Limits',[1 5],...
    'RoundFractionalValues','on',...
    'ValueDisplayFormat','%.0f points',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@ObjectSelectionSettingsChanged,...
    'Tag','LineWidth');
OOPSData.Handles.ObjectSelectionLineWidthEditfield.Layout.Row = 4;
OOPSData.Handles.ObjectSelectionLineWidthEditfield.Layout.Column = 2;

% selected line width
OOPSData.Handles.ObjectSelectionSelectedLineWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'Text','Line width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.ObjectSelectionSelectedLineWidthLabel.Layout.Row = 5;
OOPSData.Handles.ObjectSelectionSelectedLineWidthLabel.Layout.Column = 1;

OOPSData.Handles.ObjectSelectionSelectedLineWidthEditfield = uieditfield(...
    OOPSData.Handles.ObjectSelectionSettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.ObjectSelectionSelectedLineWidth,...
    'Limits',[1 5],...
    'RoundFractionalValues','on',...
    'ValueDisplayFormat','%.0f points',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@ObjectSelectionSettingsChanged,...
    'Tag','SelectedLineWidth');
OOPSData.Handles.ObjectSelectionSelectedLineWidthEditfield.Layout.Row = 5;
OOPSData.Handles.ObjectSelectionSelectedLineWidthEditfield.Layout.Column = 2;


% % draw the current figure to update final container sizes

% testing without this drawnow command
drawnow
pause(0.5)


%% CHECKPOINT

disp('Setting up cluster settings...')

%% k-means clustering settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","k-means clustering",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor",OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.ClusterSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(12).Pane;

set(OOPSData.Handles.ClusterSettingsGrid,...
    'BackgroundColor','Black',...
    'Scrollable','on',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{'1x',20,20,20,20,20,20},...
    'ColumnWidth',{'fit','1x'});

% setting up cluster variable(s) selection
OOPSData.Handles.ClusterVariablesTreePanel = uipanel(OOPSData.Handles.ClusterSettingsGrid,...
    'Title','Variables');
OOPSData.Handles.ClusterVariablesTreePanel.Layout.Row = 1;
OOPSData.Handles.ClusterVariablesTreePanel.Layout.Column = [1 2];
% grid to hold the selection uitree
OOPSData.Handles.ClusterVariablesTreeGrid = uigridlayout(OOPSData.Handles.ClusterVariablesTreePanel, ...
    [1,1], ...
    'Padding',[0 0 0 0]);
% uitree checkbox to select variables
OOPSData.Handles.ClusterVariablesTree = uitree(...
    OOPSData.Handles.ClusterVariablesTreeGrid,...
    'checkbox',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','bold',...
    'Interruptible','off',...
    'CheckedNodesChangedFcn',@ClusterVariablesChanged,...
    'BackgroundColor',OOPSData.Settings.GUIBackgroundColor,...
    'FontColor',OOPSData.Settings.GUIForegroundColor);
% add nodes for each variable
varListShort = OOPSData.Settings.ObjectPlotVariables;
varListLong = OOPSData.Settings.ObjectPlotVariablesLong;
for varIdx = 1:numel(varListShort)
    uitreenode(OOPSData.Handles.ClusterVariablesTree,...
        'Text',varListLong{varIdx},...
        'NodeData',varListShort{varIdx});
end
% determine which variables to select by default based on existing settings
varSelectionIdx = find(ismember(varListShort,OOPSData.Settings.ClusterVariableList));
if isempty(varSelectionIdx)
    OOPSData.Handles.ClusterVariablesTree.CheckedNodes = [];
else
    % select the corresponding nodes
    OOPSData.Handles.ClusterVariablesTree.CheckedNodes = ...
        OOPSData.Handles.ClusterVariablesTree.Children(varSelectionIdx);
end

% k selection mode
OOPSData.Handles.ClusternClustersModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.ClusterSettingsGrid,...
    'Text','k selection mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor',[1 1 1]);
OOPSData.Handles.ClusternClustersModeDropdownLabel.Layout.Row = 2;
OOPSData.Handles.ClusternClustersModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ClusternClustersModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.ClusterSettingsGrid,...
    'Items',{'Auto','Manual'},...
    'Value',OOPSData.Settings.ClusternClustersMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','nClustersMode',...
    'ValueChangedFcn',@ClusterSettingsChanged);
OOPSData.Handles.ClusternClustersModeDropdown.Layout.Row = 2;
OOPSData.Handles.ClusternClustersModeDropdown.Layout.Column = 2;

% k
OOPSData.Handles.ClusternClustersLabel = uilabel(...
    'Parent',OOPSData.Handles.ClusterSettingsGrid,...
    'Text','k',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor',[1 1 1]);
OOPSData.Handles.ClusternClustersLabel.Layout.Row = 3;
OOPSData.Handles.ClusternClustersLabel.Layout.Column = 1;

OOPSData.Handles.ClusternClustersEditfield = uieditfield(...
    OOPSData.Handles.ClusterSettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.ClusternClusters,...
    'Limits',[2 15],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Enable',strcmp(OOPSData.Settings.ClusternClustersMode,'Manual'),...
    'Tag','nClusters',...
    'ValueChangedFcn',@ClusterSettingsChanged);
OOPSData.Handles.ClusternClustersEditfield.Layout.Row = 3;
OOPSData.Handles.ClusternClustersEditfield.Layout.Column = 2;

% auto k selection criterion
OOPSData.Handles.ClusterCriterionDropdownLabel = uilabel(...
    "Parent",OOPSData.Handles.ClusterSettingsGrid,...
    "Text","Criterion",...
    "FontColor",[1 1 1]);
OOPSData.Handles.ClusterCriterionDropdownLabel.Layout.Row = 4;
OOPSData.Handles.ClusterCriterionDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ClusterCriterionDropdown = uidropdown(...
    "Parent",OOPSData.Handles.ClusterSettingsGrid,...
    "Items",{'CalinskiHarabasz','DaviesBouldin','silhouette'},...
    "Value",OOPSData.Settings.ClusterCriterion,...
    "Enable",strcmp(OOPSData.Settings.ClusternClustersMode,'Auto'),...
    "Tag",'Criterion',...
    "ValueChangedFcn",@ClusterSettingsChanged);
OOPSData.Handles.ClusterCriterionDropdown.Layout.Row = 4;
OOPSData.Handles.ClusterCriterionDropdown.Layout.Column = 2;

% distance metric
OOPSData.Handles.ClusterDistanceMetricDropdownLabel = uilabel(...
    "Parent",OOPSData.Handles.ClusterSettingsGrid,...
    "Text","Distance metric",...
    "FontColor",[1 1 1]);
OOPSData.Handles.ClusterDistanceMetricDropdownLabel.Layout.Row = 5;
OOPSData.Handles.ClusterDistanceMetricDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ClusterDistanceMetricDropdown = uidropdown(...
    "Parent",OOPSData.Handles.ClusterSettingsGrid,...
    "Items",{'sqeuclidean','cosine','cityblock'},...
    "Value",OOPSData.Settings.ClusterDistanceMetric,...
    "Tag",'DistanceMetric',...
    "ValueChangedFcn",@ClusterSettingsChanged);
OOPSData.Handles.ClusterDistanceMetricDropdown.Layout.Row = 5;
OOPSData.Handles.ClusterDistanceMetricDropdown.Layout.Column = 2;

% normalization
OOPSData.Handles.ClusterNormalizationMethodDropdownLabel = uilabel(...
    "Parent",OOPSData.Handles.ClusterSettingsGrid,...
    "Text","Normalization",...
    "FontColor",[1 1 1]);
OOPSData.Handles.ClusterNormalizationMethodDropdownLabel.Layout.Row = 6;
OOPSData.Handles.ClusterNormalizationMethodDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ClusterNormalizationMethodDropdown = uidropdown(...
    "Parent",OOPSData.Handles.ClusterSettingsGrid,...
    "Items",{'zscore','none'},...
    "Value",OOPSData.Settings.ClusterNormalizationMethod,...
    "Tag",'NormalizationMethod',...
    "ValueChangedFcn",@ClusterSettingsChanged);
OOPSData.Handles.ClusterNormalizationMethodDropdown.Layout.Row = 6;
OOPSData.Handles.ClusterNormalizationMethodDropdown.Layout.Column = 2;

% display evaluation
OOPSData.Handles.ClusterDisplayEvaluationDropdownLabel = uilabel(...
    "Parent",OOPSData.Handles.ClusterSettingsGrid,...
    "Text","Display evaluation",...
    "FontColor",[1 1 1]);
OOPSData.Handles.ClusterDisplayEvaluationDropdownLabel.Layout.Row = 7;
OOPSData.Handles.ClusterDisplayEvaluationDropdownLabel.Layout.Column = 1;

OOPSData.Handles.ClusterDisplayEvaluationDropdown = uidropdown(...
    "Parent",OOPSData.Handles.ClusterSettingsGrid,...
    "Items",{'yes','no'},...
    "ItemsData",{true,false},...
    "Value",OOPSData.Settings.ClusterDisplayEvaluation,...
    "Tag",'DisplayEvaluation',...
    "ValueChangedFcn",@ClusterSettingsChanged);
OOPSData.Handles.ClusterDisplayEvaluationDropdown.Layout.Row = 7;
OOPSData.Handles.ClusterDisplayEvaluationDropdown.Layout.Column = 2;

%% CHECKPOINT

disp('Setting up mask settings...')

%% Mask settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","Mask",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor",OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.MaskSettingsGrid = OOPSData.Handles.SettingsAccordion.Items(13).Pane;

set(OOPSData.Handles.MaskSettingsGrid,...
    'BackgroundColor','Black',...
    'Scrollable','on',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20},...
    'ColumnWidth',{'fit','1x'});

% mask type
OOPSData.Handles.MaskTypeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.MaskSettingsGrid,...
    'Text','Mask type',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor',[1 1 1]);
OOPSData.Handles.MaskTypeDropdownLabel.Layout.Row = 1;
OOPSData.Handles.MaskTypeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.MaskTypeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.MaskSettingsGrid,...
    'Items',{'Default','Custom'},...
    'ItemsData',{'Default','CustomScheme'},...
    'Value',OOPSData.Settings.MaskType,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','MaskType',...
    'ValueChangedFcn',@MaskTypeChanged);
OOPSData.Handles.MaskTypeDropdown.Layout.Row = 1;
OOPSData.Handles.MaskTypeDropdown.Layout.Column = 2;

% mask name
OOPSData.Handles.MaskNameDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.MaskSettingsGrid,...
    'Text','Mask type',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor',[1 1 1]);
OOPSData.Handles.MaskNameDropdownLabel.Layout.Row = 2;
OOPSData.Handles.MaskNameDropdownLabel.Layout.Column = 1;

% get cell array of mask names based on mask type
switch OOPSData.Settings.MaskType
    case 'Default'
        maskNames = {'Legacy','Filament','Adaptive'};
    case 'CustomScheme'
        maskNames = {OOPSData.Settings.SchemeNames};
end

OOPSData.Handles.MaskNameDropdown = uidropdown(...
    'Parent',OOPSData.Handles.MaskSettingsGrid,...
    'Items',maskNames,...
    'Value',OOPSData.Settings.MaskName,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Tag','MaskName',...
    'ValueChangedFcn',@MaskNameChanged);
OOPSData.Handles.MaskNameDropdown.Layout.Row = 2;
OOPSData.Handles.MaskNameDropdown.Layout.Column = 2;

%% CHECKPOINT

disp('Setting up GUI display settings...')

%% GUI settings

OOPSData.Handles.SettingsAccordion.addItem(...
    "Title","GUI",...
    "PaneBackgroundColor",[0 0 0],...
    "FontName",OOPSData.Settings.DefaultFont,...
    "FontColor",OOPSData.Settings.GUIForegroundColor,...
    "TitleBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "PaneBackgroundColor",OOPSData.Settings.GUIBackgroundColor,...
    "BorderColor",OOPSData.Settings.GUIForegroundColor);

OOPSData.Handles.GUISettingsGrid = OOPSData.Handles.SettingsAccordion.Items(14).Pane;

set(OOPSData.Handles.GUISettingsGrid,...
    'BackgroundColor','Black',...
    'Scrollable','on',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20,20,20},...
    'ColumnWidth',{'fit','1x'});

% background color
OOPSData.Handles.GUIBackgroundColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.GUISettingsGrid,...
    'Text','Background color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor',[1 1 1]);
OOPSData.Handles.GUIBackgroundColorDropdownLabel.Layout.Row = 1;
OOPSData.Handles.GUIBackgroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.GUIBackgroundColorDropdown = uidropdown('Parent',OOPSData.Handles.GUISettingsGrid,...
    'Items',[colorNames,'Custom'],...
    'ItemsData',[colorCodesCell,OOPSData.Settings.GUIBackgroundColor],...
    'Value',OOPSData.Settings.GUIBackgroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@GUIColorsChanged},...
    'Tag','BackgroundColor');
OOPSData.Handles.GUIBackgroundColorDropdown.Layout.Row = 1;
OOPSData.Handles.GUIBackgroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.GUIBackgroundColorDropdown);

% foreground color
OOPSData.Handles.GUIForegroundColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.GUISettingsGrid,...
    'Text','Foreground color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor',[1 1 1]);
OOPSData.Handles.GUIForegroundColorDropdownLabel.Layout.Row = 2;
OOPSData.Handles.GUIForegroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.GUIForegroundColorDropdown = uidropdown('Parent',OOPSData.Handles.GUISettingsGrid,...
    'Items',[colorNames,'Custom'],...
    'ItemsData',[colorCodesCell,OOPSData.Settings.GUIForegroundColor],...
    'Value',OOPSData.Settings.GUIForegroundColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@GUIColorsChanged},...
    'Tag','ForegroundColor');
OOPSData.Handles.GUIForegroundColorDropdown.Layout.Row = 2;
OOPSData.Handles.GUIForegroundColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.GUIForegroundColorDropdown);

% highlight color
OOPSData.Handles.GUIHighlightColorDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.GUISettingsGrid,...
    'Text','Highlight color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor',[1 1 1]);
OOPSData.Handles.GUIHighlightColorDropdownLabel.Layout.Row = 3;
OOPSData.Handles.GUIHighlightColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.GUIHighlightColorDropdown = uidropdown('Parent',OOPSData.Handles.GUISettingsGrid,...
    'Items',[colorNames,'Custom'],...
    'ItemsData',[colorCodesCell,OOPSData.Settings.GUIHighlightColor],...
    'Value',OOPSData.Settings.GUIHighlightColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ClickedFcn',@colorDropdownClicked,...
    'UserData',{@GUIColorsChanged},...
    'Tag','HighlightColor');
OOPSData.Handles.GUIHighlightColorDropdown.Layout.Row = 3;
OOPSData.Handles.GUIHighlightColorDropdown.Layout.Column = 2;
updateColorDropdownStyles(OOPSData.Handles.GUIHighlightColorDropdown);

% font size
OOPSData.Handles.GUIFontSizeLabel = uilabel(...
    'Parent',OOPSData.Handles.GUISettingsGrid,...
    'Text','Font size',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.GUIFontSizeLabel.Layout.Row = 4;
OOPSData.Handles.GUIFontSizeLabel.Layout.Column = 1;

OOPSData.Handles.GUIFontSizeEditfield = uieditfield(...
    OOPSData.Handles.GUISettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.GUIFontSize,...
    'Limits',[5 20],...
    'RoundFractionalValues','on',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@GUIFontSizeChanged,...
    'Tag','FontSize');
OOPSData.Handles.GUIFontSizeEditfield.Layout.Row = 4;
OOPSData.Handles.GUIFontSizeEditfield.Layout.Column = 2;

%% CHECKPOINT

disp('Setting up threshold slider panel...')

%% Mask threshold adjustment panel

% panel to hold the thresh slider grid
OOPSData.Handles.ImageOperationsPanel = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off',...
    'Title','Adjust threshhold');
OOPSData.Handles.ImageOperationsPanel.Layout.Row = 1;
OOPSData.Handles.ImageOperationsPanel.Layout.Column = [4 5];
% grid to hold thresh slider axes
OOPSData.Handles.ThreshSliderGrid = uigridlayout(OOPSData.Handles.ImageOperationsPanel,[1,1],...
    'Padding',[0 0 0 0],...
    'BackgroundColor','Black',...
    'Visible','Off');
% axes to show intensity histogram and thresh slider
OOPSData.Handles.ThreshAxH = uiaxes(OOPSData.Handles.ThreshSliderGrid,...
    'Color','Black',...
    'Visible','Off',...
    'FontName',OOPSData.Settings.DefaultPlotFont,...
    'FontSize',OOPSData.Settings.GUIFontSize,...
    'FontWeight','Bold',...
    'XTick',0:0.1:1,...
    'XTickMode','Manual',...
    'XTickLabel',{'0' '0.1' '0.2' '0.3' '0.4' '0.5' '0.6' '0.7' '0.8' '0.9' '1.0'},...
    'XTickLabelMode','Manual',...
    'XColor',[1 1 1],...
    'YTick',[],...
    'YTickMode','Manual',...
    'YTickLabelMode','Manual',...
    'XLim',[0 1],...
    'XLimMode','Manual',...
    'YScale','Log',...
    'HitTest','off',...
    'ButtonDownFcn',@StartUserThresholding);
disableDefaultInteractivity(OOPSData.Handles.ThreshAxH);

% replace default toolbar with an empty one
axtoolbar(OOPSData.Handles.ThreshAxH,{});
% graphics/display sometimes unpredictable when toolbar is visible, turn it off
OOPSData.Handles.ThreshAxH.Toolbar.Visible = 'Off';

% empty data for the thresh slider
% 256 bins - left edge of bin 1 = 0, right edge of bin 256 = 1
binEdges = linspace(0,1,257);
binCounts = zeros(1,256);

% add histogram info to the histogram, place plot in thresholding axes
OOPSData.Handles.ThreshBar = histogram(OOPSData.Handles.ThreshAxH,...
    "BinEdges",binEdges,...
    "BinCounts",binCounts,...
    'FaceColor',[0.5 0.5 0.5],...
    'EdgeColor',[1 1 1],...
    'PickableParts','None',...
    'Visible','off');

% vertical line with draggable behavior for interactive thresholding
OOPSData.Handles.CurrentThresholdLine = xline(OOPSData.Handles.ThreshAxH,0,'-',{''},...
    'Tag','CurrentThresholdLine',...
    'LabelOrientation','Horizontal',...
    'PickableParts','None',...
    'HitTest','Off',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'LineWidth',1.5,...
    'Color','White',...
    'LabelVerticalAlignment','Middle',...
    'Visible','Off');

clear RandomData

% % testing without this drawnow command
drawnow
pause(0.5)

%% CHECKPOINT

disp('Setting up log window...')

%% Log panel

% panel to display log messages (updates user on running/completed processes)
OOPSData.Handles.LogPanel = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off',...
    'Title','Log');
OOPSData.Handles.LogPanel.Layout.Row = 4;
OOPSData.Handles.LogPanel.Layout.Column = [1 5];

OOPSData.Handles.LogWindowGrid = uigridlayout(OOPSData.Handles.LogPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Visible','off');
OOPSData.Handles.LogWindow = uitextarea(OOPSData.Handles.LogWindowGrid,...
    'HorizontalAlignment','left',...
    'enable','on',...
    'tag','LogWindow',...
    'BackgroundColor','black',...
    'FontColor','white',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'Value',{''},...
    'Visible','off',...
    'Editable','off');

%% CHECKPOINT

disp('Setting up image panels...')

%% Small Image Panels
% tags for small panels
panel_tags = ['Panel_1-1' 'Panel_1-2' 'Panel_1-3' 'Panel_1-4';...
    'Panel_2-1' 'Panel_2-2' 'Panel_2-3' 'Panel_2-4'];

for SmallPanelRows = 1:2
    for SmallPanelColumns = 1:4
        OOPSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns) = uipanel(OOPSData.Handles.MainGrid,'Visible','Off');
        OOPSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Row = SmallPanelRows+1;
        OOPSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Column = SmallPanelColumns+1;
        OOPSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Tag = panel_tags(SmallPanelRows,SmallPanelColumns);
        % Important to set so we can resize children of panels with expected behavior
        OOPSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).AutoResizeChildren = 'Off';
    end
end

%% Large Image Panels
% first one (lefthand panel)
OOPSData.Handles.ImgPanel1 = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off');
OOPSData.Handles.ImgPanel1.Layout.Row = [2 3];
OOPSData.Handles.ImgPanel1.Layout.Column = [2 3];

% second one (righthand panel)
OOPSData.Handles.ImgPanel2 = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off');
OOPSData.Handles.ImgPanel2.Layout.Row = [2 3];
OOPSData.Handles.ImgPanel2.Layout.Column = [4 5];

% add these to an array so we can change their settings simultaneously
OOPSData.Handles.LargePanels = [OOPSData.Handles.ImgPanel1,OOPSData.Handles.ImgPanel2];

%% draw all the panels and pause briefly for more predictable performance

% testing without this drawnow command
drawnow
pause(0.5)

%% CHECKPOINT

disp('Setting up selection listboxes...')

%% Selection panels (selection listboxes/trees for group/image/objects)

OOPSData.Handles.SelectorGrid = uigridlayout(OOPSData.Handles.MainGrid,[1,3],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);
OOPSData.Handles.SelectorGrid.Layout.Row = 1;
OOPSData.Handles.SelectorGrid.Layout.Column = [2 3];
OOPSData.Handles.SelectorGrid.ColumnWidth = {'0.25x','0.5x','0.25x'};
OOPSData.Handles.SelectorGrid.ColumnSpacing = 0;

% group selector (uitree)
OOPSData.Handles.GroupSelectorPanel = uipanel(OOPSData.Handles.SelectorGrid,...
    'Title','Group',...
    'Visible','Off');
OOPSData.Handles.GroupSelectorPanelGrid = uigridlayout(OOPSData.Handles.GroupSelectorPanel,[1,1],...
    'Padding',[0 0 0 0]);
OOPSData.Handles.GroupTree = uitree(OOPSData.Handles.GroupSelectorPanelGrid,...
    'SelectionChangedFcn',@changeActiveGroup,...
    'NodeTextChangedFcn',@groupTreeNodeTextChanged,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','bold',...
    'Interruptible','off',...
    'Editable','on');
OOPSData.Handles.GroupTree.Layout.Row = 1;
OOPSData.Handles.GroupTree.Layout.Column = 1;
% context menu for the entire group tree
OOPSData.Handles.GroupTreeContextMenu = uicontextmenu(OOPSData.Handles.fH);
OOPSData.Handles.GroupTreeContextMenu_New = uimenu(OOPSData.Handles.GroupTreeContextMenu,...
    'Text','New group',...
    'MenuSelectedFcn',@addNewGroup);
OOPSData.Handles.GroupTree.ContextMenu = OOPSData.Handles.GroupTreeContextMenu;
% context menu for individual groups
OOPSData.Handles.GroupContextMenu = uicontextmenu(OOPSData.Handles.fH);
OOPSData.Handles.GroupContextMenu_Delete = uimenu(OOPSData.Handles.GroupContextMenu,...
    'Text','Delete group',...
    'MenuSelectedFcn',{@deleteCurrentGroup,OOPSData.Handles.fH});
OOPSData.Handles.GroupContextMenu_ChangeColor = uimenu(OOPSData.Handles.GroupContextMenu,...
    'Text','Change color',...
    'MenuSelectedFcn',{@editGroupColor,OOPSData.Handles.fH});
OOPSData.Handles.GroupContextMenu_New = uimenu(OOPSData.Handles.GroupContextMenu,...
    'Text','New group',...
    'MenuSelectedFcn',@addNewGroup);

% image selector (uitree)
OOPSData.Handles.ImageSelectorPanel = uipanel(OOPSData.Handles.SelectorGrid,...
    'Title','Image',...
    'Visible','Off');
OOPSData.Handles.ImageSelectorPanelGrid = uigridlayout(OOPSData.Handles.ImageSelectorPanel,[1,1],...
    'Padding',[0 0 0 0]);
OOPSData.Handles.ImageTree = uitree(OOPSData.Handles.ImageSelectorPanelGrid,...
    'SelectionChangedFcn',@changeActiveImage,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','bold',...
    'Multiselect','on',...
    'Enable','on',...
    'Interruptible','off');
OOPSData.Handles.ImageTree.Layout.Row = 1;
OOPSData.Handles.ImageTree.Layout.Column = 1;
% context menu for individual image nodes
OOPSData.Handles.ImageContextMenu = uicontextmenu(OOPSData.Handles.fH);
OOPSData.Handles.ImageContextMenu_Delete = uimenu(OOPSData.Handles.ImageContextMenu,...
    'Text','Delete selected',...
    'MenuSelectedFcn',{@deleteImage,OOPSData.Handles.fH});

% object selector (listbox, will replace with tree, but too slow for now)
OOPSData.Handles.ObjectSelectorPanel = uipanel(OOPSData.Handles.SelectorGrid,...
    'Title','Object',...
    'Visible','Off');
OOPSData.Handles.ObjectSelectorPanelGrid = uigridlayout(OOPSData.Handles.ObjectSelectorPanel,[1,1],...
    'Padding',[0 0 0 0]);
OOPSData.Handles.ObjectSelector = uilistbox(...
    'parent',OOPSData.Handles.ObjectSelectorPanelGrid,...
    'Visible','Off',...
    'enable','on',...
    'tag','ObjectListBox',...
    'Items',{},...
    'ValueChangedFcn',@changeActiveObject,...
    'BackgroundColor',[1 1 1],...
    'FontColor',[0 0 0],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'MultiSelect','off',...
    'Visible','Off',...
    'Interruptible','off'); %% might need to change to on

%% CHECKPOINT

disp('Setting up context menus...')

%% AXES AND IMAGE PLACEHOLDERS

% empty placeholder image
emptyimage = zeros(1024,1024);

%% CHECKPOINT

disp('Setting up small image axes...')

%% Small images
    %% Flat-field correction stack

for k = 1:4
    OOPSData.Handles.FFCAxH(k) = uiaxes('Parent',OOPSData.Handles.SmallPanels(2,k),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag',['FFC' num2str((k-1)*45)],...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = OOPSData.Handles.FFCAxH(k).PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.FFCAxH(k).Tag;
    % place placeholder image on axis
    OOPSData.Handles.FFCImgH(k) = imshow(full(emptyimage),'Parent',OOPSData.Handles.FFCAxH(k));
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.FFCImgH(k),'Tag',['FFCImage' num2str((k-1)*45)]);
    
    % restore original values after imshow() call
    OOPSData.Handles.FFCAxH(k) = restore_axis_defaults(OOPSData.Handles.FFCAxH(k),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    OOPSData.Handles.FFCAxH(k) = SetAxisTitle(OOPSData.Handles.FFCAxH(k),['Flat-Field Image (' num2str((k-1)*45) '^{\circ})']);
    OOPSData.Handles.FFCAxH(k).Colormap = OOPSData.Settings.IntensityColormap;
    OOPSData.Handles.FFCImgH(k).HitTest = 'Off';
    
    disableDefaultInteractivity(OOPSData.Handles.FFCAxH(k));
end

    %% Raw intensity stack
for k = 1:4
    OOPSData.Handles.RawIntensityAxH(k) = uiaxes('Parent',OOPSData.Handles.SmallPanels(1,k),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag',['Raw' num2str((k-1)*45)],...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = OOPSData.Handles.RawIntensityAxH(k).PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.RawIntensityAxH(k).Tag;
    % place placeholder image on axis
    OOPSData.Handles.RawIntensityImgH(k) = imshow(full(emptyimage),'Parent',OOPSData.Handles.RawIntensityAxH(k));
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.RawIntensityImgH(k),'Tag',['RawImage' num2str((k-1)*45)]);
    
    % restore original values after imshow() call
    OOPSData.Handles.RawIntensityAxH(k) = restore_axis_defaults(OOPSData.Handles.RawIntensityAxH(k),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    OOPSData.Handles.RawIntensityAxH(k) = SetAxisTitle(OOPSData.Handles.RawIntensityAxH(k),['Raw Intensity (' num2str((k-1)*45) '^{\circ})']);
    OOPSData.Handles.RawIntensityAxH(k).Colormap = OOPSData.Settings.IntensityColormap;
    OOPSData.Handles.RawIntensityImgH(k).HitTest = 'Off';
    
    disableDefaultInteractivity(OOPSData.Handles.RawIntensityAxH(k));
end
 
    %% Flat-field corrected intensity stack
for k = 1:4
    OOPSData.Handles.PolFFCAxH(k) = uiaxes('Parent',OOPSData.Handles.SmallPanels(2,k),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag',['PolFFC' num2str((k-1)*45)],...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = OOPSData.Handles.PolFFCAxH(k).PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.PolFFCAxH(k).Tag;
    % place placeholder image on axis
    OOPSData.Handles.PolFFCImgH(k) = imshow(full(emptyimage),'Parent',OOPSData.Handles.PolFFCAxH(k));
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.PolFFCImgH(k),'Tag',['PolFFCImage' num2str((k-1)*45)]);
    
    % restore original values after imshow() call
    OOPSData.Handles.PolFFCAxH(k) = restore_axis_defaults(OOPSData.Handles.PolFFCAxH(k),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    OOPSData.Handles.PolFFCAxH(k) = SetAxisTitle(OOPSData.Handles.PolFFCAxH(k),['Flat-Field Corrected Intensity (' num2str((k-1)*45) '^{\circ})']);
    
    OOPSData.Handles.PolFFCAxH(k).Colormap = OOPSData.Settings.IntensityColormap;
    OOPSData.Handles.PolFFCAxH(k).Toolbar.Visible = 'Off';
    OOPSData.Handles.PolFFCAxH(k).Title.Visible = 'Off';
    OOPSData.Handles.PolFFCAxH(k).HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.PolFFCAxH(k));
    
    OOPSData.Handles.PolFFCImgH(k).Visible = 'Off';
    OOPSData.Handles.PolFFCImgH(k).HitTest = 'Off';
end

%% CHECKPOINT

disp('Setting up large image axes...')

%% Large images
    %% Average intensity
    OOPSData.Handles.AverageIntensityAxH = uiaxes(OOPSData.Handles.ImgPanel1,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','AverageIntensity',...
        'XTick',[],...
        'YTick',[],...
        'CLim',[0 1]);
    % save original values to be restored after calling imshow()
    pbarOriginal = OOPSData.Handles.AverageIntensityAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.AverageIntensityAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.AverageIntensityImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.AverageIntensityAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.AverageIntensityImgH,'Tag','AverageIntensityImage');
    
    % restore original values after imshow() call
    OOPSData.Handles.AverageIntensityAxH = restore_axis_defaults(OOPSData.Handles.AverageIntensityAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    OOPSData.Handles.AverageIntensityAxH = SetAxisTitle(OOPSData.Handles.AverageIntensityAxH,'Average Intensity');

    % make colorbar and set colormap for the axes, hide the colorbar and disable interactions with it
    OOPSData.Handles.AverageIntensityCbar = colorbar(OOPSData.Handles.AverageIntensityAxH,...
        'location','east',...
        'color','white',...
        'tag','AverageIntensityCbar',...
        'Ticks',0:0.1:1);
    OOPSData.Handles.AverageIntensityCbar.Visible = 'Off';
    OOPSData.Handles.AverageIntensityCbar.HitTest = 'Off';

    % set colormap
    OOPSData.Handles.AverageIntensityAxH.Colormap = OOPSData.Settings.IntensityColormap;
    % hide axes toolbar and title, turn off hittest
    OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
    OOPSData.Handles.AverageIntensityAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.AverageIntensityAxH);
    % hide/diable image
    OOPSData.Handles.AverageIntensityImgH.Visible = 'Off';
    OOPSData.Handles.AverageIntensityImgH.HitTest = 'Off';

    %% Order

    OOPSData.Handles.OrderAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','Order',...
        'XTick',[],...
        'YTick',[],...
        'CLim',[0 1]);
    % save original values to be restored after calling imshow()
    pbarOriginal = OOPSData.Handles.OrderAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.OrderAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.OrderImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.OrderAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.OrderImgH,'Tag','OrderImage');
    % restore original values after imshow() call
    OOPSData.Handles.OrderAxH = restore_axis_defaults(OOPSData.Handles.OrderAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    OOPSData.Handles.OrderAxH = SetAxisTitle(OOPSData.Handles.OrderAxH,'Order');

    % make colorbar and set colormap for the axes, hide the colorbar and disable interactions with it
    OOPSData.Handles.OrderCbar = colorbar(OOPSData.Handles.OrderAxH,...
        'location','east',...
        'color','white',...
        'tag','OrderCbar',...
        'Ticks',0:0.1:1);
    OOPSData.Handles.OrderCbar.Visible = 'Off';
    OOPSData.Handles.OrderCbar.HitTest = 'Off';
    OOPSData.Handles.OrderAxH.Colormap = OOPSData.Settings.OrderColormap;
    % hide axes toolbar and title, disable click interactivity, disable all default interactivity
    OOPSData.Handles.OrderAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.OrderAxH.Title.Visible = 'Off';
    OOPSData.Handles.OrderAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.OrderAxH);
    
    OOPSData.Handles.OrderImgH.Visible = 'Off';
    OOPSData.Handles.OrderImgH.HitTest = 'Off';
    
    %% Axis for swarm plots

    OOPSData.Handles.SwarmPlot = ViolinChart(...
        "Parent",OOPSData.Handles.ImgPanel2,...
        "Data",{NaN},...
        "BackgroundColor",OOPSData.Settings.SwarmPlotBackgroundColor,...
        "ForegroundColor",OOPSData.Settings.SwarmPlotForegroundColor,...
        "Title","",...
        "XJitterWidth",OOPSData.Settings.SwarmPlotXJitterWidth,...
        "ViolinOutlinesVisible",OOPSData.Settings.SwarmPlotViolinsVisible,...
        "MarkerFaceAlpha",OOPSData.Settings.SwarmPlotMarkerFaceAlpha,...
        "ErrorBarsVisible",OOPSData.Settings.SwarmPlotErrorBarsVisible,...
        "Visible","off");

    % set up context menu for swarm plot
    OOPSData.Handles.SwarmPlotContextMenu = uicontextmenu(OOPSData.Handles.fH);
    % set up context menu options
    OOPSData.Handles.SwarmPlotContextMenu_CopyVector = uimenu(OOPSData.Handles.SwarmPlotContextMenu,...
        'Text','Copy as vector graphic',...
        'MenuSelectedFcn',@CopySwarmPlotVector);
    % add the context menu to the axes
    OOPSData.Handles.SwarmPlot.ContextMenu = OOPSData.Handles.SwarmPlotContextMenu;
    
    %% Axis for scatter plots

    OOPSData.Handles.ScatterPlotGrid = uigridlayout(OOPSData.Handles.ImgPanel1,[1,1],...
        'Padding',[0 0 0 0],...
        'BackgroundColor',OOPSData.Settings.ScatterPlotBackgroundColor,...
        'Tag','ScatterPlotGrid',...
        'Visible','Off',...
        'ColumnWidth',{'1x'},...
        'RowHeight',{'1x'});

    OOPSData.Handles.ScatterPlotAxH = uiaxes(OOPSData.Handles.ScatterPlotGrid,...
        'Tag','ScatterPlotAxes',...
        'XTick',[],...
        'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0],...
        'NextPlot','Add',...
        'Visible','Off',...
        'Color',OOPSData.Settings.ScatterPlotBackgroundColor,...
        'XColor','White',...
        'YColor','White',...
        'HitTest','Off',...
        'FontName',OOPSData.Settings.DefaultPlotFont);
    
    disableDefaultInteractivity(OOPSData.Handles.ScatterPlotAxH);
    axtoolbar(OOPSData.Handles.ScatterPlotAxH,{});

    % set axis title
    OOPSData.Handles.ScatterPlotAxH = SetAxisTitle(OOPSData.Handles.ScatterPlotAxH,'Object-Average Order vs Local S/B');
    
    OOPSData.Handles.ScatterPlotAxH.XAxis.Label.String = "Local S/B";
    OOPSData.Handles.ScatterPlotAxH.XAxis.Color = OOPSData.Settings.ScatterPlotForegroundColor;
    OOPSData.Handles.ScatterPlotAxH.XAxis.Label.FontName = OOPSData.Settings.DefaultPlotFont;
    OOPSData.Handles.ScatterPlotAxH.YAxis.Label.String = "Object-Average Order";
    OOPSData.Handles.ScatterPlotAxH.YAxis.Color = OOPSData.Settings.ScatterPlotForegroundColor;
    OOPSData.Handles.ScatterPlotAxH.YAxis.Label.FontName = OOPSData.Settings.DefaultPlotFont;
    OOPSData.Handles.ScatterPlotAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.ScatterPlotAxH.Title.Visible = 'Off';
    OOPSData.Handles.ScatterPlotAxH.Title.BackgroundColor = 'none';

    % set up legend
    OOPSData.Handles.ScatterPlotLegend = legend(OOPSData.Handles.ScatterPlotAxH);
    OOPSData.Handles.ScatterPlotLegend.TextColor = OOPSData.Settings.ScatterPlotForegroundColor;
    OOPSData.Handles.ScatterPlotLegend.Color = OOPSData.Settings.ScatterPlotBackgroundColor;

    % set up context menu for scatter plot
    OOPSData.Handles.ScatterPlotContextMenu = uicontextmenu(OOPSData.Handles.fH);
    % set up context menu options
    OOPSData.Handles.ScatterPlotContextMenu_CopyVector = uimenu(OOPSData.Handles.ScatterPlotContextMenu,...
        'Text','Copy as vector graphic',...
        'MenuSelectedFcn',@CopyScatterPlotVector);

    % add the context menu to the axes
    OOPSData.Handles.ScatterPlotAxH.ContextMenu = OOPSData.Handles.ScatterPlotContextMenu;

    %% Polar histogram - image

    % create custom polar histogram with random data
    OOPSData.Handles.ImagePolarHistogram = PolarHistogramColorChart(...
        'Parent',OOPSData.Handles.ImgPanel1,...
        'polarData',rand(1000,1)*pi,...
        'wedgeColors',OOPSData.Settings.AzimuthColormap,...
        'nBins',OOPSData.Settings.PolarHistogramnBins,...
        'circleColor',OOPSData.Settings.PolarHistogramCircleColor,...
        'circleBackgroundColor',OOPSData.Settings.PolarHistogramCircleBackgroundColor,...
        'wedgeFaceColor',OOPSData.Settings.PolarHistogramWedgeFaceColor,...
        'wedgeEdgeColor',OOPSData.Settings.PolarHistogramWedgeEdgeColor,...
        'wedgeLineWidth',OOPSData.Settings.PolarHistogramWedgeLineWidth,...
        'wedgeLineColor',OOPSData.Settings.PolarHistogramWedgeLineColor,...
        'rGridlinesLineWidth',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
        'thetaGridlinesLineWidth',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
        'rGridlinesColor',OOPSData.Settings.PolarHistogramGridlinesColor,...
        'thetaGridlinesColor',OOPSData.Settings.PolarHistogramGridlinesColor,...
        'thetaLabelsColor',OOPSData.Settings.PolarHistogramLabelsColor,...
        'BackgroundColor',OOPSData.Settings.PolarHistogramBackgroundColor,...
        'wedgeColorsRepeats',2,...
        'Title','Image - Pixel azimuths',...
        'Visible','off');

    %% Polar histogram - group

    % create custom polar histogram with random data
    OOPSData.Handles.GroupPolarHistogram = PolarHistogramColorChart(...
        'Parent',OOPSData.Handles.ImgPanel2,...
        'polarData',rand(1000,1)*pi,...
        'wedgeColors',OOPSData.Settings.AzimuthColormap,...
        'nBins',OOPSData.Settings.PolarHistogramnBins,...
        'circleColor',OOPSData.Settings.PolarHistogramCircleColor,...
        'circleBackgroundColor',OOPSData.Settings.PolarHistogramCircleBackgroundColor,...
        'wedgeFaceColor',OOPSData.Settings.PolarHistogramWedgeFaceColor,...
        'wedgeEdgeColor',OOPSData.Settings.PolarHistogramWedgeEdgeColor,...
        'wedgeLineWidth',OOPSData.Settings.PolarHistogramWedgeLineWidth,...
        'wedgeLineColor',OOPSData.Settings.PolarHistogramWedgeLineColor,...
        'rGridlinesLineWidth',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
        'thetaGridlinesLineWidth',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
        'rGridlinesColor',OOPSData.Settings.PolarHistogramGridlinesColor,...
        'thetaGridlinesColor',OOPSData.Settings.PolarHistogramGridlinesColor,...
        'thetaLabelsColor',OOPSData.Settings.PolarHistogramLabelsColor,...
        'BackgroundColor',OOPSData.Settings.PolarHistogramBackgroundColor,...
        'wedgeColorsRepeats',2,...
        'Title','Group - Pixel azimuths',...
        'Visible','off');

    %% Mask

    OOPSData.Handles.MaskAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','Mask',...
        'XTick',[],...
        'YTick',[]);

    % save original values to be restored after calling imshow()
    pbarOriginal = OOPSData.Handles.MaskAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.MaskAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.MaskImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.MaskAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.MaskImgH,'Tag','MaskImage');
    
    % restore original values after imshow() call
    OOPSData.Handles.MaskAxH = restore_axis_defaults(OOPSData.Handles.MaskAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    OOPSData.Handles.MaskAxH = SetAxisTitle(OOPSData.Handles.MaskAxH,'Mask');
    
    OOPSData.Handles.MaskAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.MaskAxH.Title.Visible = 'Off';
    OOPSData.Handles.MaskAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.MaskAxH);
    
    OOPSData.Handles.MaskImgH.Visible = 'Off';
    OOPSData.Handles.MaskImgH.HitTest = 'Off';
    
    %% Azimuth
    % azimuth image axes
    OOPSData.Handles.AzimuthAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','Azimuth',...
        'XTick',[],...
        'YTick',[]);
    % save original values to be restored after calling imshow()
    pbarOriginal = OOPSData.Handles.AzimuthAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.AzimuthAxH.Tag;    
    % place placeholder image on axis
    OOPSData.Handles.AzimuthImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.AzimuthAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.AzimuthImgH,'Tag','AzimuthImage');
    % restore original values after imshow() call
    OOPSData.Handles.AzimuthAxH = restore_axis_defaults(OOPSData.Handles.AzimuthAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    % set axis title
    OOPSData.Handles.AzimuthAxH = SetAxisTitle(OOPSData.Handles.AzimuthAxH,'Azimuth');

    imageHeight = size(emptyimage,1);

    % set up azimuth colorbar
    % calculate center and radius for lower right position
    padding = 0.025*imageHeight;
    % inner and outer radii
    outerRadius = 0.1*imageHeight;
    innerRadius = outerRadius/(pi/2);
    % center coordinates
    centerX = imageHeight-outerRadius-padding;
    centerY = centerX;

    OOPSData.Handles.AzimuthColorbar = circularColorbar(OOPSData.Handles.AzimuthAxH, ...
        'centerX',centerX, ...
        'centerY',centerY, ...
        'Colormap',vertcat(hsv,hsv), ...
        'innerRadius',innerRadius, ...
        'outerRadius',outerRadius, ...
        'nRepeats',1, ...
        'Visible','off',...
        'FontSize',OOPSData.Settings.GUIFontSize,...
        'FontName',OOPSData.Settings.DefaultPlotFont);

    OOPSData.Handles.AzimuthAxH.Title.Visible = 'Off';   
    OOPSData.Handles.AzimuthAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.AzimuthAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.AzimuthAxH);

    OOPSData.Handles.AzimuthImgH.Visible = 'Off';
    OOPSData.Handles.AzimuthImgH.HitTest = 'Off';

    %% Custom Statistics

    OOPSData.Handles.CustomStatAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','CustomStat',...
        'XTick',[],...
        'YTick',[],...
        'CLim',[0 1]);
    % save original values to be restored after calling imshow()
    pbarOriginal = OOPSData.Handles.CustomStatAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.CustomStatAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.CustomStatImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.CustomStatAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.CustomStatImgH,'Tag','CustomStatImage');
    % restore original values after imshow() call
    OOPSData.Handles.CustomStatAxH = restore_axis_defaults(OOPSData.Handles.CustomStatAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    OOPSData.Handles.CustomStatAxH = SetAxisTitle(OOPSData.Handles.CustomStatAxH,'Custom');

    % make colorbar and set colormap for the axes, hide the colorbar and disable interactions with it
    OOPSData.Handles.CustomStatCbar = colorbar(OOPSData.Handles.CustomStatAxH,'location','east','color','white','tag','CustomStatCbar');
    OOPSData.Handles.CustomStatAxH.Colormap = OOPSData.Settings.OrderColormap;
    OOPSData.Handles.CustomStatCbar.Visible = 'Off';
    OOPSData.Handles.CustomStatCbar.HitTest = 'Off';

    % hide axes toolbar and title, disable click interactivity, disable all default interactivity
    OOPSData.Handles.CustomStatAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.CustomStatAxH.Title.Visible = 'Off';
    OOPSData.Handles.CustomStatAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.CustomStatAxH);
    
    OOPSData.Handles.CustomStatImgH.Visible = 'Off';
    OOPSData.Handles.CustomStatImgH.HitTest = 'Off';


%% CHECKPOINT

disp('Setting up object image axes...')
    
    %% Object FFCIntensity Image
    
    OOPSData.Handles.ObjectPolFFCAxH = uiaxes(OOPSData.Handles.SmallPanels(1,1),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectPolFFC',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = OOPSData.Handles.ObjectPolFFCAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.ObjectPolFFCAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.ObjectPolFFCImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.ObjectPolFFCAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.ObjectPolFFCImgH,'Tag','ObjectPolFFCImage');
    % restore original values after imshow() call
    OOPSData.Handles.ObjectPolFFCAxH = restore_axis_defaults(OOPSData.Handles.ObjectPolFFCAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    OOPSData.Handles.ObjectPolFFCAxH = SetAxisTitle(OOPSData.Handles.ObjectPolFFCAxH,'Average intensity');
    OOPSData.Handles.ObjectPolFFCAxH.Colormap = OOPSData.Settings.IntensityColormap;
    OOPSData.Handles.ObjectPolFFCAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.ObjectPolFFCAxH.Title.Visible = 'Off';
    OOPSData.Handles.ObjectPolFFCAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.ObjectPolFFCAxH);
    
    OOPSData.Handles.ObjectPolFFCImgH.Visible = 'Off';
    OOPSData.Handles.ObjectPolFFCImgH.HitTest = 'Off';
    
    %% Object Binary Image
    
    OOPSData.Handles.ObjectMaskAxH = uiaxes(OOPSData.Handles.SmallPanels(1,2),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectMask',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = OOPSData.Handles.ObjectMaskAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.ObjectMaskAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.ObjectMaskImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.ObjectMaskAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.ObjectMaskImgH,'Tag','ObjectMaskImage');
    % restore original values after imshow() call
    OOPSData.Handles.ObjectMaskAxH = restore_axis_defaults(OOPSData.Handles.ObjectMaskAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    OOPSData.Handles.ObjectMaskAxH = SetAxisTitle(OOPSData.Handles.ObjectMaskAxH,'Mask');
    OOPSData.Handles.ObjectMaskAxH.Title.Visible = 'Off';
    OOPSData.Handles.ObjectMaskAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.ObjectMaskAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.ObjectMaskAxH);
    
    OOPSData.Handles.ObjectMaskImgH.Visible = 'Off';
    OOPSData.Handles.ObjectMaskImgH.HitTest = 'Off';
    
    %% Object Azimuth Overlay

    OOPSData.Handles.ObjectAzimuthOverlayAxH = uiaxes(OOPSData.Handles.SmallPanels(2,2),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectAzimuthOverlay',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = OOPSData.Handles.ObjectAzimuthOverlayAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.ObjectAzimuthOverlayAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.ObjectAzimuthOverlayImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.ObjectAzimuthOverlayAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.ObjectAzimuthOverlayImgH,'Tag','ObjectAzimuthOverlay');
    % restore original values after imshow() call
    OOPSData.Handles.ObjectAzimuthOverlayAxH = restore_axis_defaults(OOPSData.Handles.ObjectAzimuthOverlayAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    OOPSData.Handles.ObjectAzimuthOverlayAxH = SetAxisTitle(OOPSData.Handles.ObjectAzimuthOverlayAxH,'Azimuth stick overlay');
    
    OOPSData.Handles.ObjectAzimuthOverlayAxH.Colormap = OOPSData.Settings.IntensityColormap;
    
    OOPSData.Handles.ObjectAzimuthOverlayAxH.Title.Visible = 'Off';
    OOPSData.Handles.ObjectAzimuthOverlayAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.ObjectAzimuthOverlayAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.ObjectAzimuthOverlayAxH);
    
    OOPSData.Handles.ObjectAzimuthOverlayImgH.Visible = 'Off';
    OOPSData.Handles.ObjectAzimuthOverlayImgH.HitTest = 'Off';

    %% Object Order Image
    
    OOPSData.Handles.ObjectOrderAxH = uiaxes(OOPSData.Handles.SmallPanels(2,1),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectOrder',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = OOPSData.Handles.ObjectOrderAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.ObjectOrderAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.ObjectOrderImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.ObjectOrderAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.ObjectOrderImgH,'Tag','ObjectOrderImage');
    % restore original values after imshow() call
    OOPSData.Handles.ObjectOrderAxH = restore_axis_defaults(OOPSData.Handles.ObjectOrderAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    OOPSData.Handles.ObjectOrderAxH = SetAxisTitle(OOPSData.Handles.ObjectOrderAxH,'Order');
    
    OOPSData.Handles.ObjectOrderAxH.Colormap = OOPSData.Settings.OrderColormap;
    
    OOPSData.Handles.ObjectOrderAxH.Title.Visible = 'Off';
    OOPSData.Handles.ObjectOrderAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.ObjectOrderAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.ObjectOrderAxH);
    
    OOPSData.Handles.ObjectOrderImgH.Visible = 'Off';
    OOPSData.Handles.ObjectOrderImgH.HitTest = 'Off';
    
    %% Object Intensity Fit Plots

    OOPSData.Handles.ObjectIntensityPlotAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'OuterPosition',[0 0 1 0.75],...
        'Visible','Off',...
        'Tag','ObjectIntensityPlotAxH',...
        'NextPlot','Add',...
        'Color',OOPSData.Settings.ObjectIntensityProfileBackgroundColor,...
        'Box','On',...
        'XColor',OOPSData.Settings.ObjectIntensityProfileForegroundColor,...
        'YColor',OOPSData.Settings.ObjectIntensityProfileForegroundColor,...
        'BoxStyle','Back',...
        'HitTest','Off',...
        'XLim',[0 pi],...
        'XTick',[0 pi/4 pi/2 3*pi/4 pi],...
        'XTickLabel',{'0°' '45°' '90°' '135°' '180°'},...
        'FontName',OOPSData.Settings.DefaultPlotFont);
    
    OOPSData.Handles.ObjectIntensityPlotAxH.XAxis.Label.String = "Excitation polarization (°)";
    OOPSData.Handles.ObjectIntensityPlotAxH.XAxis.Label.Color = [1 1 0];
    OOPSData.Handles.ObjectIntensityPlotAxH.XAxis.Label.FontName = OOPSData.Settings.DefaultPlotFont;
    OOPSData.Handles.ObjectIntensityPlotAxH.YAxis.Label.String = "Normalized intensity (A.U.)";
    OOPSData.Handles.ObjectIntensityPlotAxH.YAxis.Label.Color = [1 1 0];
    OOPSData.Handles.ObjectIntensityPlotAxH.YAxis.Label.FontName = OOPSData.Settings.DefaultPlotFont;
    
    disableDefaultInteractivity(OOPSData.Handles.ObjectIntensityPlotAxH);

    % set up context menu for object intensity profile plot
    OOPSData.Handles.ObjectIntensityPlotContextMenu = uicontextmenu(OOPSData.Handles.fH);
    % set up context menu options
    OOPSData.Handles.ObjectIntensityPlotContextMenu_CopyVector = uimenu(OOPSData.Handles.ObjectIntensityPlotContextMenu,...
        'Text','Copy as vector graphic',...
        'MenuSelectedFcn',@CopyObjectIntensityPlotVector);
    % add the context menu to the axes
    OOPSData.Handles.ObjectIntensityPlotAxH.ContextMenu = OOPSData.Handles.ObjectIntensityPlotContextMenu;
    
    %% Object Stack-Normalized Intensity Stack
    
    OOPSData.Handles.ObjectNormIntStackAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Units','normalized',...
        'InnerPosition',[0 0.75 1 0.25],...
        'Tag','ObjectNormIntStack',...
        'XTick',[],...
        'YTick',[]);
    %OOPSData.Handles.ObjectNormIntStackAxH.Layout.Row = 1;
    % save original values
    pbarOriginal = OOPSData.Handles.ObjectNormIntStackAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.ObjectNormIntStackAxH.Tag;
    % place placeholder image on axis
    emptysz = size(emptyimage);
    OOPSData.Handles.ObjectNormIntStackImgH = imshow(full(emptyimage(1:emptysz(1)*0.25,1:end)),'Parent',OOPSData.Handles.ObjectNormIntStackAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.ObjectNormIntStackImgH,'Tag','ObjectNormIntStack');
    % restore original values after imshow() call
    OOPSData.Handles.ObjectNormIntStackAxH = restore_axis_defaults(OOPSData.Handles.ObjectNormIntStackAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    OOPSData.Handles.ObjectNormIntStackAxH = SetAxisTitle(OOPSData.Handles.ObjectNormIntStackAxH,'Normalized intensity stack');
    OOPSData.Handles.ObjectNormIntStackAxH.Colormap = OOPSData.Settings.IntensityColormap;
    OOPSData.Handles.ObjectNormIntStackAxH.Title.Visible = 'Off';
    OOPSData.Handles.ObjectNormIntStackAxH.Toolbar.Visible = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.ObjectNormIntStackAxH);
    
    OOPSData.Handles.ObjectNormIntStackImgH.Visible = 'Off';    
    OOPSData.Handles.ObjectNormIntStackImgH.HitTest = 'Off';

%% Turning on important containers and adjusting some components for proper initial display

% clean up some properties that may not display correctly
set(OOPSData.Handles.PolFFCAxH(k),'PlotBoxAspectRatio',[1 1 1]);

% set visibility to 'On' for components shown at startup
set([...
    OOPSData.Handles.SmallPanels(:);...
    OOPSData.Handles.AppInfoPanel;...
    OOPSData.Handles.ProjectSummaryPanelGrid;...
    OOPSData.Handles.AppInfoSelector;...
    OOPSData.Handles.ProjectSummaryTableGrid;...
    OOPSData.Handles.ProjectSummaryTable;...
    OOPSData.Handles.SettingsPanel;...
    OOPSData.Handles.GroupSelectorPanel;...
    OOPSData.Handles.ImageSelectorPanel;...
    OOPSData.Handles.ObjectSelectorPanel;...
    OOPSData.Handles.ObjectSelector;...
    OOPSData.Handles.LogPanel;...
    OOPSData.Handles.LogWindowGrid;...
    OOPSData.Handles.LogWindow;...
    OOPSData.Handles.ThreshSliderGrid;...
    OOPSData.Handles.ImageOperationsPanel],...
    'Visible','On');

% set uipanel linewidth
set(findobj(OOPSData.Handles.fH,'type','uipanel'),'BorderWidth',1);

% initialize some graphics placeholder objects
OOPSData.Handles.LineScanROI = gobjects(1,1);
OOPSData.Handles.LineScanFig = gobjects(1,1);
OOPSData.Handles.LineScanPlot = gobjects(1,1);
OOPSData.Handles.ObjectBoxes = gobjects(1,1);
OOPSData.Handles.SelectedObjectBoxes = gobjects(1,1);
OOPSData.Handles.AzimuthLines = gobjects(1,1);
OOPSData.Handles.ObjectAzimuthLines = gobjects(1,1);
OOPSData.Handles.ObjectMidlinePlot = gobjects(1,1);
OOPSData.Handles.ObjectBoundaryPlot = gobjects(1,1);
OOPSData.Handles.LineScanRectangle = gobjects(1,1);

% set default on/off state of toolbar buttons
OOPSData.Handles.ScaleToMaxAzimuth.Visible = 'off';

% add OOPSData to the gui using guidata (this is how we will retain access to the data across different functions)
guidata(OOPSData.Handles.fH,OOPSData)
% set global font size
fontsize(OOPSData.Handles.fH,OOPSData.Settings.GUIFontSize,'pixels');
% update GUI display colors
UpdateGUITheme(OOPSData.Handles.fH);
% update summary display
UpdateSummaryDisplay(OOPSData.Handles.fH);
% update menu bar
UpdateMenubar(OOPSData.Handles.fH);





disp('Opening...')

% some functionality will work better if the MATLAB desktop window is minimized
% uses the com.mathworks package, which will be removed in the future
try
    minimizeMLDesktop();
catch
    warning('Could not minimize MATLAB desktop window');
end

% set figure to visible to draw containers
OOPSData.Handles.fH.Visible = 'On';

drawnow
pause(0.5)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% NESTED FUNCTIONS - VARIOUS GUI CALLBACKS AND ACCESSORY FUNCTIONS

%% Custom color dropdown callbacks

    function colorDropdownClicked(source,event)
        % get the clicked item
        clickedItem = event.InteractionInformation.Item;
        % if no item clicked, return
        if isempty(clickedItem)
            return
        else
            % if 'Custom' item clicked
            if clickedItem == numel(source.Items)
                try
                    newColor = uisetcolor();
                    figure(OOPSData.Handles.fH);
                catch
                    newColor = [0 0 0];
                end
                source.ItemsData{clickedItem} = newColor;
                source.Value = newColor;
                % get a new custom color and update the dropdown styles
                updateColorDropdownStyles(source);
                % execute the callback stored in the UserData property
                feval(source.UserData{:},source);
            else
                % execute the callback stored in the UserData property
                feval(source.UserData{:},source);
            end
        end
    end

    function updateColorDropdownStyles(source)
            % first remove old styles for the entire component
            removeStyle(source);
            % then add new styles for each item based on color of each item
            for itemIdx = 1:numel(source.Items)
                thisItemColor = source.ItemsData{itemIdx};
                addStyle(source,uistyle(...
                    "BackgroundColor",thisItemColor,...
                    "FontColor",getBWContrastColor(thisItemColor)),...
                    "item",itemIdx);
            end
    end

%% Swarm plot callbacks/settings

    function CopySwarmPlotVector(source,~)
        UpdateLog3(source,'Copying...','append');
        %copygraphics(OOPSData.Handles.SwarmPlot,'ContentType','vector','BackgroundColor',OOPSData.Settings.SwarmPlotBackgroundColor);

        OOPSData.Handles.SwarmPlot.copyplot();

        UpdateLog3(source,'Swarm plot vector graphic copied to clipboard','append');
    end

    function SwarmPlotBackgroundColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.SwarmPlotSettings.BackgroundColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.SwarmPlotSettings.BackgroundColor = source.Value;
        end

        OOPSData.Handles.SwarmPlot.BackgroundColor = OOPSData.Settings.SwarmPlotBackgroundColor;
    end

    function SwarmPlotForegroundColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.SwarmPlotSettings.ForegroundColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.SwarmPlotSettings.ForegroundColor = source.Value;
        end
        
        % font color and foreground color both set to foreground color
        OOPSData.Handles.SwarmPlot.ForegroundColor = OOPSData.Settings.SwarmPlotForegroundColor;
        OOPSData.Handles.SwarmPlot.FontColor = OOPSData.Settings.SwarmPlotForegroundColor;
    end

    function SwarmPlotErrorBarsColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.SwarmPlotSettings.ErrorBarsColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.SwarmPlotSettings.ErrorBarsColor = source.Value;
        end

        OOPSData.Handles.SwarmPlot.ErrorBarsColor = OOPSData.Settings.SwarmPlotErrorBarsColor;
    end

    function SwarmPlotErrorBarsColorModeChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.ErrorBarsColorMode = source.Value;
        UpdateImages(source);
    end

    function SwarmPlotYVariableChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.YVariable = source.Value;
        UpdateImages(source);
    end

    function SwarmPlotGroupingTypeChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.GroupingType = source.Value;
        UpdateImages(source);
    end

    function SwarmPlotColorModeChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.ColorMode = source.Value;
        UpdateImages(source);
    end

    function SwarmPlotMarkerSizeChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.MarkerSize = source.Value;
        OOPSData.Handles.SwarmPlot.MarkerSize = OOPSData.Settings.SwarmPlotMarkerSize;
    end

    function SwarmPlotMarkerFaceAlphaChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.MarkerFaceAlpha = source.Value;
        OOPSData.Handles.SwarmPlot.MarkerFaceAlpha = OOPSData.Settings.SwarmPlotMarkerFaceAlpha;
    end

    function SwarmPlotErrorBarsVisibleChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.ErrorBarsVisible = source.Value;
        OOPSData.Handles.SwarmPlot.ErrorBarsVisible = OOPSData.Settings.SwarmPlotErrorBarsVisible;
    end

    function SwarmPlotXJitterWidthChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.XJitterWidth = source.Value;
        OOPSData.Handles.SwarmPlot.XJitterWidth = OOPSData.Settings.SwarmPlotXJitterWidth;
    end

    function SwarmPlotPointsVisibleChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.PointsVisible = source.Value;
        OOPSData.Handles.SwarmPlot.PointsVisible = OOPSData.Settings.SwarmPlotPointsVisible;
    end

    function SwarmPlotViolinFaceColorModeChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.ViolinFaceColorMode = source.Value;
        UpdateImages(source);
    end

    function SwarmPlotViolinFaceColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.SwarmPlotSettings.ViolinFaceColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.SwarmPlotSettings.ViolinFaceColor = source.Value;
        end

        OOPSData.Handles.SwarmPlot.ViolinFaceColor = OOPSData.Settings.SwarmPlotViolinFaceColor;
    end

    function SwarmPlotViolinEdgeColorModeChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.ViolinEdgeColorMode = source.Value;
        UpdateImages(source);
    end

    function SwarmPlotViolinEdgeColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.SwarmPlotSettings.ViolinEdgeColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.SwarmPlotSettings.ViolinEdgeColor = source.Value;
        end

        OOPSData.Handles.SwarmPlot.ViolinEdgeColor = OOPSData.Settings.SwarmPlotViolinEdgeColor;
    end

    function SwarmPlotViolinsVisibleChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.ViolinsVisible = source.Value;
        OOPSData.Handles.SwarmPlot.ViolinOutlinesVisible = OOPSData.Settings.SwarmPlotViolinsVisible;
    end

    function SwarmPlotMarkerEdgeColorModeChanged(source,~)
        OOPSData.Settings.SwarmPlotSettings.MarkerEdgeColorMode = source.Value;
        UpdateImages(source);
    end

    function SwarmPlotMarkerEdgeColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.SwarmPlotSettings.MarkerEdgeColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.SwarmPlotSettings.MarkerEdgeColor = source.Value;
        end

        OOPSData.Handles.SwarmPlot.MarkerEdgeColor = OOPSData.Settings.SwarmPlotMarkerEdgeColor;
    end

%% Scatter plot callbacks/settings

    function CopyScatterPlotVector(source,~)
        UpdateLog3(source,'Copying...','append');
        copygraphics(OOPSData.Handles.ScatterPlotAxH,...
            'ContentType','vector',...
            'BackgroundColor',OOPSData.Settings.ScatterPlotBackgroundColor);
        UpdateLog3(source,'Scatter plot vector graphic copied to clipboard','append');
    end

    function ScatterPlotColorModeChanged(source,~)
        OOPSData.Settings.ScatterPlotSettings.ColorMode = source.Value;
        UpdateImages(source);
    end

    function ScatterPlotMarkerFaceAlphaChanged(source,~)
        OOPSData.Settings.ScatterPlotSettings.MarkerFaceAlpha = source.Value;
        set(OOPSData.Handles.hScatterPlot,'MarkerFaceAlpha',OOPSData.Settings.ScatterPlotSettings.MarkerFaceAlpha);
    end

    function ScatterPlotMarkerSizeChanged(source,~)
        OOPSData.Settings.ScatterPlotSettings.MarkerSize = source.Value;
        set(OOPSData.Handles.hScatterPlot,'SizeData',OOPSData.Settings.ScatterPlotSettings.MarkerSize);
    end

    function ScatterPlotBackgroundColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.ScatterPlotSettings.BackgroundColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.ScatterPlotSettings.BackgroundColor = source.Value;
        end
        OOPSData.Handles.ScatterPlotAxH.Color = OOPSData.Settings.ScatterPlotBackgroundColor;
        OOPSData.Handles.ScatterPlotGrid.BackgroundColor = OOPSData.Settings.ScatterPlotBackgroundColor;
        OOPSData.Handles.ScatterPlotLegend.Color = OOPSData.Settings.ScatterPlotBackgroundColor;
    end

    function ScatterPlotForegroundColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.ScatterPlotSettings.ForegroundColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.ScatterPlotSettings.ForegroundColor = source.Value;
        end
        OOPSData.Handles.ScatterPlotAxH.XAxis.Color = OOPSData.Settings.ScatterPlotForegroundColor;
        OOPSData.Handles.ScatterPlotAxH.YAxis.Color = OOPSData.Settings.ScatterPlotForegroundColor;
        OOPSData.Handles.ScatterPlotLegend.TextColor = OOPSData.Settings.ScatterPlotForegroundColor;
    end

    function ScatterPlotLegendVisibleChanged(source,~)
        OOPSData.Settings.ScatterPlotSettings.LegendVisible = source.Value;
        OOPSData.Handles.ScatterPlotLegend.Visible = source.Value;
    end

    function ScatterPlotVariablesChanged(source,~)
        OOPSData.Settings.ScatterPlotSettings.(source.Tag) = source.Value;
        if strcmp(OOPSData.Settings.CurrentTab,'Plots')
            UpdateImages(source);
        end
    end

%% Object intensity profile callbacks/settings

    function CopyObjectIntensityPlotVector(source,~)
        UpdateLog3(source,'Copying...','append');
        copygraphics(OOPSData.Handles.ObjectIntensityPlotAxH,...
            'ContentType','vector',...
            'BackgroundColor',OOPSData.Settings.ObjectIntensityProfileBackgroundColor);
        UpdateLog3(source,'Object intensity plot vector graphic copied to clipboard','append');
    end

    function ObjectIntensityProfileBackgroundColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.ObjectIntensityProfileSettings.BackgroundColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.ObjectIntensityProfileSettings.BackgroundColor = source.Value;
        end
        OOPSData.Handles.ObjectIntensityPlotAxH.Color = OOPSData.Settings.ObjectIntensityProfileBackgroundColor;
        %OOPSData.Handles.ObjectIntensityProfileGrid.BackgroundColor = OOPSData.Settings.ObjectIntensityProfileBackgroundColor;
        OOPSData.Handles.ImgPanel2.BackgroundColor = OOPSData.Settings.ObjectIntensityProfileBackgroundColor;
    end

    function ObjectIntensityProfileForegroundColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.ObjectIntensityProfileSettings.ForegroundColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.ObjectIntensityProfileSettings.ForegroundColor = source.Value;
        end
        OOPSData.Handles.ObjectIntensityPlotAxH.XAxis.Color = OOPSData.Settings.ObjectIntensityProfileForegroundColor;
        OOPSData.Handles.ObjectIntensityPlotAxH.YAxis.Color = OOPSData.Settings.ObjectIntensityProfileForegroundColor;
    end

    function ObjectIntensityProfileFitLineColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.ObjectIntensityProfileSettings.FitLineColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.ObjectIntensityProfileSettings.FitLineColor = source.Value;
        end
        UpdateImages(source,{'Objects'});
    end

    function ObjectIntensityProfilePixelLinesColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.ObjectIntensityProfileSettings.PixelLinesColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.ObjectIntensityProfileSettings.PixelLinesColor = source.Value;
        end
        UpdateImages(source,{'Objects'});
    end

    function ObjectIntensityProfileAnnotationsColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.ObjectIntensityProfileSettings.AnnotationsColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.ObjectIntensityProfileSettings.AnnotationsColor = source.Value;
        end
        UpdateImages(source,{'Objects'});
    end

    function ObjectIntensityProfileAzimuthLinesColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.ObjectIntensityProfileSettings.AzimuthLinesColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.ObjectIntensityProfileSettings.AzimuthLinesColor = source.Value;
        end
        UpdateImages(source,{'Objects'});
    end

    function SaveObjectIntensityProfileSettings(source,~)
        UpdateLog3(source,'Saving object intensity profile settings...','append');
        ObjectIntensityProfileSettings = OOPSData.Settings.ObjectIntensityProfileSettings;
        if ismac || isunix
            CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'/');
            save([SavePath,'/user_settings/ObjectIntensityProfileSettings.mat'],'ObjectIntensityProfileSettings');        
        elseif ispc
            CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'\');
            save([SavePath,'\user_settings\ObjectIntensityProfileSettings.mat'],'ObjectIntensityProfileSettings');        
        end
        UpdateLog3(source,'Done.','append');
    end

%% Polar histogram callbacks/settings

    function PolarHistogramnBinsChanged(source,~)
        OOPSData.Settings.PolarHistogramSettings.nBins = source.Value;
        OOPSData.Handles.ImagePolarHistogram.nBins = source.Value;
        OOPSData.Handles.GroupPolarHistogram.nBins = source.Value;
    end

    function PolarHistogramWedgeFaceAlphaChanged(source,~)
        OOPSData.Settings.PolarHistogramSettings.WedgeFaceAlpha = source.Value;
        OOPSData.Handles.ImagePolarHistogram.wedgeFaceAlpha = source.Value;
        OOPSData.Handles.GroupPolarHistogram.wedgeFaceAlpha = source.Value;
    end

    function PolarHistogramWedgeFaceColorChanged(source,~)
        OOPSData.Settings.PolarHistogramSettings.WedgeFaceColor = source.Value;
        OOPSData.Handles.ImagePolarHistogram.wedgeFaceColor = source.Value;
        OOPSData.Handles.GroupPolarHistogram.wedgeFaceColor = source.Value;
    end

    function PolarHistogramWedgeLineWidthChanged(source,~)
        OOPSData.Settings.PolarHistogramSettings.WedgeLineWidth = source.Value;
        OOPSData.Handles.ImagePolarHistogram.wedgeLineWidth = source.Value;
        OOPSData.Handles.GroupPolarHistogram.wedgeLineWidth = source.Value;
    end

    function PolarHistogramWedgeEdgeColorChanged(source,~)
        OOPSData.Settings.PolarHistogramSettings.WedgeEdgeColor = source.Value;
        switch source.Value
            case 'flat'
                OOPSData.Handles.PolarHistogramLineColorDropdown.Enable = 'off';
            case 'interp'
                OOPSData.Handles.PolarHistogramLineColorDropdown.Enable = 'on';
        end
        OOPSData.Handles.ImagePolarHistogram.wedgeEdgeColor = source.Value;
        OOPSData.Handles.GroupPolarHistogram.wedgeEdgeColor = source.Value;
    end

    function PolarHistogramWedgeLineColorChanged(source,~)
        % if isempty(source.Value)
        %     % then open the colorpicker to choose a color
        %     OOPSData.Settings.PolarHistogramSettings.WedgeLineColor = uisetcolor();
        %     figure(OOPSData.Handles.fH);
        % else
        %     OOPSData.Settings.PolarHistogramSettings.WedgeLineColor = source.Value();
        % end

        OOPSData.Settings.PolarHistogramSettings.WedgeLineColor = source.Value();

        OOPSData.Handles.ImagePolarHistogram.wedgeLineColor = OOPSData.Settings.PolarHistogramSettings.WedgeLineColor;
        OOPSData.Handles.GroupPolarHistogram.wedgeLineColor = OOPSData.Settings.PolarHistogramSettings.WedgeLineColor;
    end

    function PolarHistogramGridlinesColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.PolarHistogramSettings.GridlinesColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.PolarHistogramSettings.GridlinesColor = source.Value();
        end
        OOPSData.Handles.ImagePolarHistogram.rGridlinesColor = OOPSData.Settings.PolarHistogramSettings.GridlinesColor;
        OOPSData.Handles.ImagePolarHistogram.thetaGridlinesColor = OOPSData.Settings.PolarHistogramSettings.GridlinesColor;
        OOPSData.Handles.GroupPolarHistogram.rGridlinesColor = OOPSData.Settings.PolarHistogramSettings.GridlinesColor;
        OOPSData.Handles.GroupPolarHistogram.thetaGridlinesColor = OOPSData.Settings.PolarHistogramSettings.GridlinesColor;

    end

    function PolarHistogramLabelsColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.PolarHistogramSettings.LabelsColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.PolarHistogramSettings.LabelsColor = source.Value();
        end
        OOPSData.Handles.ImagePolarHistogram.thetaLabelsColor = OOPSData.Settings.PolarHistogramSettings.LabelsColor;
        OOPSData.Handles.GroupPolarHistogram.thetaLabelsColor = OOPSData.Settings.PolarHistogramSettings.LabelsColor;
    end

    function PolarHistogramGridlinesLineWidthChanged(source,~)
        OOPSData.Settings.PolarHistogramSettings.GridlinesLineWidth = source.Value;
        OOPSData.Handles.ImagePolarHistogram.rGridlinesLineWidth = source.Value;
        OOPSData.Handles.ImagePolarHistogram.thetaGridlinesLineWidth = source.Value;
        OOPSData.Handles.GroupPolarHistogram.rGridlinesLineWidth = source.Value;
        OOPSData.Handles.GroupPolarHistogram.thetaGridlinesLineWidth = source.Value; 
    end

    function PolarHistogramCircleColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.PolarHistogramSettings.CircleColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.PolarHistogramSettings.CircleColor = source.Value();
        end
        OOPSData.Handles.ImagePolarHistogram.circleColor = OOPSData.Settings.PolarHistogramSettings.CircleColor;
        OOPSData.Handles.GroupPolarHistogram.circleColor = OOPSData.Settings.PolarHistogramSettings.CircleColor;
    end

    function PolarHistogramCircleBackgroundColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.PolarHistogramSettings.CircleBackgroundColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.PolarHistogramSettings.CircleBackgroundColor = source.Value();
        end
        OOPSData.Handles.ImagePolarHistogram.circleBackgroundColor = OOPSData.Settings.PolarHistogramSettings.CircleBackgroundColor;
        OOPSData.Handles.GroupPolarHistogram.circleBackgroundColor = OOPSData.Settings.PolarHistogramSettings.CircleBackgroundColor;
    end

    function PolarHistogramBackgroundColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.PolarHistogramSettings.BackgroundColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.PolarHistogramSettings.BackgroundColor = source.Value();
        end
        OOPSData.Handles.ImagePolarHistogram.BackgroundColor = OOPSData.Settings.PolarHistogramSettings.BackgroundColor;
        OOPSData.Handles.GroupPolarHistogram.BackgroundColor = OOPSData.Settings.PolarHistogramSettings.BackgroundColor;
    end

    function PolarHistogramVariableChanged(source,~)
        OOPSData.Settings.PolarHistogramSettings.Variable = source.Value;
        UpdateImages(source,{'Polar Plots'});
        return
    end

%% Azimuth stick plot callbacks/settings

    function AzimuthDisplaySettingsChanged(source,~)
        % set the variable specified by the Tag property of the calling object
        OOPSData.Settings.AzimuthDisplaySettings.(source.Tag) = source.Value;

        if strcmp(OOPSData.Settings.CurrentTab,'Azimuth')
            % update the azimuth stick overlay
            UpdateAzimuthStickOverlay(source);
        end
    end

    function AzimuthObjectMaskChanged(source,~)

        if OOPSData.Settings.AzimuthObjectMask

            selection = uiconfirm(OOPSData.Handles.fH,...
                'Plotting azimuth sticks for each pixel is slow and can cause performance issues. Do you wish to continue?',...
                'Confirm azimuth overlay mode',...
                'Options',{'Continue','Cancel'},...
                'Icon','warning',...
                'DefaultOption',2,...
                'CancelOption',2);
    
            switch selection
                case 'Continue'
                    OOPSData.Settings.AzimuthDisplaySettings.ObjectMask = false;
                case 'Cancel'
                    OOPSData.Settings.AzimuthDisplaySettings.ObjectMask = true;
            end
        else
            OOPSData.Settings.AzimuthDisplaySettings.ObjectMask = true;
        end
        source.Value = OOPSData.Settings.AzimuthObjectMask;

        if strcmp(OOPSData.Settings.CurrentTab,'Azimuth')
            % update the azimuth stick overlay
            UpdateAzimuthStickOverlay(source);
        end
    end
    
%% Object azimuth stick plot callbacks/settings

    function ObjectAzimuthDisplaySettingsChanged(source,~)
        % set the variable specified by the Tag property of the calling object
        OOPSData.Settings.ObjectAzimuthDisplaySettings.(source.Tag) = source.Value;
        UpdateImages(source,{'Objects'});
    end

%% Object selection settings

    function ObjectSelectionSettingsChanged(source,~)
        % set the variable specified by the Tag property of the calling object
        OOPSData.Settings.ObjectSelectionSettings.(source.Tag) = source.Value;
        UpdateObjectBoxes(source);
    end

    function ObjectSelectionColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.ObjectSelectionSettings.Color = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.ObjectSelectionSettings.Color = source.Value;
        end
        UpdateObjectBoxes(source);
    end

%% Colormaps settings

    function ImageTypeSelectionChanged(source,~)
        ImageTypeName = source.Value;
        OOPSData.Handles.ColormapsSelector.Value = OOPSData.Settings.ColormapsSettings.(ImageTypeName).Name;
        OOPSData.Handles.ExampleColormapAx.Colormap = OOPSData.Settings.ColormapsSettings.(ImageTypeName).Map;
    end

    function ColormapSelectionChanged(source,~)
        % determine what type of image we are changing the colormap for
        ImageTypeName = OOPSData.Handles.ColormapsImageTypeDropdown.Value;
        % from the colormap name selected in the listbox, get the corresponding 'customColormap'
        selectedMap = OOPSData.Settings.Colormaps.(source.Value);
        % update the ColorMaps settings in OOPSSettings
        OOPSData.Settings.ColormapsSettings.(ImageTypeName) = selectedMap;
        % apply the map to the example colormap image
        OOPSData.Handles.ExampleColormapAx.Colormap = selectedMap.Map;
        % update the relevant gui objects with the new map 
        UpdateColormaps(ImageTypeName);
    end

    function UpdateColormaps(ImageTypeName)

        switch ImageTypeName

            case 'Intensity'
                IntensityMap = OOPSData.Settings.IntensityColormap;
                OOPSData.Handles.AverageIntensityAxH.Colormap = IntensityMap;
                [OOPSData.Handles.FFCAxH.Colormap] = deal(IntensityMap);
                [OOPSData.Handles.RawIntensityAxH.Colormap] = deal(IntensityMap);
                [OOPSData.Handles.PolFFCAxH.Colormap] = deal(IntensityMap);
                OOPSData.Handles.ObjectPolFFCAxH.Colormap = IntensityMap;
                OOPSData.Handles.ObjectNormIntStackAxH.Colormap = IntensityMap;
                OOPSData.Handles.ObjectAzimuthOverlayAxH.Colormap = IntensityMap;
                if ~isempty(OOPSData.CurrentImage)
                    if OOPSData.CurrentImage(1).ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value
                        UpdateCompositeRGB();
                    end
                end
            case 'Order'
                OrderMap = OOPSData.Settings.OrderColormap;
                OOPSData.Handles.OrderAxH.Colormap = OrderMap;
                OOPSData.Handles.ObjectOrderAxH.Colormap = OrderMap;
                OOPSData.Handles.CustomStatAxH.Colormap = OrderMap;
                if (~isempty(OOPSData.CurrentImage) && ...
                       OOPSData.Handles.ShowAsOverlayOrder.Value && ...
                       strcmp(OOPSData.Settings.CurrentTab,'Order'))
                    UpdateImages(OOPSData.Handles.fH);
                end
            case 'Reference'
                if ~isempty(OOPSData.CurrentImage)
                    if OOPSData.CurrentImage(1).ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value
                        UpdateCompositeRGB();
                    end
                end
            case 'Azimuth'
                AzimuthMap = OOPSData.Settings.AzimuthColormap;
%                 % test below (making uniform cyclic colormap)
%                  AzimuthMap = MakeCircularColormap(AzimuthMap);
%                 % end test
                OOPSData.Handles.AzimuthAxH.Colormap = vertcat(AzimuthMap,AzimuthMap);


                % OOPSData.Handles.PhaseBarAxH.Colormap = vertcat(AzimuthMap,AzimuthMap);
                OOPSData.Handles.AzimuthColorbar.Colormap = vertcat(AzimuthMap,AzimuthMap);

                if strcmp(OOPSData.Settings.CurrentTab,'Azimuth') && ...
                        strcmp(OOPSData.Settings.AzimuthColorMode,'Direction')
                    UpdateImages(OOPSData.Handles.fH);
                end
        end

    end

%% Palettes settings

    function PaletteTypeSelectionChanged(source,~)
        PaletteTypeName = source.Value;
        OOPSData.Handles.PalettesSelector.Value = OOPSData.Settings.PalettesSettings.(PaletteTypeName).Name;
        OOPSData.Handles.ExamplePaletteAx.Colormap = OOPSData.Settings.PalettesSettings.(PaletteTypeName).Colors;
    end

    function PaletteSelectionChanged(source,~)
        % determine what type of image we are changing the colormap for
        PaletteTypeName = OOPSData.Handles.PalettesTypeDropdown.Value;
        % from the colormap name selected in the listbox, get the corresponding 'customColormap'
        selectedPalette = OOPSData.Settings.Palettes.(source.Value);
        % update the ColorMaps settings in OOPSSettings
        OOPSData.Settings.PalettesSettings.(PaletteTypeName) = selectedPalette;
        % apply the map to the example colormap image
        OOPSData.Handles.ExamplePaletteAx.Colormap = selectedPalette.Colors;
        % update the relevant gui objects with the new map 
        UpdatePalettes(source,PaletteTypeName);
    end

    function UpdatePalettes(source,PaletteTypeName)
        switch PaletteTypeName
            case 'Group'
                OOPSData.UpdateGroupColors();
                UpdateGroupTree(source);
                UpdateSummaryDisplay(source,{'Group'});
                UpdateImages(source,{'Plots'});
            case 'Label'
                OOPSData.Settings.UpdateLabelColors();
                UpdateLabelTree(source);
                UpdateSummaryDisplay(source,{'Label','Object'});
                UpdateImages(source,{'Plots','Mask','Order','Objects'});
        end
    end

%% Labels settings

    function LabelTreeNodeTextChanged(~,event)
        event.Node.NodeData.Name = event.Node.Text;
    end

    function DeleteLabel(source,~,fH)
        % get the selected nodes (to delete)
        SelectedNodes = OOPSData.Handles.LabelTree.SelectedNodes;
        % if no nodes in the tree are truly 'selected', get the right-clicked node instead
        if numel(SelectedNodes)==0
            SelectedNodes = fH.CurrentObject;
        end
        % handle possible error (we always need at least one label)
        if OOPSData.Settings.nLabels==1 || OOPSData.Settings.nLabels == numel(SelectedNodes)
            uialert(OOPSData.Handles.fH,'There must be at least one object label','Error');
            return
        end

        % loop through and delete the labels corresponding to each node
        for NodeIdx = 1:numel(SelectedNodes)
            % get the next label
            cLabel = SelectedNodes(NodeIdx).NodeData;
            % update log to indicate progress for each label
            UpdateLog3(fH,['Deleting [Label:',cLabel.Name,']...'],'append');
            % before deleting the label, we need to check for any objects that would end up unlabeled
            ObjectsWithOldLabel = OOPSData.getObjectsByLabel(cLabel);
            % delete the old label
            OOPSData.Settings.DeleteObjectLabel(cLabel);
            % add new label to the now unlabeled objects, if necessary
            if ~isempty(ObjectsWithOldLabel)
                UpdateLog3(fH,[num2str(numel(ObjectsWithOldLabel)),' objects affected. Reassigning default label...'],'append');
                % empty label object
                % DefaultLabel = OOPSLabel.empty();


                DefaultLabel = OOPSData.Settings.DefaultLabel;


                % chack if the default label exists
                for LabelIdx = 1:numel(OOPSData.Settings.ObjectLabels)
                    Label = OOPSData.Settings.ObjectLabels(LabelIdx);
                    if strcmp(Label.Name,'Default')
                        DefaultLabel = Label;
                        break
                    end
                end
                % if default label not found...
                if isempty(DefaultLabel)

                    OOPSData.Settings.restoreDefaultLabel();
                    DefaultLabel = OOPSData.Settings.DefaultLabel;


                    % % create a new default label
                    % OOPSData.Settings.AddNewObjectLabel(...
                    %     'Default',...
                    %     distinguishable_colors(1,OOPSData.Settings.LabelColors));
                    % DefaultLabel = OOPSData.Settings.ObjectLabels(end);
                end
                % add the new label to each of the unlabeled objects
                [ObjectsWithOldLabel(:).Label] = deal(DefaultLabel);
            end

        end

        % update palette colors
        UpdatePalettes(source,'Label');
        UpdateLabelTree(source);
        UpdateImages(source);
        UpdateLog3(fH,'Done.','append');
    end

    function DeleteLabelAndObjects(source,~,fH)
        % get the selected nodes (to delete)
        SelectedNodes = OOPSData.Handles.LabelTree.SelectedNodes;
        % if no nodes in the tree are truly 'selected', get the right-clicked node instead
        if numel(SelectedNodes)==0
            SelectedNodes = fH.CurrentObject;
        end
        % handle possible error (we always need at least one label)
        if OOPSData.Settings.nLabels==1 || OOPSData.Settings.nLabels == numel(SelectedNodes)
            uialert(OOPSData.Handles.fH,'There must be at least one object label','Error');
            return
        end

        % loop through and delete the labels corresponding to each node
        for NodeIdx = 1:numel(SelectedNodes)
            % get the label to delete
            cLabel = SelectedNodes(NodeIdx).NodeData;
            % update log to indicate progress for each label
            UpdateLog3(fH,['Deleting [Label:',cLabel.Name,']...'],'append');
            % before deleting the label, get all objects with this label to indicate how will be deleted
            ObjectsWithOldLabel = OOPSData.getObjectsByLabel(cLabel);
            % if any objects found, delete them and update the log
            if ~isempty(ObjectsWithOldLabel)
                UpdateLog3(fH,['Deleting ',num2str(numel(ObjectsWithOldLabel)),' objects...'],'append');
                OOPSData.DeleteObjectsByLabel(cLabel);
            else
                UpdateLog3(fH,'No objects deleted.','append');
            end
            % delete the label
            OOPSData.Settings.DeleteObjectLabel(cLabel);
        end
        % update the display
        % update palette colors
        UpdatePalettes(source,'Label');
        UpdateLabelTree(source);
        UpdateImages(source);
        UpdateLog3(fH,'Done.','append');
    end

    function ApplyLabelToSelectedObjects(source,~,fH)
        % get the node that was right-clicked
        SelectedNode = fH.CurrentObject;
        % get the label we are going to apply to the objects
        cLabel = SelectedNode.NodeData;
        % number of selected objects
        nSelected = OOPSData.nSelected;
        % apply the label to any selected objects
        OOPSData.LabelSelectedObjects(cLabel);
        % update display area
        UpdateImages(source);
        % update label tree
        UpdateLabelTree(source);
        % update summary panel
        UpdateSummaryDisplay(source,{'Object'});
        % update log
        UpdateLog3(fH,[num2str(nSelected),' objects added to ',cLabel.Name],'append');
    end

    function SelectLabeledObjects(source,~,fH)
        % get the selected nodes
        SelectedNodes = OOPSData.Handles.LabelTree.SelectedNodes;
        % if no nodes in the tree are truly 'selected', get the right-clicked node instead
        if numel(SelectedNodes)==0
            SelectedNodes = fH.CurrentObject;
        end
        % number selected before selection
        nSelectedBefore = OOPSData.nSelected;
        % select the objects for each label
        for NodeIdx = 1:numel(SelectedNodes)
            % get the label associated with the node
            cLabel = SelectedNodes(NodeIdx).NodeData;
            % select all objects with the label
            OOPSData.SelectObjectsByLabel(cLabel);
        end
        % number selected after selection
        nSelectedAfter = OOPSData.nSelected;
        % new objects added to the selection
        newNSelected = nSelectedAfter-nSelectedBefore;
        % update display area
        UpdateImages(source);
        % update summary panel
        UpdateSummaryDisplay(source,{'Object'});
        % update log
        UpdateLog3(source,[num2str(newNSelected),' objects added to selection. Total selected: ',num2str(nSelectedAfter)],'append');
    end

    function MergeLabels(source,~,fH)
        % get the selected nodes
        SelectedNodes = OOPSData.Handles.LabelTree.SelectedNodes;
        % get the node that was right-clicked
        ClickedNode = fH.CurrentObject;
        % deal with some potential errors
        if ~ismember(ClickedNode,SelectedNodes)
            uialert(OOPSData.Handles.fH,'You can only merge labels into a selected label. Select the label and try again.','Error');
            return
        end
        if ~(numel(SelectedNodes)>=2)
            uialert(OOPSData.Handles.fH,'Merging object labels requires at least 2 selected labels.','Error');
            return
        end
        % get the label that other labels will be merged into
        LabelToMergeInto = ClickedNode.NodeData;
        % for each of the selected nodes
        for NodeIdx = 1:numel(SelectedNodes)
            % get the label corresponding to the node
            cLabel = SelectedNodes(NodeIdx).NodeData;
            % then, as long as it is not the label we are merging into
            if cLabel ~= LabelToMergeInto
                % replace any objects labeled with cLabel with label we want to merge into
                OOPSData.SwapObjectLabels(cLabel,LabelToMergeInto);
                % and delete the old label
                OOPSData.Settings.DeleteObjectLabel(cLabel);
            end
        end
        UpdateLabelTree(source);
        UpdateImages(source);
        UpdateLog3(fH,'Done.','append');
    end

    function AddNewLabel(source,~)
        OOPSData.Settings.AddNewObjectLabel([],[]);
        NewLabel = OOPSData.Settings.ObjectLabels(end);
        newNode = uitreenode(OOPSData.Handles.LabelTree,...
            'Text',NewLabel.Name,...
            'NodeData',NewLabel,...
            'Icon',makeRGBColorSquare(NewLabel.Color,5));
        newNode.ContextMenu = OOPSData.Handles.LabelContextMenu;

        % update palette colors
        UpdatePalettes(source,'Label');
    end

    function EditLabelColor(source,~,fH)
        SelectedNode = fH.CurrentObject;
        cLabel = SelectedNode.NodeData;
        cLabel.Color = uisetcolor();
        figure(fH);
        SelectedNode.Icon = makeRGBColorSquare(cLabel.Color,1);

        UpdateImages(source);
%         if strcmp(OOPSData.Settings.CurrentTab,'Plots')
%             UpdateImages(source);
%         end
    end

%% Cluster settings

    function ClusterVariablesChanged(source,~)
        OOPSData.Settings.ClusterSettings.VariableList = {};
        if isempty(source.CheckedNodes)
            return
            %OOPSData.Settings.ClusterSettings.VariableList = {};
        else
            [OOPSData.Settings.ClusterSettings.VariableList{1,1:numel(source.CheckedNodes)}] = deal(source.CheckedNodes.NodeData);
        end
    end

    function ClusterSettingsChanged(source,~)
        % get the variable from the Tag property of the calling object
        varName = source.Tag;
        % set the specified property
        OOPSData.Settings.ClusterSettings.(varName) = source.Value;
        % enable or disable components depending on nClustersMode
        if strcmp(varName,'nClustersMode')
            OOPSData.Handles.ClusterCriterionDropdown.Enable = strcmp(OOPSData.Settings.ClusternClustersMode,'Auto');
            OOPSData.Handles.ClusternClustersEditfield.Enable = strcmp(OOPSData.Settings.ClusternClustersMode,'Manual');
        end
    end

%% GUI settings

    function GUIColorsChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.GUISettings.(source.Tag) = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.GUISettings.(source.Tag) = source.Value;
        end
        % update the GUI theme
        UpdateGUITheme(source);
    end

    function GUIFontSizeChanged(source,~)
        % store the FontSize in GUISettings structure
        OOPSData.Settings.GUISettings.FontSize = source.Value;
        % adjust the font size across the board for all non-custom objects
        fontsize(OOPSData.Handles.fH,OOPSData.Settings.GUIFontSize,'pixels');
        % now adjust the font size for the settings accordion
        OOPSData.Handles.SettingAccordion.FontSize = OOPSData.Settings.GUIFontSize;
        % update the GUI summary display panel
        UpdateSummaryDisplay(source,{'Project'});
    end

%% Callbacks controlling dynamic resizing of GUI containers

    function ResetContainerSizes(source,~)
        %disp('Figure Window Size Changed...');
        SmallWidth = round((source.InnerPosition(3)*0.38)/2);

        % update grid size to match new image sizes
        set(OOPSData.Handles.MainGrid,...
            'RowHeight',{'1x',SmallWidth,SmallWidth,'1x'},...
            'ColumnWidth',{'1x',SmallWidth,SmallWidth,SmallWidth,SmallWidth});

        %drawnow limitrate
        drawnow
    end

%% Callbacks for interactive thresholding

    % Set figure callbacks WindowButtonMotionFcn and WindowButtonUpFcn
    function StartUserThresholding(~,~)
        OOPSData.Handles.fH.WindowButtonMotionFcn = @MoveThresholdLine;
        OOPSData.Handles.fH.WindowButtonUpFcn = @StopMovingAndSetThresholdLine;
    end

    % Update display while thresh line is moving
    function MoveThresholdLine(source,~)
        xPosition = round(OOPSData.Handles.ThreshAxH.CurrentPoint(1,1),4);
        OOPSData.Handles.CurrentThresholdLine.Value = xPosition;
        OOPSData.Handles.CurrentThresholdLine.Label = {[OOPSData.CurrentImage(1).ThreshStatisticName,' = ',num2str(OOPSData.Handles.CurrentThresholdLine.Value)]};

        % set the position of the line label
        switch xPosition > 0.5
            case true
                OOPSData.Handles.CurrentThresholdLine.LabelHorizontalAlignment = "left";
            case false
                OOPSData.Handles.CurrentThresholdLine.LabelHorizontalAlignment = "right";
        end

        ThresholdLineMoving(source,OOPSData.Handles.CurrentThresholdLine.Value);
    end

    % Set final thresh position and restore callbacks
    function StopMovingAndSetThresholdLine(source,~)
        OOPSData.Handles.fH.WindowButtonMotionFcn = '';
        OOPSData.Handles.fH.WindowButtonUpFcn = '';
        xPosition = round(OOPSData.Handles.ThreshAxH.CurrentPoint(1,1),4);
        OOPSData.Handles.CurrentThresholdLine.Value = xPosition;
        OOPSData.Handles.CurrentThresholdLine.Label = {[OOPSData.CurrentImage(1).ThreshStatisticName,' = ',num2str(OOPSData.Handles.CurrentThresholdLine.Value)]};

        % set the position of the line label
        switch xPosition > 0.5
            case true
                OOPSData.Handles.CurrentThresholdLine.LabelHorizontalAlignment = "left";
            case false
                OOPSData.Handles.CurrentThresholdLine.LabelHorizontalAlignment = "right";
        end
        ThresholdLineMoved(source,OOPSData.Handles.CurrentThresholdLine.Value);
        drawnow
    end

%% Callbacks for intensity display scaling

    function AdjustPrimaryChannelIntensity(source,~)

        if isempty(OOPSData.CurrentImage)
            source.Value = [0 1];
            return
        end

        OOPSData.CurrentImage(1).PrimaryIntensityDisplayLimits = source.Value;

        if ismember(OOPSData.Settings.CurrentTab,[{'Mask','Order','Azimuth'},OOPSData.Settings.CustomStatisticDisplayNames.'])
            UpdateAverageIntensityImage(source);
            % if OOPSData.CurrentImage(1).ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value
            %     % UpdateCompositeRGB();
            %     UpdateAverageIntensityImage(source);
            % else
            %     UpdateAverageIntensityImage(source);
            % end
        end

        switch OOPSData.Settings.CurrentTab
            case 'Order'
                if OOPSData.Handles.ShowAsOverlayOrder.Value
                    UpdateOrderImage(source);
                end
            case 'Azimuth'
                if OOPSData.Handles.ShowAsOverlayAzimuth.Value || OOPSData.Handles.ShowAzimuthHSVOverlayAzimuth.Value
                    UpdateAzimuthImage(source);
                end
            case OOPSData.Settings.CustomStatisticDisplayNames.'
                if OOPSData.Handles.ShowAsOverlayCustomStat.Value
                    UpdateCustomStatImage(source);
                end
        end

        drawnow limitrate

    end

    function AdjustReferenceChannelIntensity(source,~)

        % if no data exist for this image
        if isempty(OOPSData.CurrentImage)
            source.Value = [0 1];
            return
        end

        % if no reference image is loaded
        if ~OOPSData.CurrentImage(1).ReferenceImageLoaded
            source.Value = [0 1];
            return
        end

        OOPSData.CurrentImage(1).ReferenceIntensityDisplayLimits = source.Value;
        if OOPSData.CurrentImage(1).ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value
            UpdateAverageIntensityImage(source);
        end

        drawnow limitrate

    end

    function UpdateCompositeRGB()
        OOPSData.Handles.AverageIntensityImgH.CData = OOPSData.CurrentImage(1).UserScaledAverageIntensityReferenceCompositeRGB;
        OOPSData.Handles.AverageIntensityAxH.CLim = [0 1];
    end

    function AdjustOrderDisplayLimits(source,~)

        if isempty(OOPSData.CurrentImage)
            source.Value = [0 1];
            return
        end

        if ~OOPSData.CurrentImage(1).FPMStatsDone
            source.Value = [0 1];
            return
        end

        % if scale to max buttons are enabled for Order axes, disable it
        OOPSData.Handles.ScaleToMaxOrder.Value = false;
        OOPSData.Handles.ScaleToMaxAzimuth.Value = false;

        OOPSData.CurrentImage(1).OrderDisplayLimits = source.Value;

        switch OOPSData.Settings.CurrentTab
            case 'Order'
                UpdateOrderImage(source);
            case 'Azimuth'
                if OOPSData.Handles.ShowAzimuthHSVOverlayAzimuth.Value
                    UpdateAzimuthImage(source);
                end
        end

        drawnow limitrate

    end

    function AdjustCustomDisplayLimits(source,~)

        % get the name of the custom statistic corresponding to this slider
        cStatName = source.Tag;

        if isempty(OOPSData.CurrentImage)
            source.Value = [0 1];
            return
        else
            cImage = OOPSData.CurrentImage(1);
        end

        if ~cImage.FPMStatsDone
            source.Value = cImage.([cStatName,'DisplayRange']);
            return
        end

        % if scale to max buttons are enabled for CustomStat axes, disable it
        OOPSData.Handles.ScaleToMaxCustomStat.Value = false;

        cImage.([cStatName,'DisplayLimits']) = source.Value;

        % get the stat
        cStatIdx = ismember(OOPSData.Settings.CurrentTab,OOPSData.Settings.CustomStatisticDisplayNames);

        % if not found
        if ~cStatIdx
            return
        else
            cStat = OOPSData.Settings.CustomStatistics(cStatIdx);
        end

        if strcmp(OOPSData.Settings.CurrentTab,cStat.StatisticDisplayName)
            UpdateCustomStatImage(source);
        end

        drawnow limitrate

    end

%% Setting axes properties during startup (to be eventually replaced with custom container classes)

    function [axH] = restore_axis_defaults(axH,OriginalPlotBoxAspectRatio,OriginalTag)
        % restore axis defaults that were changed by imshow()
        axH.YDir = 'reverse';
        axH.PlotBoxAspectRatio = OriginalPlotBoxAspectRatio;
        axH.PlotBoxAspectRatioMode = 'manual';
        axH.XTick = [];
        axH.YTick = [];
        axH.Tag = OriginalTag;
        % create a custom toolbar for the axes
        tb = axtoolbar(axH,{});
        % clear all of the default interactions
        axH.Interactions = [];
        % add relevant custom toolbars to specific axes
        switch axH.Tag
            case 'Mask'
                addZoomToCursorToolbarBtn;
                addShowSelectionToolbarBtn;
                addLassoROIToolbarBtn;
            case 'Order'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
                addLineScanToolbarBtn;
                addExportAxesToolbarBtn;
                addShowAsOverlayToolbarBtn;
                addShowColorbarToolbarBtn;
                addScaleToMaxToolbarBtn;
            case 'AverageIntensity'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
                addShowSelectionToolbarBtn;
                addLassoROIToolbarBtn;
                addShowReferenceImageToolbarBtn;
                addLineScanToolbarBtn;
                addShowColorbarToolbarBtn;
                addExportAxesToolbarBtn;
            case 'Azimuth'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
                addShowAsOverlayToolbarBtn;
                addShowAzimuthHSVOverlayToolbarBtn;
                addShowColorbarToolbarBtn;
                addScaleToMaxToolbarBtn;
                addExportAxesToolbarBtn;
            case 'ObjectAzimuthOverlay'
                addExportAxesToolbarBtn;
            case 'CustomStat'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
                addShowAsOverlayToolbarBtn;
                addShowColorbarToolbarBtn;
                addScaleToMaxToolbarBtn;
        end
        
        function addZoomToCursorToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MagnifyingGlassIcon.png';
            btn.ValueChangedFcn = @ZoomToCursor;
            btn.Tag = ['ZoomToCursor',axH.Tag];
            btn.Tooltip = 'Zoom to cursor';
            OOPSData.Handles.(btn.Tag) = btn;            
        end
        
        function addApplyMaskToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MaskIcon.png';
            btn.ValueChangedFcn = @tbApplyMaskStateChanged;
            btn.Tag = ['ApplyMask',axH.Tag];
            btn.Tooltip = 'Apply mask';
            OOPSData.Handles.(btn.Tag) = btn;
        end
        
        function addShowSelectionToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ShowSelectionIcon.png';
            btn.ValueChangedFcn = @tbShowSelectionStateChanged;
            btn.Tag = ['ShowSelection',axH.Tag];
            btn.Tooltip = 'Show objects';
            OOPSData.Handles.(btn.Tag) = btn;
        end

        function addLassoROIToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'LassoToolIcon.png';
            btn.ButtonPushedFcn = @tbLassoROI;
            btn.Tag = ['LassoROI',axH.Tag];
            btn.Tooltip = 'Select objects (lasso)';
            OOPSData.Handles.(btn.Tag) = btn;
        end        
        
        function addShowReferenceImageToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ShowReferenceImageIcon.png';
            btn.ValueChangedFcn = @tbShowReferenceImageStateChanged;
            btn.Tag = ['ShowReferenceImage',axH.Tag];
            btn.Tooltip = 'Show reference image';
            OOPSData.Handles.(btn.Tag) = btn;
        end

        function addShowAsOverlayToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ShowReferenceImageIcon.png';
            btn.ValueChangedFcn = @tbShowAsOverlayStateChanged;
            btn.Tag = ['ShowAsOverlay',axH.Tag];
            btn.Tooltip = 'Intensity overlay';
            OOPSData.Handles.(btn.Tag) = btn;
        end

        function addShowAzimuthHSVOverlayToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ShowAzimuthHSVOverlayIcon.png';
            btn.ValueChangedFcn = @tbShowAzimuthHSVOverlayStateChanged;
            btn.Tag = ['ShowAzimuthHSVOverlay',axH.Tag];
            btn.Tooltip = 'Azimuth-Order-Intensity HSV overlay';
            OOPSData.Handles.(btn.Tag) = btn;
        end
        
        function addLineScanToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'LineScanIcon.png';
            btn.ButtonPushedFcn = @tbLineScan;
            btn.Tag = ['LineScan',axH.Tag];
            btn.Tooltip = 'Integrated linescan';
            OOPSData.Handles.(btn.Tag) = btn;
        end

        function addExportAxesToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'ExportAxesIcon.png';
            btn.ButtonPushedFcn = @tbExportAxes;
            btn.Tag = ['ExportAxes',axH.Tag];
            btn.Tooltip = 'Export image';
            OOPSData.Handles.(btn.Tag) = btn;
        end

        function addShowColorbarToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ChangeColorbarVisibilityIcon.png';
            btn.ValueChangedFcn = @tbShowColorbarStateChanged;
            btn.Tag = ['ShowColorbar',axH.Tag];
            btn.Tooltip = 'Show colorbar';
            OOPSData.Handles.(btn.Tag) = btn;
            btn.Value = 1;
        end
        
        function addScaleToMaxToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ScaleToMaxIcon.png';
            btn.ValueChangedFcn = @tbScaleToMaxStateChanged;
            btn.Tag = ['ScaleToMax',axH.Tag];
            btn.Tooltip = 'Scale to max';
            OOPSData.Handles.(btn.Tag) = btn;
            btn.Value = 1;
        end
    end

    function [axH] = SetAxisTitle(axH,title)
        % Set image (actually axis) title to top center of axis
        axH.Title.String = title;
        axH.Title.Units = 'Normalized';
        axH.Title.FontName = OOPSData.Settings.DefaultPlotFont;
        axH.Title.HorizontalAlignment = 'Center';
        axH.Title.VerticalAlignment = 'Top';
        axH.Title.Color = 'White';
        axH.Title.Position = [0.5,1.0,0];
        axH.Title.BackgroundColor = [0 0 0 0.5];
        axH.Title.HitTest = 'Off';
        axH.Title.PickableParts = 'none';
    end

%% 'Objects' menubar callbacks

    function mbSelectObjectsByProperty(source,~)
        filterSet = defineFilterSet(...
            OOPSData.Settings.ObjectPlotVariables,...
            OOPSData.Settings.ObjectPlotVariablesLong);

        if isempty(filterSet)
            return
        else
            nSelectedBefore = OOPSData.nSelected;
            OOPSData.selectObjectsByProperty(filterSet);
            nSelectedAfter = OOPSData.nSelected;
            newNSelected = nSelectedAfter-nSelectedBefore;
        end
        UpdateImages(source);
        UpdateLog3(source,[num2str(newNSelected),' objects added to selection. Total selected: ',num2str(nSelectedAfter)],'append');
    end

    function mbDeleteSelectedObjects(source,~)
        % number of total objects in the project
        nObjectsExisting = OOPSData.nObjects;
        % delete selected objects in project, group, or image
        switch source.Tag
            case 'Project'
                OOPSData.DeleteSelectedObjects();
            case 'Group'
                cGroup = OOPSData.CurrentGroup;
                cGroup.DeleteSelectedObjects();
            case 'Image'
                cImage = OOPSData.CurrentImage(1);
                cImage.DeleteSelectedObjects();
        end
        % number of objects deleted
        nObjectsDeleted = nObjectsExisting - OOPSData.nObjects;
        % update display
        UpdateImages(source);
        UpdateObjectListBox(source);
        UpdateSummaryDisplay(source,{'Group','Image','Object'});
        % update log with number deleted
        UpdateLog3(source,['Deleted ',num2str(nObjectsDeleted),' objects'],'append');
    end

    function mbClearSelection(source,~)
        % deselect objects in project, group, or image
        switch source.Tag
            case 'Project'
                OOPSData.ClearSelection();
            case 'Group'
                cGroup = OOPSData.CurrentGroup;
                cGroup.ClearSelection();
            case 'Image'
                cImage = OOPSData.CurrentImage(1);
                cImage.ClearSelection();
        end
        
        UpdateImages(source);
        UpdateObjectListBox(source);
        UpdateSummaryDisplay(source);
    end

    function mbObjectkmeansClustering(source,~)

        % get the cluster settings
        ClusterSettings = OOPSData.Settings.ClusterSettings;

        % if no variables selected, throw uialert error window
        if isempty(ClusterSettings.VariableList)
            uialert(OOPSData.Handles.fH,'No variables selected','Error');
            return
        end

        % gather data for all objects using user-specified variables from above
        objectData = OOPSData.getConcatenatedObjectData(ClusterSettings.VariableList);
        % minimum repeats per iteration to find the best solution (smallest combined sum)
        nRepeats = 10;

        try
            % call the main clustering function with the inputs above
            [ClusterIdxs,OptimalK] = OOPSObjectClustering(objectData,...
                ClusterSettings.nClusters,...
                nRepeats,...
                ClusterSettings.nClustersMode,...
                ClusterSettings.Criterion,...
                ClusterSettings.DistanceMetric,...
                ClusterSettings.NormalizationMethod,...
                ClusterSettings.DisplayEvaluation);
        catch ME
            msg = ME.message;
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        end
        
        % in case k was set automatically, adjust number of clusters to match
        nClusters = OptimalK;
        % delete the existing object labels
        CurrentLabels = OOPSData.Settings.ObjectLabels;
        for LabelIdx = 1:numel(CurrentLabels)
            OOPSData.Settings.DeleteObjectLabel(CurrentLabels(LabelIdx));
        end

        % create the new cluster labels
        for idx = 1:nClusters
            OOPSData.Settings.AddNewObjectLabel(['Cluster #',num2str(idx)],[]);
        end
        % add an additional label in case clustering failed for any obejcts
        if any(isnan(ClusterIdxs))
            OOPSData.Settings.AddNewObjectLabel('Clustering failed',[]);
        end


        % use the k-means clustering output to label each object with its cluster
        ObjCounter = 1;
        for g_idx = 1:OOPSData.nGroups
            for i_idx = 1:OOPSData.Group(g_idx).nReplicates
                for o_idx = 1:OOPSData.Group(g_idx).Replicate(i_idx).nObjects
                    try
                        OOPSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label = OOPSData.Settings.ObjectLabels(ClusterIdxs(ObjCounter));
                        ObjCounter = ObjCounter+1;
                    catch
                        OOPSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label = OOPSData.Settings.ObjectLabels(end);
                        ObjCounter = ObjCounter+1;
                    end
                end
            end
        end

        fH_ClusterProportions = uifigure(...
            'Name','Cluster proportions by group',...
            'HandleVisibility','on',...
            'WindowStyle','alwaysontop',...
            'Visible','off');

        barAx = uiaxes(...
            fH_ClusterProportions,...
            "Units","normalized",...
            "OuterPosition",[0 0 1 1]);

        labelCounts = OOPSData.labelCounts;
        normalizedLabelCounts = labelCounts./sum(labelCounts,2);
        barTitles = categorical({OOPSData.Group.GroupName});

        groupBars = bar(barAx,barTitles,normalizedLabelCounts,'stacked');

        set(groupBars,...
            {'FaceColor'},{OOPSData.Settings.ObjectLabels.Color}',...
            {'DisplayName'},{OOPSData.Settings.ObjectLabels.Name}');

        legend(barAx,'Location','eastoutside');

        % move window to the center of the screen
        movegui(fH_ClusterProportions,'center');
        % show the window
        fH_ClusterProportions.Visible = 'on';

        % update label selection tree and image/plot display
        UpdateLabelTree(source);
        UpdateImages(source);
    end

    function mbShowObjectImagesByLabel(~,~)

        fH_ObjectImages = uifigure(...
            'Name','Object images by label',...
            'HandleVisibility','on',...
            'WindowStyle','alwaysontop',...
            'AutoResizeChildren','Off');
        % grid layout object
        ObjectImagesGrid = uigridlayout(fH_ObjectImages,[1,1]);

        ObjImgTiles = cell(OOPSData.Settings.nLabels,1);

        % testing below - estimate grid width to form approximate square
        gridWidth = round(sqrt(OOPSData.nObjects));
        %

        for LabelIdx = 1:OOPSData.Settings.nLabels
            Objs = OOPSData.getObjectsByLabel(OOPSData.Settings.ObjectLabels(LabelIdx));
            ObjImgs = cell(numel(Objs),1);

            for ObjIdx = 1:numel(Objs)
                ObjImgs{ObjIdx} = Objs(ObjIdx).PaddedFFCIntensitySubImage();
                %ObjImgs{ObjIdx} = Objs(ObjIdx).OrderImageRGB();
            end
            
            % ObjImgTiles{LabelIdx,1} = imtile(ObjImgs,...
            %     'ThumbnailSize',[50 50],...
            %     'BorderSize',1,...
            %     'BackgroundColor',OOPSData.Settings.ObjectLabels(LabelIdx).Color,...
            %     'GridSize',[NaN 30]);

            % 'optimal' grid width to form approximate square
            % ObjImgTiles{LabelIdx,1} = imtile(ObjImgs,...
            %     'ThumbnailSize',[50 50],...
            %     'BorderSize',1,...
            %     'BackgroundColor',OOPSData.Settings.ObjectLabels(LabelIdx).Color,...
            %     'GridSize',[NaN gridWidth]);      

            ObjImgTiles{LabelIdx,1} = imtile(ObjImgs,...
                'ThumbnailSize',[50 50],...
                'BorderSize',1,...
                'BackgroundColor',OOPSData.Settings.ObjectLabels(LabelIdx).Color,...
                'GridSize',[NaN 40]);
        end

        ObjImgTilesCombined = cell2mat(ObjImgTiles);

        ObjImgTiles_hImg = imshow(ObjImgTilesCombined);

        MyScrollPanel = imscrollpanel(fH_ObjectImages,ObjImgTiles_hImg);

        hMagBox = immagbox(fH_ObjectImages,ObjImgTiles_hImg);
        hMagBoxpos = get(hMagBox,'Position');
        set(hMagBox,'Position',[0 0 hMagBoxpos(3) hMagBoxpos(4)])
        imoverview(ObjImgTiles_hImg)
    end

%% 'Plot' menubar callbacks

    function ShowImage(source,~)
        try
            % get the current image
            cImage = OOPSData.CurrentImage;
            % if empty, throw error
            if isempty(cImage)
                error('No image found')
            else
                cImage = cImage(1);
            end
            % get the image data
            try
                imageData = cImage.(source.Tag);
                if isempty(imageData)
                    error('No image data found')
                end
            catch ME
                uialert(OOPSData.Handles.fH,ME.message,'Error')
                return
            end
            % show the image type specified by the Tag property of the clicked menu button
            imshow2(imageData);
        catch ME
            msg = ME.message;
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        end
    end

%% MaskType Selection and custom segmentation schemes

    function BuildNewScheme(~,~)
        
        SchemeNameCell = SimpleFormFig('Enter a name for the masking scheme',{'Scheme name'},'White','Black');

        try
            if iscell(SchemeNameCell)
                NewSchemeName = SchemeNameCell{1};
            else % invalid input
                error('Canceled by user');
            end

            if isempty(OOPSData.CurrentImage)
                error('No data found')
            end

            if ismember(NewSchemeName,OOPSData.Settings.SchemeNames)
                error('Restricted name')
            end

            % open the CustomMaskMaker app so user can build a masking scheme
            NewScheme = CustomMaskMaker(OOPSData.CurrentImage(1).I,[],OOPSData.Settings.IntensityColormap);
            % get the handle to the mask maker app window
            MaskMakerFig = findobj(groot,'Name','Mask Maker');
            % and wait until it is closed
            waitfor(MaskMakerFig);

            % if not a valid masking scheme, throw error
            if ~NewScheme.isValidMaskingScheme
                error('Invalid scheme. The final output must be a logical image');
            end
            % the path to the directory in which we will save the scheme
            if ismac || isunix
                SchemeFilesPath = [OOPSData.Settings.MainPath,'/assets/segmentation_schemes/'];
            elseif ispc
                SchemeFilesPath = [OOPSData.Settings.MainPath,'\assets\segmentation_schemes\'];
            end
            % save the new scheme
            temp_scheme_struct.(NewSchemeName) = NewScheme;
            save([SchemeFilesPath,NewSchemeName,'.mat'],'-struct','temp_scheme_struct');
        catch ME
            % depending on the error caught, update user, return
            switch ME.message
                case 'Invalid scheme'
                    uialert(OOPSData.Handles.fH,'Not a valid masking scheme','Error');
                    return
                case 'Canceled by user'
                    % no need to throw error here, just return
                    %uialert(OOPSData.Handles.fH,'Canceled by user','Error');
                    return
                case 'No data found'
                    uialert(OOPSData.Handles.fH,'You need to load at least one FPM stack first','Error');
                    return
                case 'Restricted name'
                    uialert(OOPSData.Handles.fH,['There is already a custom scheme named "',NewSchemeName,'"'],'Error');
                    return
                otherwise
                    report = getReport(ME);
                    uialert(OOPSData.Handles.fH,['Unable to build masking scheme: ',report],'Error');
                    return
            end
        end

        % update OOPSSettings with new scheme
        OOPSData.Settings.LoadCustomMaskSchemes;

        % update the mask name selection dropdown
        switch OOPSData.Settings.MaskType
            case 'Default'
                OOPSData.Handles.MaskNameDropdown.Items = {'Legacy','Filament','Adaptive'};
            case 'CustomScheme'
                OOPSData.Handles.MaskNameDropdown.Items = OOPSData.Settings.SchemeNames;
        end

        % update the log window
        UpdateLog3(OOPSData.Handles.fH,['Saved new scheme:',SchemeFilesPath,NewSchemeName,'.mat'],'append');
    end

    function MaskTypeChanged(source,~)
        % update the mask name selection dropdown
        switch source.Value
            case 'Default'
                OOPSData.Handles.MaskNameDropdown.Items = {'Legacy','Filament','Adaptive'};
            case 'CustomScheme'
                OOPSData.Handles.MaskNameDropdown.Items = OOPSData.Settings.SchemeNames;
        end

        OOPSData.Settings.MaskSettings.MaskType = source.Value;
        OOPSData.Settings.MaskSettings.MaskName = OOPSData.Handles.MaskNameDropdown.Value;

        % only update summary overview if 'Project' is selected
        UpdateSummaryDisplay(source,{'Project'});
        % update image operations display
        UpdateThresholdSlider(source);
    end

    function MaskNameChanged(source,~)
        % update the mask name
        OOPSData.Settings.MaskSettings.MaskName = source.Value;

        % only update summary overview if 'Project' is selected
        UpdateSummaryDisplay(source,{'Project'});
        % update image operations display
        UpdateThresholdSlider(source);
    end

%% Change summary display type

    function ChangeSummaryDisplay(source,~)
        % update the summary display type
        OOPSData.Settings.SummaryDisplayType = OOPSData.Handles.AppInfoSelector.Value;
        % update the summary panel with the selected tabular data
        UpdateSummaryDisplay(source);
    end

%% Project saving and loading

    function loadProject(source,~)
        % alert user to required action (select saved project file to load)
        uialert(OOPSData.Handles.fH,'Select saved project file (.mat)','Load project',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));
        % call uiwait() on the main window
        uiwait(OOPSData.Handles.fH);
        % set figure visibility to off
        OOPSData.Handles.fH.Visible = 'Off';
        % open file selection window
        [filename,path] = uigetfile('*.mat','Choose saved OOPS Project',OOPSData.Settings.LastDirectory);
        % turn figure visibility back on
        OOPSData.Handles.fH.Visible = 'On';
        % return focus to main figure window
        figure(OOPSData.Handles.fH);
        % handle invalid selections or cancel
        if ~filename
            msg = 'No file selected...';
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        end
        % store old pointer
        OldPointer = OOPSData.Handles.fH.Pointer;
        % set new watch pointer while we load
        OOPSData.Handles.fH.Pointer = 'watch';
        % store the handles struct
        Handles = OOPSData.Handles;
        % store the previous tab
        PreviousTab = OOPSData.Settings.CurrentTab;
        % update log
        UpdateLog3(source,['Loading project:',path,filename],'append');
        % attempt to load the selected file
        try
            load([path,filename],'SavedOOPSData');

            if isa(SavedOOPSData,'struct')
                SavedOOPSData = OOPSProject.loadobj(SavedOOPSData);
            end
        catch ME
            report = getReport(ME);
            OOPSData.Handles.fH.Pointer = OldPointer;
            uialert(OOPSData.Handles.fH,['Unable to load project: ',report],'Error')
            return
        end
        % add the stored handles to the newly loaded project
        SavedOOPSData.Handles = Handles;
        % add the loaded project to the OOPSData object
        OOPSData = SavedOOPSData;
        % add the project with handles to the gui
        guidata(OOPSData.Handles.fH,OOPSData);

        % indicate that a project exists
        OOPSData.GUIProjectStarted = true;

        % update the display with selected tab
        Tab2Switch2 = OOPSData.Settings.CurrentTab;
        % set 'CurrentTab' to previous current tab before loading project
        OOPSData.Settings.CurrentTab = PreviousTab;
        % find the uimenu that would normally be used to switch to the tab indicated by 'CurrentTab' in the loaded project
        Menu2Pass = findobj(OOPSData.Handles.hTabMenu.Children,'Text',Tab2Switch2);
        if isempty(Menu2Pass)
            Menu2Pass = OOPSData.Handles.hTabMenu.Children(1);
        end
        % update view and display with newly loaded project
        % update group/image/object selection trees
        UpdateGroupTree(source);
        UpdateImageTree(source);
        UpdateLabelTree(source);
        % update summary type selector and summary tables
        OOPSData.Handles.AppInfoSelector.Value = OOPSData.Settings.SummaryDisplayType;
        UpdateSummaryDisplay(source);
        % update threshold and intensity sliders
        UpdateThresholdSlider(source);
        UpdateIntensitySliders(source);
        % update current tab using uimenu object as the source
        TabSelection(Menu2Pass);
        UpdateImages(source);
        % update the GUI theme
        UpdateGUITheme(source);
        % update the menubar
        UpdateMenubar(source);
        % restore old pointer
        OOPSData.Handles.fH.Pointer = OldPointer;
        % update log to indicate completion
        UpdateLog3(source,'Done.','append');
    end

    function saveProject(source,~)

        uialert(OOPSData.Handles.fH,'Choose directory and filename','Save project',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));

        uiwait(OOPSData.Handles.fH);

        OOPSData.Handles.fH.Visible = 'Off';

        try
            [filename,pathname] = uiputfile('*.mat','Choose directory and filename',OOPSData.Settings.LastDirectory);
        catch
            [filename,pathname] = uiputfile('*.mat','Choose directory and filename');
        end

        OOPSData.Handles.fH.Visible = 'On';

        figure(OOPSData.Handles.fH);

        if ~filename
            msg = 'Invalid filename...';
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        end

        % store old pointer
        OldPointer = OOPSData.Handles.fH.Pointer;
        % set new watch pointer while we save
        OOPSData.Handles.fH.Pointer = 'watch';
        % update log
        UpdateLog3(source,'Saving project...','append');

%         % copy the handle to OOPSData into a new variable, SavedOOPSData
%         SavedOOPSData = OOPSData;

        tic

        % attempt to save the project
        try
            % % method 1
            % SavedOOPSData = OOPSData.saveobj();
            % disp('Saving data struct...')
            % save([path,filename],'SavedOOPSData');


            % % method 2
            SavedOOPSData = OOPSData;
            disp('Saving data struct...')
            save([pathname,filename],'SavedOOPSData');

            clear SavedOOPSData
        catch ME
            report = getReport(ME);
            OOPSData.Handles.fH.Pointer = OldPointer;
            uialert(OOPSData.Handles.fH,['Unable to save project: ',report],'Error')
            return
        end

        % display how long it took to save the data
        timeElapsed = toc;
        disp(['Total time elapsed: ',num2str(timeElapsed)])
        % restore old pointer
        OOPSData.Handles.fH.Pointer = OldPointer;

        % update log to indicate successful save
        UpdateLog3(source,['Successfully saved project:',pathname,filename],'append');

    end

%% Data saving/exporting

    function SaveImages(source,~)
        
        % get screensize
        ss = OOPSData.Settings.ScreenSize;
        % center point (x,y) of screen
        center = [ss(3)/2,ss(4)/2];

        %% Data Selection
        sz = [center(1)-150 center(2)-150 300 300];
        
        fig = uifigure('Name','Select Images to Save',...
            'Menubar','None',...
            'Position',sz,...
            'HandleVisibility','On',...
            'Visible','Off',...
            'CloseRequestFcn',@ContinueToSave);

        MainGrid = uigridlayout(fig,[2,1],'BackgroundColor','Black');
        MainGrid.RowHeight = {'1x',20};
        MainGrid.ColumnWidth = {'1x'};
        
        SaveOptionsPanel = uipanel(MainGrid);
        SaveOptionsPanel.Title = 'Save Options';
        
        % cell array of char vectors of possible save options
        SaveOptions = {'Average Intensity Image (8-bit .tif)';...
            'Order (RGB .png)';...
            'Max Scaled Order (RGB .png)';...
            'Masked Order (RGB .png)';...
            'Max Scaled Order-Intensity Overlay (RGB .png)';...
            'Azimuth (RGB .png)';...
            'Masked Azimuth (RGB .png)';...
            'Azimuth HSV (RGB .png)';...
            'Mask (8-bit .tif)';...
            'Mask (RGB .png)';...
            'Image Summary'...
            };

        % create grid for uitree with the possible save options
        SaveOptionsTreeGrid = uigridlayout(SaveOptionsPanel,[1,1],...
            'BackgroundColor','Black',...
            'Padding',[0 0 0 0]);
        % the uitree
        SaveOptionsTree = uitree(SaveOptionsTreeGrid,'checkbox');
        % the top level nodes (save options)
        for OptionIdx = 1:numel(SaveOptions)
            uitreenode(SaveOptionsTree,'Text',SaveOptions{OptionIdx},'NodeData',SaveOptions{OptionIdx});
        end
        % note: we could add children nodes for more user control over the saved data 
        % (ex: select what to include in our image summary struct, etc.)

        % button to indicate completion, leads to selecting save directory
        uibutton(MainGrid,'Push',...
            'Text','Choose Save Directory',...
            'ButtonPushedFcn',@ContinueToSave);

        % move the window to the center before showing it
        movegui(fig,'center')
        % now show it
        fig.Visible = 'On';
        % initialize save choices cell
        UserSaveChoices = {};

        % callback for Btn to close fig
        function [] = ContinueToSave(~,~)
            % hide main fig
            OOPSData.Handles.fH.Visible = 'Off';
            if numel(SaveOptionsTree.CheckedNodes)>0
                % collect the selected options
                [UserSaveChoices{1:numel(SaveOptionsTree.CheckedNodes),1}] = deal(SaveOptionsTree.CheckedNodes.NodeData);
            end
            % delete the figure
            delete(fig)
        end

        % wait until fig deleted (by 'X' or continue button)
        waitfor(fig);
        % then check for valid input
        if isempty(UserSaveChoices)
            UpdateLog3(source,'No options selected.','append');
            % turn main fig back on
            OOPSData.Handles.fH.Visible = 'On';
            return
        end
        % get save directory
        folder_name = uigetdir(pwd);
        % turn main fig back on
        OOPSData.Handles.fH.Visible = 'On';
        % move into user-selected save directory
        cd(folder_name);

        % save user-specified data for each currently selected image
        for cImage = OOPSData.CurrentImage
            
            % control for mac vs pc
            if ismac || isunix
                loc = [folder_name '/' cImage.rawFPMShortName];
            elseif ispc
                loc = [folder_name '\' cImage.rawFPMShortName];
            end
            
            if any(strcmp(UserSaveChoices,'Image Summary'))

                % data struct to hold output variable for current image
                ImageSummary = struct();
                ImageSummary.I = cImage.I;
                % mask and average Order
                ImageSummary.MaskImage = cImage.bw;
                ImageSummary.OrderAvg = cImage.OrderAvg;
                % raw data, raw data normalized to stack-max, raw stack-average
                ImageSummary.rawFPMStack = cImage.rawFPMStack;
                ImageSummary.rawFPMAverage = cImage.rawFPMAverage;
                % same as above, but with flat-field corrected data
                ImageSummary.ffcFPMStack = cImage.ffcFPMStack;
                ImageSummary.ffcFPMAverage = cImage.ffcFPMAverage;
                % FF-corrected data normalized within each 4-px stack
                ImageSummary.ffcFPMPixelNorm = cImage.ffcFPMPixelNorm;
                % output images
                ImageSummary.OrderImage = cImage.OrderImage;
                ImageSummary.MaskedOrderImage = cImage.MaskedOrderImage;
                ImageSummary.AzimuthImage = cImage.AzimuthImage;
                % image info
                ImageSummary.ImageName = cImage.rawFPMShortName;
                % calculated obj data (SB,Order,etc.)
                ImageSummary.ObjectData = GetImageObjectSummary(cImage);
                
                name = [loc,'_ImageSummary'];
                UpdateLog3(source,name,'append');
                save(name,'ImageSummary');
                clear ImageSummary
            end

            %% Order
            
            if any(strcmp(UserSaveChoices,'Order (RGB .png)'))
                name = [loc,'-Order_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.OrderImageRGB;
                imwrite(IOut,name);
            end


            if any(strcmp(UserSaveChoices,'Max Scaled Order (RGB .png)'))
                name = [loc,'-Scaled_Order_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.MaxScaledOrderImageRGB;
                imwrite(IOut,name);
            end

            if any(strcmp(UserSaveChoices,'Masked Order (RGB .png)'))
                name = [loc,'-MaskedOrder_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.MaskedOrderImageRGB;
                imwrite(IOut,name);
            end

            if any(strcmp(UserSaveChoices,'Max Scaled Order-Intensity Overlay (RGB .png)'))
                name = [loc,'-MaxScaledOrderIntensityOverlay_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.MaxScaledOrderIntensityOverlayRGB;
                imwrite(IOut,name);
            end

            %% Azimuth
            
            if any(strcmp(UserSaveChoices,'Azimuth (RGB .png)'))
                name = [loc,'-Azimuth_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.AzimuthRGB;
                imwrite(IOut,name);
            end
            
            if any(strcmp(UserSaveChoices,'Masked Azimuth (RGB .png)'))
                name = [loc,'-MaskedAzimuth_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.MaskedAzimuthRGB;
                imwrite(IOut,name);
            end

            if any(strcmp(UserSaveChoices,'Azimuth HSV (RGB .png)'))
                name = [loc,'-AzimuthHSV_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.AzimuthOrderIntensityHSV;
                imwrite(IOut,name);
            end
            
            %% Average Intensity
            
            if any(strcmp(UserSaveChoices,'Average Intensity Image (8-bit .tif)'))
                name = [loc '-AvgIntensity.tif'];
                UpdateLog3(source,name,'append');
                IOut = im2uint8(Scale0To1(cImage.ffcFPMAverage));
                imwrite(IOut,OOPSData.Settings.IntensityColormap,name);                
            end

            %% Mask

            if any(strcmp(UserSaveChoices,'Mask (8-bit .tif)'))    
                name = [loc '-Mask.tif'];
                UpdateLog3(source,name,'append');
                IOut = im2uint8(full(cImage.bw));
                imwrite(IOut,name);
            end

            if any(strcmp(UserSaveChoices,'Mask (RGB .png)'))    
                name = [loc '-Mask_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = im2uint8(full(cImage.bw));
                imwrite(IOut,name);
            end
            
        end % end of main save loop

        UpdateLog3(source,'Done.','append');
        
    end % end SaveImages

    function SaveObjectData(source,~)
        
        uialert(OOPSData.Handles.fH,'Choose directory and filename','Export object data',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));

        uiwait(OOPSData.Handles.fH);

        OOPSData.Handles.fH.Visible = 'Off';

        outputFilters = {'*.mat','MAT-files (*.mat)'; '*.xlsx','Excel Workbook (*.xlsx)'};

        try
            [filename, pathname, filterindex] = uiputfile( ...
                outputFilters,...
                'Choose directory and filename',OOPSData.Settings.LastDirectory);
        catch
            [filename, pathname, filterindex] = uiputfile( ...
                outputFilters,...
                'Choose directory and filename',pwd);
        end

        OOPSData.Handles.fH.Visible = 'On';
        figure(OOPSData.Handles.fH);

        % if user selected cancel, return
        if isequal(filename,0) || isequal(pathname,0)
            msg = 'Canceled by user';
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        else
            fullFilename = fullfile(pathname,filename);
            outputType = outputFilters{filterindex,1};
        end

        % store the most recently accessed directory
        OOPSData.Settings.LastDirectory = pathname;

        UpdateLog3(source,'Exporting object data...','append');

        % get the stacked data tables
        stackedData = OOPSData.stackedObjectDataTable();
        
        % get the filename without extension
        fileParts = strsplit(filename,'.');
        shortName = fileParts{1};

        % save the file in the format specified by the user
        switch outputType
            case '*.mat'
                % create a struct to hold the data with short filename as field name
                S.(matlab.lang.makeValidName(shortName)) = stackedData;
                % save the stacked data struct
                save(fullFilename,'-struct','S');
                clear S
            case '*.xlsx'
                for groupIdx = 1:length(stackedData)
                    if groupIdx == 1
                        writeMode = "replacefile";
                    else
                        writeMode = "overwritesheet";
                    end
                    writetable(stackedData(groupIdx).Data,...
                        fullFilename,...
                        "Sheet",stackedData(groupIdx).Group,...
                        "WriteMode",writeMode);
                end
        end

        UpdateLog3(source,'Done.','append');
    end

%% Axes toolbar callbacks

    function tbExportAxes(source,~)
        % get the parent toolbar of the calling button
        ctb = source.Parent;
        % get the parent axes of that toolbar, which we will export
        cax = ctb.Parent;

        uialert(OOPSData.Handles.fH,'Choose directory and filename','Export axes',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));

        uiwait(OOPSData.Handles.fH);

        OOPSData.Handles.fH.Visible = 'Off';

        try
            [filename,pathname] = uiputfile('*.png',...
                'Choose directory and filename',OOPSData.Settings.LastDirectory);
        catch
            [filename,pathname] = uiputfile('*.png',...
                'Choose directory and filename');
        end

        OOPSData.Handles.fH.Visible = 'On';
        figure(OOPSData.Handles.fH);

        if isequal(filename,0) || isequal(pathname,0)
            msg = 'Canceled by user';
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        end

        OOPSData.Settings.LastDirectory = pathname;

        UpdateLog3(source,'Exporting axes...','append');

        %% exportgraphics method

        % check whether title is visible
        if cax.Title.Visible
            cax.Title.Visible = false; % if so, hide it
            resetTitle = true; % indicate we need to reset the title
        else
            resetTitle = false;
        end

        % export the axes as an image at 600 dpi
        exportgraphics(cax,[pathname,filename],"ContentType","image","Resolution",600);

        % make title visible if resetTitle is true
        cax.Title.Visible = resetTitle;

        %% export_fig method
        % tempfig = uifigure("HandleVisibility","On",...
        %     "Visible","off",...
        %     "InnerPosition",[0 0 1024 1024],...
        %     "AutoResizeChildren","Off");
        % % copy the axes into the new figure
        % tempax = copyobj(cax,tempfig);
        % % set various axes properties that improve export quality
        % tempax.Visible = 'On';
        % tempax.XColor = 'Black';
        % tempax.YColor = 'Black';
        % tempax.Box = 'On';
        % tempax.LineWidth = 0.5;
        % tempax.Color = 'Black';
        % % hide the title
        % tempax.Title.String = '';
        % % set axes unit to normalized
        % tempax.Units = 'Normalized';
        % % set axes position to fill the whole figure
        % tempax.InnerPosition = [0 0 1 1];
        % % call export_fig with the relevant handle and filename
        % export_fig([path,filename],tempfig,'-nocrop');
        % % close the temporary figure
        % close(tempfig)

        UpdateLog3(source,'Done.','append');
    end

    function tbApplyMaskStateChanged(source,event)
        
        cGroupIdx = OOPSData.CurrentGroupIndex;
        cImageIdx = OOPSData.Group(cGroupIdx).CurrentImageIndex;
        ctb = source.Parent;
        cax = ctb.Parent;
        im = findobj(cax,'Type','image');

        switch event.Value
            case 1 % 'On'
                im.AlphaData = OOPSData.Group(cGroupIdx).Replicate(cImageIdx).bw;
            case 0 % 'Off'
                im.AlphaData = 1;
        end
    end

    function tbShowAsOverlayStateChanged(source,~)

        splitTag = strsplit(source.Tag,'ShowAsOverlay');
        axID = splitTag{2};

        switch axID
            case 'Order'
                UpdateOrderImage(source);
            case 'Azimuth'
                if source.Value
                    OOPSData.Handles.ShowAzimuthHSVOverlayAzimuth.Value = "off";
                end
                UpdateAzimuthImage(source);
            otherwise
                UpdateCustomStatImage(source);
        end

        %UpdateImages(source);
    end

    function tbShowAzimuthHSVOverlayStateChanged(source,~)
        % if the toolbar button is pressed
        if source.Value
            % then make sure the intensity overlay button is not pressed
            OOPSData.Handles.ShowAsOverlayAzimuth.Value = "off";
            OOPSData.Handles.ScaleToMaxAzimuth.Visible = "on";
        else
            OOPSData.Handles.ScaleToMaxAzimuth.Visible = "off";
        end
        %UpdateImages(source);
        UpdateAzimuthImage(source);
    end

    function tbShowSelectionStateChanged(source,event)
        switch event.Value
            case 1
                OOPSData.Handles.ShowSelectionAverageIntensity.Value = 1;
                OOPSData.Handles.ShowSelectionMask.Value = 1;
                UpdateImages(source);
            case 0
                OOPSData.Handles.ShowSelectionAverageIntensity.Value = 0;
                OOPSData.Handles.ShowSelectionMask.Value = 0;
                delete(findobj(OOPSData.Handles.fH,'Tag','ObjectBox'))
        end
        
    end

    function tbShowColorbarStateChanged(source,~)

        % btnTagSpit = strsplit(source.Tag,'ShowColorbar');
        % imageType = btnTagSplit{2};
        % switch imageType
        %   case 'Order'
        %       OOPSData.Handles.Ordercbar.Visible = source.Value;
        %   case 'Azimuth'
        %
        % end
        UpdateImages(source);
    end

    function tbScaleToMaxStateChanged(source,event)

        cImage = OOPSData.CurrentImage;

        if ~isempty(cImage)
            cImage = cImage(1);
        else
            source.Value = ~event.Value;
            return
        end

        switch source.Tag
            case 'ScaleToMaxOrder'
                if event.Value && cImage.FPMStatsDone
                    OOPSData.Handles.OrderSlider.Value = [0 max(cImage.OrderImage,[],"all")];
                elseif event.Value && ~cImage.FPMStatsDone
                    OOPSData.Handles.OrderSlider.Value = [0 1];
                end
                OOPSData.Handles.ScaleToMaxOrder.Value = event.Value;
                OOPSData.Handles.ScaleToMaxAzimuth.Value = event.Value;
            case 'ScaleToMaxAzimuth'
                if event.Value && cImage.FPMStatsDone
                    OOPSData.Handles.OrderSlider.Value = [0 max(cImage.OrderImage,[],"all")];
                elseif event.Value && ~cImage.FPMStatsDone
                    OOPSData.Handles.OrderSlider.Value = [0 1];                   
                end
                OOPSData.Handles.ScaleToMaxOrder.Value = event.Value;
                OOPSData.Handles.ScaleToMaxAzimuth.Value = event.Value;
            case 'ScaleToMaxCustomStat'
                % get the current custom stat based on the name of the curret tab
                statIdx = ismember(OOPSData.Settings.CurrentTab,OOPSData.Settings.CustomStatisticDisplayNames);
                % get the stat
                cStat = OOPSData.Settings.CustomStatistics(statIdx);

                if event.Value && cImage.FPMStatsDone
                    OOPSData.Handles.([cStat.StatisticName,'Slider']).Value = [cImage.([cStat.StatisticName,'DisplayRange'])(1) max(cImage.([cStat.StatisticName,'Image']),[],"all")];
                elseif event.Value && ~cImage.FPMStatsDone
                    OOPSData.Handles.([cStat.StatisticName,'Slider']).Value = OOPSData.Handles.([cStat.StatisticName,'Slider']).Limits;
                end
                OOPSData.Handles.ScaleToMaxCustomStat.Value = event.Value;
        end

    end

    function tbShowReferenceImageStateChanged(source,~)
        if OOPSData.CurrentImage.ReferenceImageLoaded
            UpdateImages(source);
        else
            source.Value = 0;
            UpdateLog3(source,'No reference image to overlay.','append');
        end
    end

    function tbLassoROI(source,~)
        ctb = source.Parent;
        cax = ctb.Parent;
        % draw rectangular ROI
        ROI = drawfreehand(cax,'Multiclick',1,'Color','yellow');
        % find and 'select' objects within ROI
        SelectObjectsInROI(source,ROI);
        % delete the ROI
        delete(ROI);
        % update display
        UpdateImages(source);
    end

    function tbLineScan(source,~)

        try
            delete(OOPSData.Handles.LineScanROI);
            delete(OOPSData.Handles.LineScanFig);
            delete(OOPSData.Handles.LineScanListeners(1));
            delete(OOPSData.Handles.LineScanListeners(2));
            delete(OOPSData.Handles.LineScanRectangle);
        catch
            % do nothing for now
        end

        switch source.Tag
            case 'LineScanAverageIntensity'
                OOPSData.Handles.LineScanROI = images.roi.Line(OOPSData.Handles.AverageIntensityAxH,...
                    'Color','Yellow',...
                    'Alpha',0.5,...
                    'Tag','LineScanAverageIntensity');
                XRange = OOPSData.Handles.AverageIntensityAxH.XLim(2)-OOPSData.Handles.AverageIntensityAxH.XLim(1);
                YRange = OOPSData.Handles.AverageIntensityAxH.YLim(2)-OOPSData.Handles.AverageIntensityAxH.YLim(1);
                x1 = OOPSData.Handles.AverageIntensityAxH.XLim(1)+0.25*XRange;
                x2 = OOPSData.Handles.AverageIntensityAxH.XLim(2)-0.25*XRange;
                y1 = OOPSData.Handles.AverageIntensityAxH.YLim(1)+0.5*YRange;
                y2 = OOPSData.Handles.AverageIntensityAxH.YLim(1)+0.5*YRange;
        
                OOPSData.Handles.LineScanFig = uifigure('Name','Average Intensity line scan',...
                    'HandleVisibility','On',...
                    'WindowStyle','AlwaysOnTop',...
                    'Units','Normalized',...
                    'Position',[0.65 0.8 0.35 0.2],...
                    'CloseRequestFcn',@CloseLineScanFig);
                
                OOPSData.Handles.LineScanAxes = uiaxes(OOPSData.Handles.LineScanFig,...
                    'Units','Normalized',...
                    'OuterPosition',[0 0 1 1]);
                OOPSData.Handles.LineScanAxes.XLabel.String = 'Distance (um)';
                OOPSData.Handles.LineScanAxes.YLabel.String = 'Integrated Intensity';

                OOPSData.Handles.LineScanROI.Position = [x1 y1; x2 y2];
                
                OOPSData.Handles.LineScanListeners(1) = addlistener(OOPSData.Handles.LineScanROI,'MovingROI',@LineScanROIMoving);
                OOPSData.Handles.LineScanListeners(2) = addlistener(OOPSData.Handles.LineScanROI,'ROIMoved',@LineScanROIMoved);
            case 'LineScanOrder'

                OOPSData.Handles.LineScanROI = images.roi.Line(OOPSData.Handles.OrderAxH,...
                    'Color','Yellow',...
                    'Alpha',0.5,...
                    'Tag','LineScanOrder');
                XRange = OOPSData.Handles.OrderAxH.XLim(2)-OOPSData.Handles.OrderAxH.XLim(1);
                YRange = OOPSData.Handles.OrderAxH.YLim(2)-OOPSData.Handles.OrderAxH.YLim(1);
                x1 = OOPSData.Handles.OrderAxH.XLim(1)+0.25*XRange;
                x2 = OOPSData.Handles.OrderAxH.XLim(2)-0.25*XRange;
                y1 = OOPSData.Handles.OrderAxH.YLim(1)+0.5*YRange;
                y2 = OOPSData.Handles.OrderAxH.YLim(1)+0.5*YRange;
        
                OOPSData.Handles.LineScanFig = uifigure('Name','Order line scan',...
                    'HandleVisibility','On',...
                    'WindowStyle','AlwaysOnTop',...
                    'Units','Normalized',...
                    'Position',[0.65 0.8 0.35 0.2],...
                    'CloseRequestFcn',@CloseLineScanFig,...
                    'Color','White');
                
                OOPSData.Handles.LineScanAxes = uiaxes(OOPSData.Handles.LineScanFig,...
                    'Units','Normalized',...
                    'OuterPosition',[0 0 1 1]);
                OOPSData.Handles.LineScanAxes.XLabel.String = 'Distance (um)';
                OOPSData.Handles.LineScanAxes.YLabel.String = 'Average Order';
                
                OOPSData.Handles.LineScanROI.Position = [x1 y1; x2 y2];
                
                OOPSData.Handles.LineScanListeners(1) = addlistener(OOPSData.Handles.LineScanROI,'MovingROI',@LineScanROIMoving);
                OOPSData.Handles.LineScanListeners(2) = addlistener(OOPSData.Handles.LineScanROI,'ROIMoved',@LineScanROIMoved);

        end

        % invoke the 'ROIMoved' callback to update the line scan
        LineScanROIMoved(OOPSData.Handles.LineScanROI,[]);
        % move roi line on top of rectangle
        bringToFront(OOPSData.Handles.LineScanROI);

    end

    function CloseLineScanFig(~,~)
        delete(OOPSData.Handles.LineScanROI);
        delete(OOPSData.Handles.LineScanListeners(1));
        delete(OOPSData.Handles.LineScanListeners(2));        
        delete(OOPSData.Handles.LineScanFig);
        delete(OOPSData.Handles.LineScanRectangle);
    end

    function LineScanROIMoving(source,~)

        cImage = OOPSData.CurrentImage;
        
        switch source.Tag
            case 'LineScanAverageIntensity'
                if cImage.ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value==1
                    % OOPSData.Handles.LineScanAxes = PlotIntegratedDoubleLineScan(OOPSData.Handles.LineScanAxes,...
                    %     OOPSData.Handles.LineScanROI.Position,...
                    %     cImage.ffcFPMAverage,...
                    %     cImage.ReferenceImageEnhanced,...
                    %     cImage.RealWorldLimits);
                    UpdateIntensityDoubleLineScan(source);
                else
                    UpdateIntensityLineScan(source);
                end
            case 'LineScanOrder'
                UpdateOrderLineScan(source);
        end

    end

    function LineScanROIMoved(source,~)

        cImage = OOPSData.CurrentImage;
        
        switch source.Tag
            case 'LineScanAverageIntensity'
                if cImage.ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value==1
                    % OOPSData.Handles.LineScanAxes = PlotIntegratedDoubleLineScan(OOPSData.Handles.LineScanAxes,...
                    %     OOPSData.Handles.LineScanROI.Position,...
                    %     cImage.ffcFPMAverage,...
                    %     cImage.ReferenceImageEnhanced,...
                    %     cImage.RealWorldLimits);
                    UpdateIntensityDoubleLineScan(source);
                else
                    % OOPSData.Handles.LineScanAxes = PlotIntegratedLineScan(OOPSData.Handles.LineScanAxes,...
                    %     OOPSData.Handles.LineScanROI.Position,...
                    %     cImage.ffcFPMAverage,...
                    %     cImage.RealWorldLimits);
                    UpdateIntensityLineScan(source);
                end
            case 'LineScanOrder'
                UpdateOrderLineScan(source);
        end
        
    end

end