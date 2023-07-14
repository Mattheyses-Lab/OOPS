function hSwarmPlot = PlotSwarmChartByGroupAndLabels(source,axH)

% get the main project data structure
OOPSData = guidata(source);

% determine how many data groups we have
nGroups = OOPSData.nGroups;
% if no groups exist, return empty graphics placeholder
if nGroups == 0
    hSwarmPlot = gobjects().empty();
    return
end

% hide the axes until we are done plotting
axH.Visible = 'off';

% get settings for the swarm plot
ErrorBarColor = OOPSData.Settings.SwarmPlotErrorBarColor;
ErrorBarsVisible = OOPSData.Settings.SwarmPlotErrorBarsVisible;
MarkerSize = OOPSData.Settings.SwarmPlotMarkerSize;
MarkerFaceAlpha = OOPSData.Settings.SwarmPlotMarkerFaceAlpha;

% determine how many unique labels we have
nLabels = length(OOPSData.Settings.ObjectLabels);
% calculate how many plots we need (number of labels * number of groups)
nPlots = nLabels*nGroups;
% then set XTick accordingly
axH.XTick = 1:1:nPlots;
% use to track which plot we are working on (1:nPlots)
PlotIdx = 1;
% set x-axis labels for each plot
for i = 1:nGroups
    for ii = 1:nLabels
        axH.XTickLabel{PlotIdx} = [OOPSData.Group(i).GroupName,' (',OOPSData.Settings.ObjectLabels(ii).Name,')'];
        PlotIdx = PlotIdx+1;
    end
end

% set X limits to 1 below and above the number of plots
axH.XLim = [0 nPlots+1];

%% collecting the data to plot and variables for the plot marker data tips

