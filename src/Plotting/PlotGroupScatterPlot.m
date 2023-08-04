function hScatter = PlotGroupScatterPlot(source,axH)

    % get the master data object
    OOPSData = guidata(source);
    % determine how many groups we will be plotting for
    nPlots = OOPSData.nGroups;
    % get the variables to plot from sattings object
    XVar = OOPSData.Settings.ScatterPlotXVariable;
    YVar = OOPSData.Settings.ScatterPlotYVariable;
    % get the 'expanded' variable names
    XName = OOPSData.Settings.expandVariableName(XVar);
    YName = OOPSData.Settings.expandVariableName(YVar);
    % set title and axes labels
    axH.Title.String = [YName,' vs ',XName];
    axH.XLabel.String = XName;
    axH.YLabel.String = YName;

    % cell array to hold vectors of XData for each group
    GroupObjectXData = cell(1,nPlots);
    % cell array to hold vectors of YData for each group
    GroupObjectYData = cell(1,nPlots);
    % cell array to hold vectors of object label idxs
    GroupObjectLabelIdxs = cell(1,nPlots);
    
    % get the object data for each group
    for i = 1:nPlots
        % cell array of XData
        GroupObjectXData{i} = GetAllObjectData(OOPSData.Group(i),XVar);
        % cell array of YData
        GroupObjectYData{i} = GetAllObjectData(OOPSData.Group(i),YVar);
        % get object LabelIdxs for plot marker colors
        GroupObjectLabelIdxs{i} = GetAllObjectData(OOPSData.Group(i),'LabelIdx');
    end
    
    % cell arrays to hold X and Y data
    Y = cell(nPlots,1);
    X = cell(nPlots,1);

    % testing below
    % make main figure active
    figure(OOPSData.Handles.fH);
    % end testing

    % set the proper current axes
    OOPSData.Handles.fH.CurrentAxes = axH;
    % initialize scatterplot array
    hScatter = gobjects(nPlots,1);
    % get a cell array of plot markers for each scatterplot
    % uncomment for unique markers
    %plotMarkers = getPlotMarkers(nPlots);

    plotMarkers = repmat({'o'},1,nPlots);
    
    for i = 1:nPlots

        % remove missing YData, save idxs to removed values
        [~,TFY] = rmmissing(GroupObjectYData{i});
        % number of YData values midding
        nYDataRemoved = numel(find(TFY));

        % remove missing XData, save idxs to removed values
        [~,TFX] = rmmissing(GroupObjectXData{i});
        % number of XData values midding
        nXDataRemoved = numel(find(TFX));

        % logical array of missing values, true if x or y are missing
        TF = TFY | TFX;

        % get new XData and YData with missing values removed
        Y{i} = GroupObjectYData{i}(~TF);
        X{i} = GroupObjectXData{i}(~TF);
        GroupObjectLabelIdxs{i} = GroupObjectLabelIdxs{i}(~TF);

        try
            % check for missing values, throw error if appropriate
            if isempty(Y{i})
                error("Object data missing");
            elseif nXDataRemoved > 0
                % if data were missing some (but not all) objects, warn the user by sending an update to the log window
                UpdateLog3(source,['Warning: ',...
                    XName,...
                    ' data missing for ',...
                    num2str(nXDataRemoved),...
                    ' objects in [Group:',...
                    OOPSData.Group(i).GroupName,...
                    ']'],...
                    'append');
            elseif nYDataRemoved > 0
                % if data were missing some (but not all) objects, warn the user by sending an update to the log window
                UpdateLog3(source,['Warning: ',...
                    YName,...
                    ' data missing for ',...
                    num2str(nYDataRemoved),...
                    ' objects in [Group:',...
                    OOPSData.Group(i).GroupName,...
                    ']'],...
                    'append');
            end

            switch OOPSData.Settings.ScatterPlotColorMode

                case 'Group'
                    % plot the data
                    hScatter(i) = scatter(axH,X{i},Y{i},...
                        'MarkerFaceColor',OOPSData.Group(i).Color,...
                        'MarkerEdgeColor',[0 0 0],...
                        'Marker',plotMarkers{i},...
                        'SizeData',OOPSData.Settings.ScatterPlotMarkerSize,...
                        'DisplayName',OOPSData.Group(i).GroupName,...
                        'MarkerFaceAlpha',1,...
                        'MarkerEdgeAlpha',1);
                case 'Density'
                    % plot the data
                    hScatter(i) = scatter(axH,X{i},Y{i},...
                        'MarkerFaceColor','flat',...
                        'MarkerEdgeColor',[0 0 0],...
                        'Marker',plotMarkers{i},...
                        'SizeData',OOPSData.Settings.ScatterPlotMarkerSize,...
                        'DisplayName',OOPSData.Group(i).GroupName,...
                        'MarkerFaceAlpha',0.5,...
                        'MarkerEdgeAlpha',1);
                case 'Label'
                    % plot the data
                    hScatter(i) = scatter(axH,X{i},Y{i},...
                        'MarkerFaceColor','flat',...
                        'CData',GroupObjectLabelIdxs{i},...
                        'MarkerEdgeColor',[0 0 0],...
                        'Marker',plotMarkers{i},...
                        'SizeData',OOPSData.Settings.ScatterPlotMarkerSize,...
                        'DisplayName',OOPSData.Group(i).GroupName,...
                        'MarkerFaceAlpha',1,...
                        'MarkerEdgeAlpha',1);
            end
        catch me
            switch me.message
                case 'Object data missing'
                    UpdateLog3(source,['Error building scatterplot: Data missing or incomplete for [Group:',OOPSData.Group(i).GroupName,']'],'append');
                otherwise
                    UpdateLog3(source,['Error building scatterplot: ',me.message],'append');
            end
        end
        hold on
    end

    

    switch OOPSData.Settings.ScatterPlotColorMode

        case 'Density'
            % preallocate object idx cell array
            objIdxsPerPlot = cell(nPlots,1);
            % get cell array of the idx of each object in each plot, w.r.t. the total num of objects in all plots
            for i = 1:nPlots
                if i == 1
                    objIdxsPerPlot{i} = 1:numel(Y{i});
                else
                    objIdxsPerPlot{i} = (1:numel(Y{i})) + objIdxsPerPlot{i-1}(end);
                end
            end
            % concatenate all XData and YData
            allY = cell2mat(Y);
            allX = cell2mat(X);
            % get the density information for each point
            densityData = ksdensity([allX(:) allY(:)], [allX(:) allY(:)]);
            % use density data for CData
            for i = 1:nPlots
                hScatter(i).CData = densityData(objIdxsPerPlot{i});
            end
            % set the colormap of the axes
            axH.Colormap = turbo;

            axH.CLim = [min(densityData) max(densityData)];

            % delete the old scatterplot legend
            delete(OOPSData.Handles.ScatterPlotLegend);

            legendPlots = gobjects(OOPSData.nGroups,1);
            legendPlotIdx = 1;

            % for each group
            for i = 1:OOPSData.nGroups
                % create an empty plot for each group,label combination
                legendPlots(legendPlotIdx) = plot(axH,...
                    NaN,NaN,...
                    'DisplayName',[OOPSData.Group(i).GroupName],...
                    'Marker',plotMarkers{i},...
                    'MarkerFaceColor',[1 1 1],...
                    'MarkerEdgeColor',[0 0 0],...
                    'MarkerSize',OOPSData.Settings.ScatterPlotMarkerSize,...
                    'LineStyle','none');
                % increment the idx
                legendPlotIdx = legendPlotIdx+1;
            end

            % remake a new legend with the empty plot handles
            OOPSData.Handles.ScatterPlotLegend = legend(legendPlots);

            OOPSData.Handles.ScatterPlotLegend.TextColor = OOPSData.Settings.ScatterPlotForegroundColor;
            OOPSData.Handles.ScatterPlotLegend.Color = OOPSData.Settings.ScatterPlotBackgroundColor;
            OOPSData.Handles.ScatterPlotLegend.EdgeColor = OOPSData.Settings.ScatterPlotForegroundColor;

        case 'Label'
            % color the points according to the color of the label of each object
            axH.Colormap = OOPSData.Settings.LabelColors;
            % set the color limits
            if OOPSData.Settings.nLabels > 1
                axH.CLim = [1 OOPSData.Settings.nLabels];
            else
                axH.CLim = [0 1];
            end

            % delete the old scatterplot legend
            delete(OOPSData.Handles.ScatterPlotLegend);

            legendPlots = gobjects(OOPSData.nGroups*OOPSData.Settings.nLabels,1);
            legendPlotIdx = 1;

            % for each group
            for i = 1:OOPSData.nGroups
                % for each label in each group
                for ii = 1:OOPSData.Settings.nLabels
                    % create an empty plot for each group,label combination
                    legendPlots(legendPlotIdx) = plot(axH,...
                        NaN,NaN,...
                        'DisplayName',[OOPSData.Group(i).GroupName,' (',OOPSData.Settings.ObjectLabels(ii).Name,')'],...
                        'Marker',plotMarkers{i},...
                        'MarkerFaceColor',OOPSData.Settings.ObjectLabels(ii).Color,...
                        'MarkerEdgeColor',[0 0 0],...
                        'MarkerSize',OOPSData.Settings.ScatterPlotMarkerSize,...
                        'LineStyle','none');
                    % increment the idx
                    legendPlotIdx = legendPlotIdx+1;
                end
            end

            % remake a new legend with the empty plot handles
            OOPSData.Handles.ScatterPlotLegend = legend(legendPlots);

            OOPSData.Handles.ScatterPlotLegend.TextColor = OOPSData.Settings.ScatterPlotForegroundColor;
            OOPSData.Handles.ScatterPlotLegend.Color = OOPSData.Settings.ScatterPlotBackgroundColor;
            OOPSData.Handles.ScatterPlotLegend.EdgeColor = OOPSData.Settings.ScatterPlotForegroundColor;

    end

    axH.YTickMode = 'Auto';
    axH.YTickLabelMode = 'Auto';
    axH.YLimMode = 'Auto';
    axH.XTickMode = 'Auto';
    axH.XTickLabelMode = 'Auto';
    axH.XLimMode = 'Auto';


    hold off

end