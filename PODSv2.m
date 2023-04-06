function PODSv2()

% try to start the parallel pool 
try
    parpool("threads");
catch
    warning("Unable to create parallel pool...")
end

% create an instance of PODSProject
% this object will hold ALL project data and GUI settings
PODSData = PODSProject;

%% set up splash screen

% get the splash screen image
if ismac || isunix
    SplashIconPath = fullfile([PODSData.Settings.MainPath,'/SplashScreenIcon/AppSplashScreen.png']);
elseif ispc
    SplashIconPath = fullfile([PODSData.Settings.MainPath,'\SplashScreenIcon\AppSplashScreen.png']);
end
SplashScreenIcon = java.awt.Toolkit.getDefaultToolkit.createImage(SplashIconPath);

% Create splash screen window
SplashImage = SplashScreenIcon;
Splash = javax.swing.JWindow;
icon = javax.swing.ImageIcon(SplashImage);
label = javax.swing.JLabel(icon);
Splash.getContentPane.add(label);
Splash.setAlwaysOnTop(true);
Splash.pack;

% set the splash image to the center of the screen
screenSize = Splash.getToolkit.getScreenSize;
screenHeight = screenSize.height;
screenWidth = screenSize.width;
% get the actual splashImage size
imgHeight = icon.getIconHeight;
imgWidth = icon.getIconWidth;
Splash.setLocation((screenWidth-imgWidth)/2,(screenHeight-imgHeight)/2);
Splash.show % show the splash screen

%% set up the main window

% struct to hold graphics objects
PODSData.Handles = struct();
% create the uifigure (main gui window)
PODSData.Handles.fH = uifigure('Name','PODS GUI',...
    'numbertitle','off',...
    'units','pixels',...
    'Position',PODSData.Settings.ScreenSize,...
    'Visible','Off',...
    'Color','white',...
    'HandleVisibility','on',...
    'AutoResizeChildren','off',...
    'SizeChangedFcn',@ResetContainerSizes);

%% set some defaults to save time and improve readability

% panel properties
set(gcf,'defaultUipanelFontName',PODSData.Settings.DefaultFont);
set(gcf,'defaultUipanelFontWeight','Bold');
set(gcf,'defaultUipanelBackgroundColor','Black');
set(gcf,'defaultUipanelForegroundColor','White');
set(gcf,'defaultUipanelAutoResizeChildren','Off');

% text properties
set(gcf,'defaultTextFontName',PODSData.Settings.DefaultFont);
set(gcf,'defaultTextFontWeight','bold');

% turn off any warning that do not adversely affect computation
warning('off','MATLAB:polyshape:repairedBySimplify');

%% CHECKPOINT

disp('Setting up menubar...')

%% File Menu Button - Create a new project, load files, etc...

PODSData.Handles.hFileMenu = uimenu(PODSData.Handles.fH,'Text','File');
% Options for File Menu Button
PODSData.Handles.hNewProject = uimenu(PODSData.Handles.hFileMenu,'Text','&New Project','Callback',@NewProject2);
PODSData.Handles.hNewProject.Accelerator = 'N';
% menu for loading existing project
PODSData.Handles.hLoadProject = uimenu(PODSData.Handles.hFileMenu,'Text','Load Project','Callback',@LoadProject);
PODSData.Handles.hSaveProject = uimenu(PODSData.Handles.hFileMenu,'Text','Save Project','Callback',@SaveProject);
% load files
PODSData.Handles.hLoadFFCFiles = uimenu(PODSData.Handles.hFileMenu,'Text','Load FFC Files','Separator','On','Callback',@pb_LoadFFCFiles);
PODSData.Handles.hLoadFPMFiles = uimenu(PODSData.Handles.hFileMenu,'Text','Load FPM Files','Callback',@pb_LoadFPMFiles);
PODSData.Handles.hLoadReferenceImages = uimenu(PODSData.Handles.hFileMenu,'Text','Load Reference Images','Callback',@LoadReferenceImages);
% save data
PODSData.Handles.hSaveOF = uimenu(PODSData.Handles.hFileMenu,'Text','Save Data for Selected Images','Separator','On','Callback',@SaveImages);
PODSData.Handles.hSaveObjectData = uimenu(PODSData.Handles.hFileMenu,'Text','Save Object Data','Callback',@SaveObjectData);
% save settings
PODSData.Handles.hSaveColormapsSettings = uimenu(PODSData.Handles.hFileMenu,'Text','Save Colormaps Settings','Separator','On','Callback',@SaveColormapsSettings);
PODSData.Handles.hSaveAzimuthDisplaySettings = uimenu(PODSData.Handles.hFileMenu,'Text','Save Azimuth Display Settings','Callback',@SaveAzimuthDisplaySettings);
PODSData.Handles.hScatterPlotSettingsMenu = uimenu(PODSData.Handles.hFileMenu,'Text','Save Scatter Plot Settings','Callback',@SaveScatterPlotSettings);
PODSData.Handles.hSaveSwarmPlotSettings = uimenu(PODSData.Handles.hFileMenu,'Text','Save Swarm Plot Settings','Callback',@SaveSwarmPlotSettings);

%% Options Menu Button - Change gui option and settings

PODSData.Handles.hOptionsMenu = uimenu(PODSData.Handles.fH,'Text','Options');
% GUI options (themes, colors, fonts, etc.)
PODSData.Handles.hGUI = uimenu(PODSData.Handles.hOptionsMenu,'Text','GUI');
% GUI theme option
PODSData.Handles.hGUITheme = uimenu(PODSData.Handles.hGUI,'Text','Theme');
% options for GUI theme
PODSData.Handles.hGUITheme_Dark = uimenu(PODSData.Handles.hGUITheme,'Text','Dark','Checked','off','Callback',@ChangeGUITheme);
PODSData.Handles.hGUITheme_Dark2 = uimenu(PODSData.Handles.hGUITheme,'Text','Dark2','Checked','on','Callback',@ChangeGUITheme);
PODSData.Handles.hGUITheme_Light = uimenu(PODSData.Handles.hGUITheme,'Text','Light','Checked','off','Callback',@ChangeGUITheme);
% GUI colors options
PODSData.Handles.hGUIBackgroundColor = uimenu(PODSData.Handles.hGUI,'Text','Background Color','Separator','on','Tag','GUIBackgroundColor','Callback',@ChangeGUIColors);
PODSData.Handles.hGUIForegroundColor = uimenu(PODSData.Handles.hGUI,'Text','Foreground Color','Tag','GUIForegroundColor','Callback',@ChangeGUIColors);
PODSData.Handles.hGUIHighlightColor = uimenu(PODSData.Handles.hGUI,'Text','Highlight Color','Tag','GUIHighlightColor','Callback',@ChangeGUIColors);

% GUI font size option
PODSData.Handles.hGUIFontSize = uimenu(PODSData.Handles.hGUI,'Text','Font Size');
% options for GUI font size
PODSData.Handles.hGUIFontSize_Larger = uimenu(PODSData.Handles.hGUIFontSize,'Text','Larger','Callback',@ChangeGUIFontSize);
PODSData.Handles.hGUIFontSize_Smaller = uimenu(PODSData.Handles.hGUIFontSize,'Text','Smaller','Callback',@ChangeGUIFontSize);

% Input File Type Option
PODSData.Handles.hFileInputType = uimenu(PODSData.Handles.hOptionsMenu,'Text','File Input Type');
% Options for input file type
PODSData.Handles.hFileInputType_nd2 = uimenu(PODSData.Handles.hFileInputType,'Text','.nd2','Checked','On','Callback',@ChangeInputFileType);
PODSData.Handles.hFileInputType_tif = uimenu(PODSData.Handles.hFileInputType,'Text','.tif','Checked','Off','Callback',@ChangeInputFileType);

