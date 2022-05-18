classdef PODSSettings < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    % need to change to handle class
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
            'ZoomLevelIdx',4);
        
        InputFileType = '.nd2';
        
        MaskType = 'MakeNew';
        
        CurrentTab = 'Files';
        
        PreviousTab = 'Files';
        
        ScreenSize
        
        % sturcturing element for masking
        SEShape = 'disk';
        SESize = 3;
        SELines = 0;
        
        % for now, either 'One-Color' or 'Two-Color'
        ExperimentType = 'One-Color';
        % for now, from 1-2
        nChannels = 1;
        
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
        
    end
    methods
        function obj = PODSSettings()
            % get monitor positions
            %MonitorPosition = get(0,'MonitorPositions');
            % size of main monitor
            obj.ScreenSize = GetMaximizedScreenSize(0);
            %clear MonitorPosition
            obj.ObjectLabels(1) = PODSLabel('Default',[1 1 1],1);
            try
                colormaps_mat_file = load('Colormaps.mat');
                obj.AllColormaps = colormaps_mat_file.Colormaps;
                obj.IntensityColormaps{1} = obj.AllColormaps.Turbo;
                obj.IntensityColormaps{2} = obj.AllColormaps.Red;
                obj.OrderFactorColormap = obj.AllColormaps.OFMapNew;
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
                load('DefaultColors.mat')
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
            load('ColormapsSettings.mat')
            obj.IntensityColormaps{1} = ColormapsSettings.Intensity{3};
            obj.OrderFactorColormap = ColormapsSettings.OrderFactor{3};
            obj.ReferenceColormap = ColormapsSettings.Reference{3};
            clear ColormapsSettings
        end

        function UpdateSwarmChartSettings(obj)
            load('SwarmChartSettings.mat');
            obj.SwarmChartGroupingType = SwarmChartSettings.GroupingType;
            obj.SwarmChartYVariable = SwarmChartSettings.YVariable;
            obj.SwarmChartColorMode = SwarmChartSettings.ColorMode;
            clear SwarmChartSettings
        end
        
        function UpdateAzimuthDisplaySettings(obj)
            load('AzimuthDisplaySettings.mat');
            obj.AzimuthLineAlpha = AzimuthDisplaySettings.LineAlpha;
            obj.AzimuthLineWidth = AzimuthDisplaySettings.LineWidth;
            obj.AzimuthLineScale = AzimuthDisplaySettings.LineScale;
            obj.AzimuthScaleDownFactor = AzimuthDisplaySettings.ScaleDownFactor;
            clear AzimuthDisplaySettings
        end
        
        function UpdateScatterPlotSettings(obj)
            load('ScatterPlotSettings.mat');
            obj.ScatterPlotXVariable = ScatterPlotSettings.XVariable;
            obj.ScatterPlotYVariable = ScatterPlotSettings.YVariable;
            clear AzimuthDisplaySettings
        end        
    end
end

