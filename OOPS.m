function OOPS()

% try to start the parallel pool 
try
    parpool("threads");
catch
    warning("Unable to create parallel pool...")
end

% create an instance of OOPSProject
% this object will hold ALL project data and GUI settings
OOPSData = OOPSProject;

%% set up splash screen

% % get the splash screen image
% if ismac || isunix
%     SplashIconPath = fullfile([OOPSData.Settings.MainPath,'/SplashScreenIcon/AppSplashScreen.png']);
% elseif ispc
%     SplashIconPath = fullfile([OOPSData.Settings.MainPath,'\SplashScreenIcon\AppSplashScreen.png']);
% end
% SplashScreenIcon = java.awt.Toolkit.getDefaultToolkit.createImage(SplashIconPath);
% 
% % Create splash screen window
% SplashImage = SplashScreenIcon;
% Splash = javax.swing.JWindow;
% icon = javax.swing.ImageIcon(SplashImage);
% label = javax.swing.JLabel(icon);
% Splash.getContentPane.add(label);
% Splash.setAlwaysOnTop(true);
% Splash.pack;
% 
% % set the splash image to the center of the screen
% screenSize = Splash.getToolkit.getScreenSize;
% screenHeight = screenSize.height;
% screenWidth = screenSize.width;
% % get the actual splashImage size
% imgHeight = icon.getIconHeight;
% imgWidth = icon.getIconWidth;
% Splash.setLocation((screenWidth-imgWidth)/2,(screenHeight-imgHeight)/2);
% Splash.show % show the splash screen

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

% turn off any warning that do not adversely affect computation
warning('off','MATLAB:polyshape:repairedBySimplify');

%% CHECKPOINT

disp('Setting up menubar...')

%% File Menu Button - Create a new project, load files, etc...

OOPSData.Handles.hFileMenu = uimenu(OOPSData.Handles.fH,'Text','File');
% Options for File Menu Button
OOPSData.Handles.hNewProject = uimenu(OOPSData.Handles.hFileMenu,'Text','&New Project','Callback',@NewProject2);
OOPSData.Handles.hNewProject.Accelerator = 'N';
% menu for loading existing project
OOPSData.Handles.hLoadProject = uimenu(OOPSData.Handles.hFileMenu,'Text','Load Project','Callback',@LoadProject);
OOPSData.Handles.hSaveProject = uimenu(OOPSData.Handles.hFileMenu,'Text','Save Project','Callback',@SaveProject);
% load files
OOPSData.Handles.hLoadFFCFiles = uimenu(OOPSData.Handles.hFileMenu,'Text','Load FFC Files','Separator','On','Callback',@pb_LoadFFCFiles);
OOPSData.Handles.hLoadFPMFiles = uimenu(OOPSData.Handles.hFileMenu,'Text','Load FPM Files','Callback',@pb_LoadFPMFiles);
OOPSData.Handles.hLoadReferenceImages = uimenu(OOPSData.Handles.hFileMenu,'Text','Load Reference Images','Callback',@LoadReferenceImages);
% save data
OOPSData.Handles.hSaveOF = uimenu(OOPSData.Handles.hFileMenu,'Text','Save Data for Selected Images','Separator','On','Callback',@SaveImages);
OOPSData.Handles.hSaveObjectData = uimenu(OOPSData.Handles.hFileMenu,'Text','Save Object Data','Callback',@SaveObjectData);
% save settings
OOPSData.Handles.hSaveColormapsSettings = uimenu(OOPSData.Handles.hFileMenu,'Text','Save Colormaps Settings','Separator','On','Callback',@SaveColormapsSettings);
OOPSData.Handles.hSaveAzimuthDisplaySettings = uimenu(OOPSData.Handles.hFileMenu,'Text','Save Azimuth Display Settings','Callback',@SaveAzimuthDisplaySettings);
OOPSData.Handles.hScatterPlotSettingsMenu = uimenu(OOPSData.Handles.hFileMenu,'Text','Save Scatter Plot Settings','Callback',@SaveScatterPlotSettings);
OOPSData.Handles.hSaveSwarmPlotSettings = uimenu(OOPSData.Handles.hFileMenu,'Text','Save Swarm Plot Settings','Callback',@SaveSwarmPlotSettings);

%% Options Menu Button - Change gui option and settings

OOPSData.Handles.hOptionsMenu = uimenu(OOPSData.Handles.fH,'Text','Options');
% GUI options (themes, colors, fonts, etc.)
OOPSData.Handles.hGUI = uimenu(OOPSData.Handles.hOptionsMenu,'Text','GUI');
% GUI theme option
OOPSData.Handles.hGUITheme = uimenu(OOPSData.Handles.hGUI,'Text','Theme');
% options for GUI theme
OOPSData.Handles.hGUITheme_Dark = uimenu(OOPSData.Handles.hGUITheme,'Text','Dark','Checked','off','Callback',@ChangeGUITheme);
OOPSData.Handles.hGUITheme_Dark2 = uimenu(OOPSData.Handles.hGUITheme,'Text','Dark2','Checked','on','Callback',@ChangeGUITheme);
OOPSData.Handles.hGUITheme_Light = uimenu(OOPSData.Handles.hGUITheme,'Text','Light','Checked','off','Callback',@ChangeGUITheme);
% GUI colors options
OOPSData.Handles.hGUIBackgroundColor = uimenu(OOPSData.Handles.hGUI,'Text','Background Color','Separator','on','Tag','GUIBackgroundColor','Callback',@ChangeGUIColors);
OOPSData.Handles.hGUIForegroundColor = uimenu(OOPSData.Handles.hGUI,'Text','Foreground Color','Tag','GUIForegroundColor','Callback',@ChangeGUIColors);
OOPSData.Handles.hGUIHighlightColor = uimenu(OOPSData.Handles.hGUI,'Text','Highlight Color','Tag','GUIHighlightColor','Callback',@ChangeGUIColors);

% GUI font size option
OOPSData.Handles.hGUIFontSize = uimenu(OOPSData.Handles.hGUI,'Text','Font Size');
% options for GUI font size
OOPSData.Handles.hGUIFontSize_Larger = uimenu(OOPSData.Handles.hGUIFontSize,'Text','Larger','Callback',@ChangeGUIFontSize);
OOPSData.Handles.hGUIFontSize_Smaller = uimenu(OOPSData.Handles.hGUIFontSize,'Text','Smaller','Callback',@ChangeGUIFontSize);

% Options for mask type ('Default' or 'Custom', 'Upload mask' in development
OOPSData.Handles.hMaskType = uimenu(OOPSData.Handles.hOptionsMenu,'Text','Mask Type');
% Option to select 'Default' mask type
OOPSData.Handles.hMaskType_Default = uimenu(OOPSData.Handles.hMaskType,'Text','Default');
% Names of 'Default' masks
OOPSData.Handles.hMaskType_Default_Legacy = uimenu(OOPSData.Handles.hMaskType_Default,'Text','Legacy','Checked','On','Tag','Default','Callback', @ChangeMaskType);
OOPSData.Handles.hMaskType_Default_AdaptiveFilament = uimenu(OOPSData.Handles.hMaskType_Default,'Text','AdaptiveFilament','Checked','Off','Tag','Default','Callback', @ChangeMaskType);
OOPSData.Handles.hMaskType_Default_FilamentEdge = uimenu(OOPSData.Handles.hMaskType_Default,'Text','FilamentEdge','Checked','Off','Tag','Default','Callback', @ChangeMaskType);
OOPSData.Handles.hMaskType_Default_Intensity = uimenu(OOPSData.Handles.hMaskType_Default,'Text','Intensity','Checked','Off','Tag','Default','Callback', @ChangeMaskType);
OOPSData.Handles.hMaskType_Default_Adaptive = uimenu(OOPSData.Handles.hMaskType_Default,'Text','Adaptive','Checked','Off','Tag','Default','Callback', @ChangeMaskType);
% Option to select 'Custom' mask type
OOPSData.Handles.hMaskType_CustomScheme = uimenu(OOPSData.Handles.hMaskType,'Text','CustomScheme');
% Load the custom schemes and make a menu option for each one
for i = 1:numel(OOPSData.Settings.SchemeNames)
    OOPSData.Handles.(['hMaskType_CustomScheme_',OOPSData.Settings.SchemeNames{i}]) = ...
        uimenu(OOPSData.Handles.hMaskType_CustomScheme,...
        'Text',OOPSData.Settings.SchemeNames{i},...
        'Tag','CustomScheme',...
        'Checked','Off',...
        'Callback',@ChangeMaskType);
end
% Option to create new 'Custom' mask scheme
OOPSData.Handles.hMaskType_NewScheme = uimenu(OOPSData.Handles.hMaskType_CustomScheme,...
    'Text','Create new scheme',...
    'Separator','on',...
    'Callback',@BuildNewScheme);

% Options for display of object boxes
OOPSData.Handles.hObjectBoxMenu = uimenu(OOPSData.Handles.hOptionsMenu,'Text','Object boxes');
% Box type option
OOPSData.Handles.hObjectBoxType = uimenu(OOPSData.Handles.hObjectBoxMenu,'Text','Box type');
% options for box type
OOPSData.Handles.hObjectBoxType_Box = uimenu(OOPSData.Handles.hObjectBoxType,'Text','Box','Checked','On','Callback',@ChangeObjectBoxType);
OOPSData.Handles.hObjectBoxType_Boundary = uimenu(OOPSData.Handles.hObjectBoxType,'Text','Boundary','Checked','Off','Callback',@ChangeObjectBoxType);
OOPSData.Handles.hObjectBoxType_Patch = uimenu(OOPSData.Handles.hObjectBoxType,'Text','Patch','Checked','Off','Callback',@ChangeObjectBoxType);
% OOPSData.Handles.hObjectBoxType_Polygon = uimenu(OOPSData.Handles.hObjectBoxType,'Text','Polygon','Checked','Off','Callback',@ChangeObjectBoxType);
% OOPSData.Handles.hObjectBoxType_Development = uimenu(OOPSData.Handles.hObjectBoxType,'Text','Development','Checked','Off','Callback',@ChangeObjectBoxType);

%% View Menu Button - changes view of GUI to different 'tabs'

OOPSData.Handles.hTabMenu = uimenu(OOPSData.Handles.fH,'Text','View');
% Tabs for 'View'
OOPSData.Handles.hTabFiles = uimenu(OOPSData.Handles.hTabMenu,'Text','Files','MenuSelectedFcn',@TabSelection,'tag','hTabFiles');
OOPSData.Handles.hTabFFC = uimenu(OOPSData.Handles.hTabMenu,'Text','FFC','MenuSelectedFcn',@TabSelection,'tag','hTabFFC');
%OOPSData.Handles.hTabGenerateMask = uimenu(OOPSData.Handles.hTabMenu,'Text','Generate Mask','MenuSelectedFcn',@TabSelection,'tag','hTabGenerateMask');
OOPSData.Handles.hTabMask = uimenu(OOPSData.Handles.hTabMenu,'Text','Mask','MenuSelectedFcn',@TabSelection,'tag','hTabMask');
OOPSData.Handles.hTabOrderFactor = uimenu(OOPSData.Handles.hTabMenu,'Text','Order Factor','MenuSelectedFcn',@TabSelection,'tag','hTabOrderFactor');
%OOPSData.Handles.hTabSBFiltering = uimenu(OOPSData.Handles.hTabMenu,'Text','Filtered Order Factor','MenuSelectedFcn',@TabSelection,'tag','hTabSBFiltering');
OOPSData.Handles.hTabAzimuth = uimenu(OOPSData.Handles.hTabMenu,'Text','Azimuth','MenuSelectedFcn',@TabSelection,'tag','hTabAzimuth');
OOPSData.Handles.hTabPlots = uimenu(OOPSData.Handles.hTabMenu,'Text','Plots','MenuSelectedFcn',@TabSelection,'tag','hTabPlots');
OOPSData.Handles.hTabPolarPlots = uimenu(OOPSData.Handles.hTabMenu,'Text','Polar Plots','MenuSelectedFcn',@TabSelection,'tag','hTabPolarPlots');
OOPSData.Handles.hTabObjects = uimenu(OOPSData.Handles.hTabMenu,'Text','Objects','MenuSelectedFcn',@TabSelection,'tag','hTabObjects');

%% Process Menu Button - allows user to perform FFC, generate mask, and generate output images

OOPSData.Handles.hProcessMenu = uimenu(OOPSData.Handles.fH,'Text','Process');
% Process Operations
OOPSData.Handles.hProcessFFC = uimenu(OOPSData.Handles.hProcessMenu,'Text','Flat-Field Correction','MenuSelectedFcn',@pb_FFC);
OOPSData.Handles.hProcessMask = uimenu(OOPSData.Handles.hProcessMenu,'Text','Build Mask','MenuSelectedFcn',@CreateMask4);
OOPSData.Handles.hProcessOF = uimenu(OOPSData.Handles.hProcessMenu,'Text','Order Factor','MenuSelectedFcn',@pb_FindOrderFactor);
OOPSData.Handles.hProcessLocalSB = uimenu(OOPSData.Handles.hProcessMenu,'Text','Local Signal:Background','MenuSelectedFcn',@pb_FindLocalSB);
%OOPSData.Handles.hProcessObjectAzimuthStats = uimenu(OOPSData.Handles.hProcessMenu,'Text','Object Azimuth Stats','MenuSelectedFcn',@pb_ComputeObjectAzimuthStats);

%% Summary Menu Button

OOPSData.Handles.hSummaryMenu = uimenu(OOPSData.Handles.fH,'Text','Summary');
% Summary choices
OOPSData.Handles.hSumaryAll = uimenu(OOPSData.Handles.hSummaryMenu,'Text','All Data','MenuSelectedFcn',@ShowSummaryTable);

%% Objects Menu Button
OOPSData.Handles.hObjectsMenu = uimenu(OOPSData.Handles.fH,'Text','Objects');
% Object Actions
OOPSData.Handles.hDeleteSelectedObjects = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Delete Selected Objects','MenuSelectedFcn',@mbDeleteSelectedObjects);
% OOPSData.Handles.hLabelSelectedObjects = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Label Selected Objects','MenuSelectedFcn',@mbLabelSelectedObjects);
OOPSData.Handles.hClearSelection = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Clear Selection','MenuSelectedFcn',@mbClearSelection);
OOPSData.Handles.hkMeansClustering = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Label Objects with k-means Clustering','MenuSelectedFcn',@mbObjectkmeansClustering);
OOPSData.Handles.hShowObjectImagesByLabel = uimenu(OOPSData.Handles.hObjectsMenu,'Text','Show Object Images by Label','MenuSelectedFcn',@mbShowObjectImagesByLabel);
%% Plot Menu Button
OOPSData.Handles.hPlotMenu = uimenu(OOPSData.Handles.fH,'Text','Plot');
% Object Actions
OOPSData.Handles.hPlotImageRelativePixelAzimuth = uimenu(OOPSData.Handles.hPlotMenu,'Text','Image - Pixel azimuth w.r.t. image','MenuSelectedFcn',@mbPlotImageRelativePixelAzimuth);
%% draw the menu bar objects and pause for more predictable performance

drawnow
pause(0.5)

%% CHECKPOINT

disp('Setting up grid layout manager...')

%% Set up the MainGrid uigridlayout manager

pos = OOPSData.Handles.fH.Position;

% width and height of the large plots
width = round(pos(3)*0.38);

% and the small plots
swidth = round(width/2);
sheight = swidth;

% main grid for managing layout
OOPSData.Handles.MainGrid = uigridlayout(OOPSData.Handles.fH,[4,5]);
OOPSData.Handles.MainGrid.BackgroundColor = [0 0 0];

OOPSData.Handles.MainGrid.RowHeight = {'1x',swidth,swidth,'1x'};
OOPSData.Handles.MainGrid.RowSpacing = 0;
OOPSData.Handles.MainGrid.ColumnSpacing = 0;
OOPSData.Handles.MainGrid.Padding = [0 0 0 0];

OOPSData.Handles.MainGrid.ColumnWidth = {'1x',sheight,sheight,sheight,sheight};

%% CHECKPOINT

disp('Setting up non-image panels...')

%% Create the non-image panels (Summary, Selector, Settings, Log)

% panel to hold app info selector
OOPSData.Handles.AppInfoSelectorPanel = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off');
OOPSData.Handles.AppInfoSelectorPanel.Title = 'Summary Display Type';
OOPSData.Handles.AppInfoSelectorPanel.Layout.Row = 1;
OOPSData.Handles.AppInfoSelectorPanel.Layout.Column = 1;

% grid to hold img operations listbox
OOPSData.Handles.AppInfoSelectorPanelGrid = uigridlayout(OOPSData.Handles.AppInfoSelectorPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);

% img operations listbox
OOPSData.Handles.AppInfoSelector = uilistbox('parent',OOPSData.Handles.AppInfoSelectorPanelGrid,...
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

% panel to show project summary
OOPSData.Handles.AppInfoPanel = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off',...
    'Title','Project Summary',...
    'Scrollable','off');
OOPSData.Handles.AppInfoPanel.Layout.Row = 2;
OOPSData.Handles.AppInfoPanel.Layout.Column = 1;

%% set up main settings panel

OOPSData.Handles.SettingsPanel = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off',...
    'Title','Display Settings');
