function hScatter = PlotGroupScatterPlot(source,axH,legendVisible,legendBackgroundColor,legendForegroundColor)

    % get the master data object
    OOPSData = guidata(source);
    % determine how many groups we will be plotting for
    nGroups = OOPSData.nGroups;
    % get the variables to plot from sattings object
    XVar = OOPSData.Settings.ScatterPlotXVariable;
    YVar = OOPSData.Settings.ScatterPlotYVariable;
    % get the 'expanded' variable names
    XName = ExpandVariableName(XVar);
    YName = ExpandVariableName(YVar);
    % set title and axes labels
    axH.Title.String = [YName,' vs ',XName];
    axH.XLabel.String = XName;
    axH.YLabel.String = YName;
    % set the proper current axes
    OOPSData.Handles.fH.CurrentAxes = axH;
    % initialize scatterplot array
    hScatter = gobjects(nGroups,1);
    
    for i = 1:nGroups
        try
            % get the data to plot
            ObjectData = rmmissing(CombineObjectData(OOPSData.Group(i),XVar,YVar));
            % check for NaNs, throw error if found
            if isempty(ObjectData(:))
                error("Object data missing");
            end
            % plot the data
            hScatter(i) = scatter(axH,ObjectData(:,1),ObjectData(:,2),...
                'MarkerFaceColor',OOPSData.Group(i).Color,...
                'MarkerEdgeColor',[0 0 0],...
                'DisplayName',OOPSData.Group(i).GroupName,...
                'MarkerFaceAlpha',1,...
                'MarkerEdgeAlpha',0.5);            
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
    
    axH.YTickMode = 'Auto';
    axH.YTickLabelMode = 'Auto';
    axH.YLimMode = 'Auto';
    axH.XTickMode = 'Auto';
    axH.XTickLabelMode = 'Auto';
    axH.XLimMode = 'Auto';

    if legendVisible
        lgd = legend(axH);
    
        lgd.Color = legendBackgroundColor;
        lgd.TextColor = legendForegroundColor;
        lgd.EdgeColor = legendForegroundColor;
    end
    
    hold off

end