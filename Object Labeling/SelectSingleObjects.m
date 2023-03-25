function SelectSingleObjects(source,~)

    % get (X,Y) of most recent cursor position on axes
    CurrentPoint = source.Parent.CurrentPoint(1,1:2);

    % store this handle so we can use it to update after deleting an object box
    hAx = source.Parent;

    PODSData = guidata(source);

    CurrentImage = PODSData.CurrentImage(1);

    x = round(CurrentPoint(1));
    y = round(CurrentPoint(2));
    
    ObjIdx = full(CurrentImage.L(y,x));

    if ObjIdx==0
        return
    end


    if strcmp(PODSData.Handles.fH.SelectionType,'extend')
        CurrentImage.CurrentObjectIdx = ObjIdx;
        UpdateSummaryDisplay(hAx,{'Object'});
        UpdateObjectListBox(hAx);
    else
        CurrentImage.Object(ObjIdx).InvertSelection();
    end

    UpdateImages(source);

end