OOPSData.Handles.SettingsPanel.Layout.Row = 3;
OOPSData.Handles.SettingsPanel.Layout.Column = 1;

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

OOPSData.Handles.ColormapsSettingsGrid = uigridlayout(OOPSData.Handles.SettingsPanel,...
    [4,1],...
    "BackgroundColor",[0 0 0],...
    "Padding",[5 5 5 5],...
    "RowSpacing",5,...
    "ColumnSpacing",5,...
    "RowHeight",{20,'fit','1x',30},...
    "ColumnWidth",{'1x'});
    
OOPSData.Handles.SettingsDropDown = uidropdown(OOPSData.Handles.ColormapsSettingsGrid,...
    'Items',{'Colormaps','Azimuth Display','Scatter Plot','Swarm Plot','Label','Polar Histogram'},...
    'ItemsData',{'ColormapsSettings','AzimuthDisplaySettings','ScatterPlotSettings','SwarmPlotSettings','LabelSettings','PolarHistogramSettings'},...
    'Value','ColormapsSettings',...
    'ValueChangedFcn',@ChangeSettingsType,...
    'FontName',OOPSData.Settings.DefaultFont);

OOPSData.Handles.ColormapsImageTypePanel = uipanel(OOPSData.Handles.ColormapsSettingsGrid,...
    'Title','Image Type',...
    'FontName',OOPSData.Settings.DefaultFont);
    
OOPSData.Handles.ColormapsSettingsGrid2 = uigridlayout(OOPSData.Handles.ColormapsImageTypePanel,...
    [1,1],...
    "Padding",[0 0 0 0]);

OOPSData.Handles.ColormapsImageTypeSelector = uilistbox(OOPSData.Handles.ColormapsSettingsGrid2,...
    'Items',ImageTypeFullNames,...
    'ItemsData',ImageTypeFields,...
    'Value',ImageTypeFields{1},...
    'Tag','ImageTypeSelectBox',...
    'ValueChangedFcn',@ImageTypeSelectionChanged,...
    'FontName',OOPSData.Settings.DefaultFont);
    
OOPSData.Handles.ColormapsPanel = uipanel(OOPSData.Handles.ColormapsSettingsGrid,...
    'Title','Colormaps',...
    'FontName',OOPSData.Settings.DefaultFont);

OOPSData.Handles.ColormapsSettingsGrid3 = uigridlayout(OOPSData.Handles.ColormapsPanel,...
    [1,1],...
    "Padding",[0 0 0 0]);

OOPSData.Handles.ColormapsSelector = uilistbox(OOPSData.Handles.ColormapsSettingsGrid3,...
    'Items',ColormapNames,...
    'Value',OOPSData.Settings.ColormapsSettings.(ImageTypeFields{1}).Name,...
    'Tag','ColormapSelectBox',...
    'ValueChangedFcn',@ColormapSelectionChanged,...
    'FontName',OOPSData.Settings.DefaultFont);


% testing below
colormapIconStyles = matlab.ui.style.Style;
colormapIconStyles = repmat(colormapIconStyles,numel(OOPSData.Handles.ColormapsSelector.Items),1);
% add icon styles to each item in the colormap selector listbox to give a colormap preview
for colormapIdx = 1:numel(OOPSData.Handles.ColormapsSelector.Items)
    colormapIconStyles(colormapIdx).Icon = OOPSData.Settings.Colormaps.(OOPSData.Handles.ColormapsSelector.Items{colormapIdx}).colormapImage([10,256],'r');
    addStyle(OOPSData.Handles.ColormapsSelector,colormapIconStyles(colormapIdx),"item",colormapIdx);
end
% end testing

% panel to hold example colormap axes
OOPSData.Handles.ExampleColormapPanel = uipanel(OOPSData.Handles.ColormapsSettingsGrid);

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

OOPSData.Handles.ExampleColormapAx.Colormap = OOPSData.Settings.ColormapsSettings.(ImageTypeFields{k}).Map;
%% azimuth display settings

OOPSData.Handles.AzimuthDisplaySettingsGrid = uigridlayout(OOPSData.Handles.SettingsPanel,...
    [7,2],...
    'Visible','Off',...
    'BackgroundColor','Black',...
    'Padding',[5 5 5 5],...
    'RowSpacing',10,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20,20,20,20,20,20},...
    'ColumnWidth',{'fit','1x'});

OOPSData.Handles.AzimuthLineAlphaLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Azimuth line alpha',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthLineAlphaLabel.Layout.Row = 2;
OOPSData.Handles.AzimuthLineAlphaLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthLineAlphaDropdown = uidropdown(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
    'ItemsData',{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1},...
    'Value',OOPSData.Settings.AzimuthLineAlpha,...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.AzimuthLineAlphaDropdown.Layout.Row = 2;
OOPSData.Handles.AzimuthLineAlphaDropdown.Layout.Column = 2;

OOPSData.Handles.AzimuthLineWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Azimuth line width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthLineWidthLabel.Layout.Row = 3;
OOPSData.Handles.AzimuthLineWidthLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthLineWidthDropdown = uidropdown(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'1','2','3','4','5','6','7','8','9','10'},...
    'ItemsData',{1,2,3,4,5,6,7,8,9,10},...
    'Value',OOPSData.Settings.AzimuthLineWidth,...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.AzimuthLineWidthDropdown.Layout.Row = 3;
OOPSData.Handles.AzimuthLineWidthDropdown.Layout.Column = 2;

OOPSData.Handles.AzimuthLineScaleLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Azimuth Line Scale Factor',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthLineScaleLabel.Layout.Row = 4;
OOPSData.Handles.AzimuthLineScaleLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthLineScaleEditfield = uieditfield(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Value',num2str(OOPSData.Settings.AzimuthLineScale),...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.AzimuthLineScaleEditfield.Layout.Row = 4;
OOPSData.Handles.AzimuthLineScaleEditfield.Layout.Column = 2;

OOPSData.Handles.AzimuthLineScaleDownLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Number of Lines to Show',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthLineScaleDownLabel.Layout.Row = 5;
OOPSData.Handles.AzimuthLineScaleDownLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthLineScaleDownDropdown = uidropdown(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'All','Half','Quarter'},...
    'ItemsData',{1,2,4},...
    'Value',OOPSData.Settings.AzimuthScaleDownFactor,...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.AzimuthLineScaleDownDropdown.Layout.Row = 5;
OOPSData.Handles.AzimuthLineScaleDownDropdown.Layout.Column = 2;
OOPSData.Handles.AzimuthLineScaleDownDropdown.ItemsData = [1 2 4];

OOPSData.Handles.AzimuthColorModeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Line color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.AzimuthColorModeDropdownLabel.Layout.Row = 6;
OOPSData.Handles.AzimuthColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.AzimuthColorModeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'Direction','Magnitude','Mono'},...
    'Value',OOPSData.Settings.AzimuthColorMode,...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.AzimuthColorModeDropdown.Layout.Row = 6;
OOPSData.Handles.AzimuthColorModeDropdown.Layout.Column = 2;

OOPSData.Handles.ApplyAzimuthDisplaySettingsButton = uibutton(OOPSData.Handles.AzimuthDisplaySettingsGrid,...
    'Push',...
    'Text','Apply',...
    'ButtonPushedFcn',@ApplyAzimuthSettings,...
    'FontName',OOPSData.Settings.DefaultFont);
OOPSData.Handles.ApplyAzimuthDisplaySettingsButton.Layout.Row = 7;
OOPSData.Handles.ApplyAzimuthDisplaySettingsButton.Layout.Column = [1 2];

%% PolarHistogram settings

OOPSData.Handles.PolarHistogramSettingsGrid = uigridlayout(OOPSData.Handles.SettingsPanel,...
    [14,2],...
    'Visible','Off',...
    'BackgroundColor','Black',...
    'Padding',[5 5 5 5],...
    'RowSpacing',10,...
    'ColumnSpacing',5,...
    'RowHeight',{20,20,20,20,20,20,20,20,20,20,20,20,20,20},...
    'ColumnWidth',{'fit','1x'},...
    'Scrollable','on');

% variable to plot
OOPSData.Handles.PolarHistogramVariableLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Variable',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramVariableLabel.Layout.Row = 2;
OOPSData.Handles.PolarHistogramVariableLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramVariableDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',OOPSData.Settings.ObjectPolarPlotVariablesLong,...
    'ItemsData',OOPSData.Settings.ObjectPolarPlotVariables,...
    'Value',OOPSData.Settings.PolarHistogramVariable,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramVariableChanged);
OOPSData.Handles.PolarHistogramVariableDropdown.Layout.Row = 2;
OOPSData.Handles.PolarHistogramVariableDropdown.Layout.Column = 2;





% nBins
OOPSData.Handles.PolarHistogramnBinsLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Number of bins',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramnBinsLabel.Layout.Row = 3;
OOPSData.Handles.PolarHistogramnBinsLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramnBinsDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'12','24','48','96'},...
    'ItemsData',{12,24,48,96},...
    'Value',OOPSData.Settings.PolarHistogramnBins,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramnBinsChanged);
OOPSData.Handles.PolarHistogramnBinsDropdown.Layout.Row = 3;
OOPSData.Handles.PolarHistogramnBinsDropdown.Layout.Column = 2;

% wedgeFaceAlpha
OOPSData.Handles.PolarHistogramWedgeFaceAlphaLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Face alpha',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeFaceAlphaLabel.Layout.Row = 4;
OOPSData.Handles.PolarHistogramWedgeFaceAlphaLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeFaceAlphaDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
    'ItemsData',{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1},...
    'Value',OOPSData.Settings.PolarHistogramWedgeFaceAlpha,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramWedgeFaceAlphaChanged);
OOPSData.Handles.PolarHistogramWedgeFaceAlphaDropdown.Layout.Row = 4;
OOPSData.Handles.PolarHistogramWedgeFaceAlphaDropdown.Layout.Column = 2;

% wedgeFaceColor
OOPSData.Handles.PolarHistogramWedgeFaceColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Face color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeFaceColorLabel.Layout.Row = 5;
OOPSData.Handles.PolarHistogramWedgeFaceColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeFaceColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'flat','interp'},...
    'Value',OOPSData.Settings.PolarHistogramWedgeFaceColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramWedgeFaceColorChanged);
OOPSData.Handles.PolarHistogramWedgeFaceColorDropdown.Layout.Row = 5;
OOPSData.Handles.PolarHistogramWedgeFaceColorDropdown.Layout.Column = 2;

% wedgeLineWidth
OOPSData.Handles.PolarHistogramWedgeLineWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Wedge line width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeLineWidthLabel.Layout.Row = 6;
OOPSData.Handles.PolarHistogramWedgeLineWidthLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeLineWidthEditfield = uieditfield(...
    OOPSData.Handles.PolarHistogramSettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.PolarHistogramWedgeLineWidth,...
    'Limits',[0 10],...
    'ValueDisplayFormat','%.1f points',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramWedgeLineWidthChanged);
OOPSData.Handles.PolarHistogramWedgeLineWidthEditfield.Layout.Row = 6;
OOPSData.Handles.PolarHistogramWedgeLineWidthEditfield.Layout.Column = 2;

% wedgeEdgeColor
OOPSData.Handles.PolarHistogramWedgeEdgeColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Edge color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeEdgeColorLabel.Layout.Row = 7;
OOPSData.Handles.PolarHistogramWedgeEdgeColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeEdgeColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'flat','interp'},...
    'Value',OOPSData.Settings.PolarHistogramWedgeEdgeColor,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramWedgeEdgeColorChanged);
OOPSData.Handles.PolarHistogramWedgeEdgeColorDropdown.Layout.Row = 7;
OOPSData.Handles.PolarHistogramWedgeEdgeColorDropdown.Layout.Column = 2;

% wedgeEdgeColor
OOPSData.Handles.PolarHistogramWedgeLineColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Edge color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramWedgeLineColorLabel.Layout.Row = 8;
OOPSData.Handles.PolarHistogramWedgeLineColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramWedgeLineColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Choose'},...
    'ItemsData',{[0 0 0],[1 1 1],[]},...
    'Value',[],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramWedgeLineColorChanged);
OOPSData.Handles.PolarHistogramWedgeLineColorDropdown.Layout.Row = 8;
OOPSData.Handles.PolarHistogramWedgeLineColorDropdown.Layout.Column = 2;

% gridline colors
OOPSData.Handles.PolarHistogramGridlinesColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Gridlines color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramGridlinesColorLabel.Layout.Row = 9;
OOPSData.Handles.PolarHistogramGridlinesColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramGridlinesColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Gray','Choose'},...
    'ItemsData',{[0 0 0],[1 1 1],[.9 .9 .9],[]},...
    'Value',[],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramGridlinesColorChanged);
OOPSData.Handles.PolarHistogramGridlinesColorDropdown.Layout.Row = 9;
OOPSData.Handles.PolarHistogramGridlinesColorDropdown.Layout.Column = 2;

% label colors
OOPSData.Handles.PolarHistogramLabelsColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Labels color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramLabelsColorLabel.Layout.Row = 10;
OOPSData.Handles.PolarHistogramLabelsColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramLabelsColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Choose'},...
    'ItemsData',{[0 0 0],[1 1 1],[]},...
    'Value',[],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramLabelsColorChanged);
OOPSData.Handles.PolarHistogramLabelsColorDropdown.Layout.Row = 10;
OOPSData.Handles.PolarHistogramLabelsColorDropdown.Layout.Column = 2;

% gridline line widths
OOPSData.Handles.PolarHistogramGridlinesLineWidthLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Gridlines line width',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramGridlinesLineWidthLabel.Layout.Row = 11;
OOPSData.Handles.PolarHistogramGridlinesLineWidthLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramGridlinesLineWidthEditfield = uieditfield(...
    OOPSData.Handles.PolarHistogramSettingsGrid,...
    'numeric',...
    'Value',OOPSData.Settings.PolarHistogramGridlinesLineWidth,...
    'Limits',[0 10],...
    'ValueDisplayFormat','%.1f points',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramGridlinesLineWidthChanged);
OOPSData.Handles.PolarHistogramGridlinesLineWidthEditfield.Layout.Row = 11;
OOPSData.Handles.PolarHistogramGridlinesLineWidthEditfield.Layout.Column = 2;

% circleBackgroundColor
OOPSData.Handles.PolarHistogramCircleBackgroundColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Circle background color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramCircleBackgroundColorLabel.Layout.Row = 12;
OOPSData.Handles.PolarHistogramCircleBackgroundColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramCircleBackgroundColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Choose'},...
    'ItemsData',{[0 0 0],[1 1 1],[]},...
    'Value',[],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramCircleBackgroundColorChanged);
OOPSData.Handles.PolarHistogramCircleBackgroundColorDropdown.Layout.Row = 12;
OOPSData.Handles.PolarHistogramCircleBackgroundColorDropdown.Layout.Column = 2;

