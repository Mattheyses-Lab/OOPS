function ThreshAxH = PODS_GridLayout()

    % create an instance of PODSProject
    % this object will hold ALL project data and GUI settings
    PODSData = PODSProject;

    % get the default colormap for Order Factor images
    OrderFactorMap = PODSData.Settings.OrderFactorColormap;

    % create the uifigure (main gui window)
    fH = uifigure('Name','PODS GUI',...
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
    hFileMenu = uimenu(fH,'Text','File');
        % Options for File Menu Button
        hNewProject = uimenu(hFileMenu,'Text','New Project','Callback',@NewProject);
        % load
        hLoadFFCFiles = uimenu(hFileMenu,'Text','Load FFC Files','Separator','On','Callback',@pb_LoadFFCFiles);
        hLoadFPMFiles = uimenu(hFileMenu,'Text','Load FPM Files','Callback',@pb_LoadFPMFiles);
        % save
        hSaveOF = uimenu(hFileMenu,'Text','Save Selected Image Data','Separator','On','Callback',@SaveImages);
        hSaveObjectData = uimenu(hFileMenu,'Text','Save Object Data','Callback',@SaveObjectData);
    
%% Options Menu Button - Change gui option and settings
    hOptionsMenu = uimenu(fH,'Text','Options');
        % Input File Type Option
        hFileInputType = uimenu(hOptionsMenu,'Text','File Input Type');
            % Options for input file type
            hFileInputType_nd2 = uimenu(hFileInputType,'Text','.nd2','Checked','On','Callback',@ChangeInputFileType);
            hFileInputType_tif = uimenu(hFileInputType,'Text','.tif','Checked','Off','Callback',@ChangeInputFileType);
        % Structuring element size
        hSESize = uimenu(hOptionsMenu,'Text','SE Size (px)');            
            % Options for SE size
            hSESize5px = uimenu(hSESize,'Text','5','Checked','Off','Callback',@ChangeSESize,'Tag','5');
            hSESize4px = uimenu(hSESize,'Text','4','Checked','Off','Callback',@ChangeSESize,'Tag','4');            
            hSESize3px = uimenu(hSESize,'Text','3 (default)','Checked','On','Callback',@ChangeSESize,'Tag','3');
            hSESize2px = uimenu(hSESize,'Text','2','Checked','Off','Callback',@ChangeSESize,'Tag','2');
        % Structuring element size
        hSELines = uimenu(hOptionsMenu,'Text','SE Approximation (# of lines)');            
            hSE0Lines = uimenu(hSELines,'Text','No Approximation (default,slowest)','Checked','On','Callback',@ChangeSELines,'Tag','0');
            hSE2Lines = uimenu(hSELines,'Text','2','Checked','Off','Callback',@ChangeSELines,'Tag','2');            
            hSE4Lines = uimenu(hSELines,'Text','4','Checked','Off','Callback',@ChangeSELines,'Tag','4');
            hSE6Lines = uimenu(hSELines,'Text','6','Checked','Off','Callback',@ChangeSELines,'Tag','6');            
            hSE8Lines = uimenu(hSELines,'Text','8 (fastest)','Checked','Off','Callback',@ChangeSELines,'Tag','8');

%% View Menu Button - changes view of GUI to different 'tabs'
    hTabMenu = uimenu(fH,'Text','View');
        % Tabs for 'View'
        hTabFiles = uimenu(hTabMenu,'Text','Files','MenuSelectedFcn',@TabSelection,'tag','hTabFiles');
        hTabFFC = uimenu(hTabMenu,'Text','FFC','MenuSelectedFcn',@TabSelection,'tag','hTabFFC');
        hTabGenerateMask = uimenu(hTabMenu,'Text','Generate Mask','MenuSelectedFcn',@TabSelection,'tag','hTabGenerateMask');
        hTabViewAdjustMask = uimenu(hTabMenu,'Text','View/Adjust Mask','MenuSelectedFcn',@TabSelection,'tag','hTabViewAdjustMask');
        hTabOrderFactor = uimenu(hTabMenu,'Text','Order Factor','MenuSelectedFcn',@TabSelection,'tag','hTabOrderFactor');
        hTabSBFiltering = uimenu(hTabMenu,'Text','Filtered Order Factor','MenuSelectedFcn',@TabSelection,'tag','hTabSBFiltering');
        hTabAzimuth = uimenu(hTabMenu,'Text','Azimuth','MenuSelectedFcn',@TabSelection,'tag','hTabAzimuth');
        hTabAnisotropy = uimenu(hTabMenu,'Text','Anisotropy','MenuSelectedFcn',@TabSelection,'tag','hTabAnisotropy');
        hViewObjects = uimenu(hTabMenu,'Text','View Objects','MenuSelectedFcn',@TabSelection,'tag','hViewObjects');
    
%% Process Menu Button - allows user to perform FFC, generate mask, and generate output images
    hProcessMenu = uimenu(fH,'Text','Process');    
        % Process Operations
        hProcessFFC = uimenu(hProcessMenu,'Text','Perform Flat-Field Correction','MenuSelectedFcn',@pb_FFC);
        hProcessMask = uimenu(hProcessMenu,'Text','Generate Mask','MenuSelectedFcn',@CreateMask3);
        hProcessOF = uimenu(hProcessMenu,'Text','Find Order Factor','MenuSelectedFcn',@FindOrderFactor3);
        hProcessLocalSB = uimenu(hProcessMenu,'Text','Find Local Signal:Background','MenuSelectedFcn',@pb_FindLocalSB);
    
%% Plot Menu Button
    hPlotMenu = uimenu(fH,'Text','Plot');
        % Plot choices
        hPlotViolins = uimenu(hPlotMenu,'Text','Order Factor Violins - All Objects','MenuSelectedFcn',@PlotViolins);
        hPlotOFvsSB = uimenu(hPlotMenu,'Text','Object Properties XY Scatter','MenuSelectedFcn',@PlotObjects);
    
%% Summary Menu Button
    hSummaryMenu = uimenu(fH,'Text','Summary');
    % Summary choices
    hSumaryAll = uimenu(hSummaryMenu,'Text','All Data','MenuSelectedFcn',@ShowSummaryTable);
    
%% draw the menu bar objects and pause for more predictable performance
    drawnow
    pause(0.5)    
    
%% Set up the MainGrid uigridlayout manager  

    pos = fH.Position;
    
    % width and height of the large plots
    width = round(pos(3)*0.40);
    height = width;
    height_norm = height/pos(4);
    width_norm = width/pos(3);
    
    % and the small plots
    swidth = round(width/2);
    sheight = swidth;
    swidth_norm = swidth/pos(3);
    sheight_norm = sheight/pos(4);    

    % main grid for managing layout
    MainGrid = uigridlayout(fH,[4,5]);
    MainGrid.BackgroundColor = [0 0 0];
    MainGrid.RowSpacing = 5;
    MainGrid.ColumnSpacing = 5;    
    MainGrid.RowHeight = {'0.5x',swidth,swidth,'0.3x'};
    MainGrid.ColumnWidth = {'0.5x',sheight,sheight,sheight,sheight};
    
%% Create the non-image panels (Summary, Selector, Settings, Log)    
    % panel to show project summary
    AppInfoPanel = uipanel(MainGrid,'Visible','Off','AutoResizeChildren','Off','SizeChangedFcn',@AppInfoPanelSizeChanged);
    AppInfoPanel.Title = 'Project Summary';
    AppInfoPanel.Layout.Row = [1 3];
    AppInfoPanel.Layout.Column = 1;
    % panel to hold ImgInfoTabGroup (Group/Image/Object) selection
    SelectorPanel = uipanel(MainGrid,'Visible','Off','AutoResizeChildren','Off');
    SelectorPanel.Title = 'Group/Image/Object Selection';
    SelectorPanel.Layout.Row = 1;
    SelectorPanel.Layout.Column = [2 3];
    % panel to hold ImgOperationsTabGroup (currently just for interactive thresholding)
    SettingsPanel = uipanel(MainGrid,'Visible','Off','AutoResizeChildren','Off');
    SettingsPanel.Title = 'Image Operations';
    SettingsPanel.Layout.Row = 1;
    SettingsPanel.Layout.Column = [4 5];    
    % panel to display log messages (updates user on running/completed processes)
    LogPanel = uipanel(MainGrid,'Visible','Off','AutoResizeChildren','Off','SizeChangedFcn',@LogPanelSizeChanged);
    LogPanel.Title = 'Log Window';
    LogPanel.Layout.Row = 4;
    LogPanel.Layout.Column = [1 5];

%% Small Image Panels
    % tags for small panels                
    panel_tags = ['Panel_1-1' 'Panel_1-2' 'Panel_1-3' 'Panel_1-4';...
                  'Panel_2-1' 'Panel_2-2' 'Panel_2-3' 'Panel_2-4'];

    for SmallPanelRows = 1:2
        for SmallPanelColumns = 1:4
            SmallPanels(SmallPanelRows,SmallPanelColumns) = uipanel(MainGrid,'Visible','Off');
            %SmallPanels(SmallPanelRows,SmallPanelColumns).Title = ['Small Panel ',num2str((SmallPanelRows-1)*4+SmallPanelColumns)];
            SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Row = SmallPanelRows+1;
            SmallPanels(SmallPanelRows,SmallPanelColumns).Layout.Column = SmallPanelColumns+1;
            SmallPanels(SmallPanelRows,SmallPanelColumns).Tag = panel_tags(SmallPanelRows,SmallPanelColumns);
            % Important to set so we can resize children of panels with expected behavior
            SmallPanels(SmallPanelRows,SmallPanelColumns).AutoResizeChildren = 'Off';
        end
    end    
    
%% Large Image Panels
    % first one (lefthand panel)
    ImgPanel1 = uipanel(MainGrid,'Visible','off','SizeChangedFcn',@ImgPanel1SizeChanged);
    ImgPanel1.Layout.Row = [2 3];
    ImgPanel1.Layout.Column = [2 3];
    %ImgPanel1.Title = 'Large Panel 1'
    ImgPanel1.AutoResizeChildren = 'Off';

    % second one (righthand panel)               
    ImgPanel2 = uipanel(MainGrid,'Visible','off','SizeChangedFcn',@ImgPanel2SizeChanged);    
    ImgPanel2.Layout.Row = [2 3];
    ImgPanel2.Layout.Column = [4 5];    
    %ImgPanel2.Title = 'Large Panel 2';
    ImgPanel2.AutoResizeChildren = 'Off';
    
    % add these to an array so we can change their settings simultaneously
    LargePanels = [ImgPanel1,ImgPanel2];
    
%% draw all the panels and pause briefly for more predictable performance
    drawnow
    pause(0.1)
    
%% Image Info Tab Group (selection boxes for group/image/objects)

    ImgInfoTabGroup = uitabgroup(SelectorPanel,'SelectionChangedFcn',@ChangeActiveChannel,'Units','Normalized','Position',[0 0 1 1],'AutoResizeChildren','Off','SizeChangedFcn',@ImgInfoTabGroupSizeChanged);
    ChannelSelectorTab(1) = uitab(ImgInfoTabGroup,'Title','Channel 1','BackgroundColor','Black','Tag','1'); 
    ChannelSelectorTab(2) = uitab(ImgInfoTabGroup,'Title','Channel 2','BackgroundColor','Black','Tag','2');    

%% Image Operations Tab Group (thresholding/colormaps/etc)

    ImgOperationsTabGroup = uitabgroup(SettingsPanel,'Units','Normalized','Position',[0 0 1 1],'AutoResizeChildren','Off','SizeChangedFcn',@ImgOperationsTabGroupSizeChanged);
    % tabs for tabgroup container
    ImgOperationsTab(1) = uitab(ImgOperationsTabGroup,'Title','Mask Threshold','BackgroundColor','Black','tag','AdjustThresholdTab');                       
    ImgOperationsTab(2) = uitab(ImgOperationsTabGroup,'Title','Colormaps','BackgroundColor','Black','tag','ColorSettings');    

%% Interactive User Thresholding    
    % axes to show intensity histogram
    ThreshAxH = uiaxes(ImgOperationsTab(1),...
        'Units','Normalized',...
        'Position',[0 0 1 1],...
        'Color',[0 0 0],...
        'Visible','On',...
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
    ThreshAxH.Toolbar.Visible = 'Off';
    % generate some random data (1024x1024) for histogram placeholder
    RandomData = rand(1024,1024);
    % build histogram from random data
    [IntensityBinCenters,IntensityHistPlot] = BuildHistogram(RandomData);
    % add histogram info to bar plot, place plot in thresholding axes
    ThreshBar = bar(ThreshAxH,IntensityBinCenters,IntensityHistPlot,...
                     'FaceColor','Yellow',...
                     'EdgeColor','None',...
                     'PickableParts','None');
    % vertical line with draggable behavior for interactive thresholding             
    CurrentThresholdLine = xline(ThreshAxH,0.5,'-',{'Threshold = 0.5'},...
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
    LogWindow = uitextarea(LogPanel,...
        'Position',[1 1 LogPanel.InnerPosition(3) LogPanel.InnerPosition(4)],...
        'HorizontalAlignment','left',...
        'enable','on',...
        'tag','LogWindow',...
        'BackgroundColor','black',...
        'FontColor','yellow',...
        'FontName','Courier',...
        'Value',{'Log Window';'Drawing Containers and Tables...'},...
        'Visible','Off');
    
%% Group Selection Box
    pos = ChannelSelectorTab(1).InnerPosition;
    small_width = (0.5*pos(3)-25)*0.5;
    large_width = small_width*2+10;
    
    GroupSelector = uilistbox('parent',ChannelSelectorTab(1),...
                              'Position', [10 10 small_width pos(4)-30],...
                              'enable','on',...
                              'tag','GroupListBox',...
                              'Items',{'Start a new project...'},...
                              'ValueChangedFcn',@ChangeActiveGroup,...
                              'FontColor','Black',...
                              'MultiSelect','Off',...
                              'Enable',0);                
    lst_pos = GroupSelector.Position;
    GroupSelectorTitle = uilabel('Parent',ChannelSelectorTab(1),...
                                 'Position', [10 lst_pos(4)+10 small_width 20],...
                                 'FontColor','Yellow',...
                                 'Text','<b>Select Group</b>',...
                                 'HorizontalAlignment','center',...
                                 'Interpreter','html');
                             
%% Image Selection Box
    ImageSelector = uilistbox('parent',ChannelSelectorTab(1),...
                              'Position', [lst_pos(3)+20 10 large_width lst_pos(4)],...
                              'enable','on',...
                              'tag','ImageListBox',...
                              'Items',{'Select group to view its images...'},...
                              'ValueChangedFcn',@ChangeActiveImage,...
                              'MultiSelect','on',...
                              'FontColor','Black',...
                              'Enable',0);                    
    lst_pos2 = ImageSelector.Position;                      
    ImageSelectorTitle = uilabel('Parent',ChannelSelectorTab(1),...
                                 'Position', [lst_pos2(1) lst_pos2(4)+10 large_width 20],...
                                 'FontColor','Yellow',...
                                 'Text','<b>Select Image</b>',...                                 
                                 'HorizontalAlignment','center',...
                                 'Interpreter','html');

%% Object Selection Box
    ObjectSelector = uilistbox('parent',ChannelSelectorTab(1),...
                               'Position', [lst_pos(3)+lst_pos2(3)+30 10 small_width lst_pos(4)],...
                               'enable','on',...
                               'tag','ObjectListBox',...
                               'Items',{'Select image to view objects...'},...
                               'ValueChangedFcn',@ChangeActiveObject,...
                               'MultiSelect','off',...
                               'FontColor','Black',...
                               'Enable',0);                   
    lst_pos3 = ObjectSelector.Position;                      
    ObjectSelectorTitle = uilabel('Parent',ChannelSelectorTab(1),...
                                  'Position', [lst_pos3(1) lst_pos3(4)+10 small_width 20],...
                                  'FontColor','Yellow',...
                                  'Text','<b>Select Object</b>',...
                                  'HorizontalAlignment','Center',...
                                  'Interpreter','html');                             

%% Summary table for current group/image/object
    ProjectDataTable = uilabel(AppInfoPanel,...
                               'Position',[10 10 AppInfoPanel.InnerPosition(3)-20 AppInfoPanel.InnerPosition(4)-20],...
                               'tag','ProjectDataTable',...
                               'FontColor','Yellow',...
                               'FontName','Courier',...
                               'BackgroundColor','Black',...
                               'VerticalAlignment','Top',...
                               'Interpreter','html');                           

    ProjectDataTable.Text = {['Start a new project first...']};
    
%%   

%% AXES AND IMAGE PLACEHOLDERS
	
    % empty placeholder image
	emptyimage = rand(1024,1024)

    greenmap = PODSData.Settings.AllColormaps.Green;

%     SmallPanelWidth = SmallPanels(1,1).InnerPosition(3);
%     SmallPanelHeight = SmallPanels(1,1).InnerPosition(4);
%     
%     LargePanelWidth = ImgPanel1.InnerPosition(3);
%     LargePanelHeight = ImgPanel1.InnerPosition(4);


    AllSmallAxes = [];
    AllLargeAxes = [];
    
%% Small Images    
    %% FLAT-FIELD IMAGES
    for i = 1:4
        FFCAxH(i) = uiaxes('Parent',SmallPanels(1,i),...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                           'Tag',['FFC' num2str((i-1)*45)],...
                           'XTick',[],...
                           'YTick',[]);      
        % save original values                          
        pbarOriginal = FFCAxH(i).PlotBoxAspectRatio;
        tagOriginal = FFCAxH(i).Tag;        
        % place placeholder image on axis
        FFCImgH(i) = imshow(full(emptyimage),'Parent',FFCAxH(i));
        % set a tag so our callback functions can find the image
        set(FFCImgH(i),'Tag',['FFCImage' num2str((i-1)*45)]);

        % restore original values after imshow() call
        FFCAxH(i) = restore_axis_defaults(FFCAxH(i),pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal

        FFCAxH(i) = SetAxisTitle(FFCAxH(i),['Flat-Field Image (' num2str((i-1)*45) '^{\circ} Excitation)']);
        FFCAxH(i).Colormap = greenmap;
        
        AllSmallAxes(end+1) = FFCAxH(i);
    end
    %linkaxes(FFCAxH);
    %% RAW INTENSITY IMAGES
    for i = 1:4
        RawIntensityAxH(i) = uiaxes('Parent',SmallPanels(2,i),...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                                    'Tag',['Raw' num2str((i-1)*45)],...
                                    'XTick',[],...
                                    'YTick',[]);
        % save original values                          
        pbarOriginal = RawIntensityAxH(i).PlotBoxAspectRatio;
        tagOriginal = RawIntensityAxH(i).Tag;        
        % place placeholder image on axis
        RawIntensityImgH(i) = imshow(full(emptyimage),'Parent',RawIntensityAxH(i));
        % set a tag so our callback functions can find the image
        set(RawIntensityImgH(i),'Tag',['RawImage' num2str((i-1)*45)]);
        
        % restore original values after imshow() call
        RawIntensityAxH(i) = restore_axis_defaults(RawIntensityAxH(i),pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        
        RawIntensityAxH(i) = SetAxisTitle(RawIntensityAxH(i),['Raw Intensity (' num2str((i-1)*45) '^{\circ} Excitation)']);
        RawIntensityAxH(i).Colormap = greenmap;
        
        AllSmallAxes(end+1) = RawIntensityAxH(i);
        
    end
    %% FLAT-FIELD CORRECTED INTENSITY
    for i = 1:4
        PolFFCAxH(i) = uiaxes('Parent',SmallPanels(2,i),...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                              'Tag',['PolFFC' num2str((i-1)*45)],...
                              'XTick',[],...
                              'YTick',[]);
        % save original values                          
        pbarOriginal = PolFFCAxH(i).PlotBoxAspectRatio;
        tagOriginal = PolFFCAxH(i).Tag;
        % place placeholder image on axis
        PolFFCImgH(i) = imshow(full(emptyimage),'Parent',PolFFCAxH(i));
        % set a tag so our callback functions can find the image
        set(PolFFCImgH(i),'Tag',['PolFFCImage' num2str((i-1)*45)]);

        % restore original values after imshow() call
        PolFFCAxH(i) = restore_axis_defaults(PolFFCAxH(i),pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        
        % set axis title
        PolFFCAxH(i) = SetAxisTitle(PolFFCAxH(i),['Flat-Field Corrected Intensity (' num2str((i-1)*45) '^{\circ} Excitation)']);
        
        PolFFCAxH(i).Colormap = greenmap;
        
        PolFFCAxH(i).Toolbar.Visible = 'Off';
        
        PolFFCImgH(i).Visible = 'Off';
        PolFFCAxH(i).Title.Visible = 'Off';
        
        AllSmallAxes(end+1) = PolFFCAxH(i);
    end
    %% MASKING STEPS
    for i = 1:4
        switch i
            case 1
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(1,1),...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                                      'Tag','MStepsIntensity',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Average Intensity';
                image_tag = 'MStepsIntensityImage';
            case 2
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(1,2),...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                                      'Tag','MStepsBackground',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Background Intensity';
                image_tag = 'MStepsBackgroundImage';                                
            case 3
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(2,1),...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                                      'Tag','MStepsBGSubtracted',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Background Subtracted Intensity';
                image_tag = 'MStepsBGSubtractedImage';                                
            case 4
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(2,2),...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                                      'Tag','MStepsMedianFiltered',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Median Filtered';
                image_tag = 'MStepsMedianFilteredImage';                                
        end
                                               
        % save original values                          
        pbarOriginal = MStepsAxH(i).PlotBoxAspectRatio;
        tagOriginal = MStepsAxH(i).Tag;        
        % place placeholder image on axis
        MStepsImgH(i) = imshow(full(emptyimage),'Parent',MStepsAxH(i));
        % set a tag so our callback functions can find the image
        set(MStepsImgH(i),'Tag',image_tag);

        % restore original values after imshow() call
        MStepsAxH(i) = restore_axis_defaults(MStepsAxH(i),pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        
        % set axis title
        MStepsAxH(i) = SetAxisTitle(MStepsAxH(i),image_title);
        
        MStepsAxH(i).Colormap = greenmap;
        
        MStepsAxH(i).Toolbar.Visible = 'Off';
        
        MStepsImgH(i).Visible = 'Off';
        MStepsAxH(i).Title.Visible = 'Off';
        
        AllSmallAxes(end+1) = MStepsAxH(i);
    end
%% Large Images
    for i = 1:1
        %% AVERAGE INTENSITY
        AverageIntensityAxH = uiaxes(ImgPanel1,...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                                     'Tag','AverageIntensity',...
                                     'XTick',[],...
                                     'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = AverageIntensityAxH.PlotBoxAspectRatio;
        tagOriginal = AverageIntensityAxH.Tag;
        % place placeholder image on axis
        AverageIntensityImgH = imshow(full(emptyimage),'Parent',AverageIntensityAxH);
        % set a tag so our callback functions can find the image
        set(AverageIntensityImgH,'Tag','AverageIntensityImage');

        % restore original values after imshow() call
        AverageIntensityAxH = restore_axis_defaults(AverageIntensityAxH,pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        
        % set axis title
        AverageIntensityAxH = SetAxisTitle(AverageIntensityAxH,'Average Intensity (Flat-Field Corrected)');
        % set celormap
        AverageIntensityAxH.Colormap = greenmap;
        % hide axes toolbar
        AverageIntensityAxH.Toolbar.Visible = 'Off';
        % hide image/axes
        AverageIntensityImgH.Visible = 'Off';
        AverageIntensityAxH.Title.Visible = 'Off';
        %% Order Factor
        % create an axis, child of a panel, to fill the container
        OrderFactorAxH = uiaxes(ImgPanel2,...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                                'Tag','OrderFactor',...
                                'XTick',[],...
                                'YTick',[],...
                                'CLim',[0 1]);
        % save original values to be restored after calling imshow()
        pbarOriginal = OrderFactorAxH.PlotBoxAspectRatio;
        tagOriginal = OrderFactorAxH.Tag;
        % place placeholder image on axis
        OrderFactorImgH = imshow(full(emptyimage),'Parent',OrderFactorAxH);
        % set a tag so our callback functions can find the image
        set(OrderFactorImgH,'Tag','OrderFactorImage');
        % restore original values after imshow() call
        OrderFactorAxH = restore_axis_defaults(OrderFactorAxH,pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        
        % set axis title
        OrderFactorAxH = SetAxisTitle(OrderFactorAxH,'Pixel-by-pixel Order Factor');
        % change active axis so we can make custom colorbar/colormap
        axes(OrderFactorAxH)
        % custom colormap/colorbar
        [mycolormap,mycolormap_noblack] = MakeRGB;
        OFCbar = colorbar('location','east','color','white','tag','OFCbar');
        
        colormap(gca,OrderFactorMap);
        
        OFCbar.Visible = 'Off';
        OrderFactorAxH.Toolbar.Visible = 'Off';

        OrderFactorImgH.Visible = 'Off';
        OrderFactorAxH.Title.Visible = 'Off';
        %% Azimuth
        % create an axis, child of a panel, to fill the container
        AzimuthAxH = uiaxes(ImgPanel2,...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                            'Tag','ColoredAzimuth',...
                            'XTick',[],...
                            'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = AzimuthAxH.PlotBoxAspectRatio;
        tagOriginal = AzimuthAxH.Tag;
        % place placeholder image on axis
        AzimuthImgH = imshow(full(emptyimage),'Parent',AzimuthAxH);
        % set a tag so our callback functions can find the image
        set(AzimuthImgH,'Tag','ColoredAzimuthImage');

        % restore original values after imshow() call
        AzimuthAxH = restore_axis_defaults(AzimuthAxH,pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        % set axis title
        AzimuthAxH = SetAxisTitle(AzimuthAxH,'Colored Azimuth Image');
        
        AzimuthAxH.Toolbar.Visible = 'Off';
        
        AzimuthImgH.Visible = 'Off';
        AzimuthAxH.Title.Visible = 'Off';    
        %% Anisotropy
        % create an axis, child of a panel, to fill the container
        AnisotropyAxH = uiaxes(ImgPanel2,...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                               'Tag','Anisotropy',...
                               'XTick',[],...
                               'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = AnisotropyAxH.PlotBoxAspectRatio;
        tagOriginal = AnisotropyAxH.Tag;
        % place placeholder image on axis
        AnisotropyImgH = imshow(full(emptyimage),'Parent',AnisotropyAxH);
        % set a tag so our callback functions can find the image
        set(AnisotropyImgH,'Tag','AnisotropyImage');

        % restore original values after imshow() call
        AnisotropyAxH = restore_axis_defaults(AnisotropyAxH,pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        % set axis title
        AnisotropyAxH = SetAxisTitle(AnisotropyAxH,'Anisotropy Image');
        
        AnisotropyAxH.Visible = 'Off';
        
        AnisotropyAxH.Toolbar.Visible = 'Off';

        AnisotropyImgH.Visible = 'Off';
        AnisotropyAxH.Title.Visible = 'Off';
        %% S-B Filtering
        % create an axis, child of a panel, to fill the container
        SBAverageIntensityAxH = uiaxes(ImgPanel1,...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                                       'Tag','SBAverageIntensity',...
                                       'XTick',[],...
                                       'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = SBAverageIntensityAxH.PlotBoxAspectRatio;
        tagOriginal = SBAverageIntensityAxH.Tag;
        % place placeholder image on axis
        SBAverageIntensityImgH = imshow(full(emptyimage),'Parent',SBAverageIntensityAxH);
        % set a tag so our callback functions can find the image
        set(SBAverageIntensityImgH,'Tag','SBAverageIntensityImage');

        % restore original values after imshow() call
        SBAverageIntensityAxH = restore_axis_defaults(SBAverageIntensityAxH,pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        
        % set axis title
        SBAverageIntensityAxH = SetAxisTitle(SBAverageIntensityAxH,'Average Intensity (S:B Overlay)');

        SBAverageIntensityAxH.Colormap = greenmap;
        
        SBAverageIntensityAxH.Toolbar.Visible = 'Off';
                
        SBAverageIntensityImgH.Visible = 'Off';
        SBAverageIntensityAxH.Title.Visible = 'Off';    
        %% MASK
        % create an axis, child of a panel, to fill the container
        MaskAxH = uiaxes(ImgPanel2,...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                         'Tag','Mask',...
                         'XTick',[],...
                         'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = MaskAxH.PlotBoxAspectRatio;
        tagOriginal = MaskAxH.Tag;
        % place placeholder image on axis
        MaskImgH = imshow(full(emptyimage),'Parent',MaskAxH);
        % set a tag so our callback functions can find the image
        set(MaskImgH,'Tag','MaskImage');
                    
        % restore original values after imshow() call
        MaskAxH = restore_axis_defaults(MaskAxH,pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        
        % set axis title
        MaskAxH = SetAxisTitle(MaskAxH,'Binary Mask');
        
        MaskAxH.Toolbar.Visible = 'Off';

        MaskImgH.Visible = 'Off';
        MaskAxH.Title.Visible = 'Off';
        %% SB FILTERED Order Factor
        % create an axis, child of a panel, to fill the container
        FilteredOFAxH = uiaxes(ImgPanel2,...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
                           'Tag','FilteredOF',...
                           'XTick',[],...
                           'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = FilteredOFAxH.PlotBoxAspectRatio;
        tagOriginal = FilteredOFAxH.Tag;
        % place placeholder image on axis
        FilteredOFImgH = imshow(full(emptyimage),'Parent',FilteredOFAxH);
        % set a tag so our callback functions can find the image
        set(FilteredOFImgH,'Tag','FilteredOFImage');

        % restore original values after imshow() call
        FilteredOFAxH = restore_axis_defaults(FilteredOFAxH,pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        
        % set axis title
        FilteredOFAxH = SetAxisTitle(FilteredOFAxH,'SB-Filtered Order Factor');
        
        % change active axis so we can make custom colorbar/colormap
        axes(FilteredOFAxH)
        % custom colormap/colorbar
        [mycolormap,mycolormap_noblack] = MakeRGB;
        OFCbar2 = colorbar('location','east','color','white','tag','OFCbar2');
        
        colormap(gca,OrderFactorMap);
        
        OFCbar2.Visible = 'Off';        

        FilteredOFAxH.Toolbar.Visible = 'Off';

        FilteredOFImgH.Visible = 'Off';
        FilteredOFAxH.Title.Visible = 'Off';
        %% Azimuth
        % create an axis, child of a panel, to fill the container
        QuiverAxH = uiaxes(ImgPanel2,...
                            'Units','Normalized',...
                            'InnerPosition',[0 0 1 1],...
                            'Tag','QuiverAzimuth',...
                            'XTick',[],...
                            'YTick',[],...
                            'Color','Black');
        % set axis title
        QuiverAxH = SetAxisTitle(QuiverAxH,'Azimuth Quiver Plot');
        
        QuiverAxH.Toolbar.Visible = 'Off';
        QuiverAxH.YDir = 'Reverse';
        QuiverAxH.Visible = 'Off';
        QuiverAxH.Title.Visible = 'Off';
        QuiverAxH.Title.Color = 'White';

%% Object FFCIntensity Image

        ObjectPolFFCAxH = uiaxes(SmallPanels(1,1),...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
            'Tag','ObjectPolFFC',...
            'XTick',[],...
            'YTick',[]);
        % save original values
        pbarOriginal = ObjectPolFFCAxH.PlotBoxAspectRatio;
        tagOriginal = ObjectPolFFCAxH.Tag;
        % place placeholder image on axis
        ObjectPolFFCImgH = imshow(full(emptyimage),'Parent',ObjectPolFFCAxH);
        % set a tag so our callback functions can find the image
        set(ObjectPolFFCImgH,'Tag','ObjectPolFFCImage');
        % restore original values after imshow() call
        ObjectPolFFCAxH = restore_axis_defaults(ObjectPolFFCAxH,pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        ObjectPolFFCAxH = SetAxisTitle(ObjectPolFFCAxH,'Flat-Field-Corrected Average Intensity');
        ObjectPolFFCAxH.Colormap = greenmap;
        ObjectPolFFCAxH.Toolbar.Visible = 'Off';
        ObjectPolFFCAxH.Title.Visible = 'Off';
        ObjectPolFFCImgH.Visible = 'Off';
        
%% Object Binary Image

        ObjectMaskAxH = uiaxes(SmallPanels(1,2),...
                           'Units','Normalized',...
                           'InnerPosition',[0 0 1 1],...
            'Tag','ObjectMask',...
            'XTick',[],...
            'YTick',[]);
        % save original values
        pbarOriginal = ObjectMaskAxH.PlotBoxAspectRatio;
        tagOriginal = ObjectMaskAxH.Tag;
        % place placeholder image on axis
        ObjectMaskImgH = imshow(full(emptyimage),'Parent',ObjectMaskAxH);
        % set a tag so our callback functions can find the image
        set(ObjectMaskImgH,'Tag','ObjectMaskImage');
        % restore original values after imshow() call
        ObjectMaskAxH = restore_axis_defaults(ObjectMaskAxH,pbarOriginal,tagOriginal);
        clear pbarOriginal tagOriginal
        ObjectMaskAxH = SetAxisTitle(ObjectMaskAxH,'Object Binary Image');
        ObjectMaskAxH.Title.Visible = 'Off';
        ObjectMaskAxH.Toolbar.Visible = 'Off';
        ObjectMaskImgH.Visible = 'Off';
        
%% Object Order Factor Contour

        ObjectOFContourAxH = uiaxes(SmallPanels(2,2),...
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

        SetAxisTitle(ObjectOFContourAxH,'OF 2D Contour');
        colormap(gca,OrderFactorMap);

        ObjectOFContourAxH.YDir = 'Reverse';
        ObjectOFContourAxH.Visible = 'Off';
        ObjectOFContourAxH.Toolbar.Visible = 'Off';
        ObjectOFContourAxH.Title.Visible = 'Off';
        ObjectOFContourAxH.Title.Color = 'White';

    end

    %drawnow
    
    old = LogWindow.Value;
    new = old;
    new{length(old)+1} = 'Drawing Axes';
    LogWindow.Value = new;
    clear old new    

    % set figure to visible to draw containers
    fH.Visible = 'On'
    drawnow
    pause(0.1)           
    
    set(AppInfoPanel,'Visible','On');
    set(SettingsPanel,'Visible','On');
    set(SelectorPanel,'Visible','On');
    set(LogPanel,'Visible','On');
    set(LogWindow,'Visible','On');
    set(SmallPanels,'Visible','On');

%% Collect obj handles and add to PODSData

    % add guihandles to PODSData struct
    PODSData.Handles = guihandles;
    
    %PODSData.Handles.GraphicsRootObject = GraphicsRootObject;
    
    % Main Figure
    PODSData.Handles.fH = fH;    
    
    % Handles for flat-field images/axes
    PODSData.Handles.FFCAxH = FFCAxH;
    PODSData.Handles.FFCImgH = FFCImgH;
    
    % ...to the small image panels
    PODSData.Handles.SmallPanels = SmallPanels;
    
    PODSData.Handles.ImgInfoTabGroup = ImgInfoTabGroup;
    PODSData.Handles.ImgOperationsTabGroup = ImgOperationsTabGroup;
    
    % ...masking steps images/axes
    PODSData.Handles.MStepsAxH = MStepsAxH;
    PODSData.Handles.MStepsImgH = MStepsImgH;
    
    % ...flat-field corrected intensity images/axes
    PODSData.Handles.PolFFCAxH = PolFFCAxH;
    PODSData.Handles.PolFFCImgH = PolFFCImgH;
    
    % ...raw intensity images images/axes
    PODSData.Handles.RawIntensityAxH = RawIntensityAxH;
    PODSData.Handles.RawIntensityImgH = RawIntensityImgH;
    
    % ...average intensity
    PODSData.Handles.AverageIntensityAxH = AverageIntensityAxH;
    PODSData.Handles.AverageIntensityImgH = AverageIntensityImgH;
    
    % ...order factor
    PODSData.Handles.OrderFactorAxH = OrderFactorAxH;
    PODSData.Handles.OrderFactorImgH = OrderFactorImgH;
    
    % ...azimuth
    PODSData.Handles.AzimuthAxH = AzimuthAxH;
    PODSData.Handles.AzimuthImgH = AzimuthImgH;
    
    % ...anisotropy
    PODSData.Handles.AnisotropyAxH = AnisotropyAxH;
    PODSData.Handles.AnisotropyImgH = AnisotropyImgH;
    
    % ...SB-filtered intensity
    PODSData.Handles.SBAverageIntensityAxH = SBAverageIntensityAxH;
    PODSData.Handles.SBAverageIntensityImgH = SBAverageIntensityImgH;
    
    % ...Binary mask
    PODSData.Handles.MaskAxH = MaskAxH;
    PODSData.Handles.MaskImgH = MaskImgH;
        
    % ...SB-filtered binary mask
    PODSData.Handles.FilteredOFAxH = FilteredOFAxH;
    PODSData.Handles.FilteredOFImgH = FilteredOFImgH;
    
    PODSData.Handles.QuiverAxH = QuiverAxH;
    
    % ...large image panels
    PODSData.Handles.ImgPanel1 = ImgPanel1;
    PODSData.Handles.ImgPanel2 = ImgPanel2;
    
    % ...colorbars
    PODSData.Handles.OFCbar = OFCbar;
    PODSData.Handles.OFCbar2 = OFCbar2;
    
    % ...Mask threshold control
    PODSData.Handles.ThreshAxH = ThreshAxH;
    PODSData.Handles.ThreshBar = ThreshBar;
    PODSData.Handles.CurrentThresholdLine = CurrentThresholdLine;

    % ...Selection
    PODSData.Handles.GroupSelector = GroupSelector;
    PODSData.Handles.ImageSelector = ImageSelector;
    PODSData.Handles.ObjectSelector = ObjectSelector;
    
    % ...to 2D object images
    PODSData.Handles.ObjectPolFFCAxH = ObjectPolFFCAxH;
    PODSData.Handles.ObjectPolFFCImgH = ObjectPolFFCImgH;
    PODSData.Handles.ObjectMaskAxH = ObjectMaskAxH;
    PODSData.Handles.ObjectMaskImgH = ObjectMaskImgH;
    PODSData.Handles.ObjectOFContourAxH = ObjectOFContourAxH;
    
    % update guidata with handles structure                     
    guidata(fH,PODSData)
    
    linkaxes(FFCAxH,'xy');
    linkaxes(RawIntensityAxH,'xy');    
    
    
    
    

%% Callbacks controlling dynamic resizing of GUI containers   
    %  RESET IMAGE CONTAINER SIZES UPON CHANGING SIZE OF MAIN FIGURE WINDOW
    function [] = ResetContainerSizes(source,event)
        
        % get changed size of main window
        NewWindowSize = fH.InnerPosition;

        % calculate new size of large images
        LargeWidth = round(NewWindowSize(3)*0.40);

        % calculate new size of small images
        SmallWidth = round(LargeWidth/2);
        SmallHeight = SmallWidth;

        % update grid size to maatch new image sizes
        MainGrid.RowHeight = {'0.5x',SmallWidth,SmallWidth,'0.3x'};
        MainGrid.ColumnWidth = {'1x',SmallHeight,SmallHeight,SmallHeight,SmallHeight};

        drawnow
        pause(0.1)
        
        %set(AllSmallAxes,'InnerPosition',[0 0 1 1]);

    end

    function [] = ImgInfoTabGroupSizeChanged(source,event)
        currentpos = ChannelSelectorTab(1).InnerPosition;
        small_box_width = (0.5*currentpos(3)-25)*0.5;
        large_box_width = small_box_width*2+10;
        % set new position for group selector box and label
        set(GroupSelector,'Position',[10 10 small_box_width currentpos(4)-30]);
        set(GroupSelectorTitle,'Position',[10 GroupSelector.Position(4)+10 small_box_width 20]);
        % set new position for image selector box and label
        set(ImageSelector,'Position',[GroupSelector.Position(3)+20 10 large_box_width GroupSelector.Position(4)]);
        set(ImageSelectorTitle,'Position',[ImageSelector.Position(1) ImageSelector.Position(4)+10 large_box_width 20]);
        % set new position for object selector box and label
        set(ObjectSelector,'Position',[GroupSelector.Position(3)+ImageSelector.Position(3)+30 10 small_box_width GroupSelector.Position(4)]);
        set(ObjectSelectorTitle,'Position',[ObjectSelector.Position(1) ObjectSelector.Position(4)+10 small_box_width 20]);
    end

    function [] = LogPanelSizeChanged(source,event)
        set(LogWindow,'Position',[1 1 LogPanel.InnerPosition(3) LogPanel.InnerPosition(4)]);
    end

    function [] = ImgOperationsTabGroupSizeChanged(source,event)
        set(ThreshAxH,'Position',[0 0 1 1]);
    end

    function [] = AppInfoPanelSizeChanged(source,event)
        set(ProjectDataTable,'Position',[10 10 AppInfoPanel.InnerPosition(3)-20 AppInfoPanel.InnerPosition(4)-20]);
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
        fH.WindowButtonMotionFcn = @MoveThresholdLine;
        fH.WindowButtonUpFcn = @StopMovingAndSetThresholdLine;
    end
    % Update display while thresh line is moving
    function [] = MoveThresholdLine(source,event)
        CurrentThresholdLine.Value = round(ThreshAxH.CurrentPoint(1,1),4);
        CurrentThresholdLine.Label = {['Threshold = ',num2str(CurrentThresholdLine.Value)]};
        %drawnow limitrate
        %testing below
        ThresholdLineMoving(source,CurrentThresholdLine.Value);
        drawnow limitrate
    end
    % Set final thresh position and restore callbacks
    function [] = StopMovingAndSetThresholdLine(source,event)
        CurrentThresholdLine.Value = round(ThreshAxH.CurrentPoint(1,1),4);
        CurrentThresholdLine.Label = {['Threshold = ',num2str(CurrentThresholdLine.Value)]};
        fH.WindowButtonMotionFcn = '';
        fH.WindowButtonUpFcn = '';
        ThresholdLineMoved(source,CurrentThresholdLine.Value);
        drawnow limitrate
    end

    %% NESTED FUNCTIONS

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
            btn.Tooltip = 'Zoom to Cursor';
            btn.ValueChangedFcn = @ZoomToCursor;
        end
        
        function addApplyMaskToolbarBtn
            btn = axtoolbarbtn(tb,'state');
            btn.Icon = 'MaskIcon.png';
            btn.Tooltip = 'Apply Mask';
            btn.ValueChangedFcn = @tbApplyMaskStateChanged;
            btn.Tag = ['ApplyMask',axH.Tag];
        end
        
        function addRemoveObjectsToolbarBtn
            btn = axtoolbarbtn(tb,'push');
            btn.Icon = 'RemoveObjects.png';
            btn.Tooltip = 'Remove Objects in ROI';
            btn.ButtonPushedFcn = @tbRemoveObjects;
            btn.Tag = ['RemoveObjects',axH.Tag];            
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
    %% CALLBACKS
    
    function [] = TabSelection(source,event)

        NewTab = source.Text;
        
        data = guidata(source);
        
        OldTab = data.Settings.CurrentTab;
        
        UpdateLog3(source,[NewTab, ' Tab Selected'],'append');
        
        data.Settings.PreviousTab = data.Settings.CurrentTab;
        
        data.Settings.CurrentTab = source.Text;

        switch data.Settings.PreviousTab
            case 'Files'
                try    
                    linkaxes(FFCAxH,'off');
                    linkaxes(RawIntensityAxH,'off');
                catch
                    % do nothing
                end
                
                for i = 1:4
                    RawIntensityAxH(i).Parent = SmallPanels(1,i);
                    
                    FFCImgH(i).Visible = 'Off';
                    FFCAxH(i).Title.Visible = 'Off';
                    FFCAxH(i).Toolbar.Visible = 'Off';
                    
                    RawIntensityImgH(i).Visible = 'Off';
                    RawIntensityAxH(i).Title.Visible = 'Off';
                    RawIntensityAxH(i).Toolbar.Visible = 'Off';
                    
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                    
                end
                
            case 'FFC'
                
                for i = 1:4
                    RawIntensityAxH(i).Parent = SmallPanels(2,i);
                    
                    PolFFCImgH(i).Visible = 'Off';
                    PolFFCAxH(i).Title.Visible = 'Off';
                    PolFFCAxH(i).Toolbar.Visible = 'Off';
                    
                    RawIntensityImgH(i).Visible = 'Off';
                    RawIntensityAxH(i).Title.Visible = 'Off';
                    RawIntensityAxH(i).Toolbar.Visible = 'Off';
                    
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'Generate Mask'
                try
                    linkaxes([MStepsAxH,MaskAxH],'off');
                catch
                    % do nothing
                end
                
                MaskImgH.Visible = 'Off';
                MaskAxH.Title.Visible = 'Off';
                MaskAxH.Toolbar.Visible = 'Off';                 
                
                % hide masking steps and small panels
                for i = 1:2
                    MStepsImgH(i).Visible = 'Off';
                    MStepsAxH(i).Title.Visible = 'Off';
                    MStepsAxH(i).Toolbar.Visible = 'Off';
                    
                    MStepsImgH(i+2).Visible = 'Off';
                    MStepsAxH(i+2).Title.Visible = 'Off';
                    MStepsAxH(i+2).Toolbar.Visible = 'Off';
                    
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';
                end

            case 'View/Adjust Mask'
                % link large AvgIntensityAxH and MaskAxH
                try
                    linkaxes([AverageIntensityAxH,MaskAxH],'off');
                catch
                    % do nothing
                end

                AverageIntensityImgH.Visible = 'Off';
                AverageIntensityAxH.Title.Visible = 'Off';
                AverageIntensityAxH.Toolbar.Visible = 'Off';              

                MaskImgH.Visible = 'Off';
                MaskAxH.Title.Visible = 'Off';
                MaskAxH.Toolbar.Visible = 'Off';

            case 'Order Factor'
                
                OrderFactorImgH.Visible = 'Off';
                OrderFactorAxH.Title.Visible = 'Off';
                OrderFactorAxH.Toolbar.Visible = 'Off';

                AverageIntensityImgH.Visible = 'Off';
                AverageIntensityAxH.Title.Visible = 'Off';
                AverageIntensityAxH.Toolbar.Visible = 'Off';
                
                ImgPanel1.Visible = 'Off';
                
                OFCbar.Visible = 'Off';
                
            case 'Azimuth'
                
                try
                    delete(data.Handles.AzimuthLines);
                catch
                    warning('Failed to delete Azimuth Lines');
                end

                QuiverAxH.Visible = 'Off';
                QuiverAxH.Title.Visible = 'Off';
                QuiverAxH.Toolbar.Visible = 'Off';

                AverageIntensityImgH.Visible = 'Off';
                AverageIntensityAxH.Title.Visible = 'Off';
                AverageIntensityAxH.Toolbar.Visible = 'Off';
                
            case 'Anisotropy'
                
                AnisotropyImgH.Visible = 'Off';
                AnisotropyAxH.Title.Visible = 'Off';
                AnisotropyAxH.Toolbar.Visible = 'Off';

                AverageIntensityImgH.Visible = 'Off';
                AverageIntensityAxH.Title.Visible = 'Off';
                AverageIntensityAxH.Toolbar.Visible = 'Off';
                
            case 'Filtered Order Factor'
                
                SBAverageIntensityImgH.Visible = 'Off';
                SBAverageIntensityAxH.Title.Visible = 'Off';
                SBAverageIntensityAxH.Toolbar.Visible = 'Off';

                FilteredOFImgH.Visible = 'Off';
                FilteredOFAxH.Title.Visible = 'Off';
                FilteredOFAxH.Toolbar.Visible = 'Off';
                
                OFCbar2.Visible = 'Off';
                
            case 'View Objects'

                try
                    delete(PODSData.Handles.hObjectOFContour);
                catch
                    warning('No 2D contour to delete');
                end                
                
                % object intensity image
                ObjectPolFFCAxH.Title.Visible = 'Off';
                ObjectPolFFCImgH.Visible = 'Off';
                
                % object mask image
                ObjectMaskAxH.Title.Visible = 'Off';
                ObjectMaskImgH.Visible = 'Off';
                
                % object 2D contour plot
                ObjectOFContourAxH.Title.Visible = 'Off';
                ObjectOFContourAxH.Visible = 'Off';

                ImgPanel2.Visible = 'Off';
                
                for i = 1:2
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';
                end

        end
        
        switch data.Settings.CurrentTab
            case 'Files'
                
                for i = 1:4
                    RawIntensityAxH(i).Parent = SmallPanels(2,i);
                    
                    RawIntensityImgH(i).Visible = 'On';
                    RawIntensityAxH(i).Title.Visible = 'On';
                    RawIntensityAxH(i).Toolbar.Visible = 'On';
                    
                    FFCImgH(i).Visible = 'On';
                    FFCAxH(i).Title.Visible = 'On';
                    FFCAxH(i).Toolbar.Visible = 'On';
                    
                    SmallPanels(1,i).Visible = 'On';
                    SmallPanels(2,i).Visible = 'On';
                end
                ImgPanel1.Visible = 'Off';
                ImgPanel2.Visible = 'Off';
                
            case 'FFC'
                
                for i = 1:4
                    RawIntensityAxH(i).Parent = SmallPanels(1,i);
                    
                    RawIntensityImgH(i).Visible = 'On';
                    RawIntensityAxH(i).Title.Visible = 'On';
                    RawIntensityAxH(i).Toolbar.Visible = 'On';

                    PolFFCImgH(i).Visible = 'On';
                    PolFFCAxH(i).Title.Visible = 'On';
                    PolFFCAxH(i).Toolbar.Visible = 'On';

                    SmallPanels(1,i).Visible = 'On';
                    SmallPanels(2,i).Visible = 'On';
                end
                ImgPanel1.Visible = 'Off';
                ImgPanel2.Visible = 'Off';
                
            case 'Generate Mask'
                
                MaskImgH.Visible = 'On';
                MaskAxH.Title.Visible = 'On';
                MaskAxH.Toolbar.Visible = 'On';
                
                ImgPanel1.Visible = 'Off';                
                ImgPanel2.Visible = 'On';                
                
                for i = 1:2
                    MStepsImgH(i).Visible = 'On';
                    MStepsAxH(i).Title.Visible = 'On';
                    MStepsAxH(i).Toolbar.Visible = 'On';
                    
                    MStepsImgH(i+2).Visible = 'On';
                    MStepsAxH(i+2).Title.Visible = 'On';
                    MStepsAxH(i+2).Toolbar.Visible = 'On';
                    
                    SmallPanels(1,i).Visible = 'On';
                    SmallPanels(2,i).Visible = 'On';
                    
                    SmallPanels(1,i+2).Visible = 'Off';
                    SmallPanels(2,i+2).Visible = 'Off';                    
                end
                
                
                linkaxes([MStepsAxH,MaskAxH],'xy');
                ImgOperationsTabGroup.SelectedTab = ImgOperationsTab(1);
                
            case 'View/Adjust Mask'
                ImgPanel1.Visible = 'On';
                ImgPanel2.Visible = 'On';                

                AverageIntensityImgH.Visible = 'On';
                AverageIntensityAxH.Title.Visible = 'On';
                AverageIntensityAxH.Toolbar.Visible = 'On';
                
                MaskImgH.Visible = 'On';
                MaskAxH.Title.Visible = 'On';
                MaskAxH.Toolbar.Visible = 'On';

                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end
                linkaxes([AverageIntensityAxH,MaskAxH],'xy');
                ImgOperationsTabGroup.SelectedTab = ImgOperationsTab(2);

            case 'Order Factor'
                
                OrderFactorImgH.Visible = 'On';
                OrderFactorAxH.Title.Visible = 'On';
                OrderFactorAxH.Toolbar.Visible = 'On';
                OrderFactorAxH.XLim = [1 1024];
                OrderFactorAxH.YLim = OrderFactorAxH.XLim;
                
                AverageIntensityImgH.Visible = 'On';
                AverageIntensityAxH.Title.Visible = 'On';
                AverageIntensityAxH.Toolbar.Visible = 'On';
                
                ImgPanel2.Visible = 'On';
                ImgPanel1.Visible = 'On';
                
                OFCbar.Visible = 'On';
                
                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end                
                
            case 'Azimuth'

                QuiverAxH.Visible = 'On';
                QuiverAxH.Title.Visible = 'On';
                QuiverAxH.Toolbar.Visible = 'On';

                AverageIntensityImgH.Visible = 'On';
                AverageIntensityAxH.Title.Visible = 'On';
                AverageIntensityAxH.Toolbar.Visible = 'On';
                
                ImgPanel1.Visible = 'On';
                ImgPanel2.Visible = 'On';

                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end                 
                
            case 'Anisotropy'
                
                AnisotropyImgH.Visible = 'On';
                AnisotropyAxH.Title.Visible = 'On';
                AnisotropyAxH.Toolbar.Visible = 'On';
                
                AverageIntensityImgH.Visible = 'On';
                AverageIntensityAxH.Title.Visible = 'On';
                AverageIntensityAxH.Toolbar.Visible = 'On';
                
                ImgPanel1.Visible = 'On';                
                ImgPanel2.Visible = 'On';
                
                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end 

            case 'Filtered Order Factor'
                
                SBAverageIntensityImgH.Visible = 'On';
                SBAverageIntensityAxH.Title.Visible = 'On';
                SBAverageIntensityAxH.Toolbar.Visible = 'On';
                
                FilteredOFImgH.Visible = 'On';
                FilteredOFAxH.Title.Visible = 'On';
                FilteredOFAxH.Toolbar.Visible = 'On';
                
                OFCbar2.Visible = 'On';
                
                ImgPanel1.Visible = 'On';
                ImgPanel2.Visible = 'On';
            
                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end

            case 'View Objects'
                
                % 3D Object Plot
                Object3DAxH.Visible = 'On';
                Object3DAxH.Title.Visible = 'On';

                % object intensity image
                ObjectPolFFCAxH.Title.Visible = 'On';
                ObjectPolFFCImgH.Visible = 'On';

                % object binary image
                ObjectMaskAxH.Title.Visible = 'On';
                ObjectMaskImgH.Visible = 'On';

                % object 2D contour plot
                ObjectOFContourAxH.Title.Visible = 'On';
                ObjectOFContourAxH.Visible = 'On';                

                ImgPanel2.Visible = 'On';

                for i = 1:2
                    SmallPanels(1,i).Visible = 'On';
                    SmallPanels(2,i).Visible = 'On';
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
                hFileInputType_nd2.Checked = 'On';
                hFileInputType_tif.Checked = 'Off';
            case '.tif'
                hFileInputType_nd2.Checked = 'Off';
                hFileInputType_tif.Checked = 'On';                
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
        GroupSelector.Parent = source.SelectedTab;
        GroupSelectorTitle.Parent = source.SelectedTab;
        ImageSelector.Parent = source.SelectedTab;
        ImageSelectorTitle.Parent = source.SelectedTab;
        ObjectSelector.Parent = source.SelectedTab;
        ObjectSelectorTitle.Parent = source.SelectedTab;
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
            hSELines.Children(i).Checked = 'Off';
        end
        source.Checked = 'On';        

    end

    function [] = ChangeSESize(source,event)

        PODSData.Settings.SESize = str2num(source.Tag);
        
        for i = 1:length(hSESize.Children)
            hSESize.Children(i).Checked = 'Off';
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
                       ['Unmasked Order Factor'];...
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
            % object data for image
            ImageSummary.ObjectProperties = cImage.ObjectProperties;
            % image info
            ImageSummary.ImageName = cImage.pol_shortname;

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
                colormap(gca,greenmap);
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