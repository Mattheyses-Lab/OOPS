function hScatter = PlotGroupScatterPlot(source,axH)

    % get the master data object
    PODSData = guidata(source);
    % determine how many groups we will be plotting for
    nGroups = PODSData.nGroups;
    % get the variables to plot from sattings object
    XVar = PODSData.Settings.ScatterPlotXVariable;
    YVar = PODSData.Settings.ScatterPlotYVariable;
    % get the 'expanded' variable names
    XName = ExpandVariableName(XVar);
    YName = ExpandVariableName(YVar);
    % set title and axes labels
    axH.Title.String = [YName,' vs ',XName];
    axH.XLabel.String = XName;
    axH.YLabel.String = YName;
    % set the proper current axes
    PODSData.Handles.fH.CurrentAxes = axH;
    % initialize empty array to hold the scatterplots
    hScatter = [];
    
    for i = 1:nGroups
        try
            % get the data to plot
            ObjectData = CombineObjectData(PODSData.Group(i),XVar,YVar);
            % check for NaNs, throw error if found
            if any(isnan(ObjectData(:)))
                error();
            end
            % plot the data
            hScatter(i) = scatter(axH,ObjectData(:,1),ObjectData(:,2),...
                'MarkerFaceColor',PODSData.Group(i).Color,...
                'MarkerEdgeColor',[0 0 0],...
                'DisplayName',PODSData.Group(i).GroupName,...
                'MarkerFaceAlpha',1,...
                'MarkerEdgeAlpha',0.5);            
        catch
            UpdateLog3(source,['Error building group scatterplot: Data missing or incomplete for [Group:',PODSData.Group(i).GroupName,']'],'append');
        end
        hold on
    end
    
    axH.YTickMode = 'Auto';
    axH.YTickLabelMode = 'Auto';
    axH.YLimMode = 'Auto';
    axH.XTickMode = 'Auto';
    axH.XTickLabelMode = 'Auto';
    axH.XLimMode = 'Auto';
    lgd = legend(axH);
    lgd.Color = [0 0 0];
    lgd.TextColor = 'Yellow';
    lgd.EdgeColor = 'Yellow';
    
    hold off

end