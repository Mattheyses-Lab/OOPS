function hSwarmPlot = PlotSwarmChartByLabels(source,axH)

    PODSData = guidata(source);
    
    CurrentGroup = PODSData.CurrentGroup;
    
    nLabels = length(PODSData.Settings.ObjectLabels);
    
    axH.XTick = 1:1:nLabels;

    for ii = 1:nLabels
        axH.XTickLabel{ii} = [CurrentGroup.GroupName,' (',PODSData.Settings.ObjectLabels(ii).Name,')'];
    end

    Var2Get = PODSData.Settings.SwarmPlotYVariable;
    
    % cell array of Var2Get values, one cell per label
    LabelObjectData = CurrentGroup.GetObjectDataByLabel(Var2Get);

    % determine the number of plots (i.e. number of labels)
    nPlots = length(LabelObjectData);

    % cell arrays to hold X and Y data
    Y = cell(nPlots,1);
    X = cell(nPlots,1);

    % empty array to hold the swarm plots
    hSwarmPlot = [];
    MaxPerGroup = [];
    
    LabelIdxs = 1:1:nLabels;

    for i = 1:nPlots
        % Y data is just the vector of object values for selected variable
        Y{i} = LabelObjectData{i};
        % generate X data of the same size, multiply by the index of the current group
        X{i} = LabelIdxs(i)*ones(size(Y{i}));
        
        try
            % throw error if we have any NaNs
            if any(isnan(Y{i}))
                error();
            end
            
            switch PODSData.Settings.SwarmPlotColorMode
                case 'Magnitude'
                % color by value
                hSwarmPlot(i) = swarmchart(axH,X{i},Y{i},150,Y{i},'Filled','HitTest','Off','MarkerEdgeColor',[0 0 0]);
                case 'ID'
                % color by group (label)
                hSwarmPlot(i) = swarmchart(axH,X{i},Y{i},150,'Filled',...
                    'HitTest','Off',...
                    'MarkerEdgeColor',[0 0 0],...
                    'MarkerFaceColor',PODSData.Settings.ObjectLabels(i).Color);
            end
        
            MaxPerGroup(i) = max(Y{i});
            hold on
        catch
            UpdateLog3(source,['ERROR: Unable to find objects with [Label:',PODSData.Settings.ObjectLabels(i).Name,'] in [Group:',CurrentGroup.GroupName,']'],'append');
            MaxPerGroup(i) = NaN;
        end
        
    end

    hold off

    axH.YTickMode = 'Auto';
    axH.YTickLabelMode = 'Auto';
    %axH.Color = 'Black';
    
    % set X limits to 0.5 below and above the max
    axH.XLim = [LabelIdxs(1)-1 nLabels+1];

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