% Options for mask type ('Default' or 'Custom', 'Upload mask' in development
PODSData.Handles.hMaskType = uimenu(PODSData.Handles.hOptionsMenu,'Text','Mask Type');
% Option to select 'Default' mask type
PODSData.Handles.hMaskType_Default = uimenu(PODSData.Handles.hMaskType,'Text','Default');
% Names of 'Default' masks
PODSData.Handles.hMaskType_Default_Legacy = uimenu(PODSData.Handles.hMaskType_Default,'Text','Legacy','Checked','On','Tag','Default','Callback', @ChangeMaskType);
PODSData.Handles.hMaskType_Default_Filament = uimenu(PODSData.Handles.hMaskType_Default,'Text','Filament','Checked','Off','Tag','Default','Callback', @ChangeMaskType);
PODSData.Handles.hMaskType_Default_FilamentEdge = uimenu(PODSData.Handles.hMaskType_Default,'Text','FilamentEdge','Checked','Off','Tag','Default','Callback', @ChangeMaskType);
PODSData.Handles.hMaskType_Default_Intensity = uimenu(PODSData.Handles.hMaskType_Default,'Text','Intensity','Checked','Off','Tag','Default','Callback', @ChangeMaskType);
PODSData.Handles.hMaskType_Default_Adaptive = uimenu(PODSData.Handles.hMaskType_Default,'Text','Adaptive','Checked','Off','Tag','Default','Callback', @ChangeMaskType);
% Option to select 'Custom' mask type
PODSData.Handles.hMaskType_CustomScheme = uimenu(PODSData.Handles.hMaskType,'Text','CustomScheme');
% Load the custom schemes and make a menu option for each one
for i = 1:numel(PODSData.Settings.SchemeNames)
    PODSData.Handles.(['hMaskType_CustomScheme_',PODSData.Settings.SchemeNames{i}]) = ...
        uimenu(PODSData.Handles.hMaskType_CustomScheme,...
        'Text',PODSData.Settings.SchemeNames{i},...
        'Tag','CustomScheme',...
        'Checked','Off',...
        'Callback',@ChangeMaskType);
end
% Option to create new 'Custom' mask scheme
PODSData.Handles.hMaskType_NewScheme = uimenu(PODSData.Handles.hMaskType_CustomScheme,...
    'Text','Create new scheme',...
    'Separator','on',...
    'Callback',@BuildNewScheme);

% Options for display of object boxes
PODSData.Handles.hObjectBoxMenu = uimenu(PODSData.Handles.hOptionsMenu,'Text','Object boxes');
% Box type option
PODSData.Handles.hObjectBoxType = uimenu(PODSData.Handles.hObjectBoxMenu,'Text','Box type');
% options for box type
PODSData.Handles.hObjectBoxType_Box = uimenu(PODSData.Handles.hObjectBoxType,'Text','Box','Checked','On','Callback',@ChangeObjectBoxType);
PODSData.Handles.hObjectBoxType_Boundary = uimenu(PODSData.Handles.hObjectBoxType,'Text','Boundary','Checked','Off','Callback',@ChangeObjectBoxType);
PODSData.Handles.hObjectBoxType_Patch = uimenu(PODSData.Handles.hObjectBoxType,'Text','Patch','Checked','Off','Callback',@ChangeObjectBoxType);
% PODSData.Handles.hObjectBoxType_Polygon = uimenu(PODSData.Handles.hObjectBoxType,'Text','Polygon','Checked','Off','Callback',@ChangeObjectBoxType);
% PODSData.Handles.hObjectBoxType_Development = uimenu(PODSData.Handles.hObjectBoxType,'Text','Development','Checked','Off','Callback',@ChangeObjectBoxType);

%% View Menu Button - changes view of GUI to different 'tabs'

PODSData.Handles.hTabMenu = uimenu(PODSData.Handles.fH,'Text','View');
% Tabs for 'View'
PODSData.Handles.hTabFiles = uimenu(PODSData.Handles.hTabMenu,'Text','Files','MenuSelectedFcn',@TabSelection,'tag','hTabFiles');
PODSData.Handles.hTabFFC = uimenu(PODSData.Handles.hTabMenu,'Text','FFC','MenuSelectedFcn',@TabSelection,'tag','hTabFFC');
%PODSData.Handles.hTabGenerateMask = uimenu(PODSData.Handles.hTabMenu,'Text','Generate Mask','MenuSelectedFcn',@TabSelection,'tag','hTabGenerateMask');
PODSData.Handles.hTabMask = uimenu(PODSData.Handles.hTabMenu,'Text','Mask','MenuSelectedFcn',@TabSelection,'tag','hTabMask');
PODSData.Handles.hTabOrderFactor = uimenu(PODSData.Handles.hTabMenu,'Text','Order Factor','MenuSelectedFcn',@TabSelection,'tag','hTabOrderFactor');
%PODSData.Handles.hTabSBFiltering = uimenu(PODSData.Handles.hTabMenu,'Text','Filtered Order Factor','MenuSelectedFcn',@TabSelection,'tag','hTabSBFiltering');
PODSData.Handles.hTabAzimuth = uimenu(PODSData.Handles.hTabMenu,'Text','Azimuth','MenuSelectedFcn',@TabSelection,'tag','hTabAzimuth');
PODSData.Handles.hTabViewPlots = uimenu(PODSData.Handles.hTabMenu,'Text','Plots','MenuSelectedFcn',@TabSelection,'tag','hTabViewPlots');
PODSData.Handles.hViewObjects = uimenu(PODSData.Handles.hTabMenu,'Text','View Objects','MenuSelectedFcn',@TabSelection,'tag','hViewObjects');

%% Process Menu Button - allows user to perform FFC, generate mask, and generate output images

PODSData.Handles.hProcessMenu = uimenu(PODSData.Handles.fH,'Text','Process');
% Process Operations
PODSData.Handles.hProcessFFC = uimenu(PODSData.Handles.hProcessMenu,'Text','Flat-Field Correction','MenuSelectedFcn',@pb_FFC);
PODSData.Handles.hProcessMask = uimenu(PODSData.Handles.hProcessMenu,'Text','Build Mask','MenuSelectedFcn',@CreateMask4);
PODSData.Handles.hProcessOF = uimenu(PODSData.Handles.hProcessMenu,'Text','Order Factor','MenuSelectedFcn',@pb_FindOrderFactor);
PODSData.Handles.hProcessLocalSB = uimenu(PODSData.Handles.hProcessMenu,'Text','Local Signal:Background','MenuSelectedFcn',@pb_FindLocalSB);
PODSData.Handles.hProcessObjectAzimuthStats = uimenu(PODSData.Handles.hProcessMenu,'Text','Object Azimuth Stats','MenuSelectedFcn',@pb_ComputeObjectAzimuthStats);

%% Summary Menu Button

PODSData.Handles.hSummaryMenu = uimenu(PODSData.Handles.fH,'Text','Summary');
% Summary choices
PODSData.Handles.hSumaryAll = uimenu(PODSData.Handles.hSummaryMenu,'Text','All Data','MenuSelectedFcn',@ShowSummaryTable);

%% Objects Menu Button
PODSData.Handles.hObjectsMenu = uimenu(PODSData.Handles.fH,'Text','Objects');
% Object Actions
PODSData.Handles.hDeleteSelectedObjects = uimenu(PODSData.Handles.hObjectsMenu,'Text','Delete Selected Objects','MenuSelectedFcn',@mbDeleteSelectedObjects);
% PODSData.Handles.hLabelSelectedObjects = uimenu(PODSData.Handles.hObjectsMenu,'Text','Label Selected Objects','MenuSelectedFcn',@mbLabelSelectedObjects);
PODSData.Handles.hClearSelection = uimenu(PODSData.Handles.hObjectsMenu,'Text','Clear Selection','MenuSelectedFcn',@mbClearSelection);
PODSData.Handles.hkMeansClustering = uimenu(PODSData.Handles.hObjectsMenu,'Text','Label Objects with k-means Clustering','MenuSelectedFcn',@mbObjectkmeansClustering);
PODSData.Handles.hShowObjectImagesByLabel = uimenu(PODSData.Handles.hObjectsMenu,'Text','Show Object Images by Label','MenuSelectedFcn',@mbShowObjectImagesByLabel);

%% draw the menu bar objects and pause for more predictable performance

drawnow
pause(0.5)

%% CHECKPOINT

disp('Setting up grid layout manager...')

%% Set up the MainGrid uigridlayout manager

pos = PODSData.Handles.fH.Position;

% width and height of the large plots
width = round(pos(3)*0.38);

% and the small plots
swidth = round(width/2);
sheight = swidth;

% main grid for managing layout
PODSData.Handles.MainGrid = uigridlayout(PODSData.Handles.fH,[4,5]);
PODSData.Handles.MainGrid.BackgroundColor = [0 0 0];

PODSData.Handles.MainGrid.RowHeight = {'1x',swidth,swidth,'1x'};
PODSData.Handles.MainGrid.RowSpacing = 0;
PODSData.Handles.MainGrid.ColumnSpacing = 0;
PODSData.Handles.MainGrid.Padding = [0 0 0 0];

PODSData.Handles.MainGrid.ColumnWidth = {'1x',sheight,sheight,sheight,sheight};

%% CHECKPOINT

disp('Setting up non-image panels...')

%% Create the non-image panels (Summary, Selector, Settings, Log)

% panel to hold app info selector
PODSData.Handles.AppInfoSelectorPanel = uipanel(PODSData.Handles.MainGrid,...
    'Visible','Off');
PODSData.Handles.AppInfoSelectorPanel.Title = 'Summary Display Type';
PODSData.Handles.AppInfoSelectorPanel.Layout.Row = 1;
PODSData.Handles.AppInfoSelectorPanel.Layout.Column = 1;

% grid to hold img operations listbox
PODSData.Handles.AppInfoSelectorPanelGrid = uigridlayout(PODSData.Handles.AppInfoSelectorPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);

% img operations listbox
PODSData.Handles.AppInfoSelector = uilistbox('parent',PODSData.Handles.AppInfoSelectorPanelGrid,...
    'Visible','Off',...
    'enable','on',...
    'tag','AppInfoSelector',...
    'Items',{'Project','Group','Image','Object'},...
    'BackgroundColor',[1 1 1],...
    'FontColor',[0 0 0],...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'MultiSelect','Off',...
    'ValueChangedFcn',@ChangeSummaryDisplay);

% panel to show project summary
PODSData.Handles.AppInfoPanel = uipanel(PODSData.Handles.MainGrid,...
    'Visible','Off');
PODSData.Handles.AppInfoPanel.Title = 'Project Summary';
PODSData.Handles.AppInfoPanel.Layout.Row = 2;
PODSData.Handles.AppInfoPanel.Layout.Column = 1;

%% set up main settings panel

PODSData.Handles.SettingsPanel = uipanel(PODSData.Handles.MainGrid,...
    'Visible','Off');
PODSData.Handles.SettingsPanel.Layout.Row = 3;
PODSData.Handles.SettingsPanel.Layout.Column = 1;
PODSData.Handles.SettingsPanel.Title = 'Display Settings';

%% colormaps settings
ColormapNames = fieldnames(PODSData.Settings.Colormaps);
ImageTypeFields = fieldnames(PODSData.Settings.ColormapsSettings);
nImageTypes = length(ImageTypeFields);
ImageTypeFullNames = cell(1,nImageTypes);
ImageTypeColormapsNames = cell(1,nImageTypes);
ImageTypeColormaps = cell(1,nImageTypes);
for k = 1:nImageTypes
    ImageTypeFullNames{k} = PODSData.Settings.ColormapsSettings.(ImageTypeFields{k}){1};
    ImageTypeColormapsNames{k} = PODSData.Settings.ColormapsSettings.(ImageTypeFields{k}){2};
    ImageTypeColormaps{k} = PODSData.Settings.ColormapsSettings.(ImageTypeFields{k}){3};
end

PODSData.Handles.ColormapsSettingsGrid = uigridlayout(PODSData.Handles.SettingsPanel,[4,1]);
PODSData.Handles.ColormapsSettingsGrid.BackgroundColor = 'Black';
PODSData.Handles.ColormapsSettingsGrid.Padding = [5 5 5 5];
PODSData.Handles.ColormapsSettingsGrid.RowSpacing = 5;
PODSData.Handles.ColormapsSettingsGrid.ColumnSpacing = 5;
PODSData.Handles.ColormapsSettingsGrid.RowHeight = {20,'fit','1x',30};
PODSData.Handles.ColormapsSettingsGrid.ColumnWidth = {'1x'};
    
PODSData.Handles.SettingsDropDown = uidropdown(PODSData.Handles.ColormapsSettingsGrid,...
    'Items',{'Colormaps','Azimuth Display','Scatter Plot','Swarm Plot','Label'},...
    'ItemsData',{'ColormapsSettings','AzimuthDisplaySettings','ScatterPlotSettings','SwarmPlotSettings','LabelSettings'},...
    'Value','ColormapsSettings',...
    'ValueChangedFcn',@ChangeSettingsType,...
    'FontName',PODSData.Settings.DefaultFont);

PODSData.Handles.ColormapsImageTypePanel = uipanel(PODSData.Handles.ColormapsSettingsGrid,...
    'Title','Image Type',...
    'FontName',PODSData.Settings.DefaultFont);
    
PODSData.Handles.ColormapsSettingsGrid2 = uigridlayout(PODSData.Handles.ColormapsImageTypePanel,[1,1]);
PODSData.Handles.ColormapsSettingsGrid2.Padding = [0 0 0 0];

PODSData.Handles.ColormapsImageTypeSelector = uilistbox(PODSData.Handles.ColormapsSettingsGrid2,...
    'Items',ImageTypeFullNames,...
    'ItemsData',ImageTypeFields,...
    'Value',ImageTypeFields{1},...
    'Tag','ImageTypeSelectBox',...
    'ValueChangedFcn',@ImageTypeSelectionChanged,...
    'FontName',PODSData.Settings.DefaultFont);
    
PODSData.Handles.ColormapsPanel = uipanel(PODSData.Handles.ColormapsSettingsGrid,...
    'Title','Colormaps',...
    'FontName',PODSData.Settings.DefaultFont);

PODSData.Handles.ColormapsSettingsGrid3 = uigridlayout(PODSData.Handles.ColormapsPanel,[1,1]);
PODSData.Handles.ColormapsSettingsGrid3.Padding = [0 0 0 0];

PODSData.Handles.ColormapsSelector = uilistbox(PODSData.Handles.ColormapsSettingsGrid3,...
    'Items',ColormapNames,...
    'Value',ImageTypeColormapsNames{1},...
    'Tag','ColormapSelectBox',...
    'ValueChangedFcn',@ColormapSelectionChanged,...
    'FontName',PODSData.Settings.DefaultFont);

% testing below
colormapIconStyles = matlab.ui.style.Style;
colormapIconStyles = repmat(colormapIconStyles,numel(PODSData.Handles.ColormapsSelector.Items),1);
% add icon styles to each item in the colormap selector listbox to give a colormap preview
for colormapIdx = 1:numel(PODSData.Handles.ColormapsSelector.Items)
    mapImage = ind2rgb(im2uint8(repmat(linspace(0,1,256),1,1)),PODSData.Settings.Colormaps.(ColormapNames{colormapIdx}));
    colormapIconStyles(colormapIdx).Icon = mapImage;
    addStyle(PODSData.Handles.ColormapsSelector,colormapIconStyles(colormapIdx),"item",colormapIdx);
end
% end testing

% panel to hold example colormap axes
PODSData.Handles.ExampleColormapPanel = uipanel(PODSData.Handles.ColormapsSettingsGrid);

% axes to hold example colorbar
PODSData.Handles.ExampleColormapAx = uiaxes(PODSData.Handles.ExampleColormapPanel,...
    'Visible','Off',...
    'XTick',[],...
    'YTick',[],...
    'Units','Normalized',...
    'InnerPosition',[0 0 1 1]);
PODSData.Handles.ExampleColormapAx.Toolbar.Visible = 'Off';
disableDefaultInteractivity(PODSData.Handles.ExampleColormapAx);

% create image to show example colorbar for colormap switching
cbarslice = 1:1:256;
cbarimage = repmat(cbarslice,50,1);
PODSData.Handles.ExampleColorbar = image(PODSData.Handles.ExampleColormapAx,'CData',cbarimage,'CDataMapping','direct');

% set display limits to show full cbarimage without extra borders
PODSData.Handles.ExampleColormapAx.YLim = [0.5 50.5];
PODSData.Handles.ExampleColormapAx.XLim = [0.5 256.5];

PODSData.Handles.ExampleColormapAx.Colormap = ImageTypeColormaps{1};
%% azimuth display settings

PODSData.Handles.AzimuthDisplaySettingsGrid = uigridlayout(PODSData.Handles.SettingsPanel,[7,2],...
    'Visible','Off',...
    'BackgroundColor','Black');
PODSData.Handles.AzimuthDisplaySettingsGrid.Padding = [5 5 5 5];
PODSData.Handles.AzimuthDisplaySettingsGrid.RowSpacing = 10;
PODSData.Handles.AzimuthDisplaySettingsGrid.ColumnSpacing = 5;
PODSData.Handles.AzimuthDisplaySettingsGrid.RowHeight = {20,20,20,20,20,20,20};
PODSData.Handles.AzimuthDisplaySettingsGrid.ColumnWidth = {'fit','1x'};

PODSData.Handles.AzimuthLineAlphaLabel = uilabel('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Azimuth Line Alpha (default: 0.5)',...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontColor','White');
PODSData.Handles.AzimuthLineAlphaLabel.Layout.Row = 2;
PODSData.Handles.AzimuthLineAlphaLabel.Layout.Column = 1;
PODSData.Handles.AzimuthLineAlphaDropdown = uidropdown('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'},...
    'ItemsData',{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1},...
    'Value',PODSData.Settings.AzimuthLineAlpha,...
    'FontName',PODSData.Settings.DefaultFont);
PODSData.Handles.AzimuthLineAlphaDropdown.Layout.Row = 2;
PODSData.Handles.AzimuthLineAlphaDropdown.Layout.Column = 2;

PODSData.Handles.AzimuthLineWidthLabel = uilabel('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Azimuth Line Width (default: 1 pt)',...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontColor','White');
PODSData.Handles.AzimuthLineWidthLabel.Layout.Row = 3;
PODSData.Handles.AzimuthLineWidthLabel.Layout.Column = 1;
PODSData.Handles.AzimuthLineWidthDropdown = uidropdown('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'1','2','3','4','5','6','7','8','9','10'},...
    'ItemsData',{1,2,3,4,5,6,7,8,9,10},...
    'Value',PODSData.Settings.AzimuthLineWidth,...
    'FontName',PODSData.Settings.DefaultFont);
PODSData.Handles.AzimuthLineWidthDropdown.Layout.Row = 3;
PODSData.Handles.AzimuthLineWidthDropdown.Layout.Column = 2;

PODSData.Handles.AzimuthLineScaleLabel = uilabel('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Azimuth Line Scale Factor (default: 100)',...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontColor','White');
PODSData.Handles.AzimuthLineScaleLabel.Layout.Row = 4;
PODSData.Handles.AzimuthLineScaleLabel.Layout.Column = 1;
PODSData.Handles.AzimuthLineScaleEditfield = uieditfield('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Value',num2str(PODSData.Settings.AzimuthLineScale),...
    'FontName',PODSData.Settings.DefaultFont);
PODSData.Handles.AzimuthLineScaleEditfield.Layout.Row = 4;
PODSData.Handles.AzimuthLineScaleEditfield.Layout.Column = 2;

PODSData.Handles.AzimuthLineScaleDownLabel = uilabel('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Number of Lines to Show (default: All)',...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontColor','White');
PODSData.Handles.AzimuthLineScaleDownLabel.Layout.Row = 5;
PODSData.Handles.AzimuthLineScaleDownLabel.Layout.Column = 1;
PODSData.Handles.AzimuthLineScaleDownDropdown = uidropdown('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'All','Half','Quarter'},...
    'ItemsData',{1,2,4},...
    'Value',PODSData.Settings.AzimuthScaleDownFactor,...
    'FontName',PODSData.Settings.DefaultFont);
PODSData.Handles.AzimuthLineScaleDownDropdown.Layout.Row = 5;
PODSData.Handles.AzimuthLineScaleDownDropdown.Layout.Column = 2;
PODSData.Handles.AzimuthLineScaleDownDropdown.ItemsData = [1 2 4];

PODSData.Handles.AzimuthColorModeDropdownLabel = uilabel('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Text','Line color mode (default: Direction)',...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontColor','White');
PODSData.Handles.AzimuthColorModeDropdownLabel.Layout.Row = 6;
PODSData.Handles.AzimuthColorModeDropdownLabel.Layout.Column = 1;
PODSData.Handles.AzimuthColorModeDropdown = uidropdown('Parent',PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Items',{'Direction','Magnitude','Mono'},...
    'Value',PODSData.Settings.AzimuthColorMode,...
    'FontName',PODSData.Settings.DefaultFont);
PODSData.Handles.AzimuthColorModeDropdown.Layout.Row = 6;
PODSData.Handles.AzimuthColorModeDropdown.Layout.Column = 2;

PODSData.Handles.ApplyAzimuthDisplaySettingsButton = uibutton(PODSData.Handles.AzimuthDisplaySettingsGrid,...
    'Push',...
    'Text','Apply',...
    'ButtonPushedFcn',@ApplyAzimuthSettings,...
    'FontName',PODSData.Settings.DefaultFont);
PODSData.Handles.ApplyAzimuthDisplaySettingsButton.Layout.Row = 7;
PODSData.Handles.ApplyAzimuthDisplaySettingsButton.Layout.Column = [1 2];
%% ScatterPlot settings

PODSData.Handles.ScatterPlotSettingsGrid = uigridlayout(PODSData.Handles.SettingsPanel,[3,1],...
    'BackgroundColor','Black',...
    'Visible','Off');
PODSData.Handles.ScatterPlotSettingsGrid.Padding = [5 5 5 5];
PODSData.Handles.ScatterPlotSettingsGrid.RowSpacing = 5;
PODSData.Handles.ScatterPlotSettingsGrid.ColumnSpacing = 5;
PODSData.Handles.ScatterPlotSettingsGrid.RowHeight = {20,'1x','1x'};
PODSData.Handles.ScatterPlotSettingsGrid.ColumnWidth = {'1x'};

% setting up x-axis variable selection
PODSData.Handles.ScatterPlotXVarListBoxPanel = uipanel(PODSData.Handles.ScatterPlotSettingsGrid,...
    'Title','X-axis Variable');
PODSData.Handles.ScatterPlotXVarListBoxPanel.Layout.Row = 2;
PODSData.Handles.ScatterPlotXVarListBoxPanel.Layout.Column = 1;

PODSData.Handles.ScatterPlotXVarGrid = uigridlayout(PODSData.Handles.ScatterPlotXVarListBoxPanel,[1,1]);
PODSData.Handles.ScatterPlotXVarGrid.Padding = [0 0 0 0];

PODSData.Handles.ScatterPlotXVarSelectBox = uilistbox(PODSData.Handles.ScatterPlotXVarGrid,...
    'Items', PODSData.Settings.ObjectPlotVariablesLong,...
    'ItemsData', PODSData.Settings.ObjectPlotVariables,...
    'Value',PODSData.Settings.ScatterPlotXVariable,...
    'Tag','XVariable',...
    'ValueChangedFcn',@ScatterPlotVariablesChanged,...
    'FontName',PODSData.Settings.DefaultFont);

% setting up y-axis variable selection
PODSData.Handles.ScatterPlotYVarListBoxPanel = uipanel(PODSData.Handles.ScatterPlotSettingsGrid,...
    'Title','Y-axis Variable');
PODSData.Handles.ScatterPlotYVarListBoxPanel.Layout.Row = 3;
PODSData.Handles.ScatterPlotYVarListBoxPanel.Layout.Column = 1;

PODSData.Handles.ScatterPlotYVarGrid = uigridlayout(PODSData.Handles.ScatterPlotYVarListBoxPanel,[1,1]);
PODSData.Handles.ScatterPlotYVarGrid.Padding = [0 0 0 0];

PODSData.Handles.ScatterPlotYVarSelectBox = uilistbox(PODSData.Handles.ScatterPlotYVarGrid,...
    'Items', PODSData.Settings.ObjectPlotVariablesLong,...
    'ItemsData', PODSData.Settings.ObjectPlotVariables,...
    'Value',PODSData.Settings.ScatterPlotYVariable,...
    'Tag','YVariable',...
    'ValueChangedFcn',@ScatterPlotVariablesChanged,...
    'FontName',PODSData.Settings.DefaultFont);
%% SwarmPlot settings

PODSData.Handles.SwarmPlotSettingsGrid = uigridlayout(PODSData.Handles.SettingsPanel,[4,2],...
    'BackgroundColor','Black',...
    'Visible','Off');
PODSData.Handles.SwarmPlotSettingsGrid.Padding = [5 5 5 5];
PODSData.Handles.SwarmPlotSettingsGrid.RowSpacing = 5;
PODSData.Handles.SwarmPlotSettingsGrid.ColumnSpacing = 5;
PODSData.Handles.SwarmPlotSettingsGrid.RowHeight = {20,'1x',20,20};
PODSData.Handles.SwarmPlotSettingsGrid.ColumnWidth = {'fit','1x'};

% setting up x-axis variable selection
PODSData.Handles.SwarmPlotYVarListBoxPanel = uipanel(PODSData.Handles.SwarmPlotSettingsGrid,...
    'Title','Y-axis Variable');
PODSData.Handles.SwarmPlotYVarListBoxPanel.Layout.Row = 2;
PODSData.Handles.SwarmPlotYVarListBoxPanel.Layout.Column = [1 2];

PODSData.Handles.SwarmPlotYVarGrid = uigridlayout(PODSData.Handles.SwarmPlotYVarListBoxPanel,[1,1]);
PODSData.Handles.SwarmPlotYVarGrid.Padding = [0 0 0 0];

PODSData.Handles.SwarmPlotYVarSelectBox = uilistbox(PODSData.Handles.SwarmPlotYVarGrid,...
    'Items', PODSData.Settings.ObjectPlotVariablesLong,...
    'ItemsData', PODSData.Settings.ObjectPlotVariables,...
    'Value',PODSData.Settings.SwarmPlotYVariable,...
    'Tag','YVariable',...
    'ValueChangedFcn',@SwarmPlotYVariableChanged,...
    'FontName',PODSData.Settings.DefaultFont);

% grouping type
PODSData.Handles.SwarmPlotGroupingTypeDropdownLabel = uilabel('Parent',PODSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Grouping type',...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontColor','White');
PODSData.Handles.SwarmPlotGroupingTypeDropdownLabel.Layout.Row = 3;
PODSData.Handles.SwarmPlotGroupingTypeDropdownLabel.Layout.Column = 1;

PODSData.Handles.SwarmPlotGroupingTypeDropdown = uidropdown('Parent',PODSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Group','Label','Both'},...
    'ItemsData',{'Group','Label','Both'},...
    'Value',PODSData.Settings.SwarmPlotGroupingType,...
    'FontName',PODSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotGroupingTypeChanged);
PODSData.Handles.SwarmPlotGroupingTypeDropdown.Layout.Row = 3;
PODSData.Handles.SwarmPlotGroupingTypeDropdown.Layout.Column = 2;

% color mode
PODSData.Handles.SwarmPlotColorModeDropdownLabel = uilabel('Parent',PODSData.Handles.SwarmPlotSettingsGrid,...
    'Text','Color mode',...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontColor','White');
PODSData.Handles.SwarmPlotColorModeDropdownLabel.Layout.Row = 4;
PODSData.Handles.SwarmPlotColorModeDropdownLabel.Layout.Column = 1;

PODSData.Handles.SwarmPlotColorModeDropdown = uidropdown('Parent',PODSData.Handles.SwarmPlotSettingsGrid,...
    'Items',{'Magnitude','ID'},...
    'ItemsData',{'Magnitude','ID'},...
    'Value',PODSData.Settings.SwarmPlotColorMode,...
    'FontName',PODSData.Settings.DefaultFont,...
    'ValueChangedFcn',@SwarmPlotColorModeChanged);
PODSData.Handles.SwarmPlotColorModeDropdown.Layout.Row = 4;
PODSData.Handles.SwarmPlotColorModeDropdown.Layout.Column = 2;
%% Label settings

PODSData.Handles.LabelSettingsGrid = uigridlayout(PODSData.Handles.SettingsPanel,[2,1],...
    'BackgroundColor','Black',...
    'Visible','Off');
PODSData.Handles.LabelSettingsGrid.Padding = [5 5 5 5];
PODSData.Handles.LabelSettingsGrid.RowSpacing = 5;
PODSData.Handles.LabelSettingsGrid.ColumnSpacing = 5;
PODSData.Handles.LabelSettingsGrid.RowHeight = {20,'1x'};
PODSData.Handles.LabelSettingsGrid.ColumnWidth = {'1x'};

% setting up x-axis variable selection
PODSData.Handles.LabelListBoxPanel = uipanel(PODSData.Handles.LabelSettingsGrid,...
    'Title','Object labels');
PODSData.Handles.LabelListBoxPanel.Layout.Row = 2;
PODSData.Handles.LabelListBoxPanel.Layout.Column = 1;

PODSData.Handles.LabelGrid = uigridlayout(PODSData.Handles.LabelListBoxPanel,[1,1]);
PODSData.Handles.LabelGrid.Padding = [0 0 0 0];

PODSData.Handles.LabelTree = uitree(PODSData.Handles.LabelGrid,...
    'NodeTextChangedFcn',@LabelTreeNodeTextChanged,...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','bold',...
    'Interruptible','off',...
    'Editable','on',...
    'Multiselect','On');

% context menu for individual labels
PODSData.Handles.LabelContextMenu = uicontextmenu(PODSData.Handles.fH);
PODSData.Handles.LabelContextMenu_ApplyLabelToSelectedObjects = uimenu(PODSData.Handles.LabelContextMenu,'Text','Apply label to selected objects','MenuSelectedFcn',{@ApplyLabelToSelectedObjects,PODSData.Handles.fH});
PODSData.Handles.LabelContextMenu_SelectLabeledObjects = uimenu(PODSData.Handles.LabelContextMenu,'Text','Select objects with selected label(s)','MenuSelectedFcn',{@SelectLabeledObjects,PODSData.Handles.fH});
PODSData.Handles.LabelContextMenu_Delete = uimenu(PODSData.Handles.LabelContextMenu,'Text','Delete label(s)','MenuSelectedFcn',{@DeleteLabel,PODSData.Handles.fH});
PODSData.Handles.LabelContextMenu_DeleteLabelAndObjects = uimenu(PODSData.Handles.LabelContextMenu,'Text','Delete label(s) and objects','MenuSelectedFcn',{@DeleteLabelAndObjects,PODSData.Handles.fH});
PODSData.Handles.LabelContextMenu_ChangeColor = uimenu(PODSData.Handles.LabelContextMenu,'Text','Change label color','MenuSelectedFcn',{@EditLabelColor,PODSData.Handles.fH});
PODSData.Handles.LabelContextMenu_MergeLabels = uimenu(PODSData.Handles.LabelContextMenu,'Text','Merge selected labels','MenuSelectedFcn',{@MergeLabels,PODSData.Handles.fH});
PODSData.Handles.LabelContextMenu_AddNewLabel = uimenu(PODSData.Handles.LabelContextMenu,'Text','New label','MenuSelectedFcn',@AddNewLabel);

uitreenode(PODSData.Handles.LabelTree,...
    'Text',PODSData.Settings.ObjectLabels(1).Name,...
    'NodeData',PODSData.Settings.ObjectLabels(1),...
    'ContextMenu',PODSData.Handles.LabelContextMenu,...
    'Icon',makeRGBColorSquare(PODSData.Settings.ObjectLabels(1).Color,10));

% draw the current figure to update final container sizes
drawnow
pause(0.05)

%% ImgOperations grid layout (currently for interactive thresholding and intensity display)

PODSData.Handles.ImageOperationsGrid = uigridlayout(PODSData.Handles.MainGrid,[1,2],'BackgroundColor',[0 0 0],'Padding',[0 0 0 0]);
PODSData.Handles.ImageOperationsGrid.ColumnWidth = {'0.25x','0.75x'};
PODSData.Handles.ImageOperationsGrid.ColumnSpacing = 0;
PODSData.Handles.ImageOperationsGrid.Layout.Row = 1;
PODSData.Handles.ImageOperationsGrid.Layout.Column = [4 5];

% panel to hold img operations listbox grid
PODSData.Handles.ImageOperationsSelectorPanel = uipanel(PODSData.Handles.ImageOperationsGrid,...
    'Visible','Off');
PODSData.Handles.ImageOperationsSelectorPanel.Title = 'Image Operations';
PODSData.Handles.ImageOperationsSelectorPanel.Layout.Column = 1;

% grid to hold img operations listbox
PODSData.Handles.ImageOperationsSelectorPanelGrid = uigridlayout(PODSData.Handles.ImageOperationsSelectorPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);
% img operations listbox
PODSData.Handles.ImageOperationsSelector = uilistbox('parent',PODSData.Handles.ImageOperationsSelectorPanelGrid,...
    'Visible','Off',...
    'enable','on',...
    'tag','SettingsSelector',...
    'Items',{'Mask Threshold','Intensity Display'},...
    'BackgroundColor',[1 1 1],...
    'FontColor',[0 0 0],...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'MultiSelect','Off',...
    'ValueChangedFcn',@ChangeImageOperation);

PODSData.Handles.ImageOperationsPanel = uipanel(PODSData.Handles.ImageOperationsGrid,...
    'Visible','Off');
PODSData.Handles.ImageOperationsPanel.Layout.Column = 2;
PODSData.Handles.ImageOperationsPanel.Title = 'Adjust Otsu threshhold';

%% LogPanel

% panel to display log messages (updates user on running/completed processes)
PODSData.Handles.LogPanel = uipanel(PODSData.Handles.MainGrid,...
    'Visible','Off');
PODSData.Handles.LogPanel.Title = 'Log Window';
PODSData.Handles.LogPanel.Layout.Row = 4;
PODSData.Handles.LogPanel.Layout.Column = [1 5];

%% CHECKPOINT

disp('Setting up image panels...')

%% Small Image Panels
% tags for small panels
panel_tags = ['Panel_1-1' 'Panel_1-2' 'Panel_1-3' 'Panel_1-4';...
    'Panel_2-1' 'Panel_2-2' 'Panel_2-3' 'Panel_2-4'];

for SmallPanelRows = 1:2
    for SmallPanelColumns = 1:4
        PODSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns) = uipanel(PODSData.Handles.MainGrid,'Visible','Off');
        PODSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Row = SmallPanelRows+1;
        PODSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Column = SmallPanelColumns+1;
        PODSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Tag = panel_tags(SmallPanelRows,SmallPanelColumns);
        % Important to set so we can resize children of panels with expected behavior
        PODSData.Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).AutoResizeChildren = 'Off';
    end
end

%% Large Image Panels
% first one (lefthand panel)
PODSData.Handles.ImgPanel1 = uipanel(PODSData.Handles.MainGrid,...
    'Visible','Off');
PODSData.Handles.ImgPanel1.Layout.Row = [2 3];
PODSData.Handles.ImgPanel1.Layout.Column = [2 3];

% second one (righthand panel)
PODSData.Handles.ImgPanel2 = uipanel(PODSData.Handles.MainGrid,...
    'Visible','Off');
PODSData.Handles.ImgPanel2.Layout.Row = [2 3];
PODSData.Handles.ImgPanel2.Layout.Column = [4 5];

% add these to an array so we can change their settings simultaneously
PODSData.Handles.LargePanels = [PODSData.Handles.ImgPanel1,PODSData.Handles.ImgPanel2];



%% draw all the panels and pause briefly for more predictable performance
drawnow
pause(0.5)

%% CHECKPOINT

disp('Setting up selection listboxes...')

%% Selection panels (selection listboxes/trees for group/image/objects)

PODSData.Handles.SelectorGrid = uigridlayout(PODSData.Handles.MainGrid,[1,3],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);
PODSData.Handles.SelectorGrid.Layout.Row = 1;
PODSData.Handles.SelectorGrid.Layout.Column = [2 3];
PODSData.Handles.SelectorGrid.ColumnWidth = {'0.25x','0.5x','0.25x'};
PODSData.Handles.SelectorGrid.ColumnSpacing = 0;

% group selector (uitree)
PODSData.Handles.GroupSelectorPanel = uipanel(PODSData.Handles.SelectorGrid,...
    'Title','Group Selection',...
    'Visible','Off');
PODSData.Handles.GroupSelectorPanelGrid = uigridlayout(PODSData.Handles.GroupSelectorPanel,[1,1],...
    'Padding',[0 0 0 0]);
PODSData.Handles.GroupTree = uitree(PODSData.Handles.GroupSelectorPanelGrid,...
    'SelectionChangedFcn',@GroupSelectionChanged,...
    'NodeTextChangedFcn',@GroupTreeNodeTextChanged,...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','bold',...
    'Interruptible','off',...
    'Editable','on');
PODSData.Handles.GroupTree.Layout.Row = 1;
PODSData.Handles.GroupTree.Layout.Column = 1;
% context menu for the entire group tree
PODSData.Handles.GroupTreeContextMenu = uicontextmenu(PODSData.Handles.fH);
PODSData.Handles.GroupTreeContextMenu_New = uimenu(PODSData.Handles.GroupTreeContextMenu,...
    'Text','New group',...
    'MenuSelectedFcn',@AddNewGroup);
PODSData.Handles.GroupTree.ContextMenu = PODSData.Handles.GroupTreeContextMenu;
% context menu for individual groups
PODSData.Handles.GroupContextMenu = uicontextmenu(PODSData.Handles.fH);
PODSData.Handles.GroupContextMenu_Delete = uimenu(PODSData.Handles.GroupContextMenu,...
    'Text','Delete group',...
    'MenuSelectedFcn',{@DeleteGroup,PODSData.Handles.fH});
PODSData.Handles.GroupContextMenu_ChangeColor = uimenu(PODSData.Handles.GroupContextMenu,...
    'Text','Change color',...
    'MenuSelectedFcn',{@EditGroupColor,PODSData.Handles.fH});
PODSData.Handles.GroupContextMenu_New = uimenu(PODSData.Handles.GroupContextMenu,...
    'Text','New group',...
    'MenuSelectedFcn',@AddNewGroup);

% image selector (uitree)
PODSData.Handles.ImageSelectorPanel = uipanel(PODSData.Handles.SelectorGrid,...
    'Title','Image Selection',...
    'Visible','Off');
PODSData.Handles.ImageSelectorPanelGrid = uigridlayout(PODSData.Handles.ImageSelectorPanel,[1,1],...
    'Padding',[0 0 0 0]);
PODSData.Handles.ImageTree = uitree(PODSData.Handles.ImageSelectorPanelGrid,...
    'SelectionChangedFcn',@ImageSelectionChanged,...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','bold',...
    'Multiselect','on',...
    'Enable','on',...
    'Interruptible','off');
PODSData.Handles.ImageTree.Layout.Row = 1;
PODSData.Handles.ImageTree.Layout.Column = 1;
% context menu for individual image nodes
PODSData.Handles.ImageContextMenu = uicontextmenu(PODSData.Handles.fH);
PODSData.Handles.ImageContextMenu_Delete = uimenu(PODSData.Handles.ImageContextMenu,...
    'Text','Delete selected',...
    'MenuSelectedFcn',{@DeleteImage,PODSData.Handles.fH});

% object selector (listbox, will replace with tree, but too slow for now)
PODSData.Handles.ObjectSelectorPanel = uipanel(PODSData.Handles.SelectorGrid,...
    'Title','Object Selection',...
    'Visible','Off');
PODSData.Handles.ObjectSelectorPanelGrid = uigridlayout(PODSData.Handles.ObjectSelectorPanel,[1,1],...
    'Padding',[0 0 0 0]);
PODSData.Handles.ObjectSelector = uilistbox(...
    'parent',PODSData.Handles.ObjectSelectorPanelGrid,...
    'Visible','Off',...
    'enable','on',...
    'tag','ObjectListBox',...
    'Items',{'Select image to view objects...'},...
    'ValueChangedFcn',@ChangeActiveObject,...
    'BackgroundColor',[1 1 1],...
    'FontColor',[0 0 0],...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'MultiSelect','off',...
    'Visible','Off',...
    'Interruptible','off');

%% CHECKPOINT

disp('Setting up thresholding histogram/slider...')

%% Interactive User Thresholding

PODSData.Handles.ThreshSliderGrid = uigridlayout(PODSData.Handles.ImageOperationsPanel,[1,1],...
    'Padding',[0 0 0 0],...
    'BackgroundColor','Black');
% axes to show intensity histogram
PODSData.Handles.ThreshAxH = uiaxes(PODSData.Handles.ThreshSliderGrid,...
    'Color','Black',...
    'Visible','On',...
    'FontName',PODSData.Settings.DefaultFont,...
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
disableDefaultInteractivity(PODSData.Handles.ThreshAxH);
% graphics/display sometimes unpredictable when toolbar is visible, let's turn it off
PODSData.Handles.ThreshAxH.Toolbar.Visible = 'Off';
% generate some random data (1024x1024) for histogram placeholder
RandomData = rand(1024,1024);
% build histogram from random data
[IntensityBinCenters,IntensityHistPlot] = BuildHistogram(RandomData);
% add histogram info to bar plot, place plot in thresholding axes
PODSData.Handles.ThreshBar = bar(PODSData.Handles.ThreshAxH,IntensityBinCenters,IntensityHistPlot,...
    'FaceColor',[0.5 0.5 0.5],...
    'EdgeColor','None',...
    'PickableParts','None');
% vertical line with draggable behavior for interactive thresholding
PODSData.Handles.CurrentThresholdLine = xline(PODSData.Handles.ThreshAxH,0.5,'-',{'Threshold = 0.5'},...
    'Tag','CurrentThresholdLine',...
    'LabelOrientation','Horizontal',...
    'PickableParts','None',...
    'HitTest','Off',...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'LineWidth',1.5,...
    'Color','White',...
    'LabelVerticalAlignment','Middle');

clear RandomData

drawnow
pause(0.1)

%% Intensity display limits range sliders

PODSData.Handles.IntensitySlidersGrid = uigridlayout(PODSData.Handles.ImageOperationsPanel,[2 1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[5 5 5 5],...
    'Visible','Off');
PODSData.Handles.IntensitySlidersGrid.RowSpacing = 0;
PODSData.Handles.IntensitySlidersGrid.RowHeight = {'1x','1x'};

PODSData.Handles.PrimaryIntensitySlider = RangeSlider('Parent',PODSData.Handles.IntensitySlidersGrid,...
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
PODSData.Handles.PrimaryIntensitySlider.Layout.Row = 1;
PODSData.Handles.PrimaryIntensitySlider.ValueChangedFcn = @AdjustPrimaryChannelIntensity;

PODSData.Handles.ReferenceIntensitySlider = RangeSlider('Parent',PODSData.Handles.IntensitySlidersGrid,...
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
PODSData.Handles.ReferenceIntensitySlider.Layout.Row = 2;
PODSData.Handles.ReferenceIntensitySlider.ValueChangedFcn = @AdjustReferenceChannelIntensity;

%% CHECKPOINT

disp('Setting up log window...')

%% Log Window
PODSData.Handles.LogWindowGrid = uigridlayout(PODSData.Handles.LogPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);
PODSData.Handles.LogWindow = uitextarea(PODSData.Handles.LogWindowGrid,...
    'HorizontalAlignment','left',...
    'enable','on',...
    'tag','LogWindow',...
    'BackgroundColor','black',...
    'FontColor','white',...
    'FontName',PODSData.Settings.DefaultFont,...
    'Value',{''},...
    'Visible','off',...
    'Editable','off');
%% CHECKPOINT

disp('Setting up summary table...')

%% Summary table for current project/group/image/object
% summary table for the project
PODSData.Handles.ProjectSummaryTableGrid = uigridlayout(PODSData.Handles.AppInfoPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Scrollable','on',...
    'RowHeight',{'fit'},...
    'Visible','off');
PODSData.Handles.ProjectSummaryTable = uitable(PODSData.Handles.ProjectSummaryTableGrid);
% summary table for the current group
PODSData.Handles.GroupSummaryTableGrid = uigridlayout(PODSData.Handles.AppInfoPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Scrollable','on',...
    'Visible','off',...
    'RowHeight',{'fit'});
PODSData.Handles.GroupSummaryTable = uitable(PODSData.Handles.GroupSummaryTableGrid);
% summary table for the current image
PODSData.Handles.ImageSummaryTableGrid = uigridlayout(PODSData.Handles.AppInfoPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Scrollable','on',...
    'Visible','off',...
    'RowHeight',{'fit'});
PODSData.Handles.ImageSummaryTable = uitable(PODSData.Handles.ImageSummaryTableGrid);
% summary table for current object
PODSData.Handles.ObjectSummaryTableGrid = uigridlayout(PODSData.Handles.AppInfoPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0],...
    'Scrollable','on',...
    'Visible','off',...
    'RowHeight',{'fit'});
PODSData.Handles.ObjectSummaryTable = uitable(PODSData.Handles.ObjectSummaryTableGrid);
%% CHECKPOINT

disp('Setting up context menus...')

%% AXES AND IMAGE PLACEHOLDERS

% empty placeholder image
emptyimage = zeros(1024,1024);

%% CHECKPOINT

disp('Setting up small image axes...')

%% Small Images
    %% FLAT-FIELD IMAGES

for k = 1:4
    PODSData.Handles.FFCAxH(k) = uiaxes('Parent',PODSData.Handles.SmallPanels(2,k),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag',['FFC' num2str((k-1)*45)],...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = PODSData.Handles.FFCAxH(k).PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.FFCAxH(k).Tag;
    % place placeholder image on axis
    PODSData.Handles.FFCImgH(k) = imshow(full(emptyimage),'Parent',PODSData.Handles.FFCAxH(k));
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.FFCImgH(k),'Tag',['FFCImage' num2str((k-1)*45)]);
    
    % restore original values after imshow() call
    PODSData.Handles.FFCAxH(k) = restore_axis_defaults(PODSData.Handles.FFCAxH(k),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    PODSData.Handles.FFCAxH(k) = SetAxisTitle(PODSData.Handles.FFCAxH(k),['Flat-Field Image (' num2str((k-1)*45) '^{\circ} Excitation)']);
    PODSData.Handles.FFCAxH(k).Colormap = PODSData.Settings.IntensityColormap;
    PODSData.Handles.FFCImgH(k).HitTest = 'Off';
    
    disableDefaultInteractivity(PODSData.Handles.FFCAxH(k));
end

    %% RAW INTENSITY IMAGES
for k = 1:4
    PODSData.Handles.RawIntensityAxH(k) = uiaxes('Parent',PODSData.Handles.SmallPanels(1,k),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag',['Raw' num2str((k-1)*45)],...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = PODSData.Handles.RawIntensityAxH(k).PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.RawIntensityAxH(k).Tag;
    % place placeholder image on axis
    PODSData.Handles.RawIntensityImgH(k) = imshow(full(emptyimage),'Parent',PODSData.Handles.RawIntensityAxH(k));
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.RawIntensityImgH(k),'Tag',['RawImage' num2str((k-1)*45)]);
    
    % restore original values after imshow() call
    PODSData.Handles.RawIntensityAxH(k) = restore_axis_defaults(PODSData.Handles.RawIntensityAxH(k),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    PODSData.Handles.RawIntensityAxH(k) = SetAxisTitle(PODSData.Handles.RawIntensityAxH(k),['Raw Intensity (' num2str((k-1)*45) '^{\circ} Excitation)']);
    PODSData.Handles.RawIntensityAxH(k).Colormap = PODSData.Settings.IntensityColormap;
    PODSData.Handles.RawIntensityImgH(k).HitTest = 'Off';
    
    disableDefaultInteractivity(PODSData.Handles.RawIntensityAxH(k));
end
 
    %% FLAT-FIELD CORRECTED INTENSITY
for k = 1:4
    PODSData.Handles.PolFFCAxH(k) = uiaxes('Parent',PODSData.Handles.SmallPanels(2,k),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag',['PolFFC' num2str((k-1)*45)],...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = PODSData.Handles.PolFFCAxH(k).PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.PolFFCAxH(k).Tag;
    % place placeholder image on axis
    PODSData.Handles.PolFFCImgH(k) = imshow(full(emptyimage),'Parent',PODSData.Handles.PolFFCAxH(k));
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.PolFFCImgH(k),'Tag',['PolFFCImage' num2str((k-1)*45)]);
    
    % restore original values after imshow() call
    PODSData.Handles.PolFFCAxH(k) = restore_axis_defaults(PODSData.Handles.PolFFCAxH(k),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    PODSData.Handles.PolFFCAxH(k) = SetAxisTitle(PODSData.Handles.PolFFCAxH(k),['Flat-Field Corrected Intensity (' num2str((k-1)*45) '^{\circ} Excitation)']);
    
    PODSData.Handles.PolFFCAxH(k).Colormap = PODSData.Settings.IntensityColormap;
    PODSData.Handles.PolFFCAxH(k).Toolbar.Visible = 'Off';
    PODSData.Handles.PolFFCAxH(k).Title.Visible = 'Off';
    PODSData.Handles.PolFFCAxH(k).HitTest = 'Off';
    disableDefaultInteractivity(PODSData.Handles.PolFFCAxH(k));
    
    PODSData.Handles.PolFFCImgH(k).Visible = 'Off';
    PODSData.Handles.PolFFCImgH(k).HitTest = 'Off';
end

%% CHECKPOINT

disp('Setting up large image axes...')

    %% AVERAGE INTENSITY
    PODSData.Handles.AverageIntensityAxH = uiaxes(PODSData.Handles.ImgPanel1,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','AverageIntensity',...
        'XTick',[],...
        'YTick',[],...
        'Color','Black');
    % save original values to be restored after calling imshow()
    pbarOriginal = PODSData.Handles.AverageIntensityAxH.PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.AverageIntensityAxH.Tag;
    % place placeholder image on axis
    PODSData.Handles.AverageIntensityImgH = imshow(full(emptyimage),'Parent',PODSData.Handles.AverageIntensityAxH);
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.AverageIntensityImgH,'Tag','AverageIntensityImage');
    
    % restore original values after imshow() call
    PODSData.Handles.AverageIntensityAxH = restore_axis_defaults(PODSData.Handles.AverageIntensityAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    PODSData.Handles.AverageIntensityAxH = SetAxisTitle(PODSData.Handles.AverageIntensityAxH,'Average Intensity (Flat-Field Corrected)');
    % set celormap
    PODSData.Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormap;
    % hide axes toolbar and title, turn off hittest
    PODSData.Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.AverageIntensityAxH.Title.Visible = 'Off';
    PODSData.Handles.AverageIntensityAxH.HitTest = 'Off';
    disableDefaultInteractivity(PODSData.Handles.AverageIntensityAxH);
    % hide/diable image
    PODSData.Handles.AverageIntensityImgH.Visible = 'Off';
    PODSData.Handles.AverageIntensityImgH.HitTest = 'Off';

    %% Order Factor

    PODSData.Handles.OrderFactorAxH = uiaxes(PODSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','OrderFactor',...
        'XTick',[],...
        'YTick',[],...
        'CLim',[0 1],...
        'Color','Black');
    % save original values to be restored after calling imshow()
    pbarOriginal = PODSData.Handles.OrderFactorAxH.PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.OrderFactorAxH.Tag;
    % place placeholder image on axis
    PODSData.Handles.OrderFactorImgH = imshow(full(emptyimage),'Parent',PODSData.Handles.OrderFactorAxH);
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.OrderFactorImgH,'Tag','OrderFactorImage');
    % restore original values after imshow() call
    PODSData.Handles.OrderFactorAxH = restore_axis_defaults(PODSData.Handles.OrderFactorAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    PODSData.Handles.OrderFactorAxH = SetAxisTitle(PODSData.Handles.OrderFactorAxH,'Pixel-by-pixel Order Factor');

    % make colorbar and set colormap for the axes, hide the colorbar and disable interactions with it
    PODSData.Handles.OFCbar = colorbar(PODSData.Handles.OrderFactorAxH,'location','east','color','white','tag','OFCbar');
    PODSData.Handles.OrderFactorAxH.Colormap = PODSData.Settings.OrderFactorColormap;
    PODSData.Handles.OFCbar.Visible = 'Off';
    PODSData.Handles.OFCbar.HitTest = 'Off';
    % hide axes toolbar and title, disable click interactivity, disable all default interactivity
    PODSData.Handles.OrderFactorAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.OrderFactorAxH.Title.Visible = 'Off';
    PODSData.Handles.OrderFactorAxH.HitTest = 'Off';
    disableDefaultInteractivity(PODSData.Handles.OrderFactorAxH);
    
    PODSData.Handles.OrderFactorImgH.Visible = 'Off';
    PODSData.Handles.OrderFactorImgH.HitTest = 'Off';
    
    %% Axis for swarm plots

    PODSData.Handles.SwarmPlotGrid = uigridlayout(PODSData.Handles.ImgPanel2,[1,1],...
        'Padding',[0 0 0 0],...
        'BackgroundColor',PODSData.Settings.SwarmPlotBackgroundColor,...
        'Tag','SwarmPlotGrid',...
        'Visible','Off',...
        'ColumnWidth',{'1x'},...
        'RowHeight',{'1x'});

    PODSData.Handles.SwarmPlotAxH = uiaxes(PODSData.Handles.SwarmPlotGrid,...
        'Tag','SwarmPlotAxes',...
        'XTick',[],...
        'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0],...
        'NextPlot','Add',...
        'Visible','Off',...
        'Color',PODSData.Settings.SwarmPlotBackgroundColor,...
        'XColor','White',...
        'YColor','White',...
        'HitTest','Off',...
        'FontName',PODSData.Settings.DefaultPlotFont);
    
    %disableDefaultInteractivity(PODSData.Handles.SwarmPlotAxH);
    PODSData.Handles.SwarmPlotAxH.Interactions = dataTipInteraction;
    axtoolbar(PODSData.Handles.SwarmPlotAxH,{});

    % set axis title
    PODSData.Handles.SwarmPlotAxH = SetAxisTitle(PODSData.Handles.SwarmPlotAxH,'Object OF (per group)');
    PODSData.Handles.SwarmPlotAxH.XAxis.Label.String = "Group";
    PODSData.Handles.SwarmPlotAxH.XAxis.Color = PODSData.Settings.SwarmPlotForegroundColor;
    PODSData.Handles.SwarmPlotAxH.XAxis.FontName = PODSData.Settings.DefaultPlotFont;
    PODSData.Handles.SwarmPlotAxH.YAxis.Label.String = "Object Order Factor";
    PODSData.Handles.SwarmPlotAxH.YAxis.Color = PODSData.Settings.SwarmPlotForegroundColor;
    PODSData.Handles.SwarmPlotAxH.YAxis.FontName = PODSData.Settings.DefaultPlotFont;
    PODSData.Handles.SwarmPlotAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.SwarmPlotAxH.Title.Visible = 'Off';

    % set up context menu for swarm plot
    PODSData.Handles.SwarmPlotContextMenu = uicontextmenu(PODSData.Handles.fH);
    % set up context menu options
    PODSData.Handles.SwarmPlotContextMenu_CopyVector = uimenu(PODSData.Handles.SwarmPlotContextMenu,...
        'Text','Copy as vector graphic',...
        'MenuSelectedFcn',@CopySwarmPlotVector);
    PODSData.Handles.SwarmPlotContextMenu_BackgroundColor = uimenu(PODSData.Handles.SwarmPlotContextMenu,...
        'Text','Background color',...
        'MenuSelectedFcn',@SetSwarmPlotBackgroundColor);
    PODSData.Handles.SwarmPlotContextMenu_ForegroundColor = uimenu(PODSData.Handles.SwarmPlotContextMenu,...
        'Text','Foreground color',...
        'MenuSelectedFcn',@SetSwarmPlotForegroundColor);
    PODSData.Handles.SwarmPlotContextMenu_ErrorBarColor = uimenu(PODSData.Handles.SwarmPlotContextMenu,...
        'Text','Error bars color',...
        'MenuSelectedFcn',@SetSwarmPlotErrorBarColor);

    % add the context menu to the axes
    PODSData.Handles.SwarmPlotAxH.ContextMenu = PODSData.Handles.SwarmPlotContextMenu;
    
    %% Axis for scatter plots

    PODSData.Handles.ScatterPlotGrid = uigridlayout(PODSData.Handles.ImgPanel1,[1,1],...
        'Padding',[0 0 0 0],...
        'BackgroundColor',PODSData.Settings.ScatterPlotBackgroundColor,...
        'Tag','ScatterPlotGrid',...
        'Visible','Off',...
        'ColumnWidth',{'1x'},...
        'RowHeight',{'1x'});

    PODSData.Handles.ScatterPlotAxH = uiaxes(PODSData.Handles.ScatterPlotGrid,...
        'Tag','ScatterPlotAxes',...
        'XTick',[],...
        'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0],...
        'NextPlot','Add',...
        'Visible','Off',...
        'Color',PODSData.Settings.ScatterPlotBackgroundColor,...
        'XColor','White',...
        'YColor','White',...
        'HitTest','Off',...
        'FontName',PODSData.Settings.DefaultPlotFont);
    
    disableDefaultInteractivity(PODSData.Handles.ScatterPlotAxH);
    axtoolbar(PODSData.Handles.ScatterPlotAxH,{});

    % set axis title
    PODSData.Handles.ScatterPlotAxH = SetAxisTitle(PODSData.Handles.ScatterPlotAxH,'Object-Average OF vs Local S/B');
    
    PODSData.Handles.ScatterPlotAxH.XAxis.Label.String = "Local S/B";
    PODSData.Handles.ScatterPlotAxH.XAxis.Color = PODSData.Settings.ScatterPlotForegroundColor;
    PODSData.Handles.ScatterPlotAxH.XAxis.Label.FontName = PODSData.Settings.DefaultPlotFont;
    PODSData.Handles.ScatterPlotAxH.YAxis.Label.String = "Object-Average Order Factor";
    PODSData.Handles.ScatterPlotAxH.YAxis.Color = PODSData.Settings.ScatterPlotForegroundColor;
    PODSData.Handles.ScatterPlotAxH.YAxis.Label.FontName = PODSData.Settings.DefaultPlotFont;
    PODSData.Handles.ScatterPlotAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.ScatterPlotAxH.Title.Visible = 'Off';

    % set up context menu for scatter plot
    PODSData.Handles.ScatterPlotContextMenu = uicontextmenu(PODSData.Handles.fH);
    % set up context menu options
    PODSData.Handles.ScatterPlotContextMenu_CopyVector = uimenu(PODSData.Handles.ScatterPlotContextMenu,...
        'Text','Copy as vector graphic',...
        'MenuSelectedFcn',@CopyScatterPlotVector);
    PODSData.Handles.ScatterPlotContextMenu_BackgroundColor = uimenu(PODSData.Handles.ScatterPlotContextMenu,...
        'Text','Background color',...
        'MenuSelectedFcn',@SetScatterPlotBackgroundColor);
    PODSData.Handles.ScatterPlotContextMenu_AxisColor = uimenu(PODSData.Handles.ScatterPlotContextMenu,...
        'Text','Foreground color',...
        'MenuSelectedFcn',@SetScatterPlotForegroundColor);

    % add the context menu to the axes
    PODSData.Handles.ScatterPlotAxH.ContextMenu = PODSData.Handles.ScatterPlotContextMenu;    

    %% MASK

    PODSData.Handles.MaskAxH = uiaxes(PODSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','Mask',...
        'XTick',[],...
        'YTick',[]);
    % save original values to be restored after calling imshow()
    pbarOriginal = PODSData.Handles.MaskAxH.PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.MaskAxH.Tag;
    % place placeholder image on axis
    PODSData.Handles.MaskImgH = imshow(full(emptyimage),'Parent',PODSData.Handles.MaskAxH);
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.MaskImgH,'Tag','MaskImage');
    
    % restore original values after imshow() call
    PODSData.Handles.MaskAxH = restore_axis_defaults(PODSData.Handles.MaskAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    PODSData.Handles.MaskAxH = SetAxisTitle(PODSData.Handles.MaskAxH,'Binary Mask');
    
    PODSData.Handles.MaskAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.MaskAxH.Title.Visible = 'Off';
    PODSData.Handles.MaskAxH.HitTest = 'Off';
    disableDefaultInteractivity(PODSData.Handles.MaskAxH);
    
    PODSData.Handles.MaskImgH.Visible = 'Off';
    PODSData.Handles.MaskImgH.HitTest = 'Off';
    
    %% Azimuth
    % azimuth image axes
    PODSData.Handles.AzimuthAxH = uiaxes(PODSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','Azimuth',...
        'XTick',[],...
        'YTick',[],...
        'Color','Black');
    % save original values to be restored after calling imshow()
    pbarOriginal = PODSData.Handles.AzimuthAxH.PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.AzimuthAxH.Tag;    
    % place placeholder image on axis
    PODSData.Handles.AzimuthImgH = imshow(full(emptyimage),'Parent',PODSData.Handles.AzimuthAxH);
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.AzimuthImgH,'Tag','AzimuthImage');
    % restore original values after imshow() call
    PODSData.Handles.AzimuthAxH = restore_axis_defaults(PODSData.Handles.AzimuthAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    % set axis title
    PODSData.Handles.AzimuthAxH = SetAxisTitle(PODSData.Handles.AzimuthAxH,'Pixel-by-pixel Azimuth');
    % change active axis so we can make custom colorbar/colormap
    %axes(PODSData.Handles.AzimuthAxH)
    tempmap = hsv;
    
    PODSData.Handles.AzimuthAxH.Colormap = vertcat(tempmap,tempmap);
    % custom colormap/colorbar
    PODSData.Handles.PhaseBarAxH = phasebarmod('rad','Location','se','axes',PODSData.Handles.AzimuthAxH);
    PODSData.Handles.PhaseBarAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.PhaseBarAxH.HitTest = 'Off';
    PODSData.Handles.PhaseBarAxH.PickableParts = 'None';
    PODSData.Handles.PhaseBarComponents = PODSData.Handles.PhaseBarAxH.Children;
    set(PODSData.Handles.PhaseBarComponents,'Visible','Off');
    PODSData.Handles.PhaseBarAxH.Colormap = vertcat(tempmap,tempmap);

    PODSData.Handles.AzimuthAxH.YDir = 'Reverse';
    PODSData.Handles.AzimuthAxH.Visible = 'Off';
    PODSData.Handles.AzimuthAxH.Title.Visible = 'Off';
    PODSData.Handles.AzimuthAxH.Title.Color = 'White';    
    PODSData.Handles.AzimuthAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.AzimuthAxH.HitTest = 'Off';
    disableDefaultInteractivity(PODSData.Handles.AzimuthAxH);

    PODSData.Handles.AzimuthImgH.Visible = 'Off';
    PODSData.Handles.AzimuthImgH.HitTest = 'Off';

%% CHECKPOINT

disp('Setting up object image axes...')
    
    %% Object FFCIntensity Image
    
    PODSData.Handles.ObjectPolFFCAxH = uiaxes(PODSData.Handles.SmallPanels(1,1),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectPolFFC',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = PODSData.Handles.ObjectPolFFCAxH.PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.ObjectPolFFCAxH.Tag;
    % place placeholder image on axis
    PODSData.Handles.ObjectPolFFCImgH = imshow(full(emptyimage),'Parent',PODSData.Handles.ObjectPolFFCAxH);
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.ObjectPolFFCImgH,'Tag','ObjectPolFFCImage');
    % restore original values after imshow() call
    PODSData.Handles.ObjectPolFFCAxH = restore_axis_defaults(PODSData.Handles.ObjectPolFFCAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    PODSData.Handles.ObjectPolFFCAxH = SetAxisTitle(PODSData.Handles.ObjectPolFFCAxH,'Flat-Field-Corrected Average Intensity');
    PODSData.Handles.ObjectPolFFCAxH.Colormap = PODSData.Settings.IntensityColormap;
    PODSData.Handles.ObjectPolFFCAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.ObjectPolFFCAxH.Title.Visible = 'Off';
    PODSData.Handles.ObjectPolFFCAxH.HitTest = 'Off';
    disableDefaultInteractivity(PODSData.Handles.ObjectPolFFCAxH);
    
    PODSData.Handles.ObjectPolFFCImgH.Visible = 'Off';
    PODSData.Handles.ObjectPolFFCImgH.HitTest = 'Off';
    
    %% Object Binary Image
    
    PODSData.Handles.ObjectMaskAxH = uiaxes(PODSData.Handles.SmallPanels(1,2),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectMask',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = PODSData.Handles.ObjectMaskAxH.PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.ObjectMaskAxH.Tag;
    % place placeholder image on axis
    PODSData.Handles.ObjectMaskImgH = imshow(full(emptyimage),'Parent',PODSData.Handles.ObjectMaskAxH);
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.ObjectMaskImgH,'Tag','ObjectMaskImage');
    % restore original values after imshow() call
    PODSData.Handles.ObjectMaskAxH = restore_axis_defaults(PODSData.Handles.ObjectMaskAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    PODSData.Handles.ObjectMaskAxH = SetAxisTitle(PODSData.Handles.ObjectMaskAxH,'Object Binary Image');
    PODSData.Handles.ObjectMaskAxH.Title.Visible = 'Off';
    PODSData.Handles.ObjectMaskAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.ObjectMaskAxH.HitTest = 'Off';
    disableDefaultInteractivity(PODSData.Handles.ObjectMaskAxH);
    
    PODSData.Handles.ObjectMaskImgH.Visible = 'Off';
    PODSData.Handles.ObjectMaskImgH.HitTest = 'Off';
    
    %% Object Azimuth Overlay

    PODSData.Handles.ObjectAzimuthOverlayAxH = uiaxes(PODSData.Handles.SmallPanels(2,2),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectAzimuthOverlay',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = PODSData.Handles.ObjectAzimuthOverlayAxH.PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.ObjectAzimuthOverlayAxH.Tag;
    % place placeholder image on axis
    PODSData.Handles.ObjectAzimuthOverlayImgH = imshow(full(emptyimage),'Parent',PODSData.Handles.ObjectAzimuthOverlayAxH);
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.ObjectAzimuthOverlayImgH,'Tag','ObjectAzimuthOverlay');
    % restore original values after imshow() call
    PODSData.Handles.ObjectAzimuthOverlayAxH = restore_axis_defaults(PODSData.Handles.ObjectAzimuthOverlayAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    PODSData.Handles.ObjectAzimuthOverlayAxH = SetAxisTitle(PODSData.Handles.ObjectAzimuthOverlayAxH,'Object Azimuth Overlay');
    
    PODSData.Handles.ObjectAzimuthOverlayAxH.Colormap = PODSData.Settings.IntensityColormap;
    
    PODSData.Handles.ObjectAzimuthOverlayAxH.Title.Visible = 'Off';
    PODSData.Handles.ObjectAzimuthOverlayAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.ObjectAzimuthOverlayAxH.HitTest = 'Off';
    disableDefaultInteractivity(PODSData.Handles.ObjectAzimuthOverlayAxH);
    
    PODSData.Handles.ObjectAzimuthOverlayImgH.Visible = 'Off';
    PODSData.Handles.ObjectAzimuthOverlayImgH.HitTest = 'Off';

    %% Object OF Image
    
    PODSData.Handles.ObjectOFAxH = uiaxes(PODSData.Handles.SmallPanels(2,1),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectOF',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = PODSData.Handles.ObjectOFAxH.PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.ObjectOFAxH.Tag;
    % place placeholder image on axis
    PODSData.Handles.ObjectOFImgH = imshow(full(emptyimage),'Parent',PODSData.Handles.ObjectOFAxH);
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.ObjectOFImgH,'Tag','ObjectOFImage');
    % restore original values after imshow() call
    PODSData.Handles.ObjectOFAxH = restore_axis_defaults(PODSData.Handles.ObjectOFAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    PODSData.Handles.ObjectOFAxH = SetAxisTitle(PODSData.Handles.ObjectOFAxH,'Object OF Image');
    
    PODSData.Handles.ObjectOFAxH.Colormap = PODSData.Settings.OrderFactorColormap;
    
    PODSData.Handles.ObjectOFAxH.Title.Visible = 'Off';
    PODSData.Handles.ObjectOFAxH.Toolbar.Visible = 'Off';
    PODSData.Handles.ObjectOFAxH.HitTest = 'Off';
    disableDefaultInteractivity(PODSData.Handles.ObjectOFAxH);
    
    PODSData.Handles.ObjectOFImgH.Visible = 'Off';
    PODSData.Handles.ObjectOFImgH.HitTest = 'Off';
    
    %% Object Intensity Fit Plots
    
    PODSData.Handles.ObjectIntensityPlotAxH = uiaxes(PODSData.Handles.ImgPanel2,...
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
        'FontName',PODSData.Settings.DefaultPlotFont);
    
    PODSData.Handles.ObjectIntensityPlotAxH.Title.String = 'Pixel-normalized intensitites fit to sinusoids';
    PODSData.Handles.ObjectIntensityPlotAxH.Title.Color = 'White';
    PODSData.Handles.ObjectIntensityPlotAxH.Title.FontName = PODSData.Settings.DefaultPlotFont;
    PODSData.Handles.ObjectIntensityPlotAxH.Title.HorizontalAlignment = 'Center';
    PODSData.Handles.ObjectIntensityPlotAxH.Title.VerticalAlignment = 'Top';
    
    PODSData.Handles.ObjectIntensityPlotAxH.XAxis.Label.String = "Excitation polarization (°)";
    PODSData.Handles.ObjectIntensityPlotAxH.XAxis.Label.Color = [1 1 0];
    PODSData.Handles.ObjectIntensityPlotAxH.XAxis.Label.FontName = PODSData.Settings.DefaultPlotFont;
    PODSData.Handles.ObjectIntensityPlotAxH.YAxis.Label.String = "Normalized emission intensity (A.U.)";
    PODSData.Handles.ObjectIntensityPlotAxH.YAxis.Label.Color = [1 1 0];
    PODSData.Handles.ObjectIntensityPlotAxH.YAxis.Label.FontName = PODSData.Settings.DefaultPlotFont;
    
    disableDefaultInteractivity(PODSData.Handles.ObjectIntensityPlotAxH);
    
    %% Object Stack-Normalized Intensity Stack
    
    PODSData.Handles.ObjectNormIntStackAxH = uiaxes(PODSData.Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0.75 1 0.25],...
        'Tag','ObjectNormIntStack',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = PODSData.Handles.ObjectNormIntStackAxH.PlotBoxAspectRatio;
    tagOriginal = PODSData.Handles.ObjectNormIntStackAxH.Tag;
    % place placeholder image on axis
    emptysz = size(emptyimage);
    PODSData.Handles.ObjectNormIntStackImgH = imshow(full(emptyimage(1:emptysz(1)*0.25,1:end)),'Parent',PODSData.Handles.ObjectNormIntStackAxH);
    % set a tag so our callback functions can find the image
    set(PODSData.Handles.ObjectNormIntStackImgH,'Tag','ObjectNormIntStack');
    % restore original values after imshow() call
    PODSData.Handles.ObjectNormIntStackAxH = restore_axis_defaults(PODSData.Handles.ObjectNormIntStackAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    PODSData.Handles.ObjectNormIntStackAxH = SetAxisTitle(PODSData.Handles.ObjectNormIntStackAxH,'Stack-Normalized Object Intensity');
    PODSData.Handles.ObjectNormIntStackAxH.Colormap = PODSData.Settings.IntensityColormap;
    PODSData.Handles.ObjectNormIntStackAxH.Title.Visible = 'Off';
    PODSData.Handles.ObjectNormIntStackAxH.Toolbar.Visible = 'Off';
    disableDefaultInteractivity(PODSData.Handles.ObjectNormIntStackAxH);
    
    PODSData.Handles.ObjectNormIntStackImgH.Visible = 'Off';    
    PODSData.Handles.ObjectNormIntStackImgH.HitTest = 'Off';
    
%% Turning on important containers and adjusting some components for proper initial display

set(PODSData.Handles.AppInfoSelectorPanel,'Visible','On');
set(PODSData.Handles.AppInfoSelector,'Visible','On');

set(PODSData.Handles.ProjectSummaryTableGrid,'Visible','On');

set(PODSData.Handles.AppInfoPanel,'Visible','On');
set(PODSData.Handles.SettingsPanel,'Visible','On');

set(PODSData.Handles.ImageOperationsPanel,'Visible','On');
set(PODSData.Handles.ThreshAxH,'Visible','On');
set(PODSData.Handles.ImageOperationsSelectorPanel,'Visible','On');
set(PODSData.Handles.ImageOperationsSelector,'Visible','On');

set(PODSData.Handles.LogPanel,'Visible','On');
set(PODSData.Handles.LogWindow,'Visible','On');

set(PODSData.Handles.SmallPanels,'Visible','On');

set(PODSData.Handles.GroupSelectorPanel,'Visible','On');
set(PODSData.Handles.ImageSelectorPanel,'Visible','On');
set(PODSData.Handles.ObjectSelectorPanel,'Visible','On');
set(PODSData.Handles.ObjectSelector,'Visible','On');

% set uipanel linewidth
set(findobj(PODSData.Handles.fH,'type','uipanel'),'BorderWidth',1);

% initialize some graphics placeholder objects
PODSData.Handles.LineScanROI = gobjects(1,1);
PODSData.Handles.LineScanFig = gobjects(1,1);
PODSData.Handles.LineScanPlot = gobjects(1,1);
PODSData.Handles.ObjectBoxes = gobjects(1,1);
PODSData.Handles.SelectedObjectBoxes = gobjects(1,1);
PODSData.Handles.AzimuthLines = gobjects(1,1);
PODSData.Handles.ObjectAzimuthLines = gobjects(1,1);
PODSData.Handles.ObjectMidlinePlot = gobjects(1,1);
PODSData.Handles.ObjectBoundaryPlot = gobjects(1,1);


% add PODSData to the gui using guidata
% (this is how we will retain access to the data across different functions)
guidata(PODSData.Handles.fH,PODSData)
% set optimum font size for display
fontsize(PODSData.Handles.fH,PODSData.Settings.FontSize,'pixels');
% update GUI display colors
UpdateGUITheme();
% update summary display
UpdateSummaryDisplay(PODSData.Handles.fH);

% delete the splash screen and clear out java components so we don't run into issues when saving
Splash.dispose();
clear Splash label icon SplashImage SplashScreenIcon

disp('Opening...')

% some functionality will work better if the MATLAB desktop window is minimized
% uses the com.mathworks package, which will be removed in the future
try
    minimizeMLDesktop();
catch
    warning('Could not minimize MATLAB desktop window');
end

% set figure to visible to draw containers
PODSData.Handles.fH.Visible = 'On';

drawnow
pause(0.5)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% NESTED FUNCTIONS - VARIOUS GUI CALLBACKS AND ACCESSORY FUNCTIONS

%% Context menu callbacks for swarm plot

    function CopySwarmPlotVector(source,~)
        UpdateLog3(source,'Copying...','append');
        copygraphics(PODSData.Handles.SwarmPlotAxH,'ContentType','vector','BackgroundColor',PODSData.Settings.SwarmPlotBackgroundColor);
        UpdateLog3(source,'Swarm plot vector graphic copied to clipboard','append');
    end

    function SetSwarmPlotBackgroundColor(~,~)
        PODSData.Settings.SwarmPlotBackgroundColor = uisetcolor();
        figure(PODSData.Handles.fH);
        PODSData.Handles.SwarmPlotAxH.Color = PODSData.Settings.SwarmPlotBackgroundColor;
        PODSData.Handles.SwarmPlotGrid.BackgroundColor = PODSData.Settings.SwarmPlotBackgroundColor;
    end

    function SetSwarmPlotForegroundColor(~,~)
        PODSData.Settings.SwarmPlotForegroundColor = uisetcolor();
        figure(PODSData.Handles.fH);
        PODSData.Handles.SwarmPlotAxH.XAxis.Color = PODSData.Settings.SwarmPlotForegroundColor;
        PODSData.Handles.SwarmPlotAxH.YAxis.Color = PODSData.Settings.SwarmPlotForegroundColor;
    end

    function SetSwarmPlotErrorBarColor(source,~)
        PODSData.Settings.SwarmPlotErrorBarColor = uisetcolor();
        figure(PODSData.Handles.fH);
        UpdateImages(source);
    end

%% callback functions for scatter plot

    function CopyScatterPlotVector(source,~)
        UpdateLog3(source,'Copying...','append');
        copygraphics(PODSData.Handles.ScatterPlotAxH,'ContentType','vector','BackgroundColor',PODSData.Settings.ScatterPlotBackgroundColor);
        UpdateLog3(source,'Scatter plot vector graphic copied to clipboard','append');
    end

    function SetScatterPlotBackgroundColor(~,~)
        PODSData.Settings.ScatterPlotBackgroundColor = uisetcolor();
        figure(PODSData.Handles.fH);
        PODSData.Handles.ScatterPlotAxH.Color = PODSData.Settings.ScatterPlotBackgroundColor;
        PODSData.Handles.ScatterPlotGrid.BackgroundColor = PODSData.Settings.ScatterPlotBackgroundColor;
    end

    function SetScatterPlotForegroundColor(~,~)
        PODSData.Settings.ScatterPlotForegroundColor = uisetcolor();
        figure(PODSData.Handles.fH);
        PODSData.Handles.ScatterPlotAxH.XAxis.Color = PODSData.Settings.ScatterPlotForegroundColor;
        PODSData.Handles.ScatterPlotAxH.YAxis.Color = PODSData.Settings.ScatterPlotForegroundColor;
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
        PODSData.DeleteGroup(cGroup)
        UpdateImageTree(source);
        UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});        
        UpdateLog3(fH,'Done.','append');
    end

    function AddNewGroup(source,~)
        PODSData.AddNewGroup(['Untitled Group ',num2str(PODSData.nGroups+1)]);
        NewGroup = PODSData.Group(end);
        newNode = uitreenode(PODSData.Handles.GroupTree,...
            'Text',NewGroup.GroupName,...
            'NodeData',NewGroup,...
            'Icon',makeRGBColorSquare(NewGroup.Color,5));
        newNode.ContextMenu = PODSData.Handles.GroupContextMenu;
        UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});
    end

    function EditGroupColor(source,~,fH)
        SelectedNode = fH.CurrentObject;
        cGroup = SelectedNode.NodeData;
        cGroup.Color = uisetcolor();
        figure(fH);
        SelectedNode.Icon = makeRGBColorSquare(cGroup.Color,1);
        if strcmp(PODSData.Settings.CurrentTab,'Plots')
            UpdateImages(source);
        end
    end

%% Image uitree callbacks

    function DeleteImage(source,~,fH)

        SelectedNodes = PODSData.Handles.ImageTree.SelectedNodes;
        %SelectedImages = deal([SelectedNodes(:).NodeData]);
        UpdateLog3(fH,'Deleting images...','append');
        delete(SelectedNodes)
        cGroup = PODSData.CurrentGroup;
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
        PODSData.Handles.([event.PreviousValue,'Grid']).Visible = 'Off';
        PODSData.Handles.([event.Value,'Grid']).Visible = 'On';
        ncols = length(PODSData.Handles.([event.Value,'Grid']).ColumnWidth);
        source.Parent = PODSData.Handles.([event.Value,'Grid']);
        if ncols > 1
            source.Layout.Column = [1 ncols];
        else
            source.Layout.Column = 1;
        end
    end

%% Azimuth display settings

    function ApplyAzimuthSettings(source,~)
        PODSData.Settings.AzimuthDisplaySettings.LineAlpha = PODSData.Handles.AzimuthLineAlphaDropdown.Value;
        PODSData.Settings.AzimuthDisplaySettings.LineWidth = PODSData.Handles.AzimuthLineWidthDropdown.Value;
        PODSData.Settings.AzimuthDisplaySettings.LineScale = str2double(PODSData.Handles.AzimuthLineScaleEditfield.Value);
        PODSData.Settings.AzimuthDisplaySettings.ScaleDownFactor = PODSData.Handles.AzimuthLineScaleDownDropdown.Value;
        PODSData.Settings.AzimuthDisplaySettings.ColorMode = PODSData.Handles.AzimuthColorModeDropdown.Value;
        UpdateImages(source);
    end

    function SaveAzimuthDisplaySettings(source,~)
        % saves the currently selected colormaps settings to a .mat file
        % which will be loaded in future sessions by PODSSettings
        UpdateLog3(source,'Saving azimuth display settings...','append');
        AzimuthDisplaySettings = PODSData.Settings.AzimuthDisplaySettings;
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

%% SwarmPlot settings

    function SwarmPlotYVariableChanged(source,~)
        PODSData.Settings.SwarmPlotSettings.YVariable = source.Value;
        UpdateImages(source);
    end

    function SwarmPlotGroupingTypeChanged(source,~)
        PODSData.Settings.SwarmPlotSettings.GroupingType = source.Value;
        UpdateImages(source);
    end

    function SwarmPlotColorModeChanged(source,~)
        PODSData.Settings.SwarmPlotSettings.ColorMode = source.Value;
        UpdateImages(source);
    end

    function SaveSwarmPlotSettings(source,~)
        % saves the currently selected SwarmPlot settings to a .mat file
        % which will be loaded in future sessions by PODSSettings
        UpdateLog3(source,'Saving swarmplot settings...','append');
        SwarmPlotSettings = PODSData.Settings.SwarmPlotSettings;
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

%% Scatterplot settings

    function ScatterPlotVariablesChanged(source,~)
        PODSData.Settings.ScatterPlotSettings.(source.Tag) = source.Value;
        if strcmp(PODSData.Settings.CurrentTab,'Plots')
            UpdateImages(source);
        end
    end

    function SaveScatterPlotSettings(source,~)
        % saves the currently selected colormaps settings to a .mat file
        % which will be loaded in future sessions by PODSSettings
        UpdateLog3(source,'Saving scatterplot settings...','append');
        ScatterPlotSettings = PODSData.Settings.ScatterPlotSettings;
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
        PODSData.Handles.ColormapsSelector.Value = PODSData.Settings.ColormapsSettings.(ImageTypeName){2};
        PODSData.Handles.ExampleColormapAx.Colormap = PODSData.Settings.ColormapsSettings.(ImageTypeName){3};
    end

    function ColormapSelectionChanged(source,~)
        ImageTypeName = PODSData.Handles.ColormapsImageTypeSelector.Value;
        PODSData.Settings.ColormapsSettings.(ImageTypeName){2} = source.Value;
        PODSData.Settings.ColormapsSettings.(ImageTypeName){3} = PODSData.Settings.Colormaps.(source.Value);
        PODSData.Handles.ExampleColormapAx.Colormap = PODSData.Settings.Colormaps.(source.Value);
        UpdateColormaps(ImageTypeName);
    end

    function UpdateColormaps(ImageTypeName)

        switch ImageTypeName

            case 'Intensity'
                IntensityMap = PODSData.Settings.ColormapsSettings.(ImageTypeName){3};
                PODSData.Handles.AverageIntensityAxH.Colormap = IntensityMap;
                [PODSData.Handles.FFCAxH.Colormap] = deal(IntensityMap);
                [PODSData.Handles.RawIntensityAxH.Colormap] = deal(IntensityMap);
                [PODSData.Handles.PolFFCAxH.Colormap] = deal(IntensityMap);
                PODSData.Handles.ObjectPolFFCAxH.Colormap = IntensityMap;
                PODSData.Handles.ObjectNormIntStackAxH.Colormap = IntensityMap;
                PODSData.Handles.ObjectAzimuthOverlayAxH.Colormap = IntensityMap;
                if ~isempty(PODSData.CurrentImage)
                    if PODSData.CurrentImage(1).ReferenceImageLoaded && PODSData.Handles.ShowReferenceImageAverageIntensity.Value
                        UpdateCompositeRGB();
                    end
                end
            case 'OrderFactor'
                OrderFactorMap = PODSData.Settings.ColormapsSettings.(ImageTypeName){3};
                PODSData.Handles.OrderFactorAxH.Colormap = OrderFactorMap;
                PODSData.Handles.ObjectOFAxH.Colormap = OrderFactorMap;
                PODSData.Handles.ObjectOFContourAxH.Colormap = OrderFactorMap;
                if (~isempty(PODSData.CurrentImage) && ...
                       PODSData.Handles.ShowAsOverlayOrderFactor.Value && ...
                       strcmp(PODSData.Settings.CurrentTab,'Order Factor'))
                    UpdateImages(PODSData.Handles.fH);
                end
            case 'Reference'
                if ~isempty(PODSData.CurrentImage)
                    if PODSData.CurrentImage(1).ReferenceImageLoaded && PODSData.Handles.ShowReferenceImageAverageIntensity.Value
                        UpdateCompositeRGB();
                    end
                end
            case 'Azimuth'
                AzimuthMap = PODSData.Settings.ColormapsSettings.(ImageTypeName){3};
%                 % test below (making uniform cyclic colormap)
%                  AzimuthMap = MakeCircularColormap(AzimuthMap);
%                 % end test
                PODSData.Handles.AzimuthAxH.Colormap = vertcat(AzimuthMap,AzimuthMap);
                PODSData.Handles.PhaseBarAxH.Colormap = vertcat(AzimuthMap,AzimuthMap);
                if strcmp(PODSData.Settings.CurrentTab,'Azimuth') && ...
                        strcmp(PODSData.Settings.AzimuthColorMode,'Direction')
                    UpdateImages(PODSData.Handles.fH);
                end
        end

    end

    function SaveColormapsSettings(source,~)
        % saves the currently selected colormaps settings to a .mat file
        % which will be loaded in future sessions by PODSSettings
        UpdateLog3(source,'Saving colormaps settings...','append');
        ColormapsSettings = PODSData.Settings.ColormapsSettings;
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
        SelectedNodes = PODSData.Handles.LabelTree.SelectedNodes;
        % if no nodes in the tree are truly 'selected', get the right-clicked node instead
        if numel(SelectedNodes)==0
            SelectedNodes = fH.CurrentObject;
        end
        % handle possible error (we always need at least one label)
        if PODSData.Settings.nLabels==1 || PODSData.Settings.nLabels == numel(SelectedNodes)
            uialert(PODSData.Handles.fH,'There must be at least one object label','Error');
            return
        end

        % loop through and delete the labels corresponding to each node
        for NodeIdx = 1:numel(SelectedNodes)
            % get the next label
            cLabel = SelectedNodes(NodeIdx).NodeData;
            % update log to indicate progress for each label
            UpdateLog3(fH,['Deleting [Label:',cLabel.Name,']...'],'append');
            % before deleting the label, we need to check for any objects that would end up unlabeled
            ObjectsWithOldLabel = PODSData.getObjectsByLabel(cLabel);
            % delete the old label
            PODSData.Settings.DeleteObjectLabel(cLabel);
            % add new label to the now unlabeled objects, if necessary
            if ~isempty(ObjectsWithOldLabel)
                UpdateLog3(fH,[num2str(numel(ObjectsWithOldLabel)),' objects affected. Reassigning default label...'],'append');
                % empty label object
                DefaultLabel = PODSLabel.empty();
                % chack if the default label exists
                for LabelIdx = 1:numel(PODSData.Settings.ObjectLabels)
                    Label = PODSData.Settings.ObjectLabels(LabelIdx);
                    if strcmp(Label.Name,'Default')
                        DefaultLabel = Label;
                        break
                    end
                end
                % if default label not found...
                if isempty(DefaultLabel)
                    % create a new default label
                    PODSData.Settings.AddNewObjectLabel(...
                        'Default',...
                        distinguishable_colors(1,PODSData.Settings.LabelColors));
                    DefaultLabel = PODSData.Settings.ObjectLabels(end);
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
        SelectedNodes = PODSData.Handles.LabelTree.SelectedNodes;
        % if no nodes in the tree are truly 'selected', get the right-clicked node instead
        if numel(SelectedNodes)==0
            SelectedNodes = fH.CurrentObject;
        end
        % handle possible error (we always need at least one label)
        if PODSData.Settings.nLabels==1 || PODSData.Settings.nLabels == numel(SelectedNodes)
            uialert(PODSData.Handles.fH,'There must be at least one object label','Error');
            return
        end

        % loop through and delete the labels corresponding to each node
        for NodeIdx = 1:numel(SelectedNodes)
            % get the label to delete
            cLabel = SelectedNodes(NodeIdx).NodeData;
            % update log to indicate progress for each label
            UpdateLog3(fH,['Deleting [Label:',cLabel.Name,']...'],'append');
            % before deleting the label, get all objects with this label to indicate how will be deleted
            ObjectsWithOldLabel = PODSData.getObjectsByLabel(cLabel);
            % if any objects found, delete them and update the log
            if ~isempty(ObjectsWithOldLabel)
                UpdateLog3(fH,['Deleting ',num2str(numel(ObjectsWithOldLabel)),' objects...'],'append');
                PODSData.DeleteObjectsByLabel(cLabel);
            else
                UpdateLog3(fH,['No objects deleted.'],'append');
            end
            % delete the label
            PODSData.Settings.DeleteObjectLabel(cLabel);
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
        PODSData.LabelSelectedObjects(cLabel);
        % update display
        UpdateImages(source);
        UpdateSummaryDisplay(source,{'Object'});
        UpdateLog3(fH,'Done.','append');
    end

    function SelectLabeledObjects(source,~,fH)
        % get the selected nodes
        SelectedNodes = PODSData.Handles.LabelTree.SelectedNodes;
        % if no nodes in the tree are truly 'selected', get the right-clicked node instead
        if numel(SelectedNodes)==0
            SelectedNodes = fH.CurrentObject;
        end

        for NodeIdx = 1:numel(SelectedNodes)
            % get the label associated with the node
            cLabel = SelectedNodes(NodeIdx).NodeData;
            % select all objects with the label
            PODSData.SelectObjectsByLabel(cLabel);
        end
        % update display
        UpdateImages(source);
        UpdateSummaryDisplay(source,{'Object'});
        UpdateLog3(fH,'Done.','append');
    end

    function MergeLabels(source,~,fH)
        % get the selected nodes
        SelectedNodes = PODSData.Handles.LabelTree.SelectedNodes;
        % get the node that was right-clicked
        ClickedNode = fH.CurrentObject;
        % deal with some potential errors
        if ~ismember(ClickedNode,SelectedNodes)
            uialert(PODSData.Handles.fH,'You can only merge labels into a selected label. Select the label and try again.','Error');
            return
        end
        if ~(numel(SelectedNodes)>=2)
            uialert(PODSData.Handles.fH,'Merging object labels requires at least 2 selected labels.','Error');
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
                PODSData.SwapObjectLabels(cLabel,LabelToMergeInto);
                % and delete the old label
                PODSData.Settings.DeleteObjectLabel(cLabel);
            end
        end
        UpdateLabelTree(source);
        UpdateImages(source);
        UpdateLog3(fH,'Done.','append');
    end

    function AddNewLabel(~,~)
        PODSData.Settings.AddNewObjectLabel([],[]);
        NewLabel = PODSData.Settings.ObjectLabels(end);
        newNode = uitreenode(PODSData.Handles.LabelTree,...
            'Text',NewLabel.Name,...
            'NodeData',NewLabel,...
            'Icon',makeRGBColorSquare(NewLabel.Color,5));
        newNode.ContextMenu = PODSData.Handles.LabelContextMenu;
    end

    function EditLabelColor(source,~,fH)
        SelectedNode = fH.CurrentObject;
        cLabel = SelectedNode.NodeData;
        cLabel.Color = uisetcolor();
        figure(fH);
        SelectedNode.Icon = makeRGBColorSquare(cLabel.Color,1);

        UpdateImages(source);
%         if strcmp(PODSData.Settings.CurrentTab,'Plots')
%             UpdateImages(source);
%         end
    end

%% Callbacks controlling dynamic resizing of GUI containers

    function ResetContainerSizes(source,~)
        disp('Figure Window Size Changed...');
        SmallWidth = round((source.InnerPosition(3)*0.38)/2);
        % update grid size to maatch new image sizes
        PODSData.Handles.MainGrid.RowHeight = {'1x',SmallWidth,SmallWidth,'1x'};
        PODSData.Handles.MainGrid.ColumnWidth = {'1x',SmallWidth,SmallWidth,SmallWidth,SmallWidth};

        % testing dynamic font size update
        %fontsize(PODSData.Handles.fH,round(PODSData.Handles.fH.OuterPosition(4)*.0125),'pixels');

        %drawnow limitrate
        drawnow
    end

%% Callbacks for interactive thresholding
% Set figure callbacks WindowButtonMotionFcn and WindowButtonUpFcn
    function StartUserThresholding(~,~)
        PODSData.Handles.fH.WindowButtonMotionFcn = @MoveThresholdLine;
        PODSData.Handles.fH.WindowButtonUpFcn = @StopMovingAndSetThresholdLine;
    end
% Update display while thresh line is moving
    function MoveThresholdLine(source,~)
        PODSData.Handles.CurrentThresholdLine.Value = round(PODSData.Handles.ThreshAxH.CurrentPoint(1,1),4);
        PODSData.Handles.CurrentThresholdLine.Label = {[PODSData.CurrentImage(1).ThreshStatisticName,' = ',num2str(PODSData.Handles.CurrentThresholdLine.Value)]};
        ThresholdLineMoving(source,PODSData.Handles.CurrentThresholdLine.Value);
        drawnow
    end
% Set final thresh position and restore callbacks
    function StopMovingAndSetThresholdLine(source,~)
        PODSData.Handles.CurrentThresholdLine.Value = round(PODSData.Handles.ThreshAxH.CurrentPoint(1,1),4);
        PODSData.Handles.CurrentThresholdLine.Label = {[PODSData.CurrentImage(1).ThreshStatisticName,' = ',num2str(PODSData.Handles.CurrentThresholdLine.Value)]};
        PODSData.Handles.fH.WindowButtonMotionFcn = '';
        PODSData.Handles.fH.WindowButtonUpFcn = '';
        ThresholdLineMoved(source,PODSData.Handles.CurrentThresholdLine.Value);
        drawnow
    end

%% Callbacks for intensity display scaling

    function AdjustPrimaryChannelIntensity(source,~)

        PODSData.CurrentImage(1).PrimaryIntensityDisplayLimits = source.Value;

        if PODSData.CurrentImage(1).ReferenceImageLoaded && PODSData.Handles.ShowReferenceImageAverageIntensity.Value
            UpdateCompositeRGB();
        else
            PODSData.Handles.AverageIntensityAxH.CLim = source.Value;
        end

        drawnow limitrate

    end

    function AdjustReferenceChannelIntensity(source,~)
        PODSData.CurrentImage(1).ReferenceIntensityDisplayLimits = source.Value;
        if PODSData.CurrentImage(1).ReferenceImageLoaded && PODSData.Handles.ShowReferenceImageAverageIntensity.Value
            UpdateCompositeRGB();
        end

        drawnow limitrate

    end

    function UpdateCompositeRGB()
        PODSData.Handles.AverageIntensityImgH.CData = ...
            CompositeRGB(Scale0To1(PODSData.CurrentImage(1).I),...
            PODSData.Settings.IntensityColormap,...
            PODSData.CurrentImage(1).PrimaryIntensityDisplayLimits,...
            Scale0To1(PODSData.CurrentImage(1).ReferenceImage),...
            PODSData.Settings.ReferenceColormap,...
            PODSData.CurrentImage(1).ReferenceIntensityDisplayLimits);
        PODSData.Handles.AverageIntensityAxH.CLim = [0 255];
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
                addRectangularROIToolbarBtn;
                addLassoROIToolbarBtn;
            case 'OrderFactor'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
                addLineScanToolbarBtn;
                addExportAxesToolbarBtn;
                addShowAsOverlayToolbarBtn;
                addShowColorbarToolbarBtn;
            case 'AverageIntensity'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
                addShowSelectionToolbarBtn;
                addRectangularROIToolbarBtn;
                addLassoROIToolbarBtn;
                addShowReferenceImageToolbarBtn;
                addLineScanToolbarBtn;
                addExportAxesToolbarBtn;
            case 'Azimuth'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
                addShowAsOverlayToolbarBtn;
                addShowColorbarToolbarBtn;
                addExportAxesToolbarBtn;
        end
        
        function addZoomToCursorToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MagnifyingGlassBlackAndYellow.png';
            btn.ValueChangedFcn = @ZoomToCursor;
            btn.Tag = ['ZoomToCursor',axH.Tag];
            btn.Tooltip = 'Zoom to cursor';
            PODSData.Handles.(btn.Tag) = btn;            
        end
        
        function addApplyMaskToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MaskIcon.png';
            btn.ValueChangedFcn = @tbApplyMaskStateChanged;
            btn.Tag = ['ApplyMask',axH.Tag];
            btn.Tooltip = 'Apply mask';
            PODSData.Handles.(btn.Tag) = btn;
        end
        
        function addShowSelectionToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ShowSelectionIcon.png';
            btn.ValueChangedFcn = @tbShowSelectionStateChanged;
            btn.Tag = ['ShowSelection',axH.Tag];
            btn.Tooltip = 'Show objects';
            PODSData.Handles.(btn.Tag) = btn;
        end
        
        function addRectangularROIToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'RectangularROIIcon.png';
            btn.ButtonPushedFcn = @tbRectangularROI;
            btn.Tag = ['RectangularROI',axH.Tag];
            btn.Tooltip = 'Select objects (rectangle)';
            PODSData.Handles.(btn.Tag) = btn;
        end

        function addLassoROIToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'LassoToolIcon.png';
            btn.ButtonPushedFcn = @tbLassoROI;
            btn.Tag = ['LassoROI',axH.Tag];
            btn.Tooltip = 'Select objects (lasso)';
            PODSData.Handles.(btn.Tag) = btn;
        end        
        
        function addShowReferenceImageToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ShowReferenceImageIcon.png';
            btn.ValueChangedFcn = @tbShowReferenceImageStateChanged;
            btn.Tag = ['ShowReferenceImage',axH.Tag];
            btn.Tooltip = 'Show reference image';
            PODSData.Handles.(btn.Tag) = btn;
        end

        function addShowAsOverlayToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ShowReferenceImageIcon.png';
            btn.ValueChangedFcn = @tbShowAsOverlayStateChanged;
            btn.Tag = ['ShowAsOverlay',axH.Tag];
            btn.Tooltip = 'Intensity overlay';
            PODSData.Handles.(btn.Tag) = btn;
        end
        
        function addLineScanToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'LineScanIcon.png';
            btn.ButtonPushedFcn = @tbLineScan;
            btn.Tag = ['LineScan',axH.Tag];
            btn.Tooltip = 'Integrated linescan';
            PODSData.Handles.(btn.Tag) = btn;
        end

        function addExportAxesToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'ExportAxesIcon.png';
            btn.ButtonPushedFcn = @tbExportAxes;
            btn.Tag = ['ExportAxes',axH.Tag];
            btn.Tooltip = 'Export image';
            PODSData.Handles.(btn.Tag) = btn;
        end

        function addShowColorbarToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ChangeColorbarVisibilityIcon.png';
            btn.ValueChangedFcn = @tbShowColorbarStateChanged;
            btn.Tag = ['ShowColorbar',axH.Tag];
            btn.Tooltip = 'Show colorbar';
            PODSData.Handles.(btn.Tag) = btn;
            btn.Value = 1;
        end
        
    end

    function [axH] = SetAxisTitle(axH,title)
        % Set image (actually axis) title to top center of axis
        axH.Title.String = title;
        axH.Title.Units = 'Normalized';
        axH.Title.FontName = PODSData.Settings.DefaultPlotFont;
        axH.Title.HorizontalAlignment = 'Center';
        axH.Title.VerticalAlignment = 'Top';
        axH.Title.Color = 'White';
        axH.Title.Position = [0.5,1.0,0];
        axH.Title.BackgroundColor = [0 0 0 0.5];
        axH.Title.HitTest = 'Off';
    end

%% 'Objects' menubar callbacks

    function mbDeleteSelectedObjects(source,~)
        
        cGroup = PODSData.CurrentGroup;
        
        cGroup.DeleteSelectedObjects();
        
        UpdateImages(source);
        UpdateObjectListBox(source);
        UpdateSummaryDisplay(source,{'Group','Image','Object'});
    end

    function mbClearSelection(source,~)
        
        cGroup = PODSData.CurrentGroup;
        
        cGroup.ClearSelection();
        
        UpdateImages(source);
        UpdateObjectListBox(source);
        UpdateSummaryDisplay(source);
    end

    function mbObjectkmeansClustering(source,~)

        % get the object data table
        T = SavePODSData(source);
        % the variables we can use to cluster
        VarShortList = PODSData.Settings.ObjectPlotVariables;
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
        [ClusterIdxs,OptimalK] = PODSObjectClustering(ObjectData,...
            nClusters,...
            nRepeats,...
            VariablesList,...
            [1,1,1],...
            nClustersMode,...
            Criterion);
        % in case k was set automatically, adjust number of clusters to match
        nClusters = OptimalK;
        % delete the existing object labels
        CurrentLabels = PODSData.Settings.ObjectLabels;
        for LabelIdx = 1:numel(CurrentLabels)
            PODSData.Settings.DeleteObjectLabel(CurrentLabels(LabelIdx));
        end
        % find set of colors (n = nClusters) distinguishable from both black and white 
        BGColors = [0 0 0;1 1 1];
        LabelColors = distinguishable_colors(nClusters,BGColors);
        % create the new cluster labels
        for idx = 1:nClusters
            PODSData.Settings.ObjectLabels(idx,1) = PODSLabel(['Cluster #',num2str(idx)],LabelColors(idx,:),PODSData.Settings);
        end

        if any(isnan(ClusterIdxs))
            % add one additional label in case custering fails (NaNs in the clustering data -> NaNs in ClusterIdxs)
            PODSData.Settings.ObjectLabels(end+1,1) = PODSLabel(['Clustering failed'],distinguishable_colors(1,[LabelColors;BGColors]),PODSData.Settings);
        end

        % Testing below
        PieChartData = cell(PODSData.nGroups,1);
        for g_idx = 1:PODSData.nGroups
            PieChartData{g_idx,1} = {};
        end
        % end testing

        % use the k-means clustering output to label each object with its cluster
        ObjCounter = 1;
        for g_idx = 1:PODSData.nGroups
            for i_idx = 1:PODSData.Group(g_idx).nReplicates
                for o_idx = 1:PODSData.Group(g_idx).Replicate(i_idx).nObjects
                    try
                        PODSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label = PODSData.Settings.ObjectLabels(ClusterIdxs(ObjCounter));
                        PieChartData{g_idx,1}{end+1} = PODSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label.Name;
                        ObjCounter = ObjCounter+1;
                    catch
                        PODSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label = PODSData.Settings.ObjectLabels(end);
                        PieChartData{g_idx,1}{end+1} = PODSData.Group(g_idx).Replicate(i_idx).Object(o_idx).Label.Name;
                        ObjCounter = ObjCounter+1;
                    end
                end
            end
        end

        fH_ClusterProportions = uifigure('Name','Cluster proportions by group','HandleVisibility','on');
        % PieGrid = uigridlayout(fH_ClusterProportions,[1,PODSData.nGroups]);
        PieGrid = uigridlayout(fH_ClusterProportions);
        PieAxes = gobjects(PODSData.nGroups,1);
        for g_idx = 1:PODSData.nGroups
            PieAxes(g_idx) = uiaxes(PieGrid);
            pie(PieAxes(g_idx),categorical(PieChartData{g_idx,1}));
            PieAxes(g_idx).Title.String = [PODSData.Group(g_idx).GroupName];
        end

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

        ObjImgTiles = cell(PODSData.Settings.nLabels,1);

        for LabelIdx = 1:PODSData.Settings.nLabels
            Objs = PODSData.getObjectsByLabel(PODSData.Settings.ObjectLabels(LabelIdx));
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
                'BackgroundColor',PODSData.Settings.ObjectLabels(LabelIdx).Color,...
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

%% Changing file input settings

    function ChangeInputFileType(source,~)
        PODSData.Settings.InputFileType = source.Text;
        UpdateLog3(source,['Input File Type Changed to ',source.Text],'append');
        
        switch PODSData.Settings.InputFileType
            case '.nd2'
                PODSData.Handles.hFileInputType_nd2.Checked = 'On';
                PODSData.Handles.hFileInputType_tif.Checked = 'Off';
            case '.tif'
                PODSData.Handles.hFileInputType_nd2.Checked = 'Off';
                PODSData.Handles.hFileInputType_tif.Checked = 'On';
        end

        % only update summary overview if 'Project' is selected
        UpdateSummaryDisplay(source,{'Project'});
    end

%% Changing object boxes type

    function ChangeObjectBoxType(source,~)
        PODSData.Settings.ObjectBoxType = source.Text;
        UpdateLog3(source,['Object Box Type Changed to ',source.Text],'append');

        set(PODSData.Handles.hObjectBoxType.Children(),'Checked','Off');
        set(PODSData.Handles.(['hObjectBoxType_',source.Text]),'Checked','On');

        % only update summary overview if 'Project' is selected
        UpdateSummaryDisplay(source,{'Project'});
        UpdateImages(source);
    end

%% changing GUI theme (dark or light)

    function ChangeGUITheme(source,~)

        PODSData.Settings.GUITheme = source.Text;
        UpdateLog3(source,['Switched theme to ',source.Text],'append');

        set(PODSData.Handles.hGUITheme.Children,'Checked','Off');
        source.Checked = 'On';

        switch PODSData.Settings.GUITheme
            case 'Dark'
                PODSData.Settings.GUIBackgroundColor = [0 0 0];
                PODSData.Settings.GUIForegroundColor = [1 1 1];
                PODSData.Settings.GUIHighlightColor = [1 1 1];
            case 'Dark2'
                PODSData.Settings.GUIBackgroundColor = [0.0549,0.0667,0.0902];
                PODSData.Settings.GUIForegroundColor = [1,1,1];
                PODSData.Settings.GUIHighlightColor = [0.6,0.6,0.6];
            case 'Light'
                PODSData.Settings.GUIBackgroundColor = [1 1 1];
                PODSData.Settings.GUIForegroundColor = [0 0 0];
                PODSData.Settings.GUIHighlightColor = [0 0 0];
        end
        
        UpdateGUITheme();
    end

    function UpdateGUITheme()
        GUIBackgroundColor = PODSData.Settings.GUIBackgroundColor;
        GUIForegroundColor = PODSData.Settings.GUIForegroundColor;
        GUIHighlightColor = PODSData.Settings.GUIHighlightColor;
        set(findobj(PODSData.Handles.fH,'type','uigridlayout'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(PODSData.Handles.fH,'type','uipanel'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(PODSData.Handles.fH,'type','uipanel'),'ForegroundColor',GUIForegroundColor);
        set(findobj(PODSData.Handles.fH,'type','uipanel'),'HighlightColor',GUIHighlightColor);
        set(findobj(PODSData.Handles.fH,'type','uitextarea'),'FontColor',GUIForegroundColor);
        set(findobj(PODSData.Handles.fH,'type','uitextarea'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(PODSData.Handles.fH,'type','axes'),'XColor',GUIForegroundColor);
        set(findobj(PODSData.Handles.fH,'type','axes'),'YColor',GUIForegroundColor);
        set(findobj(PODSData.Handles.fH,'type','axes'),'Color',GUIBackgroundColor);
        set(findobj(PODSData.Handles.fH,'type','uilabel'),'FontColor',GUIForegroundColor);
        set(findobj(PODSData.Handles.fH,'type','uilabel'),'BackgroundColor',GUIBackgroundColor);

        % set uitable colors
        set(findobj(PODSData.Handles.fH,'type','uitable'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(PODSData.Handles.fH,'type','uitable'),'ForegroundColor',GUIForegroundColor);

        % set uilistbox colors
        set(findobj(PODSData.Handles.fH,'type','uilistbox'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(PODSData.Handles.fH,'type','uilistbox'),'FontColor',GUIForegroundColor);

        % set uitree colors
        set(findobj(PODSData.Handles.fH,'type','uitree'),'BackgroundColor',GUIBackgroundColor);
        set(findobj(PODSData.Handles.fH,'type','uitree'),'FontColor',GUIForegroundColor);

        % set swarm plot colors
        PODSData.Handles.ScatterPlotGrid.BackgroundColor = PODSData.Settings.SwarmPlotBackgroundColor;
        PODSData.Handles.ScatterPlotAxH.Color = PODSData.Settings.SwarmPlotBackgroundColor;
        PODSData.Handles.ScatterPlotAxH.XAxis.Color = PODSData.Settings.SwarmPlotForegroundColor;
        PODSData.Handles.ScatterPlotAxH.YAxis.Color = PODSData.Settings.SwarmPlotForegroundColor;

        % set scatter plot colors
        PODSData.Handles.SwarmPlotGrid.BackgroundColor = PODSData.Settings.SwarmPlotBackgroundColor;
        PODSData.Handles.SwarmPlotAxH.Color = PODSData.Settings.SwarmPlotBackgroundColor;
        PODSData.Handles.SwarmPlotAxH.XAxis.Color = PODSData.Settings.SwarmPlotForegroundColor;
        PODSData.Handles.SwarmPlotAxH.YAxis.Color = PODSData.Settings.SwarmPlotForegroundColor;

        % set intensity slider colors
        set(PODSData.Handles.PrimaryIntensitySlider,...
            'BackgroundColor',GUIBackgroundColor,...
            'Knob1Color',GUIForegroundColor,...
            'Knob2Color',GUIForegroundColor,...
            'RangeColor',GUIForegroundColor,...
            'MidLineColor',GUIForegroundColor);
        set(PODSData.Handles.ReferenceIntensitySlider,...
            'BackgroundColor',GUIBackgroundColor,...
            'Knob1Color',GUIForegroundColor,...
            'Knob2Color',GUIForegroundColor,...
            'RangeColor',GUIForegroundColor,...
            'MidLineColor',GUIForegroundColor);

        PODSData.Handles.CurrentThresholdLine.Color = GUIForegroundColor;

        PODSData.Handles.OrderFactorAxH.Color = 'Black';
        PODSData.Handles.AverageIntensityAxH.Color = 'Black';
        PODSData.Handles.AzimuthAxH.Color = 'Black';
        PODSData.Handles.MaskAxH.Color = 'Black';

        UpdateSummaryDisplay(PODSData.Handles.fH);

    end

    function ChangeGUIColors(source,~)
        % get the color of the GUI element for which we want to change color
        PODSData.Settings.(source.Tag) = uisetcolor();
        % bring the main figure into focus
        figure(PODSData.Handles.fH);
        % uncheck all menubar options for built-in themes
        set(PODSData.Handles.hGUITheme.Children,'Checked','Off');
        % update the GUI colors
        UpdateGUITheme();
    end

%% GUI font size

    function ChangeGUIFontSize(source,~)
        switch source.Text
            case 'Larger'
                PODSData.Settings.FontSize = PODSData.Settings.FontSize+1;
            case 'Smaller'
                PODSData.Settings.FontSize = PODSData.Settings.FontSize-1;
        end
        % adjust the font size across the board
        fontsize(PODSData.Handles.fH,PODSData.Settings.FontSize,'pixels');
        % update the GUI summary display panel
        UpdateSummaryDisplay(source,{'Project'});
    end


%% MaskType Selection

    function ChangeMaskType(source,~)
        PODSData.Settings.MaskType = source.Tag;
        PODSData.Settings.MaskName = source.Text;
        set(PODSData.Handles.hMaskType_CustomScheme.Children,'Checked','Off');
        set(PODSData.Handles.hMaskType_Default.Children,'Checked','Off');
        % set chosen mask type to checked
        source.Checked = 'On';
        % only update summary overview if 'Project' is selected
        UpdateSummaryDisplay(source,{'Project'});
        % update image operations display
        UpdateImageOperationDisplay(source);
    end

    function BuildNewScheme(~,~)
        
        SchemeNameCell = SimpleFormFig('Enter a name for the masking scheme',{'Scheme name'},'White','Black');

        if iscell(SchemeNameCell)
            NewSchemeName = SchemeNameCell{1};
        else % invalid input
            return
        end

        % open the CustomMaskMaker app so user can build a masking scheme
        NewScheme = CustomMaskMaker(PODSData.CurrentImage(1).I,[],PODSData.Settings.IntensityColormap);
        % get the handle to the mask maker app window
        MaskMakerFig = findobj(groot,'Name','Mask Maker');
        % and wait until it is closed
        waitfor(MaskMakerFig);

        % attempt to save the new mask scheme
        try
            % if not a valid masking scheme, throw error
            if ~NewScheme.isValidMaskingScheme
                error('Invalid scheme');
            end
            % the path to the directory in which we will save the scheme
            if ismac || isunix
                SchemeFilesPath = [PODSData.Settings.MainPath,'/CustomMasks/Schemes/'];
            elseif ispc
                SchemeFilesPath = [PODSData.Settings.MainPath,'\CustomMasks\Schemes\'];
            end
            % save the new scheme
            temp_scheme_struct.(NewSchemeName) = NewScheme;
            save([SchemeFilesPath,NewSchemeName,'.mat'],'-struct','temp_scheme_struct');
        catch ME
            % depending on the error caught, update user, return
            switch ME.message
                case 'Invalid scheme'
                    uialert(PODSData.Handles.fH,'Not a valid masking scheme','Error');
                    return
                otherwise
                    report = getReport(ME);
                    uialert(PODSData.Handles.fH,['Unable to load project: ',report],'Error');
                    return
            end
        end

        % update PODSSettings with new scheme
        PODSData.Settings.LoadCustomMaskSchemes;

        % update uimenu to show newly saved scheme
        delete(PODSData.Handles.hMaskType_CustomScheme);

        % rebuild the menu bar options for custom mask schemes
        PODSData.Handles.hMaskType_CustomScheme = uimenu(PODSData.Handles.hMaskType,'Text','CustomScheme');

        for SchemeIdx = 1:numel(PODSData.Settings.SchemeNames)
            PODSData.Handles.(['hMaskType_CustomScheme_',PODSData.Settings.SchemeNames{SchemeIdx}]) = ...
                uimenu(PODSData.Handles.hMaskType_CustomScheme,...
                'Text',PODSData.Settings.SchemeNames{SchemeIdx},...
                'Tag','CustomScheme',...
                'Checked','Off',...
                'Callback',@ChangeMaskType);
        end

        PODSData.Handles.hMaskType_NewScheme = uimenu(PODSData.Handles.hMaskType_CustomScheme,...
            'Text','Create new scheme',...
            'Separator','on',...
            'Callback',@BuildNewScheme);

        % update the log window
        UpdateLog3(PODSData.Handles.fH,['Saved new scheme:',SchemeFilesPath,NewSchemeName,'.mat'],'append');
    end

%% Changing active object/image/group indices

    function ChangeActiveObject(source,~)
        cImage = PODSData.CurrentImage;
        cImage.CurrentObjectIdx = source.Value;
        UpdateSummaryDisplay(source,{'Object'});
        if strcmp(PODSData.Settings.CurrentTab,'View Objects')
            UpdateImages(source);
        end
        %disp('object selection changed');
    end

    function GroupSelectionChanged(source,~)
        PODSData.CurrentGroupIndex = source.SelectedNodes(1).NodeData.SelfIdx;
        % update display of image tree, images, and summary
        UpdateImageTree(source);
        UpdateImages(source);
        UpdateImageOperationDisplay(source);
        UpdateSummaryDisplay(source,{'Group','Image','Object'});
    end

    function ImageSelectionChanged(source,~)
        CurrentGroupIndex = PODSData.CurrentGroupIndex;
        SelectedImages = deal([source.SelectedNodes(:).NodeData]);
        PODSData.Group(CurrentGroupIndex).CurrentImageIndex = [SelectedImages(:).SelfIdx];
        % update display of images, object selector, summary
        UpdateImages(source);
        UpdateObjectListBox(source);
        UpdateImageOperationDisplay(source);
        UpdateSummaryDisplay(source,{'Image','Object'});
    end

    function ObjectSelectionChanged(source,~)
        cImage = PODSData.CurrentImage;
        SelectedObjects = deal([source.SelectedNodes(:).NodeData]);
        cImage.CurrentObjectIdx = [SelectedObjects(:).SelfIdx];
        % update images and summary
        UpdateImages(source);
        UpdateSummaryDisplay(source,{'Image','Object'});
    end

    function ChangeImageOperation(source,~)

        OldOperation = PODSData.Settings.CurrentImageOperation;
        PODSData.Settings.CurrentImageOperation = source.Value;

        try
            cImage = PODSData.CurrentImage(1);
        catch
            PODSData.Settings.CurrentImageOperation = OldOperation;
            source.Value = OldOperation;
            UpdateLog3(source,'Warning: No image selected','append');
            return
        end

        UpdateImageOperationDisplay(source);

    end

%% Change summary display type

    function ChangeSummaryDisplay(source,~)
        % update the summary display type
        PODSData.Settings.SummaryDisplayType = PODSData.Handles.AppInfoSelector.Value;


        % % set the title of the summary panel
        % PODSData.Handles.AppInfoPanel.Title = [PODSData.Settings.SummaryDisplayType,' summary'];
        % % hide grid layout managers for all summary tables
        % set(findobj(PODSData.Handles.AppInfoPanel.Children(),'type','uigridlayout'),'Visible','off');
        % % show the grid layout manager for the summary type that is active
        % PODSData.Handles.([PODSData.Settings.SummaryDisplayType,'SummaryTableGrid']).Visible = 'on';


        % update the summary panel with the selected tabular data
        UpdateSummaryDisplay(source);
    end

%% Local SB

    function pb_FindLocalSB(source,~)
        % number of selected images
        nImages = length(PODSData.CurrentImage);
        % update log to indicate # of images we are processing
        UpdateLog3(source,['Detecting Local S/B for ',num2str(nImages),' images'],'append');
        % counter to track which image we're on
        Counter = 1;
        for cImage = PODSData.CurrentImage
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

%% Object Azimuth Stats

    function pb_ComputeObjectAzimuthStats(source,~)
        % number of selected images
        nImages = length(PODSData.CurrentImage);
        % update log to indicate # of images we are processing
        UpdateLog3(source,['Computing object azimuth statistics for ',num2str(nImages),' images'],'append');
        % counter to track progress
        Counter = 1;
        % detect object azimuth stats for each currently selected image
        for cImage = PODSData.CurrentImage
            % update log to indicate which image we are on
            UpdateLog3(source,['    ',cImage.pol_shortname,' (',num2str(Counter),'/',num2str(nImages),')'],'append');
            % compute the azimuth stats
            cImage.ComputeObjectAzimuthStats();
            % log update to indicate we are done with this image
            UpdateLog3(source,['        Computed object azimuth statistics for ',num2str(cImage.nObjects),' objects...'],'append');
            % increment the counter
            Counter = Counter+1;
        end
        % update summary table
        UpdateSummaryDisplay(source,{'Group','Image','Object'});
        % update log to indicate we are done
        UpdateLog3(source,'Done.','append');
    end

%% Order statistics (OF, azimuth, potentially more in the future)

    function pb_FindOrderFactor(source,~)
        % number of selected images
        nImages = length(PODSData.CurrentImage);
        % update log to indicate # of images we are processing
        UpdateLog3(source,['Computing order statistics statistics for ',num2str(nImages),' images'],'append');
        % counter to track progress
        Counter = 1;
        % start a timer
        tic
        % detect object azimuth stats for each currently selected image
        for cImage = PODSData.CurrentImage
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
        if ~strcmp(PODSData.Settings.CurrentTab,'Order Factor')
            feval(PODSData.Handles.hTabOrderFactor.Callback,PODSData.Handles.hTabOrderFactor,[]);
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
        uialert(PODSData.Handles.fH,'Select saved project file (.mat)','Load Project File',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(PODSData.Handles.fH));
        % call uiwait() on the main window
        uiwait(PODSData.Handles.fH);
        % set figure visibility to off
        PODSData.Handles.fH.Visible = 'Off';
        % open file selection window
        [filename,path] = uigetfile('*.mat','Choose saved PODS Project',PODSData.Settings.LastDirectory);
        % turn figure visibility back on
        PODSData.Handles.fH.Visible = 'On';
        % return focus to main figure window
        figure(PODSData.Handles.fH);
        % handle invalid selections or cancel
        if ~filename
            msg = 'No file selected...';
            uialert(PODSData.Handles.fH,msg,'Error');
            return
        end
        % store old pointer
        OldPointer = PODSData.Handles.fH.Pointer;
        % set new watch pointer while we load
        PODSData.Handles.fH.Pointer = 'watch';
        % store the handles struct
        Handles = PODSData.Handles;
        % store the previous tab
        PreviousTab = PODSData.Settings.CurrentTab;
        % update log
        UpdateLog3(source,['Loading project:',path,filename],'append');
        % attempt to load the selected file
        try
            load([path,filename],'SavedPODSData');
            if isa(SavedPODSData,'struct')
                SavedPODSData = PODSProject.loadobj(SavedPODSData);
            end
        catch ME
            report = getReport(ME);
            PODSData.Handles.fH.Pointer = OldPointer;
            uialert(PODSData.Handles.fH,['Unable to load project: ',report],'Error')
            return
        end
        % add the stored handles to the newly loaded project
        SavedPODSData.Handles = Handles;
        % add the loaded project to the PODSData object
        PODSData = SavedPODSData;
        % add the project with handles to the gui
        guidata(PODSData.Handles.fH,PODSData);

        % update some settings for the current window

        % update custom schemes menu options
        % delete all the existing options
        delete(PODSData.Handles.hMaskType_CustomScheme.Children)
        % Load the custom schemes and make a menu option for each one
        for SchemeIdx = 1:numel(PODSData.Settings.SchemeNames)
            PODSData.Handles.(['hMaskType_CustomScheme_',PODSData.Settings.SchemeNames{SchemeIdx}]) = ...
                uimenu(PODSData.Handles.hMaskType_CustomScheme,...
                'Text',PODSData.Settings.SchemeNames{SchemeIdx},...
                'Tag','CustomScheme',...
                'Checked','Off',...
                'Callback',@ChangeMaskType);
        end
        % Option to create new 'Custom' mask scheme
        PODSData.Handles.hMaskType_NewScheme = uimenu(PODSData.Handles.hMaskType_CustomScheme,...
            'Text','Create new scheme',...
            'Separator','on',...
            'Callback',@BuildNewScheme);

        % update swarm plot grouping type drop down
        PODSData.Handles.SwarmPlotGroupingTypeDropdown.Value = PODSData.Settings.SwarmPlotGroupingType;


        % update the display with selected tab
        Tab2Switch2 = PODSData.Settings.CurrentTab;
        % set 'CurrentTab' to previous current tab before loading project
        PODSData.Settings.CurrentTab = PreviousTab;
        % find the uimenu that would normally be used to switch to the tab indicated by 'CurrentTab' in the loaded project
        Menu2Pass = findobj(PODSData.Handles.hTabMenu.Children,'Text',Tab2Switch2);
        % update view and display with newly loaded project
        % update group/image/object selection trees
        UpdateGroupTree(source);
        UpdateImageTree(source);
        UpdateLabelTree(source);
        % update summary type selector and summary tables
        PODSData.Handles.AppInfoSelector.Value = PODSData.Settings.SummaryDisplayType;
        UpdateSummaryDisplay(source);
        % update image operations type selector and image operations panel
        PODSData.Handles.ImageOperationsSelector.Value = PODSData.Settings.CurrentImageOperation;       
        UpdateImageOperationDisplay(source);
        % update current tab using uimenu object as the source
        TabSelection(Menu2Pass);
        UpdateImages(source);
        % update menu bar items
        % update mask type/name options context menu
        % uncheck all mask names for each mask type
        set(PODSData.Handles.hMaskType_CustomScheme.Children,'Checked','Off');
        set(PODSData.Handles.hMaskType_Default.Children,'Checked','Off');
        % check the currently selected mask name
        switch PODSData.Settings.MaskType
            case 'Default'
                PODSData.Handles.(['hMaskType_Default_',PODSData.Settings.MaskName]).Checked = 'On';
            case 'CustomScheme'
                PODSData.Handles.(['hMaskType_CustomScheme_',PODSData.Settings.MaskName]).Checked = 'On';
        end
        % update object box type options context menu
        set(PODSData.Handles.hObjectBoxType.Children,'Checked','off');
        PODSData.Handles.(['hObjectBoxType_',PODSData.Settings.ObjectBoxType]).Checked = 'On';



        % restore old pointer
        PODSData.Handles.fH.Pointer = OldPointer;
        % update log to indicate completion
        UpdateLog3(source,'Done.','append');
    end

    function SaveProject(source,~)

        uialert(PODSData.Handles.fH,'Set save location/filename','Save Project File',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(PODSData.Handles.fH));

        uiwait(PODSData.Handles.fH);

        PODSData.Handles.fH.Visible = 'Off';

        try
            [filename,path] = uiputfile('*.mat','Set directory and filename',PODSData.Settings.LastDirectory);
        catch
            [filename,path] = uiputfile('*.mat','Set directory and filename');
        end

        PODSData.Handles.fH.Visible = 'On';

        figure(PODSData.Handles.fH);

        if ~filename
            msg = 'Invalid filename...';
            uialert(PODSData.Handles.fH,msg,'Error');
            return
        end

        % store old pointer
        OldPointer = PODSData.Handles.fH.Pointer;
        % set new watch pointer while we save
        PODSData.Handles.fH.Pointer = 'watch';
        % update log
        UpdateLog3(source,'Saving project...','append');

%         % copy the handle to PODSData into a new variable, SavedPODSData
%         SavedPODSData = PODSData;

        tic

        % attempt to save the project
        try
            disp('Retrieving data struct...')
    
            % % method 1
            % SavedPODSData = PODSData.saveobj();
            % disp('Saving data struct...')
            % save([path,filename],'SavedPODSData');


            % % method 2
            SavedPODSData = PODSData;
            disp('Saving data struct...')
            save([path,filename],'SavedPODSData');

            clear SavedPODSData
        catch ME
            report = getReport(ME);
            PODSData.Handles.fH.Pointer = OldPointer;
            uialert(PODSData.Handles.fH,['Unable to save project: ',report],'Error')
            return
        end

        % display how long it took to save the data
        timeElapsed = toc;
        disp(['Total time elapsed: ',num2str(timeElapsed)])
        % restore old pointer
        PODSData.Handles.fH.Pointer = OldPointer;

        % update log to indicate successful save
        UpdateLog3(source,['Successfully saved project:',path,filename],'append');

    end

%% Data saving

    function [] = SaveImages(source,~)
        
        % get screensize
        ss = PODSData.Settings.ScreenSize;
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
            PODSData.Handles.fH.Visible = 'Off';
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
            PODSData.Handles.fH.Visible = 'On';
            return
        end
        % get save directory
        folder_name = uigetdir(pwd);
        % turn main fig back on
        PODSData.Handles.fH.Visible = 'On';
        % move into user-selected save directory
        cd(folder_name);

        % save user-specified data for each currently selected image
        for cImage = PODSData.CurrentImage
            
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
                ImageSummary.RawData = cImage.pol_rawdata;
                ImageSummary.RawDataAvg = cImage.RawPolAvg;
                % same as above, but with flat-field corrected data
                ImageSummary.FlatFieldCorrectedData = cImage.pol_ffc;
                ImageSummary.FlatFieldCorrectedDataAvg = cImage.Pol_ImAvg;
                % FF-corrected data normalized within each 4-px stack
                ImageSummary.FlatFieldCorrectedDataPixelNorm = cImage.norm;
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
                imwrite(IOut,PODSData.Settings.IntensityColormap,name);                
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
        
        CurrentGroup = PODSData.CurrentGroup;
        
        % alert box to indicate required action
        uialert(PODSData.Handles.fH,['Select a directory to save object data for Group:',CurrentGroup.GroupName],'Save object data',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(PODSData.Handles.fH));
        % prevent interaction with main window until we finish
        uiwait(PODSData.Handles.fH);
        % hide main window
        PODSData.Handles.fH.Visible = 'Off';
        % try to get files from the most recent directory,
        % otherwise, just use default
        try
            UserChoice = uigetdir(PODSData.Settings.LastDirectory);
        catch
            UserChoice = uigetdir(pwd);
        end
        % save accessed directory
        PODSData.Settings.LastDirectory = UserChoice;
        % hide main window
        PODSData.Handles.fH.Visible = 'On';
        % make PODSGUI active figure
        figure(PODSData.Handles.fH);
        % if no files selected, throw error

        if ~UserChoice
            msg = 'No directory selected...';
            uialert(PODSData.Handles.fH,msg,'Error');
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

%% Toolbar callbacks

    function tbExportAxes(source,~)
        % get the toolbar parent of the calling button
        ctb = source.Parent;
        % get the axes parent of that toolbar, which we will export
        cax = ctb.Parent;

        uialert(PODSData.Handles.fH,'Set save location/filename','Export axes',...
            'Icon','',...
            'CloseFcn',@(o,e) uiresume(PODSData.Handles.fH));

        uiwait(PODSData.Handles.fH);

        PODSData.Handles.fH.Visible = 'Off';

        try
            [filename,path] = uiputfile('*.png',...
                'Set directory and filename',PODSData.Settings.LastDirectory);
        catch
            [filename,path] = uiputfile('*.png',...
                'Set directory and filename');
        end

        PODSData.Handles.fH.Visible = 'On';
        figure(PODSData.Handles.fH);

        if ~filename
            msg = 'Invalid filename...';
            uialert(PODSData.Handles.fH,msg,'Error');
            return
        end

        PODSData.Settings.LastDirectory = path;

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
        
        cGroupIdx = PODSData.CurrentGroupIndex;
        cImageIdx = PODSData.Group(cGroupIdx).CurrentImageIndex;
        ctb = source.Parent;
        cax = ctb.Parent;
        im = findobj(cax,'Type','image');

        % if strcmp(cax.Tag,'OrderFactor')
        %     switch event.Value
        %         case 1
        %             im.CData = PODSData.Group(cGroupIdx).Replicate(cImageIdx).MaskedOFImageRGB;
        %         case 0
        %             im.CData = PODSData.Group(cGroupIdx).Replicate(cImageIdx).OF_image;
        %     end
        % 
        %     return
        % end

        switch event.Value
            case 1 % 'On'
                im.AlphaData = PODSData.Group(cGroupIdx).Replicate(cImageIdx).bw;
            case 0 % 'Off'
                im.AlphaData = 1;
        end
    end

    function tbShowAsOverlayStateChanged(source,~)
        UpdateImages(source);
    end

    function tbShowSelectionStateChanged(source,event)
        switch event.Value
            case 1
                PODSData.Handles.ShowSelectionAverageIntensity.Value = 1;
                PODSData.Handles.ShowSelectionMask.Value = 1;
                UpdateImages(source);
            case 0
                PODSData.Handles.ShowSelectionAverageIntensity.Value = 0;
                PODSData.Handles.ShowSelectionMask.Value = 0;
                delete(findobj(PODSData.Handles.fH,'Tag','ObjectBox'))
        end
        
    end

    function tbShowColorbarStateChanged(source,~)
        UpdateImages(source);
    end

    function tbShowReferenceImageStateChanged(source,~)
        if PODSData.CurrentImage.ReferenceImageLoaded
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
            delete(PODSData.Handles.LineScanROI);
            delete(PODSData.Handles.LineScanFig);
            delete(PODSData.Handles.LineScanListeners(1));
            delete(PODSData.Handles.LineScanListeners(2));
        catch
            % do nothing for now
        end

        switch source.Tag
            case 'LineScanAverageIntensity'
                PODSData.Handles.LineScanROI = images.roi.Line(PODSData.Handles.AverageIntensityAxH,...
                    'Color','Yellow',...
                    'Alpha',0.5,...
                    'Tag','LineScanAverageIntensity');
                XRange = PODSData.Handles.AverageIntensityAxH.XLim(2)-PODSData.Handles.AverageIntensityAxH.XLim(1);
                YRange = PODSData.Handles.AverageIntensityAxH.YLim(2)-PODSData.Handles.AverageIntensityAxH.YLim(1);
                x1 = PODSData.Handles.AverageIntensityAxH.XLim(1)+0.25*XRange;
                x2 = PODSData.Handles.AverageIntensityAxH.XLim(2)-0.25*XRange;
                y1 = PODSData.Handles.AverageIntensityAxH.YLim(1)+0.5*YRange;
                y2 = PODSData.Handles.AverageIntensityAxH.YLim(1)+0.5*YRange;
        
                PODSData.Handles.LineScanFig = uifigure('Name','Average Intensity line scan',...
                    'HandleVisibility','On',...
                    'WindowStyle','AlwaysOnTop',...
                    'Units','Normalized',...
                    'Position',[0.65 0.8 0.35 0.2],...
                    'CloseRequestFcn',@CloseLineScanFig);
                
                PODSData.Handles.LineScanAxes = uiaxes(PODSData.Handles.LineScanFig,'Units','Normalized','OuterPosition',[0 0 1 1]);
                
                PODSData.Handles.LineScanROI.Position = [x1 y1; x2 y2];
                
                PODSData.Handles.LineScanListeners(1) = addlistener(PODSData.Handles.LineScanROI,'MovingROI',@LineScanROIMoving);
                PODSData.Handles.LineScanListeners(2) = addlistener(PODSData.Handles.LineScanROI,'ROIMoved',@LineScanROIMoved);
            case 'LineScanOrderFactor'
                PODSData.Handles.LineScanROI = images.roi.Line(PODSData.Handles.OrderFactorAxH,...
                    'Color','Yellow',...
                    'Alpha',0.5,...
                    'Tag','LineScanOrderFactor');
                XRange = PODSData.Handles.OrderFactorAxH.XLim(2)-PODSData.Handles.OrderFactorAxH.XLim(1);
                YRange = PODSData.Handles.OrderFactorAxH.YLim(2)-PODSData.Handles.OrderFactorAxH.YLim(1);
                x1 = PODSData.Handles.OrderFactorAxH.XLim(1)+0.25*XRange;
                x2 = PODSData.Handles.OrderFactorAxH.XLim(2)-0.25*XRange;
                y1 = PODSData.Handles.OrderFactorAxH.YLim(1)+0.5*YRange;
                y2 = PODSData.Handles.OrderFactorAxH.YLim(1)+0.5*YRange;
        
                PODSData.Handles.LineScanFig = uifigure('Name','Order Factor line scan',...
                    'HandleVisibility','On',...
                    'WindowStyle','AlwaysOnTop',...
                    'Units','Normalized',...
                    'Position',[0.65 0.8 0.35 0.2],...
                    'CloseRequestFcn',@CloseLineScanFig,...
                    'Color','White');
                
                PODSData.Handles.LineScanAxes = uiaxes(PODSData.Handles.LineScanFig,'Units','Normalized','OuterPosition',[0 0 1 1]);
                PODSData.Handles.LineScanAxes.XLabel.String = 'Distance (um)';
                PODSData.Handles.LineScanAxes.YLabel.String = 'Average OF';
                
                PODSData.Handles.LineScanROI.Position = [x1 y1; x2 y2];
                
                PODSData.Handles.LineScanListeners(1) = addlistener(PODSData.Handles.LineScanROI,'MovingROI',@LineScanROIMoving);
                PODSData.Handles.LineScanListeners(2) = addlistener(PODSData.Handles.LineScanROI,'ROIMoved',@LineScanROIMoved);
        end

    end

    function CloseLineScanFig(~,~)
        delete(PODSData.Handles.LineScanROI);
        delete(PODSData.Handles.LineScanListeners(1));
        delete(PODSData.Handles.LineScanListeners(2));        
        delete(PODSData.Handles.LineScanFig);
    end

    function LineScanROIMoving(source,~)

        cImage = PODSData.CurrentImage;
        
        switch source.Tag
            case 'LineScanAverageIntensity'
                if cImage.ReferenceImageLoaded && PODSData.Handles.ShowReferenceImageAverageIntensity.Value==1
                    PODSData.Handles.LineScanAxes = PlotIntegratedDoubleLineScan(PODSData.Handles.LineScanAxes,...
                        PODSData.Handles.LineScanROI.Position,...
                        cImage.Pol_ImAvg,...
                        cImage.ReferenceImageEnhanced,...
                        cImage.RealWorldLimits);
                else
                    PODSData.Handles.LineScanAxes = PlotIntegratedLineScan(PODSData.Handles.LineScanAxes,...
                        PODSData.Handles.LineScanROI.Position,...
                        cImage.Pol_ImAvg,...
                        cImage.RealWorldLimits);
                end
            case 'LineScanOrderFactor'
                switch PODSData.Handles.ApplyMaskOrderFactor.Value
                    case true
                        PODSData.Handles.LineScanAxes = PlotOrderFactorLineScan(PODSData.Handles.LineScanAxes,...
                            PODSData.Handles.LineScanROI.Position,...
                            cImage.OF_image,...
                            cImage.RealWorldLimits,...
                            cImage.bw);
                    case false
                        PODSData.Handles.LineScanAxes = PlotOrderFactorLineScan(PODSData.Handles.LineScanAxes,...
                            PODSData.Handles.LineScanROI.Position,...
                            cImage.OF_image,...
                            cImage.RealWorldLimits,...
                            []);
                end
        end

    end

    function LineScanROIMoved(source,~)

        cImage = PODSData.CurrentImage;
        
        switch source.Tag
            case 'LineScanAverageIntensity'
                if cImage.ReferenceImageLoaded && PODSData.Handles.ShowReferenceImageAverageIntensity.Value==1
                    PODSData.Handles.LineScanAxes = PlotIntegratedDoubleLineScan(PODSData.Handles.LineScanAxes,...
                        PODSData.Handles.LineScanROI.Position,...
                        cImage.Pol_ImAvg,...
                        cImage.ReferenceImageEnhanced,...
                        cImage.RealWorldLimits);
                else
                    PODSData.Handles.LineScanAxes = PlotIntegratedLineScan(PODSData.Handles.LineScanAxes,...
                        PODSData.Handles.LineScanROI.Position,...
                        cImage.Pol_ImAvg,...
                        cImage.RealWorldLimits);
                end
            case 'LineScanOrderFactor'
                switch PODSData.Handles.ApplyMaskOrderFactor.Value
                    case true
                        PODSData.Handles.LineScanAxes = PlotOrderFactorLineScan(PODSData.Handles.LineScanAxes,...
                            PODSData.Handles.LineScanROI.Position,...
                            cImage.OF_image,...
                            cImage.RealWorldLimits,...
                            cImage.bw);
                    case false
                        PODSData.Handles.LineScanAxes = PlotOrderFactorLineScan(PODSData.Handles.LineScanAxes,...
                            PODSData.Handles.LineScanROI.Position,...
                            cImage.OF_image,...
                            cImage.RealWorldLimits,...
                            []);
                end
        end
        
    end


end