function ShowSummaryTable(source,event)

    T = SavePODSData(source);
    PODSData = guidata(source);

    SummaryFig = uifigure('Position',PODSData.Handles.fH.Position);
    
    uit = uitable(SummaryFig,'data',T);
    
    uit.Position = PODSData.Handles.fH.InnerPosition;


end