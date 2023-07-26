function deleteImage(source,~,fH)
    
    OOPSData = guidata(source);

    SelectedNodes = OOPSData.Handles.ImageTree.SelectedNodes;
    %SelectedImages = deal([SelectedNodes(:).NodeData]);
    UpdateLog3(fH,'Deleting images...','append');
    delete(SelectedNodes)
    cGroup = OOPSData.CurrentGroup;
    cGroup.DeleteSelectedImages();
    
    cGroup.CurrentImageIndex = cGroup.CurrentImageIndex(1);
    UpdateImageTree(source);
    UpdateImages(source);
    UpdateSummaryDisplay(source,{'Project','Group','Image','Object'});
    UpdateLog3(fH,'Done.','append');
    
end