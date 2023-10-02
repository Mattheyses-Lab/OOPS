function UpdateSwarmChart(source)

% get the GUI data structure
OOPSData = guidata(source);

% the variable for which we will be retrieving object data to plot
Var2Plot = OOPSData.Settings.SwarmPlotYVariable;
% display name of the variable used for axes and data tip labels
varDisplayName = OOPSData.Settings.expandVariableName(Var2Plot);
% number of groups in the project
nGroups = OOPSData.nGroups;
% number of distinct object labels
nLabels = OOPSData.Settings.nLabels;

switch OOPSData.Settings.SwarmPlotGroupingType
    case 'Group'
    %% determine number of plots and get group names

        % determine the number of plots (depends on grouping type)
        nPlots = OOPSData.nGroups;
        % preallocate cell array of plot names (x-axis tick labels)
        groupNames = cell(1,nPlots);
        % get names for each plot group
        for i = 1:nPlots
            groupNames{i} = OOPSData.Group(i).GroupName;
        end

    %% gather the data

        % cell array of Var2Plot data
        ObjectData = OOPSData.GetObjectDataByGroup(Var2Plot);
        % get object SelfIdxs for data tips
        ObjectSelfIdxs = OOPSData.GetObjectDataByGroup('SelfIdx');
        % get object GroupNames for data tips
        ObjectGroupNames = OOPSData.GetObjectDataByGroup('GroupName');
        % get object ImageNames for data tips
        ObjectImageNames = OOPSData.GetObjectDataByGroup('texFriendlyImageName');
        % get object LabelNames for data tips
        ObjectLabelNames = OOPSData.GetObjectDataByGroup('LabelName');
        % get object LabelIdxs for plot marker colors
        ObjectLabelIdxs = OOPSData.GetObjectDataByGroup('LabelIdx');
        % get object GroupIdxs for plot marker colors
        ObjectGroupIdxs = OOPSData.GetObjectDataByGroup('GroupIdx');

    %% get some other properties

    XAxisLabel = "Group";

    case 'Label'
    %% determine number of plots and get group names
        
        % get the current group
        cGroup = OOPSData.CurrentGroup;
        % determine the number of plots (depends on grouping type)
        nPlots = OOPSData.Settings.nLabels;
        % preallocate cell array of plot names (x-axis tick labels)
        groupNames = cell(1,nPlots);
        % get names for each plot group
        for i = 1:nPlots
            groupNames{i} = [cGroup.GroupName,' (',OOPSData.Settings.ObjectLabels(i).Name,')'];
        end

    %% gather the data

        % cell array of Var2Plot values, one cell per label
        ObjectData = cGroup.GetObjectDataByLabel(Var2Plot);
        % get object SelfIdxs for data tips
        ObjectSelfIdxs = cGroup.GetObjectDataByLabel('SelfIdx');
        % get object GroupName for data tips
        ObjectGroupNames = cGroup.GetObjectDataByLabel('GroupName');
        % get object ImageName for data tips
        ObjectImageNames = cGroup.GetObjectDataByLabel('texFriendlyImageName');
        % get object LabelName for data tips
        ObjectLabelNames = cGroup.GetObjectDataByLabel('LabelName');
        % get object GroupIdx for plot colors
        ObjectLabelIdxs = cGroup.GetObjectDataByLabel('LabelIdx');
        % get object GroupIdxs for plot marker colors
        ObjectGroupIdxs = cGroup.GetObjectDataByLabel('GroupIdx');

    %% get some other properties

    XAxisLabel = "Label";

    case 'Both'
    %% determine number of plots and get group names
        
        % determine the number of plots (depends on grouping type)
        nPlots = nGroups*nLabels;
        % preallocate cell array of plot names (x-axis tick labels)
        groupNames = cell(1,nPlots);
        % get names for each plot group
        plotIdx = 1;
        for i = 1:nGroups
            for ii = 1:nLabels
                groupNames{plotIdx} = [OOPSData.Group(i).GroupName,' (',OOPSData.Settings.ObjectLabels(ii).Name,')'];
                plotIdx = plotIdx+1;
            end
        end

    %% gather the data

        % gather the data: cell array of Var2Get values, transposed so that rows = labels, cols = groups
        ObjectData = OOPSData.GetObjectDataByLabel(Var2Plot)';
        % get object SelfIdxs for data tips
        ObjectSelfIdxs = OOPSData.GetObjectDataByLabel('SelfIdx')';
        % get object GroupName for data tips
        ObjectGroupNames = OOPSData.GetObjectDataByLabel('GroupName')';
        % get object ImageName for data tips
        ObjectImageNames = OOPSData.GetObjectDataByLabel('texFriendlyImageName')';
        % get object LabelName for data tips
        ObjectLabelNames = OOPSData.GetObjectDataByLabel('LabelName')';
        % get object GroupIdx for plot colors
        ObjectLabelIdxs = OOPSData.GetObjectDataByLabel('LabelIdx')';
        % get object GroupIdxs for plot marker colors
        ObjectGroupIdxs = OOPSData.GetObjectDataByLabel('GroupIdx')';

    %% get some other properties

    XAxisLabel = "Group (Label)";

