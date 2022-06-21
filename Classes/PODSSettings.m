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
            'ZoomLevels',[1/10 1/5 1/3 1/2 1/1.5 1/1.25 1],...
            'ZoomLevelIdx',4,...
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
        
        MaskType = 'MakeNew';
        
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
        % struct of all colormaps
        AllColormaps struct
        % currently selected colormaps for each image type
        IntensityColormaps cell
        OrderFactorColormap double
        ReferenceColormap double
        
        % Azimuth display settings
        AzimuthLineAlpha = 0.5;
        AzimuthLineWidth = 1;
        AzimuthLineScale = 100;
        AzimuthScaleDownFactor = 1;
        AzimuthColorMode = 'Direction';
        
        % SwarmChart settings
        % how to group the data, by group, by custom label, or both
        SwarmChartGroupingType = 'Label';
        % y-axis variable to plot
        SwarmChartYVariable = 'OFAvg';
        % ID or Magnitude
        SwarmChartColorMode = 'ID';
        
        % ScatterPlot Settings
        ScatterPlotXVariable = 'SBRatio';
        ScatterPlotYVariable = 'OFAvg';
        
        % Group Colors
        DefaultGroupColors cell

        % object labeling
        ObjectLabels PODSLabel
        
        % Fonts
        DefaultFont char
        
        % px size (um/px)
        PixelSize = 0.1083;
        
    end
    
    methods
        
        % constructor method
        function obj = PODSSettings()
            % size of main monitor
            obj.ScreenSize = GetMaximizedScreenSize(1);
            % set up default object label (PODSLabel object)
            obj.ObjectLabels(1) = PODSLabel('Default',[1 1 1],1);
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
                obj.IntensityColormaps{1} = obj.Colormaps.Turbo;
                obj.IntensityColormaps{2} = obj.Colormaps.Red;
                obj.OrderFactorColormap = obj.Colormaps.OFMapNew;
            catch
                warning('Unable to load "Colormaps.mat"...');
            end
            
            try
                obj.UpdateColormapsSettings();
            catch
                warning('Unable to load "ColormapsSettings.mat"...');
            end
            
            try
                obj.UpdateSwarmChartSettings();
            catch
                warning('Unable to load "SwarmChartSettings.mat"...');
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
            obj.IntensityColormaps{1} = obj.ColormapsSettings.Intensity{3};
            obj.OrderFactorColormap = obj.ColormapsSettings.OrderFactor{3};
            obj.ReferenceColormap = obj.ColormapsSettings.Reference{3};
        end

        function UpdateSwarmChartSettings(obj)
            load SwarmChartSettings.mat SwarmChartSettings
            obj.SwarmChartGroupingType = SwarmChartSettings.GroupingType;
            obj.SwarmChartYVariable = SwarmChartSettings.YVariable;
            obj.SwarmChartColorMode = SwarmChartSettings.ColorMode;
            clear SwarmChartSettings
        end
        
        function UpdateAzimuthDisplaySettings(obj)
            load AzimuthDisplaySettings.mat AzimuthDisplaySettings
            obj.AzimuthLineAlpha = AzimuthDisplaySettings.LineAlpha;
            obj.AzimuthLineWidth = AzimuthDisplaySettings.LineWidth;
            obj.AzimuthLineScale = AzimuthDisplaySettings.LineScale;
            obj.AzimuthScaleDownFactor = AzimuthDisplaySettings.ScaleDownFactor;
            obj.AzimuthColorMode = AzimuthDisplaySettings.ColorMode;
            clear AzimuthDisplaySettings
        end
        
        function UpdateScatterPlotSettings(obj)
            load ScatterPlotSettings.mat ScatterPlotSettings
            obj.ScatterPlotXVariable = ScatterPlotSettings.XVariable;
            obj.ScatterPlotYVariable = ScatterPlotSettings.YVariable;
            clear AzimuthDisplaySettings
        end        
    end
end

