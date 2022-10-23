function hSwarmPlot = PlotSwarmChartByGroupAndLabels(source,axH)

    PODSData = guidata(source);
    
    nLabels = length(PODSData.Settings.ObjectLabels);
    
    nGroups = PODSData.nGroups;
    
    nPlots = nLabels*nGroups;
    
    axH.XTick = 1:1:nPlots;

    PlotIdx = 1;
    
    for i = 1:nGroups
        for ii = 1:nLabels
            axH.XTickLabel{PlotIdx} = [PODSData.Group(i).GroupName,' (',PODSData.Settings.ObjectLabels(ii).Name,')'];
            PlotIdx = PlotIdx+1;
        end
    end

    Var2Get = PODSData.Settings.SwarmPlotYVariable;
    
    % cell array of Var2Get values, one row of cells per group, one column of cells per label
    LabelObjectData = PODSData.GetObjectDataByLabel(Var2Get);

    % cell arrays to hold X and Y data
    Y = cell(nPlots,1);
    X = cell(nPlots,1);

    % empty array to hold the swarm plots
    hSwarmPlot = [];
    MaxPerGroup = [];
    
    PlotIdx = 1;

    for i = 1:nGroups
        
        for ii = 1:nLabels
            Y{PlotIdx} = LabelObjectData{i,ii};
            
            X{PlotIdx} = PlotIdx*ones(size(Y{PlotIdx}));
            
            try
                % throw error if we have any NaNs
                if any(isnan(Y{PlotIdx}))
                    error();
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
            catch
                UpdateLog3(source,['ERROR: Unable to find objects with [Label:',PODSData.Settings.ObjectLabels(ii).Name,'] in [Group:',PODSData.Group(i).GroupName,']'],'append');
                MaxPerGroup(PlotIdx) = NaN;                
            end
            PlotIdx = PlotIdx+1;
        end
    end
    
    hold off

    axH.YTickMode = 'Auto';
    axH.YTickLabelMode = 'Auto';
    
    % set X limits to -1 below and +1 above the max
    axH.XLim = [0 nPlots+1];

    GlobalMax = max(MaxPerGroup);

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