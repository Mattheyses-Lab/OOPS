function hSwarmPlot = PlotGroupSwarmChart(source,axH)

% get the GUI data structure
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
ErrorBarColor = OOPSData.Settings.SwarmPlotErrorBarsColor;
ErrorBarsVisible = OOPSData.Settings.SwarmPlotErrorBarsVisible;
MarkerSize = OOPSData.Settings.SwarmPlotMarkerSize;
MarkerFaceAlpha = OOPSData.Settings.SwarmPlotMarkerFaceAlpha;


% determine the number of plots (number of groups)
nPlots = OOPSData.nGroups;
% set axis ticks, one for each group, even those that won't be plotted
axH.XTick = 1:1:OOPSData.nGroups;
% set x-axis label for each group
for i = 1:nPlots
    axH.XTickLabel{i} = OOPSData.Group(i).GroupName;
end

% set X limits to 1 below and above the max
axH.XLim = [0 OOPSData.nGroups+1];

% the variable for which we will be retrieving object data to plot
Var2Plot = OOPSData.Settings.SwarmPlotYVariable;

% display name of the variable used for axes and data tip labels
varDisplayName = OOPSData.Settings.expandVariableName(Var2Plot);

% cell array to hold vectors of Var2Plot for each group
GroupObjectData = cell(1,nPlots);
% cell array to hold vectors of object idxs
GroupObjectSelfIdxs = cell(1,nPlots);
% cell array to hold vectors of object group names
GroupObjectGroupNames = cell(1,nPlots);
% cell array to hold vectors of object image names
GroupObjectImageNames = cell(1,nPlots);
% cell array to hold vectors of object label names
GroupObjectLabelNames = cell(1,nPlots);
% cell array to hold vectors of object label idxs
GroupObjectLabelIdxs = cell(1,nPlots);

% get the object data for each group
for i = 1:nPlots
    % cell array of Var2Plot data
    GroupObjectData{i} = GetAllObjectData(OOPSData.Group(i),Var2Plot);
    % get object SelfIdxs for data tips
    GroupObjectSelfIdxs{i} = GetAllObjectData(OOPSData.Group(i),'SelfIdx');
    % get object GroupNames for data tips
    GroupObjectGroupNames{i} = GetAllObjectData(OOPSData.Group(i),'GroupName');
    % get object ImageNames for data tips
    GroupObjectImageNames{i} = GetAllObjectData(OOPSData.Group(i),'texFriendlyImageName');
    % get object LabelNames for data tips
    GroupObjectLabelNames{i} = GetAllObjectData(OOPSData.Group(i),'LabelName');
    % get object LabelIdxs for plot marker colors
    GroupObjectLabelIdxs{i} = GetAllObjectData(OOPSData.Group(i),'LabelIdx');
end

% cell arrays to hold X and Y data
Y = cell(nPlots,1);
X = cell(nPlots,1);

globalMax = [];
globalMin = [];

% initialize swarmchart array
hSwarmPlot = gobjects(nPlots,1);
mean_marker = gobjects(nPlots,1);

for i = 1:nPlots
    % Y data is just the vector of object values for selected variable
    [Y{i},TF] = rmmissing(GroupObjectData{i});
    % the number of objects for which Var2Plot data was missing
    nRemoved = numel(find(TF));
    % adjust data tip variables to account for any data removed above
    GroupObjectSelfIdxs{i} = GroupObjectSelfIdxs{i}(~TF);
    GroupObjectGroupNames{i} = GroupObjectGroupNames{i}(~TF);
    GroupObjectImageNames{i} = GroupObjectImageNames{i}(~TF);
    GroupObjectLabelNames{i} = GroupObjectLabelNames{i}(~TF);
    GroupObjectLabelIdxs{i} = GroupObjectLabelIdxs{i}(~TF);
    % generate X data of the same size, multiply by the index of the current group
    X{i} = i*ones(size(Y{i}));
    % try and draw the plot, catch errors
    try
        if isempty(Y{i})
            % if data missing for all objects, throw error
            error("Object data missing");
        elseif nRemoved > 0
            % if data were missing some (but not all) objects, warn the user by sending an update to the log window
            UpdateLog3(source,['Warning: ',...
                varDisplayName,...
                ' data missing for ',...
                num2str(nRemoved),...
                ' objects in [Group:',...
                OOPSData.Group(i).GroupName,...
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
                    'CData',Y{i}',...
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
                    'MarkerFaceColor',OOPSData.Group(i).Color,...
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
                    'MarkerFaceColor','flat',...
                    'CData',GroupObjectLabelIdxs{i}',...
                    'MarkerEdgeColor',[0 0 0],...
                    'MarkerFaceAlpha',MarkerFaceAlpha,...
                    'SizeData',MarkerSize,...
                    'HitTest','off',...
                    'Visible','off');
        end
        % build data tips for each plot marker of the swarm chart
        hSwarmPlot(i).DataTipTemplate.DataTipRows(1) = dataTipTextRow("Group",categorical(GroupObjectGroupNames{i}));
        hSwarmPlot(i).DataTipTemplate.DataTipRows(2) = dataTipTextRow("Image",categorical(GroupObjectImageNames{i}));
        hSwarmPlot(i).DataTipTemplate.DataTipRows(3) = dataTipTextRow("Object",GroupObjectSelfIdxs{i});
        hSwarmPlot(i).DataTipTemplate.DataTipRows(4) = dataTipTextRow("Label",categorical(GroupObjectLabelNames{i}));
        hSwarmPlot(i).DataTipTemplate.DataTipRows(5) = dataTipTextRow(varDisplayName,Y{i});
        hSwarmPlot(i).HitTest = 'On';
        % get the mean, std, n, max, and min of this group
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
            % add custom data tip rows for the mean marker
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
                    varDisplayName,...
                    '] data missing for [Group:',...
                    OOPSData.Group(i).GroupName,']'],...
                    'append');
            otherwise
                UpdateLog3(source,['Warning: ',me.message],'append');
        end
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
        axH.Colormap = OOPSData.Settings.OrderColormap;
        % set the color limits
        axH.CLim = axH.YLim;
    case 'Label'
        % color the points according to the color of the label of each object
        axH.Colormap = OOPSData.Settings.LabelColors;
        % set the color limits
        if OOPSData.Settings.nLabels > 1
            axH.CLim = [1 OOPSData.Settings.nLabels];
        else
            axH.CLim = [0 1];
        end
end

% show the axes
axH.Visible = 'on';

end