% circleColor
OOPSData.Handles.PolarHistogramCircleColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Circle line color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramCircleColorLabel.Layout.Row = 13;
OOPSData.Handles.PolarHistogramCircleColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramCircleColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Choose'},...
    'ItemsData',{[0 0 0],[1 1 1],[]},...
    'Value',[],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramCircleColorChanged);
OOPSData.Handles.PolarHistogramCircleColorDropdown.Layout.Row = 13;
OOPSData.Handles.PolarHistogramCircleColorDropdown.Layout.Column = 2;

% BackgroundColor
OOPSData.Handles.PolarHistogramBackgroundColorLabel = uilabel(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Text','Background color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.PolarHistogramBackgroundColorLabel.Layout.Row = 14;
OOPSData.Handles.PolarHistogramBackgroundColorLabel.Layout.Column = 1;

OOPSData.Handles.PolarHistogramBackgroundColorDropdown = uidropdown(...
    'Parent',OOPSData.Handles.PolarHistogramSettingsGrid,...
    'Items',{'Black','White','Choose'},...
    'ItemsData',{[0 0 0],[1 1 1],[]},...
    'Value',[],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@PolarHistogramBackgroundColorChanged);
OOPSData.Handles.PolarHistogramBackgroundColorDropdown.Layout.Row = 14;
OOPSData.Handles.PolarHistogramBackgroundColorDropdown.Layout.Column = 2;



%% ScatterPlot settings

OOPSData.Handles.ScatterPlotSettingsGrid = uigridlayout(OOPSData.Handles.SettingsPanel,...
    [3,1],...
    'BackgroundColor','Black',...
    'Visible','Off',...
    'Padding',[5 5 5 5],...
    'RowSpacing',5,...
    'ColumnSpacing',5,...
    'RowHeight',{20,'1x','1x'},...
    'ColumnWidth',{'1x'});

% setting up x-axis variable selection
OOPSData.Handles.ScatterPlotXVarListBoxPanel = uipanel(OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Title','X-axis Variable');
OOPSData.Handles.ScatterPlotXVarListBoxPanel.Layout.Row = 2;
OOPSData.Handles.ScatterPlotXVarListBoxPanel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotXVarGrid = uigridlayout(OOPSData.Handles.ScatterPlotXVarListBoxPanel,...
    [1,1],...
    "Padding",[0 0 0 0]);

OOPSData.Handles.ScatterPlotXVarSelectBox = uilistbox(OOPSData.Handles.ScatterPlotXVarGrid,...
    'Items', OOPSData.Settings.ObjectPlotVariablesLong,...
    'ItemsData', OOPSData.Settings.ObjectPlotVariables,...
    'Value',OOPSData.Settings.ScatterPlotXVariable,...
    'Tag','XVariable',...
    'ValueChangedFcn',@ScatterPlotVariablesChanged,...
    'FontName',OOPSData.Settings.DefaultFont);

% setting up y-axis variable selection
OOPSData.Handles.ScatterPlotYVarListBoxPanel = uipanel(OOPSData.Handles.ScatterPlotSettingsGrid,...
    'Title','Y-axis Variable');
OOPSData.Handles.ScatterPlotYVarListBoxPanel.Layout.Row = 3;
OOPSData.Handles.ScatterPlotYVarListBoxPanel.Layout.Column = 1;

OOPSData.Handles.ScatterPlotYVarGrid = uigridlayout(OOPSData.Handles.ScatterPlotYVarListBoxPanel,...
    [1,1],...
    "Padding",[0 0 0 0]);

OOPSData.Handles.ScatterPlotYVarSelectBox = uilistbox(OOPSData.Handles.ScatterPlotYVarGrid,...
    'Items', OOPSData.Settings.ObjectPlotVariablesLong,...
    'ItemsData', OOPSData.Settings.ObjectPlotVariables,...
    'Value',OOPSData.Settings.ScatterPlotYVariable,...
    'Tag','YVariable',...
    'ValueChangedFcn',@ScatterPlotVariablesChanged,...
    'FontName',OOPSData.Settings.DefaultFont);
%% SwarmPlot settings

OOPSData.Handles.SwarmPlotSettingsGrid = uigridlayout(OOPSData.Handles.SettingsPanel,[4,2],...
    'BackgroundColor','Black',...
    'Visible','Off',...
    'Scrollable','on');
OOPSData.Handles.SwarmPlotSettingsGrid.Padding = [5 5 5 5];
OOPSData.Handles.SwarmPlotSettingsGrid.RowSpacing = 5;
OOPSData.Handles.SwarmPlotSettingsGrid.ColumnSpacing = 5;
OOPSData.Handles.SwarmPlotSettingsGrid.RowHeight = {20,'1x',20,20,20,20,20};
OOPSData.Handles.SwarmPlotSettingsGrid.ColumnWidth = {'fit','1x'};

% setting up x-axis variable selection
OOPSData.Handles.SwarmPlotYVarListBoxPanel = uipanel(OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Title','Y-axis Variable');
OOPSData.Handles.SwarmPlotYVarListBoxPanel.Layout.Row = 2;
OOPSData.Handles.SwarmPlotYVarListBoxPanel.Layout.Column = [1 2];

OOPSData.Handles.SwarmPlotYVarGrid = uigridlayout(OOPSData.Handles.SwarmPlotYVarListBoxPanel,[1,1]);
OOPSData.Handles.SwarmPlotYVarGrid.Padding = [0 0 0 0];

OOPSData.Handles.SwarmPlotYVarSelectBox = uilistbox(OOPSData.Handles.SwarmPlotYVarGrid,...
    'Items', OOPSData.Settings.ObjectPlotVariablesLong,...
    'ItemsData', OOPSData.Settings.ObjectPlotVariables,...
    'Value',OOPSData.Settings.SwarmPlotYVariable,...
    'Tag','YVariable',...
    'ValueChangedFcn',@SwarmPlotYVariableChanged,...
    'FontName',OOPSData.Settings.DefaultFont);

% grouping type
OOPSData.Handles.SwarmPlotGroupingTypeDropdownLabel = uilabel(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Grouping type',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotGroupingTypeDropdownLabel.Layout.Row = 3;
OOPSData.Handles.SwarmPlotGroupingTypeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotGroupingTypeDropdown = uidropdown(...
    'Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Group','Label','Both'},...
    'ItemsData',{'Group','Label','Both'},...
    'Value',OOPSData.Settings.SwarmPlotGroupingType,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotGroupingTypeChanged);
OOPSData.Handles.SwarmPlotGroupingTypeDropdown.Layout.Row = 3;
OOPSData.Handles.SwarmPlotGroupingTypeDropdown.Layout.Column = 2;

% color mode
OOPSData.Handles.SwarmPlotColorModeDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Color mode',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotColorModeDropdownLabel.Layout.Row = 4;
OOPSData.Handles.SwarmPlotColorModeDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotColorModeDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Magnitude','ID'},...
    'ItemsData',{'Magnitude','ID'},...
    'Value',OOPSData.Settings.SwarmPlotColorMode,...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotColorModeChanged);
OOPSData.Handles.SwarmPlotColorModeDropdown.Layout.Row = 4;
OOPSData.Handles.SwarmPlotColorModeDropdown.Layout.Column = 2;

% background color
OOPSData.Handles.SwarmPlotBackgroundColorDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Background color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotBackgroundColorDropdownLabel.Layout.Row = 5;
OOPSData.Handles.SwarmPlotBackgroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotBackgroundColorDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Black','White','Choose'},...
    'ItemsData',{[0 0 0],[1 1 1],[]},...
    'Value',[],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotBackgroundColorChanged);
OOPSData.Handles.SwarmPlotBackgroundColorDropdown.Layout.Row = 5;
OOPSData.Handles.SwarmPlotBackgroundColorDropdown.Layout.Column = 2;

% foreground color
OOPSData.Handles.SwarmPlotForegroundColorDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Foreground color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotForegroundColorDropdownLabel.Layout.Row = 6;
OOPSData.Handles.SwarmPlotForegroundColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotForegroundColorDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Black','White','Choose'},...
    'ItemsData',{[0 0 0],[1 1 1],[]},...
    'Value',[],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotForegroundColorChanged);
OOPSData.Handles.SwarmPlotForegroundColorDropdown.Layout.Row = 6;
OOPSData.Handles.SwarmPlotForegroundColorDropdown.Layout.Column = 2;

