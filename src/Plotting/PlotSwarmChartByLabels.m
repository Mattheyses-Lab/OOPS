function hSwarmPlot = PlotSwarmChartByLabels(source,axH)

% get the main project data structure
OOPSData = guidata(source);

% get the current group
CurrentGroup = OOPSData.CurrentGroup;
% if group is empty, return empty graphics placeholder
if isempty(CurrentGroup)
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

% the number of different object labels in the project
nLabels = length(OOPSData.Settings.ObjectLabels);
% make an x axis tick for each label
axH.XTick = 1:1:nLabels;
% for each object label, make an x axis tick label
for ii = 1:nLabels
    axH.XTickLabel{ii} = [CurrentGroup.GroupName,' (',OOPSData.Settings.ObjectLabels(ii).Name,')'];
end

% set X limits to 1 below and above the max
axH.XLim = [0 nLabels+1];

% the object variable for which we are going to retrieve data
Var2Plot = OOPSData.Settings.SwarmPlotYVariable;
% cell array of Var2Plot values, one cell per label
LabelObjectData = CurrentGroup.GetObjectDataByLabel(Var2Plot);
% get object SelfIdxs for data tips
LabelObjectSelfIdxs = CurrentGroup.GetObjectDataByLabel('SelfIdx');
% get object GroupName for data tips
LabelObjectGroupNames = CurrentGroup.GetObjectDataByLabel('GroupName');
% get object ImageName for data tips
LabelObjectImageNames = CurrentGroup.GetObjectDataByLabel('InterpreterFriendlyImageName');
% get object LabelName for data tips
LabelObjectLabelNames = CurrentGroup.GetObjectDataByLabel('LabelName');
% get object GroupIdx for plot colors
LabelObjectGroupIdx = CurrentGroup.GetObjectDataByLabel('GroupIdx');

% determine the number of plots (i.e. number of labels)
nPlots = length(LabelObjectData);
% cell arrays to hold X and Y data
Y = cell(nPlots,1);
X = cell(nPlots,1);

% empty array to hold the swarm plots
hSwarmPlot = gobjects(nPlots,1);
mean_marker = gobjects(nPlots,1);

globalMax = [];
globalMin = [];

LabelIdxs = 1:1:nLabels;

