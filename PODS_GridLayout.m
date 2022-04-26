function PODS_GridLayout()

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

% set some defaults to save time and improve readability
set(gcf,'defaultUipanelFontName','Consolas');
set(gcf,'defaultUipanelBackgroundColor','Black');
set(gcf,'defaultUipanelForegroundColor','White');

%% File Menu Button - Create a new project, load files, etc...
Handles.hFileMenu = uimenu(Handles.fH,'Text','File');
% Options for File Menu Button
Handles.hNewProject = uimenu(Handles.hFileMenu,'Text','New Project','Callback',@NewProject);
% load
Handles.hLoadFFCFiles = uimenu(Handles.hFileMenu,'Text','Load FFC Files','Separator','On','Callback',@pb_LoadFFCFiles);
Handles.hLoadFPMFiles = uimenu(Handles.hFileMenu,'Text','Load FPM Files','Callback',@pb_LoadFPMFiles);
%Handles.hLoadCoLocFiles = uimenu(Handles.hFileMenu,'Text','Load Colocalization Files','Callback',@LoadColocFiles);
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

Handles.hSelectColormapMenu = uimenu(Handles.hOptionsMenu,'Text','Change Colormap');
Handles.hSelectIntensityColormapMenu = uimenu(Handles.hSelectColormapMenu,'Text','Intensity','Callback',@ChangeIntensityColormap);
Handles.hSelectOFColormapMenu = uimenu(Handles.hSelectColormapMenu,'Text','Order Factor','Callback',@ChangeOFColormap);
% Structuring element size
% Handles.hSESize = uimenu(Handles.hOptionsMenu,'Text','SE Size (px)');
% % Options for SE size
% Handles.hSESize5px = uimenu(Handles.hSESize,'Text','5','Checked','Off','Callback',@ChangeSESize,'Tag','5');
% Handles.hSESize4px = uimenu(Handles.hSESize,'Text','4','Checked','Off','Callback',@ChangeSESize,'Tag','4');
% Handles.hSESize3px = uimenu(Handles.hSESize,'Text','3 (default)','Checked','On','Callback',@ChangeSESize,'Tag','3');
% Handles.hSESize2px = uimenu(Handles.hSESize,'Text','2','Checked','Off','Callback',@ChangeSESize,'Tag','2');
% % Structuring element size
% Handles.hSELines = uimenu(Handles.hOptionsMenu,'Text','SE Approximation (# of lines)');
% Handles.hSE0Lines = uimenu(Handles.hSELines,'Text','No Approximation (default,slowest)','Checked','On','Callback',@ChangeSELines,'Tag','0');
% Handles.hSE2Lines = uimenu(Handles.hSELines,'Text','2','Checked','Off','Callback',@ChangeSELines,'Tag','2');
% Handles.hSE4Lines = uimenu(Handles.hSELines,'Text','4','Checked','Off','Callback',@ChangeSELines,'Tag','4');
% Handles.hSE6Lines = uimenu(Handles.hSELines,'Text','6','Checked','Off','Callback',@ChangeSELines,'Tag','6');
% Handles.hSE8Lines = uimenu(Handles.hSELines,'Text','8 (fastest)','Checked','Off','Callback',@ChangeSELines,'Tag','8');

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
%Handles.hTabImageColocalization = uimenu(Handles.hTabMenu,'Text','Image Colocalization','MenuSelectedFcn',@TabSelection,'tag','hTabImageColocalization');

%% Process Menu Button - allows user to perform FFC, generate mask, and generate output images
Handles.hProcessMenu = uimenu(Handles.fH,'Text','Process');
% Process Operations
Handles.hProcessFFC = uimenu(Handles.hProcessMenu,'Text','Perform Flat-Field Correction','MenuSelectedFcn',@pb_FFC);
Handles.hProcessMask = uimenu(Handles.hProcessMenu,'Text','Generate Mask','MenuSelectedFcn',@CreateMask3);
Handles.hProcessOF = uimenu(Handles.hProcessMenu,'Text','Find Order Factor','MenuSelectedFcn',@FindOrderFactor3);
Handles.hProcessLocalSB = uimenu(Handles.hProcessMenu,'Text','Find Local Signal:Background','MenuSelectedFcn',@pb_FindLocalSB);
%Handles.hProcessColocalization = uimenu(Handles.hProcessMenu,'Text','Compute Colocalization Stats','MenuSelectedFcn',@ComputeColocalizationStats);

%% Plot Menu Button
Handles.hPlotMenu = uimenu(Handles.fH,'Text','Plot');
% Plot choices
Handles.hPlotViolins = uimenu(Handles.hPlotMenu,'Text','Order Factor Violins - All Objects','MenuSelectedFcn',@PlotViolins);
Handles.hPlotOFvsSB = uimenu(Handles.hPlotMenu,'Text','Object Properties Correlation','MenuSelectedFcn',@PlotObjects);

%% Summary Menu Button
Handles.hSummaryMenu = uimenu(Handles.fH,'Text','Summary');
% Summary choices
Handles.hSumaryAll = uimenu(Handles.hSummaryMenu,'Text','All Data','MenuSelectedFcn',@ShowSummaryTable);

%% draw the menu bar objects and pause for more predictable performance
drawnow
pause(0.5)

%% Set up the MainGrid uigridlayout manager

pos = Handles.fH.Position;

% width and height of the large plots
width = round(pos(3)*0.35);
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
Handles.MainGrid.ColumnWidth = {'0.38x',sheight,sheight,sheight,sheight};

%% Create the non-image panels (Summary, Selector, Settings, Log)
% panel to show project summary
Handles.AppInfoPanel = uipanel(Handles.MainGrid,...
    'Visible','Off',...
    'AutoResizeChildren','Off',...
    'SizeChangedFcn',@AppInfoPanelSizeChanged);
Handles.AppInfoPanel.Title = 'Project Summary';
Handles.AppInfoPanel.Layout.Row = [1 3];
Handles.AppInfoPanel.Layout.Column = 1;
% panel to hold ImgInfoTabGroup (Group/Image/Object) selection
Handles.SelectorPanel = uipanel(Handles.MainGrid,...
    'Visible','Off',...
    'AutoResizeChildren','Off');
Handles.SelectorPanel.Title = 'Group/Image/Object Selection';
Handles.SelectorPanel.Layout.Row = 1;
Handles.SelectorPanel.Layout.Column = [2 3];
% panel to hold ImgOperationsTabGroup (currently just for interactive thresholding)
Handles.SettingsPanel = uipanel(Handles.MainGrid,...
    'Visible','Off',...
    'AutoResizeChildren','Off');