% error bars color
OOPSData.Handles.SwarmPlotErrorBarColorDropdownLabel = uilabel('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Error bars color',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontColor','White');
OOPSData.Handles.SwarmPlotErrorBarColorDropdownLabel.Layout.Row = 7;
OOPSData.Handles.SwarmPlotErrorBarColorDropdownLabel.Layout.Column = 1;

OOPSData.Handles.SwarmPlotErrorBarColorDropdown = uidropdown('Parent',OOPSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Black','White','Choose'},...
    'ItemsData',{[0 0 0],[1 1 1],[]},...
    'Value',[],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotErrorBarColorChanged);
OOPSData.Handles.SwarmPlotErrorBarColorDropdown.Layout.Row = 7;
OOPSData.Handles.SwarmPlotErrorBarColorDropdown.Layout.Column = 2;

%% Label settings

OOPSData.Handles.LabelSettingsGrid = uigridlayout(OOPSData.Handles.SettingsPanel,[2,1],...
    'BackgroundColor','Black',...
    'Visible','Off');
OOPSData.Handles.LabelSettingsGrid.Padding = [5 5 5 5];
OOPSData.Handles.LabelSettingsGrid.RowSpacing = 5;
OOPSData.Handles.LabelSettingsGrid.ColumnSpacing = 5;
OOPSData.Handles.LabelSettingsGrid.RowHeight = {20,'1x'};
OOPSData.Handles.LabelSettingsGrid.ColumnWidth = {'1x'};

% setting up x-axis variable selection
OOPSData.Handles.LabelListBoxPanel = uipanel(OOPSData.Handles.LabelSettingsGrid,...
    'Title','Object labels');
OOPSData.Handles.LabelListBoxPanel.Layout.Row = 2;
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

uitreenode(OOPSData.Handles.LabelTree,...
    'Text',OOPSData.Settings.ObjectLabels(1).Name,...
    'NodeData',OOPSData.Settings.ObjectLabels(1),...
    'ContextMenu',OOPSData.Handles.LabelContextMenu,...
    'Icon',makeRGBColorSquare(OOPSData.Settings.ObjectLabels(1).Color,10));

% draw the current figure to update final container sizes
drawnow
pause(0.05)

%% ImgOperations grid layout (currently for interactive thresholding and intensity display)

OOPSData.Handles.ImageOperationsGrid = uigridlayout(OOPSData.Handles.MainGrid,...
    [1,2],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);
OOPSData.Handles.ImageOperationsGrid.ColumnWidth = {'0.25x','0.75x'};
OOPSData.Handles.ImageOperationsGrid.ColumnSpacing = 0;
OOPSData.Handles.ImageOperationsGrid.Layout.Row = 1;
OOPSData.Handles.ImageOperationsGrid.Layout.Column = [4 5];

% panel to hold img operations listbox grid
OOPSData.Handles.ImageOperationsSelectorPanel = uipanel(OOPSData.Handles.ImageOperationsGrid,...
    'Visible','Off');
OOPSData.Handles.ImageOperationsSelectorPanel.Title = 'Image Operations';
OOPSData.Handles.ImageOperationsSelectorPanel.Layout.Column = 1;

% grid to hold img operations listbox
OOPSData.Handles.ImageOperationsSelectorPanelGrid = uigridlayout(OOPSData.Handles.ImageOperationsSelectorPanel,...
    [1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);
% img operations listbox
OOPSData.Handles.ImageOperationsSelector = uilistbox(...
    'parent',OOPSData.Handles.ImageOperationsSelectorPanelGrid,...
    'Visible','Off',...
    'enable','on',...
    'tag','SettingsSelector',...
    'Items',{'Mask Threshold','Intensity Display'},...
    'BackgroundColor',[1 1 1],...
    'FontColor',[0 0 0],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'MultiSelect','Off',...
    'ValueChangedFcn',@ChangeImageOperation);

OOPSData.Handles.ImageOperationsPanel = uipanel(OOPSData.Handles.ImageOperationsGrid,...
    'Visible','Off');
OOPSData.Handles.ImageOperationsPanel.Layout.Column = 2;
OOPSData.Handles.ImageOperationsPanel.Title = 'Adjust Otsu threshhold';

%% LogPanel

% panel to display log messages (updates user on running/completed processes)
OOPSData.Handles.LogPanel = uipanel(OOPSData.Handles.MainGrid,...
    'Visible','Off');
OOPSData.Handles.LogPanel.Title = 'Log';
OOPSData.Handles.LogPanel.Layout.Row = 4;
OOPSData.Handles.LogPanel.Layout.Column = [1 5];

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
    'Title','Group Selection',...
    'Visible','Off');
OOPSData.Handles.GroupSelectorPanelGrid = uigridlayout(OOPSData.Handles.GroupSelectorPanel,[1,1],...
    'Padding',[0 0 0 0]);
OOPSData.Handles.GroupTree = uitree(OOPSData.Handles.GroupSelectorPanelGrid,...
    'SelectionChangedFcn',@GroupSelectionChanged,...
    'NodeTextChangedFcn',@GroupTreeNodeTextChanged,...
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
    'MenuSelectedFcn',@AddNewGroup);
OOPSData.Handles.GroupTree.ContextMenu = OOPSData.Handles.GroupTreeContextMenu;
% context menu for individual groups
OOPSData.Handles.GroupContextMenu = uicontextmenu(OOPSData.Handles.fH);
OOPSData.Handles.GroupContextMenu_Delete = uimenu(OOPSData.Handles.GroupContextMenu,...
    'Text','Delete group',...
    'MenuSelectedFcn',{@DeleteGroup,OOPSData.Handles.fH});
OOPSData.Handles.GroupContextMenu_ChangeColor = uimenu(OOPSData.Handles.GroupContextMenu,...
    'Text','Change color',...
    'MenuSelectedFcn',{@EditGroupColor,OOPSData.Handles.fH});
OOPSData.Handles.GroupContextMenu_New = uimenu(OOPSData.Handles.GroupContextMenu,...
    'Text','New group',...
    'MenuSelectedFcn',@AddNewGroup);

% image selector (uitree)
OOPSData.Handles.ImageSelectorPanel = uipanel(OOPSData.Handles.SelectorGrid,...
    'Title','Image Selection',...
    'Visible','Off');
OOPSData.Handles.ImageSelectorPanelGrid = uigridlayout(OOPSData.Handles.ImageSelectorPanel,[1,1],...
    'Padding',[0 0 0 0]);
OOPSData.Handles.ImageTree = uitree(OOPSData.Handles.ImageSelectorPanelGrid,...
    'SelectionChangedFcn',@ImageSelectionChanged,...
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
    'MenuSelectedFcn',{@DeleteImage,OOPSData.Handles.fH});

% object selector (listbox, will replace with tree, but too slow for now)
OOPSData.Handles.ObjectSelectorPanel = uipanel(OOPSData.Handles.SelectorGrid,...
    'Title','Object Selection',...
    'Visible','Off');
OOPSData.Handles.ObjectSelectorPanelGrid = uigridlayout(OOPSData.Handles.ObjectSelectorPanel,[1,1],...
    'Padding',[0 0 0 0]);
OOPSData.Handles.ObjectSelector = uilistbox(...
    'parent',OOPSData.Handles.ObjectSelectorPanelGrid,...
    'Visible','Off',...
    'enable','on',...
    'tag','ObjectListBox',...
    'Items',{'Select image to view objects...'},...
    'ValueChangedFcn',@ChangeActiveObject,...
    'BackgroundColor',[1 1 1],...
    'FontColor',[0 0 0],...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'MultiSelect','off',...
    'Visible','Off',...
    'Interruptible','off'); %% might need to change to on

%% CHECKPOINT

disp('Setting up thresholding histogram/slider...')

%% Interactive User Thresholding

OOPSData.Handles.ThreshSliderGrid = uigridlayout(OOPSData.Handles.ImageOperationsPanel,[1,1],...
    'Padding',[0 0 0 0],...
    'BackgroundColor','Black');
% axes to show intensity histogram
OOPSData.Handles.ThreshAxH = uiaxes(OOPSData.Handles.ThreshSliderGrid,...
    'Color','Black',...
    'Visible','On',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontSize',12,...
    'FontWeight','Bold',...
    'XTick',[],...
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
    'ButtonDownFcn',@StartUserThresholding);
disableDefaultInteractivity(OOPSData.Handles.ThreshAxH);
% graphics/display sometimes unpredictable when toolbar is visible, let's turn it off
OOPSData.Handles.ThreshAxH.Toolbar.Visible = 'Off';
% generate some random data (1024x1024) for histogram placeholder
RandomData = rand(1024,1024);
% build histogram from random data
[IntensityBinCenters,IntensityHistPlot] = BuildHistogram(RandomData);
% add histogram info to bar plot, place plot in thresholding axes
OOPSData.Handles.ThreshBar = bar(OOPSData.Handles.ThreshAxH,IntensityBinCenters,IntensityHistPlot,...
    'FaceColor',[0.5 0.5 0.5],...
    'EdgeColor','None',...
    'PickableParts','None');
% vertical line with draggable behavior for interactive thresholding
OOPSData.Handles.CurrentThresholdLine = xline(OOPSData.Handles.ThreshAxH,0.5,'-',{'Threshold = 0.5'},...
    'Tag','CurrentThresholdLine',...
    'LabelOrientation','Horizontal',...
    'PickableParts','None',...
    'HitTest','Off',...
    'FontName',OOPSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'LineWidth',1.5,...
    'Color','White',...
    'LabelVerticalAlignment','Middle');

clear RandomData

drawnow
pause(0.1)

%% Intensity display limits range sliders

OOPSData.Handles.IntensitySlidersGrid = uigridlayout(OOPSData.Handles.ImageOperationsPanel,[2 1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[5 5 5 5],...
    'Visible','Off');
OOPSData.Handles.IntensitySlidersGrid.RowSpacing = 0;
OOPSData.Handles.IntensitySlidersGrid.RowHeight = {'1x','1x'};

OOPSData.Handles.PrimaryIntensitySlider = RangeSlider('Parent',OOPSData.Handles.IntensitySlidersGrid,...
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

OOPSData.Handles.ReferenceIntensitySlider = RangeSlider('Parent',OOPSData.Handles.IntensitySlidersGrid,...
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

%% CHECKPOINT

disp('Setting up log window...')

%% Log Window
OOPSData.Handles.LogWindowGrid = uigridlayout(OOPSData.Handles.LogPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);
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

disp('Setting up summary table...')

%% Summary table for current project/group/image/object
% summary table for the project
OOPSData.Handles.ProjectSummaryTableGrid = uigridlayout(OOPSData.Handles.AppInfoPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Scrollable','on',...
    'RowHeight',{'fit'},...
    'Visible','off');
OOPSData.Handles.ProjectSummaryTable = uitable(OOPSData.Handles.ProjectSummaryTableGrid);
% summary table for the current group
OOPSData.Handles.GroupSummaryTableGrid = uigridlayout(OOPSData.Handles.AppInfoPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Scrollable','on',...
    'Visible','off',...
    'RowHeight',{'fit'});
OOPSData.Handles.GroupSummaryTable = uitable(OOPSData.Handles.GroupSummaryTableGrid);
% summary table for the current image
OOPSData.Handles.ImageSummaryTableGrid = uigridlayout(OOPSData.Handles.AppInfoPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Scrollable','on',...
    'Visible','off',...
    'RowHeight',{'fit'});
OOPSData.Handles.ImageSummaryTable = uitable(OOPSData.Handles.ImageSummaryTableGrid);
% summary table for current object
OOPSData.Handles.ObjectSummaryTableGrid = uigridlayout(OOPSData.Handles.AppInfoPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Scrollable','on',...
    'Visible','off',...
    'RowHeight',{'fit'});
OOPSData.Handles.ObjectSummaryTable = uitable(OOPSData.Handles.ObjectSummaryTableGrid);
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
    
    OOPSData.Handles.FFCAxH(k) = SetAxisTitle(OOPSData.Handles.FFCAxH(k),['Flat-Field Image (' num2str((k-1)*45) '^{\circ} Excitation)']);
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
    
    OOPSData.Handles.RawIntensityAxH(k) = SetAxisTitle(OOPSData.Handles.RawIntensityAxH(k),['Raw Intensity (' num2str((k-1)*45) '^{\circ} Excitation)']);
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
    OOPSData.Handles.PolFFCAxH(k) = SetAxisTitle(OOPSData.Handles.PolFFCAxH(k),['Flat-Field Corrected Intensity (' num2str((k-1)*45) '^{\circ} Excitation)']);
    
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
        'Color','Black',...
        'Visible','off');
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
    OOPSData.Handles.AverageIntensityAxH = SetAxisTitle(OOPSData.Handles.AverageIntensityAxH,'Average Intensity (Flat-Field Corrected)');
    % set celormap
    OOPSData.Handles.AverageIntensityAxH.Colormap = OOPSData.Settings.IntensityColormap;
    % hide axes toolbar and title, turn off hittest
    OOPSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
    OOPSData.Handles.AverageIntensityAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.AverageIntensityAxH);
    % hide/diable image
    OOPSData.Handles.AverageIntensityImgH.Visible = 'Off';
    OOPSData.Handles.AverageIntensityImgH.HitTest = 'Off';

    %% Order Factor

    OOPSData.Handles.OrderFactorAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','OrderFactor',...
        'XTick',[],...
        'YTick',[],...
        'CLim',[0 1],...
        'Color','Black',...
        'Visible','off');
    % save original values to be restored after calling imshow()
    pbarOriginal = OOPSData.Handles.OrderFactorAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.OrderFactorAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.OrderFactorImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.OrderFactorAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.OrderFactorImgH,'Tag','OrderFactorImage');
    % restore original values after imshow() call
    OOPSData.Handles.OrderFactorAxH = restore_axis_defaults(OOPSData.Handles.OrderFactorAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    OOPSData.Handles.OrderFactorAxH = SetAxisTitle(OOPSData.Handles.OrderFactorAxH,'Pixel-by-pixel Order Factor');

    % make colorbar and set colormap for the axes, hide the colorbar and disable interactions with it
    OOPSData.Handles.OFCbar = colorbar(OOPSData.Handles.OrderFactorAxH,'location','east','color','white','tag','OFCbar');
    OOPSData.Handles.OrderFactorAxH.Colormap = OOPSData.Settings.OrderFactorColormap;
    OOPSData.Handles.OFCbar.Visible = 'Off';
    OOPSData.Handles.OFCbar.HitTest = 'Off';

    % hide axes toolbar and title, disable click interactivity, disable all default interactivity
    OOPSData.Handles.OrderFactorAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.OrderFactorAxH.Title.Visible = 'Off';
    OOPSData.Handles.OrderFactorAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.OrderFactorAxH);
    
    OOPSData.Handles.OrderFactorImgH.Visible = 'Off';
    OOPSData.Handles.OrderFactorImgH.HitTest = 'Off';
    
    %% Axis for swarm plots

    OOPSData.Handles.SwarmPlotGrid = uigridlayout(OOPSData.Handles.ImgPanel2,[1,1],...
        'Padding',[0 0 0 0],...
        'BackgroundColor',OOPSData.Settings.SwarmPlotBackgroundColor,...
        'Tag','SwarmPlotGrid',...
        'Visible','Off',...
        'ColumnWidth',{'1x'},...
        'RowHeight',{'1x'});

    OOPSData.Handles.SwarmPlotAxH = uiaxes(OOPSData.Handles.SwarmPlotGrid,...
        'Tag','SwarmPlotAxes',...
        'XTick',[],...
        'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0],...
        'NextPlot','Add',...
        'Visible','Off',...
        'Color',OOPSData.Settings.SwarmPlotBackgroundColor,...
        'XColor','White',...
        'YColor','White',...
        'HitTest','Off',...
        'FontName',OOPSData.Settings.DefaultPlotFont);
    
    OOPSData.Handles.SwarmPlotAxH.Interactions = dataTipInteraction;
    axtoolbar(OOPSData.Handles.SwarmPlotAxH,{});

    % set axis title
    OOPSData.Handles.SwarmPlotAxH = SetAxisTitle(OOPSData.Handles.SwarmPlotAxH,'Object OF (per group)');
    OOPSData.Handles.SwarmPlotAxH.XAxis.Label.String = "Group";
    OOPSData.Handles.SwarmPlotAxH.XAxis.Color = OOPSData.Settings.SwarmPlotForegroundColor;
    OOPSData.Handles.SwarmPlotAxH.XAxis.FontName = OOPSData.Settings.DefaultPlotFont;
    OOPSData.Handles.SwarmPlotAxH.YAxis.Label.String = "Object Order Factor";
    OOPSData.Handles.SwarmPlotAxH.YAxis.Color = OOPSData.Settings.SwarmPlotForegroundColor;
    OOPSData.Handles.SwarmPlotAxH.YAxis.FontName = OOPSData.Settings.DefaultPlotFont;
    OOPSData.Handles.SwarmPlotAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.SwarmPlotAxH.Title.Visible = 'Off';

    % set up context menu for swarm plot
    OOPSData.Handles.SwarmPlotContextMenu = uicontextmenu(OOPSData.Handles.fH);
    % set up context menu options
    OOPSData.Handles.SwarmPlotContextMenu_CopyVector = uimenu(OOPSData.Handles.SwarmPlotContextMenu,...
        'Text','Copy as vector graphic',...
        'MenuSelectedFcn',@CopySwarmPlotVector);

    % add the context menu to the axes
    OOPSData.Handles.SwarmPlotAxH.ContextMenu = OOPSData.Handles.SwarmPlotContextMenu;
    
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
    OOPSData.Handles.ScatterPlotAxH = SetAxisTitle(OOPSData.Handles.ScatterPlotAxH,'Object-Average OF vs Local S/B');
    
    OOPSData.Handles.ScatterPlotAxH.XAxis.Label.String = "Local S/B";
    OOPSData.Handles.ScatterPlotAxH.XAxis.Color = OOPSData.Settings.ScatterPlotForegroundColor;
    OOPSData.Handles.ScatterPlotAxH.XAxis.Label.FontName = OOPSData.Settings.DefaultPlotFont;
    OOPSData.Handles.ScatterPlotAxH.YAxis.Label.String = "Object-Average Order Factor";
    OOPSData.Handles.ScatterPlotAxH.YAxis.Color = OOPSData.Settings.ScatterPlotForegroundColor;
    OOPSData.Handles.ScatterPlotAxH.YAxis.Label.FontName = OOPSData.Settings.DefaultPlotFont;
    OOPSData.Handles.ScatterPlotAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.ScatterPlotAxH.Title.Visible = 'Off';

    % set up context menu for scatter plot
    OOPSData.Handles.ScatterPlotContextMenu = uicontextmenu(OOPSData.Handles.fH);
    % set up context menu options
    OOPSData.Handles.ScatterPlotContextMenu_CopyVector = uimenu(OOPSData.Handles.ScatterPlotContextMenu,...
        'Text','Copy as vector graphic',...
        'MenuSelectedFcn',@CopyScatterPlotVector);
    OOPSData.Handles.ScatterPlotContextMenu_BackgroundColor = uimenu(OOPSData.Handles.ScatterPlotContextMenu,...
        'Text','Background color',...
        'MenuSelectedFcn',@SetScatterPlotBackgroundColor);
    OOPSData.Handles.ScatterPlotContextMenu_AxisColor = uimenu(OOPSData.Handles.ScatterPlotContextMenu,...
        'Text','Foreground color',...
        'MenuSelectedFcn',@SetScatterPlotForegroundColor);

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

    %% MASK
    OOPSData.Handles.MaskAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','Mask',...
        'XTick',[],...
        'YTick',[],...
        'Visible','off');
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
    OOPSData.Handles.MaskAxH = SetAxisTitle(OOPSData.Handles.MaskAxH,'Binary Mask');
    
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
        'YTick',[],...
        'Color','Black',...
        'Visible','off');
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
    OOPSData.Handles.AzimuthAxH = SetAxisTitle(OOPSData.Handles.AzimuthAxH,'Pixel-by-pixel Azimuth');
    % get the default azimuth colormap (one half)
    tempmap = hsv;
    % vertically concatenate to make the full map
    OOPSData.Handles.AzimuthAxH.Colormap = vertcat(tempmap,tempmap);
    % custom colormap/colorbar for azimuth axes
    OOPSData.Handles.PhaseBarAxH = phasebarmod('rad','Location','se','axes',OOPSData.Handles.AzimuthAxH);
    OOPSData.Handles.PhaseBarAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.PhaseBarAxH.HitTest = 'Off';
    OOPSData.Handles.PhaseBarAxH.PickableParts = 'None';
    OOPSData.Handles.PhaseBarComponents = OOPSData.Handles.PhaseBarAxH.Children;
    set(OOPSData.Handles.PhaseBarComponents,'Visible','Off');
    OOPSData.Handles.PhaseBarAxH.Colormap = vertcat(tempmap,tempmap);

    
    OOPSData.Handles.AzimuthAxH.Title.Visible = 'Off';   
    OOPSData.Handles.AzimuthAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.AzimuthAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.AzimuthAxH);

    OOPSData.Handles.AzimuthImgH.Visible = 'Off';
    OOPSData.Handles.AzimuthImgH.HitTest = 'Off';

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
    OOPSData.Handles.ObjectPolFFCAxH = SetAxisTitle(OOPSData.Handles.ObjectPolFFCAxH,'Flat-Field-Corrected Average Intensity');
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
    OOPSData.Handles.ObjectMaskAxH = SetAxisTitle(OOPSData.Handles.ObjectMaskAxH,'Object Binary Image');
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
    OOPSData.Handles.ObjectAzimuthOverlayAxH = SetAxisTitle(OOPSData.Handles.ObjectAzimuthOverlayAxH,'Object Azimuth Overlay');
    
    OOPSData.Handles.ObjectAzimuthOverlayAxH.Colormap = OOPSData.Settings.IntensityColormap;
    
    OOPSData.Handles.ObjectAzimuthOverlayAxH.Title.Visible = 'Off';
    OOPSData.Handles.ObjectAzimuthOverlayAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.ObjectAzimuthOverlayAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.ObjectAzimuthOverlayAxH);
    
    OOPSData.Handles.ObjectAzimuthOverlayImgH.Visible = 'Off';
    OOPSData.Handles.ObjectAzimuthOverlayImgH.HitTest = 'Off';

    %% Object OF Image
    
    OOPSData.Handles.ObjectOFAxH = uiaxes(OOPSData.Handles.SmallPanels(2,1),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectOF',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = OOPSData.Handles.ObjectOFAxH.PlotBoxAspectRatio;
    tagOriginal = OOPSData.Handles.ObjectOFAxH.Tag;
    % place placeholder image on axis
    OOPSData.Handles.ObjectOFImgH = imshow(full(emptyimage),'Parent',OOPSData.Handles.ObjectOFAxH);
    % set a tag so our callback functions can find the image
    set(OOPSData.Handles.ObjectOFImgH,'Tag','ObjectOFImage');
    % restore original values after imshow() call
    OOPSData.Handles.ObjectOFAxH = restore_axis_defaults(OOPSData.Handles.ObjectOFAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    OOPSData.Handles.ObjectOFAxH = SetAxisTitle(OOPSData.Handles.ObjectOFAxH,'Object OF Image');
    
    OOPSData.Handles.ObjectOFAxH.Colormap = OOPSData.Settings.OrderFactorColormap;
    
    OOPSData.Handles.ObjectOFAxH.Title.Visible = 'Off';
    OOPSData.Handles.ObjectOFAxH.Toolbar.Visible = 'Off';
    OOPSData.Handles.ObjectOFAxH.HitTest = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.ObjectOFAxH);
    
    OOPSData.Handles.ObjectOFImgH.Visible = 'Off';
    OOPSData.Handles.ObjectOFImgH.HitTest = 'Off';
    
    %% Object Intensity Fit Plots
    
    OOPSData.Handles.ObjectIntensityPlotAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Visible','Off',...
        'Units','Normalized',...
        'OuterPosition',[0 0 1 0.75],...
        'Tag','ObjectIntensityPlotAxH',...
        'NextPlot','Add',...
        'Color','Black',...
        'Box','On',...
        'XColor','White',...
        'YColor','White',...
        'BoxStyle','Back',...
        'HitTest','Off',...
        'XLim',[0 pi],...
        'XTick',[0 pi/4 pi/2 3*pi/4 pi],...
        'XTickLabel',{'0°' '45°' '90°' '135°' '180°'},...
        'FontName',OOPSData.Settings.DefaultPlotFont);
    
    OOPSData.Handles.ObjectIntensityPlotAxH.Title.String = 'Pixel-normalized intensitites fit to sinusoids';
    OOPSData.Handles.ObjectIntensityPlotAxH.Title.Color = 'White';
    OOPSData.Handles.ObjectIntensityPlotAxH.Title.FontName = OOPSData.Settings.DefaultPlotFont;
    OOPSData.Handles.ObjectIntensityPlotAxH.Title.HorizontalAlignment = 'Center';
    OOPSData.Handles.ObjectIntensityPlotAxH.Title.VerticalAlignment = 'Top';
    
    OOPSData.Handles.ObjectIntensityPlotAxH.XAxis.Label.String = "Excitation polarization (°)";
    OOPSData.Handles.ObjectIntensityPlotAxH.XAxis.Label.Color = [1 1 0];
    OOPSData.Handles.ObjectIntensityPlotAxH.XAxis.Label.FontName = OOPSData.Settings.DefaultPlotFont;
    OOPSData.Handles.ObjectIntensityPlotAxH.YAxis.Label.String = "Normalized emission intensity (A.U.)";
    OOPSData.Handles.ObjectIntensityPlotAxH.YAxis.Label.Color = [1 1 0];
    OOPSData.Handles.ObjectIntensityPlotAxH.YAxis.Label.FontName = OOPSData.Settings.DefaultPlotFont;
    
    disableDefaultInteractivity(OOPSData.Handles.ObjectIntensityPlotAxH);
    
    %% Object Stack-Normalized Intensity Stack
    
    OOPSData.Handles.ObjectNormIntStackAxH = uiaxes(OOPSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0.75 1 0.25],...
        'Tag','ObjectNormIntStack',...
        'XTick',[],...
        'YTick',[]);
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
    OOPSData.Handles.ObjectNormIntStackAxH = SetAxisTitle(OOPSData.Handles.ObjectNormIntStackAxH,'Stack-Normalized Object Intensity');
    OOPSData.Handles.ObjectNormIntStackAxH.Colormap = OOPSData.Settings.IntensityColormap;
    OOPSData.Handles.ObjectNormIntStackAxH.Title.Visible = 'Off';
    OOPSData.Handles.ObjectNormIntStackAxH.Toolbar.Visible = 'Off';
    disableDefaultInteractivity(OOPSData.Handles.ObjectNormIntStackAxH);
    
    OOPSData.Handles.ObjectNormIntStackImgH.Visible = 'Off';    
    OOPSData.Handles.ObjectNormIntStackImgH.HitTest = 'Off';
    
