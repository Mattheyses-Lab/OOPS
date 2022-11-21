function hSwarmPlot = PlotSwarmChartByGroupAndLabels(source,axH)

    % get handle to PODSProject object, which is storing all the data
    PODSData = guidata(source);
    % determine how many unique labels we have
    nLabels = length(PODSData.Settings.ObjectLabels);
    % determine how many data groups we have
    nGroups = PODSData.nGroups;
    % calculate how many plots we need
    nPlots = nLabels*nGroups;
    % then set XTick accordingly
    axH.XTick = 1:1:nPlots;
    % use to track which plot we are working on (1:nPlots)
    PlotIdx = 1;
    % set x-axis labels for each plot
    for i = 1:nGroups
        for ii = 1:nLabels
            axH.XTickLabel{PlotIdx} = [PODSData.Group(i).GroupName,' (',PODSData.Settings.ObjectLabels(ii).Name,')'];
            PlotIdx = PlotIdx+1;
        end
    end
    % the variable we wish to plot, as indicated by user selection in SwarmPlot settings panel
    Var2Get = PODSData.Settings.SwarmPlotYVariable;
    % gather the data: cell array of Var2Get values, one row of cells per group, one column of cells per label
    LabelObjectData = PODSData.GetObjectDataByLabel(Var2Get);
    % cell arrays to hold X and Y data
    Y = cell(nPlots,1);
    X = cell(nPlots,1);
    % empty array to hold the swarm plots
    hSwarmPlot = [];
    % empty array to hold the max values in each group (to set axis limits later)
    MaxPerGroup = [];
    % return PlotIdx to 1
    PlotIdx = 1;

    for i = 1:nGroups
        
        for ii = 1:nLabels
            Y{PlotIdx} = LabelObjectData{i,ii};
            
            X{PlotIdx} = PlotIdx*ones(size(Y{PlotIdx}));
            
            try
                % throw error if we have any NaNs
                if any(isnan(Y{PlotIdx}))
                    error("Object data missing");
                end
                
                switch PODSData.Settings.SwarmPlotColorMode
                    case 'Magnitude'
                        % color by value
                        hSwarmPlot(PlotIdx) = swarmchart(axH,X{PlotIdx},Y{PlotIdx},150,Y{PlotIdx},'Filled','HitTest','Off','MarkerEdgeColor',[0 0 0]);
                    case 'ID'
                        % color by group (label)
                        hSwarmPlot(PlotIdx) = swarmchart(axH,X{PlotIdx},Y{PlotIdx},150,'Filled',...
                            'HitTest','Off',...
                            'MarkerEdgeColor',[0 0 0],...
                            'MarkerFaceColor',PODSData.Settings.ObjectLabels(ii).Color);
                end
                MaxPerGroup(PlotIdx) = max(Y{PlotIdx});
                hold on
            catch me
                switch me.message
                    case "Object data missing"
                        UpdateLog3(source,['ERROR: ',ExpandVariableName(Var2Get),' data missing or incomplete for objects with [Label:',PODSData.Settings.ObjectLabels(ii).Name,'] in [Group:',PODSData.Group(i).GroupName,']'],'append');
                        MaxPerGroup(i) = NaN;
                    otherwise
                        UpdateLog3(source,['ERROR: Unable to find objects with [Label:',PODSData.Settings.ObjectLabels(ii).Name,'] in [Group:',PODSData.Group(i).GroupName,']'],'append');
                        MaxPerGroup(i) = NaN;
                end
            end
            PlotIdx = PlotIdx+1;
        end
    end
    
    hold off

    axH.YTickMode = 'Auto';
    axH.YTickLabelMode = 'Auto';
    
    % set X limits to -1 below and +1 above the max
    axH.XLim = [0 nPlots+1];
    % find max across all groups/labels
    GlobalMax = max(MaxPerGroup);
    % use it to set the y-axis limits
    if GlobalMax > 1
        UpperLim = round(GlobalMax)+round(0.1*GlobalMax);
    else
        UpperLim = round(GlobalMax,1);
        if UpperLim < GlobalMax;UpperLim = UpperLim+0.1;end
    end
    
    try
        axH.YLim = [0 UpperLim];
        axH.CLim = axH.YLim;
    catch
        axH.YLim = [0 1];
        axH.CLim = [0 1];
    end
    
    % set the JitterWidth of each plot
    %[hSwarmPlot(:).XJitterWidth] = deal(0.5);

    % color the points according to magnitude using the currently selected Order factor colormap
    colormap(axH,PODSData.Settings.OrderFactorColormap);

end