Handles.SettingsPanel.Title = 'Image Operations';
Handles.SettingsPanel.Layout.Row = 1;
Handles.SettingsPanel.Layout.Column = [4 5];
% panel to display log messages (updates user on running/completed processes)
Handles.LogPanel = uipanel(Handles.MainGrid,...
    'Visible','Off',...
    'AutoResizeChildren','Off',...
    'SizeChangedFcn',@LogPanelSizeChanged);
Handles.LogPanel.Title = 'Log Window';
Handles.LogPanel.Layout.Row = 4;
Handles.LogPanel.Layout.Column = [1 5];

%% Small Image Panels
% tags for small panels
panel_tags = ['Panel_1-1' 'Panel_1-2' 'Panel_1-3' 'Panel_1-4';...
    'Panel_2-1' 'Panel_2-2' 'Panel_2-3' 'Panel_2-4'];

for SmallPanelRows = 1:2
    for SmallPanelColumns = 1:4
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns) = uipanel(Handles.MainGrid,'Visible','Off');
        %SmallPanels(SmallPanelRows,SmallPanelColumns).Title = ['Small Panel ',num2str((SmallPanelRows-1)*4+SmallPanelColumns)];
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Row = SmallPanelRows+1;
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Column = SmallPanelColumns+1;
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).Tag = panel_tags(SmallPanelRows,SmallPanelColumns);
        % Important to set so we can resize children of panels with expected behavior
        Handles.SmallPanels(SmallPanelRows,SmallPanelColumns).AutoResizeChildren = 'Off';
    end
end

%% Large Image Panels
% first one (lefthand panel)
Handles.ImgPanel1 = uipanel(Handles.MainGrid,'Visible','off','SizeChangedFcn',@ImgPanel1SizeChanged);
Handles.ImgPanel1.Layout.Row = [2 3];
Handles.ImgPanel1.Layout.Column = [2 3];
%ImgPanel1.Title = 'Large Panel 1'
Handles.ImgPanel1.AutoResizeChildren = 'Off';

% second one (righthand panel)
Handles.ImgPanel2 = uipanel(Handles.MainGrid,'Visible','off','SizeChangedFcn',@ImgPanel2SizeChanged);
Handles.ImgPanel2.Layout.Row = [2 3];
Handles.ImgPanel2.Layout.Column = [4 5];
%ImgPanel2.Title = 'Large Panel 2';
Handles.ImgPanel2.AutoResizeChildren = 'Off';

% add these to an array so we can change their settings simultaneously
Handles.LargePanels = [Handles.ImgPanel1,Handles.ImgPanel2];

%% draw all the panels and pause briefly for more predictable performance
drawnow
pause(0.5)

%% Image Info Tab Group (selection boxes for group/image/objects)

Handles.ImgInfoTabGroup = uitabgroup(Handles.SelectorPanel,...
    'SelectionChangedFcn',@ChangeActiveChannel,...
    'Units','Normalized',...
    'Position',[0 0 1 1],...
    'AutoResizeChildren','Off');
Handles.ChannelSelectorTab(1) = uitab(Handles.ImgInfoTabGroup,...
    'Title','Channel 1',...
    'BackgroundColor','Black',...
    'Tag','1',...
    'AutoResizeChildren','Off',...
    'SizeChangedFcn',@ImgInfoTabGroupSizeChanged);
Handles.ChannelSelectorTab(2) = uitab(Handles.ImgInfoTabGroup,...
    'Title','Channel 2',...
    'BackgroundColor','Black',...
    'Tag','2',...
    'AutoResizeChildren','Off');

%% Image Operations Tab Group (thresholding/colormaps/etc)

Handles.ImgOperationsTabGroup = uitabgroup(Handles.SettingsPanel,...
    'Units','Normalized',...
    'Position',[0 0 1 1],...
    'AutoResizeChildren','Off');
% tabs for tabgroup container
Handles.ImgOperationsTab(1) = uitab(Handles.ImgOperationsTabGroup,...
    'Title','Mask Threshold',...
    'BackgroundColor','Black',...
    'tag','AdjustThresholdTab',...
    'AutoResizeChildren','Off',...
    'SizeChangedFcn',@ImgOperationsTabGroupSizeChanged);
Handles.ImgOperationsTab(2) = uitab(Handles.ImgOperationsTabGroup,...
    'Title','Colormaps',...
    'BackgroundColor','Black',...
    'tag','ColorSettings',...
    'AutoResizeChildren','Off');

%% Interactive User Thresholding
% axes to show intensity histogram
Handles.ThreshAxH = uiaxes(Handles.ImgOperationsTab(1),...
    'Units','Normalized',...
    'Position',[0 0 1 1],...
    'Color',[0 0 0],...
    'Visible','Off',...
    'FontName','Consolas',...
    'FontSize',12,...
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
    'FontName','Consolas',...
    'FontWeight','Bold',...
    'LineWidth',1.5,...
    'Color',[0 0 1],...
    'LabelVerticalAlignment','Middle');


drawnow
pause(0.1)

%% add log window to log panel for process updates
Handles.LogWindow = uitextarea(Handles.LogPanel,...
    'Position',[1 1 Handles.LogPanel.InnerPosition(3) Handles.LogPanel.InnerPosition(4)],...
    'HorizontalAlignment','left',...
    'enable','on',...
    'tag','LogWindow',...
    'BackgroundColor','black',...
    'FontColor','yellow',...
    'FontName','Courier',...
    'Value',{'Log Window';'Drawing Containers and Tables...'},...
    'Visible','Off');

%% Group Selection Box
pos = Handles.ChannelSelectorTab(1).InnerPosition;
small_width = (0.5*pos(3)-25)*0.5;
large_width = small_width*2+10;

Handles.GroupSelector = uilistbox('parent',Handles.ChannelSelectorTab(1),...
    'Position', [10 10 small_width pos(4)-30],...
    'enable','on',...
    'tag','GroupListBox',...
    'Items',{'Start a new project...'},...
    'ValueChangedFcn',@ChangeActiveGroup,...
    'FontColor','Black',...
    'MultiSelect','Off',...
    'Enable',0);
lst_pos = Handles.GroupSelector.Position;
Handles.GroupSelectorTitle = uilabel('Parent',Handles.ChannelSelectorTab(1),...
    'Position', [10 lst_pos(4)+10 small_width 20],...
    'FontColor','Yellow',...
    'Text','<b>Select Group</b>',...
    'HorizontalAlignment','center',...
    'Interpreter','html');

