function saveSettings(source,~)

    % the main data structure
    OOPSData = guidata(source);

    % get path settings directory
    if ismac || isunix
        settingsPath = [OOPSData.Settings.MainPath,'/user_settings/'];
    elseif ispc
        settingsPath = [OOPSData.Settings.MainPath,'\user_settings\'];
    end

    % base name of the different settings files (no extension)
    settingsFiles = {...
        'ColormapsSettings',...
        'PalettesSettings',...
        'ScatterPlotSettings',...
        'SwarmPlotSettings',...
        'AzimuthDisplaySettings',...
        'PolarHistogramSettings',...
        'ObjectIntensityProfileSettings',...
        'ObjectAzimuthDisplaySettings',...
        'ObjectSelectionSettings',...
        'ClusterSettings',...
        'MaskSettings',...
        'GUISettings'};

    % update log
    UpdateLog3(source,'Saving settings...','append');

    % save each settings struct to a separate MAT-file
    for i = 1:numel(settingsFiles)
        settingsName = settingsFiles{i};
        tempStruct.(settingsName) = OOPSData.Settings.(settingsName);
        save([settingsPath,settingsName,'.mat'],'-struct','tempStruct');
        clear tempStruct
    end
    
    % update log to indicate completion
    UpdateLog3(source,'Done.','append');

end