for i = 1:nPlots
    % Y data is just the vector of object values for selected variable
    [Y{i},TF] = rmmissing(LabelObjectData{i});
    % the number of objects for which Var2Plot data was missing
    nRemoved = numel(find(TF));
    % adjust data tip variables to account for any data removed above
    LabelObjectSelfIdxs{i} = LabelObjectSelfIdxs{i}(~TF);
    LabelObjectGroupNames{i} = LabelObjectGroupNames{i}(~TF);
    LabelObjectImageNames{i} = LabelObjectImageNames{i}(~TF);
    LabelObjectLabelNames{i} = LabelObjectLabelNames{i}(~TF);
    LabelObjectGroupIdx{i} = LabelObjectGroupIdx{i}(~TF);
    % generate X data of the same size, multiply by the index of the current group
    X{i} = LabelIdxs(i)*ones(size(Y{i}));
    % try and draw the plot, catch errors
    try
        if isempty(Y{i})
            % if data missing for all objects, throw error
            error("Object data missing");
        elseif nRemoved > 0
            % if data were missing some (but not all) objects, warn the user by sending an update to the log window
            UpdateLog3(source,['Warning: ',...
                ExpandVariableName(Var2Plot),...
                ' data missing for ',...
                num2str(nRemoved),...
                ' objects with [Label:',...
                OOPSData.Settings.ObjectLabels(i).Name,...
                '] in [Group:',...
                CurrentGroup.GroupName,...
                ']'],...
                'append');
        end
        % build swarm chart based on selected color mode
        switch OOPSData.Settings.SwarmPlotColorMode
            case 'Magnitude'
                % color by value
                hSwarmPlot(i) = swarmchart(...
                    axH,...
                    X{i},Y{i},...
                    'Filled',...
                    'MarkerFaceColor','flat',...
                    'CData',Y{i},...
                    'MarkerEdgeColor',[0 0 0],...
                    'MarkerFaceAlpha',MarkerFaceAlpha,...
                    'SizeData',MarkerSize,...                   
                    'HitTest','off',...
                    'Visible','off');
            case 'Label'
                % color by label
                hSwarmPlot(i) = swarmchart(...
                    axH,...
                    X{i},Y{i},...
                    'Filled',...
                    'MarkerFaceColor',OOPSData.Settings.ObjectLabels(i).Color,...
                    'MarkerEdgeColor',[0 0 0],...
                    'MarkerFaceAlpha',MarkerFaceAlpha,...
                    'SizeData',MarkerSize,...
                    'HitTest','off',...
                    'Visible','off');
            case 'Group'
                % color by group
                hSwarmPlot(i) = swarmchart(...
                    axH,...
                    X{i},Y{i},...
                    'Filled',...
                    'MarkerFaceColor','flat',...
                    'CData',LabelObjectGroupIdx{i},...
                    'MarkerEdgeColor',[0 0 0],...
                    'MarkerFaceAlpha',MarkerFaceAlpha,...
                    'SizeData',MarkerSize,...
                    'HitTest','off',...
                    'Visible','off');
        end
        % build data tips for each plot marker of the swarm chart
        hSwarmPlot(i).DataTipTemplate.DataTipRows(1) = dataTipTextRow("Group",categorical(LabelObjectGroupNames{i}));
        hSwarmPlot(i).DataTipTemplate.DataTipRows(2) = dataTipTextRow("Image",categorical(LabelObjectImageNames{i}));
        hSwarmPlot(i).DataTipTemplate.DataTipRows(3) = dataTipTextRow("Object",LabelObjectSelfIdxs{i});
        hSwarmPlot(i).DataTipTemplate.DataTipRows(4) = dataTipTextRow("Label",categorical(LabelObjectLabelNames{i}));
        hSwarmPlot(i).DataTipTemplate.DataTipRows(5) = dataTipTextRow(ExpandVariableName(Var2Plot),Y{i});
        hSwarmPlot(i).HitTest = 'On';
        % get the mean, std, and n of this group
        GroupMean = mean(Y{i});
        GroupStd = std(Y{i});
        Groupn = numel(Y{i});
        GroupMin = min(Y{i});
        GroupMax = max(Y{i});
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
            line(axH,[i-0.25 i+0.25],[GroupMean GroupMean],...
                'LineStyle','-',...
                'LineWidth',3,...
                'HitTest','Off',...
                'Color',ErrorBarColor,...
                'PickableParts','none',...
                'Visible','off');
            % plot horizontal lines showing the mean +/- SD
            line(axH,[i-0.15 i+0.15],[GroupMean-GroupStd GroupMean-GroupStd],...
                'LineStyle','-',...
                'LineWidth',3,...
                'HitTest','Off',...
                'Color',ErrorBarColor,...
                'PickableParts','none',...
                'Visible','off');
            line(axH,[i-0.15 i+0.15],[GroupMean+GroupStd GroupMean+GroupStd],...
                'LineStyle','-',...
                'LineWidth',3,...
                'HitTest','Off',...
                'Color',ErrorBarColor,...
                'PickableParts','none',...
                'Visible','off');
            % plot a vertical line orthogonal to the three lines above
            line(axH,[i i],[GroupMean+GroupStd GroupMean-GroupStd],...
                'LineStyle','-',...
                'LineWidth',3,...
                'HitTest','Off',...
                'Color',ErrorBarColor,...
                'PickableParts','none',...
                'Visible','off');
            % plot a point at the group mean
            mean_marker(i) = plot(axH,i,GroupMean,...
                'Marker','o',...
                'MarkerSize',10,...
                'MarkerEdgeColor',[0 0 0],...
                'MarkerFaceColor',ErrorBarColor,...
                'Visible','off');
            % add custom data tip rows
            mean_marker(i).DataTipTemplate.DataTipRows(1) = dataTipTextRow("Group",categorical(axH.XTickLabel(i)));
            mean_marker(i).DataTipTemplate.DataTipRows(2) = dataTipTextRow("n",Groupn);
            mean_marker(i).DataTipTemplate.DataTipRows(3) = dataTipTextRow("Mean",GroupMean);
            mean_marker(i).DataTipTemplate.DataTipRows(4) = dataTipTextRow("Standard Deviation",GroupStd);
            mean_marker(i).DataTipTemplate.DataTipRows(5) = dataTipTextRow("Max",GroupMax);
            mean_marker(i).DataTipTemplate.DataTipRows(6) = dataTipTextRow("Min",GroupMin);
        end
    catch me
        switch me.message
            case "Object data missing"
                UpdateLog3(source,...
                    ['Warning: [',...
                    ExpandVariableName(Var2Plot),...
                    '] data missing for objects with [Label:',...
                    OOPSData.Settings.ObjectLabels(i).Name,...
                    '] in [Group:',...
                    CurrentGroup.GroupName,...
                    ']'],...
                    'append');
            otherwise
                UpdateLog3(source,['Warning: ',me.message],'append');
        end
    end
end

axH.YTickMode = 'Auto';
axH.YTickLabelMode = 'Auto';
axH.YLimMode = 'Auto';

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

% unhide all the plot elements
set(findobj(axH,'type','scatter'),'Visible','on');
set(findobj(axH,'type','line'),'Visible','on');

% show the axes
axH.Visible = 'on';

end