%% Image Selection Box
Handles.ImageSelector = uilistbox('parent',Handles.ChannelSelectorTab(1),...
    'Position', [lst_pos(3)+20 10 large_width lst_pos(4)],...
    'enable','on',...
    'tag','ImageListBox',...
    'Items',{'Select group to view its images...'},...
    'ValueChangedFcn',@ChangeActiveImage,...
    'MultiSelect','on',...
    'FontColor','Black',...
    'Enable',0,...
    'Visible','Off');
lst_pos2 = Handles.ImageSelector.Position;
Handles.ImageSelectorTitle = uilabel('Parent',Handles.ChannelSelectorTab(1),...
    'Position', [lst_pos2(1) lst_pos2(4)+10 large_width 20],...
    'FontColor','Yellow',...
    'Text','<b>Select Image</b>',...
    'HorizontalAlignment','center',...
    'Interpreter','html',...
    'Visible','Off');

%% Object Selection Box
Handles.ObjectSelector = uilistbox('parent',Handles.ChannelSelectorTab(1),...
    'Position', [lst_pos(3)+lst_pos2(3)+30 10 small_width lst_pos(4)],...
    'enable','on',...
    'tag','ObjectListBox',...
    'Items',{'Select image to view objects...'},...
    'ValueChangedFcn',@ChangeActiveObject,...
    'MultiSelect','off',...
    'FontColor','Black',...
    'Enable',0,...
    'Visible','Off');
lst_pos3 = Handles.ObjectSelector.Position;
Handles.ObjectSelectorTitle = uilabel('Parent',Handles.ChannelSelectorTab(1),...
    'Position', [lst_pos3(1) lst_pos3(4)+10 small_width 20],...
    'FontColor','Yellow',...
    'Text','<b>Select Object</b>',...
    'HorizontalAlignment','Center',...
    'Interpreter','html',...
    'Visible','Off');

%% Summary table for current group/image/object
Handles.ProjectDataTable = uilabel(Handles.AppInfoPanel,...
    'Position',[10 10 Handles.AppInfoPanel.InnerPosition(3)-20 Handles.AppInfoPanel.InnerPosition(4)-20],...
    'tag','ProjectDataTable',...
    'FontColor','Yellow',...
    'FontName','Courier',...
    'BackgroundColor','Black',...
    'VerticalAlignment','Top',...
    'Interpreter','html');

Handles.ProjectDataTable.Text = {['Start a new project first...']};

%% AXES AND IMAGE PLACEHOLDERS

% empty placeholder image
emptyimage = rand(1024,1024);

greenmap = PODSData.Settings.AllColormaps.Green;

AllSmallAxes = [];
AllLargeAxes = [];

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
    Handles.FFCAxH(i).Colormap = greenmap;
end

Handles.AllSmallAxes = Handles.FFCAxH;

%linkaxes(FFCAxH);
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
    Handles.RawIntensityAxH(i).Colormap = greenmap;
    
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
    
    Handles.PolFFCAxH(i).Colormap = greenmap;
    
    Handles.PolFFCAxH(i).Toolbar.Visible = 'Off';
    
    Handles.PolFFCImgH(i).Visible = 'Off';
    Handles.PolFFCAxH(i).Title.Visible = 'Off';
    
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
    
    Handles.MStepsAxH(i).Colormap = greenmap;
    
    Handles.MStepsAxH(i).Toolbar.Visible = 'Off';
    
    Handles.MStepsImgH(i).Visible = 'Off';
    Handles.MStepsAxH(i).Title.Visible = 'Off';
    
    Handles.AllSmallAxes(end+1) = Handles.MStepsAxH(i);
end


%% COLOCALIZATION TAB AXES

    %% PRIMARY CHANNEL AVERAGE INTENSITY
