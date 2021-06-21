function [] = PODS_v2()
    
%% Need to go through and add all handle arrays to PODSData.Handles
     GraphicsRootObject = groot;

     im = zeros(1024,1024);
     
     for i = 1:1024
         im(i,1:1024) = linspace(0,1,1024);
     end

% get monitor positions to determine figure size
    MonitorPosition = get(0, 'MonitorPositions');
    
    % get size of main monitor
    MP1 = MonitorPosition(1,1:4);
    
    Zoom = struct('XRange',0,...
                  'YRange',0,...
                  'ZRange',0,...
                  'XDist',0,...
                  'YDist',0,...
                  'ZDist',0,...
                  'OldXLim',[0 1],...
                  'OldYLim',[0 1],...
                  'OldZLim',[0 1],...
                  'pct',0.5,...
                  'ZoomLevels',[1/10 1/5 1/3 1/2 1/1.5 1/1.25 1],...
                  'ZoomLevelIdx',4);

    % struct to hold gui settings
    UserSettings = struct('InputFileType','.nd2',...
                          'MaskType','MakeNew',...
                          'CurrentTab','Files',...
                          'PreviousTab','Files',...
                          'ScreenSize',MP1,...
                          'Zoom',Zoom);
                      
    Object = struct('Area',0,...
                    'BoundingBox',[],...
                    'Centroid',[],...
                    'Circularity',0,...
                    'ConvexArea',0,...
                    'ConvexHull',[],...
                    'ConvexImage',[],...
                    'Eccentricity',0,...
                    'Extrema',[],...
                    'FilledArea',0,...
                    'Image',[],...
                    'MajorAxisLength',0,...
                    'MinorAxisLength',0,...
                    'Orientation',0,...
                    'Perimeter',0,...
                    'PixelIdxList',[],...
                    'PixelList',[],...
                    'MaxFFCAvgIntensity',0,...
                    'MeanFFCAvgIntensity',0,...
                    'MinFFCAvgIntensity',0,...
                    'BGPixelIdxList',[],...
                    'MeanBGIntensity',0,...
                    'LocalSBRatio',0,...
                    'RawPixelValues',[],...
                    'OFPixelValues',[],...
                    'AzimuthPixelValues',[],...
                    'AnisotropyPixelValues',[],...
                    'OFAvg',0,...
                    'OFMin',0,...
                    'OFMax',0,...
                    'Name','',...
                    'OriginalIdx',0);

    % data structure for individual replicates
    Replicate = struct('OFAvg',0,...
                       'OFMax',0,...
                       'OFMin',0,...        
                       'FilteredOFAvg',0,...
                       'pol_shortname','',...
                       'nObjects',0,...
                       'level',0,...
                       'Width',0,...
                       'Height',0,...
                       'ThresholdAdjusted',logical(0),...
                       'MaskDone',logical(0),...
                       'OFDone',logical(0),...
                       'SE','disk',...
                       'SESize',num2str(5),...
                       'SELines',num2str(4),...
                       'FilterType','Median',...
                       'Object',Object,...
                       'ObjectNames',{['No Objects Found']},...
                       'CurrentObjectIdx',1);
                   
                  

    % data structure holding all groups within one experiment
    Group = struct('Replicate',Replicate,...
                   'CurrentImageIndex',1,...
                   'BatchImageIndex',[],...
                   'nReplicates',0,...
                   'FFCData',struct(),...
                   'GroupName','Untitled Group 1',...
                   'ImageNames',{'No Image Found'},...
                   'OFAvg',0,...
                   'TotalObjects',0);
    
    % data structure to hold all GUI settings and data
    PODSData = struct('Settings',UserSettings,...
                      'Handles',struct(),...
                      'Group',Group,...
                      'nGroups',1,...
                      'ProjectName','Untitled Project',...
                      'CurrentGroupIndex',1,...
                      'GroupNames',{'Untitled Group 1'});

    fH = uifigure('Name','PODS GUI',...
                 'numbertitle','off',...
                 'units','pixels',...
                 'Position',MP1,...
                 'Visible','On',...
                 'Color','yellow',...
                 'HandleVisibility','on');
    
    % draw the figure body
    drawnow
    %% File Menu Button - Create a new project, load files, etc...
    hFileMenu = uimenu(fH,'Text','File');
    % Options for File Menu Button
    hNewProject = uimenu(hFileMenu,'Text','New Project','Callback',@NewProject);
    hLoadFFCFiles = uimenu(hFileMenu,'Text','Load FFC Files','Callback',@pb_LoadFFCFiles);
    hLoadFPMFiles = uimenu(hFileMenu,'Text','Load FPM Files','Callback',@pb_LoadFPMFiles);
    
    %% Options Menu Button - Change gui option and settings
    hOptionsMenu = uimenu(fH,'Text','Options');
    % Input File Type Option
    hFileInputType = uimenu(hOptionsMenu,'Text','File Input Type');
    % Options for input file type
    hFileInputType_nd2 = uimenu(hFileInputType,'Text','.nd2','Checked','on','Callback',@ChangeInputFileType);
    hFileInputType_tif = uimenu(hFileInputType,'Text','.tif','Checked','off','Callback',@ChangeInputFileType);

    %% View Menu Button - changes view of GUI to different 'tabs'
    hTabMenu = uimenu(fH,'Text','Change Tab');
    % Tabs for 'View'
    hTabFiles = uimenu(hTabMenu,'Text','Files','MenuSelectedFcn',@TabSelection);
    hTabFFC = uimenu(hTabMenu,'Text','FFC','MenuSelectedFcn',@TabSelection);
    hTabGenerateMask = uimenu(hTabMenu,'Text','Generate Mask','MenuSelectedFcn',@TabSelection);
    hTabViewAdjustMask = uimenu(hTabMenu,'Text','View/Adjust Mask','MenuSelectedFcn',@TabSelection);
    hTabOrderFactor = uimenu(hTabMenu,'Text','Order Factor','MenuSelectedFcn',@TabSelection);
    hTabAzimuth = uimenu(hTabMenu,'Text','Azimuth','MenuSelectedFcn',@TabSelection);
    hTabAnisotropy = uimenu(hTabMenu,'Text','Anisotropy','MenuSelectedFcn',@TabSelection);
    hTabSBFiltering = uimenu(hTabMenu,'Text','SB-Filtering','MenuSelectedFcn',@TabSelection);
    
    %% Process Menu Button - allows user to perform FFC, generate mask, and generate output images
    hProcessMenu = uimenu(fH,'Text','Process');    
    % Process Operations
    hProcessFFC = uimenu(hProcessMenu,'Text','Perform Flat-Field Correction','MenuSelectedFcn',@pb_FFC);
    hProcessMask = uimenu(hProcessMenu,'Text','Generate Mask','MenuSelectedFcn',@CreateMask3);
    hProcessOF = uimenu(hProcessMenu,'Text','Find Order Factor','MenuSelectedFcn',@FindOrderFactor3);

    hPlotMenu = uimenu(fH,'Text','Plot');
    % Plot choices
    hPlotViolins = uimenu(hPlotMenu,'Text','Violin','MenuSelectedFcn',@PlotViolins);

    drawnow
    pause(0.1)
    
    pos = fH.Position;
    
    % width and height of the large plots
    width = round(pos(3)*0.400);
    height = width;
    height_norm = height/pos(4);
    width_norm = width/pos(3);
    
    % and the small plots
    swidth = round(width/2);
    sheight = swidth;
    swidth_norm = swidth/pos(3);
    sheight_norm = sheight/pos(4);
    