end

% cell arrays to hold YData, CData, and datatip info
Y = cell(nPlots,1);
% color data for marker faces
CData = cell(nPlots,1);
% datatip info
dtNames = cell(nPlots,1);
dtData = cell(nPlots,1);
dataTipNames = {'Group','Image','Object','Label',varDisplayName};

% get the object data for each group
for i = 1:nPlots

    % Y data is just the vector of object values for selected variable
    [Y{i},TF] = rmmissing(ObjectData{i});
    % the number of objects for which Var2Plot data was missing
    nRemoved = numel(find(TF));
    % adjust data tip variables to account for any data removed above
    ObjectSelfIdxs{i} = ObjectSelfIdxs{i}(~TF);
    ObjectGroupNames{i} = ObjectGroupNames{i}(~TF);
    ObjectImageNames{i} = ObjectImageNames{i}(~TF);
    ObjectLabelNames{i} = ObjectLabelNames{i}(~TF);
    ObjectLabelIdxs{i} = ObjectLabelIdxs{i}(~TF);
    ObjectGroupIdxs{i} = ObjectGroupIdxs{i}(~TF);

    % try and draw the plot, catch errors
    try
        if isempty(Y{i})
            % if data missing for all objects, throw error
            error("Object data missing");
        elseif nRemoved > 0
            % if data were missing some (but not all) objects, warn the user by sending an update to the log window
            UpdateLog3(source,['Warning: ',varDisplayName,' data missing for ',num2str(nRemoved),' objects in [',groupNames{i},']'],'append');
        end

        % set color data for plot marker faces
        switch OOPSData.Settings.SwarmPlotColorMode
            case 'Magnitude'
                % CData set to match the actual values of each point
                CData{i} = Y{i};
            case 'Group'
                switch OOPSData.Settings.SwarmPlotGroupingType
                    case 'Group'
                        CData{i} = OOPSData.Group(i).Color;
                    case 'Label'
                        CData{i} = ObjectGroupIdxs{i};
                    case 'Both'
                        % determine which group we are on 
                        [~,groupIdx] = ind2sub([nLabels,nGroups],i);
                        CData{i} = OOPSData.Group(groupIdx).Color;
                end
            case 'Label'
                switch OOPSData.Settings.SwarmPlotGroupingType
                    case 'Group'
                        CData{i} = ObjectLabelIdxs{i};
                    case 'Label'
                        CData{i} = OOPSData.Settings.ObjectLabels(i).Color;
                    case 'Both'
                        % determine which group we are on 
                        [labelIdx,~] = ind2sub([nLabels,nGroups],i);
                        CData{i} = OOPSData.Settings.ObjectLabels(labelIdx).Color;
                end
        end

        % cell array of data tip labels
        dtNames{i} = dataTipNames;
        % cell array of datatip values for each label (we will have one of these cells per violin)
        dataTipValues = cell(1,numel(dtNames{i}));
        % add arrays of values for each label
        dataTipValues{1,1} = categorical(ObjectGroupNames{i});
        dataTipValues{1,2} = categorical(ObjectImageNames{i});
        dataTipValues{1,3} = ObjectSelfIdxs{i};
        dataTipValues{1,4} = categorical(ObjectLabelNames{i});
        dataTipValues{1,5} = Y{i};
        % add the set of datatip values for each label to the cell in dtData for this violin
        dtData{i} = dataTipValues;
    catch me
        switch me.message
            case "Object data missing"
                UpdateLog3(source,['Warning: [',varDisplayName,'] data missing for [',groupNames{i},']'],'append');
            otherwise
                UpdateLog3(source,['Warning: ',me.message],'append');
        end
        % create filler CData
        CData{i} = [1 1 1];
        % create filler data (NaN)
        Y{i} = NaN;
        % create filler data tip info
        dtNames{i} = {};
        dtData{i} = {};
    end

end

% concatenate the datatip names and data to form datatip info cell which we will pass to ViolinChart
dtCell = [dtNames, dtData];

