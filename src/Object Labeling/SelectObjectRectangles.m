function SelectObjectRectangles(source,~)

    % get the GUI data structure
    OOPSData = guidata(source);

    % get parent axes
    hAx = source.Parent;

    % get object index from bounding box UserData
    ObjIdx = source.UserData;
    
    % get active image in GUI
    CurrentImage = OOPSData.CurrentImage(1);

    % if shift-click, update object summary display with clicked object
    if strcmp(OOPSData.Handles.fH.SelectionType,'extend')
        CurrentImage.CurrentObjectIdx = ObjIdx;
        UpdateSummaryDisplay(hAx,{'Object'});
        UpdateObjectListBox(hAx);
    else
        CurrentImage.Object(ObjIdx).InvertSelection();
        OOPSData.Handles.ObjectBoxes(ObjIdx,1).LineWidth = CurrentImage.Object(ObjIdx).SelectionBoxLineWidth;
        OOPSData.Handles.ObjectBoxes(ObjIdx,2).LineWidth = CurrentImage.Object(ObjIdx).SelectionBoxLineWidth;
    end

end