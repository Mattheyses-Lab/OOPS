function PODSv2

% create an instance of PODSProject
% this object will hold ALL project data and GUI settings
PODSData = PODSProject;

% get the default colormap for Order Factor images
OrderFactorMap = PODSData.Settings.OrderFactorColormap;

Handles = struct();

% create the uifigure (main gui window)
Handles.fH = uifigure('Name','PODS GUI',...
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

%% CHECKPOINT

disp('Setting up menubar...')

%% File Menu Button - Create a new project, load files, etc...
Handles.hFileMenu = uimenu(Handles.fH,'Text','File');
% Options for File Menu Button
Handles.hNewProject = uimenu(Handles.hFileMenu,'Text','New Project','Callback',@NewProject);
% load
Handles.hLoadFFCFiles = uimenu(Handles.hFileMenu,'Text','Load FFC Files','Separator','On','Callback',@pb_LoadFFCFiles);
Handles.hLoadFPMFiles = uimenu(Handles.hFileMenu,'Text','Load FPM Files','Callback',@pb_LoadFPMFiles);
Handles.hLoadReferenceImages = uimenu(Handles.hFileMenu,'Text','Load Reference Images','Callback',@LoadReferenceImages);
% save
Handles.hSaveOF = uimenu(Handles.hFileMenu,'Text','Save Selected Image Data','Separator','On','Callback',@SaveImages);
Handles.hSaveObjectData = uimenu(Handles.hFileMenu,'Text','Save Object Data','Callback',@SaveObjectData);

%% Options Menu Button - Change gui option and settings
Handles.hOptionsMenu = uimenu(Handles.fH,'Text','Options');
% Input File Type Option
Handles.hFileInputType = uimenu(Handles.hOptionsMenu,'Text','File Input Type');
% Options for input file type
Handles.hFileInputType_nd2 = uimenu(Handles.hFileInputType,'Text','.nd2','Checked','On','Callback',@ChangeInputFileType);
Handles.hFileInputType_tif = uimenu(Handles.hFileInputType,'Text','.tif','Checked','Off','Callback',@ChangeInputFileType);
% Colormap settings
Handles.hColormapsSettingsMenu = uimenu(Handles.hOptionsMenu,'Text','Colormaps Settings','Callback',@SetColormapsSettings);
% Change azimuth display settings
Handles.hAzimuthDisplaySettingsMenu = uimenu(Handles.hOptionsMenu,'Text','Azimuth Display Settings','Separator','On','Callback',@SetAzimuthDisplaySettings);
Handles.hSwarmChartSettingsMenu = uimenu(Handles.hOptionsMenu,'Text','Swarm Chart Settings','Callback',@SetSwarmChartSettings);
Handles.hScatterPlotSettingsMenu = uimenu(Handles.hOptionsMenu,'Text','Scatter Plot Settings','Callback',@SetScatterPlotSettings);

%% View Menu Button - changes view of GUI to different 'tabs'
Handles.hTabMenu = uimenu(Handles.fH,'Text','View');
% Tabs for 'View'
Handles.hTabFiles = uimenu(Handles.hTabMenu,'Text','Files','MenuSelectedFcn',@TabSelection,'tag','hTabFiles');
Handles.hTabFFC = uimenu(Handles.hTabMenu,'Text','FFC','MenuSelectedFcn',@TabSelection,'tag','hTabFFC');
Handles.hTabGenerateMask = uimenu(Handles.hTabMenu,'Text','Generate Mask','MenuSelectedFcn',@TabSelection,'tag','hTabGenerateMask');
Handles.hTabViewAdjustMask = uimenu(Handles.hTabMenu,'Text','View/Adjust Mask','MenuSelectedFcn',@TabSelection,'tag','hTabViewAdjustMask');
Handles.hTabOrderFactor = uimenu(Handles.hTabMenu,'Text','Order Factor','MenuSelectedFcn',@TabSelection,'tag','hTabOrderFactor');
Handles.hTabSBFiltering = uimenu(Handles.hTabMenu,'Text','Filtered Order Factor','MenuSelectedFcn',@TabSelection,'tag','hTabSBFiltering');
Handles.hTabAzimuth = uimenu(Handles.hTabMenu,'Text','Azimuth','MenuSelectedFcn',@TabSelection,'tag','hTabAzimuth');
Handles.hTabViewPlots = uimenu(Handles.hTabMenu,'Text','Plots','MenuSelectedFcn',@TabSelection,'tag','hTabViewPlots');
Handles.hViewObjects = uimenu(Handles.hTabMenu,'Text','View Objects','MenuSelectedFcn',@TabSelection,'tag','hViewObjects');

%% Process Menu Button - allows user to perform FFC, generate mask, and generate output images
Handles.hProcessMenu = uimenu(Handles.fH,'Text','Process');
% Process Operations
Handles.hProcessFFC = uimenu(Handles.hProcessMenu,'Text','Perform Flat-Field Correction','MenuSelectedFcn',@pb_FFC);
Handles.hProcessMask = uimenu(Handles.hProcessMenu,'Text','Generate Mask','MenuSelectedFcn',@CreateMask4);
Handles.hProcessOF = uimenu(Handles.hProcessMenu,'Text','Find Order Factor','MenuSelectedFcn',@FindOrderFactor3);
Handles.hProcessLocalSB = uimenu(Handles.hProcessMenu,'Text','Find Local Signal:Background','MenuSelectedFcn',@pb_FindLocalSB);

%% Summary Menu Button
Handles.hSummaryMenu = uimenu(Handles.fH,'Text','Summary');
% Summary choices
Handles.hSumaryAll = uimenu(Handles.hSummaryMenu,'Text','All Data','MenuSelectedFcn',@ShowSummaryTable);

%% Objects Menu Button
Handles.hObjectsMenu = uimenu(Handles.fH,'Text','Objects');
% Object Actions
Handles.hDeleteSelectedObjects = uimenu(Handles.hObjectsMenu,'Text','Delete Selected Objects','MenuSelectedFcn',@mbDeleteSelectedObjects);
Handles.hLabelSelectedObjects = uimenu(Handles.hObjectsMenu,'Text','Label Selected Objects','MenuSelectedFcn',@mbLabelSelectedObjects);
Handles.hClearSelection = uimenu(Handles.hObjectsMenu,'Text','Clear Selection','MenuSelectedFcn',@mbClearSelection);

%% draw the menu bar objects and pause for more predictable performance
drawnow
pause(0.5)

%% CHECKPOINT

disp('Setting up grid layout manager...')

%% Set up the MainGrid uigridlayout manager

pos = Handles.fH.Position;

% width and height of the large plots
width = round(pos(3)*0.38);
height = width;
height_norm = height/pos(4);
width_norm = width/pos(3);

% and the small plots
swidth = round(width/2);
sheight = swidth;
swidth_norm = swidth/pos(3);
sheight_norm = sheight/pos(4);

% main grid for managing layout
Handles.MainGrid = uigridlayout(Handles.fH,[4,5]);
Handles.MainGrid.BackgroundColor = [0 0 0];
Handles.MainGrid.RowSpacing = 5;
Handles.MainGrid.ColumnSpacing = 5;
Handles.MainGrid.RowHeight = {'0.5x',swidth,swidth,'0.3x'};
Handles.MainGrid.ColumnWidth = {'1x',sheight,sheight,sheight,sheight};

%% CHECKPOINT

disp('Setting up non-image panels...')

%% Create the non-image panels (Summary, Selector, Settings, Log)
% panel to show project summary
Handles.AppInfoPanel = uipanel(Handles.MainGrid,...
    'Visible','Off',...
    'AutoResizeChildren','Off');
Handles.AppInfoPanel.Title = 'Project Summary';
Handles.AppInfoPanel.Layout.Row = [1 3];
Handles.AppInfoPanel.Layout.Column = 1;

% ImgOperations grid layout (currently just for interactive thresholding)
Handles.ImageOperationsGrid = uigridlayout(Handles.MainGrid,[1,2],'BackgroundColor',[0 0 0],'Padding',[0 0 0 0]);
Handles.ImageOperationsGrid.ColumnWidth = {'0.25x','0.75x'};
Handles.ImageOperationsGrid.ColumnSpacing = 5;
Handles.ImageOperationsGrid.Layout.Row = 1;
Handles.ImageOperationsGrid.Layout.Column = [4 5];

% panel to hold img operations listbox grid
Handles.SettingsSelectorPanel = uipanel(Handles.ImageOperationsGrid,...
    'Visible','Off',...
    'AutoResizeChildren','Off');
Handles.SettingsSelectorPanel.Title = 'Image Operations';
Handles.SettingsSelectorPanel.Layout.Column = 1;

% grid to hold img operations listbox
Handles.SettingsSelectorPanelGrid = uigridlayout(Handles.SettingsSelectorPanel,[1,1],...
    'BackgroundColor',[0 0 0],...
    'Padding',[0 0 0 0]);
% img operations listbox
Handles.SettingsSelector = uilistbox('parent',Handles.SettingsSelectorPanelGrid,...
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

Handles.SettingsPanel = uipanel(Handles.ImageOperationsGrid,...
    'Visible','Off',...
    'AutoResizeChildren','Off');
Handles.SettingsPanel.Layout.Column = 2;
Handles.SettingsPanel.Title = 'Adjust mask threshold';

% panel to display log messages (updates user on running/completed processes)
Handles.LogPanel = uipanel(Handles.MainGrid,...
    'Visible','Off',...
    'AutoResizeChildren','Off');
Handles.LogPanel.Title = 'Log Window';
Handles.LogPanel.Layout.Row = 4;
Handles.LogPanel.Layout.Column = [1 5];

%% CHECKPOINT

disp('Setting up image panels...')

%% Small Image Panels
% tags for small panels
panel_tags = ['Panel_1-1' 'Panel_1-2' 'Panel_1-3' 'Panel_1-4';...
    'Panel_2-1' 'Panel_2-2' 'Panel_2-3' 'Panel_2-4'];

for SmallPanelRows = 1:2
    for SmallPanelColumns = 1:4
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns) = uipanel(Handles.MainGrid,'Visible','Off');
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Row = SmallPanelRows+1;
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Column = SmallPanelColumns+1;
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Tag = panel_tags(SmallPanelRows,SmallPanelColumns);
        % Important to set so we can resize children of panels with expected behavior
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).AutoResizeChildren = 'Off';
    end
end

%% Large Image Panels
% first one (lefthand panel)
Handles.ImgPanel1 = uipanel(Handles.MainGrid,'Visible','Off');
Handles.ImgPanel1.Layout.Row = [2 3];
Handles.ImgPanel1.Layout.Column = [2 3];
%ImgPanel1.Title = 'Large Panel 1'
Handles.ImgPanel1.AutoResizeChildren = 'On';

