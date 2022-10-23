function SelectObjectRectangles(source,~)

    % get the GUI data structure
    PODSData = guidata(source);

    % get parent axes
    hAx = source.Parent;

    % get object index from bounding box UserData
    ObjIdx = source.UserData;
    
    % get active image in GUI
    CurrentImage = PODSData.CurrentImage(1);

    % if shift-click, update object summary display with clicked object
    if strcmp(PODSData.Handles.fH.SelectionType,'extend')
        CurrentImage.CurrentObjectIdx = ObjIdx;
        UpdateSummaryDisplay(hAx,{'Object'});
        UpdateListBoxes(hAx);
    else
        CurrentImage.Object(ObjIdx).InvertSelection();
        PODSData.Handles.ObjectBoxes(ObjIdx,1).LineWidth = CurrentImage.Object(ObjIdx).SelectionBoxLineWidth;
        PODSData.Handles.ObjectBoxes(ObjIdx,2).LineWidth = CurrentImage.Object(ObjIdx).SelectionBoxLineWidth;
    end

%     % invert selection status of clicked object
%     switch CurrentImage.Object(ObjIdx).Selected
%         case true
%             CurrentImage.Object(ObjIdx).Selected = false;
%             PODSData.Handles.ObjectBoxes(ObjIdx,1).LineWidth = 1;
%             PODSData.Handles.ObjectBoxes(ObjIdx,2).LineWidth = 1;
%         case false
%             CurrentImage.Object(ObjIdx).Selected = true;
%             PODSData.Handles.ObjectBoxes(ObjIdx,1).LineWidth = 2;
%             PODSData.Handles.ObjectBoxes(ObjIdx,2).LineWidth = 2;
%     end



end