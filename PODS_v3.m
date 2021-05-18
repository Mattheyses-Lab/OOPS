function [] = PODS_v3()
    
%% Need to go through and add all handle arrays to PODSData.Handles

% get monitor positions to determine figure size
    MonitorPosition = get(0, 'MonitorPositions');
    
    % get size of main monitor
    MP1 = MonitorPosition(1,1:4);


    % struct to hold gui settings
    UserSettings = struct('InputFileType','.nd2',...
                          'MaskType','MakeNew',...
                          'CurrentTab','Files',...
                          'PreviousTab','Files',...
                          'ScreenSize',MP1);

    % data structure for individual replicates
    Replicate = struct('OF_Avg',0,...
                       'FilteredOFAvg',0,...
                       'pol_shortname','');
              
    % data structure holding all groups within one experiment
    Group = struct('Replicate',Replicate,...
                   'CurrentImageIndex',1,...
                   'BatchImageIndex',[],...
                   'nReplicates',0,...
                   'FFCData',struct(),...
                   'GroupName','Untitled Group 1',...
                   'ImageNames',{'No Image Found'});
    
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
                 'Position',[MP1(1) MP1(2) MP1(3) MP1(4)],...
                 'Visible','On',...
                 'Color','yellow',...
                 'HandleVisibility','on',...
                 'AutoResizeChildren','on');
    
    % draw the figure body
    drawnow
    %% File Menu Button - Create a new project, load files, etc...
    hFileMenu = uimenu(fH,'Text','File');
    % Options for File Menu Button
    hNewProject = uimenu(hFileMenu,'Text','New Project','MenuSelectedFcn',@NewProject);
    hLoadFFCFiles = uimenu(hFileMenu,'Text','Load FFC Files','MenuSelectedFcn',@pb_LoadFFCFiles);
    hLoadFPMFiles = uimenu(hFileMenu,'Text','Load FPM Files','MenuSelectedFcn',@pb_LoadFPMFiles);
    
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
    %hProcessFFC = uimenu(hProcessMenu,'Text','Process');
    
    drawnow
    pause(0.1)
    
    pos = fH.Position
    
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
    