%     Handles.PrimaryColocIntensityAxH = uiaxes('Parent',Handles.SmallPanels(1,1),...
%         'Units','Normalized',...
%         'InnerPosition',[0 0 1 1],...
%         'Tag','PrimaryColocIntensity',...
%         'XTick',[],...
%         'YTick',[]);
%     image_title = 'Primary Channel';
%     image_tag = 'PrimaryColocIntensityImage';
% 
%     % save original values
%     pbarOriginal = Handles.PrimaryColocIntensityAxH.PlotBoxAspectRatio;
%     tagOriginal = Handles.PrimaryColocIntensityAxH.Tag;
%     % place placeholder image on axis
%     Handles.PrimaryColocIntensityImgH = imshow(full(emptyimage),'Parent',Handles.PrimaryColocIntensityAxH);
%     % set a tag so our callback functions can find the image
%     set(Handles.PrimaryColocIntensityImgH,'Tag',image_tag);
%     
%     % restore original values after imshow() call
%     Handles.PrimaryColocIntensityAxH = restore_axis_defaults(Handles.PrimaryColocIntensityAxH,pbarOriginal,tagOriginal);
%     clear pbarOriginal tagOriginal
%     
%     % set axis title
%     Handles.PrimaryColocIntensityAxH = SetAxisTitle(Handles.PrimaryColocIntensityAxH,image_title);
%     
%     Handles.PrimaryColocIntensityAxH.Colormap = greenmap;
%     
%     Handles.PrimaryColocIntensityAxH.Toolbar.Visible = 'Off';
%     
%     Handles.PrimaryColocIntensityImgH.Visible = 'Off';
%     Handles.PrimaryColocIntensityAxH.Title.Visible = 'Off';
%     
%     Handles.AllSmallAxes(end+1) = Handles.PrimaryColocIntensityAxH;
%     
%     %% SECONDARY CHANNEL AVERAGE INTENSITY
%     Handles.SecondaryColocIntensityAxH = uiaxes('Parent',Handles.SmallPanels(1,2),...
%         'Units','Normalized',...
%         'InnerPosition',[0 0 1 1],...
%         'Tag','SecondaryColocIntensity',...
%         'XTick',[],...
%         'YTick',[]);
%     image_title = 'Analysis Channel';
%     image_tag = 'SecondaryColocIntensityImage';
% 
%     % save original values
%     pbarOriginal = Handles.SecondaryColocIntensityAxH.PlotBoxAspectRatio;
%     tagOriginal = Handles.SecondaryColocIntensityAxH.Tag;
%     % place placeholder image on axis
%     Handles.SecondaryColocIntensityImgH = imshow(full(emptyimage),'Parent',Handles.SecondaryColocIntensityAxH);
%     % set a tag so our callback functions can find the image
%     set(Handles.SecondaryColocIntensityImgH,'Tag',image_tag);
%     
%     % restore original values after imshow() call
%     Handles.SecondaryColocIntensityAxH = restore_axis_defaults(Handles.SecondaryColocIntensityAxH,pbarOriginal,tagOriginal);
%     clear pbarOriginal tagOriginal
%     
%     % set axis title
%     Handles.SecondaryColocIntensityAxH = SetAxisTitle(Handles.SecondaryColocIntensityAxH,image_title);
%     
%     Handles.SecondaryColocIntensityAxH.Colormap = greenmap;
%     
%     Handles.SecondaryColocIntensityAxH.Toolbar.Visible = 'Off';
%     
%     Handles.SecondaryColocIntensityImgH.Visible = 'Off';
%     Handles.SecondaryColocIntensityAxH.Title.Visible = 'Off';
%     
%     Handles.AllSmallAxes(end+1) = Handles.SecondaryColocIntensityAxH;
%     
%     %% PRIMARY CHANNEL MASK
%     Handles.PrimaryColocMaskAxH = uiaxes('Parent',Handles.SmallPanels(2,1),...
%         'Units','Normalized',...
%         'InnerPosition',[0 0 1 1],...
%         'Tag','PrimaryColocMask',...
%         'XTick',[],...
%         'YTick',[]);
%     image_title = 'Mask';
%     image_tag = 'PrimaryColocMaskImage';
% 
%     % save original values
%     pbarOriginal = Handles.PrimaryColocMaskAxH.PlotBoxAspectRatio;
%     tagOriginal = Handles.PrimaryColocMaskAxH.Tag;
%     % place placeholder image on axis
%     Handles.PrimaryColocMaskImgH = imshow(full(emptyimage),'Parent',Handles.PrimaryColocMaskAxH);
%     % set a tag so our callback functions can find the image
%     set(Handles.PrimaryColocMaskImgH,'Tag',image_tag);
%     
%     % restore original values after imshow() call
%     Handles.PrimaryColocMaskAxH = restore_axis_defaults(Handles.PrimaryColocMaskAxH,pbarOriginal,tagOriginal);
%     clear pbarOriginal tagOriginal
%     
%     % set axis title
%     Handles.PrimaryColocMaskAxH = SetAxisTitle(Handles.PrimaryColocMaskAxH,image_title);
%     
%     Handles.PrimaryColocMaskAxH.Toolbar.Visible = 'Off';
%     
%     Handles.PrimaryColocMaskImgH.Visible = 'Off';
%     Handles.PrimaryColocMaskAxH.Title.Visible = 'Off';
%     
%     Handles.AllSmallAxes(end+1) = Handles.PrimaryColocMaskAxH;
%     
%     %% PRIMARY CHANNEL MASK
%     Handles.SecondaryColocMaskAxH = uiaxes('Parent',Handles.SmallPanels(2,2),...
%         'Units','Normalized',...
%         'InnerPosition',[0 0 1 1],...
%         'Tag','SecondaryColocMask',...
%         'XTick',[],...
%         'YTick',[]);
%     image_title = 'Mask';
%     image_tag = 'SecondaryColocMaskImage';
% 
%     % save original values
%     pbarOriginal = Handles.SecondaryColocMaskAxH.PlotBoxAspectRatio;
%     tagOriginal = Handles.SecondaryColocMaskAxH.Tag;
%     % place placeholder image on axis
%     Handles.SecondaryColocMaskImgH = imshow(full(emptyimage),'Parent',Handles.SecondaryColocMaskAxH);
%     % set a tag so our callback functions can find the image
%     set(Handles.SecondaryColocMaskImgH,'Tag',image_tag);
%     
%     % restore original values after imshow() call
%     Handles.SecondaryColocMaskAxH = restore_axis_defaults(Handles.SecondaryColocMaskAxH,pbarOriginal,tagOriginal);
%     clear pbarOriginal tagOriginal
%     
%     % set axis title
%     Handles.SecondaryColocMaskAxH = SetAxisTitle(Handles.SecondaryColocMaskAxH,image_title);
%     
%     Handles.SecondaryColocMaskAxH.Toolbar.Visible = 'Off';
%     
%     Handles.SecondaryColocMaskImgH.Visible = 'Off';
%     Handles.SecondaryColocMaskAxH.Title.Visible = 'Off';
%     
%     Handles.AllSmallAxes(end+1) = Handles.SecondaryColocMaskAxH;

    
%% Large Images

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
    Handles.AverageIntensityAxH.Colormap = greenmap;
    % hide axes toolbar
    Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
    % hide image/axes
    Handles.AverageIntensityImgH.Visible = 'Off';
    Handles.AverageIntensityAxH.Title.Visible = 'Off';
    
    %% Order Factor
    % create an axis, child of a panel, to fill the container
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
    axes(Handles.OrderFactorAxH)
    % custom colormap/colorbar
    [mycolormap,mycolormap_noblack] = MakeRGB;
    Handles.OFCbar = colorbar('location','east','color','white','tag','OFCbar');
    
    colormap(gca,OrderFactorMap);
    
    Handles.OFCbar.Visible = 'Off';
    Handles.OrderFactorAxH.Toolbar.Visible = 'Off';
    
    Handles.OrderFactorImgH.Visible = 'Off';
    Handles.OrderFactorAxH.Title.Visible = 'Off';

    %% Axis for swarm plots
    % create an axis, child of a panel, to fill the container
    Handles.SwarmPlotAxH = uiaxes(Handles.ImgPanel2,...
        'Units','Normalized',...
        'OuterPosition',[0 0 1 1],...
        'Tag','SwarmPlotAxes',...
        'XTick',[],...
        'YTick',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0],...
        'NextPlot','Add',...
        'Visible','Off',...
        'XColor','White',...
        'YColor','White');
    
    % set axis title
    Handles.SwarmPlotAxH = SetAxisTitle(Handles.SwarmPlotAxH,'Object OF (per group)');
    
    Handles.SwarmPlotAxH.XAxis.Label.String = "Group";
    Handles.SwarmPlotAxH.XAxis.Label.Color = 'White';
    Handles.SwarmPlotAxH.YAxis.Label.String = "Object Order Factor";
    Handles.SwarmPlotAxH.YAxis.Label.Color = 'White';
    Handles.SwarmPlotAxH.Toolbar.Visible = 'Off';
    
    Handles.SwarmPlotAxH.HitTest = 'Off';

    Handles.SwarmPlotAxH.Title.Visible = 'Off';

    %% MASK
    % create an axis, child of a panel, to fill the container
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
    
    Handles.MaskImgH.Visible = 'Off';
    Handles.MaskAxH.Title.Visible = 'Off';
    
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
    
    % change active axis so we can make custom colorbar/colormap
    axes(Handles.FilteredOFAxH)
    % custom colormap/colorbar
    [mycolormap,mycolormap_noblack] = MakeRGB;
    Handles.OFCbar2 = colorbar('location','east','color','white','tag','OFCbar2');
    
    colormap(gca,OrderFactorMap);
    
    Handles.OFCbar2.Visible = 'Off';
    
    Handles.FilteredOFAxH.Toolbar.Visible = 'Off';
    
    Handles.FilteredOFImgH.Visible = 'Off';
    Handles.FilteredOFAxH.Title.Visible = 'Off';
    
    %% Azimuth
    % create an axis, child of a panel, to fill the container
    Handles.QuiverAxH = uiaxes(Handles.ImgPanel2,...
        'Units','Normalized',...
        'InnerPosition',[0 0 1 1],...
        'Tag','QuiverAzimuth',...
        'XTick',[],...
        'YTick',[],...
        'Color','Black');
    % set axis title
    Handles.QuiverAxH = SetAxisTitle(Handles.QuiverAxH,'Azimuth Quiver Plot');
    
    Handles.QuiverAxH.Toolbar.Visible = 'Off';
    Handles.QuiverAxH.YDir = 'Reverse';
    Handles.QuiverAxH.Visible = 'Off';
    Handles.QuiverAxH.Title.Visible = 'Off';
    Handles.QuiverAxH.Title.Color = 'White';
    
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
    Handles.ObjectPolFFCAxH.Colormap = greenmap;
    Handles.ObjectPolFFCAxH.Toolbar.Visible = 'Off';
    Handles.ObjectPolFFCAxH.Title.Visible = 'Off';
    Handles.ObjectPolFFCImgH.Visible = 'Off';
    
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
    Handles.ObjectMaskImgH.Visible = 'Off';
    
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
    colormap(gca,OrderFactorMap);
    
    Handles.ObjectOFContourAxH.YDir = 'Reverse';
    Handles.ObjectOFContourAxH.Visible = 'Off';
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
    Handles.ObjectOFImgH.Visible = 'Off';    
    
    %% Colocalization Tab Pixel Intensity Correlation Plot
    % create an axis, child of a panel, to fill the container
