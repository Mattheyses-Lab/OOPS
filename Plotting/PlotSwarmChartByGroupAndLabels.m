function hSwarmPlot = PlotSwarmChartByGroupAndLabels(source,axH)

% get handle to PODSProject object, which is storing all the data
PODSData = guidata(source);
% determine how many unique labels we have
nLabels = length(PODSData.Settings.ObjectLabels);
% determine how many data groups we have
nGroups = PODSData.nGroups;
% calculate how many plots we need (number of labels * number of groups)
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

%% collecting the data to plot and variables for the plot marker data tips

% the variable we wish to plot, as indicated by user selection in SwarmPlot settings panel
Var2Plot = PODSData.Settings.SwarmPlotYVariable;
% gather the data: cell array of Var2Get values, one row of cells per group, one column of cells per label
LabelObjectData = PODSData.GetObjectDataByLabel(Var2Plot);
% get object SelfIdxs for data tips
LabelObjectSelfIdxs = PODSData.GetObjectDataByLabel('SelfIdx');
% get object GroupName for data tips
LabelObjectGroupNames = PODSData.GetObjectDataByLabel('GroupName');
% get object ImageName for data tips
LabelObjectImageNames = PODSData.GetObjectDataByLabel('InterpreterFriendlyImageName');
% get object LabelName for data tips
LabelObjectLabelNames = PODSData.GetObjectDataByLabel('LabelName');

%% setup some variables before making the plots

% cell arrays to hold X and Y data for each plot
Y = cell(nPlots,1);
X = cell(nPlots,1);

% initialize swarmchart array
hSwarmPlot = gobjects(nPlots,1);
mean_marker = gobjects(nPlots,1);

% return PlotIdx to 1
PlotIdx = 1;

% max and min values among all groups
globalMax = [];
globalMin = [];

