function ShowSummaryTable(source,event)

    % get the summary table
    T = SavePODSData(source);
    
    % get handles
    PODSData = guidata(source);

    % new figure to show summary table
    SummaryFig = uifigure('Position',PODSData.Handles.fH.Position);
    
    % uitable to hold data
    uit = uitable(SummaryFig,'data',T);
    
    % maximize table size within figure window
    uit.Position = PODSData.Handles.fH.InnerPosition;

end