%     Handles.PixelCorrelationPlotAxH = uiaxes(Handles.ImgPanel2,...
%         'Units','Normalized',...
%         'OuterPosition',[0 0 1 1],...
%         'Tag','PixelCorrelationPlotAxes',...
%         'XTick',[],...
%         'YTick',[],...
%         'NextPlot','Replace',...
%         'Visible','Off',...
%         'XColor','White',...
%         'YColor','White');
%     
%     % try to prevent annoying datatips that throw errors when we switch tabs or delete plots
%     disableDefaultInteractivity(Handles.PixelCorrelationPlotAxH);
%     
%     % set axis title
%     Handles.PixelCorrelationPlotAxH = SetAxisTitle(Handles.PixelCorrelationPlotAxH,'Pixel Intensity Correlation Plot');
%     
%     Handles.PixelCorrelationPlotAxH.XAxis.Label.String = "Primary Channel";
%     Handles.PixelCorrelationPlotAxH.XAxis.Label.Color = 'White';
%     Handles.PixelCorrelationPlotAxH.YAxis.Label.String = "Analysis Channel";
%     Handles.PixelCorrelationPlotAxH.YAxis.Label.Color = 'White';
%     Handles.PixelCorrelationPlotAxH.Toolbar.Visible = 'Off';
%     
%     Handles.PixelCorrelationPlotAxH.HitTest = 'Off';
% 
%     Handles.PixelCorrelationPlotAxH.Title.Visible = 'Off';
%     Handles.PixelCorrelationPlotAxH.Visible = 'Off';
    
%% Turning on important containers
%drawnow

old = Handles.LogWindow.Value;
new = old;
new{length(old)+1} = 'Drawing Axes';
Handles.LogWindow.Value = new;
clear old new

% set figure to visible to draw containers
Handles.fH.Visible = 'On'
drawnow
pause(0.5)

set(Handles.AppInfoPanel,'Visible','On');
set(Handles.SettingsPanel,'Visible','On');
set(Handles.SelectorPanel,'Visible','On');
set(Handles.LogPanel,'Visible','On');
set(Handles.LogWindow,'Visible','On');
set(Handles.SmallPanels,'Visible','On');
set(Handles.ThreshAxH,'Visible','On');
set(Handles.GroupSelector,'Visible','On');
set(Handles.GroupSelectorTitle,'Visible','On');
set(Handles.ImageSelector,'Visible','On');
set(Handles.ImageSelectorTitle,'Visible','On');
set(Handles.ObjectSelector,'Visible','On');
set(Handles.ObjectSelectorTitle,'Visible','On');

%% Collect obj handles and add to PODSData

% update guidata with handles structure
PODSData.Handles = Handles;
guidata(Handles.fH,PODSData)

% linkaxes(Handles.FFCAxH,'xy');
% linkaxes(Handles.RawIntensityAxH,'xy');


%% Colormap settings

    function [] = ChangeIntensityColormap(source,event)
        
        PODSData.Settings.IntensityColormaps{1} = SelectColormap(PODSData.Settings.AllColormaps);
        UpdateImages(source);
    end

    function [] = ChangeOFColormap(source,event)
        
        PODSData.Settings.OrderFactorColormap = SelectColormap(PODSData.Settings.AllColormaps);
        UpdateImages(source);
    end