%% DRAW INITIAL PANELS    
    % Panel to display overall gui settings, has buttons for various tools
    % that can be used in any tab
    AppInfoPanel = uipanel('Parent',fH,...
                           'Position',[1 round(0.100*pos(4)) round(0.200*pos(3))+2 round(0.900*pos(4))+1],...
                           'BackgroundColor','black',...
                           'BorderType','line');

    % holds log window and summary table                   
    LogPanel = uipanel('Parent',fH,...
                       'Position',[1 1 pos(3) round(0.100*pos(4))],...
                       'BackgroundColor','black',...
                       'BorderType','line');
                       
    % holds info and tools relevant to current tab                    
    ImgInfoPanel = uipanel('Parent',fH,...
                           'Position',[round(0.200*pos(3))+2 round(0.100*pos(4)+height)-1 round(width*2)-1 round(0.900*pos(4)-height)+2],...
                           'BackgroundColor','black',...
                           'BorderType','line'); 
                       
    % Bottom left panel of 2-panel tabs        
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
                'AutoResizeChildren','On',...
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
                           'Value',{'Log Window'}); 
                      
    pos = ImgInfoPanel.InnerPosition;                   
    GroupSelector = uilistbox('parent',ImgInfoPanel,...
                              'Position', [0.05*pos(4) 0.05*pos(4) 0.1*pos(3) 0.8*pos(4)],...
                              'enable','on',...
                              'tag','GroupListBox',...
                              'Items',{'UntitledGroup1'},...
                              'ValueChangedFcn',@ChangeActiveGroup);
                          
    GroupSelectorTitle = uilabel('Parent',ImgInfoPanel,...
                                 'Position', [0.05*pos(4) 0.05*pos(4)+0.8*pos(4) 0.1*pos(3) 20],...
                                 'FontColor','Yellow',...
                                 'Text','Select Group');
                  
                             
                             
    ImageSelector = uilistbox('parent',ImgInfoPanel,...
                              'Position', [(0.05*pos(4))*2+0.1*pos(3) 0.05*pos(4) 0.3*pos(3) 0.8*pos(4)],...
                              'enable','on',...
                              'tag','ImageListBox',...
                              'Items',{'No Images Loaded'},...
                              'ValueChangedFcn',@ChangeActiveImage,...
                              'MultiSelect','on');                          

    ImageSelectorTitle = uilabel('Parent',ImgInfoPanel,...
                                 'Position', [(0.05*pos(4))*2+0.1*pos(3) 0.05*pos(4)+0.8*pos(4) 0.3*pos(3) 20],...
                                 'FontColor','Yellow',...
                                 'Text','Select Image');                          
                          

                             
                                                     
                             
    pos = AppInfoPanel.Position;

    ProjectDataTable = uilabel('Parent',AppInfoPanel,...
                               'Position',[20 0.5*pos(4) pos(3)-40 0.5*pos(4)-20],...
                               'tag','ProjectDataTable',...
                               'Text','Loading...',...
                               'FontColor','Yellow',...
                               'FontName','Courier',...
                               'BackgroundColor','#3b3b3b',...
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
        FFCImgH(i) = imshow(emptyimage,'Parent',FFCAxH(i));
        % set a tag so our callback functions can find the image
        set(FFCImgH(i),'Tag',['FFCImage' num2str((i-1)*45)]);

        % restore original values after imshow() call
        FFCAxH(i) = restore_axis_defaults(FFCAxH(i),pbarOriginal,tagOriginal);

        FFCAxH(i) = SetAxisTitle(FFCAxH(i),['Flat-Field Image (' num2str((i-1)*45) '^{\circ} Excitation)']);
    end
    %% RAW INTENSITY IMAGES
    for i = 1:4
        RawIntensityAxH(i) = uiaxes('Parent',SmallPanels(2,i),...
                                    'Units','normalized',...
                                    'InnerPosition',[0 0 1 1],...
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
        
    end
    %% FLAT-FIELD CORRECTED INTENSITY
    for i = 1:4
        PolFFCAxH(i) = uiaxes('Parent',SmallPanels(2,i),...
                              'Units','normalized',...
                              'InnerPosition',[0 0 1 1],...
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
        
        PolFFCImgH(i).Visible = 'Off';
        PolFFCAxH(i).Title.Visible = 'Off';
    end
    %% MASKING STEPS
    for i = 1:4
        switch i
            case 1
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(1,1),...
                                      'Units','normalized',...
                                      'InnerPosition',[0 0 1 1],...
                                      'Tag','MStepsIntensity',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Average Intensity';
                image_tag = 'MStepsIntensityImage';
            case 2
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(1,2),...
                                      'Units','normalized',...
                                      'InnerPosition',[0 0 1 1],...
                                      'Tag','MStepsBackground',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Background Intensity';
                image_tag = 'MStepsBackgroundImage';                                
            case 3
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(2,1),...
                                      'Units','normalized',...
                                      'InnerPosition',[0 0 1 1],...
                                      'Tag','MStepsBGSubtracted',...
                                      'XTick',[],...
                                      'YTick',[]);
                image_title = 'Background Subtracted Intensity';
                image_tag = 'MStepsBGSubtractedImage';                                
            case 4
                MStepsAxH(i) = uiaxes('Parent',SmallPanels(2,2),...
                                      'Units','normalized',...
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
        MStepsImgH(i) = imshow(emptyimage,'Parent',MStepsAxH(i));
        % set a tag so our callback functions can find the image
        set(MStepsImgH(i),'Tag',image_tag);

        % restore original values after imshow() call
        MStepsAxH(i) = restore_axis_defaults(MStepsAxH(i),pbarOriginal,tagOriginal);
        % set axis title
        MStepsAxH(i) = SetAxisTitle(MStepsAxH(i),image_title);
        
        MStepsImgH(i).Visible = 'Off';
        MStepsAxH(i).Title.Visible = 'Off';
    end
    %% AVERAGE INTENSITY
    for i = 1:1
        % create an axis, child of a panel, to fill the container
        AverageIntensityAxH = uiaxes('Parent',ImgPanel1,...
                                     'Units','normalized',...
                                     'InnerPosition',[0 0 1 1],...
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

        AverageIntensityImgH.Visible = 'Off';
        AverageIntensityAxH.Title.Visible = 'Off';
        %% Order Factor
        % create an axis, child of a panel, to fill the container
        OrderFactorAxH = uiaxes('Parent',ImgPanel2,...
                                'Units','normalized',...
                                'InnerPosition',[0 0 1 1],...
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
        
        axes(OrderFactorAxH)
        
        % custom colormap/colorbar
        [mycolormap,mycolormap_noblack] = MakeRGB;
        OF_cbar = colorbar('location','east','color','white');
        colormap(gca,mycolormap);

        OrderFactorImgH.Visible = 'Off';
        OrderFactorAxH.Title.Visible = 'Off';
        %% Azimuth
        % create an axis, child of a panel, to fill the container
        AzimuthAxH = uiaxes('Parent',ImgPanel2,...
                            'Units','normalized',...
                            'InnerPosition',[0 0 1 1],...
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

        AzimuthImgH.Visible = 'Off';
        AzimuthAxH.Title.Visible = 'Off';    
        %% Anisotropy
        % create an axis, child of a panel, to fill the container
        AnisotropyAxH = uiaxes('Parent',ImgPanel2,...
                               'Units','normalized',...
                               'InnerPosition',[0 0 1 1],...
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

        AnisotropyImgH.Visible = 'Off';
        AnisotropyAxH.Title.Visible = 'Off';
        %% S-B Filtering
        % create an axis, child of a panel, to fill the container
        SBAverageIntensityAxH = uiaxes('Parent',ImgPanel1,...
                                       'Units','normalized',...
                                       'InnerPosition',[0 0 1 1],...
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

        SBAverageIntensityImgH.Visible = 'Off';
        SBAverageIntensityAxH.Title.Visible = 'Off';    
        %% MASK
        % create an axis, child of a panel, to fill the container
        MaskAxH = uiaxes('Parent',ImgPanel2,...
                         'Units','normalized',...
                         'InnerPosition',[0 0 1 1],...
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

        MaskImgH.Visible = 'Off';
        MaskAxH.Title.Visible = 'Off';

         %% SB FILTERED MASK
        % create an axis, child of a panel, to fill the container
        SBMaskAxH = uiaxes('Parent',ImgPanel2,...
                           'Units','normalized',...
                           'InnerPosition',[0 0 1 1],...
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
    
    % Should do this for all handles
    PODSData.Handles.FFCAxH = FFCAxH;
    PODSData.Handles.FFCImgH = FFCImgH;
    
    PODSData.Handles.SmallPanels = SmallPanels;
    
    % masking steps
    PODSData.Handles.MStepsAxH = MStepsAxH;
    PODSData.Handles.MStepsImgH = MStepsImgH;
    
    % flat-field corrected intensity
    PODSData.Handles.PolFFCAxH = PolFFCAxH;
    PODSData.Handles.PolFFCImgH = PolFFCImgH;
    
    % raw intensity images
    PODSData.Handles.RawIntensityAxH = RawIntensityAxH;
    PODSData.Handles.RawIntensityImgH = RawIntensityImgH;
    
    % average intensity
    PODSData.Handles.AverageIntensityAxH = AverageIntensityAxH;
    PODSData.Handles.AverageIntensityImgH = AverageIntensityImgH;
    
    % order factor
    PODSData.Handles.OrderFactorAxH = OrderFactorAxH;
    PODSData.Handles.OrderFactorImgH = OrderFactorImgH;
    
    % azimuth
    PODSData.Handles.AzimuthAxH = AzimuthAxH;
    PODSData.Handles.AzimuthImgH = AzimuthImgH;
    
    % anisotropy
    PODSData.Handles.AnisotropyAxH = AnisotropyAxH;
    PODSData.Handles.AnisotropyImgH = AnisotropyImgH;
    
    % SB-filtered intensity
    PODSData.Handles.SBAverageIntensityAxH = SBAverageIntensityAxH;
    PODSData.Handles.SBAverageIntensityImgH = SBAverageIntensityImgH;
    
    % Binary mask
    PODSData.Handles.MaskAxH = MaskAxH;
    PODSData.Handles.MaskImgH = MaskImgH;
        
    % SB-filtered binary mask
    PODSData.Handles.SBMaskAxH = SBMaskAxH;
    PODSData.Handles.SBMaskImgH = SBMaskImgH;    
    
    % large image panels
    PODSData.Handles.ImgPanel1 = ImgPanel1;
    PODSData.Handles.ImgPanel2 = ImgPanel2;
    
    % update guidata with handles structure                     
    guidata(fH,PODSData)
    
    disp(ProjectDataTable.Text(1))
    
    test_fcn(fH);

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
                for i = 1:4
                    RawIntensityAxH(i).Parent = SmallPanels(1,i);
                    
                    FFCImgH(i).Visible = 'Off';
                    FFCAxH(i).Title.Visible = 'Off';
                    
                    RawIntensityImgH(i).Visible = 'Off';
                    RawIntensityAxH(i).Title.Visible = 'Off';
                end
                
            case 'FFC'
                for i = 1:4
                    RawIntensityAxH(i).Parent = SmallPanels(2,i);
                    
                    PolFFCImgH(i).Visible = 'Off';
                    PolFFCAxH(i).Title.Visible = 'Off';
                    
                    RawIntensityImgH(i).Visible = 'Off';
                    RawIntensityAxH(i).Title.Visible = 'Off';
                end
                
            case 'Generate Mask'
                MaskImgH.Visible = 'Off';
                MaskAxH.Title.Visible = 'Off';
                
                for i = 1:2
                    MStepsImgH(i).Visible = 'Off';
                    MStepsAxH(i).Title.Visible = 'Off';
                    
                    MStepsImgH(i+2).Visible = 'Off';
                    MStepsAxH(i+2).Title.Visible = 'Off';
                    
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';
                end
                
            case 'View/Adjust Mask'
                AverageIntensityImgH.Visible = 'Off';
                AverageIntensityAxH.Title.Visible = 'Off';

                MaskImgH.Visible = 'Off';
                MaskAxH.Title.Visible = 'Off';
                
            case 'Order Factor'       
                OrderFactorImgH.Visible = 'Off';
                OrderFactorAxH.Title.Visible = 'Off';

                AverageIntensityImgH.Visible = 'Off';
                AverageIntensityAxH.Title.Visible = 'Off';
                
            case 'Azimuth' 
                AzimuthImgH.Visible = 'Off';
                AzimuthAxH.Title.Visible = 'Off';

                AverageIntensityImgH.Visible = 'Off';
                AverageIntensityAxH.Title.Visible = 'Off';
                
            case 'Anisotropy'       
                AnisotropyImgH.Visible = 'Off';
                AnisotropyAxH.Title.Visible = 'Off';

                AverageIntensityImgH.Visible = 'Off';
                AverageIntensityAxH.Title.Visible = 'Off';
                
            case 'SB-Filtering'
                SBAverageIntensityImgH.Visible = 'Off';
                SBAverageIntensityAxH.Title.Visible = 'Off';

                SBMaskImgH.Visible = 'Off';
                SBMaskAxH.Title.Visible = 'Off';
        end
        
        switch NewTab
            case 'Files'
                for i = 1:4
                    RawIntensityAxH(i).Parent = SmallPanels(2,i);
                    
                    RawIntensityAxH(i).Title.Visible = 'On';
                    RawIntensityImgH(i).Visible = 'On';
                    
                    FFCImgH(i).Visible = 'On';
                    FFCAxH(i).Title.Visible = 'On';
                    
                    SmallPanels(1,i).Visible = 'On';
                    SmallPanels(2,i).Visible = 'On';
                end
                ImgPanel1.Visible = 'Off';
                ImgPanel2.Visible = 'Off';
                
            case 'FFC'
                for i = 1:4
                    RawIntensityAxH(i).Parent = SmallPanels(1,i);
                    
                    PolFFCImgH(i).Visible = 'On';
                    PolFFCAxH(i).Title.Visible = 'On';
                    
                    RawIntensityImgH(i).Visible = 'On';
                    RawIntensityAxH(i).Title.Visible = 'On';
                    
                    SmallPanels(1,i).Visible = 'On';
                    SmallPanels(2,i).Visible = 'On';
                end
                ImgPanel1.Visible = 'Off';
                ImgPanel2.Visible = 'Off';
                
            case 'Generate Mask' 
                MaskImgH.Visible = 'On';
                MaskAxH.Title.Visible = 'On';
                
                ImgPanel1.Visible = 'Off';                
                ImgPanel2.Visible = 'On';
                
                for i = 1:2
                    MStepsImgH(i).Visible = 'On';
                    MStepsAxH(i).Title.Visible = 'On';
                    
                    MStepsImgH(i+2).Visible = 'On';
                    MStepsAxH(i+2).Title.Visible = 'On';
                    
                    SmallPanels(1,i).Visible = 'On';
                    SmallPanels(2,i).Visible = 'On';
                    
                    SmallPanels(1,i+2).Visible = 'Off';
                    SmallPanels(2,i+2).Visible = 'Off';                    
                end
                
            case 'View/Adjust Mask'         
                AverageIntensityImgH.Visible = 'On';
                AverageIntensityAxH.Title.Visible = 'On';
                
                MaskImgH.Visible = 'On';
                MaskAxH.Title.Visible = 'On';                
                
                ImgPanel1.Visible = 'On';
                ImgPanel2.Visible = 'On';
                
                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end
                
            case 'Order Factor'
                OrderFactorImgH.Visible = 'On';
                OrderFactorAxH.Title.Visible = 'On';
                
                AverageIntensityImgH.Visible = 'On';
                AverageIntensityAxH.Title.Visible = 'On';                
                
                ImgPanel2.Visible = 'On';
                ImgPanel1.Visible = 'On';
                
                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end                
                
            case 'Azimuth'
                AzimuthImgH.Visible = 'On';
                AzimuthAxH.Title.Visible = 'On';
                
                AverageIntensityImgH.Visible = 'On';
                AverageIntensityAxH.Title.Visible = 'On';
                
                ImgPanel1.Visible = 'On';
                ImgPanel2.Visible = 'On';

                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end                 
                
            case 'Anisotropy'
                AnisotropyImgH.Visible = 'On';
                AnisotropyAxH.Title.Visible = 'On';
                
                AverageIntensityImgH.Visible = 'On';
                AverageIntensityAxH.Title.Visible = 'On';                
                
                ImgPanel1.Visible = 'On';                
                ImgPanel2.Visible = 'On';
                
                for i = 1:4
                    SmallPanels(1,i).Visible = 'Off';
                    SmallPanels(2,i).Visible = 'Off';                
                end 

            case 'SB-Filtering'
                SBAverageIntensityImgH.Visible = 'On';
                SBAverageIntensityAxH.Title.Visible = 'On';
                
                SBMaskImgH.Visible = 'On';
                SBMaskAxH.Title.Visible = 'On';                
                
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
    
    %% CaALLBACKS
    
    
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
        
        
        guidata(source,data);        
        % update gui image objects with user-specified group
        UpdateImages(source);
        UpdateTables(source);
    end

    function [] = ChangeActiveImage(source,event)
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
        
        guidata(source,data);        
        UpdateImages(source);
        UpdateTables(source);        
    end

%     waitfor(fH)
%     close all

end