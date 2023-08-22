function ShowSummaryTable(source,~)

    % get the summary table
    T = SaveOOPSData(source);
    
    % handle to the main data structure
    OOPSData = guidata(source);

    % new figure to show summary table
    SummaryFig = uifigure('Position',OOPSData.Handles.fH.Position);
    
    % uitable to hold data
    uit = uitable(SummaryFig,'data',T);

    % make uitable fill the figure
    uit.Units = 'normalized';
    uit.Position = [0 0 1 1];
end