%% Callbacks controlling dynamic resizing of GUI containers
%  RESET IMAGE CONTAINER SIZES UPON CHANGING SIZE OF MAIN FIGURE WINDOW
    function [] = ResetContainerSizes(source,event)
        disp('Figure Window Size Changed...')
        
        SmallWidth = round((Handles.fH.InnerPosition(3)*0.38)/2);
        % update grid size to maatch new image sizes
        Handles.MainGrid.RowHeight = {'0.5x',SmallWidth,SmallWidth,'0.3x'};
        Handles.MainGrid.ColumnWidth = {'0.3x',SmallWidth,SmallWidth,SmallWidth,SmallWidth};
        
        drawnow limitrate
    end

    function [] = ImgInfoTabGroupSizeChanged(source,event)
        
        currentpos = Handles.ChannelSelectorTab(1).InnerPosition;
        small_box_width = (0.5*currentpos(3)-25)*0.5;
        large_box_width = small_box_width*2+10;
        % set new position for group selector box and label
        set(Handles.GroupSelector,...
            'Position',[10 10 small_box_width currentpos(4)-30]);
        set(Handles.GroupSelectorTitle,...
            'Position',[10 Handles.GroupSelector.Position(4)+10 small_box_width 20]);
        % set new position for image selector box and label
        set(Handles.ImageSelector,...
            'Position',[Handles.GroupSelector.Position(3)+20 10 large_box_width Handles.GroupSelector.Position(4)]);
        set(Handles.ImageSelectorTitle,...
            'Position',[Handles.ImageSelector.Position(1) Handles.ImageSelector.Position(4)+10 large_box_width 20]);
        % set new position for object selector box and label
        set(Handles.ObjectSelector,...
            'Position',[Handles.GroupSelector.Position(3)+Handles.ImageSelector.Position(3)+30 10 small_box_width Handles.GroupSelector.Position(4)]);
        set(Handles.ObjectSelectorTitle,...
            'Position',[Handles.ObjectSelector.Position(1) Handles.ObjectSelector.Position(4)+10 small_box_width 20]);
        
    end

    function [] = LogPanelSizeChanged(source,event)
        drawnow
        set(Handles.LogWindow,'Position',[1 1 Handles.LogPanel.InnerPosition(3) Handles.LogPanel.InnerPosition(4)]);
    end

    function [] = ImgOperationsTabGroupSizeChanged(source,event)
        
        set(Handles.ThreshAxH,'Position',[0 0 1 1]);
    end

    function [] = AppInfoPanelSizeChanged(source,event)
        
        set(Handles.ProjectDataTable,'Position',[10 10 Handles.AppInfoPanel.InnerPosition(3)-20 Handles.AppInfoPanel.InnerPosition(4)-20]);
    end

    function [] = ImgPanel1SizeChanged(source,event)
        disp('ImgPanel1SieChanged')
    end

    function [] = ImgPanel2SizeChanged(source,event)
        disp('ImgPane21SieChanged')
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
            case 'OrderFactor'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
            case 'AverageIntensity'
                addZoomToCursorToolbarBtn;
                addApplyMaskToolbarBtn;
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
            case 'QuiverAzimuth'
                addZoomToCursorToolbarBtn;
        end
        
        % Adding custom toolbar to allow ZoomToCursor
        function addZoomToCursorToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MagnifyingGlassBlackAndYellow.png';
            %btn.Tooltip = 'Zoom to Cursor';
            btn.ValueChangedFcn = @ZoomToCursor;
        end
        
        function addApplyMaskToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MaskIcon.png';
            %btn.Tooltip = 'Apply Mask';
            btn.ValueChangedFcn = @tbApplyMaskStateChanged;
            btn.Tag = ['ApplyMask',axH.Tag];
            Handles.(btn.Tag) = btn;
        end
        
        function addRemoveObjectsToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'RemoveObjects.png';
            %btn.Tooltip = 'Remove Objects in ROI';
            btn.ButtonPushedFcn = @tbRemoveObjects;
            btn.Tag = ['RemoveObjects',axH.Tag];
            Handles.(btn.Tag) = btn;
        end
    end

    function [axH] = SetAxisTitle(axH,title)
        % Set image (actually axis) title to top center of axis
        axH.Title.String = title;
        axH.Title.Units = 'Normalized';
        axH.Title.HorizontalAlignment = 'Center';
        axH.Title.VerticalAlignment = 'Top';
        axH.Title.Color = 'White';
        axH.Title.Position = [0.5,1.0,0];
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
        
        switch data.Settings.PreviousTab
            
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
                    
                    Handles.RawIntensityImgH(i).Visible = 'Off';
                    Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                    Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
                    
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'FFC'
                
                for i = 1:4
                    Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(2,i);
                    
                    Handles.PolFFCImgH(i).Visible = 'Off';
                    Handles.PolFFCAxH(i).Title.Visible = 'Off';
                    Handles.PolFFCAxH(i).Toolbar.Visible = 'Off';
                    
                    Handles.RawIntensityImgH(i).Visible = 'Off';
                    Handles.RawIntensityAxH(i).Title.Visible = 'Off';
                    Handles.RawIntensityAxH(i).Toolbar.Visible = 'Off';
                    
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
                
                % hide masking steps and small panels
                for i = 1:2
                    Handles.MStepsImgH(i).Visible = 'Off';
                    Handles.MStepsAxH(i).Title.Visible = 'Off';
                    Handles.MStepsAxH(i).Toolbar.Visible = 'Off';
                    
                    Handles.MStepsImgH(i+2).Visible = 'Off';
                    Handles.MStepsAxH(i+2).Title.Visible = 'Off';
                    Handles.MStepsAxH(i+2).Toolbar.Visible = 'Off';
                    
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
                
                Handles.AverageIntensityImgH.Visible = 'Off';
                Handles.AverageIntensityAxH.Title.Visible = 'Off';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
                
                Handles.MaskImgH.Visible = 'Off';
                Handles.MaskAxH.Title.Visible = 'Off';
                Handles.MaskAxH.Toolbar.Visible = 'Off';
                
            case 'Order Factor'
                
                Handles.OrderFactorImgH.Visible = 'Off';
                Handles.OrderFactorAxH.Title.Visible = 'Off';
                Handles.OrderFactorAxH.Toolbar.Visible = 'Off';
                
                Handles.AverageIntensityImgH.Visible = 'Off';
                Handles.AverageIntensityAxH.Title.Visible = 'Off';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
                
                Handles.ImgPanel1.Visible = 'Off';
                
                Handles.OFCbar.Visible = 'Off';
                
            case 'Azimuth'
                
                try
                    delete(data.Handles.AzimuthLines);
                catch
                    warning('Failed to delete Azimuth Lines');
                end
                
                Handles.QuiverAxH.Visible = 'Off';
                Handles.QuiverAxH.Title.Visible = 'Off';
                Handles.QuiverAxH.Toolbar.Visible = 'Off';
                
                Handles.AverageIntensityImgH.Visible = 'Off';
                Handles.AverageIntensityAxH.Title.Visible = 'Off';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'Off';
                
            case 'Plots'

                try
                    % hide the swarm plot
                    set(Handles.SwarmPlotAxH.Children,'Visible','Off')
                catch
                    % do nothing
                end

                Handles.SwarmPlotAxH.Title.Visible = 'Off';
                Handles.SwarmPlotAxH.Toolbar.Visible = 'Off';
                Handles.SwarmPlotAxH.Visible = 'Off';

            case 'Filtered Order Factor'
                
                Handles.FilteredOFImgH.Visible = 'Off';
                Handles.FilteredOFAxH.Title.Visible = 'Off';
                Handles.FilteredOFAxH.Toolbar.Visible = 'Off';
                
                Handles.OFCbar2.Visible = 'Off';
                
            case 'View Objects'
                
                try
                    delete(data.Handles.hObjectOFContour);
                catch
                    warning('No 2D contour to delete');
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
                
                Handles.ImgPanel2.Visible = 'Off';
                
                for i = 1:2
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'Image Colocalization'
                
                % average intensity images
                Handles.PrimaryColocIntensityAxH.Title.Visible = 'Off';
                Handles.PrimaryColocIntensityImgH.Visible = 'Off';
                
                Handles.SecondaryColocIntensityAxH.Title.Visible = 'Off';
                Handles.SecondaryColocIntensityImgH.Visible = 'Off';
                
                % image masks
                Handles.PrimaryColocMaskAxH.Title.Visible = 'Off';
                Handles.PrimaryColocMaskImgH.Visible = 'Off';
                
                Handles.SecondaryColocMaskAxH.Title.Visible = 'Off';
                Handles.SecondaryColocMaskImgH.Visible = 'Off';           

                % pixel intensity correlation plot
                try
                    % hide the intensity scatter plot
                    set(Handles.PixelCorrelationPlotAxH.Children,'Visible','Off')
                catch
                    % do nothing
                end

                Handles.PixelCorrelationPlotAxH.Title.Visible = 'Off';
                Handles.PixelCorrelationPlotAxH.Toolbar.Visible = 'Off';
                Handles.PixelCorrelationPlotAxH.Visible = 'Off';

                % panels
                Handles.ImgPanel2.Visible = 'Off';
                
                for i = 1:2
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end                
         
        end
        
        switch data.Settings.CurrentTab
            case 'Files'
                
                for i = 1:4
                    Handles.RawIntensityAxH(i).Parent = Handles.SmallPanels(2,i);
                    
                    Handles.RawIntensityImgH(i).Visible = 'On';
                    Handles.RawIntensityAxH(i).Title.Visible = 'On';
                    Handles.RawIntensityAxH(i).Toolbar.Visible = 'On';
                    
                    Handles.FFCImgH(i).Visible = 'On';
                    Handles.FFCAxH(i).Title.Visible = 'On';
                    Handles.FFCAxH(i).Toolbar.Visible = 'On';
                    
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
                    
                    Handles.PolFFCImgH(i).Visible = 'On';
                    Handles.PolFFCAxH(i).Title.Visible = 'On';
                    Handles.PolFFCAxH(i).Toolbar.Visible = 'On';
                    
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
                    
                    Handles.MStepsImgH(i+2).Visible = 'On';
                    Handles.MStepsAxH(i+2).Title.Visible = 'On';
                    Handles.MStepsAxH(i+2).Toolbar.Visible = 'On';
                    
                    Handles.SmallPanels(1,i).Visible = 'On';
                    Handles.SmallPanels(2,i).Visible = 'On';
                    
                    Handles.SmallPanels(1,i+2).Visible = 'Off';
                    Handles.SmallPanels(2,i+2).Visible = 'Off';
                end
                
                
                linkaxes([Handles.MStepsAxH,Handles.MaskAxH],'xy');
                Handles.ImgOperationsTabGroup.SelectedTab = Handles.ImgOperationsTab(1);
                
            case 'View/Adjust Mask'
                Handles.ImgPanel1.Visible = 'On';
                Handles.ImgPanel2.Visible = 'On';
                
                Handles.AverageIntensityImgH.Visible = 'On';
                Handles.AverageIntensityAxH.Title.Visible = 'On';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
                
                Handles.MaskImgH.Visible = 'On';
                Handles.MaskAxH.Title.Visible = 'On';
                Handles.MaskAxH.Toolbar.Visible = 'On';
                
                for i = 1:4
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                linkaxes([Handles.AverageIntensityAxH,Handles.MaskAxH],'xy');
                Handles.ImgOperationsTabGroup.SelectedTab = Handles.ImgOperationsTab(1);
                
            case 'Order Factor'
                
                Handles.OrderFactorImgH.Visible = 'On';
                Handles.OrderFactorAxH.Title.Visible = 'On';
                Handles.OrderFactorAxH.Toolbar.Visible = 'On';
                Handles.OrderFactorAxH.XLim = [1 1024];
                Handles.OrderFactorAxH.YLim = Handles.OrderFactorAxH.XLim;
                
                Handles.AverageIntensityImgH.Visible = 'On';
                Handles.AverageIntensityAxH.Title.Visible = 'On';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
                
                Handles.ImgPanel2.Visible = 'On';
                Handles.ImgPanel1.Visible = 'On';
                
                Handles.OFCbar.Visible = 'On';
                
                for i = 1:4
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
                linkaxes([Handles.AverageIntensityAxH,Handles.OrderFactorAxH],'xy');
                
            case 'Azimuth'
                
                Handles.QuiverAxH.Visible = 'On';
                Handles.QuiverAxH.Title.Visible = 'On';
                Handles.QuiverAxH.Toolbar.Visible = 'On';
                
                Handles.AverageIntensityImgH.Visible = 'On';
                Handles.AverageIntensityAxH.Title.Visible = 'On';
                Handles.AverageIntensityAxH.Toolbar.Visible = 'On';
                
                Handles.ImgPanel1.Visible = 'On';
                Handles.ImgPanel2.Visible = 'On';
                
                for i = 1:4
                    Handles.SmallPanels(1,i).Visible = 'Off';
                    Handles.SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'Plots'
                
                try
                    set(Handles.SwarmPlotAxH.Children,'Visible','On')
                catch
                    % do nothing
                end
                
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
                