% get CLim and colormap for plot marker colors
switch OOPSData.Settings.SwarmPlotColorMode
    case 'Magnitude'
        % color the points according to magnitude using the currently selected Order factor colormap
        cmap = OOPSData.Settings.OrderColormap;
        % get the color limits
        CLim = [0 1];
        % mode by which CLim is set
        CLimMode = 'auto';
    case 'Group'
        % color the points according to the color of the group
        cmap = OOPSData.GroupColors;
        % set the color limits
        if OOPSData.nGroups > 1
            CLim = [1 OOPSData.nGroups];
        else
            CLim = [0 1];
        end
        % mode by which CLim is set
        CLimMode = 'manual';
    case 'Label'
        % color the points according to the color of the label of each object
        cmap = OOPSData.Settings.LabelColors;
        % set the color limits
        if OOPSData.Settings.nLabels > 1
            CLim = [1 OOPSData.Settings.nLabels];
        else
            CLim = [0 1];
        end
        % mode by which CLim is set
        CLimMode = 'manual';
end

%% get 'auto' violin face/edge, error bar, and plot marker edge colors

switch OOPSData.Settings.SwarmPlotGroupingType
    case 'Group'
        switch OOPSData.Settings.SwarmPlotColorMode
            case 'Magnitude'
                autoColors = zeros(nPlots,3); % black violin outlines if points colored by magnitude
            case 'Group'
                autoColors = OOPSData.GroupColors;
            case 'Label'
                autoColors = OOPSData.GroupColors;
        end
    case 'Label'
        switch OOPSData.Settings.SwarmPlotColorMode
            case 'Magnitude'
                autoColors = zeros(nPlots,3); % black violin outlines if points colored by magnitude
            case 'Group'
                autoColors = OOPSData.Settings.LabelColors;
            case 'Label'
                autoColors = OOPSData.Settings.LabelColors;
        end
    case 'Both'
        switch OOPSData.Settings.SwarmPlotColorMode
            case 'Magnitude'
                autoColors = zeros(nPlots,3); % black violin outlines if points colored by magnitude
            case 'Group'
                % convert group colors matrix into cell array, duplicate for each label
                groupColorsCell = repmat(mat2cell(OOPSData.GroupColors,ones(nGroups,1),3)',nLabels,1);
                % convert back to matrix of RGB triplets
                autoColors = cell2mat(groupColorsCell(:));
            case 'Label'
                % duplicate label colors for each group
                autoColors = repmat(OOPSData.Settings.LabelColors,nGroups,1);
        end
end


switch OOPSData.Settings.SwarmPlotViolinEdgeColorMode
    case 'auto'
        ViolinEdgeColor = autoColors;
    case 'Custom'
        ViolinEdgeColor = OOPSData.Settings.SwarmPlotViolinEdgeColor;
end

switch OOPSData.Settings.SwarmPlotViolinFaceColorMode
    case 'auto'
        ViolinFaceColor = autoColors;
    case 'Custom'
        ViolinFaceColor = OOPSData.Settings.SwarmPlotViolinFaceColor;
end

switch OOPSData.Settings.SwarmPlotMarkerEdgeColorMode
    case 'auto'
        MarkerEdgeColor = autoColors;
    case 'Custom'
        MarkerEdgeColor = OOPSData.Settings.SwarmPlotMarkerEdgeColor;
end

switch OOPSData.Settings.SwarmPlotErrorBarsColorMode
    case 'auto'
        ErrorBarsColor = autoColors;
    case 'Custom'
        ErrorBarsColor = OOPSData.Settings.SwarmPlotErrorBarsColor;
end

MarkerSize = OOPSData.Settings.SwarmPlotMarkerSize;
XJitterWidth = OOPSData.Settings.SwarmPlotXJitterWidth;
ViolinsVisible = OOPSData.Settings.SwarmPlotViolinsVisible;
MarkerFaceAlpha = OOPSData.Settings.SwarmPlotMarkerFaceAlpha;
BGColor = OOPSData.Settings.SwarmPlotBackgroundColor;
FGColor = OOPSData.Settings.SwarmPlotForegroundColor;


% set all the properties
set(OOPSData.Handles.SwarmPlot,...
    "Title",varDisplayName,...
    "Data",Y,...
    "BackgroundColor",BGColor,...
    "ForegroundColor",FGColor,...
    "FontColor",FGColor,...
    "Position",[0 0 1 1],...
    "PlotSpacing",1,...
    "XJitterWidth",XJitterWidth,...
    "DataTipCell",dtCell,...
    "XLabel",XAxisLabel,...
    "YLabel",varDisplayName,...
    "MarkerEdgeColor",MarkerEdgeColor,...
    "MarkerSize",MarkerSize,...
    "MarkerFaceAlpha",MarkerFaceAlpha,...
    "CData",CData,...
    "ViolinOutlinesVisible",ViolinsVisible,...
    "ViolinLineWidth",2,...
    "ViolinFaceColor",ViolinFaceColor,...
    "ViolinEdgeColor",ViolinEdgeColor,...
    "ErrorBarsColor",ErrorBarsColor,...
    "ErrorBarsLineWidth",2,...
    "GroupNames",groupNames,...
    "Colormap",cmap,...
    "CLim",CLim,...
    "CLimMode",CLimMode);

end