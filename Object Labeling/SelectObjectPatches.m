function SelectObjectPatches(source,~)
% ButtonDownFcn callback for patch objects showing object boundaries

%% get the location of the clicked point and the object corresponding to it
    % get (x,y) coordinates of most recent cursor position on axes
    CurrentPoint = source.Parent.CurrentPoint(1,1:2);
    % store this handle so we can use it to update after deleting an object box
    hAx = source.Parent;
    % get the main data structure
    PODSData = guidata(source);
    % get the handle to the active image in the GUI
    CurrentImage = PODSData.CurrentImage(1);
    % round the (x,y) coordinates of the clicked point
    x = round(CurrentPoint(1));
    y = round(CurrentPoint(2));
    % using the label matrix, determine the idx of the clicked object
    ObjIdx = full(CurrentImage.L(y,x));
    % if click landed outside the image mask (L(y,x)==0), do nothing and return
    if ObjIdx==0
        return
    end
%% depending on the type of click, either select/deselect the object, or make it active in the GUI
% we could add more functionality here by including alternate click types (double-click, etc.)
    % if shift-click
    if strcmp(PODSData.Handles.fH.SelectionType,'extend')
        % change the active object
        CurrentImage.CurrentObjectIdx = ObjIdx;
        % update the summary display if the summary type is 'Object'
        UpdateSummaryDisplay(hAx,{'Object'});
        % update the object selection listbox
        UpdateObjectListBox(hAx);
    else
        % invert the selection status of the object corresponding to the clicked patch
        CurrentImage.Object(ObjIdx).InvertSelection();
        % swap faces between selected and unselected patch objects
        tempFace = PODSData.Handles.ObjectBoxes.Faces(ObjIdx,:);
        PODSData.Handles.ObjectBoxes.Faces(ObjIdx,:) = PODSData.Handles.SelectedObjectBoxes.Faces(ObjIdx,:);
        PODSData.Handles.SelectedObjectBoxes.Faces(ObjIdx,:) = tempFace;
    end
end