%                 SBAverageIntensityImgH.Visible = 'On';
%                 SBAverageIntensityAxH.Title.Visible = 'On';
%                 SBAverageIntensityAxH.Toolbar.Visible = 'On';
                
                Handles.FilteredOFImgH.Visible = 'On';
                Handles.FilteredOFAxH.Title.Visible = 'On';
                Handles.FilteredOFAxH.Toolbar.Visible = 'On';
                
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
                
                
                Handles.ImgPanel2.Visible = 'On';
                
                for i = 1:2
                    Handles.SmallPanels(1,i).Visible = 'On';
                    Handles.SmallPanels(2,i).Visible = 'On';
                end
                
                Handles.ImgPanel1.Visible = 'Off';
                
            case 'Image Colocalization'
                
                % average intensity images
                Handles.PrimaryColocIntensityAxH.Title.Visible = 'On';
                Handles.PrimaryColocIntensityImgH.Visible = 'On';
                
                Handles.SecondaryColocIntensityAxH.Title.Visible = 'On';
                Handles.SecondaryColocIntensityImgH.Visible = 'On';
                
                % image masks
                Handles.PrimaryColocMaskAxH.Title.Visible = 'On';
                Handles.PrimaryColocMaskImgH.Visible = 'On';
                
                Handles.SecondaryColocMaskAxH.Title.Visible = 'On';
                Handles.SecondaryColocMaskImgH.Visible = 'On';                
                
                % pixel intensity correlation plot
                try
                    % hide the swarm plot
                    set(Handles.PixelCorrelationPlotAxH.Children,'Visible','On')
                catch
                    % do nothing
                end
                
                Handles.PixelCorrelationPlotAxH.Visible = 'On';
                Handles.PixelCorrelationPlotAxH.Title.Visible = 'On';

                % panels
                Handles.ImgPanel2.Visible = 'On';
                
                for i = 1:2
                    Handles.SmallPanels(1,i).Visible = 'On';
                    Handles.SmallPanels(2,i).Visible = 'On';
                end   
        end
        
        guidata(source,data);
        UpdateImages(source);
    end

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
        % get total channels
        nChannels = data.nChannels;
        % get current group index
        CurrentGroupIndex = data.CurrentGroupIndex;
        % update current image index for all channels
        for ChIdx = 1:nChannels
            data.Group(CurrentGroupIndex,ChIdx).CurrentImageIndex = source.Value;
        end
        % update display
        UpdateListBoxes(source);
        UpdateImages(source);
        UpdateTables(source);
    end

    function [] = ChangeActiveChannel(source,event)
        data = guidata(source);
        
        %         OldChannelIndex = data.CurrentChannelIdx;
        %         NewChannelIndex = str2num(source.SelectedTab.Tag);
        if str2num(source.SelectedTab.Tag) > data.nChannels
            source.SelectedTab = ChannelSelectorTab(data.CurrentChannelIndex);
            return
        end
        
        % set new channel index based on user selection
        data.CurrentChannelIndex = str2num(source.SelectedTab.Tag);
        % move listboxes to tab of selected channel
        Handles.GroupSelector.Parent = source.SelectedTab;
        Handles.GroupSelectorTitle.Parent = source.SelectedTab;
        Handles.ImageSelector.Parent = source.SelectedTab;
        Handles.ImageSelectorTitle.Parent = source.SelectedTab;
        Handles.ObjectSelector.Parent = source.SelectedTab;
        Handles.ObjectSelectorTitle.Parent = source.SelectedTab;
        drawnow
        % update display
        UpdateListBoxes(source);
        UpdateImages(source);
    end

    function [] = SelectFilterType(source,event)
        FilterType = source.Value;
        data = guidata(source);
        cGroupIndex = data.CurrentGroupIndex;
        cImageIndex = data.Group(cGroupIndex).CurrentImageIndex;
        
        for i = 1:length(cImageIndex)
            ii = cImageIndex(i);
            data.Group(cGroupIndex).Replicate(ii).FilterType = FilterType;
        end
        guidata(source,data);
        UpdateTables(source);
    end

    function [] = ChangeSELines(source,event)
        
        PODSData.Settings.SELines = str2num(source.Tag);
        
        for i = 1:length(hSELines.Children)
            Handles.hSELines.Children(i).Checked = 'Off';
        end
        source.Checked = 'On';
        
    end

    function [] = ChangeSESize(source,event)
        
        PODSData.Settings.SESize = str2num(source.Tag);
        
        for i = 1:length(hSESize.Children)
            Handles.hSESize.Children(i).Checked = 'Off';
        end
        source.Checked = 'On';
        
    end

    function [] = pb_FindLocalSB(source,event)
        
        data = guidata(source);
        cGroupIndex = data.CurrentGroupIndex;
        cImageIndex = data.Group(cGroupIndex).CurrentImageIndex;
        
        for i = 1:length(cImageIndex)
            data.Group(cGroupIndex).Replicate(cImageIndex(i)) = FindLocalSB(data.Group(cGroupIndex).Replicate(cImageIndex(i)),source);
            data.Group(cGroupIndex).Replicate(cImageIndex(i)).LocalSBDone = true;
            
            cImage = data.Group(cGroupIndex).Replicate(cImageIndex(i));
            
            cImage.bwFiltered = zeros(size(cImage.bw));
            cImage.OFFiltered = zeros(size(cImage.OF_image));
            
            if cImage.nObjects > 0
                for ii = 1:length(cImage.Object)
                    if cImage.Object(ii).SBRatio >= cImage.SBCutoff
                        cImage.bwFiltered(cImage.Object(ii).PixelIdxList) = 1;
                    end
                    cImage.OFFiltered(cImage.bwFiltered) = cImage.OF_image(cImage.bwFiltered);
                end
            end
        end
        
        guidata(source,data);
    end

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
        
        guidata(source,PODSData);
    end

    function [] = tbRemoveObjects(source,event)
        
        ctb = source.Parent;
        cax = ctb.Parent;
        
        roi_remove = drawrectangle(cax);
        
        vertices = roi_remove.Vertices;
        
        c1 = int16(vertices(1,1));
        r1 = int16(vertices(1,2));
        
        %c2 = int16(vertices(2,1));
        r2 = int16(vertices(2,2));
        
        %c3 = int16(vertices(3,1));
        %r3 = int16(vertices(3,2));
        
        c4 = int16(vertices(4,1));
        %r4 = int16(vertices(4,2));
        
        MainReplicate = PODSData.CurrentImage(1);
        
        MainReplicate.bw(r1:r2,c1:c4) = 0
        
        % update mask display
        PODSData.Handles.MaskImgH.CData = MainReplicate.bw;
        
        delete(roi_remove);
        
        MainReplicate.L = bwlabel(full(MainReplicate.bw),4);
        
        UpdateLog3(source,'Deleting objects and updating...','append');
        delete(MainReplicate.Object);
        MainReplicate.DetectObjects;
        MainReplicate.ObjectDetectionDone = true;
        UpdateLog3(source,'Done.','append');
    end
end