%% Turning on important containers and adjusting some components for proper initial display

set(OOPSData.Handles.AppInfoSelectorPanel,'Visible','On');
set(OOPSData.Handles.AppInfoSelector,'Visible','On');

set(OOPSData.Handles.ProjectSummaryTableGrid,'Visible','On');

set(OOPSData.Handles.AppInfoPanel,'Visible','On');
set(OOPSData.Handles.SettingsPanel,'Visible','On');

set(OOPSData.Handles.ImageOperationsPanel,'Visible','On');
set(OOPSData.Handles.ThreshAxH,'Visible','On');
set(OOPSData.Handles.ImageOperationsSelectorPanel,'Visible','On');
set(OOPSData.Handles.ImageOperationsSelector,'Visible','On');

set(OOPSData.Handles.LogPanel,'Visible','On');
set(OOPSData.Handles.LogWindow,'Visible','On');

set(OOPSData.Handles.SmallPanels,'Visible','On');

set(OOPSData.Handles.GroupSelectorPanel,'Visible','On');
set(OOPSData.Handles.ImageSelectorPanel,'Visible','On');
set(OOPSData.Handles.ObjectSelectorPanel,'Visible','On');
set(OOPSData.Handles.ObjectSelector,'Visible','On');

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


% add OOPSData to the gui using guidata
% (this is how we will retain access to the data across different functions)
guidata(OOPSData.Handles.fH,OOPSData)
% set optimum font size for display
fontsize(OOPSData.Handles.fH,OOPSData.Settings.FontSize,'pixels');
% update GUI display colors
UpdateGUITheme();
% update summary display
UpdateSummaryDisplay(OOPSData.Handles.fH);

% % delete the splash screen and clear out java components so we don't run into issues when saving
% Splash.dispose();
% clear Splash label icon SplashImage SplashScreenIcon

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

%% Swarm plot callbacks/settings

    function CopySwarmPlotVector(source,~)
        UpdateLog3(source,'Copying...','append');
        copygraphics(OOPSData.Handles.SwarmPlotAxH,'ContentType','vector','BackgroundColor',OOPSData.Settings.SwarmPlotBackgroundColor);
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
        OOPSData.Handles.SwarmPlotAxH.Color = OOPSData.Settings.SwarmPlotBackgroundColor;
        OOPSData.Handles.SwarmPlotGrid.BackgroundColor = OOPSData.Settings.SwarmPlotBackgroundColor;
    end

    function SwarmPlotForegroundColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.SwarmPlotSettings.ForegroundColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.SwarmPlotSettings.ForegroundColor = source.Value;
        end
        OOPSData.Handles.SwarmPlotAxH.XAxis.Color = OOPSData.Settings.SwarmPlotForegroundColor;
        OOPSData.Handles.SwarmPlotAxH.YAxis.Color = OOPSData.Settings.SwarmPlotForegroundColor;
    end

    function SwarmPlotErrorBarColorChanged(source,~)
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.SwarmPlotSettings.ErrorBarColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.SwarmPlotSettings.ErrorBarColor = source.Value;
        end
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

    function SaveSwarmPlotSettings(source,~)
        % saves the currently selected SwarmPlot settings to a .mat file
        % which will be loaded in future sessions by OOPSSettings
        UpdateLog3(source,'Saving swarmplot settings...','append');
        SwarmPlotSettings = OOPSData.Settings.SwarmPlotSettings;
        if ismac || isunix
            CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'/');
            save([SavePath,'/Settings/SwarmPlotSettings.mat'],'SwarmPlotSettings');        
        elseif ispc
            CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'\');
            save([SavePath,'\Settings\SwarmPlotSettings.mat'],'SwarmPlotSettings');        
        end
        UpdateLog3(source,'Done.','append');
    end
%% Scatter plot callbacks/settings

    function CopyScatterPlotVector(source,~)
        UpdateLog3(source,'Copying...','append');
        copygraphics(OOPSData.Handles.ScatterPlotAxH,'ContentType','vector','BackgroundColor',OOPSData.Settings.ScatterPlotBackgroundColor);
        UpdateLog3(source,'Scatter plot vector graphic copied to clipboard','append');
    end

    function SetScatterPlotBackgroundColor(~,~)
        OOPSData.Settings.ScatterPlotBackgroundColor = uisetcolor();
        figure(OOPSData.Handles.fH);
        OOPSData.Handles.ScatterPlotAxH.Color = OOPSData.Settings.ScatterPlotBackgroundColor;
        OOPSData.Handles.ScatterPlotGrid.BackgroundColor = OOPSData.Settings.ScatterPlotBackgroundColor;
    end

    function SetScatterPlotForegroundColor(~,~)
        OOPSData.Settings.ScatterPlotForegroundColor = uisetcolor();
        figure(OOPSData.Handles.fH);
        OOPSData.Handles.ScatterPlotAxH.XAxis.Color = OOPSData.Settings.ScatterPlotForegroundColor;
        OOPSData.Handles.ScatterPlotAxH.YAxis.Color = OOPSData.Settings.ScatterPlotForegroundColor;
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
        if isempty(source.Value)
            % then open the colorpicker to choose a color
            OOPSData.Settings.PolarHistogramSettings.WedgeLineColor = uisetcolor();
            figure(OOPSData.Handles.fH);
        else
            OOPSData.Settings.PolarHistogramSettings.WedgeLineColor = source.Value();
        end
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
        imagePolarData = deg2rad([OOPSData.CurrentImage(1).Object(:).(source.Value)]);
        imagePolarData(isnan(imagePolarData)) = [];
        imagePolarData(imagePolarData<0) = imagePolarData(imagePolarData<0)+pi;
        OOPSData.Handles.ImagePolarHistogram.polarData = [imagePolarData,imagePolarData+pi];
        OOPSData.Handles.ImagePolarHistogram.Title = ['Image - Object ',ExpandVariableName(source.Value)];

        groupPolarData = deg2rad([OOPSData.CurrentGroup.GetAllObjectData(source.Value)]);
        groupPolarData(isnan(groupPolarData)) = [];
        groupPolarData(groupPolarData<0) = groupPolarData(groupPolarData<0)+pi;
        OOPSData.Handles.GroupPolarHistogram.polarData = [groupPolarData,groupPolarData+pi];
        OOPSData.Handles.GroupPolarHistogram.Title = ['Group - Object ',ExpandVariableName(source.Value)];
    end

%% Group uitree callbacks

    function GroupTreeNodeTextChanged(source,event)
        event.Node.NodeData.GroupName = event.Node.Text;
        UpdateSummaryDisplay(source,{'Group'});
    end

    function DeleteGroup(source,~,fH)
        SelectedNode = fH.CurrentObject;
        cGroup = SelectedNode.NodeData;
        UpdateLog3(fH,['Deleting [Group:',cGroup.GroupName,']...'],'append');
        delete(SelectedNode)
        OOPSData.DeleteGroup(cGroup)
        UpdateImageTree(source);
        UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});        
        UpdateLog3(fH,'Done.','append');
    end

    function AddNewGroup(source,~)
        OOPSData.AddNewGroup(['Untitled Group ',num2str(OOPSData.nGroups+1)]);
        NewGroup = OOPSData.Group(end);
        newNode = uitreenode(OOPSData.Handles.GroupTree,...
            'Text',NewGroup.GroupName,...
            'NodeData',NewGroup,...
            'Icon',makeRGBColorSquare(NewGroup.Color,5));
        newNode.ContextMenu = OOPSData.Handles.GroupContextMenu;
        UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});
    end

    function EditGroupColor(source,~,fH)
        SelectedNode = fH.CurrentObject;
        cGroup = SelectedNode.NodeData;
        cGroup.Color = uisetcolor();
        figure(fH);
        SelectedNode.Icon = makeRGBColorSquare(cGroup.Color,1);
        if strcmp(OOPSData.Settings.CurrentTab,'Plots')
            UpdateImages(source);
        end
    end

%% Image uitree callbacks

    function DeleteImage(source,~,fH)

        SelectedNodes = OOPSData.Handles.ImageTree.SelectedNodes;
        %SelectedImages = deal([SelectedNodes(:).NodeData]);
        UpdateLog3(fH,'Deleting images...','append');
        delete(SelectedNodes)
        cGroup = OOPSData.CurrentGroup;
        cGroup.DeleteSelectedImages();
        
        cGroup.CurrentImageIndex = cGroup.CurrentImageIndex(1);
        UpdateImageTree(source);
        UpdateImages(source);
        UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});
        UpdateLog3(fH,'Done.','append');
    end

%% Settings type selection

    % change the current view in the settings menu according to user input
    function ChangeSettingsType(source,event)
        OOPSData.Handles.([event.PreviousValue,'Grid']).Visible = 'Off';
        OOPSData.Handles.([event.Value,'Grid']).Visible = 'On';
        ncols = length(OOPSData.Handles.([event.Value,'Grid']).ColumnWidth);
        source.Parent = OOPSData.Handles.([event.Value,'Grid']);
        if ncols > 1
            source.Layout.Column = [1 ncols];
        else
            source.Layout.Column = 1;
        end
    end

%% Azimuth stick plot callbacks/settings

    function ApplyAzimuthSettings(source,~)
        OOPSData.Settings.AzimuthDisplaySettings.LineAlpha = OOPSData.Handles.AzimuthLineAlphaDropdown.Value;
        OOPSData.Settings.AzimuthDisplaySettings.LineWidth = OOPSData.Handles.AzimuthLineWidthDropdown.Value;
        OOPSData.Settings.AzimuthDisplaySettings.LineScale = str2double(OOPSData.Handles.AzimuthLineScaleEditfield.Value);
        OOPSData.Settings.AzimuthDisplaySettings.ScaleDownFactor = OOPSData.Handles.AzimuthLineScaleDownDropdown.Value;
        OOPSData.Settings.AzimuthDisplaySettings.ColorMode = OOPSData.Handles.AzimuthColorModeDropdown.Value;
        UpdateImages(source);
    end

    function SaveAzimuthDisplaySettings(source,~)
        % saves the currently selected colormaps settings to a .mat file
        % which will be loaded in future sessions by OOPSSettings
        UpdateLog3(source,'Saving azimuth display settings...','append');
        AzimuthDisplaySettings = OOPSData.Settings.AzimuthDisplaySettings;
        if ismac || isunix
            CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'/');
            save([SavePath,'/Settings/AzimuthDisplaySettings.mat'],'AzimuthDisplaySettings');        
        elseif ispc
            CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'\');
            save([SavePath,'\Settings\AzimuthDisplaySettings.mat'],'AzimuthDisplaySettings');        
        end
        UpdateLog3(source,'Done.','append');
    end

%% Scatterplot settings

    function ScatterPlotVariablesChanged(source,~)
        OOPSData.Settings.ScatterPlotSettings.(source.Tag) = source.Value;
        if strcmp(OOPSData.Settings.CurrentTab,'Plots')
            UpdateImages(source);
        end
    end

    function SaveScatterPlotSettings(source,~)
        % saves the currently selected colormaps settings to a .mat file
        % which will be loaded in future sessions by OOPSSettings
        UpdateLog3(source,'Saving scatterplot settings...','append');
        ScatterPlotSettings = OOPSData.Settings.ScatterPlotSettings;
        if ismac || isunix
            CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'/');
            save([SavePath,'/Settings/ScatterPlotSettings.mat'],'ScatterPlotSettings');        
        elseif ispc
            CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'\');
            save([SavePath,'\Settings\ScatterPlotSettings.mat'],'ScatterPlotSettings');        
        end
        UpdateLog3(source,'Done.','append');
    end