% second one (righthand panel)
Handles.ImgPanel2 = uipanel(Handles.MainGrid,'Visible','Off');
Handles.ImgPanel2.Layout.Row = [2 3];
Handles.ImgPanel2.Layout.Column = [4 5];
%ImgPanel2.Title = 'Large Panel 2';
Handles.ImgPanel2.AutoResizeChildren = 'On';

% add these to an array so we can change their settings simultaneously
Handles.LargePanels = [Handles.ImgPanel1,Handles.ImgPanel2];

%% CHECKPOINT

disp('Drawing the panels...')

%% draw all the panels and pause briefly for more predictable performance
drawnow
pause(0.5)

%% CHECKPOINT

disp('Setting up selection listboxes...')

%% Selection panels (selection boxes for group/image/objects)

Handles.SelectorGrid = uigridlayout(Handles.MainGrid,[1,3],'BackgroundColor',[0 0 0],'Padding',[0 0 0 0]);
Handles.SelectorGrid.Layout.Row = 1;
Handles.SelectorGrid.Layout.Column = [2 3];
Handles.SelectorGrid.ColumnWidth = {'0.25x','0.5x','0.25x'};
Handles.SelectorGrid.ColumnSpacing = 5;

Handles.GroupSelectorPanel = uipanel(Handles.SelectorGrid,'Title','Group Selection','Visible','Off');
Handles.GroupSelectorPanelGrid = uigridlayout(Handles.GroupSelectorPanel,[1,1],'Padding',[0 0 0 0]);
Handles.GroupSelector = uilistbox('parent',Handles.GroupSelectorPanelGrid,...
    'Visible','Off',...
    'enable','on',...
    'tag','GroupListBox',...
    'Items',{'Start a new project...'},...
    'ValueChangedFcn',@ChangeActiveGroup,...
    'BackgroundColor',[1 1 1],...
    'FontColor',[0 0 0],...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'MultiSelect','Off');

Handles.ImageSelectorPanel = uipanel(Handles.SelectorGrid,'Title','Image Selection','Visible','Off');
Handles.ImageSelectorPanelGrid = uigridlayout(Handles.ImageSelectorPanel,[1,1],'Padding',[0 0 0 0]);
Handles.ImageSelector = uilistbox('parent',Handles.ImageSelectorPanelGrid,...
    'Visible','Off',...
    'enable','on',...
    'tag','ImageListBox',...
    'Items',{'Select group to view its images...'},...
    'ValueChangedFcn',@ChangeActiveImage,...
    'BackgroundColor',[1 1 1],...
    'FontColor',[0 0 0],...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'MultiSelect','on',...
    'Visible','Off');

Handles.ObjectSelectorPanel = uipanel(Handles.SelectorGrid,'Title','Object Selection','Visible','Off');
Handles.ObjectSelectorPanelGrid = uigridlayout(Handles.ObjectSelectorPanel,[1,1],'Padding',[0 0 0 0]);
Handles.ObjectSelector = uilistbox('parent',Handles.ObjectSelectorPanelGrid,...
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
    'Visible','Off');

%% CHECKPOINT

disp('    Interactive thresholding tab group...')

%% Interactive User Thresholding