%% APP INFO PANEL
    AppInfoPanel = uipanel('Parent',fH,...
                           'Position',[1 round(0.100*pos(4)) round(0.200*pos(3))+2 round(0.900*pos(4))+1],...
                           'BackgroundColor','black',...
                           'BorderType','line');
%% LOG PANEL                       
    LogPanel = uipanel('Parent',fH,...
                       'Position',[1 1 pos(3) round(0.100*pos(4))],...
                       'BackgroundColor','black',...
                       'BorderType','line');  
%% IMAGE INFO PANEL                   
    ImgInfoPanel = uipanel('Parent',fH,...
                           'Position',[round(0.200*pos(3))+2 round(0.100*pos(4)+height)-1 round(width) round(0.900*pos(4)-height)+2],...
                           'BackgroundColor','black',...
                           'BorderType','line');
%% IMAGE OPERATIONS PANEL                   
    ImgOperationsPanel = uipanel('Parent',fH,...
                           'Position',[round(0.200*pos(3))+width+1 round(0.100*pos(4)+height)-1 round(width) round(0.900*pos(4)-height)+2],...
                           'BackgroundColor','black',...
                           'BorderType','line');                                
%% Mask threshold adjuster                       
    ThreshSlider = uislider('Parent',ImgOperationsPanel,...
                             'Position',[20 35 round(width)-40 3],...
                             'ValueChangingFcn',@SliderMoving,...
                             'ValueChangedFcn',@SliderMoved,...
                             'Limits',[0 1],...
                             'Visible','Off',...
                             'tag','ThreshSlider',...
                             'FontColor','yellow',...
                             'MajorTicks',[0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1]);
                         
    ThreshAxH = uiaxes('Parent',ImgOperationsPanel,...
                       'InnerPosition',[20 45 round(width)-40 80],...
                       'XTick',[],...
                       'YTick',[],...
                       'XLimMode','manual',...
                       'XLim',[0 1],...
                       'Visible','off');
             
    corn_gray = im2double(imread('corn.tif',3));
    corn_gray = corn_gray./max(max(corn_gray));
    corn_gray = corn_gray(1:100,1:100);

    [IntensityBinCenters,IntensityHistPlot] = BuildHistogram(corn_gray);             
                   
    ThreshBar = bar(ThreshAxH,IntensityBinCenters,IntensityHistPlot,...
                    'FaceColor','Yellow',...
                    'EdgeColor','None',...
                    'Visible','Off');
%% MASKING PARAMETERS ADJUSTMENT             
    temp = ImgOperationsPanel.InnerPosition;
    FilterSelectorTitle = uilabel('Parent',ImgOperationsPanel,...
                                  'Position', [20 round(temp(4)-30) 140 20],...
                                  'FontColor','Yellow',...
                                  'Text','Filter Type',...
                                  'Visible','Off');    
    FilterSelectorDropdown = uidropdown('Parent',ImgOperationsPanel,...
                                        'Items',{'Median','Tophat'},...
                                        'Value','Median',...
                                        'Position',[160 round(temp(4)-30) 100 20],...
                                        'ValueChangedFcn',@SelectFilterType,...
                                        'Visible','Off');                              
                                    
    SESizeBoxTitle = uilabel('Parent',ImgOperationsPanel,...
                             'Position', [20 round(temp(4)-60) 140 20],...
                             'FontColor','Yellow',...
                             'Text','Structuring Element Size',...
                             'WordWrap','on',...
                             'Visible','Off');                                    
    SESizeBox = uieditfield('Parent',ImgOperationsPanel,...
                            'Position',[160 round(temp(4)-60) 100 20],...
                            'Value',num2str(5),...
                            'ValueChangedFcn',@SESizeChanged,...
                            'Visible','Off');                  

    SELinesBoxTitle = uilabel('Parent',ImgOperationsPanel,...
                              'Position', [20 round(temp(4)-90) 140 20],...
                              'FontColor','Yellow',...
                              'Text','Number of Lines',...
                              'Visible','Off');    
    SELinesBox = uieditfield('Parent',ImgOperationsPanel,...
                             'Position',[160 round(temp(4)-90) 100 20],...
                             'Value',num2str(4),...
                             'ValueChangedFcn',@SELinesChanged,...
                             'Visible','Off');
                    
                             
