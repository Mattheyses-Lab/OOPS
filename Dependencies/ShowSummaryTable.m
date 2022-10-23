function ShowSummaryTable(source,event)

    % get the summary table
    T = SavePODSData(source);
    
    % get handles
    PODSData = guidata(source);

    % new figure to show summary table
    SummaryFig = uifigure('Position',PODSData.Handles.fH.Position);
    
    % uitable to hold data
    uit = uitable(SummaryFig,'data',T);

    uit.Units = 'normalized';
    uit.Position = [0 0 1 1];
    
    % maximize table size within figure window
    %uit.Position = SummaryFig.InnerPosition;

end