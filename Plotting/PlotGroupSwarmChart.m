function hSwarmPlot = PlotGroupSwarmChart(source,axH)

% get the GUI data structure
PODSData = guidata(source);
% use GUI foreground color as error bar color
ErrorBarColor = PODSData.Settings.SwarmPlotErrorBarColor;
% determine the number of plots
nPlots = PODSData.nGroups;
% set axis ticks, one for each group, even those that won't be plotted
axH.XTick = 1:1:PODSData.nGroups;
% set x-axis label for each group
for i = 1:nPlots
    axH.XTickLabel{i} = PODSData.Group(i).GroupName;
end
% cell array to hold vectors of objectOF for each group
GroupObjectData = cell(1,nPlots);

Var2Plot = PODSData.Settings.SwarmPlotYVariable;

% get the data for each group
for i = 1:nPlots
    % could change 'OFAvg' to a variable for more control over plotting
    GroupObjectData{i} = GetAllObjectData(PODSData.Group(i),Var2Plot);
end

% cell arrays to hold X and Y data
Y = cell(nPlots,1);
X = cell(nPlots,1);

globalMax = 0;
globalMin = 0;

% initialize swarmchart array
hSwarmPlot = gobjects(nPlots,1);
mean_marker = gobjects(nPlots,1);

for i = 1:nPlots
    % Y data is just the vector of object values for selected variable
    Y{i} = rmmissing(GroupObjectData{i});
    % generate X data of the same size, multiply by the index of the current group
    X{i} = i*ones(size(Y{i}));
    
    try
        if isempty(Y{i})
            error("Object data missing");
        end

        switch PODSData.Settings.SwarmPlotColorMode
            case 'Magnitude'
                % color by value
                hSwarmPlot(i) = swarmchart(axH,X{i},Y{i},[],Y{i},'Filled',...
                    'HitTest','Off',...
                    'MarkerEdgeColor',[0 0 0]);
            case 'ID'
                % color by group (label)
                hSwarmPlot(i) = swarmchart(axH,X{i},Y{i},'Filled',...
                    'MarkerFaceColor',PODSData.Group(i).Color,...
                    'HitTest','Off',...
                    'MarkerEdgeColor',[0 0 0]);
        end

        globalMax = max(globalMax,max(Y{i}));
        globalMin = min(globalMin,min(Y{i}));
        %hold on
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
                UpdateLog3(source,['Warning: ',ExpandVariableName(Var2Plot),' data missing or incomplete for objects in [Group:',PODSData.Group(i).GroupName,']'],'append');
            otherwise
                UpdateLog3(source,['Warning: Unable to find objects in [Group:',PODSData.Group(i).GroupName,']'],'append');
        end
    end
end

axH.YTickMode = 'Auto';
axH.YTickLabelMode = 'Auto';

% set X limits to 1 below and above the max
axH.XLim = [0 PODSData.nGroups+1];

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
    axH.CLim = axH.YLim;
end

% color the points according to magnitude using the currently selected Order factor colormap
colormap(axH,PODSData.Settings.OrderFactorColormap);

end