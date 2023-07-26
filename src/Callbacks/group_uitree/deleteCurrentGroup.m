function deleteCurrentGroup(source,~,fH)
    OOPSData = guidata(source);
    SelectedNode = fH.CurrentObject;
    cGroup = SelectedNode.NodeData;
    UpdateLog3(fH,['Deleting [Group:',cGroup.GroupName,']...'],'append');
    delete(SelectedNode)
    OOPSData.DeleteGroup(cGroup)
    UpdateImageTree(source);
    UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});
    UpdateLog3(fH,'Done.','append');
end