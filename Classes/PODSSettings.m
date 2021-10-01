classdef PODSSettings
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
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
        
    end
    
    methods
        function obj = PODSSettings()
            % get monitor positions
            MonitorPosition = get(0,'MonitorPositions');
            % size of main monitor
            obj.ScreenSize = MonitorPosition(1,1:4);
            clear MonitorPosition
            
            try
                colormaps_mat_file = load('Colormaps.mat');
                obj.AllColormaps = colormaps_mat_file.Colormaps;
                obj.IntensityColormaps{1} = obj.AllColormaps.Green;
                obj.IntensityColormaps{2} = obj.AllColormaps.Red;
                obj.OrderFactorColormap = obj.AllColormaps.OFMap;
            catch
                warning('Unable to find file: Colormaps.mat, proceeding with default colors');
            end

        end
    end
end

