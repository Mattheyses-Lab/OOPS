function hSwarmPlot = PlotSwarmChartByLabels(source,axH)

    PODSData = guidata(source);
    
    CurrentGroup = PODSData.CurrentGroup;
    
    nLabels = length(PODSData.Settings.ObjectLabels);
    
    axH.XTick = 1:1:nLabels;

    % use GUI foreground color as error bar color
    ErrorBarColor = PODSData.Settings.SwarmPlotErrorBarColor;

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
    hSwarmPlot = gobjects(nPlots,1);
    mean_marker = gobjects(nPlots,1);

    globalMax = 0;
    globalMin = 0;
    
    LabelIdxs = 1:1:nLabels;

    for i = 1:nPlots
        % Y data is just the vector of object values for selected variable
        Y{i} = rmmissing(LabelObjectData{i});
        % generate X data of the same size, multiply by the index of the current group
        X{i} = LabelIdxs(i)*ones(size(Y{i}));
        
        try
            % throw error if we have any NaNs
            if isempty(Y{i})
                error("Object data missing");
            end
            
            switch PODSData.Settings.SwarmPlotColorMode
                case 'Magnitude'
                    % color by value
                    hSwarmPlot(i) = swarmchart(axH,X{i},Y{i},Y{i},'Filled','HitTest','Off','MarkerEdgeColor',[0 0 0]);
                case 'ID'
                    % color by group (label)
                    hSwarmPlot(i) = swarmchart(axH,X{i},Y{i},'Filled',...
                        'HitTest','Off',...
                        'MarkerEdgeColor',[0 0 0],...
                        'MarkerFaceColor',PODSData.Settings.ObjectLabels(i).Color);
            end

            globalMax = max(globalMax,max(Y{i}));
            globalMin = min(globalMin,min(Y{i}));

            GroupMean = mean(Y{i});
            GroupStd = std(Y{i});
            % plot a horizontal line showing the group mean
            line(axH,[i-0.25 i+0.25],[GroupMean GroupMean],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
            % plot horizontal lines showing the mean +/- SD
            line(axH,[i-0.15 i+0.15],[GroupMean-GroupStd GroupMean-GroupStd],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
            line(axH,[i-0.15 i+0.15],[GroupMean+GroupStd GroupMean+GroupStd],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
            % plot a vertical line orthogonal to the three lines above
            line(axH,[i i],[GroupMean+GroupStd GroupMean-GroupStd],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');

            mean_marker(i) = plot(axH,i,GroupMean,'Marker','o','MarkerSize',10,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',ErrorBarColor);
            mean_marker(i).DataTipTemplate.DataTipRows(1) = dataTipTextRow("Mean",GroupMean);
            mean_marker(i).DataTipTemplate.DataTipRows(2) = dataTipTextRow("Standard Deviation",GroupStd);
            
        catch me
            switch me.message
                case "Object data missing"
                    UpdateLog3(source,['Warning: ',ExpandVariableName(Var2Get),' data missing or incomplete for objects with [Label:',PODSData.Settings.ObjectLabels(i).Name,'] in [Group:',CurrentGroup.GroupName,']'],'append');
                otherwise
                    UpdateLog3(source,['Warning: Unable to find objects with [Label:',PODSData.Settings.ObjectLabels(i).Name,'] in [Group:',CurrentGroup.GroupName,']'],'append');
            end
            

        end
        
    end

    axH.YTickMode = 'Auto';
    axH.YTickLabelMode = 'Auto';
    
    % set X limits to 0.5 below and above the max
    axH.XLim = [LabelIdxs(1)-1 nLabels+1];

    if globalMax > 1
        UpperLim = round(globalMax)+round(0.1*globalMax);
    else
        UpperLim = round(globalMax,1);
        if UpperLim < globalMax;UpperLim = UpperLim+0.1;end
    end

    if globalMin < 0
        LowerLim = (UpperLim)*(-1);
    else
        LowerLim = 0;
    end

    try
        axH.YLim = [LowerLim UpperLim];
        axH.CLim = axH.YLim;
    catch
        axH.YLim = [0 1];
        axH.CLim = [0 1];
    end

    % color the points according to magnitude using the currently selected Order factor colormap
    colormap(axH,PODSData.Settings.OrderFactorColormap);

end