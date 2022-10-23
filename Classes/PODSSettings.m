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
            'ZDist',0,...
            'OldXLim',[0 1],...
            'OldYLim',[0 1],...
            'OldZLim',[0 1],...
            'pct',0.5,...
            'ZoomLevels',[1/20 1/15 1/10 1/5 1/3 1/2 1/1.5 1/1.25 1],...
            'ZoomLevelIdx',6,...
            'OldWindowButtonMotionFcn','',...
            'OldImageButtonDownFcn','',...
            'Active',false,...
            'CurrentButton',gobjects(1,1),...
            'StaticAxes',gobjects(1,1),...
            'StaticImage',gobjects(1,1),...
            'DynamicAxes',gobjects(1,1),...
            'DynamicAxesParent',gobjects(1,1));
        
        InputFileType = '.nd2';

        LastDirectory = pwd;

        SummaryDisplayType = 'Project';
        
        % monitor tab switching
        CurrentTab = 'Files';
        PreviousTab = 'Files';
        
        % current image operation
        CurrentImageOperation = 'Mask Threshold';
        
        % size of the display (to set main window Position)
        ScreenSize
        
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

        % currently selected colormaps for each image type
        IntensityColormap double
        OrderFactorColormap double
        ReferenceColormap double
        
        % Azimuth display settings
        AzimuthDisplaySettings struct
        
        % ScatterPlot Settings
        ScatterPlotSettings struct

        % SwarmPlot Settings
        SwarmPlotSettings struct
        
        % Group Colors
        DefaultGroupColors cell

        % object labeling
        ObjectLabels PODSLabel
        
        % Fonts
        DefaultFont char
        
        % default px size (um/px)
        PixelSize = 0.1083;

        % type of mask to generate and use for object detection
        MaskType = 'Legacy';

        % object box type ('Box' or 'Boundary')
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
        ScatterPlotVariablesLong
        ScatterPlotVariablesShort

        % SwarmPlot settings
        SwarmPlotVariablesLong
        SwarmPlotVariablesShort
        SwarmPlotYVariable
        SwarmPlotGroupingType
        SwarmPlotColorMode

    end
    
    methods
        
        % constructor method
        function obj = PODSSettings()
            % size of main monitor
            obj.ScreenSize = GetMaximizedScreenSize(1);
            % set up default object label (PODSLabel object)
            obj.ObjectLabels(1) = PODSLabel('Default',[1 1 0],1);
            % get list of supported fonts
            FontList = listfonts();
            % check if 'Consolas' is in list of supported fonts
            if ismember('Consolas',FontList)
                obj.DefaultFont = 'Consolas';   % if so, make it default
            else
                obj.DefaultFont = 'Courier New';  % otherwise, use 'Courier New'
            end            

            try
                Colormaps_mat_file = load('Colormaps.mat');
                obj.Colormaps = Colormaps_mat_file.Colormaps;
                obj.IntensityColormap = obj.Colormaps.Turbo;
                obj.OrderFactorColormap = obj.Colormaps.OFMapNew;
                obj.ReferenceColormap = obj.Colormaps.Gray;
            catch
                warning('Unable to load "Colormaps.mat"...');
            end
            
            try
                obj.UpdateColormapsSettings();
            catch
                warning('Unable to load "ColormapsSettings.mat"...');
            end
            
            try
                obj.UpdateSwarmPlotSettings();
            catch
                warning('Unable to load "SwarmPlotSettings.mat"...');
            end
            
            try
                obj.UpdateAzimuthDisplaySettings();
            catch
                warning('Unable to load "AzimuthDisplaySettings.mat"...');
            end
            
            try
                obj.UpdateScatterPlotSettings();
            catch
                warning('Unable to load "ScatterPlotSettings.mat"...');
            end
            
            try
                load DefaultColors.mat DefaultColors
                fnames = fieldnames(DefaultColors);
                nColors = length(fnames);
                for i = 1:nColors
                    obj.DefaultGroupColors{i} = DefaultColors.(fnames{i});
                end
            catch
                warning('Unable to load "DefaultColors.mat"...')
            end
            
        end
        
        function UpdateColormapsSettings(obj)
            ColormapsSettings_mat_file = load('ColormapsSettings.mat');
            obj.ColormapsSettings = ColormapsSettings_mat_file.ColormapsSettings;
            obj.IntensityColormap = obj.ColormapsSettings.Intensity{3};
            obj.OrderFactorColormap = obj.ColormapsSettings.OrderFactor{3};
            obj.ReferenceColormap = obj.ColormapsSettings.Reference{3};
        end

        function UpdateSwarmPlotSettings(obj)
            SwarmPlotSettings_mat_file = load('SwarmPlotSettings.mat');
            obj.SwarmPlotSettings = SwarmPlotSettings_mat_file.SwarmPlotSettings;
        end
        
        function UpdateAzimuthDisplaySettings(obj)
            AzimuthSettings_mat_file = load('AzimuthDisplaySettings.mat');
            obj.AzimuthDisplaySettings = AzimuthSettings_mat_file.AzimuthDisplaySettings;
        end
        
        function UpdateScatterPlotSettings(obj)
            ScatterPlotSettings_mat_file = load('ScatterPlotSettings.mat');
            obj.ScatterPlotSettings = ScatterPlotSettings_mat_file.ScatterPlotSettings;
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

        function ScatterPlotVariablesLong = get.ScatterPlotVariablesLong(obj)
            ScatterPlotVariablesLong = obj.ScatterPlotSettings.VariablesLong;
        end

        function ScatterPlotVariablesShort = get.ScatterPlotVariablesShort(obj)
            ScatterPlotVariablesShort = obj.ScatterPlotSettings.VariablesShort;
        end

        function SwarmPlotVariablesLong = get.SwarmPlotVariablesLong(obj)
            SwarmPlotVariablesLong = obj.SwarmPlotSettings.VariablesLong;
        end

        function SwarmPlotVariablesShort = get.SwarmPlotVariablesShort(obj)
            SwarmPlotVariablesShort = obj.SwarmPlotSettings.VariablesShort;
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

    end
end