%% draw a swarm plot for each label of each group
% for each group
for i = 1:nGroups
    % for each object label in group
    for ii = 1:nLabels
        % get the data vector to plot for this group, remove missing values, track which were removed (TF)
        [Y{PlotIdx},TF] = rmmissing(LabelObjectData{i,ii});
        % the number of objects for which Var2Plot data was missing
        nRemoved = numel(find(TF));
        % adjust data tip variables to account for any data removed above
        LabelObjectSelfIdxs{i,ii} = LabelObjectSelfIdxs{i,ii}(~TF);
        LabelObjectGroupNames{i,ii} = LabelObjectGroupNames{i,ii}(~TF);
        LabelObjectImageNames{i,ii} = LabelObjectImageNames{i,ii}(~TF);
        LabelObjectLabelNames{i,ii} = LabelObjectLabelNames{i,ii}(~TF);
        % generate X data of the same size, multiply by the index of the current group
        X{PlotIdx} = PlotIdx*ones(size(Y{PlotIdx}));
        % try and draw the plot, catch errors
        try
            if isempty(Y{PlotIdx})
                % if data missing for all objects, throw error
                error("Object data missing");
            elseif nRemoved > 0
                % if data were missing some (but not all) objects, warn the user by sending an update to the log window
                UpdateLog3(source,['Warning: ',...
                    ExpandVariableName(Var2Plot),...
                    ' data missing for ',...
                    num2str(nRemoved),...
                    ' objects with [Label:',...
                    PODSData.Settings.ObjectLabels(ii).Name,...
                    '] in [Group:',...
                    PODSData.Group(i).GroupName,...
                    ']'],...
                    'append');
            end
            % build swarm chart based on selected color mode
            switch PODSData.Settings.SwarmPlotColorMode
                case 'Magnitude'
                    % color by value
                    hSwarmPlot(PlotIdx) = swarmchart(...
                        axH,...
                        X{PlotIdx},Y{PlotIdx},...
                        Y{PlotIdx},...
                        'Filled',...
                        'HitTest','Off',...
                        'MarkerEdgeColor',[0 0 0]);
                case 'ID'
                    % color by group (label)
                    hSwarmPlot(PlotIdx) = swarmchart(...
                        axH,...
                        X{PlotIdx},Y{PlotIdx},...
                        'Filled',...
                        'HitTest','Off',...
                        'MarkerEdgeColor',[0 0 0],...
                        'MarkerFaceColor',PODSData.Settings.ObjectLabels(ii).Color);
            end
            % build data tips for each plot marker of the swarm chart
            hSwarmPlot(PlotIdx).DataTipTemplate.DataTipRows(1) = dataTipTextRow("Group",categorical(LabelObjectGroupNames{i,ii}));
            hSwarmPlot(PlotIdx).DataTipTemplate.DataTipRows(2) = dataTipTextRow("Image",categorical(LabelObjectImageNames{i,ii}));
            hSwarmPlot(PlotIdx).DataTipTemplate.DataTipRows(3) = dataTipTextRow("Object",LabelObjectSelfIdxs{i,ii});
            hSwarmPlot(PlotIdx).DataTipTemplate.DataTipRows(4) = dataTipTextRow("Label",categorical(LabelObjectLabelNames{i,ii}));
            hSwarmPlot(PlotIdx).DataTipTemplate.DataTipRows(5) = dataTipTextRow(ExpandVariableName(Var2Plot),Y{PlotIdx});
            hSwarmPlot(PlotIdx).HitTest = 'On';
            % get the mean, std, and n of this group
            GroupMean = mean(Y{PlotIdx});
            GroupStd = std(Y{PlotIdx});
            Groupn = numel(Y{PlotIdx});
            GroupMin = min(Y{PlotIdx});
            GroupMax = max(Y{PlotIdx});
            % get the maximum value among all groups
            if isempty(globalMax)
                globalMax = GroupMax;
            else
                globalMax = max(globalMax,GroupMax);
            end
            % get the minimum value among all groups
            if isempty(globalMin)
                globalMin = GroupMin;
            else
                globalMin = min(globalMin,GroupMin);
            end
            % plot a horizontal line showing the group mean
            line(axH,[PlotIdx-0.25 PlotIdx+0.25],[GroupMean GroupMean],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
            % plot horizontal lines showing the mean +/- SD
            line(axH,[PlotIdx-0.15 PlotIdx+0.15],[GroupMean-GroupStd GroupMean-GroupStd],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
            line(axH,[PlotIdx-0.15 PlotIdx+0.15],[GroupMean+GroupStd GroupMean+GroupStd],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
            % plot a vertical line orthogonal to the three lines above
            line(axH,[PlotIdx PlotIdx],[GroupMean+GroupStd GroupMean-GroupStd],'LineStyle','-','LineWidth',3,'HitTest','Off','Color',ErrorBarColor,'PickableParts','none');
            % plot a point at the group mean
            mean_marker(PlotIdx) = plot(axH,PlotIdx,GroupMean,'Marker','o','MarkerSize',10,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',ErrorBarColor);
            % add custom data tip rows
            mean_marker(PlotIdx).DataTipTemplate.DataTipRows(1) = dataTipTextRow("Group",categorical(axH.XTickLabel(PlotIdx)));
            mean_marker(PlotIdx).DataTipTemplate.DataTipRows(2) = dataTipTextRow("n",Groupn);
            mean_marker(PlotIdx).DataTipTemplate.DataTipRows(3) = dataTipTextRow("Mean",GroupMean);
            mean_marker(PlotIdx).DataTipTemplate.DataTipRows(4) = dataTipTextRow("Standard Deviation",GroupStd);
            mean_marker(PlotIdx).DataTipTemplate.DataTipRows(5) = dataTipTextRow("Max",GroupMax);
            mean_marker(PlotIdx).DataTipTemplate.DataTipRows(6) = dataTipTextRow("Min",GroupMin);
        catch me
            switch me.message
                case "Object data missing"
                    UpdateLog3(source,['Warning: [',ExpandVariableName(Var2Plot),'] data missing for objects with [Label:',PODSData.Settings.ObjectLabels(ii).Name,'] in [Group:',PODSData.Group(i).GroupName,']'],'append');
                otherwise
                    UpdateLog3(source,['Warning: ',me.message],'append');
            end
        end
        PlotIdx = PlotIdx+1;
    end
end

axH.YTickMode = 'Auto';
axH.YTickLabelMode = 'Auto';

axH.YLimMode = 'Auto';
axH.CLim = axH.YLim;

% set X limits to 1 below and above the number of plots
axH.XLim = [0 nPlots+1];

% color the points according to magnitude using the currently selected Order factor colormap
colormap(axH,PODSData.Settings.OrderFactorColormap);

end