classdef PODSSettings < handle
    %PODSSettings - PODSGUI project & display settings
    %   An instance of this class holds and determines various 
    %   settings for a single run of PODS GUI
    
    properties
        
        Zoom = struct('XRange',0,...
            'YRange',0,...
            'ZRange',0,...
            'XDist',0,...
            'YDist',0,...
            'OldXLim',[0 1],...
            'OldYLim',[0 1],...
            'pct',0.5,...
            'ZoomLevels',[1/20 1/15 1/10 1/5 1/3 1/2 1/1.5 1/1.25 1],...
            'ZoomLevelIdx',6,...
            'OldWindowButtonMotionFcn','',...
            'OldImageButtonDownFcn','',...
            'Active',false,...
            'Freeze',false,...
            'Restore',false,...
            'RestoreProps',[],...
            'CurrentButton',gobjects(1,1),...
            'StaticAxes',gobjects(1,1),...
            'StaticImage',gobjects(1,1),...
            'DynamicAxes',gobjects(1,1),...
            'DynamicAxesParent',gobjects(1,1),...
            'ActiveObjectIdx',NaN);
        
        InputFileType = '.nd2';

        LastDirectory = pwd;

        % path to main code directory (path with PODSv2.m)
        MainPath char

        SummaryDisplayType = 'Project';
        
        % monitor tab switching
        CurrentTab = 'Files';
        PreviousTab = 'Files';
        
        % current image operation
        CurrentImageOperation = 'Mask Threshold';
        
        % size of the display (to set main window Position)
        ScreenSize

        % starts as optimized font size (px) based on size of display, user can change
        FontSize

        % themes and colors for GUI display
        GUITheme = 'Dark';
        GUIBackgroundColor = [0 0 0];
        GUIForegroundColor = [1 1 1];
        GUIHighlightColor = [1 1 1];

        % sturcturing element for masking
        SEShape = 'disk';
        SESize = 3;
        SELines = 0;
        
        % for now, just 'One-Color'
        ExperimentType = 'One-Color';
        % for now, just 1
        nChannels = 1;
        
        % colormaps settings
        Colormaps struct
        ColormapsSettings struct
        
        % Azimuth display settings
        AzimuthDisplaySettings struct
        
        % ScatterPlot Settings
        ScatterPlotSettings struct
        ScatterPlotBackgroundColor = [0 0 0];
        ScatterPlotForegroundColor = [1 1 1];
        ScatterPlotLegendVisible = true;

        % SwarmPlot Settings
        SwarmPlotSettings struct
        SwarmPlotBackgroundColor = [0 0 0];
        SwarmPlotForegroundColor = [1 1 1];
        SwarmPlotErrorBarColor = [1 1 1];

        % variables for object plots (swarm and scatter plots for now)
        ObjectPlotVariables cell
        
        % object labeling
        ObjectLabels PODSLabel
        
        % Fonts
        DefaultFont char
        DefaultPlotFont = 'Arial';
        
        % default px size (um/px)
        PixelSize = 0.1083;

        % type of mask to generate and use for object detection
        % Default, CustomScheme, or CustomUpload
        MaskType = 'Default';

        % various names
        MaskName = 'Legacy';
        
        % custom mask schemes
        SchemeNames cell
        SchemePaths cell
        
        % object box type ('Box','Boundary',etc...)
        ObjectBoxType = 'Box';

    end

    properties (Dependent = true)

        % azimuth display settings
        AzimuthLineAlpha
        AzimuthLineWidth
        AzimuthLineScale
        AzimuthScaleDownFactor
        AzimuthColorMode

        % Scatterplot settings
        ScatterPlotXVariable
        ScatterPlotYVariable

        % SwarmPlot settings
        SwarmPlotYVariable
        SwarmPlotGroupingType
        SwarmPlotColorMode

        % Object variables "long" names
        ObjectPlotVariablesLong

        % for adding/deleting/adjusting labels
        nLabels
        LabelColors

        % selected colormaps for different image types
        % must be 256x3 double with values in the range [0 1]
        IntensityColormap double
        OrderFactorColormap double
        ReferenceColormap double
        AzimuthColormap double

    end
    
    methods
        
        % constructor method
        function obj = PODSSettings()
            % size of main monitor
            obj.ScreenSize = GetMaximizedScreenSize(1);
            % optimum font size
            obj.FontSize = ceil(obj.ScreenSize(4)*.01);
            % set up default object label (PODSLabel object)
            obj.ObjectLabels(1) = PODSLabel('Default',[1 1 0],obj);
            % get list of supported fonts
            FontList = listfonts();
            % check if 'Consolas' is in list of supported fonts
            if ismember('Consolas',FontList)
                obj.DefaultFont = 'Consolas';   % if so, make it default
            else
                obj.DefaultFont = 'Courier New';  % otherwise, use 'Courier New'
            end

            if ismac || isunix
                % get the path to this .m file (two levels below the directory we want)
                CurrentPathSplit = strsplit(mfilename("fullpath"),'/');
                % get the "MainPath" (path to main gui driver)
                obj.MainPath = strjoin(CurrentPathSplit(1:end-2),'/');
            elseif ispc
                CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
                obj.MainPath = strjoin(CurrentPathSplit(1:end-2),'\');
            end

            settingsFiles = {...
                'ObjectPlotVariables.mat',...
                'Colormaps.mat',...
                'ColormapsSettings.mat',...
                'ScatterPlotSettings.mat',...
                'SwarmPlotSettings.mat',...
                'AzimuthDisplaySettings.mat'};

            obj.updateSettingsFromFiles(settingsFiles);

            try 
                obj.LoadCustomMaskSchemes();
            catch
                warning('Unable to load custom mask schemes...')
            end
            
        end

        % saveobj method
        function settings = saveobj(obj)

            settings.InputFileType = obj.InputFileType;

            settings.SummaryDisplayType = obj.SummaryDisplayType;

            % monitor tab switching
            settings.CurrentTab = obj.CurrentTab;
            settings.PreviousTab = obj.PreviousTab;

            % current image operation
            settings.CurrentImageOperation = obj.CurrentImageOperation;

            % themes and colors for GUI display
            settings.GUITheme = obj.GUITheme;
            settings.GUIBackgroundColor = obj.GUIBackgroundColor;
            settings.GUIForegroundColor = obj.GUIForegroundColor;
            settings.GUIHighlightColor = obj.GUIHighlightColor;

            % sturcturing element for masking
            settings.SEShape = obj.SEShape;
            settings.SESize = obj.SESize;
            settings.SELines = obj.SELines;

            % ScatterPlot Settings
            settings.ScatterPlotBackgroundColor = obj.ScatterPlotBackgroundColor;
            settings.ScatterPlotForegroundColor = obj.ScatterPlotForegroundColor;
            settings.ScatterPlotLegendVisible = obj.ScatterPlotLegendVisible;

            % SwarmPlot Settings
            settings.SwarmPlotBackgroundColor = obj.SwarmPlotBackgroundColor;
            settings.SwarmPlotForegroundColor = obj.SwarmPlotForegroundColor;
            settings.SwarmPlotErrorBarColor = obj.SwarmPlotErrorBarColor;

            % object labeling
            settings.ObjectLabels = obj.ObjectLabels;

            % type of mask to generate and use for object detection
            % Default, CustomScheme, or CustomUpload
            settings.MaskType = obj.MaskType;

            % various names
            settings.MaskName = obj.MaskName;

            % object box type ('Box' or 'Boundary')
            settings.ObjectBoxType = obj.ObjectBoxType;

        end

        function LoadCustomMaskSchemes(obj)
            if ismac || isunix
                SchemeFilesList = dir(fullfile([obj.MainPath,'/CustomMasks/Schemes'],'*.mat'));
            elseif ispc
                SchemeFilesList = dir(fullfile([obj.MainPath,'\CustomMasks\Schemes'],'*.mat'));
            end

            for i = 1:numel(SchemeFilesList)
                SplitName = strsplit(SchemeFilesList(i).name,'.');
                obj.SchemeNames{i} = SplitName{1};
                if ismac || isunix
                    obj.SchemePaths{i} = [SchemeFilesList(i).folder,'/',SchemeFilesList(i).name];
                elseif ispc
                    obj.SchemePaths{i} = [SchemeFilesList(i).folder,'\',SchemeFilesList(i).name];
                end
            end
        end

        function updateSettingsFromFiles(obj,fileNames)
            % generalized function to update various settings by loading the indicated file(s)
            % fileNames is a cell array of char vectors with names of settings mat files
            for fileIdx = 1:numel(fileNames)
                try
                    % load the mat file indicated by fileNames{fileIdx} as a struct
                    file = load(fileNames{fileIdx});
                    % get the filedName of the loaded struct, not hardcoded in case it changes or we add more settings
                    fieldName = fieldnames(file);
                    % store the settings in the associated class property
                    obj.(fieldName{1}) = file.(fieldName{1});
                catch ME
                    warning(['Error loading file "',fileNames{fileIdx},'": ',ME.getReport]);
                end
            end
        end
    
        function AddNewObjectLabel(obj,LabelName,LabelColor)
            if isempty(LabelColor)
                BGColors = [0 0 0;1 1 1];
                LabelColor = distinguishable_colors(1,[obj.LabelColors;BGColors]);
            end

            if isempty(LabelName)
                LabelName = ['Untitled Label ',num2str(obj.nLabels+1)];
            end

            obj.ObjectLabels(end+1,1) = PODSLabel(LabelName,LabelColor,obj);
        end

        function DeleteObjectLabel(obj,Label)
            Label2Delete = Label;
            LabelIdx = find(obj.ObjectLabels==Label2Delete);
            if LabelIdx == 1
                if obj.nLabels > 1
                    obj.ObjectLabels = obj.ObjectLabels(2:end);
                else
                    obj.ObjectLabels = PODSLabel.empty();
                end
            elseif LabelIdx == obj.nLabels
                obj.ObjectLabels = obj.ObjectLabels(1:end-1);
            else
                obj.ObjectLabels = [obj.ObjectLabels(1:LabelIdx-1);obj.ObjectLabels(LabelIdx+1:end)];
            end
            delete(Label2Delete);
        end

        function ObjectPlotVariablesLong = get.ObjectPlotVariablesLong(obj)
            ObjectPlotVariablesLong = cell(size(obj.ObjectPlotVariables));
            for varIdx = 1:numel(obj.ObjectPlotVariables)
                ObjectPlotVariablesLong{varIdx} = ExpandVariableName(obj.ObjectPlotVariables{varIdx});
            end
        end

        function IntensityColormap = get.IntensityColormap(obj)
            IntensityColormap = obj.ColormapsSettings.Intensity{3};
        end

        function OrderFactorColormap = get.OrderFactorColormap(obj)
            OrderFactorColormap = obj.ColormapsSettings.OrderFactor{3};
        end

        function ReferenceColormap = get.ReferenceColormap(obj)
            ReferenceColormap = obj.ColormapsSettings.Reference{3};
        end

        function AzimuthColormap = get.AzimuthColormap(obj)
            AzimuthColormap = obj.ColormapsSettings.Azimuth{3};
        end

        function AzimuthLineAlpha = get.AzimuthLineAlpha(obj)
            AzimuthLineAlpha = obj.AzimuthDisplaySettings.LineAlpha;
        end

        function AzimuthLineWidth = get.AzimuthLineWidth(obj)
            AzimuthLineWidth = obj.AzimuthDisplaySettings.LineWidth;
        end

        function AzimuthLineScale = get.AzimuthLineScale(obj)
            AzimuthLineScale = obj.AzimuthDisplaySettings.LineScale;
        end

        function AzimuthScaleDownFactor = get.AzimuthScaleDownFactor(obj)
            AzimuthScaleDownFactor = obj.AzimuthDisplaySettings.ScaleDownFactor;
        end

        function AzimuthColorMode = get.AzimuthColorMode(obj)
            AzimuthColorMode = obj.AzimuthDisplaySettings.ColorMode;
        end

        function ScatterPlotXVariable = get.ScatterPlotXVariable(obj)
            ScatterPlotXVariable = obj.ScatterPlotSettings.XVariable;
        end

        function ScatterPlotYVariable = get.ScatterPlotYVariable(obj)
            ScatterPlotYVariable = obj.ScatterPlotSettings.YVariable;
        end

        function SwarmPlotYVariable = get.SwarmPlotYVariable(obj)
            SwarmPlotYVariable = obj.SwarmPlotSettings.YVariable;
        end

        function SwarmPlotColorMode = get.SwarmPlotColorMode(obj)
            SwarmPlotColorMode = obj.SwarmPlotSettings.ColorMode;
        end

        function SwarmPlotGroupingType = get.SwarmPlotGroupingType(obj)
            SwarmPlotGroupingType = obj.SwarmPlotSettings.GroupingType;
        end

        function nLabels = get.nLabels(obj)
            % find number of unique object labels
            nLabels = numel(obj.ObjectLabels);
        end

        function LabelColors = get.LabelColors(obj)
            % initialize label colors array
            LabelColors = zeros(obj.nLabels,3);
            % add the colors from each label
            for i = 1:obj.nLabels
                LabelColors(i,:) = obj.ObjectLabels(i).Color;
            end
        end

    end

    methods (Static)

        function obj = loadobj(settings)

            % create the default settings object, to which we will add our saved settings
            obj = PODSSettings();

            obj.InputFileType = settings.InputFileType;

            obj.SummaryDisplayType = settings.SummaryDisplayType;

            % monitor tab switching
            obj.CurrentTab = settings.CurrentTab;
            obj.PreviousTab = settings.PreviousTab;

            % current image operation
            obj.CurrentImageOperation = settings.CurrentImageOperation;

            % themes and colors for GUI display
            obj.GUITheme = settings.GUITheme;
            obj.GUIBackgroundColor = settings.GUIBackgroundColor;
            obj.GUIForegroundColor = settings.GUIForegroundColor;
            obj.GUIHighlightColor = settings.GUIHighlightColor;

            % sturcturing element for masking
            obj.SEShape = settings.SEShape;
            obj.SESize = settings.SESize;
            obj.SELines = settings.SELines;

            % ScatterPlot Settings
            obj.ScatterPlotBackgroundColor = settings.ScatterPlotBackgroundColor;
            obj.ScatterPlotForegroundColor = settings.ScatterPlotForegroundColor;
            obj.ScatterPlotLegendVisible = settings.ScatterPlotLegendVisible;

            % SwarmPlot Settings
            obj.SwarmPlotBackgroundColor = settings.SwarmPlotBackgroundColor;
            obj.SwarmPlotForegroundColor = settings.SwarmPlotForegroundColor;
            obj.SwarmPlotErrorBarColor = settings.SwarmPlotErrorBarColor;

            % object labeling
            obj.ObjectLabels = settings.ObjectLabels;

            % make sure to add this settings object to each of the labels
            for LabelIdx = 1:numel(obj.ObjectLabels)
                obj.ObjectLabels(LabelIdx).Settings = obj;
            end

            % type of mask to generate and use for object detection
            % Default, CustomScheme, or CustomUpload
            obj.MaskType = settings.MaskType;

            % various names
            obj.MaskName = settings.MaskName;

            % object box type ('Box' or 'Boundary')
            obj.ObjectBoxType = settings.ObjectBoxType;
        end

    end
end

