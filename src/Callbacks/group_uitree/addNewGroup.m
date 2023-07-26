function addNewGroup(source,~)
    OOPSData = guidata(source);
    OOPSData.AddNewGroup(['Untitled Group ',num2str(OOPSData.nGroups+1)]);
    UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});
    UpdateGroupTree(source);
end