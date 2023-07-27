function groupTreeNodeTextChanged(source,event)
    event.Node.NodeData.GroupName = event.Node.Text;
    UpdateSummaryDisplay(source,{'Group'});
end