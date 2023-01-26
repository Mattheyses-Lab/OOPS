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
    % use GUI foreground color as error bar color
    ErrorBarColor = PODSData.Settings.SwarmPlotErrorBarColor;
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
    % initialize swarmchart array
    hSwarmPlot = gobjects(nPlots,1);
    mean_marker = gobjects(nPlots,1);
    % return PlotIdx to 1
    PlotIdx = 1;

    globalMax = 0;
    globalMin = 0;

    for i = 1:nGroups
        
        for ii = 1:nLabels

            Y{PlotIdx} = rmmissing(LabelObjectData{i,ii});
            
            X{PlotIdx} = PlotIdx*ones(size(Y{PlotIdx}));
            
            try
                % throw error if we have any NaNs
                if isempty(Y{PlotIdx})
                    error("Object data missing");
                end
                
                switch PODSData.Settings.SwarmPlotColorMode
                    case 'Magnitude'
                        % color by value
                        hSwarmPlot(PlotIdx) = swarmchart(axH,X{PlotIdx},Y{PlotIdx},Y{PlotIdx},'Filled','HitTest','Off','MarkerEdgeColor',[0 0 0]);
                    case 'ID'
                        % color by group (label)
                        hSwarmPlot(PlotIdx) = swarmchart(axH,X{PlotIdx},Y{PlotIdx},'Filled',...
                            'HitTest','Off',...
                            'MarkerEdgeColor',[0 0 0],...
                            'MarkerFaceColor',PODSData.Settings.ObjectLabels(ii).Color);
                end
                
                globalMax = max(globalMax,max(Y{PlotIdx}));
                globalMin = min(globalMin,min(Y{PlotIdx}));

                GroupMean = mean(Y{PlotIdx});
                GroupStd = std(Y{PlotIdx});
                % plot a horizontal line showing the group mean
                line(axH,[PlotIdx-0.25 PlotIdx+0.25],[GroupMean GroupMean],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
                % plot horizontal lines showing the mean +/- SD
                line(axH,[PlotIdx-0.15 PlotIdx+0.15],[GroupMean-GroupStd GroupMean-GroupStd],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
                line(axH,[PlotIdx-0.15 PlotIdx+0.15],[GroupMean+GroupStd GroupMean+GroupStd],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
                % plot a vertical line orthogonal to the three lines above
                line(axH,[PlotIdx PlotIdx],[GroupMean+GroupStd GroupMean-GroupStd],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');

                mean_marker(PlotIdx) = plot(axH,PlotIdx,GroupMean,'Marker','o','MarkerSize',10,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',ErrorBarColor);
                mean_marker(PlotIdx).DataTipTemplate.DataTipRows(1) = dataTipTextRow("Mean",GroupMean);
                mean_marker(PlotIdx).DataTipTemplate.DataTipRows(2) = dataTipTextRow("Standard Deviation",GroupStd);
            catch me
                switch me.message
                    case "Object data missing"
                        UpdateLog3(source,['ERROR: ',ExpandVariableName(Var2Get),' data missing or incomplete for objects with [Label:',PODSData.Settings.ObjectLabels(ii).Name,'] in [Group:',PODSData.Group(i).GroupName,']'],'append');
                    otherwise
                        UpdateLog3(source,['ERROR: Unable to find objects with [Label:',PODSData.Settings.ObjectLabels(ii).Name,'] in [Group:',PODSData.Group(i).GroupName,']'],'append');
                end
            end
            PlotIdx = PlotIdx+1;
        end
    end

    axH.YTickMode = 'Auto';
    axH.YTickLabelMode = 'Auto';
    
    % set X limits to -1 below and +1 above the max
    axH.XLim = [0 nPlots+1];

    % use it to set the y-axis limits
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
    
    % set the JitterWidth of each plot
    %[hSwarmPlot(:).XJitterWidth] = deal(0.5);

    % color the points according to magnitude using the currently selected Order factor colormap
    colormap(axH,PODSData.Settings.OrderFactorColormap);

end