% axes to show intensity histogram
Handles.ThreshAxH = uiaxes(Handles.SettingsPanel,...
    'Units','Normalized',...
    'OuterPosition',[0 0 1 1],...
    'Color',[0 0 0],...
    'Visible','Off',...
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
disableDefaultInteractivity(Handles.ThreshAxH);
% graphics/display sometimes unpredictable when toolbar is visible, let's turn it off
Handles.ThreshAxH.Toolbar.Visible = 'Off';
% generate some random data (1024x1024) for histogram placeholder
RandomData = rand(1024,1024);
% build histogram from random data
[IntensityBinCenters,IntensityHistPlot] = BuildHistogram(RandomData);
% add histogram info to bar plot, place plot in thresholding axes
Handles.ThreshBar = bar(Handles.ThreshAxH,IntensityBinCenters,IntensityHistPlot,...
    'FaceColor','Yellow',...
    'EdgeColor','None',...
    'PickableParts','None');
% vertical line with draggable behavior for interactive thresholding
Handles.CurrentThresholdLine = xline(Handles.ThreshAxH,0.5,'-',{'Threshold = 0.5'},...
    'Tag','CurrentThresholdLine',...
    'LabelOrientation','Horizontal',...
    'PickableParts','None',...
    'HitTest','Off',...
    'FontName',PODSData.Settings.DefaultFont,...
    'FontWeight','Bold',...
    'LineWidth',1.5,...
    'Color',[1 1 0],...
    'LabelVerticalAlignment','Middle');

drawnow
pause(0.1)

%% Intensity display limits range sliders

Handles.PrimaryIntensitySlider = RangeSlider('Parent',Handles.SettingsPanel,...
        'Position',[0 0.5 1 0.5],...
        'Visible','Off',...
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
        'LabelColor','Black',...
        'LabelBGColor',[1 1 1 0.5],...
        'TickColor','White');

Handles.PrimaryIntensitySlider.ValueChangedFcn = @AdjustPrimaryChannelIntensity;

Handles.ReferenceIntensitySlider = RangeSlider('Parent',Handles.SettingsPanel,...
        'Position',[0 0 1 0.5],...
        'Visible','Off',...
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
        'LabelColor','Black',...
        'LabelBGColor',[1 1 1 0.5],...
        'TickColor','White');

Handles.ReferenceIntensitySlider.ValueChangedFcn = @AdjustReferenceChannelIntensity;

%% CHECKPOINT

disp('Setting up log window...')

%% Log Window
Handles.LogWindowGrid = uigridlayout(Handles.LogPanel,[1,1],'BackgroundColor',[0 0 0],'Padding',[0 0 0 0]);
Handles.LogWindow = uitextarea(Handles.LogWindowGrid,...
    'HorizontalAlignment','left',...
    'enable','on',...
    'tag','LogWindow',...
    'BackgroundColor','black',...
    'FontColor','yellow',...
    'FontName',PODSData.Settings.DefaultFont,...
    'Value',{''},...
    'Visible','Off');

%% CHECKPOINT

disp('Setting up summary table...')

%% Summary table for current group/image/object
Handles.ProjectDataTableGrid = uigridlayout(Handles.AppInfoPanel,[1,1],'BackgroundColor',[0 0 0],'Padding',[10 10 10 10]);
Handles.ProjectDataTable = uilabel(Handles.ProjectDataTableGrid,...
    'tag','ProjectDataTable',...
    'FontColor','Yellow',...
    'FontName',PODSData.Settings.DefaultFont,...
    'BackgroundColor','Black',...
    'VerticalAlignment','Top',...
    'Interpreter','html');

Handles.ProjectDataTable.Text = {['Start a new project first...']};

%% AXES AND IMAGE PLACEHOLDERS

% empty placeholder image
emptyimage = zeros(1024,1024);

AllSmallAxes = [];
AllLargeAxes = [];

%% CHECKPOINT

disp('Setting up small image axes...')

%% Small Images
    %% FLAT-FIELD IMAGES
for i = 1:4
    Handles.FFCAxH(i) = uiaxes('Parent',Handles.SmallPanels(1,i),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag',['FFC' num2str((i-1)*45)],...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = Handles.FFCAxH(i).PlotBoxAspectRatio;
    tagOriginal = Handles.FFCAxH(i).Tag;
    % place placeholder image on axis
    Handles.FFCImgH(i) = imshow(full(emptyimage),'Parent',Handles.FFCAxH(i));
    % set a tag so our callback functions can find the image
    set(Handles.FFCImgH(i),'Tag',['FFCImage' num2str((i-1)*45)]);
    
    % restore original values after imshow() call
    Handles.FFCAxH(i) = restore_axis_defaults(Handles.FFCAxH(i),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    Handles.FFCAxH(i) = SetAxisTitle(Handles.FFCAxH(i),['Flat-Field Image (' num2str((i-1)*45) '^{\circ} Excitation)']);
    Handles.FFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
    Handles.FFCImgH(i).HitTest = 'Off';
    
    disableDefaultInteractivity(Handles.FFCAxH(i));
end

Handles.AllSmallAxes = Handles.FFCAxH;

    %% RAW INTENSITY IMAGES
for i = 1:4
    Handles.RawIntensityAxH(i) = uiaxes('Parent',Handles.SmallPanels(2,i),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag',['Raw' num2str((i-1)*45)],...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = Handles.RawIntensityAxH(i).PlotBoxAspectRatio;
    tagOriginal = Handles.RawIntensityAxH(i).Tag;
    % place placeholder image on axis
    Handles.RawIntensityImgH(i) = imshow(full(emptyimage),'Parent',Handles.RawIntensityAxH(i));
    % set a tag so our callback functions can find the image
    set(Handles.RawIntensityImgH(i),'Tag',['RawImage' num2str((i-1)*45)]);
    
    % restore original values after imshow() call
    Handles.RawIntensityAxH(i) = restore_axis_defaults(Handles.RawIntensityAxH(i),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    Handles.RawIntensityAxH(i) = SetAxisTitle(Handles.RawIntensityAxH(i),['Raw Intensity (' num2str((i-1)*45) '^{\circ} Excitation)']);
    Handles.RawIntensityAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
    Handles.RawIntensityImgH(i).HitTest = 'Off';
    
    disableDefaultInteractivity(Handles.RawIntensityAxH(i));
    Handles.AllSmallAxes(end+1) = Handles.RawIntensityAxH(i);
end

    %% FLAT-FIELD CORRECTED INTENSITY
for i = 1:4
    Handles.PolFFCAxH(i) = uiaxes('Parent',Handles.SmallPanels(2,i),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag',['PolFFC' num2str((i-1)*45)],...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = Handles.PolFFCAxH(i).PlotBoxAspectRatio;
    tagOriginal = Handles.PolFFCAxH(i).Tag;
    % place placeholder image on axis
    Handles.PolFFCImgH(i) = imshow(full(emptyimage),'Parent',Handles.PolFFCAxH(i));
    % set a tag so our callback functions can find the image
    set(Handles.PolFFCImgH(i),'Tag',['PolFFCImage' num2str((i-1)*45)]);
    
    % restore original values after imshow() call
    Handles.PolFFCAxH(i) = restore_axis_defaults(Handles.PolFFCAxH(i),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    Handles.PolFFCAxH(i) = SetAxisTitle(Handles.PolFFCAxH(i),['Flat-Field Corrected Intensity (' num2str((i-1)*45) '^{\circ} Excitation)']);
    
    Handles.PolFFCAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
    Handles.PolFFCAxH(i).Toolbar.Visible = 'Off';
    Handles.PolFFCAxH(i).Title.Visible = 'Off';
    Handles.PolFFCAxH(i).HitTest = 'Off';
    disableDefaultInteractivity(Handles.PolFFCAxH(i));
    
    Handles.PolFFCImgH(i).Visible = 'Off';
    Handles.PolFFCImgH(i).HitTest = 'Off';

    Handles.AllSmallAxes(end+1) = Handles.PolFFCAxH(i);
end

    %% MASKING STEPS
for i = 1:4
    switch i
        case 1
            Handles.MStepsAxH(i) = uiaxes('Parent',Handles.SmallPanels(1,1),...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],...
                'Tag','MStepsIntensity',...
                'XTick',[],...
                'YTick',[]);
            image_title = 'Average Intensity';
            image_tag = 'MStepsIntensityImage';
        case 2
            Handles.MStepsAxH(i) = uiaxes('Parent',Handles.SmallPanels(1,2),...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],...
                'Tag','MStepsBackground',...
                'XTick',[],...
                'YTick',[]);
            image_title = 'Background Intensity';
            image_tag = 'MStepsBackgroundImage';
        case 3
            Handles.MStepsAxH(i) = uiaxes('Parent',Handles.SmallPanels(2,1),...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],...
                'Tag','MStepsBGSubtracted',...
                'XTick',[],...
                'YTick',[]);
            image_title = 'Background Subtracted Intensity';
            image_tag = 'MStepsBGSubtractedImage';
        case 4
            Handles.MStepsAxH(i) = uiaxes('Parent',Handles.SmallPanels(2,2),...
                'Units','Normalized',...
                'InnerPosition',[0 0 1 1],...
                'Tag','MStepsMedianFiltered',...
                'XTick',[],...
                'YTick',[]);
            image_title = 'Median Filtered';
            image_tag = 'MStepsMedianFilteredImage';
    end
    
    % save original values
    pbarOriginal = Handles.MStepsAxH(i).PlotBoxAspectRatio;
    tagOriginal = Handles.MStepsAxH(i).Tag;
    % place placeholder image on axis
    Handles.MStepsImgH(i) = imshow(full(emptyimage),'Parent',Handles.MStepsAxH(i));
    % set a tag so our callback functions can find the image
    set(Handles.MStepsImgH(i),'Tag',image_tag);
    
    % restore original values after imshow() call
    Handles.MStepsAxH(i) = restore_axis_defaults(Handles.MStepsAxH(i),pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    Handles.MStepsAxH(i) = SetAxisTitle(Handles.MStepsAxH(i),image_title);
    
    Handles.MStepsAxH(i).Colormap = PODSData.Settings.IntensityColormaps{1};
    Handles.MStepsAxH(i).Toolbar.Visible = 'Off';
    Handles.MStepsAxH(i).Title.Visible = 'Off';
    Handles.MStepsAxH(i).HitTest = 'Off';
    disableDefaultInteractivity(Handles.PolFFCAxH(i));
    
    Handles.MStepsImgH(i).Visible = 'Off';

    Handles.AllSmallAxes(end+1) = Handles.MStepsAxH(i);
end

%% CHECKPOINT

disp('Setting up large image axes...')

    %% AVERAGE INTENSITY
    Handles.AverageIntensityAxH = uiaxes(Handles.ImgPanel1,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','AverageIntensity',...
        'XTick',[],...
        'YTick',[]);
    % save original values to be restored after calling imshow()
    pbarOriginal = Handles.AverageIntensityAxH.PlotBoxAspectRatio;
    tagOriginal = Handles.AverageIntensityAxH.Tag;
    % place placeholder image on axis
    Handles.AverageIntensityImgH = imshow(full(emptyimage),'Parent',Handles.AverageIntensityAxH);
    % set a tag so our callback functions can find the image
    set(Handles.AverageIntensityImgH,'Tag','AverageIntensityImage');
    
    % restore original values after imshow() call
    Handles.AverageIntensityAxH = restore_axis_defaults(Handles.AverageIntensityAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    Handles.AverageIntensityAxH = SetAxisTitle(Handles.AverageIntensityAxH,'Average Intensity (Flat-Field Corrected)');
    % set celormap
    Handles.AverageIntensityAxH.Colormap = PODSData.Settings.IntensityColormaps{1};
    % hide axes toolbar and title, turn off hittest
    Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
    Handles.AverageIntensityAxH.Title.Visible = 'Off';
    Handles.AverageIntensityAxH.HitTest = 'Off';
    disableDefaultInteractivity(Handles.AverageIntensityAxH);
    % hide/diable image
    Handles.AverageIntensityImgH.Visible = 'Off';
    Handles.AverageIntensityImgH.HitTest = 'Off';

    %% Order Factor

    Handles.OrderFactorAxH = uiaxes(Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','OrderFactor',...
        'XTick',[],...
        'YTick',[],...
        'CLim',[0 1]);
    % save original values to be restored after calling imshow()
    pbarOriginal = Handles.OrderFactorAxH.PlotBoxAspectRatio;
    tagOriginal = Handles.OrderFactorAxH.Tag;
    % place placeholder image on axis
    Handles.OrderFactorImgH = imshow(full(emptyimage),'Parent',Handles.OrderFactorAxH);
    % set a tag so our callback functions can find the image
    set(Handles.OrderFactorImgH,'Tag','OrderFactorImage');
    % restore original values after imshow() call
    Handles.OrderFactorAxH = restore_axis_defaults(Handles.OrderFactorAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    Handles.OrderFactorAxH = SetAxisTitle(Handles.OrderFactorAxH,'Pixel-by-pixel Order Factor');
    % change active axis so we can make custom colorbar/colormap
    %axes(Handles.OrderFactorAxH)
    % custom colormap/colorbar
    %[mycolormap,mycolormap_noblack] = MakeRGB;
    Handles.OFCbar = colorbar(Handles.OrderFactorAxH,'location','east','color','white','tag','OFCbar');
    Handles.OrderFactorAxH.Colormap = PODSData.Settings.OrderFactorColormap;
    
    Handles.OFCbar.Visible = 'Off';
    Handles.OFCbar.HitTest = 'Off';
    
    Handles.OrderFactorAxH.Toolbar.Visible = 'Off';
    Handles.OrderFactorAxH.Title.Visible = 'Off';
    Handles.OrderFactorAxH.HitTest = 'Off';
    disableDefaultInteractivity(Handles.OrderFactorAxH);
    
    Handles.OrderFactorImgH.Visible = 'Off';
    Handles.OrderFactorImgH.HitTest = 'Off';
    
    %% Axis for swarm plots

    Handles.SwarmPlotAxH = uiaxes(Handles.ImgPanel2,...
        'Units','Normalized',...
        'OuterPosition',[0 0 1 1],...
        'Tag','SwarmPlotAxes',...
        'XTick',[],...
        'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0],...
        'NextPlot','Add',...
        'Visible','Off',...
        'Color','Black',...
        'XColor','Yellow',...
        'YColor','Yellow',...
        'HitTest','Off');
    
    disableDefaultInteractivity(Handles.SwarmPlotAxH);
    % set axis title
    Handles.SwarmPlotAxH = SetAxisTitle(Handles.SwarmPlotAxH,'Object OF (per group)');
    
    Handles.SwarmPlotAxH.XAxis.Label.String = "Group";
    Handles.SwarmPlotAxH.XAxis.Label.Color = 'Yellow';
    Handles.SwarmPlotAxH.XAxis.FontName = PODSData.Settings.DefaultFont;
    Handles.SwarmPlotAxH.YAxis.Label.String = "Object Order Factor";
    Handles.SwarmPlotAxH.YAxis.Label.Color = 'Yellow';
    Handles.SwarmPlotAxH.YAxis.FontName = PODSData.Settings.DefaultFont;
    Handles.SwarmPlotAxH.Toolbar.Visible = 'Off';

    Handles.SwarmPlotAxH.Title.Visible = 'Off';
    
    %% Axis for scatter plots

    Handles.ScatterPlotAxH = uiaxes(Handles.ImgPanel1,...
        'Units','Normalized',...
        'OuterPosition',[0 0 1 1],...
        'Tag','ScatterPlotAxes',...
        'XTick',[],...
        'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0],...
        'NextPlot','Add',...
        'Visible','Off',...
        'Color','Black',...
        'XColor','Yellow',...
        'YColor','Yellow',...
        'HitTest','Off');
    
    disableDefaultInteractivity(Handles.ScatterPlotAxH);
    % set axis title
    Handles.ScatterPlotAxH = SetAxisTitle(Handles.ScatterPlotAxH,'Object-Average OF vs Local S/B');
    
    Handles.ScatterPlotAxH.XAxis.Label.String = "Local S/B";
    Handles.ScatterPlotAxH.XAxis.Label.Color = 'Yellow';
    Handles.ScatterPlotAxH.XAxis.Label.FontName = PODSData.Settings.DefaultFont;
    Handles.ScatterPlotAxH.YAxis.Label.String = "Object-Average Order Factor";
    Handles.ScatterPlotAxH.YAxis.Label.Color = 'Yellow';
    Handles.ScatterPlotAxH.YAxis.Label.FontName = PODSData.Settings.DefaultFont;
    Handles.ScatterPlotAxH.Toolbar.Visible = 'Off';

    Handles.ScatterPlotAxH.Title.Visible = 'Off';

    %% MASK

    Handles.MaskAxH = uiaxes(Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','Mask',...
        'XTick',[],...
        'YTick',[]);
    % save original values to be restored after calling imshow()
    pbarOriginal = Handles.MaskAxH.PlotBoxAspectRatio;
    tagOriginal = Handles.MaskAxH.Tag;
    % place placeholder image on axis
    Handles.MaskImgH = imshow(full(emptyimage),'Parent',Handles.MaskAxH);
    % set a tag so our callback functions can find the image
    set(Handles.MaskImgH,'Tag','MaskImage');
    
    % restore original values after imshow() call
    Handles.MaskAxH = restore_axis_defaults(Handles.MaskAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    Handles.MaskAxH = SetAxisTitle(Handles.MaskAxH,'Binary Mask');
    
    Handles.MaskAxH.Toolbar.Visible = 'Off';
    Handles.MaskAxH.Title.Visible = 'Off';
    Handles.MaskAxH.HitTest = 'Off';
    disableDefaultInteractivity(Handles.MaskAxH);
    
    Handles.MaskImgH.Visible = 'Off';
    Handles.MaskImgH.HitTest = 'Off';
    
    %% SB FILTERED Order Factor
    % create an axis, child of a panel, to fill the container
    Handles.FilteredOFAxH = uiaxes(Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','FilteredOF',...
        'XTick',[],...
        'YTick',[]);
    % save original values to be restored after calling imshow()
    pbarOriginal = Handles.FilteredOFAxH.PlotBoxAspectRatio;
    tagOriginal = Handles.FilteredOFAxH.Tag;
    % place placeholder image on axis
    Handles.FilteredOFImgH = imshow(full(emptyimage),'Parent',Handles.FilteredOFAxH);
    % set a tag so our callback functions can find the image
    set(Handles.FilteredOFImgH,'Tag','FilteredOFImage');
    
    % restore original values after imshow() call
    Handles.FilteredOFAxH = restore_axis_defaults(Handles.FilteredOFAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    
    % set axis title
    Handles.FilteredOFAxH = SetAxisTitle(Handles.FilteredOFAxH,'SB-Filtered Order Factor');
    
    Handles.OFCbar2 = colorbar(Handles.FilteredOFAxH,'location','east','color','white','tag','OFCbar2');
    Handles.FilteredOFAxH.Colormap = PODSData.Settings.OrderFactorColormap;
    
    Handles.OFCbar2.Visible = 'Off';
    Handles.OFCbar2.HitTest = 'Off';
    
    Handles.FilteredOFAxH.Toolbar.Visible = 'Off';
    Handles.FilteredOFAxH.Title.Visible = 'Off';
    Handles.FilteredOFAxH.HitTest = 'Off';
    
    disableDefaultInteractivity(Handles.FilteredOFAxH);
    
    Handles.FilteredOFImgH.Visible = 'Off';
    Handles.FilteredOFImgH.HitTest = 'Off';
    
    %% Azimuth
    % create an axis, child of a panel, to fill the container
    Handles.AzimuthAxH = uiaxes(Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','AzimuthImage',...
        'XTick',[],...
        'YTick',[],...
        'Color','Black');
    % save original values to be restored after calling imshow()
    pbarOriginal = Handles.AzimuthAxH.PlotBoxAspectRatio;
    tagOriginal = Handles.AzimuthAxH.Tag;    
    % place placeholder image on axis
    Handles.AzimuthImgH = imshow(full(emptyimage),'Parent',Handles.AzimuthAxH);
    % set a tag so our callback functions can find the image
    set(Handles.AzimuthImgH,'Tag','AzimuthImage');
    % restore original values after imshow() call
    Handles.AzimuthAxH = restore_axis_defaults(Handles.AzimuthAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    % set axis title
    Handles.AzimuthAxH = SetAxisTitle(Handles.AzimuthAxH,'Pixel-by-pixel Azimuth');
    % change active axis so we can make custom colorbar/colormap
    %axes(Handles.AzimuthAxH)
    tempmap = hsv;
    %colormap(gca,vertcat(tempmap,tempmap));
    
    Handles.AzimuthAxH.Colormap = vertcat(tempmap,tempmap);
    % custom colormap/colorbar
    Handles.PhaseBarAxH = phasebarmod('rad','Location','se','axes',Handles.AzimuthAxH);
    Handles.PhaseBarAxH.Toolbar.Visible = 'Off';
    Handles.PhaseBarAxH.HitTest = 'Off';
    Handles.PhaseBarAxH.PickableParts = 'None';
    Handles.PhaseBarComponents = Handles.PhaseBarAxH.Children;
    set(Handles.PhaseBarComponents,'Visible','Off');
    Handles.PhaseBarAxH.Colormap = vertcat(tempmap,tempmap);
    %colormap(gca,vertcat(tempmap,tempmap));

    Handles.AzimuthAxH.YDir = 'Reverse';
    Handles.AzimuthAxH.Visible = 'Off';
    Handles.AzimuthAxH.Title.Visible = 'Off';
    Handles.AzimuthAxH.Title.Color = 'White';    
    Handles.AzimuthAxH.Toolbar.Visible = 'Off';
    Handles.AzimuthAxH.HitTest = 'Off';
    disableDefaultInteractivity(Handles.AzimuthAxH);

    Handles.AzimuthImgH.Visible = 'Off';
    Handles.AzimuthImgH.HitTest = 'Off';

%% CHECKPOINT

disp('Setting up object image axes...')
    
    %% Object FFCIntensity Image
    
    Handles.ObjectPolFFCAxH = uiaxes(Handles.SmallPanels(1,1),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectPolFFC',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = Handles.ObjectPolFFCAxH.PlotBoxAspectRatio;
    tagOriginal = Handles.ObjectPolFFCAxH.Tag;
    % place placeholder image on axis
    Handles.ObjectPolFFCImgH = imshow(full(emptyimage),'Parent',Handles.ObjectPolFFCAxH);
    % set a tag so our callback functions can find the image
    set(Handles.ObjectPolFFCImgH,'Tag','ObjectPolFFCImage');
    % restore original values after imshow() call
    Handles.ObjectPolFFCAxH = restore_axis_defaults(Handles.ObjectPolFFCAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    Handles.ObjectPolFFCAxH = SetAxisTitle(Handles.ObjectPolFFCAxH,'Flat-Field-Corrected Average Intensity');
    Handles.ObjectPolFFCAxH.Colormap = PODSData.Settings.IntensityColormaps{1};
    Handles.ObjectPolFFCAxH.Toolbar.Visible = 'Off';
    Handles.ObjectPolFFCAxH.Title.Visible = 'Off';
    Handles.ObjectPolFFCAxH.HitTest = 'Off';
    disableDefaultInteractivity(Handles.ObjectPolFFCAxH);
    
    Handles.ObjectPolFFCImgH.Visible = 'Off';
    Handles.ObjectPolFFCImgH.HitTest = 'Off';
    
    %% Object Binary Image
    
    Handles.ObjectMaskAxH = uiaxes(Handles.SmallPanels(1,2),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectMask',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = Handles.ObjectMaskAxH.PlotBoxAspectRatio;
    tagOriginal = Handles.ObjectMaskAxH.Tag;
    % place placeholder image on axis
    Handles.ObjectMaskImgH = imshow(full(emptyimage),'Parent',Handles.ObjectMaskAxH);
    % set a tag so our callback functions can find the image
    set(Handles.ObjectMaskImgH,'Tag','ObjectMaskImage');
    % restore original values after imshow() call
    Handles.ObjectMaskAxH = restore_axis_defaults(Handles.ObjectMaskAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    Handles.ObjectMaskAxH = SetAxisTitle(Handles.ObjectMaskAxH,'Object Binary Image');
    Handles.ObjectMaskAxH.Title.Visible = 'Off';
    Handles.ObjectMaskAxH.Toolbar.Visible = 'Off';
    Handles.ObjectMaskAxH.HitTest = 'Off';
    disableDefaultInteractivity(Handles.ObjectMaskAxH);
    
    Handles.ObjectMaskImgH.Visible = 'Off';
    Handles.ObjectMaskImgH.HitTest = 'Off';
    
    %% Object Order Factor Contour
    
    Handles.ObjectOFContourAxH = uiaxes(Handles.SmallPanels(2,2),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectContour',...
        'Color','Black',...
        'XColor','White',...
        'YColor','White',...
        'ZColor','White',...
        'CLim',[0 1],...
        'XTick',[],...
        'YTick',[]);
    
    SetAxisTitle(Handles.ObjectOFContourAxH,'OF 2D Contour');
    Handles.ObjectOFContourAxH.Colormap = PODSData.Settings.OrderFactorColormap;
    %colormap(gca,OrderFactorMap);
    
    Handles.ObjectOFContourAxH.YDir = 'Reverse';
    Handles.ObjectOFContourAxH.Visible = 'Off';
    Handles.ObjectOFContourAxH.HitTest = 'Off';
    disableDefaultInteractivity(Handles.ObjectOFContourAxH);
    Handles.ObjectOFContourAxH.Toolbar.Visible = 'Off';
    Handles.ObjectOFContourAxH.Title.Visible = 'Off';
    Handles.ObjectOFContourAxH.Title.Color = 'White';
    
    %% Object OF Image
    
    Handles.ObjectOFAxH = uiaxes(Handles.SmallPanels(2,1),...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','ObjectOF',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = Handles.ObjectOFAxH.PlotBoxAspectRatio;
    tagOriginal = Handles.ObjectOFAxH.Tag;
    % place placeholder image on axis
    Handles.ObjectOFImgH = imshow(full(emptyimage),'Parent',Handles.ObjectOFAxH);
    % set a tag so our callback functions can find the image
    set(Handles.ObjectOFImgH,'Tag','ObjectOFImage');
    % restore original values after imshow() call
    Handles.ObjectOFAxH = restore_axis_defaults(Handles.ObjectOFAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    Handles.ObjectOFAxH = SetAxisTitle(Handles.ObjectOFAxH,'Object OF Image');
    
    Handles.ObjectOFAxH.Colormap = PODSData.Settings.OrderFactorColormap;
    
    Handles.ObjectOFAxH.Title.Visible = 'Off';
    Handles.ObjectOFAxH.Toolbar.Visible = 'Off';
    Handles.ObjectOFAxH.HitTest = 'Off';
    disableDefaultInteractivity(Handles.ObjectOFAxH);
    
    Handles.ObjectOFImgH.Visible = 'Off';
    Handles.ObjectOFImgH.HitTest = 'Off';
    
    %% Object Intensity Fit Plots
    
    Handles.ObjectIntensityPlotAxH = uiaxes(Handles.ImgPanel2,...
        'Visible','Off',...
        'Units','Normalized',...
        'OuterPosition',[0 0 1 0.75],...
        'Tag','ObjectIntensityPlotAxH',...
        'NextPlot','Add',...
        'Color','Black',...
        'Box','On',...
        'XColor','Yellow',...
        'YColor','Yellow',...
        'BoxStyle','Back',...
        'HitTest','Off',...
        'XLim',[0 pi],...
        'XTick',[0 pi/4 pi/2 3*pi/4 pi],...
        'XTickLabel',{'0°' '45°' '90°' '135°' '180°'});
    Handles.ObjectIntensityPlotAxH.Title.String = 'Pixel-normalized intensitites fit to sinusoids';
    Handles.ObjectIntensityPlotAxH.Title.Color = 'Yellow';
    Handles.ObjectIntensityPlotAxH.Title.FontName = PODSData.Settings.DefaultFont;
    Handles.ObjectIntensityPlotAxH.Title.HorizontalAlignment = 'Center';
    Handles.ObjectIntensityPlotAxH.Title.VerticalAlignment = 'Top';
    
    Handles.ObjectIntensityPlotAxH.XAxis.Label.String = "Excitation polarization (°)";
    Handles.ObjectIntensityPlotAxH.XAxis.Label.Color = [1 1 0];
    Handles.ObjectIntensityPlotAxH.YAxis.Label.String = "Normalized emission intensity (A.U.)";
    Handles.ObjectIntensityPlotAxH.YAxis.Label.Color = [1 1 0];    
    
    disableDefaultInteractivity(Handles.ObjectIntensityPlotAxH);
    
    %% Object Stack-Normalized Intensity Stack
    
    Handles.ObjectNormIntStackAxH = uiaxes(Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0.75 1 0.25],...
        'Tag','ObjectNormIntStack',...
        'XTick',[],...
        'YTick',[]);
    % save original values
    pbarOriginal = Handles.ObjectNormIntStackAxH.PlotBoxAspectRatio;
    tagOriginal = Handles.ObjectNormIntStackAxH.Tag;
    % place placeholder image on axis
    emptysz = size(emptyimage);
    Handles.ObjectNormIntStackImgH = imshow(full(emptyimage(1:emptysz(1)*0.25,1:end)),'Parent',Handles.ObjectNormIntStackAxH);
    % set a tag so our callback functions can find the image
    set(Handles.ObjectNormIntStackImgH,'Tag','ObjectNormIntStack');
    % restore original values after imshow() call
    Handles.ObjectNormIntStackAxH = restore_axis_defaults(Handles.ObjectNormIntStackAxH,pbarOriginal,tagOriginal);
    clear pbarOriginal tagOriginal
    Handles.ObjectNormIntStackAxH = SetAxisTitle(Handles.ObjectNormIntStackAxH,'Stack-Normalized Object Intensity');
    Handles.ObjectNormIntStackAxH.Colormap = PODSData.Settings.IntensityColormaps{1};
    Handles.ObjectNormIntStackAxH.Title.Visible = 'Off';
    Handles.ObjectNormIntStackAxH.Toolbar.Visible = 'Off';
    disableDefaultInteractivity(Handles.ObjectNormIntStackAxH);
    
    Handles.ObjectNormIntStackImgH.Visible = 'Off';    
    Handles.ObjectNormIntStackImgH.HitTest = 'Off';
    
%% Turning on important containers

set(Handles.AppInfoPanel,'Visible','On');
set(Handles.SettingsPanel,'Visible','On');
set(Handles.ThreshAxH,'Visible','On');
set(Handles.SettingsSelectorPanel,'Visible','On');
set(Handles.SettingsSelector,'Visible','On');

set(Handles.LogPanel,'Visible','On');
set(Handles.LogWindow,'Visible','On');

set(Handles.SmallPanels,'Visible','On');

set(Handles.GroupSelectorPanel,'Visible','On');
set(Handles.GroupSelector,'Visible','On');
set(Handles.ImageSelectorPanel,'Visible','On');
set(Handles.ImageSelector,'Visible','On');
set(Handles.ObjectSelectorPanel,'Visible','On');
set(Handles.ObjectSelector,'Visible','On');

Handles.LineScanROI = [];
Handles.LineScanFig = [];
Handles.LineScanPlot = [];

PODSData.Handles = Handles;
guidata(PODSData.Handles.fH,PODSData)
% set figure to visible to draw containers
PODSData.Handles.fH.Visible = 'On';
drawnow
pause(0.5)

%% Azimuth display settings

    function [] = SetAzimuthDisplaySettings(source,event)
        fHAzimuthDisplaySettings = openfig('AzimuthDisplaySettings.fig');
        waitfor(fHAzimuthDisplaySettings);
        PODSData.Settings.UpdateAzimuthDisplaySettings();
        UpdateImages(source);
    end

%% Swarmchart settings

    function [] = SetSwarmChartSettings(source,event)
        fHSwarmChartSettings = openfig('SwarmChartSettings.fig');
        waitfor(fHSwarmChartSettings);
        PODSData.Settings.UpdateSwarmChartSettings();
        UpdateImages(source);
    end

%% Scatterplot settings

    function [] = SetScatterPlotSettings(source,event)
        fHScatterPlotSettings = openfig('ScatterPlotSettings.fig');
        waitfor(fHScatterPlotSettings);
        PODSData.Settings.UpdateScatterPlotSettings();
        UpdateImages(source);        
    end

%% Colormap settings

    function [] = SetColormapsSettings(source,event)
        fHColormapsSettings = openfig('ColormapsSettings.fig');
        waitfor(fHColormapsSettings);
        PODSData.Settings.UpdateColormapsSettings();
        UpdateImages(source);
    end

%% Callbacks controlling dynamic resizing of GUI containers

    function [] = ResetContainerSizes(source,event)
        disp('Figure Window Size Changed...');
        
        SmallWidth = round((source.InnerPosition(3)*0.38)/2);
        % update grid size to maatch new image sizes
        PODSData.Handles.MainGrid.RowHeight = {'0.5x',SmallWidth,SmallWidth,'0.3x'};
        PODSData.Handles.MainGrid.ColumnWidth = {'1x',SmallWidth,SmallWidth,SmallWidth,SmallWidth};
        drawnow limitrate

    end

    function [] = LogPanelSizeChanged(source,event)
        %drawnow
        %set(Handles.LogWindow,'Position',[1 1 Handles.LogPanel.InnerPosition(3) Handles.LogPanel.InnerPosition(4)]);
    end

    function [] = ImgOperationsTabGroupSizeChanged(source,event)
        
        %set(Handles.ThreshAxH,'Position',[0 0 1 1]);
    end

    function [] = AppInfoPanelSizeChanged(source,event)
        
        set(Handles.ProjectDataTable,'Position',[10 10 Handles.AppInfoPanel.InnerPosition(3)-20 Handles.AppInfoPanel.InnerPosition(4)-20]);
    end

%% Callbacks for interactive thresholding
% Set figure callbacks WindowButtonMotionFcn and WindowButtonUpFcn
    function [] = StartUserThresholding(source,event)
        Handles.fH.WindowButtonMotionFcn = @MoveThresholdLine;
        Handles.fH.WindowButtonUpFcn = @StopMovingAndSetThresholdLine;
    end
% Update display while thresh line is moving
    function [] = MoveThresholdLine(source,event)
        Handles.CurrentThresholdLine.Value = round(Handles.ThreshAxH.CurrentPoint(1,1),4);
        Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
        %drawnow limitrate
        %testing below
        ThresholdLineMoving(source,Handles.CurrentThresholdLine.Value);
        drawnow limitrate
    end
% Set final thresh position and restore callbacks
    function [] = StopMovingAndSetThresholdLine(source,event)
        Handles.CurrentThresholdLine.Value = round(Handles.ThreshAxH.CurrentPoint(1,1),4);
        Handles.CurrentThresholdLine.Label = {['Threshold = ',num2str(Handles.CurrentThresholdLine.Value)]};
        Handles.fH.WindowButtonMotionFcn = '';
        Handles.fH.WindowButtonUpFcn = '';
        ThresholdLineMoved(source,Handles.CurrentThresholdLine.Value);
        drawnow limitrate
    end

%% Callbacks for intensity display scaling

    function [] = AdjustPrimaryChannelIntensity(source,event)
        PODSData.CurrentImage(1).PrimaryIntensityDisplayLimits = source.Value;
        
        if PODSData.CurrentImage(1).ReferenceImageLoaded & Handles.ShowReferenceImageAverageIntensity.Value
            UpdateCompositeRGB();
        else
            Handles.AverageIntensityAxH.CLim = source.Value;
        end
    end

    function [] = AdjustReferenceChannelIntensity(source,event)
        PODSData.CurrentImage(1).ReferenceIntensityDisplayLimits = source.Value;
        
        if PODSData.CurrentImage(1).ReferenceImageLoaded & Handles.ShowReferenceImageAverageIntensity.Value
            UpdateCompositeRGB();
        end
    end

    function UpdateCompositeRGB()
        Handles.AverageIntensityImgH.CData = ...
            CompositeRGB(PODSData.CurrentImage(1).I,...
            PODSData.Settings.IntensityColormaps{1},...
            PODSData.CurrentImage(1).PrimaryIntensityDisplayLimits,...
            Scale0To1(PODSData.CurrentImage(1).ReferenceImage),...
            PODSData.Settings.ReferenceColormap,...
            PODSData.CurrentImage(1).ReferenceIntensityDisplayLimits);
        Handles.AverageIntensityAxH.CLim = [0 255];
    end

%% Settings axes properties during startup (to be eventually replaced with custom container classes)

    function [axH] = restore_axis_defaults(axH,OriginalPlotBoxAspectRatio,OriginalTag)
        % restore axis defaults that were changed by imshow()
        axH.YDir = 'reverse';
        axH.PlotBoxAspectRatioMode = 'manual';
        %axH.DataAspectRatioMode = 'auto';
        axH.PlotBoxAspectRatio = OriginalPlotBoxAspectRatio;
        axH.XTick = [];
        axH.YTick = [];
        axH.Tag = OriginalTag;
        
        tb = axtoolbar(axH,{});
        
        % add relevant custom toolbars to specific axes
        switch axH.Tag
            case 'Mask'
                addZoomToCursorToolbarBtn;
                addRemoveObjectsToolbarBtn;
                addShowSelectionToolbarBtn;
                addRectangularROIToolbarBtn;
            case 'OrderFactor'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
            case 'AverageIntensity'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
                addShowSelectionToolbarBtn;
                addRectangularROIToolbarBtn;
                addShowReferenceImageToolbarBtn;
                addLineScanToolbarBtn;
            case 'MStepsIntensity'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
            case 'MStepsBackground'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
            case 'MStepsBGSubtracted'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
            case 'MStepsMedianFiltered'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
            case 'AzimuthImage'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
        end
        
        % Adding custom toolbar to allow ZoomToCursor
        function addZoomToCursorToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MagnifyingGlassBlackAndYellow.png';
            btn.ValueChangedFcn = @ZoomToCursor;
        end
        
        function addApplyMaskToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MaskIcon.png';
            btn.ValueChangedFcn = @tbApplyMaskStateChanged;
            btn.Tag = ['ApplyMask',axH.Tag];
            Handles.(btn.Tag) = btn;
        end
        
        function addRemoveObjectsToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'RemoveObjects.png';
            btn.ButtonPushedFcn = @tbRemoveObjects;
            btn.Tag = ['RemoveObjects',axH.Tag];
            Handles.(btn.Tag) = btn;
        end
        
        function addShowSelectionToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ShowSelectionIcon.png';
            btn.ValueChangedFcn = @tbShowSelectionStateChanged;
            btn.Tag = ['ShowSelection',axH.Tag];
            Handles.(btn.Tag) = btn;
        end
        
        function addRectangularROIToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'RectangularROIIcon.png';
            btn.ButtonPushedFcn = @tbRectangularROI;
            btn.Tag = ['RectangularROI',axH.Tag];
            Handles.(btn.Tag) = btn;
        end
        
        function addShowReferenceImageToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'ShowReferenceImageIcon.png';
            btn.ValueChangedFcn = @tbShowReferenceImageStateChanged;
            btn.Tag = ['ShowReferenceImage',axH.Tag];
            Handles.(btn.Tag) = btn;
        end
        
        function addLineScanToolbarBtn;
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'LineScanIcon.png';
            btn.ButtonPushedFcn = @tbLineScan;
            btn.Tag = ['LineScan',axH.Tag];
            Handles.(btn.Tag) = btn;
        end
        
        
    end

    function [axH] = SetAxisTitle(axH,title)
        % Set image (actually axis) title to top center of axis
        axH.Title.String = title;
        axH.Title.Units = 'Normalized';
        axH.Title.FontName = PODSData.Settings.DefaultFont;
        axH.Title.HorizontalAlignment = 'Center';
        axH.Title.VerticalAlignment = 'Top';
        axH.Title.Color = 'White';
        axH.Title.Position = [0.5,1.0,0];
        axH.Title.BackgroundColor = [0 0 0 0.5];
        axH.Title.HitTest = 'Off';
    end

%% Tab Selection (uimenu callback)

    function [] = TabSelection(source,event)
        % current PODSData structure
        data = guidata(source);
        % the tab to switch to
        NewTab = source.Text;
        % the tab we switched from
        OldTab = data.Settings.CurrentTab;
        % indicate tab selection in log
        UpdateLog3(source,[NewTab, ' Tab Selected'],'append');
        % update GUI state to reflect new current/previous tabs
        data.Settings.PreviousTab = data.Settings.CurrentTab;
        data.Settings.CurrentTab = source.Text;

        switch data.Settings.PreviousTab % the tab we are switching from
            
            case 'Files'
                try
                    linkaxes(Handles.FFCAxH,'off');
                    linkaxes(Handles.RawIntensityAxH,'off');
                catch
                    % do nothing
                end
                
                for i = 1:4
                    Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(1,i);
                    
                    Handles.FFCImgH(i).Visible = 'Off';
                    Handles.FFCAxH(i).Title.Visible = 'Off';
                    Handles.FFCAxH(i).Toolbar.Visible = 'Off';
                    Handles.FFCAxH(i).HitTest = 'Off';
                    
                    Handles.RawIntensityImgH(i).Visible = 'Off';
                    Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                    Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
                    Handles.RawIntensityAxH(i).HitTest = 'Off';
                    
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'FFC'
                
                for i = 1:4
                    Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(2,i);
                    
                    Handles.PolFFCImgH(i).Visible = 'Off';
                    Handles.PolFFCAxH(i).Title.Visible = 'Off';
                    Handles.PolFFCAxH(i).Toolbar.Visible = 'Off';
                    Handles.PolFFCAxH(i).HitTest = 'Off';
                    
                    Handles.RawIntensityImgH(i).Visible = 'Off';
                    Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                    Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
                    Handles.RawIntensityAxH(i).HitTest = 'Off';
                    
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'Generate Mask'
                try
                    linkaxes([Handles.MStepsAxH,Handles.MaskAxH],'off');
                catch
                    % do nothing
                end

                Handles.MaskImgH.Visible = 'Off';
                Handles.MaskAxH.Title.Visible = 'Off';
                Handles.MaskAxH.Toolbar.Visible = 'Off';
                Handles.MaskAxH.HitTest = 'Off';
                
                % hide masking steps and small panels
                for i = 1:2
                    Handles.MStepsImgH(i).Visible = 'Off';
                    Handles.MStepsAxH(i).Title.Visible = 'Off';
                    Handles.MStepsAxH(i).Toolbar.Visible = 'Off';
                    Handles.MStepsAxH(i).HitTest = 'Off';
                    
                    Handles.MStepsImgH(i+2).Visible = 'Off';
                    Handles.MStepsAxH(i+2).Title.Visible = 'Off';
                    Handles.MStepsAxH(i+2).Toolbar.Visible = 'Off';
                    Handles.MStepsAxH(i+2).HitTest = 'Off';
                    
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'View/Adjust Mask'
                % link large AvgIntensityAxH and MaskAxH
                try
                    linkaxes([Handles.AverageIntensityAxH,Handles.MaskAxH],'off');
                catch
                    % do nothing
                end
                
                try
                    delete(PODSData.Handles.ObjectRectangles);
                end

                Handles.AverageIntensityImgH.Visible = 'Off';
                Handles.AverageIntensityAxH.Title.Visible = 'Off';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
                Handles.AverageIntensityAxH.HitTest = 'Off';
                
                Handles.MaskImgH.Visible = 'Off';
                Handles.MaskAxH.Title.Visible = 'Off';
                Handles.MaskAxH.Toolbar.Visible = 'Off';
                Handles.MaskAxH.HitTest = 'Off';
                
            case 'Order Factor'
                
                Handles.OrderFactorImgH.Visible = 'Off';
                Handles.OrderFactorAxH.Title.Visible = 'Off';
                Handles.OrderFactorAxH.Toolbar.Visible = 'Off';
                Handles.OrderFactorAxH.HitTest = 'Off';
                
                Handles.AverageIntensityImgH.Visible = 'Off';
                Handles.AverageIntensityAxH.Title.Visible = 'Off';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
                Handles.AverageIntensityAxH.HitTest = 'Off';
                
                Handles.ImgPanel1.Visible = 'Off';
                
                Handles.OFCbar.Visible = 'Off';
                
            case 'Azimuth'
                try
                    linkaxes([Handles.AverageIntensityAxH,Handles.AzimuthAxH],'off');
                end                
                try
                    delete(data.Handles.AzimuthLines);
                end
                
                set(Handles.PhaseBarComponents,'Visible','Off');
                
                Handles.AzimuthImgH.Visible = 'Off';
                Handles.AzimuthAxH.Title.Visible = 'Off';
                Handles.AzimuthAxH.Toolbar.Visible = 'Off';
                Handles.AzimuthAxH.HitTest = 'Off';
                
                Handles.AverageIntensityImgH.Visible = 'Off';
                Handles.AverageIntensityAxH.Title.Visible = 'Off';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
                Handles.AverageIntensityAxH.HitTest = 'Off';
                
            case 'Plots'

                try
                    delete(Handles.ScatterPlotAxH.Children)
                end
                
                Handles.ScatterPlotAxH.Legend.Visible = 'Off';
                Handles.ScatterPlotAxH.Title.Visible = 'Off';
                Handles.ScatterPlotAxH.Toolbar.Visible = 'Off';
                Handles.ScatterPlotAxH.Visible = 'Off';

                try
                    % hide the swarm plot
                    delete(Handles.SwarmPlotAxH.Children)
                end

                Handles.SwarmPlotAxH.Title.Visible = 'Off';
                Handles.SwarmPlotAxH.Toolbar.Visible = 'Off';
                Handles.SwarmPlotAxH.Visible = 'Off';

            case 'Filtered Order Factor'
                
                Handles.AverageIntensityImgH.Visible = 'Off';
                Handles.AverageIntensityAxH.Title.Visible = 'Off';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
                Handles.AverageIntensityAxH.HitTest = 'Off';                

                Handles.FilteredOFImgH.Visible = 'Off';
                Handles.FilteredOFAxH.Title.Visible = 'Off';
                Handles.FilteredOFAxH.Toolbar.Visible = 'Off';
                Handles.FilteredOFAxH.HitTest = 'Off';
                
                Handles.OFCbar2.Visible = 'Off';
                
            case 'View Objects'
                
                % delete the object OF contour plot
                try
                    delete(data.Handles.hObjectOFContour);
                end
                
                % delete the object intensity curves
                try
                    delete(Handles.ObjectIntensityPlotAxH.Children);
                end
                
                % object intensity image
                Handles.ObjectPolFFCAxH.Title.Visible = 'Off';
                Handles.ObjectPolFFCImgH.Visible = 'Off';
                
                % object mask image
                Handles.ObjectMaskAxH.Title.Visible = 'Off';
                Handles.ObjectMaskImgH.Visible = 'Off';
                
                % object 2D contour plot
                Handles.ObjectOFContourAxH.Title.Visible = 'Off';
                Handles.ObjectOFContourAxH.Visible = 'Off';
                
                Handles.ObjectOFAxH.Title.Visible = 'Off';
                Handles.ObjectOFImgH.Visible = 'Off';
                
                Handles.ObjectIntensityPlotAxH.Visible = 'Off';
                Handles.ObjectIntensityPlotAxH.Title.Visible = 'Off';
                
                Handles.ObjectNormIntStackImgH.Visible = 'Off';
                Handles.ObjectNormIntStackAxH.Title.Visible = 'Off';                
                
                Handles.ImgPanel2.Visible = 'Off';
                
                for i = 1:2
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end                
         
        end
        
        switch data.Settings.CurrentTab % the tab we are switching to
            case 'Files'
                
                for i = 1:4
                    Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(2,i);
                    
                    Handles.RawIntensityImgH(i).Visible = 'On';
                    Handles.RawIntensityAxH(i).Title.Visible = 'On';
                    Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';
                    Handles.RawIntensityAxH(i).HitTest = 'On';
                    
                    Handles.FFCImgH(i).Visible = 'On';
                    Handles.FFCAxH(i).Title.Visible = 'On';
                    Handles.FFCAxH(i).Toolbar.Visible = 'On';
                    Handles.FFCAxH(i).HitTest = 'On';
                    
                    Handles.SmallPanels(1,i).Visible = 'On';
                    Handles.SmallPanels(2,i).Visible = 'On';
                end
                Handles.ImgPanel1.Visible = 'Off';
                Handles.ImgPanel2.Visible = 'Off';
                
            case 'FFC'
                
                for i = 1:4
                    Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(1,i);
                    
                    Handles.RawIntensityImgH(i).Visible = 'On';
                    Handles.RawIntensityAxH(i).Title.Visible = 'On';
                    Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';
                    Handles.RawIntensityAxH(i).HitTest = 'On';
                    
                    Handles.PolFFCImgH(i).Visible = 'On';
                    Handles.PolFFCAxH(i).Title.Visible = 'On';
                    Handles.PolFFCAxH(i).Toolbar.Visible = 'On';
                    Handles.PolFFCAxH(i).HitTest = 'On';
                    
                    Handles.SmallPanels(1,i).Visible = 'On';
                    Handles.SmallPanels(2,i).Visible = 'On';
                end
                Handles.ImgPanel1.Visible = 'Off';
                Handles.ImgPanel2.Visible = 'Off';
                
            case 'Generate Mask'
                
                Handles.MaskImgH.Visible = 'On';
                Handles.MaskAxH.Title.Visible = 'On';
                Handles.MaskAxH.Toolbar.Visible = 'On';
                
                Handles.ImgPanel1.Visible = 'Off';
                Handles.ImgPanel2.Visible = 'On';
                
                for i = 1:2
                    Handles.MStepsImgH(i).Visible = 'On';
                    Handles.MStepsAxH(i).Title.Visible = 'On';
                    Handles.MStepsAxH(i).Toolbar.Visible = 'On';
                    Handles.MStepsAxH(i).HitTest = 'On';
                    
                    Handles.MStepsImgH(i+2).Visible = 'On';
                    Handles.MStepsAxH(i+2).Title.Visible = 'On';
                    Handles.MStepsAxH(i+2).Toolbar.Visible = 'On';
                    Handles.MStepsAxH(i+2).HitTest = 'On';
                    
                    Handles.SmallPanels(1,i).Visible = 'On';
                    Handles.SmallPanels(2,i).Visible = 'On';
                    
                    Handles.SmallPanels(1,i+2).Visible = 'Off';
                    Handles.SmallPanels(2,i+2).Visible = 'Off';
                end

                linkaxes([Handles.MStepsAxH,Handles.MaskAxH],'xy');
                
            case 'View/Adjust Mask'
                Handles.ImgPanel1.Visible = 'On';
                Handles.ImgPanel2.Visible = 'On';
                
                Handles.AverageIntensityImgH.Visible = 'On';
                Handles.AverageIntensityAxH.Title.Visible = 'On';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
                Handles.AverageIntensityAxH.HitTest = 'On';

                Handles.MaskImgH.Visible = 'On';
                Handles.MaskAxH.Title.Visible = 'On';
                Handles.MaskAxH.Toolbar.Visible = 'On';
                Handles.MaskAxH.HitTest = 'On';
                
                for i = 1:4
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
                linkaxes([Handles.AverageIntensityAxH,Handles.MaskAxH],'xy');
                
            case 'Order Factor'
                
                Handles.OrderFactorImgH.Visible = 'On';
                Handles.OrderFactorAxH.Title.Visible = 'On';
                Handles.OrderFactorAxH.Toolbar.Visible = 'On';
                Handles.OrderFactorAxH.HitTest = 'On';
                
                Handles.AverageIntensityImgH.Visible = 'On';
                Handles.AverageIntensityAxH.Title.Visible = 'On';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
                Handles.AverageIntensityAxH.HitTest = 'On';
                
                Handles.ImgPanel2.Visible = 'On';
                Handles.ImgPanel1.Visible = 'On';
                
                Handles.OFCbar.Visible = 'On';
                
                for i = 1:4
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
                linkaxes([Handles.AverageIntensityAxH,Handles.OrderFactorAxH],'xy');
                
            case 'Azimuth'
                
                Handles.AzimuthImgH.Visible = 'On';
                Handles.AzimuthAxH.Title.Visible = 'On';
                Handles.AzimuthAxH.Toolbar.Visible = 'On';
                Handles.AzimuthAxH.HitTest = 'On';
                
                set(Handles.PhaseBarComponents,'Visible','On');
                
                Handles.AverageIntensityImgH.Visible = 'On';
                Handles.AverageIntensityAxH.Title.Visible = 'On';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
                Handles.AverageIntensityAxH.HitTest = 'On';
                
                Handles.ImgPanel1.Visible = 'On';
                Handles.ImgPanel2.Visible = 'On';
                
                for i = 1:4
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                try
                    linkaxes([Handles.AverageIntensityAxH,Handles.AzimuthAxH],'xy');
                end                
                
            case 'Plots'
                try
                    Handles.ScatterPlotAxH.Legend.Visible = 'On';
                end

                Handles.ScatterPlotAxH.Title.Visible = 'On';
                Handles.ScatterPlotAxH.Toolbar.Visible = 'On';
                Handles.ScatterPlotAxH.Visible = 'On';
                
                Handles.SwarmPlotAxH.Visible = 'On';
                Handles.SwarmPlotAxH.Title.Visible = 'On';
                Handles.SwarmPlotAxH.Toolbar.Visible = 'On';
                
                Handles.ImgPanel1.Visible = 'On';
                Handles.ImgPanel2.Visible = 'On';
                
                for i = 1:4
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'Filtered Order Factor'
                
                Handles.AverageIntensityImgH.Visible = 'On';
                Handles.AverageIntensityAxH.Title.Visible = 'On';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
                Handles.AverageIntensityAxH.HitTest = 'On';
                
                Handles.FilteredOFImgH.Visible = 'On';
                Handles.FilteredOFAxH.Title.Visible = 'On';
                Handles.FilteredOFAxH.Toolbar.Visible = 'On';
                Handles.FilteredOFAxH.HitTest = 'On';
                
                Handles.OFCbar2.Visible = 'On';
                
                Handles.ImgPanel1.Visible = 'On';
                Handles.ImgPanel2.Visible = 'On';
                
                for i = 1:4
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'View Objects'
                
                % object intensity image
                Handles.ObjectPolFFCAxH.Title.Visible = 'On';
                Handles.ObjectPolFFCImgH.Visible = 'On';
                
                % object binary image
                Handles.ObjectMaskAxH.Title.Visible = 'On';
                Handles.ObjectMaskImgH.Visible = 'On';
                
                % object 2D contour plot
                Handles.ObjectOFContourAxH.Title.Visible = 'On';
                Handles.ObjectOFContourAxH.Visible = 'On';
                
                Handles.ObjectOFAxH.Title.Visible = 'On';
                Handles.ObjectOFImgH.Visible = 'On';
                
                Handles.ObjectNormIntStackImgH.Visible = 'On';
                Handles.ObjectNormIntStackAxH.Title.Visible = 'On';               

                Handles.ObjectIntensityPlotAxH.Visible = 'On';
                Handles.ObjectIntensityPlotAxH.Title.Visible = 'On';
                
                Handles.ImgPanel2.Visible = 'On';
                
                for i = 1:2
                    Handles.SmallPanels(1,i).Visible = 'On';
                    Handles.SmallPanels(2,i).Visible = 'On';
                end
                
                Handles.ImgPanel1.Visible = 'Off';
                   
        end
        
        guidata(source,data);
        UpdateImages(source);
    end

%% 'Objects' menubar callbacks

    function [] = mbDeleteSelectedObjects(source,event)
        
        cGroup = PODSData.CurrentGroup;
        
        cGroup.DeleteSelectedObjects();
        
        UpdateImages(source);
        UpdateListBoxes(source);
        UpdateTables(source);
    end

    function [] = mbLabelSelectedObjects(source,event)
        
        CustomLabel = ChooseObjectLabel(source);
        
        for i = 1:PODSData.nGroups
            PODSData.Group(i,1).LabelSelectedObjects(CustomLabel);
        end
        
        UpdateImages(source);
        UpdateListBoxes(source);
        UpdateTables(source);
    end

    function [] = mbClearSelection(source,event)
        
        cGroup = PODSData.CurrentGroup;
        
        cGroup.ClearSelection();
        
        UpdateImages(source);
        UpdateListBoxes(source);
        UpdateTables(source);
    end

%% Changing file input settings

    function [] = ChangeInputFileType(source,event)
        OldInputFileType = PODSData.Settings.InputFileType;
        NewInputFileType = source.Text
        PODSData.Settings.InputFileType = NewInputFileType;
        UpdateLog3(source,['Input File Type Changed to ',NewInputFileType],'append');
        
        switch NewInputFileType
            case '.nd2'
                Handles.hFileInputType_nd2.Checked = 'On';
                Handles.hFileInputType_tif.Checked = 'Off';
            case '.tif'
                Handles.hFileInputType_nd2.Checked = 'Off';
                Handles.hFileInputType_tif.Checked = 'On';
        end
    end

%% Changing active object/image/group indices

    function [] = ChangeActiveObject(source,event)
        data = guidata(source);
        
        cImage = data.CurrentImage;
        cImage.CurrentObjectIdx = source.Value;
        
        UpdateImages(source);
        UpdateTables(source);
    end

    function [] = ChangeActiveGroup(source,event)
        data = guidata(source);
        % set new group index based on user selection
        data.CurrentGroupIndex = source.Value;
        % update display
        UpdateListBoxes(source);
        UpdateImages(source);
        UpdateTables(source);
    end

    function [] = ChangeActiveImage(source,event)
        % get PODSData
        data = guidata(source);
        % get current group index
        CurrentGroupIndex = data.CurrentGroupIndex;
        % update current image index for all channels
        data.Group(CurrentGroupIndex).CurrentImageIndex = source.Value;
        % update display
        UpdateListBoxes(source);
        UpdateImages(source);
        UpdateTables(source);
    end

%% Changing active image operation

    function[] = ChangeImageOperation(source,event)
        
        data = guidata(source);
        OldOperation = data.Settings.CurrentImageOperation;
        data.Settings.CurrentImageOperation = source.Value;
        
        switch OldOperation
            case 'Mask Threshold'
                data.Handles.ThreshAxH.Visible = 'Off';
                data.Handles.ThreshBar.Visible = 'Off';
                data.Handles.CurrentThresholdLine.Visible = 'Off';
            case 'Intensity Display'
                data.Handles.PrimaryIntensitySlider.Visible = 'Off';
                data.Handles.ReferenceIntensitySlider.Visible = 'Off';
        end

        switch data.Settings.CurrentImageOperation
            case 'Mask Threshold'
                data.Handles.SettingsPanel.Title = 'Adjust mask threshold';
                data.Handles.ThreshAxH.Visible = 'On';
                data.Handles.ThreshBar.Visible = 'On';
                data.Handles.CurrentThresholdLine.Visible = 'On';
            case 'Intensity Display'
                data.Handles.SettingsPanel.Title = 'Adjust intensity display limits';
                data.Handles.PrimaryIntensitySlider.Visible = 'On';
                data.Handles.ReferenceIntensitySlider.Visible = 'On';
        end

    end


%% Local SB

    function [] = pb_FindLocalSB(source,event)
        % get the data structure
        data = guidata(source);
        % number of selected images
        nImages = length(data.CurrentImage);
        % update log to indicate # of images we are processing
        UpdateLog3(source,['Detecting Local S/B for ',num2str(nImages),' images'],'append');
        % counter to track which image we're on
        Counter = 1;
        for cImage = data.CurrentImage;
            % update log to indicate which image we are on
            UpdateLog3(source,['    ',cImage.pol_shortname,' (',num2str(Counter),'/',num2str(nImages),')'],'append');
            % detect local S/B for one image
            cImage.FindLocalSB(source);
            % preallocate filtered mask and OF image
            cImage.bwFiltered = zeros(size(cImage.bw));
            cImage.OFFiltered = zeros(size(cImage.OF_image));
            % fill filtered mask and OF images according to local S/B cutoff level
            if cImage.nObjects > 0
                for ii = 1:length(cImage.Object)
                    if cImage.Object(ii).SBRatio >= cImage.SBCutoff
                        cImage.bwFiltered(cImage.Object(ii).PixelIdxList) = 1;
                    end
                    cImage.OFFiltered(cImage.bwFiltered) = cImage.OF_image(cImage.bwFiltered);
                end
            end
            % log update to indicate we are done with this image
            UpdateLog3(source,['        Local S/B detected for ',num2str(cImage.nObjects),' objects...'],'append');
            % increment counter
            Counter = Counter+1;
        end
        % update log to indicate we are done
        UpdateLog3(source,'Done.','append');
        % update summary table
        UpdateTables(source);
    end

%% Data saving

    function [] = SaveImages(source,event)
        
        data = guidata(source)
        cGroupIndex = data.CurrentGroupIndex;
        % array of selected image(s) indices
        cImageIndex = data.Group(cGroupIndex).CurrentImageIndex;
        
        % get screensize
        ss = data.Settings.ScreenSize;
        % center point (x,y) of screen
        center = [ss(3)/2,ss(4)/2];

        %% Data Selection
        sz = [center(1)-150 center(2)-300 300 600];
        
        fig = uifigure('Name','Select Images to Save',...
            'Menubar','None',...
            'Position',sz,...
            'HandleVisibility','On');
        
        % cell array of char vectors of possible save options
        SaveOptions = {['Average Intensity Image'];...
            ['Background Subtracted Image'];...
            ['Masked Order Factor'];...
            ['Binary Mask'];...
            ['Filtered Order Factor'];...
            ['Filtered Mask']};
        
        % generate save options check boxes
        for i = 1:length(SaveOptions)
            SaveCBox(i) = uicheckbox(fig,...
                'Text',SaveOptions{i},...
                'Value',0,...
                'Position',[20 600-40*i 160 20]);
        end
        
        Btn = uibutton(fig,'Push',...
            'Text','Choose Save Directory',...
            'Position',[20 20 160 20],...
            'ButtonPushedFcn',@ContinueToSave);
        
        UserSaveChoices = {};
        
        % callback for Btn to close fig
        function [] = ContinueToSave(source,event)
            for i = 1:length(SaveCBox)
                if SaveCBox(i).Value == 1
                    UserSaveChoices{end+1} = SaveCBox(i).Text;
                end
            end
            delete(fig)
        end
        
        % wait for deletion of SaveOptions figure (button push)
        waitfor(fig)
        
        % let user select save directory
        folder_name = uigetdir(pwd);
        
        % move into user-selected save directory
        cd(folder_name);
        
        % save user-specified data for each currently selected image
        for i = 1:length(cImageIndex)
            
            % current replicate to save images for
            cImage = data.Group(cGroupIndex).Replicate(cImageIndex(i));
            % data struct to hold output variable for current image
            ImageSummary = struct();
            % mask and average OF
            ImageSummary.bw = cImage.bw;
            ImageSummary.OFAvg = cImage.OFAvg;
            % filtered mask and average OF
            ImageSummary.bwFiltered = cImage.bwFiltered;
            ImageSummary.FilteredOFAvg = cImage.FiltOFAvg;
            % raw data, raw data normalized to stack-max, raw stack-average
            ImageSummary.RawData = cImage.pol_rawdata;
            ImageSummary.RawDataNormMax = cImage.pol_rawdata_normalizedbystack;
            ImageSummary.RawDataAvg = cImage.RawPolAvg;
            % same as above, but with flat-field corrected data
            ImageSummary.FlatFieldCorrectedData = cImage.pol_ffc;
            ImageSummary.FlatFieldCorrectedDataNormMax = cImage.pol_ffc_normalizedbystack;
            ImageSummary.FlatFieldCorrectedDataAvg = cImage.Pol_ImAvg;
            % FF-corrected data normalized within each 4-px stack
            ImageSummary.FlatFieldCorrectedDataPixelNorm = cImage.norm;
            % output images
            ImageSummary.OFImage = cImage.OF_image;
            ImageSummary.MaskedOFImage = cImage.masked_OF_image;
            ImageSummary.FilteredOFImage = cImage.OFFiltered;
            ImageSummary.AzimuthImage = cImage.AzimuthImage;
            % object properties data for image
            ImageSummary.ObjectProperties = cImage.ObjectProperties;
            % image info
            ImageSummary.ImageName = cImage.pol_shortname;
            % calculated obj data (SB,OF,etc.)
            ImageSummary.ObjectData = GetImageObjectSummary(cImage);

            % control for mac vs pc
            if ismac
                loc = [folder_name '/' cImage.pol_shortname];
            elseif ispc
                loc = [folder_name '\' cImage.pol_shortname];
            end
            
            save([loc,'_Output'],'ImageSummary');
            
            %% Masked OF Image
            % if user selected this save option, then...
            if any(strcmp(UserSaveChoices,'Masked Order Factor'))
                
                name = [loc,'-OF_masked'];
                UpdateLog3(source,name,'append');
                fig = figure('Visible','off','Color','Black');
                hImage = imshow(full(cImage.OF_image),[0,1]);
                colormap(gca,PODSData.Settings.OrderFactorColormap);
                hImage.AlphaData = cImage.bw;
                set(hImage.Parent,'YDir','Reverse');
                
                % dirty trick to get export fig to save transparent pixels - need to improve
                hImage.AlphaData(1,1) = 1;
                hImage.AlphaData(end,end) = 1;
                
                % save and close fig
                export_fig(name,'-native');
                close(fig);
                
            end
            
            %% Filtered OF Image
            if any(strcmp(UserSaveChoices,'Filtered Order Factor'))
                
                name = [loc '-OF_Filtered'];
                UpdateLog3(source,name,'append');
                fig = figure('Visible','off');
                hImage = imshow(full(cImage.OFFiltered),[0,1]);
                colormap(gca,PODSData.Settings.OrderFactorColormap);
                hImage.AlphaData = cImage.bw;
                hImage.YDir = 'Reverse';
                
                % save and close fig
                export_fig(name,'-native');
                close(fig);
                
            end
            %% Average Intensity
            if any(strcmp(UserSaveChoices,'Average Intensity Image'))
                
                name = [loc '-Avg_Intensity'];
                UpdateLog3(source,name,'append');
                fig = figure('Visible','off');
                hImage = imshow(full(cImage.I),[min(min(cImage.I)),max(max(cImage.I))]);
                colormap(gca,PODSData.Settings.IntensityColormaps{1});
                set(hImage.Parent,'YDir','Reverse');
                
                export_fig(name,'-native');
                %close(fig)
                
            end
            
        end % end of main save loop
        
    end % end SaveImages

    function [] = SaveObjectData(source,event)
        
        data = guidata(source);
        
        CurrentGroup = data.CurrentGroup;
        
        % instruct and allow user to set a save directory
        tempmsg = msgbox(['Select a directory to save Object Data Table for Group:',CurrentGroup.GroupName]);
        waitfor(tempmsg);
        UserChoice = uigetdir(pwd);
        
        % control for mac vs pc
        if ismac
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
        
        % create a struct with dynamic field name for unambiguous naming of the saved variable
        S.(matlab.lang.makeValidName([CurrentGroup.GroupName,'_AvgFilteredOFPerImage'])) = full([CurrentGroup.Replicate(:).FiltOFAvg]');
        save([SaveLocation,'_AvgFilteredOFPerImage','.mat'],'-struct','S');
        
        UpdateLog3(source,['Done saving data for Group:',CurrentGroup.GroupName],'append');
        
    end

%% Toolbar callbacks

    function [] = tbApplyMaskStateChanged(source,event)
        
        cGroupIdx = PODSData.CurrentGroupIndex;
        cImageIdx = PODSData.Group(cGroupIdx).CurrentImageIndex;
        ctb = source.Parent;
        cax = ctb.Parent;
        im = findobj(cax,'Type','image');
        switch event.Value
            case 1 % 'On'
                im.AlphaData = PODSData.Group(cGroupIdx).Replicate(cImageIdx).bw;
            case 0 % 'Off'
                im.AlphaData = 1;
        end
        
    end

    function [] = tbShowSelectionStateChanged(source,event)
        switch event.Value
            case 1
                PODSData.Handles.ShowSelectionAverageIntensity.Value = 1;
                PODSData.Handles.ShowSelectionMask.Value = 1;
            case 0
                PODSData.Handles.ShowSelectionAverageIntensity.Value = 0;
                PODSData.Handles.ShowSelectionMask.Value = 0;                
        end
        UpdateImages(source);
    end

    function [] = tbShowReferenceImageStateChanged(source,event)
        if PODSData.CurrentImage.ReferenceImageLoaded
            UpdateImages(source);
        else
            source.Value = 0;
            warning('No reference image to overlay...')
        end
    end

    function [] = tbRectangularROI(source,event)
        ctb = source.Parent;
        cax = ctb.Parent;
        % draw rectangular ROI
        ROI = drawrectangle(cax);
        % find and 'select' objects within ROI
        SelectObjectsInRectangularROI(source,ROI);
        % delete the ROI
        delete(ROI);
        % update display
        UpdateImages(source);
    end

    function [] = tbLineScan(source,event)
        
        try
            delete(Handles.LineScanROI);
            delete(Handles.LineScanFig);
        catch
            % do nothing for now
        end
        
        Handles.LineScanROI = images.roi.Line(Handles.AverageIntensityAxH);
        XRange = Handles.AverageIntensityAxH.XLim(2)-Handles.AverageIntensityAxH.XLim(1);
        YRange = Handles.AverageIntensityAxH.YLim(2)-Handles.AverageIntensityAxH.YLim(1);
        x1 = Handles.AverageIntensityAxH.XLim(1)+0.25*XRange;
        x2 = Handles.AverageIntensityAxH.XLim(2)-0.25*XRange;
        y1 = Handles.AverageIntensityAxH.YLim(1)+0.5*YRange;
        y2 = Handles.AverageIntensityAxH.YLim(1)+0.5*YRange;
        
        Handles.LineScanFig = uifigure('Name','Intensity line scan',...
            'HandleVisibility','On',...
            'WindowStyle','AlwaysOnTop',...
            'Units','Normalized',...
            'Position',[0.6 0.8 0.4 0.2],...
            'CloseRequestFcn',@CloseLineScanFig);        
        
        Handles.LineScanAxes = uiaxes(Handles.LineScanFig,'Units','Normalized','OuterPosition',[0 0 1 1]);
        
        Handles.LineScanROI.Position = [x1 y1; x2 y2];
        
        addlistener(Handles.LineScanROI,'MovingROI',@OneChannelLineScan);
        addlistener(Handles.LineScanROI,'ROIMoved',@OneChannelLineScan);        

    end

    function CloseLineScanFig(source,event)
        
        delete(Handles.LineScanROI);
        delete(Handles.LineScanFig);
        
    end


    function OneChannelLineScan(source,event)
        
        if PODSData.CurrentImage.ReferenceImageLoaded & PODSData.Handles.ShowReferenceImageAverageIntensity.Value==1
            Handles.LineScanAxes = PlotDoubleLineScan(Handles.LineScanAxes,...
                Handles.LineScanROI.Position,...
                PODSData.CurrentImage.I,...
                Scale0To1(PODSData.CurrentImage.ReferenceImage),...
                PODSData.CurrentImage.RealWorldLimits);
            %drawnow limitrate
        else
            Handles.LineScanAxes = PlotLineScan(Handles.LineScanAxes,...
                Handles.LineScanROI.Position,...
                PODSData.CurrentImage.I,...
                PODSData.CurrentImage.RealWorldLimits);
            %drawnow limitrate
        end
        
    end


end