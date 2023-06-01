classdef OOPSSettings < handle
    %OOPSSettings - OOPSGUI project & display settings
    %   An instance of this class holds and determines various 
    %   settings for a single run of OOPS GUI
    
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
            'CurrentButton',[],...
            'StaticAxes',[],...
            'StaticImage',[],...
            'DynamicAxes',[],...
            'DynamicAxesParent',[],...
            'ActiveObjectIdx',NaN);

        LastDirectory = pwd;

        % path to main code directory (path with OOPSv2.m)
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
        
        % colormaps settings
        Colormaps struct
        xColormaps struct
        ColormapsSettings struct
        
        % Azimuth display settings
        AzimuthDisplaySettings struct
        
        % ScatterPlot settings
        ScatterPlotSettings struct

        % SwarmPlot settings
        SwarmPlotSettings struct

        % PolarHistogram settings
        PolarHistogramSettings struct

        % variables for object plots (swarm and scatter plots for now)
        ObjectPlotVariables cell

        % variables for object polar plots
        ObjectPolarPlotVariables cell
        
        % object labeling
        ObjectLabels OOPSLabel
        
        % Fonts
        DefaultFont char
        DefaultPlotFont = 'Arial';
        
        % default px size (um/px)
        PixelSize = 0.1083;

        % type of mask to generate and use for object detection (Default, CustomScheme, or CustomUpload)
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
        ScatterPlotMarkerSize
        ScatterPlotColorMode
        ScatterPlotBackgroundColor
        ScatterPlotForegroundColor
        ScatterPlotLegendVisible

        % SwarmPlot settings
        SwarmPlotYVariable
        SwarmPlotGroupingType
        SwarmPlotColorMode
        SwarmPlotBackgroundColor
        SwarmPlotForegroundColor
        SwarmPlotErrorBarColor

        % new swarm plot settings
        SwarmPlotMarkerFaceAlpha
        SwarmPlotMarkerSize
        SwarmPlotErrorBarsVisible

        % PolarHistogram settings
        PolarHistogramnBins
        PolarHistogramWedgeFaceAlpha
        PolarHistogramCircleBackgroundColor
        PolarHistogramWedgeFaceColor
        PolarHistogramWedgeEdgeColor
        PolarHistogramWedgeLineWidth
        PolarHistogramWedgeLineColor
        PolarHistogramGridlinesColor
        PolarHistogramLabelsColor
        PolarHistogramCircleColor
        PolarHistogramGridlinesLineWidth
        PolarHistogramBackgroundColor
        PolarHistogramVariable

        % Object variables "long" names
        ObjectPlotVariablesLong

        ObjectPolarPlotVariablesLong

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
        function obj = OOPSSettings()
            % size of main monitor
            obj.ScreenSize = GetMaximizedScreenSize(1);
            % optimum font size
            obj.FontSize = max(ceil(obj.ScreenSize(4)*.01),11);
            % set up default object label (OOPSLabel object)
            obj.ObjectLabels(1) = OOPSLabel('Default',[1 1 0],obj);
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
                obj.MainPath = strjoin(CurrentPathSplit(1:end-3),'/');
            elseif ispc
                CurrentPathSplit = strsplit(mfilename("fullpath"),'\');
                obj.MainPath = strjoin(CurrentPathSplit(1:end-3),'\');
            end

            settingsFiles = {...
                'ObjectPlotVariables.mat',...
                'Colormaps.mat',...
                'ColormapsSettings.mat',...
                'ScatterPlotSettings.mat',...
                'SwarmPlotSettings.mat',...
                'AzimuthDisplaySettings.mat',...
                'PolarHistogramSettings.mat',...
                'ObjectPolarPlotVariables.mat'};

            obj.updateSettingsFromFiles(settingsFiles);

            try 
                obj.LoadCustomMaskSchemes();
            catch
                warning('Unable to load custom mask schemes...')
            end
            
        end

        % saveobj method
        function settings = saveobj(obj)

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
                SchemeFilesList = dir(fullfile([obj.MainPath,'/assets/segmentation_schemes'],'*.mat'));
            elseif ispc
                SchemeFilesList = dir(fullfile([obj.MainPath,'\assets\segmentation_schemes'],'*.mat'));
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
                BGColors = [0 0 0];
                LabelColor = distinguishable_colors(1,[obj.LabelColors;BGColors]);
            end

            if isempty(LabelName)
                LabelName = ['Untitled Label ',num2str(obj.nLabels+1)];
            end

            obj.ObjectLabels(end+1,1) = OOPSLabel(LabelName,LabelColor,obj);
        end

        function DeleteObjectLabel(obj,Label)
            Label2Delete = Label;
            LabelIdx = find(obj.ObjectLabels==Label2Delete);
            if LabelIdx == 1
                if obj.nLabels > 1
                    obj.ObjectLabels = obj.ObjectLabels(2:end);
                else
                    obj.ObjectLabels = OOPSLabel.empty();
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

        function ObjectPolarPlotVariablesLong = get.ObjectPolarPlotVariablesLong(obj)
            ObjectPolarPlotVariablesLong = cell(size(obj.ObjectPolarPlotVariables));
            for varIdx = 1:numel(obj.ObjectPolarPlotVariables)
                ObjectPolarPlotVariablesLong{varIdx} = ExpandVariableName(obj.ObjectPolarPlotVariables{varIdx});
            end
        end

        function IntensityColormap = get.IntensityColormap(obj)
            IntensityColormap = obj.ColormapsSettings.Intensity.Map;
        end

        function OrderFactorColormap = get.OrderFactorColormap(obj)
            OrderFactorColormap = obj.ColormapsSettings.OrderFactor.Map;
        end

        function ReferenceColormap = get.ReferenceColormap(obj)
            ReferenceColormap = obj.ColormapsSettings.Reference.Map;
        end

        function AzimuthColormap = get.AzimuthColormap(obj)
            AzimuthColormap = obj.ColormapsSettings.Azimuth.Map;
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

        function ScatterPlotMarkerSize = get.ScatterPlotMarkerSize(obj)
            ScatterPlotMarkerSize = obj.ScatterPlotSettings.MarkerSize;
        end

        function ScatterPlotColorMode = get.ScatterPlotColorMode(obj)
            ScatterPlotColorMode = obj.ScatterPlotSettings.ColorMode;
        end

        function ScatterPlotBackgroundColor = get.ScatterPlotBackgroundColor(obj)
            ScatterPlotBackgroundColor = obj.ScatterPlotSettings.BackgroundColor;
        end

        function ScatterPlotForegroundColor = get.ScatterPlotForegroundColor(obj)
            ScatterPlotForegroundColor = obj.ScatterPlotSettings.ForegroundColor;
        end

        function ScatterPlotLegendVisible = get.ScatterPlotLegendVisible(obj)
            ScatterPlotLegendVisible = obj.ScatterPlotSettings.LegendVisible;
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

        function SwarmPlotBackgroundColor = get.SwarmPlotBackgroundColor(obj)
            SwarmPlotBackgroundColor = obj.SwarmPlotSettings.BackgroundColor;
        end

        function SwarmPlotForegroundColor = get.SwarmPlotForegroundColor(obj)
            SwarmPlotForegroundColor = obj.SwarmPlotSettings.ForegroundColor;
        end

        function SwarmPlotErrorBarColor = get.SwarmPlotErrorBarColor(obj)
            SwarmPlotErrorBarColor = obj.SwarmPlotSettings.ErrorBarColor;
        end

        function SwarmPlotMarkerFaceAlpha = get.SwarmPlotMarkerFaceAlpha(obj)
            SwarmPlotMarkerFaceAlpha = obj.SwarmPlotSettings.MarkerFaceAlpha;
        end

        function SwarmPlotMarkerSize = get.SwarmPlotMarkerSize(obj)
            SwarmPlotMarkerSize = obj.SwarmPlotSettings.MarkerSize;
        end

        function SwarmPlotErrorBarsVisible = get.SwarmPlotErrorBarsVisible(obj)
            SwarmPlotErrorBarsVisible = obj.SwarmPlotSettings.ErrorBarsVisible;
        end

        function PolarHistogramnBins = get.PolarHistogramnBins(obj)
            PolarHistogramnBins = obj.PolarHistogramSettings.nBins;
        end

        function PolarHistogramWedgeFaceAlpha = get.PolarHistogramWedgeFaceAlpha(obj)
            PolarHistogramWedgeFaceAlpha = obj.PolarHistogramSettings.WedgeFaceAlpha;
        end

        function PolarHistogramCircleBackgroundColor = get.PolarHistogramCircleBackgroundColor(obj)
            PolarHistogramCircleBackgroundColor = obj.PolarHistogramSettings.CircleBackgroundColor;
        end

        function PolarHistogramWedgeFaceColor = get.PolarHistogramWedgeFaceColor(obj)
            PolarHistogramWedgeFaceColor = obj.PolarHistogramSettings.WedgeFaceColor;
        end

        function PolarHistogramWedgeEdgeColor = get.PolarHistogramWedgeEdgeColor(obj)
            PolarHistogramWedgeEdgeColor = obj.PolarHistogramSettings.WedgeEdgeColor;
        end

        function PolarHistogramWedgeLineWidth = get.PolarHistogramWedgeLineWidth(obj)
            PolarHistogramWedgeLineWidth = obj.PolarHistogramSettings.WedgeLineWidth;
        end

        function PolarHistogramWedgeLineColor = get.PolarHistogramWedgeLineColor(obj)
            PolarHistogramWedgeLineColor = obj.PolarHistogramSettings.WedgeLineColor;
        end

        function PolarHistogramGridlinesColor = get.PolarHistogramGridlinesColor(obj)
            PolarHistogramGridlinesColor = obj.PolarHistogramSettings.GridlinesColor;
        end

        function PolarHistogramLabelsColor = get.PolarHistogramLabelsColor(obj)
            PolarHistogramLabelsColor = obj.PolarHistogramSettings.LabelsColor;
        end

        function PolarHistogramCircleColor = get.PolarHistogramCircleColor(obj)
            PolarHistogramCircleColor = obj.PolarHistogramSettings.CircleColor;
        end

        function PolarHistogramGridlinesLineWidth = get.PolarHistogramGridlinesLineWidth(obj)
            PolarHistogramGridlinesLineWidth = obj.PolarHistogramSettings.GridlinesLineWidth;
        end

        function PolarHistogramBackgroundColor = get.PolarHistogramBackgroundColor(obj)
            PolarHistogramBackgroundColor = obj.PolarHistogramSettings.BackgroundColor;
        end

        function PolarHistogramVariable = get.PolarHistogramVariable(obj)
            PolarHistogramVariable = obj.PolarHistogramSettings.Variable;
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
            obj = OOPSSettings();

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