%% LARGE IMAGE PANELS
    ImgPanel1 = uipanel('Parent',fH,...
                        'Position',[round(0.200*pos(3))+2 round(0.100*pos(4)) width height],...
                        'BackgroundColor','black',...
                        'Visible','off',...
                        'BorderType','line');
                    
    % Bottom right panel of 2-panel tabs               
    ImgPanel2 = uipanel('Parent',fH,...
                        'Position',[round(0.200*pos(3)+width)+1 round(0.100*pos(4)) width height],...
                        'BackgroundColor','black',...
                        'Visible','off',...
                        'BorderType','line');
                    
    % tags for small panels                
    panel_tags = ['Panel_1-1' 'Panel_1-2' 'Panel_1-3' 'Panel_1-4';...
                  'Panel_2-1' 'Panel_2-2' 'Panel_2-3' 'Panel_2-4'];               
                                   
    % Loop to generate small image panels, held in a vector of panel
    % handles
    for i = 1:2
        for ii = 1:4
            SmallPanels(i,ii) = uipanel('Parent',fH,...
                'Position',[round(0.200*pos(3)+swidth*(ii-1)) round(0.100*pos(4)+sheight-sheight*(i-1)) swidth sheight],...
                'BackgroundColor','black',...
                'Tag',panel_tags(i,ii),...
                'BorderType','line');
        end
    end           
    
    % Slight adjustments to panel positions for improved look
    SmallPanels(1,1).Position(1) = SmallPanels(1,1).Position(1)+2;
    SmallPanels(2,1).Position(1) = SmallPanels(2,1).Position(1)+2;
    
    SmallPanels(1,2).Position(1) = SmallPanels(1,2).Position(1)+1;
    SmallPanels(2,2).Position(1) = SmallPanels(2,2).Position(1)+1;    
    
%    SmallPanels(1,3).Position(1) = SmallPanels(1,3).Position(1)+0;
%    SmallPanels(2,3).Position(1) = SmallPanels(2,3).Position(1)+0;     
    
    SmallPanels(1,4).Position(1) = SmallPanels(1,4).Position(1)-1;
    SmallPanels(2,4).Position(1) = SmallPanels(2,4).Position(1)-1;
    
    
    SmallPanels(1,1).Position(2) = SmallPanels(1,1).Position(2)-1;    
    SmallPanels(1,2).Position(2) = SmallPanels(1,2).Position(2)-1;    
    SmallPanels(1,3).Position(2) = SmallPanels(1,3).Position(2)-1;    
    SmallPanels(1,4).Position(2) = SmallPanels(1,4).Position(2)-1;    
   
    % draw panels               
    drawnow
    pause(0.1)

%% Log Window For User Updates
    LogWindow = uitextarea('parent',LogPanel,...
                           'Position', [0 0 LogPanel.Position(3) LogPanel.Position(4)],...
                           'HorizontalAlignment','left',...
                           'enable','on',...
                           'tag','LogWindow',...
                           'BackgroundColor','black',...
                           'FontColor','yellow',...
                           'FontName','Courier',...
                           'Value',{'Log Window';'Drawing Containers and Tables...'}); 

%% Group Selection Box
    pos = ImgInfoPanel.InnerPosition;
    
    small_width = (0.5*pos(3)-25)*0.5;
    large_width = small_width*2+10;
    
    
    
    GroupSelector = uilistbox('parent',ImgInfoPanel,...
                              'Position', [10 10 small_width pos(4)-30],...
                              'enable','on',...
                              'tag','GroupListBox',...
                              'Items',{'UntitledGroup1'},...
                              'ValueChangedFcn',@ChangeActiveGroup,...
                              'FontColor','Black');                
    lst_pos = GroupSelector.Position;
    GroupSelectorTitle = uilabel('Parent',ImgInfoPanel,...
                                 'Position', [10 lst_pos(4)+10 small_width 20],...
                                 'FontColor','Yellow',...
                                 'Text','<b>Select Group</b>',...
                                 'HorizontalAlignment','center',...
                                 'Interpreter','html');
                             
%% Image Selection Box                   
    ImageSelector = uilistbox('parent',ImgInfoPanel,...
                              'Position', [lst_pos(3)+20 10 large_width lst_pos(4)],...
                              'enable','on',...
                              'tag','ImageListBox',...
                              'Items',{'No Images Loaded'},...
                              'ValueChangedFcn',@ChangeActiveImage,...
                              'MultiSelect','on',...
                              'FontColor','Black');                    
    lst_pos2 = ImageSelector.Position;                      
    ImageSelectorTitle = uilabel('Parent',ImgInfoPanel,...
                                 'Position', [lst_pos2(1) lst_pos2(4)+10 large_width 20],...
                                 'FontColor','Yellow',...
                                 'Text','<b>Select Image</b>',...                                 
                                 'HorizontalAlignment','center',...
                                 'Interpreter','html');
                             
    %% Object Selection Box                          
    ObjectSelector = uilistbox('parent',ImgInfoPanel,...
                               'Position', [lst_pos(3)+lst_pos2(3)+30 10 small_width lst_pos(4)],...
                               'enable','on',...
                               'tag','ObjectListBox',...
                               'Items',{'No Objects Identified'},...
                               'ValueChangedFcn',@ChangeActiveObject,...
                               'MultiSelect','on',...
                               'FontColor','Black');                   
    lst_pos3 = ObjectSelector.Position;                      
    ObjectSelectorTitle = uilabel('Parent',ImgInfoPanel,...
                                  'Position', [lst_pos3(1) lst_pos3(4)+10 small_width 20],...
                                  'FontColor','Yellow',...
                                  'Text','<b>Select Object</b>',...
                                  'HorizontalAlignment','Center',...
                                  'Interpreter','html');                             
                                                     
           
    pos = AppInfoPanel.Position;

    ProjectDataTable = uilabel('Parent',AppInfoPanel,...
                               'Position',[20 0.5*pos(4) pos(3)-40 0.5*pos(4)-20],...
                               'tag','ProjectDataTable',...
                               'Text','Loading...',...
                               'FontColor','Yellow',...
                               'FontName','Courier',...
                               'BackgroundColor','Black',...
                               'VerticalAlignment','Top',...
                               'Interpreter','html');                 
                             
    ProjectDataTable.Text = {['<b>Project Overview</b>'];...
                             ['Project Name:          ', PODSData.ProjectName];...
                             ['Number of Groups:      ', num2str(PODSData.nGroups)];...
                             ['InputFileType:         ', PODSData.Settings.InputFileType];...
                             ['Current Tab:           ', PODSData.Settings.CurrentTab]};     
    drawnow
    
    old = LogWindow.Value;
    new = old;
    new{length(old)+1} = 'Drawing Axes';
    LogWindow.Value = new;
    
