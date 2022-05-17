function hSwarmPlot = PlotGroupSwarmChart(source,axH)

% get the GUI data structure
PODSData = guidata(source);

% array to hold the group idxs where selected variable has been determined
GoodGroups = [];

% get the index of the current channel
cChannelIdx = PODSData.CurrentChannelIndex;
% only plot groups if order factor is calculated

% set axis ticks, one for each group, even those that won't be plotted
axH.XTick = [1:1:PODSData.nGroups];

%% Check which groups have OFAllDone true, get the object OF, add to plot
for i = 1:PODSData.nGroups
    if PODSData.Group(i,cChannelIdx).OFAllDone
        GoodGroups(end+1) = i;
    end
    axH.XTickLabel{i} = PODSData.Group(i,cChannelIdx).GroupName;
end

% cell array to hold vectors of objectOF for each group
GroupObjectData = cell(1,length(GoodGroups));

Var2Plot = PODSData.Settings.SwarmChartYVariable;

% get the data for each group
for i = 1:length(GoodGroups)
    % could change 'OFAvg' to a variable for more control over plotting
    GroupObjectData{i} = GetAllObjectData(PODSData.Group(GoodGroups(i),cChannelIdx),Var2Plot);
end

% determine the number of plots
nPlots = length(GoodGroups);

% cell arrays to hold X and Y data
Y = cell(nPlots,1);
X = cell(nPlots,1);

% empty array to hold the swarm plots
%hSwarmPlot = [];

% maximum value in each group
MaxPerGroup = [];

for i = 1:nPlots
    % Y data is just the vector of object values for selected variable
    Y{i} = GroupObjectData{i};
    % generate X data of the same size, multiply by the index of the current group
    X{i} = GoodGroups(i)*ones(size(Y{i}));
    
    switch PODSData.Settings.SwarmChartColorMode
        case 'Magnitude'
            % color by value
            hSwarmPlot(i) = swarmchart(axH,X{i},Y{i},150,Y{i},'Filled','HitTest','Off','MarkerEdgeColor',[0 0 0]);
        case 'ID'
            % color by group (label)
            hSwarmPlot(i) = swarmchart(axH,X{i},Y{i},150,'Filled',...
                'MarkerFaceColor',PODSData.Group(i).Color,...
                'HitTest','Off',...
                'MarkerEdgeColor',[0 0 0]);
    end
    
    MaxPerGroup(i) = max(Y{i});
    
    hold on
end

hold off

axH.YTickMode = 'Auto';
axH.YTickLabelMode = 'Auto';

% set X limits to 0.5 below and above the max
axH.XLim = [GoodGroups(1)-1 PODSData.nGroups+1];

GlobalMax = max(MaxPerGroup);

if GlobalMax > 1
    UpperLim = round(GlobalMax)+round(0.1*GlobalMax);
else
    UpperLim = round(GlobalMax,1);
    if UpperLim < GlobalMax;UpperLim = UpperLim+0.1;end
end

axH.YLim = [0 UpperLim];

axH.CLim = axH.YLim;

% set the JitterWidth of each plot
[hSwarmPlot(:).XJitterWidth] = deal(0.5);

% color the points according to magnitude using the currently selected Order factor colormap
colormap(axH,PODSData.Settings.OrderFactorColormap);

end