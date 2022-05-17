function SelectSingleObjects(source,event)
    PODSData = guidata(source);

    disp(['That worked! Selected Object ',source.Tag])
    
    % get object index from bounding box tag
    ObjIdx = str2num(source.Tag);
    
    % get active image
    CurrentImage = PODSData.CurrentImage(1);

    switch CurrentImage.Object(ObjIdx).Selected
        case true
            CurrentImage.Object(ObjIdx).Selected = false;
            PODSData.Handles.ObjectRectangles(ObjIdx,1).LineWidth = 1;
            PODSData.Handles.ObjectRectangles(ObjIdx,2).LineWidth = 1;
        case false
            CurrentImage.Object(ObjIdx).Selected = true;
            PODSData.Handles.ObjectRectangles(ObjIdx,1).LineWidth = 2;
            PODSData.Handles.ObjectRectangles(ObjIdx,2).LineWidth = 2;
    end
    
%     guidata(source,PODSData.Handles);
%     UpdateImages(source);

end