%% AXES AND IMAGE PLACEHOLDERS    
	
    % empty placeholder image
	emptyimage = zeros(1024,1024);
    % black to green colormap for fluorescence images
    graymap = gray;
    greenmap = zeros(256,3);
    greenmap(:,2) = graymap(:,2);    

    SmallPanelWidth = SmallPanels(1,1).InnerPosition(3);
    SmallPanelHeight = SmallPanels(1,1).InnerPosition(4);
    
    LargePanelWidth = ImgPanel1.InnerPosition(3);
    LargePanelHeight = ImgPanel1.InnerPosition(4);

    %% FLAT-FIELD IMAGES
    for i = 1:4
        FFCAxH(i) = uiaxes('Parent',SmallPanels(1,i),...
                           'Units','Pixels',...
                           'InnerPosition',[1 1 SmallPanelWidth SmallPanelHeight],...
                           'Tag',['FFC' num2str((i-1)*45)],...
                           'XTick',[],...
                           'YTick',[]);      
        % save original values                          
        pbarOriginal = FFCAxH(i).PlotBoxAspectRatio;
        tagOriginal = FFCAxH(i).Tag;        
        % place placeholder image on axis
        FFCImgH(i) = imshow(im,'Parent',FFCAxH(i));
        % set a tag so our callback functions can find the image
        set(FFCImgH(i),'Tag',['FFCImage' num2str((i-1)*45)]);

        % restore original values after imshow() call
        FFCAxH(i) = restore_axis_defaults(FFCAxH(i),pbarOriginal,tagOriginal);

        FFCAxH(i) = SetAxisTitle(FFCAxH(i),['Flat-Field Image (' num2str((i-1)*45) '^{\circ} Excitation)']);
        
        FFCAxH(i).Colormap = greenmap;
    end
    %linkaxes(FFCAxH);
    %% RAW INTENSITY IMAGES
    for i = 1:4
        RawIntensityAxH(i) = uiaxes('Parent',SmallPanels(2,i),...
                                    'Units','Pixels',...
                                    'InnerPosition',[1 1 SmallPanelWidth SmallPanelHeight],...
                                    'Tag',['Raw' num2str((i-1)*45)],...
                                    'XTick',[],...
                                    'YTick',[]);
        % save original values                          
        pbarOriginal = RawIntensityAxH(i).PlotBoxAspectRatio;
        tagOriginal = RawIntensityAxH(i).Tag;        
        % place placeholder image on axis
        RawIntensityImgH(i) = imshow(emptyimage,'Parent',RawIntensityAxH(i));
        % set a tag so our callback functions can find the image
        set(RawIntensityImgH(i),'Tag',['RawImage' num2str((i-1)*45)]);
        

        % restore original values after imshow() call
        RawIntensityAxH(i) = restore_axis_defaults(RawIntensityAxH(i),pbarOriginal,tagOriginal);

        RawIntensityAxH(i) = SetAxisTitle(RawIntensityAxH(i),['Raw Intensity (' num2str((i-1)*45) '^{\circ} Excitation)']);
        
        RawIntensityAxH(i).Colormap = greenmap;
        
    end
    %% FLAT-FIELD CORRECTED INTENSITY
    for i = 1:4
        PolFFCAxH(i) = uiaxes('Parent',SmallPanels(2,i),...
                              'Units','Pixels',...
                              'InnerPosition',[1 1 SmallPanelWidth SmallPanelHeight],...
                              'Tag',['PolFFC' num2str((i-1)*45)],...
                              'XTick',[],...
                              'YTick',[]);
        % save original values                          
        pbarOriginal = PolFFCAxH(i).PlotBoxAspectRatio;
        tagOriginal = PolFFCAxH(i).Tag;
        % place placeholder image on axis
        PolFFCImgH(i) = imshow(emptyimage,'Parent',PolFFCAxH(i));
        % set a tag so our callback functions can find the image
        set(PolFFCImgH(i),'Tag',['PolFFCImage' num2str((i-1)*45)]);

        % restore original values after imshow() call
        PolFFCAxH(i) = restore_axis_defaults(PolFFCAxH(i),pbarOriginal,tagOriginal);
        % set axis title
        PolFFCAxH(i) = SetAxisTitle(PolFFCAxH(i),['Flat-Field Corrected Intensity (' num2str((i-1)*45) '^{\circ} Excitation)']);
        
        PolFFCAxH(i).Colormap = greenmap;
        
        PolFFCAxH(i).Toolbar.Visible = 'Off';
        
        PolFFCImgH(i).Visible = 'Off';
        PolFFCAxH(i).Title.Visible = 'Off';
    end
    %% MASKING STEPS
    for i = 1:4
        switch i
            case 1
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(1,1),...
                                      'Units','Pixels',...
                                      'InnerPosition',[1 1 SmallPanelWidth SmallPanelHeight],...
                                      'Tag','MStepsIntensity',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Average Intensity';
                image_tag = 'MStepsIntensityImage';
            case 2
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(1,2),...
                                      'Units','Pixels',...
                                      'InnerPosition',[1 1 SmallPanelWidth SmallPanelHeight],...
                                      'Tag','MStepsBackground',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Background Intensity';
                image_tag = 'MStepsBackgroundImage';                                
            case 3
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(2,1),...
                                      'Units','Pixels',...
                                      'InnerPosition',[1 1 SmallPanelWidth SmallPanelHeight],...
                                      'Tag','MStepsBGSubtracted',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Background Subtracted Intensity';
                image_tag = 'MStepsBGSubtractedImage';                                
            case 4
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(2,2),...
                                      'Units','Pixels',...
                                      'InnerPosition',[1 1 SmallPanelWidth SmallPanelHeight],...
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
        MStepsImgH(i) = imshow(emptyimage,'Parent',MStepsAxH(i));
        % set a tag so our callback functions can find the image
        set(MStepsImgH(i),'Tag',image_tag);

        % restore original values after imshow() call
        MStepsAxH(i) = restore_axis_defaults(MStepsAxH(i),pbarOriginal,tagOriginal);
        % set axis title
        MStepsAxH(i) = SetAxisTitle(MStepsAxH(i),image_title);
        
        MStepsAxH(i).Colormap = greenmap;
        
        MStepsAxH(i).Toolbar.Visible = 'Off';
        
        MStepsImgH(i).Visible = 'Off';
        MStepsAxH(i).Title.Visible = 'Off';
    end
    %% AVERAGE INTENSITY
    for i = 1:1
        % create an axis, child of a panel, to fill the container
        AverageIntensityAxH = uiaxes('Parent',ImgPanel1,...
                                     'Units','Pixels',...
                                     'InnerPosition',[1 1 LargePanelWidth LargePanelHeight],...
                                     'Tag','AverageIntensity',...
                                     'XTick',[],...
                                     'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = AverageIntensityAxH.PlotBoxAspectRatio;
        tagOriginal = AverageIntensityAxH.Tag;
        % place placeholder image on axis
        AverageIntensityImgH = imshow(emptyimage,'Parent',AverageIntensityAxH);
        % set a tag so our callback functions can find the image
        set(AverageIntensityImgH,'Tag','AverageIntensityImage');

        % restore original values after imshow() call
        AverageIntensityAxH = restore_axis_defaults(AverageIntensityAxH,pbarOriginal,tagOriginal);
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
        OrderFactorAxH = uiaxes('Parent',ImgPanel2,...
                                'Units','Pixels',...
                                'InnerPosition',[1 1 LargePanelWidth LargePanelHeight],...
                                'Tag','OrderFactor',...
                                'XTick',[],...
                                'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = OrderFactorAxH.PlotBoxAspectRatio;
        tagOriginal = OrderFactorAxH.Tag;
        % place placeholder image on axis
        OrderFactorImgH = imshow(emptyimage,'Parent',OrderFactorAxH);
        % set a tag so our callback functions can find the image
        set(OrderFactorImgH,'Tag','OrderFactorImage');
        % restore original values after imshow() call
        OrderFactorAxH = restore_axis_defaults(OrderFactorAxH,pbarOriginal,tagOriginal);
        % set axis title
        OrderFactorAxH = SetAxisTitle(OrderFactorAxH,'Pixel-by-pixel Order Factor');
        % change active axis so we can make custom colorbar/colormap
        axes(OrderFactorAxH)
        % custom colormap/colorbar
        [mycolormap,mycolormap_noblack] = MakeRGB;
        OFCbar = colorbar('location','east','color','white','tag','OFCbar');
        
        colormap(gca,mycolormap);
        
        OCFbar.Visible = 'Off';
        OrderFactorAxH.Toolbar.Visible = 'Off';

        OrderFactorImgH.Visible = 'Off';
        OrderFactorAxH.Title.Visible = 'Off';
        %% Azimuth
        % create an axis, child of a panel, to fill the container
        AzimuthAxH = uiaxes('Parent',ImgPanel2,...
                            'Units','Pixels',...
                            'InnerPosition',[1 1 LargePanelWidth LargePanelHeight],...
                            'Tag','ColoredAzimuth',...
                            'XTick',[],...
                            'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = AzimuthAxH.PlotBoxAspectRatio;
        tagOriginal = AzimuthAxH.Tag;
        % place placeholder image on axis
        AzimuthImgH = imshow(emptyimage,'Parent',AzimuthAxH);
        % set a tag so our callback functions can find the image
        set(AzimuthImgH,'Tag','ColoredAzimuthImage');

        % restore original values after imshow() call
        AzimuthAxH = restore_axis_defaults(AzimuthAxH,pbarOriginal,tagOriginal);
        % set axis title
        AzimuthAxH = SetAxisTitle(AzimuthAxH,'Colored Azimuth Image');
        
        AzimuthAxH.Toolbar.Visible = 'Off';
        
        AzimuthImgH.Visible = 'Off';
        AzimuthAxH.Title.Visible = 'Off';    
        %% Anisotropy
        % create an axis, child of a panel, to fill the container
        AnisotropyAxH = uiaxes('Parent',ImgPanel2,...
                               'Units','Pixels',...
                               'InnerPosition',[1 1 LargePanelWidth LargePanelHeight],...
                               'Tag','Anisotropy',...
                               'XTick',[],...
                               'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = AnisotropyAxH.PlotBoxAspectRatio;
        tagOriginal = AnisotropyAxH.Tag;
        % place placeholder image on axis
        AnisotropyImgH = imshow(emptyimage,'Parent',AnisotropyAxH);
        % set a tag so our callback functions can find the image
        set(AnisotropyImgH,'Tag','AnisotropyImage');

        % restore original values after imshow() call
        AnisotropyAxH = restore_axis_defaults(AnisotropyAxH,pbarOriginal,tagOriginal);
        % set axis title
        AnisotropyAxH = SetAxisTitle(AnisotropyAxH,'Anisotropy Image');
        
        AnisotropyAxH.Visible = 'Off';
        
        AnisotropyAxH.Toolbar.Visible = 'Off';

        AnisotropyImgH.Visible = 'Off';
        AnisotropyAxH.Title.Visible = 'Off';
        %% S-B Filtering
        % create an axis, child of a panel, to fill the container
        SBAverageIntensityAxH = uiaxes('Parent',ImgPanel1,...
                                       'Units','Pixels',...
                                       'InnerPosition',[1 1 LargePanelWidth LargePanelHeight],...
                                       'Tag','SBAverageIntensity',...
                                       'XTick',[],...
                                       'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = SBAverageIntensityAxH.PlotBoxAspectRatio;
        tagOriginal = SBAverageIntensityAxH.Tag;
        % place placeholder image on axis
        SBAverageIntensityImgH = imshow(emptyimage,'Parent',SBAverageIntensityAxH);
        % set a tag so our callback functions can find the image
        set(SBAverageIntensityImgH,'Tag','SBAverageIntensityImage');

        % restore original values after imshow() call
        SBAverageIntensityAxH = restore_axis_defaults(SBAverageIntensityAxH,pbarOriginal,tagOriginal);
        % set axis title
        SBAverageIntensityAxH = SetAxisTitle(SBAverageIntensityAxH,'Average Intensity (S:B Overlay)');

        SBAverageIntensityAxH.Colormap = greenmap;
        
        SBAverageIntensityAxH.Toolbar.Visible = 'Off';
                
        SBAverageIntensityImgH.Visible = 'Off';
        SBAverageIntensityAxH.Title.Visible = 'Off';    
        %% MASK
        % create an axis, child of a panel, to fill the container
        MaskAxH = uiaxes('Parent',ImgPanel2,...
                         'Units','Pixels',...
                         'InnerPosition',[1 1 LargePanelWidth LargePanelHeight],...
                         'Tag','Mask',...
                         'XTick',[],...
                         'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = MaskAxH.PlotBoxAspectRatio;
        tagOriginal = MaskAxH.Tag;
        % place placeholder image on axis
        MaskImgH = imshow(emptyimage,'Parent',MaskAxH);
        % set a tag so our callback functions can find the image
        set(MaskImgH,'Tag','MaskImage');
                    
        % restore original values after imshow() call
        MaskAxH = restore_axis_defaults(MaskAxH,pbarOriginal,tagOriginal);
        % set axis title
        MaskAxH = SetAxisTitle(MaskAxH,'Binary Mask');
        
        MaskAxH.Toolbar.Visible = 'Off';

        MaskImgH.Visible = 'Off';
        MaskAxH.Title.Visible = 'Off';

         %% SB FILTERED MASK
        % create an axis, child of a panel, to fill the container
        SBMaskAxH = uiaxes('Parent',ImgPanel2,...
                           'Units','Pixels',...
                           'InnerPosition',[1 1 LargePanelWidth LargePanelHeight],...
                           'Tag','SBMask',...
                           'XTick',[],...
                           'YTick',[]);
        % save original values to be restored after calling imshow()
        pbarOriginal = SBMaskAxH.PlotBoxAspectRatio;
        tagOriginal = SBMaskAxH.Tag;
        % place placeholder image on axis
        SBMaskImgH = imshow(emptyimage,'Parent',SBMaskAxH);
        % set a tag so our callback functions can find the image
        set(SBMaskImgH,'Tag','SBMaskImage');

        % restore original values after imshow() call
        SBMaskAxH = restore_axis_defaults(SBMaskAxH,pbarOriginal,tagOriginal);
        % set axis title
        SBMaskAxH = SetAxisTitle(SBMaskAxH,'SB-Filtered Binary Mask');
        
        SBMaskAxH.Toolbar.Visible = 'Off';

        SBMaskImgH.Visible = 'Off';
        SBMaskAxH.Title.Visible = 'Off';
    end

    drawnow

    old = LogWindow.Value;
    new = old;
    new{length(old)+1} = 'Done Drawing Axes.';
    LogWindow.Value = new;

    % add guihandles to PODSData struct
    PODSData.Handles = guihandles;
    
    PODSData.Handles.GraphicsRootObject = GraphicsRootObject;
    
    % Main Figure
    PODSData.Handles.fH = fH;    
    
    % Handles for flat-field images/axes
    PODSData.Handles.FFCAxH = FFCAxH;
    PODSData.Handles.FFCImgH = FFCImgH;
    
    % ...to the small image panels
    PODSData.Handles.SmallPanels = SmallPanels;
    
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
    PODSData.Handles.SBMaskAxH = SBMaskAxH;
    PODSData.Handles.SBMaskImgH = SBMaskImgH;    
    
    % ...large image panels
    PODSData.Handles.ImgPanel1 = ImgPanel1;
    PODSData.Handles.ImgPanel2 = ImgPanel2;
    
    % ...colorbars
    PODSData.Handles.OFCbar = OFCbar;
    
    % ...Mask threshold control
    PODSData.Handles.ThreshAxH = ThreshAxH;
    PODSData.Handles.ThreshBar = ThreshBar;

    % ...Mask paramaters control
    PODSData.Handles.FilterSelectorDropDown = FilterSelectorDropdown;
    PODSData.Handles.FilterSelectorTitle = FilterSelectorTitle;
    PODSData.Handles.SESizeBox = SESizeBox;
    PODSData.Handles.SESizeBoxTitle = SESizeBoxTitle;
    PODSData.Handles.SELinesBox = SELinesBox;
    PODSData.Handles.SELinesBoxTitle = SELinesBoxTitle;

    
    PODSData.Handles.ObjectSelector = ObjectSelector;
    
    
    % update guidata with handles structure                     
    guidata(fH,PODSData)
    
    linkaxes(FFCAxH,'xy');
    linkaxes(RawIntensityAxH,'xy');

    %test_fcn(fH);

    %% NESTED FUNCTIONS
    function [] = TabSelection(source,event)

        NewTab = source.Text;
        data = guidata(source)
        OldTab = data.Settings.CurrentTab;
        UpdateLog3(source,[NewTab, ' Tab Selected'],'append');
        data.Settings.CurrentTab = NewTab;
        data.Settings.PreviousTab = OldTab;

        switch OldTab
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
                
                if ~strcmp(NewTab,'View/Adjust Mask')
                    ThreshSlider.Visible = 'Off';
                    %ThreshAxH.Visible = 'Off';
                    FilterSelectorDropdown.Visible = 'Off';
                    FilterSelectorTitle.Visible = 'Off';
                    SESizeBox.Visible = 'Off';
                    SESizeBoxTitle.Visible = 'Off';
                    SELinesBox.Visible = 'Off';
                    SELinesBoxTitle.Visible = 'Off';
                    ThreshBar.Visible = 'Off';         
                end                 
                
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

                if ~strcmp(NewTab,'Generate Mask')
                    ThreshSlider.Visible = 'Off';
                    FilterSelectorDropdown.Visible = 'Off';
                    FilterSelectorTitle.Visible = 'Off';
                    SESizeBox.Visible = 'Off';
                    SESizeBoxTitle.Visible = 'Off';
                    SELinesBox.Visible = 'Off';
                    SELinesBoxTitle.Visible = 'Off';
                    ThreshBar.Visible = 'Off';         
                end                

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
                
                OFCbar.Visible = 'Off';
                
            case 'Azimuth' 
                AzimuthImgH.Visible = 'Off';
                AzimuthAxH.Title.Visible = 'Off';
                AzimuthAxH.Toolbar.Visible = 'Off';

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
                
            case 'SB-Filtering'
                SBAverageIntensityImgH.Visible = 'Off';
                SBAverageIntensityAxH.Title.Visible = 'Off';
                SBAverageIntensityAxH.Toolbar.Visible = 'Off';

                SBMaskImgH.Visible = 'Off';
                SBMaskAxH.Title.Visible = 'Off';
                SBMaskAxH.Toolbar.Visible = 'Off';
        end
        
        switch NewTab
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
                
                if ~strcmp(OldTab,'View/Adjust Mask')
                    ThreshSlider.Visible = 'On';
                    %ThreshAxH.Visible = 'On';
                    ThreshBar.Visible = 'On';
                    FilterSelectorDropdown.Visible = 'On';
                    FilterSelectorTitle.Visible = 'On';
                    SESizeBox.Visible = 'On';
                    SESizeBoxTitle.Visible = 'On';
                    SELinesBox.Visible = 'On';
                    SELinesBoxTitle.Visible = 'On';
                    
                end                
                
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
                
            case 'View/Adjust Mask'         
                AverageIntensityImgH.Visible = 'On';
                AverageIntensityAxH.Title.Visible = 'On';
                AverageIntensityAxH.Toolbar.Visible = 'On';
                
                MaskImgH.Visible = 'On';
                MaskAxH.Title.Visible = 'On';
                MaskAxH.Toolbar.Visible = 'On';
                
                ImgPanel1.Visible = 'On';
                ImgPanel2.Visible = 'On';
                
                if ~strcmp(OldTab,'Generate Mask')
                    ThreshSlider.Visible = 'On';
                    %ThreshAxH.Visible = 'On';
                    ThreshBar.Visible = 'On';
                    FilterSelectorDropdown.Visible = 'On';
                    FilterSelectorTitle.Visible = 'On';
                    SESizeBox.Visible = 'On';
                    SESizeBoxTitle.Visible = 'On';
                    SELinesBox.Visible = 'On';
                    SELinesBoxTitle.Visible = 'On';
                    
                end
                
                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end
                linkaxes([AverageIntensityAxH,MaskAxH],'xy');
                
            case 'Order Factor'
                OrderFactorImgH.Visible = 'On';
                OrderFactorAxH.Title.Visible = 'On';
                OrderFactorAxH.Toolbar.Visible = 'On';
                
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
                AzimuthImgH.Visible = 'On';
                AzimuthAxH.Title.Visible = 'On';
                AzimuthAxH.Toolbar.Visible = 'On';
                
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

            case 'SB-Filtering'
                SBAverageIntensityImgH.Visible = 'On';
                SBAverageIntensityAxH.Title.Visible = 'On';
                SBAverageIntensityAxH.Toolbar.Visible = 'On';
                
                SBMaskImgH.Visible = 'On';
                SBMaskAxH.Title.Visible = 'On';
                SBMaskAxH.Toolbar.Visible = 'On';
                
                ImgPanel1.Visible = 'On';
                ImgPanel2.Visible = 'On';
            
                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end
        end
        guidata(source,data);
    end
    
    function [axH] = restore_axis_defaults(axH,OriginalPlotBoxAspectRatio,OriginalTag)
        % restore axis defaults that were changed by imshow()
        axH.YDir = 'normal';
        axH.PlotBoxAspectRatioMode = 'manual';
        %axH.DataAspectRatioMode = 'auto';
        axH.PlotBoxAspectRatio = OriginalPlotBoxAspectRatio;
        axH.XTick = [];
        axH.YTick = [];
        axH.Tag = OriginalTag;
        
        % range of axes (for ZoomToCursor)
        axH.addprop('XRange');
        axH.XRange = diff(axH.XLim);
        axH.addprop('YRange');
        axH.YRange = diff(axH.YLim);
        axH.addprop('ZRange');        
        axH.ZRange = diff(axH.ZLim);
        
        % size of zoom box (for ZoomToCursor)
        axH.addprop('XDist');
        axH.XDist = 0.5*axH.XRange;
        axH.addprop('YDist');
        axH.YDist = 0.5*axH.YRange;
        axH.addprop('ZDist');        
        axH.ZDist = 0.5*axH.ZRange;
        
        axH.addprop('OldXLim');
        axH.OldXLim = axH.XLim;
        axH.addprop('OldYLim');
        axH.OldYLim = axH.YLim;
        axH.addprop('OldZLim');
        axH.OldZLim = axH.ZLim;
        
        % Adding custom toolbar to allow ZoomToCursor
        tb = axtoolbar(axH,{});
    
        btn = axtoolbarbtn(tb,'state');
        btn.Icon = 'MagnifyingGlassBlackAndYellow.png';
        btn.Tooltip = 'Zoom to Cursor';
        btn.ValueChangedFcn = @ZoomToCursor;        

    end 

    function [axH] = SetAxisTitle(axH,title)
        % Set image (actually axis) title to top center of axis
        axH.Title.String = title;
        axH.Title.Units = 'Normalized';
        axH.Title.HorizontalAlignment = 'Center';
        axH.Title.VerticalAlignment = 'Top';
        axH.Title.Color = 'Yellow';
        axH.Title.Position = [0.5,1.0,0];
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
    
    %% CALLBACKS
    function [] = ChangeActiveObject(source,event)
        % do nothing for now
    end
    
    function [] = ChangeActiveGroup(source,event)
        data = guidata(source);
        OldGroupIndex = data.CurrentGroupIndex;
        NewGroupIndex = source.Value;
        data.CurrentGroupIndex = NewGroupIndex;
        UpdateLog3(source,['Changed current group from ',data.Group(OldGroupIndex).GroupName,' to ',data.Group(NewGroupIndex).GroupName],'append');
        
        group = data.Group(NewGroupIndex);
        ImageIndex = group.CurrentImageIndex;
        FFCData = group.FFCData;

        % update ImageListBox Items to reflect current user-specified group
        try
            data.Handles.ImageListBox.Items = group.ImageNames;
            data.Handles.ImageListBox.ItemsData = [1:length(group.ImageNames)];
            data.Handles.ImageListBox.Value = group.CurrentImageIndex;
        catch
            data.Handles.ImageListBox.Items = {'No images loaded for this group...'};
        end
        
        replicate = group.Replicate(group.CurrentImageIndex);
        
        % update ObjectListBox Items to reflect current user-specified
        % group/replicate
        try
            data.Handles.ObjectSelector.Items = replicate.ObjectNames;
            data.Handles.ObjectSelector.ItemsData = [1:length(replicate.ObjectNames)];
            data.Handles.ObjectSelector.Value = replicate.CurrentObjectIdx;
        catch
            data.Handles.ObjectSelector.Items = {'No objects identified for this group...'};
        end        
        
        
        
        
        guidata(source,data);        
        % update gui image objects with user-specified group
        UpdateImages(source);
        UpdateTables(source);
    end

    function [] = ChangeActiveImage(source,event)
        disp('user changed image');
        % get PODSData
        data = guidata(source);
        % get current group index
        CurrentGroupIndex = data.CurrentGroupIndex;
        % get old image index (before user click)
        OldImageIndex = data.Group(CurrentGroupIndex).CurrentImageIndex;
        % new image index, according to user click
        NewImageIndex = source.Value;
        % Update data with new image index
        data.Group(CurrentGroupIndex).CurrentImageIndex = NewImageIndex;
        
        if length(NewImageIndex) > 1
            UpdateLog3(source,[num2str(length(NewImageIndex)),'images selected for analysis'],'append');
        else
            NewImage = data.Group(CurrentGroupIndex).Replicate(NewImageIndex).pol_shortname;
            UpdateLog3(source,['Selected ',NewImage,' for analysis'],'append');
        end
        
        replicate = data.Group(CurrentGroupIndex).Replicate(NewImageIndex);
        
        % update ObjectListBox Items to reflect current user-specified
        % group/replicate
        try
            data.Handles.ObjectSelector.Items = replicate.ObjectNames;
            data.Handles.ObjectSelector.ItemsData = [1:length(replicate.ObjectNames)];
            data.Handles.ObjectSelector.Value = replicate.CurrentObjectIdx;
        catch
            data.Handles.ObjectListBox.Items = {'No objects identified for this group...'};
        end        

        guidata(source,data);        
        UpdateImages(source);
        UpdateTables(source);        
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

    function [] = SESizeChanged(source,event)
        data = guidata(source);
        cGroupIndex = data.CurrentGroupIndex;
        cImageIndex = data.Group(cGroupIndex).CurrentImageIndex; 
        
        for i = 1:length(cImageIndex)
            ii = cImageIndex(i);
            data.Group(cGroupIndex).Replicate(ii).SESize = source.Value;
        end
        guidata(source,data);
        UpdateTables(source);
    end

    function [] = SELinesChanged(source,event)
        data = guidata(source);
        cGroupIndex = data.CurrentGroupIndex;
        cImageIndex = data.Group(cGroupIndex).CurrentImageIndex;
        
        for i = 1:length(cImageIndex)
            ii = cImageIndex(i);
            data.Group(cGroupIndex).Replicate(ii).SELines = source.Value;
        end         
        guidata(source,data);
        UpdateTables(source);
    end

%     waitfor(fH)
%     close all

end