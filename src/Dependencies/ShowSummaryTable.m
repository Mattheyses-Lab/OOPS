function ShowSummaryTable(source,event)

    % get the summary table
    T = SaveOOPSData(source);
    
    % get handles
    OOPSData = guidata(source);

    % new figure to show summary table
    SummaryFig = uifigure('Position',OOPSData.Handles.fH.Position);
    
    % uitable to hold data
    uit = uitable(SummaryFig,'data',T);

    uit.Units = 'normalized';
    uit.Position = [0 0 1 1];
    
    % maximize table size within figure window
    %uit.Position = SummaryFig.InnerPosition;

end