%% Colormaps settings

    function ImageTypeSelectionChanged(source,~)
        ImageTypeName = source.Value;
        OOPSData.Handles.ColormapsSelector.Value = OOPSData.Settings.ColormapsSettings.(ImageTypeName).Name;
        OOPSData.Handles.ExampleColormapAx.Colormap = OOPSData.Settings.ColormapsSettings.(ImageTypeName).Map;
    end

    function ColormapSelectionChanged(source,~)
        % determine what type of image we are changing the colormap for
        ImageTypeName = OOPSData.Handles.ColormapsImageTypeSelector.Value;
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
            case 'OrderFactor'
                OrderFactorMap = OOPSData.Settings.OrderFactorColormap;
                OOPSData.Handles.OrderFactorAxH.Colormap = OrderFactorMap;
                OOPSData.Handles.ObjectOFAxH.Colormap = OrderFactorMap;
                OOPSData.Handles.ObjectOFContourAxH.Colormap = OrderFactorMap;
                if (~isempty(OOPSData.CurrentImage) && ...
                       OOPSData.Handles.ShowAsOverlayOrderFactor.Value && ...
                       strcmp(OOPSData.Settings.CurrentTab,'Order Factor'))
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
                OOPSData.Handles.PhaseBarAxH.Colormap = vertcat(AzimuthMap,AzimuthMap);
                if strcmp(OOPSData.Settings.CurrentTab,'Azimuth') && ...
                        strcmp(OOPSData.Settings.AzimuthColorMode,'Direction')
                    UpdateImages(OOPSData.Handles.fH);
                end
        end

    end

    function SaveColormapsSettings(source,~)
        % saves the currently selected colormaps settings to a .mat file
        % which will be loaded in future sessions by OOPSSettings
        UpdateLog3(source,'Saving colormaps settings...','append');
        ColormapsSettings = OOPSData.Settings.ColormapsSettings;
        if ismac || isunix
            CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'/');
            save([SavePath,'/Settings/ColormapsSettings.mat'],'ColormapsSettings');        
        elseif ispc
            CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
            SavePath = strjoin(CurrentPathSplit(1:end-1),'\');
            save([SavePath,'\Settings\ColormapsSettings.mat'],'ColormapsSettings');        
        end
        UpdateLog3(source,'Done.','append');
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
                DefaultLabel = OOPSLabel.empty();
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
                    % create a new default label
                    OOPSData.Settings.AddNewObjectLabel(...
                        'Default',...
                        distinguishable_colors(1,OOPSData.Settings.LabelColors));
                    DefaultLabel = OOPSData.Settings.ObjectLabels(end);
                end
                % add the new label to each of the unlabeled objects
                [ObjectsWithOldLabel(:).Label] = deal(DefaultLabel);
            end

        end

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
        UpdateLabelTree(source);
        UpdateImages(source);
        UpdateLog3(fH,'Done.','append');
    end

    function ApplyLabelToSelectedObjects(source,~,fH)
        % get the node that was right-clicked
        SelectedNode = fH.CurrentObject;
        % get the label we are going to apply to the objects
        cLabel = SelectedNode.NodeData;
        % apply the label to any selected objects
        OOPSData.LabelSelectedObjects(cLabel);
        % update display
        UpdateImages(source);
        UpdateSummaryDisplay(source,{'Object'});
        UpdateLog3(fH,'Done.','append');
    end

    function SelectLabeledObjects(source,~,fH)
        % get the selected nodes
        SelectedNodes = OOPSData.Handles.LabelTree.SelectedNodes;
        % if no nodes in the tree are truly 'selected', get the right-clicked node instead
        if numel(SelectedNodes)==0
            SelectedNodes = fH.CurrentObject;
        end

        for NodeIdx = 1:numel(SelectedNodes)
            % get the label associated with the node
            cLabel = SelectedNodes(NodeIdx).NodeData;
            % select all objects with the label
            OOPSData.SelectObjectsByLabel(cLabel);
        end
        % update display
        UpdateImages(source);
        UpdateSummaryDisplay(source,{'Object'});
        UpdateLog3(fH,'Done.','append');
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

    function AddNewLabel(~,~)
        OOPSData.Settings.AddNewObjectLabel([],[]);
        NewLabel = OOPSData.Settings.ObjectLabels(end);
        newNode = uitreenode(OOPSData.Handles.LabelTree,...
            'Text',NewLabel.Name,...
            'NodeData',NewLabel,...
            'Icon',makeRGBColorSquare(NewLabel.Color,5));
        newNode.ContextMenu = OOPSData.Handles.LabelContextMenu;
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

%% Callbacks controlling dynamic resizing of GUI containers

    function ResetContainerSizes(source,~)
        disp('Figure Window Size Changed...');
        SmallWidth = round((source.InnerPosition(3)*0.38)/2);
        % update grid size to maatch new image sizes
        OOPSData.Handles.MainGrid.RowHeight = {'1x',SmallWidth,SmallWidth,'1x'};
        OOPSData.Handles.MainGrid.ColumnWidth = {'1x',SmallWidth,SmallWidth,SmallWidth,SmallWidth};

        % testing dynamic font size update
        %fontsize(OOPSData.Handles.fH,round(OOPSData.Handles.fH.OuterPosition(4)*.0125),'pixels');

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
        OOPSData.Handles.CurrentThresholdLine.Value = round(OOPSData.Handles.ThreshAxH.CurrentPoint(1,1),4);
        OOPSData.Handles.CurrentThresholdLine.Label = {[OOPSData.CurrentImage(1).ThreshStatisticName,' = ',num2str(OOPSData.Handles.CurrentThresholdLine.Value)]};
        ThresholdLineMoving(source,OOPSData.Handles.CurrentThresholdLine.Value);
        %drawnow
    end
% Set final thresh position and restore callbacks
    function StopMovingAndSetThresholdLine(source,~)
        OOPSData.Handles.CurrentThresholdLine.Value = round(OOPSData.Handles.ThreshAxH.CurrentPoint(1,1),4);
        OOPSData.Handles.CurrentThresholdLine.Label = {[OOPSData.CurrentImage(1).ThreshStatisticName,' = ',num2str(OOPSData.Handles.CurrentThresholdLine.Value)]};
        OOPSData.Handles.fH.WindowButtonMotionFcn = '';
        OOPSData.Handles.fH.WindowButtonUpFcn = '';
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

        if OOPSData.CurrentImage(1).ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value
            UpdateCompositeRGB();
        else
            OOPSData.Handles.AverageIntensityAxH.CLim = source.Value;
        end

        drawnow limitrate

    end

    function AdjustReferenceChannelIntensity(source,~)
        OOPSData.CurrentImage(1).ReferenceIntensityDisplayLimits = source.Value;
        if OOPSData.CurrentImage(1).ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value
            UpdateCompositeRGB();
        end

        drawnow limitrate

    end

    function UpdateCompositeRGB()
        OOPSData.Handles.AverageIntensityImgH.CData = ...
            CompositeRGB(Scale0To1(OOPSData.CurrentImage(1).I),...
            OOPSData.Settings.IntensityColormap,...
            OOPSData.CurrentImage(1).PrimaryIntensityDisplayLimits,...
            Scale0To1(OOPSData.CurrentImage(1).ReferenceImage),...
            OOPSData.Settings.ReferenceColormap,...
            OOPSData.CurrentImage(1).ReferenceIntensityDisplayLimits);
        OOPSData.Handles.AverageIntensityAxH.CLim = [0 255];
    end

%% Setting axes properties during startup (to be eventually replaced with custom container classes)

    function [axH] = restore_axis_defaults(axH,OriginalPlotBoxAspectRatio,OriginalTag)
        % restore axis defaults that were changed by imshow()
        axH.YDir = 'reverse';
        axH.PlotBoxAspectRatio = OriginalPlotBoxAspectRatio;
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
            case 'OrderFactor'
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
                addExportAxesToolbarBtn;
            case 'Azimuth'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
                addShowAsOverlayToolbarBtn;
                addShowAzimuthHSVOverlayToolbarBtn;
                addShowColorbarToolbarBtn;
                addExportAxesToolbarBtn;
        end
        
        function addZoomToCursorToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MagnifyingGlassBlackAndYellow.png';
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
            btn.Icon = 'ShowAzimuthHSVOverlay.png';
            btn.ValueChangedFcn = @tbShowAzimuthHSVOverlayStateChanged;
            btn.Tag = ['ShowAzimuthHSVOverlay',axH.Tag];
            btn.Tooltip = 'Azimuth-OF-Intensity HSV overlay';
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

    function mbDeleteSelectedObjects(source,~)
        
        cGroup = OOPSData.CurrentGroup;
        
        cGroup.DeleteSelectedObjects();
        
        UpdateImages(source);
        UpdateObjectListBox(source);
        UpdateSummaryDisplay(source,{'Group','Image','Object'});
    end

    function mbClearSelection(source,~)
        
        cGroup = OOPSData.CurrentGroup;
        
        cGroup.ClearSelection();
        
        UpdateImages(source);
        UpdateObjectListBox(source);
        UpdateSummaryDisplay(source);
    end

    function mbObjectkmeansClustering(source,~)

        % get the object data table
        T = SaveOOPSData(source);
        % the variables we can use to cluster
        VarShortList = OOPSData.Settings.ObjectPlotVariables;
        % get user settings for the clustering
        ClusterSettings = GetClusterSettings(VarShortList);
        % make sure the output is valid
        if isempty(ClusterSettings)
            UpdateLog3(source,'No variables selected.','append');
            return
        end
        % gather data for all objects using user-specified variables from above
        ObjectData = T{:,string(ClusterSettings.VarList)};
        % list of variables that the user chose
        VariablesList = ClusterSettings.VarList;
        % how many clusters we will build, valid for 'manual' only
        nClusters = ClusterSettings.nClusters;
        % 'manual' or 'auto' selection of k
        nClustersMode = ClusterSettings.nClustersMode;
        % criterion to find optimal k, valid only 'auto' only
        Criterion = ClusterSettings.Criterion;
        % minimum repeats per iteration to find the best solution (smallest combined sum)
        nRepeats = 10;
        % call the main clustering function with the inputs above
        [ClusterIdxs,OptimalK] = OOPSObjectClustering(ObjectData,...
            nClusters,...
            nRepeats,...
            VariablesList,...
            [1,1,1],...
            nClustersMode,...
            Criterion);
        % in case k was set automatically, adjust number of clusters to match
        nClusters = OptimalK;
        % delete the existing object labels
        CurrentLabels = OOPSData.Settings.ObjectLabels;
        for LabelIdx = 1:numel(CurrentLabels)
            OOPSData.Settings.DeleteObjectLabel(CurrentLabels(LabelIdx));
        end
        % find set of colors (n = nClusters) distinguishable from both black and white 
        BGColors = [0 0 0;1 1 1];
        LabelColors = distinguishable_colors(nClusters,BGColors);
        % create the new cluster labels
        for idx = 1:nClusters
            OOPSData.Settings.ObjectLabels(idx,1) = OOPSLabel(['Cluster #',num2str(idx)],LabelColors(idx,:),OOPSData.Settings);
        end

        if any(isnan(ClusterIdxs))
            % add one additional label in case custering fails (NaNs in the clustering data -> NaNs in ClusterIdxs)
            OOPSData.Settings.ObjectLabels(end+1,1) = OOPSLabel(...
                'Clustering failed',...
                distinguishable_colors(1,[LabelColors;BGColors]),...
                OOPSData.Settings);
        end

        % Testing below
        PieChartData = cell(OOPSData.nGroups,1);
        for g_idx = 1:OOPSData.nGroups
            PieChartData{g_idx,1} = {};
        end
        % end testing

        % use the k-means clustering output to label each object with its cluster
        ObjCounter = 1;
        for g_idx = 1:OOPSData.nGroups
            for i_idx = 1:OOPSData.Group(g_idx).nReplicates
                for o_idx = 1:OOPSData.Group(g_idx).Replicate(i_idx).nObjects
                    try
                        OOPSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label = OOPSData.Settings.ObjectLabels(ClusterIdxs(ObjCounter));
                        PieChartData{g_idx,1}{end+1} = OOPSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label.Name;
                        ObjCounter = ObjCounter+1;
                    catch
                        OOPSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label = OOPSData.Settings.ObjectLabels(end);
                        PieChartData{g_idx,1}{end+1} = OOPSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label.Name;
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

        % PieGrid = uigridlayout(fH_ClusterProportions);
        % PieAxes = gobjects(OOPSData.nGroups,1);
        % for g_idx = 1:OOPSData.nGroups
        %     PieAxes(g_idx) = uiaxes(PieGrid);
        %     pie(PieAxes(g_idx),categorical(PieChartData{g_idx,1}));
        %     PieAxes(g_idx).Title.String = [OOPSData.Group(g_idx).GroupName];
        % end

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

        for LabelIdx = 1:OOPSData.Settings.nLabels
            Objs = OOPSData.getObjectsByLabel(OOPSData.Settings.ObjectLabels(LabelIdx));
            ObjImgs = cell(numel(Objs),1);
            % for ObjIdx = 1:numel(Objs)
            %     ObjImgs{ObjIdx} = Objs(ObjIdx).RestrictedPaddedMaskSubImage();
            % end
            for ObjIdx = 1:numel(Objs)
                ObjImgs{ObjIdx} = Objs(ObjIdx).PaddedFFCIntensitySubImage();
            end
            
            ObjImgTiles{LabelIdx,1} = imtile(ObjImgs,...
                'ThumbnailSize',[50 50],...
                'BorderSize',1,...
                'BackgroundColor',OOPSData.Settings.ObjectLabels(LabelIdx).Color,...
                'GridSize',[NaN 30]);
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

    function mbPlotImageRelativePixelAzimuth(~,~)

        try
            % get the current image
            cImage = OOPSData.CurrentImage;
            % if empty, throw error
            if isempty(cImage)
                error('No image found')
            else
                cImage = cImage(1);
            end

            polarData = cImage.AzimuthImage(cImage.bw);
            polarData(polarData<0) = polarData(polarData<0)+pi;
            polarData = [polarData, polarData+pi];
            
            phistFigure = uifigure("WindowStyle","alwaysontop",...
                "Name","Polar histogram",...
                "Units","pixels",...
                "Position",[0 0 500 500],...
                "HandleVisibility","on",...
                "Visible","off");

            movegui(phistFigure,"center")

            polarHistogram = PolarHistogramColorChart(...
                'parent',phistFigure,...
                'polarData',polarData,...
                'wedgeColors',OOPSData.Settings.AzimuthColormap,...
                'wedgeColorsRepeats',2,...
                'nBins',48);

            phistFigure.Visible = 'On';
        catch ME
            msg = ME.message;
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        end


    end

%% Changing object boxes type

    function ChangeObjectBoxType(source,~)
        OOPSData.Settings.ObjectBoxType = source.Text;
        UpdateLog3(source,['Object Box Type Changed to ',source.Text],'append');

        set(OOPSData.Handles.hObjectBoxType.Children(),'Checked','Off');
        set(OOPSData.Handles.(['hObjectBoxType_',source.Text]),'Checked','On');

        % only update summary overview if 'Project' is selected
        UpdateSummaryDisplay(source,{'Project'});
        UpdateImages(source);
    end

%% changing GUI theme (dark or light)

    function ChangeGUITheme(source,~)

        OOPSData.Settings.GUITheme = source.Text;
        UpdateLog3(source,['Switched theme to ',source.Text],'append');

        set(OOPSData.Handles.hGUITheme.Children,'Checked','Off');
        source.Checked = 'On';

        switch OOPSData.Settings.GUITheme
            case 'Dark'
                OOPSData.Settings.GUIBackgroundColor = [0 0 0];
                OOPSData.Settings.GUIForegroundColor = [1 1 1];
                OOPSData.Settings.GUIHighlightColor = [1 1 1];
            case 'Dark2'
                OOPSData.Settings.GUIBackgroundColor = [0.0549,0.0667,0.0902];
                OOPSData.Settings.GUIForegroundColor = [1,1,1];
                OOPSData.Settings.GUIHighlightColor = [0.6,0.6,0.6];
            case 'Light'
                OOPSData.Settings.GUIBackgroundColor = [1 1 1];
                OOPSData.Settings.GUIForegroundColor = [0 0 0];
                OOPSData.Settings.GUIHighlightColor = [0 0 0];
        end
        
        UpdateGUITheme();
        UpdateSummaryDisplay(source);
    end

    function UpdateGUITheme()
        GUIBackgroundColor = OOPSData.Settings.GUIBackgroundColor;
        GUIForegroundColor = OOPSData.Settings.GUIForegroundColor;
        GUIHighlightColor = OOPSData.Settings.GUIHighlightColor;
        set(findobj(OOPSData.Handles.fH,'type','uigridlayout'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(OOPSData.Handles.fH,'type','uipanel'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(OOPSData.Handles.fH,'type','uipanel'),'ForegroundColor',GUIForegroundColor);
        set(findobj(OOPSData.Handles.fH,'type','uipanel'),'HighlightColor',GUIHighlightColor);
        set(findobj(OOPSData.Handles.fH,'type','uitextarea'),'FontColor',GUIForegroundColor);
        set(findobj(OOPSData.Handles.fH,'type','uitextarea'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(OOPSData.Handles.fH,'type','axes'),'XColor',GUIForegroundColor);
        set(findobj(OOPSData.Handles.fH,'type','axes'),'YColor',GUIForegroundColor);
        set(findobj(OOPSData.Handles.fH,'type','axes'),'Color',GUIBackgroundColor);
        set(findobj(OOPSData.Handles.fH,'type','uilabel'),'FontColor',GUIForegroundColor);
        set(findobj(OOPSData.Handles.fH,'type','uilabel'),'BackgroundColor',GUIBackgroundColor);

        % set uitable colors
        set(findobj(OOPSData.Handles.fH,'type','uitable'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(OOPSData.Handles.fH,'type','uitable'),'ForegroundColor',GUIForegroundColor);

        % set uilistbox colors
        set(findobj(OOPSData.Handles.fH,'type','uilistbox'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(OOPSData.Handles.fH,'type','uilistbox'),'FontColor',GUIForegroundColor);

        % set uitree colors
        set(findobj(OOPSData.Handles.fH,'type','uitree'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(OOPSData.Handles.fH,'type','uitree'),'FontColor',GUIForegroundColor);

        % set swarm plot colors
        OOPSData.Handles.ScatterPlotGrid.BackgroundColor = OOPSData.Settings.SwarmPlotBackgroundColor;
        OOPSData.Handles.ScatterPlotAxH.Color = OOPSData.Settings.SwarmPlotBackgroundColor;
        OOPSData.Handles.ScatterPlotAxH.XAxis.Color = OOPSData.Settings.SwarmPlotForegroundColor;
        OOPSData.Handles.ScatterPlotAxH.YAxis.Color = OOPSData.Settings.SwarmPlotForegroundColor;

        % set scatter plot colors
        OOPSData.Handles.SwarmPlotGrid.BackgroundColor = OOPSData.Settings.SwarmPlotBackgroundColor;
        OOPSData.Handles.SwarmPlotAxH.Color = OOPSData.Settings.SwarmPlotBackgroundColor;
        OOPSData.Handles.SwarmPlotAxH.XAxis.Color = OOPSData.Settings.SwarmPlotForegroundColor;
        OOPSData.Handles.SwarmPlotAxH.YAxis.Color = OOPSData.Settings.SwarmPlotForegroundColor;

        % set intensity slider colors
        set(OOPSData.Handles.PrimaryIntensitySlider,...
            'BackgroundColor',GUIBackgroundColor,...
            'Knob1Color',GUIForegroundColor,...
            'Knob2Color',GUIForegroundColor,...
            'RangeColor',GUIForegroundColor,...
            'MidLineColor',GUIForegroundColor);
        set(OOPSData.Handles.ReferenceIntensitySlider,...
            'BackgroundColor',GUIBackgroundColor,...
            'Knob1Color',GUIForegroundColor,...
            'Knob2Color',GUIForegroundColor,...
            'RangeColor',GUIForegroundColor,...
            'MidLineColor',GUIForegroundColor);

        OOPSData.Handles.CurrentThresholdLine.Color = GUIForegroundColor;

        OOPSData.Handles.OrderFactorAxH.Color = 'Black';
        OOPSData.Handles.AverageIntensityAxH.Color = 'Black';
        OOPSData.Handles.AzimuthAxH.Color = 'Black';
        OOPSData.Handles.MaskAxH.Color = 'Black';

    end

    function ChangeGUIColors(source,~)
        % get the color of the GUI element for which we want to change color
        OOPSData.Settings.(source.Tag) = uisetcolor();
        % bring the main figure into focus
        figure(OOPSData.Handles.fH);
        % uncheck all menubar options for built-in themes
        set(OOPSData.Handles.hGUITheme.Children,'Checked','Off');
        % update the GUI colors
        UpdateGUITheme();
        % update summary display
        UpdateSummaryDisplay(source);
    end

%% GUI font size

    function ChangeGUIFontSize(source,~)
        switch source.Text
            case 'Larger'
                OOPSData.Settings.FontSize = OOPSData.Settings.FontSize+1;
            case 'Smaller'
                OOPSData.Settings.FontSize = OOPSData.Settings.FontSize-1;
        end
        % adjust the font size across the board
        fontsize(OOPSData.Handles.fH,OOPSData.Settings.FontSize,'pixels');
        % update the GUI summary display panel
        UpdateSummaryDisplay(source,{'Project'});
    end


%% MaskType Selection

    function ChangeMaskType(source,~)
        OOPSData.Settings.MaskType = source.Tag;
        OOPSData.Settings.MaskName = source.Text;
        set(OOPSData.Handles.hMaskType_CustomScheme.Children,'Checked','Off');
        set(OOPSData.Handles.hMaskType_Default.Children,'Checked','Off');
        % set chosen mask type to checked
        source.Checked = 'On';
        % only update summary overview if 'Project' is selected
        UpdateSummaryDisplay(source,{'Project'});
        % update image operations display
        UpdateImageOperationDisplay(source);
    end

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

            % open the CustomMaskMaker app so user can build a masking scheme
            NewScheme = CustomMaskMaker(OOPSData.CurrentImage(1).I,[],OOPSData.Settings.IntensityColormap);
            % get the handle to the mask maker app window
            MaskMakerFig = findobj(groot,'Name','Mask Maker');
            % and wait until it is closed
            waitfor(MaskMakerFig);

            % if not a valid masking scheme, throw error
            if ~NewScheme.isValidMaskingScheme
                error('Invalid scheme');
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
                otherwise
                    report = getReport(ME);
                    uialert(OOPSData.Handles.fH,['Unable to build masking scheme: ',report],'Error');
                    return
            end
        end

        % update OOPSSettings with new scheme
        OOPSData.Settings.LoadCustomMaskSchemes;

        % update uimenu to show newly saved scheme
        delete(OOPSData.Handles.hMaskType_CustomScheme);

        % rebuild the menu bar options for custom mask schemes
        OOPSData.Handles.hMaskType_CustomScheme = uimenu(OOPSData.Handles.hMaskType,'Text','CustomScheme');

        for SchemeIdx = 1:numel(OOPSData.Settings.SchemeNames)
            OOPSData.Handles.(['hMaskType_CustomScheme_',OOPSData.Settings.SchemeNames{SchemeIdx}]) = ...
                uimenu(OOPSData.Handles.hMaskType_CustomScheme,...
                'Text',OOPSData.Settings.SchemeNames{SchemeIdx},...
                'Tag','CustomScheme',...
                'Checked','Off',...
                'Callback',@ChangeMaskType);
        end

        OOPSData.Handles.hMaskType_NewScheme = uimenu(OOPSData.Handles.hMaskType_CustomScheme,...
            'Text','Create new scheme',...
            'Separator','on',...
            'Callback',@BuildNewScheme);

        % update the log window
        UpdateLog3(OOPSData.Handles.fH,['Saved new scheme:',SchemeFilesPath,NewSchemeName,'.mat'],'append');
    end

%% Changing active object/image/group indices

    function ChangeActiveObject(source,~)
        cImage = OOPSData.CurrentImage;
        cImage.CurrentObjectIdx = source.Value;
        UpdateSummaryDisplay(source,{'Object'});
        if strcmp(OOPSData.Settings.CurrentTab,'Objects')
            UpdateImages(source);
        end
        %disp('object selection changed');
    end

    function GroupSelectionChanged(source,~)
        OOPSData.CurrentGroupIndex = source.SelectedNodes(1).NodeData.SelfIdx;
        % update display of image tree, images, and summary
        UpdateImageTree(source);
        UpdateImages(source);
        UpdateImageOperationDisplay(source);
        UpdateSummaryDisplay(source,{'Group','Image','Object'});
    end

    function ImageSelectionChanged(source,~)
        CurrentGroupIndex = OOPSData.CurrentGroupIndex;
        SelectedImages = deal([source.SelectedNodes(:).NodeData]);
        OOPSData.Group(CurrentGroupIndex).CurrentImageIndex = [SelectedImages(:).SelfIdx];
        % update display of images, object selector, summary
        UpdateImages(source);
        UpdateObjectListBox(source);
        UpdateImageOperationDisplay(source);
        UpdateSummaryDisplay(source,{'Image','Object'});
    end

    function ObjectSelectionChanged(source,~)
        cImage = OOPSData.CurrentImage;
        SelectedObjects = deal([source.SelectedNodes(:).NodeData]);
        cImage.CurrentObjectIdx = [SelectedObjects(:).SelfIdx];
        % update images and summary
        UpdateImages(source);
        UpdateSummaryDisplay(source,{'Image','Object'});
    end

    function ChangeImageOperation(source,~)
        OOPSData.Settings.CurrentImageOperation = source.Value;
        UpdateImageOperationDisplay(source);
    end

%% Change summary display type

    function ChangeSummaryDisplay(source,~)
        % update the summary display type
        OOPSData.Settings.SummaryDisplayType = OOPSData.Handles.AppInfoSelector.Value;


        % % set the title of the summary panel
        % OOPSData.Handles.AppInfoPanel.Title = [OOPSData.Settings.SummaryDisplayType,' summary'];
        % % hide grid layout managers for all summary tables
        % set(findobj(OOPSData.Handles.AppInfoPanel.Children(),'type','uigridlayout'),'Visible','off');
        % % show the grid layout manager for the summary type that is active
        % OOPSData.Handles.([OOPSData.Settings.SummaryDisplayType,'SummaryTableGrid']).Visible = 'on';


        % update the summary panel with the selected tabular data
        UpdateSummaryDisplay(source);
    end

%% 'Process' menubar callbacks

    function pb_FindLocalSB(source,~)
        % number of selected images
        nImages = length(OOPSData.CurrentImage);
        % update log to indicate # of images we are processing
        UpdateLog3(source,['Detecting Local S/B for ',num2str(nImages),' images'],'append');
        % counter to track which image we're on
        Counter = 1;
        for cImage = OOPSData.CurrentImage
            % update log to indicate which image we are on
            UpdateLog3(source,['    ',cImage.pol_shortname,' (',num2str(Counter),'/',num2str(nImages),')'],'append');
            % detect local S/B for one image
            cImage.FindLocalSB();
            % log update to indicate we are done with this image
            UpdateLog3(source,['        Local S/B detected for ',num2str(cImage.nObjects),' objects...'],'append');
            % increment counter
            Counter = Counter+1;
        end
        % update log to indicate we are done
        UpdateLog3(source,'Done.','append');
        % update summary table
        UpdateSummaryDisplay(source,{'Group','Image','Object'});
    end

    function pb_FindOrderFactor(source,~)
        % number of selected images
        nImages = length(OOPSData.CurrentImage);
        % update log to indicate # of images we are processing
        UpdateLog3(source,['Computing order statistics statistics for ',num2str(nImages),' images'],'append');
        % counter to track progress
        Counter = 1;
        % start a timer
        tic
        % detect object azimuth stats for each currently selected image
        for cImage = OOPSData.CurrentImage
            % update log to indicate which image we are on
            UpdateLog3(source,['    ',cImage.pol_shortname,' (',num2str(Counter),'/',num2str(nImages),')'],'append');
            % compute the azimuth stats
            cImage.FindOrderFactor();
            % increment the counter
            Counter = Counter+1;
        end
        % end the timer and save the time
        timeElapsed = toc;
        % change to the Order Factor 'tab' if not there already
        if ~strcmp(OOPSData.Settings.CurrentTab,'Order Factor')
            feval(OOPSData.Handles.hTabOrderFactor.Callback,OOPSData.Handles.hTabOrderFactor,[]);
        else
            % update displayed images (tab switching will automatically update the display)
            UpdateImages(source);
        end
        % update summary table
        UpdateSummaryDisplay(source,{'Group','Image','Object'});
        % update log with time elapsed
        UpdateLog3(source,['Time elapsed: ',num2str(timeElapsed),' seconds'],'append');
        % update log to indicate we are done
        UpdateLog3(source,'Done.','append');        
    end

%% Project saving and loading

    function LoadProject(source,~)
        % alert user to required action (select saved project file to load)
        uialert(OOPSData.Handles.fH,'Select saved project file (.mat)','Load Project File',...
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

        % update some settings for the current window

        % update custom schemes menu options
        % delete all the existing options
        delete(OOPSData.Handles.hMaskType_CustomScheme.Children)
        % Load the custom schemes and make a menu option for each one
        for SchemeIdx = 1:numel(OOPSData.Settings.SchemeNames)
            OOPSData.Handles.(['hMaskType_CustomScheme_',OOPSData.Settings.SchemeNames{SchemeIdx}]) = ...
                uimenu(OOPSData.Handles.hMaskType_CustomScheme,...
                'Text',OOPSData.Settings.SchemeNames{SchemeIdx},...
                'Tag','CustomScheme',...
                'Checked','Off',...
                'Callback',@ChangeMaskType);
        end
        % Option to create new 'Custom' mask scheme
        OOPSData.Handles.hMaskType_NewScheme = uimenu(OOPSData.Handles.hMaskType_CustomScheme,...
            'Text','Create new scheme',...
            'Separator','on',...
            'Callback',@BuildNewScheme);

        % update swarm plot grouping type drop down
        OOPSData.Handles.SwarmPlotGroupingTypeDropdown.Value = OOPSData.Settings.SwarmPlotGroupingType;


        % update the display with selected tab
        Tab2Switch2 = OOPSData.Settings.CurrentTab;
        % set 'CurrentTab' to previous current tab before loading project
        OOPSData.Settings.CurrentTab = PreviousTab;
        % find the uimenu that would normally be used to switch to the tab indicated by 'CurrentTab' in the loaded project
        Menu2Pass = findobj(OOPSData.Handles.hTabMenu.Children,'Text',Tab2Switch2);
        % update view and display with newly loaded project
        % update group/image/object selection trees
        UpdateGroupTree(source);
        UpdateImageTree(source);
        UpdateLabelTree(source);
        % update summary type selector and summary tables
        OOPSData.Handles.AppInfoSelector.Value = OOPSData.Settings.SummaryDisplayType;
        UpdateSummaryDisplay(source);
        % update image operations type selector and image operations panel
        OOPSData.Handles.ImageOperationsSelector.Value = OOPSData.Settings.CurrentImageOperation;       
        UpdateImageOperationDisplay(source);
        % update current tab using uimenu object as the source
        TabSelection(Menu2Pass);
        UpdateImages(source);
        % update menu bar items
        % update mask type/name options context menu
        % uncheck all mask names for each mask type
        set(OOPSData.Handles.hMaskType_CustomScheme.Children,'Checked','Off');
        set(OOPSData.Handles.hMaskType_Default.Children,'Checked','Off');
        % check the currently selected mask name
        switch OOPSData.Settings.MaskType
            case 'Default'
                OOPSData.Handles.(['hMaskType_Default_',OOPSData.Settings.MaskName]).Checked = 'On';
            case 'CustomScheme'
                OOPSData.Handles.(['hMaskType_CustomScheme_',OOPSData.Settings.MaskName]).Checked = 'On';
        end
        % update object box type options context menu
        set(OOPSData.Handles.hObjectBoxType.Children,'Checked','off');
        OOPSData.Handles.(['hObjectBoxType_',OOPSData.Settings.ObjectBoxType]).Checked = 'On';

        % update the GUI theme
        UpdateGUITheme()

        % restore old pointer
        OOPSData.Handles.fH.Pointer = OldPointer;
        % update log to indicate completion
        UpdateLog3(source,'Done.','append');
    end

    function SaveProject(source,~)

        uialert(OOPSData.Handles.fH,'Set save location/filename','Save Project File',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));

        uiwait(OOPSData.Handles.fH);

        OOPSData.Handles.fH.Visible = 'Off';

        try
            [filename,path] = uiputfile('*.mat','Set directory and filename',OOPSData.Settings.LastDirectory);
        catch
            [filename,path] = uiputfile('*.mat','Set directory and filename');
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
            disp('Retrieving data struct...')
    
            % % method 1
            % SavedOOPSData = OOPSData.saveobj();
            % disp('Saving data struct...')
            % save([path,filename],'SavedOOPSData');


            % % method 2
            SavedOOPSData = OOPSData;
            disp('Saving data struct...')
            save([path,filename],'SavedOOPSData');

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
        UpdateLog3(source,['Successfully saved project:',path,filename],'append');

    end

%% Data saving

    function [] = SaveImages(source,~)
        
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
            'Order Factor (RGB .png)';...
            'Masked Order Factor (RGB .png)';...
            'Azimuth (RGB .png)';...
            'Masked Azimuth (RGB .png)';...
            'Mask (8-bit .tif)';...
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
                loc = [folder_name '/' cImage.pol_shortname];
            elseif ispc
                loc = [folder_name '\' cImage.pol_shortname];
            end
            
            if any(strcmp(UserSaveChoices,'Image Summary'))

                % data struct to hold output variable for current image
                ImageSummary = struct();
                ImageSummary.I = cImage.I;
                % mask and average OF
                ImageSummary.bw = cImage.bw;
                ImageSummary.OFAvg = cImage.OFAvg;
                % raw data, raw data normalized to stack-max, raw stack-average
                ImageSummary.rawFPMStack = cImage.rawFPMStack;
                ImageSummary.rawFPMAverage = cImage.rawFPMAverage;
                % same as above, but with flat-field corrected data
                ImageSummary.ffcFPMStack = cImage.ffcFPMStack;
                ImageSummary.ffcFPMAverage = cImage.ffcFPMAverage;
                % FF-corrected data normalized within each 4-px stack
                ImageSummary.ffcFPMPixelNorm = cImage.ffcFPMPixelNorm;
                % output images
                ImageSummary.OFImage = cImage.OF_image;
                ImageSummary.MaskedOFImage = cImage.MaskedOFImage;
                ImageSummary.AzimuthImage = cImage.AzimuthImage;
                % image info
                ImageSummary.ImageName = cImage.pol_shortname;
                % calculated obj data (SB,OF,etc.)
                ImageSummary.ObjectData = GetImageObjectSummary(cImage);
                
                name = [loc,'_Output'];
                UpdateLog3(source,name,'append');
                save(name,'ImageSummary');
                clear ImageSummary
            end

            %% Masked OF Image
            
            if any(strcmp(UserSaveChoices,'Order Factor (RGB .png)'))
                name = [loc,'-OF_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.OFImageRGB;
                imwrite(IOut,name);
            end

            if any(strcmp(UserSaveChoices,'Masked Order Factor (RGB .png)'))
                name = [loc,'-MaskedOF_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.MaskedOFImageRGB;
                imwrite(IOut,name);
            end

            %% Azimuth (.png)
            
            if any(strcmp(UserSaveChoices,'Azimuth (RGB .png)'))
                name = [loc,'-Azimuth_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.AzimuthRGB;
                imwrite(IOut,name);
            end

            %% Masked azimuth (.png)
            
            if any(strcmp(UserSaveChoices,'Masked Azimuth (RGB .png)'))
                name = [loc,'-MaskedAzimuth_RGB.png'];
                UpdateLog3(source,name,'append');
                IOut = cImage.MaskedAzimuthRGB;
                imwrite(IOut,name);
            end
            
            %% Average Intensity
            
            if any(strcmp(UserSaveChoices,'Average Intensity Image (8-bit .tif)'))
                name = [loc '-AvgIntensity.tif'];
                UpdateLog3(source,name,'append');
                IOut = im2uint8(Scale0To1(cImage.Pol_ImAvg));
                imwrite(IOut,OOPSData.Settings.IntensityColormap,name);                
            end

            if any(strcmp(UserSaveChoices,'Mask (8-bit .tif)'))    
                name = [loc '-Mask.tif'];
                UpdateLog3(source,name,'append');
                IOut = im2uint8(full(cImage.bw));
                imwrite(IOut,name);
            end
            
        end % end of main save loop
        
    end % end SaveImages

    function [] = SaveObjectData(source,~)
        
        CurrentGroup = OOPSData.CurrentGroup;
        
        % alert box to indicate required action
        uialert(OOPSData.Handles.fH,['Select a directory to save object data for Group:',CurrentGroup.GroupName],'Save object data',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));
        % prevent interaction with main window until we finish
        uiwait(OOPSData.Handles.fH);
        % hide main window
        OOPSData.Handles.fH.Visible = 'Off';
        % try to get files from the most recent directory,
        % otherwise, just use default
        try
            UserChoice = uigetdir(OOPSData.Settings.LastDirectory);
        catch
            UserChoice = uigetdir(pwd);
        end
        % save accessed directory
        OOPSData.Settings.LastDirectory = UserChoice;
        % hide main window
        OOPSData.Handles.fH.Visible = 'On';
        % make OOPSGUI active figure
        figure(OOPSData.Handles.fH);
        % if no files selected, throw error

        if ~UserChoice
            msg = 'No directory selected...';
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        end
        
        % control for mac vs pc
        if ismac || isunix
            SaveLocation = [UserChoice '/' CurrentGroup.GroupName];
        elseif ispc
            SaveLocation = [UserChoice '\' CurrentGroup.GroupName];
        end
        
        UpdateLog3(source,['Saving data for Group:',CurrentGroup.GroupName],'append');
        
        % get data table for current group
        Table2Save = GetGroupObjectSummary(source);
        
        % create a struct with dynamic field name for unambiguous naming of the saved variable
        S.(matlab.lang.makeValidName([CurrentGroup.GroupName,'_ObjectSummary'])) = Table2Save;
        % save the data table
        save([SaveLocation,'_ObjectSummary','.mat'],'-struct','S');
        clear S
        
        % create a struct with dynamic field name for unambiguous naming of the saved variable
        S.(matlab.lang.makeValidName([CurrentGroup.GroupName,'_AvgOFPerImage'])) = full([CurrentGroup.Replicate(:).OFAvg]');
        save([SaveLocation,'_AvgOFPerImage','.mat'],'-struct','S');
        clear S

        %% filtered OF - temporary until a better solution is written (need a way to specify object filters explicitly)
        % create a struct with dynamic field name for unambiguous naming of the saved variable
        S.(matlab.lang.makeValidName([CurrentGroup.GroupName,'_AvgFilteredOFPerImage'])) = full([CurrentGroup.Replicate(:).FilteredOFAvg]');
        save([SaveLocation,'_AvgFilteredOFPerImage','.mat'],'-struct','S');
        clear S


        
        UpdateLog3(source,['Done saving data for Group:',CurrentGroup.GroupName],'append');
        
    end

%% Axes toolbar callbacks

    function tbExportAxes(source,~)
        % get the toolbar parent of the calling button
        ctb = source.Parent;
        % get the axes parent of that toolbar, which we will export
        cax = ctb.Parent;

        uialert(OOPSData.Handles.fH,'Set save location/filename','Export axes',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(OOPSData.Handles.fH));

        uiwait(OOPSData.Handles.fH);

        OOPSData.Handles.fH.Visible = 'Off';

        try
            [filename,path] = uiputfile('*.png',...
                'Set directory and filename',OOPSData.Settings.LastDirectory);
        catch
            [filename,path] = uiputfile('*.png',...
                'Set directory and filename');
        end

        OOPSData.Handles.fH.Visible = 'On';
        figure(OOPSData.Handles.fH);

        if ~filename
            msg = 'Invalid filename...';
            uialert(OOPSData.Handles.fH,msg,'Error');
            return
        end

        OOPSData.Settings.LastDirectory = path;

        UpdateLog3(source,'Exporting axes...','append');

        tempfig = uifigure("HandleVisibility","On",...
            "Visible","off",...
            "InnerPosition",[0 0 1024 1024],...
            "AutoResizeChildren","Off");

        tempax = copyobj(cax,tempfig);
        tempax.Visible = 'On';
        tempax.XColor = 'Black';
        tempax.YColor = 'Black';
        tempax.Box = 'On';
        tempax.LineWidth = 0.5;
        tempax.Color = 'Black';

        tempax.Title.String = '';
        tempax.Units = 'Normalized';
        tempax.InnerPosition = [0 0 1 1];

        export_fig([path,filename],tempfig,'-nocrop');

        close(tempfig)

        UpdateLog3(source,'Done.','append');
        
    end

    function tbApplyMaskStateChanged(source,event)
        
        cGroupIdx = OOPSData.CurrentGroupIndex;
        cImageIdx = OOPSData.Group(cGroupIdx).CurrentImageIndex;
        ctb = source.Parent;
        cax = ctb.Parent;
        im = findobj(cax,'Type','image');

        % if strcmp(cax.Tag,'OrderFactor')
        %     switch event.Value
        %         case 1
        %             im.CData = OOPSData.Group(cGroupIdx).Replicate(cImageIdx).MaskedOFImageRGB;
        %         case 0
        %             im.CData = OOPSData.Group(cGroupIdx).Replicate(cImageIdx).OF_image;
        %     end
        % 
        %     return
        % end

        switch event.Value
            case 1 % 'On'
                im.AlphaData = OOPSData.Group(cGroupIdx).Replicate(cImageIdx).bw;
            case 0 % 'Off'
                im.AlphaData = 1;
        end
    end

    function tbShowAsOverlayStateChanged(source,~)
        UpdateImages(source);
    end

    function tbShowAzimuthHSVOverlayStateChanged(source,~)
        % if the toolbar button is pressed
        if source.Value
            % then make sure the intensity overlay button is not pressed
            OOPSData.Handles.ShowAsOverlayAzimuth.Value = "off";
        end
        UpdateImages(source);
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
        %   case 'OrderFactor'
        %       OOPSData.Handles.OFcbar.Visible = source.Value;
        %   case 'Azimuth'
        %
        % end
        UpdateImages(source);
    end

    function tbScaleToMaxStateChanged(source,~)
        UpdateImages(source);
    end

    function tbShowReferenceImageStateChanged(source,~)
        if OOPSData.CurrentImage.ReferenceImageLoaded
            UpdateImages(source);
        else
            source.Value = 0;
            UpdateLog3(source,'No reference image to overlay.','append');
        end
    end

    function tbRectangularROI(source,~)
        % original code here
        ctb = source.Parent;
        cax = ctb.Parent;
        % end original code, start test

        cimg = findobj(cax.Children,'Type','image');

        % image contrast tool
        %hTool = imcontrast(cimg);
        %waitfor(hTool)


        % pixel region tool

        pixelRegionFig = uifigure("WindowStyle","alwaysontop","AutoResizeChildren","off");
        hTool = impixelregionpanel(pixelRegionFig,cimg);
        waitfor(hTool)
        
        return
        % end test

        % % below is original code
        % % draw rectangular ROI
        % ROI = drawrectangle(cax);
        % % find and 'select' objects within ROI
        % %SelectObjectsInRectangularROI(source,ROI);
        % SelectObjectsInROI(source,ROI);
        % % delete the ROI
        % delete(ROI);
        % % update display
        % UpdateImages(source);
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
                
                OOPSData.Handles.LineScanAxes = uiaxes(OOPSData.Handles.LineScanFig,'Units','Normalized','OuterPosition',[0 0 1 1]);
                
                OOPSData.Handles.LineScanROI.Position = [x1 y1; x2 y2];
                
                OOPSData.Handles.LineScanListeners(1) = addlistener(OOPSData.Handles.LineScanROI,'MovingROI',@LineScanROIMoving);
                OOPSData.Handles.LineScanListeners(2) = addlistener(OOPSData.Handles.LineScanROI,'ROIMoved',@LineScanROIMoved);
            case 'LineScanOrderFactor'
                OOPSData.Handles.LineScanROI = images.roi.Line(OOPSData.Handles.OrderFactorAxH,...
                    'Color','Yellow',...
                    'Alpha',0.5,...
                    'Tag','LineScanOrderFactor');
                XRange = OOPSData.Handles.OrderFactorAxH.XLim(2)-OOPSData.Handles.OrderFactorAxH.XLim(1);
                YRange = OOPSData.Handles.OrderFactorAxH.YLim(2)-OOPSData.Handles.OrderFactorAxH.YLim(1);
                x1 = OOPSData.Handles.OrderFactorAxH.XLim(1)+0.25*XRange;
                x2 = OOPSData.Handles.OrderFactorAxH.XLim(2)-0.25*XRange;
                y1 = OOPSData.Handles.OrderFactorAxH.YLim(1)+0.5*YRange;
                y2 = OOPSData.Handles.OrderFactorAxH.YLim(1)+0.5*YRange;
        
                OOPSData.Handles.LineScanFig = uifigure('Name','Order Factor line scan',...
                    'HandleVisibility','On',...
                    'WindowStyle','AlwaysOnTop',...
                    'Units','Normalized',...
                    'Position',[0.65 0.8 0.35 0.2],...
                    'CloseRequestFcn',@CloseLineScanFig,...
                    'Color','White');
                
                OOPSData.Handles.LineScanAxes = uiaxes(OOPSData.Handles.LineScanFig,'Units','Normalized','OuterPosition',[0 0 1 1]);
                OOPSData.Handles.LineScanAxes.XLabel.String = 'Distance (um)';
                OOPSData.Handles.LineScanAxes.YLabel.String = 'Average OF';
                
                OOPSData.Handles.LineScanROI.Position = [x1 y1; x2 y2];
                
                OOPSData.Handles.LineScanListeners(1) = addlistener(OOPSData.Handles.LineScanROI,'MovingROI',@LineScanROIMoving);
                OOPSData.Handles.LineScanListeners(2) = addlistener(OOPSData.Handles.LineScanROI,'ROIMoved',@LineScanROIMoved);
        end

    end

    function CloseLineScanFig(~,~)
        delete(OOPSData.Handles.LineScanROI);
        delete(OOPSData.Handles.LineScanListeners(1));
        delete(OOPSData.Handles.LineScanListeners(2));        
        delete(OOPSData.Handles.LineScanFig);
    end

    function LineScanROIMoving(source,~)

        cImage = OOPSData.CurrentImage;
        
        switch source.Tag
            case 'LineScanAverageIntensity'
                if cImage.ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value==1
                    OOPSData.Handles.LineScanAxes = PlotIntegratedDoubleLineScan(OOPSData.Handles.LineScanAxes,...
                        OOPSData.Handles.LineScanROI.Position,...
                        cImage.Pol_ImAvg,...
                        cImage.ReferenceImageEnhanced,...
                        cImage.RealWorldLimits);
                else
                    OOPSData.Handles.LineScanAxes = PlotIntegratedLineScan(OOPSData.Handles.LineScanAxes,...
                        OOPSData.Handles.LineScanROI.Position,...
                        cImage.Pol_ImAvg,...
                        cImage.RealWorldLimits);
                end
            case 'LineScanOrderFactor'
                switch OOPSData.Handles.ApplyMaskOrderFactor.Value
                    case true
                        OOPSData.Handles.LineScanAxes = PlotOrderFactorLineScan(OOPSData.Handles.LineScanAxes,...
                            OOPSData.Handles.LineScanROI.Position,...
                            cImage.OF_image,...
                            cImage.RealWorldLimits,...
                            cImage.bw);
                    case false
                        OOPSData.Handles.LineScanAxes = PlotOrderFactorLineScan(OOPSData.Handles.LineScanAxes,...
                            OOPSData.Handles.LineScanROI.Position,...
                            cImage.OF_image,...
                            cImage.RealWorldLimits,...
                            []);
                end
        end

    end

    function LineScanROIMoved(source,~)

        cImage = OOPSData.CurrentImage;
        
        switch source.Tag
            case 'LineScanAverageIntensity'
                if cImage.ReferenceImageLoaded && OOPSData.Handles.ShowReferenceImageAverageIntensity.Value==1
                    OOPSData.Handles.LineScanAxes = PlotIntegratedDoubleLineScan(OOPSData.Handles.LineScanAxes,...
                        OOPSData.Handles.LineScanROI.Position,...
                        cImage.Pol_ImAvg,...
                        cImage.ReferenceImageEnhanced,...
                        cImage.RealWorldLimits);
                else
                    OOPSData.Handles.LineScanAxes = PlotIntegratedLineScan(OOPSData.Handles.LineScanAxes,...
                        OOPSData.Handles.LineScanROI.Position,...
                        cImage.Pol_ImAvg,...
                        cImage.RealWorldLimits);
                end
            case 'LineScanOrderFactor'
                switch OOPSData.Handles.ApplyMaskOrderFactor.Value
                    case true
                        OOPSData.Handles.LineScanAxes = PlotOrderFactorLineScan(OOPSData.Handles.LineScanAxes,...
                            OOPSData.Handles.LineScanROI.Position,...
                            cImage.OF_image,...
                            cImage.RealWorldLimits,...
                            cImage.bw);
                    case false
                        OOPSData.Handles.LineScanAxes = PlotOrderFactorLineScan(OOPSData.Handles.LineScanAxes,...
                            OOPSData.Handles.LineScanROI.Position,...
                            cImage.OF_image,...
                            cImage.RealWorldLimits,...
                            []);
                end
        end
        
    end


end