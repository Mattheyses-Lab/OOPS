function axH = PlotGroupScatterPlot(source,axH)

    PODSData = guidata(source);
    
    nGroups = PODSData.nGroups;

    XVar = PODSData.Settings.ScatterPlotXVariable;
    YVar = PODSData.Settings.ScatterPlotYVariable;
    
    XName = ExpandVariableName(XVar);
    YName = ExpandVariableName(YVar);

    axH.Title.String = [YName,' vs ',XName];
    axH.XLabel.String = XName;
    axH.YLabel.String = YName;

    for i = 1:nGroups
        
        try
            ObjectData = CombineObjectData(PODSData.Group(i),XVar,YVar);
            scatter(axH,ObjectData(:,1),ObjectData(:,2),...
                'MarkerFaceColor',PODSData.Group(i).Color,...
                'MarkerEdgeColor',[0 0 0],...
                'DisplayName',PODSData.Group(i).GroupName,...
                'MarkerFaceAlpha',1,...
                'MarkerEdgeAlpha',0.5);            
        catch
            UpdateLog3(source,['ERROR: No object data found for [Group:',PODSData.Group(i).GroupName,']'],'append');
        end
        
        hold on
        
    end
    
    axH.YTickMode = 'Auto';
    axH.YTickLabelMode = 'Auto';
    axH.XTickMode = 'Auto';
    axH.XTickLabelMode = 'Auto';    
    lgd = legend(axH);
    lgd.Color = [0 0 0];
    lgd.TextColor = 'Yellow';
    lgd.EdgeColor = 'Yellow';
    
    hold off

end