% the variable we wish to plot, as indicated by user selection in SwarmPlot settings panel
Var2Plot = OOPSData.Settings.SwarmPlotYVariable;
% gather the data: cell array of Var2Get values, one row of cells per group, one column of cells per label
LabelObjectData = OOPSData.GetObjectDataByLabel(Var2Plot);
% get object SelfIdxs for data tips
LabelObjectSelfIdxs = OOPSData.GetObjectDataByLabel('SelfIdx');
% get object GroupName for data tips
LabelObjectGroupNames = OOPSData.GetObjectDataByLabel('GroupName');
% get object ImageName for data tips
LabelObjectImageNames = OOPSData.GetObjectDataByLabel('InterpreterFriendlyImageName');
% get object LabelName for data tips
LabelObjectLabelNames = OOPSData.GetObjectDataByLabel('LabelName');
% get object GroupIdx for plot colors
LabelObjectGroupIdx = OOPSData.GetObjectDataByLabel('GroupIdx');

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
        LabelObjectGroupIdx{i,ii} = LabelObjectGroupIdx{i,ii}(~TF);
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
                    OOPSData.Settings.ObjectLabels(ii).Name,...
                    '] in [Group:',...
                    OOPSData.Group(i).GroupName,...
                    ']'],...
                    'append');
            end
            % build swarm chart based on selected color mode
            switch OOPSData.Settings.SwarmPlotColorMode
                case 'Magnitude'
                    % color by value
                    hSwarmPlot(PlotIdx) = swarmchart(...
                        axH,...
                        X{PlotIdx},Y{PlotIdx},...
                        'Filled',...
                        'MarkerFaceColor','flat',...
                        'CData',Y{PlotIdx}',...
                        'MarkerEdgeColor',[0 0 0],...
                        'MarkerFaceAlpha',MarkerFaceAlpha,...
                        'SizeData',MarkerSize,...                   
                        'HitTest','off',...
                        'Visible','off');
                case 'Label'
                    % color by label
                    hSwarmPlot(PlotIdx) = swarmchart(...
                        axH,...
                        X{PlotIdx},Y{PlotIdx},...
                        'Filled',...
                        'MarkerFaceColor',OOPSData.Settings.ObjectLabels(ii).Color,...
                        'MarkerEdgeColor',[0 0 0],...
                        'MarkerFaceAlpha',MarkerFaceAlpha,...
                        'SizeData',MarkerSize,...
                        'HitTest','off',...
                        'Visible','off');
                case 'Group'
                    % color by group
                    hSwarmPlot(PlotIdx) = swarmchart(...
                        axH,...
                        X{PlotIdx},Y{PlotIdx},...
                        'Filled',...
                        'MarkerFaceColor','flat',...
                        'CData',LabelObjectGroupIdx{i,ii}',...
                        'MarkerEdgeColor',[0 0 0],...
                        'MarkerFaceAlpha',MarkerFaceAlpha,...
                        'SizeData',MarkerSize,...
                        'HitTest','off',...
                        'Visible','off');
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
            if ErrorBarsVisible
                % plot a horizontal line showing the group mean
                line(axH,[PlotIdx-0.25 PlotIdx+0.25],[GroupMean GroupMean],...
                    'LineStyle','-',...
                    'LineWidth',3,...
                    'HitTest','Off',...
                    'Color',ErrorBarColor,...
                    'PickableParts','none',...
                    'Visible','off');
                % plot horizontal lines showing the mean +/- SD
                line(axH,[PlotIdx-0.15 PlotIdx+0.15],[GroupMean-GroupStd GroupMean-GroupStd],...
                    'LineStyle','-',...
                    'LineWidth',3,...
                    'HitTest','Off',...
                    'Color',ErrorBarColor,...
                    'PickableParts','none',...
                    'Visible','off');
                line(axH,[PlotIdx-0.15 PlotIdx+0.15],[GroupMean+GroupStd GroupMean+GroupStd],...
                    'LineStyle','-',...
                    'LineWidth',3,...
                    'HitTest','Off',...
                    'Color',ErrorBarColor,...
                    'PickableParts','none',...
                    'Visible','off');
                % plot a vertical line orthogonal to the three lines above
                line(axH,[PlotIdx PlotIdx],[GroupMean+GroupStd GroupMean-GroupStd],...
                    'LineStyle','-',...
                    'LineWidth',3,...
                    'HitTest','Off',...
                    'Color',ErrorBarColor,...
                    'PickableParts','none',...
                    'Visible','off');
                % plot a point at the group mean
                mean_marker(PlotIdx) = plot(axH,PlotIdx,GroupMean,...
                    'Marker','o',...
                    'MarkerSize',10,...
                    'MarkerEdgeColor',[0 0 0],...
                    'MarkerFaceColor',ErrorBarColor,...
                    'Visible','off');
                % add custom data tip rows
                mean_marker(PlotIdx).DataTipTemplate.DataTipRows(1) = dataTipTextRow("Group",categorical(axH.XTickLabel(PlotIdx)));
                mean_marker(PlotIdx).DataTipTemplate.DataTipRows(2) = dataTipTextRow("n",Groupn);
                mean_marker(PlotIdx).DataTipTemplate.DataTipRows(3) = dataTipTextRow("Mean",GroupMean);
                mean_marker(PlotIdx).DataTipTemplate.DataTipRows(4) = dataTipTextRow("Standard Deviation",GroupStd);
                mean_marker(PlotIdx).DataTipTemplate.DataTipRows(5) = dataTipTextRow("Max",GroupMax);
                mean_marker(PlotIdx).DataTipTemplate.DataTipRows(6) = dataTipTextRow("Min",GroupMin);
            end
        catch me
            switch me.message
                case "Object data missing"
                    UpdateLog3(source,['Warning: [',ExpandVariableName(Var2Plot),'] data missing for objects with [Label:',OOPSData.Settings.ObjectLabels(ii).Name,'] in [Group:',OOPSData.Group(i).GroupName,']'],'append');
                otherwise
                    UpdateLog3(source,['Warning: ',me.message],'append');
            end
        end
        PlotIdx = PlotIdx+1;
    end
end

% set y-axis limits, y-axis tick locations, and y-axis tick labels automatically
axH.YTickMode = 'Auto';
axH.YTickLabelMode = 'Auto';
axH.YLimMode = 'Auto';

% unhide all the plot elements
set(findobj(axH,'type','scatter'),'Visible','on');
set(findobj(axH,'type','line'),'Visible','on');

% set marker colors based on color mode
switch OOPSData.Settings.SwarmPlotColorMode
    case 'Magnitude'
        % color the points according to magnitude using the currently selected Order factor colormap
        axH.Colormap = OOPSData.Settings.OrderFactorColormap;
        % set the color limits
        axH.CLim = axH.YLim;
    case 'Group'
        % color the points according to the group of each object
        axH.Colormap = OOPSData.GroupColors;
        % set the color limits
        if OOPSData.nGroups > 1
            axH.CLim = [1 OOPSData.nGroups];
        else
            axH.CLim = [0 1];
        end
end

% hide the axes until we are done plotting
axH.Visible = 'on';



end