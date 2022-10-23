function SelectSingleObjects(source,~)

    % get (X,Y) of most recent cursor position on axes
    CurrentPoint = source.Parent.CurrentPoint(1,1:2);

    % store this handle so we can use it to update after deleting an object box
    hAx = source.Parent;

    %CurrentPointFull = source.Parent.CurrentPoint(1,1);

    PODSData = guidata(source);

    CurrentImage = PODSData.CurrentImage;
    
%     % get object index from bounding box tag
%     ObjIdx = source.UserData;
%     
%     % get active image
%     CurrentImage = PODSData.CurrentImage(1);
% 
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

    % initialize array of object centroid coordinates
    Centroids = zeros(2,CurrentImage.nObjects);
    %CentroidsY = zeros(1,CurrentImage.nObjects);
    % get x-, and y-coordinates for each centroid
    [Centroids(1,:)] = deal([CurrentImage.Object.CentroidX]);
    [Centroids(2,:)] = deal([CurrentImage.Object.CentroidY]);

    diff_squared = zeros(size(Centroids));

    diff_squared(1,:) = (abs(Centroids(1,:)-CurrentPoint(1))).^2;

    diff_squared(2,:) = (abs(Centroids(2,:)-CurrentPoint(2))).^2;

    distances = zeros(1,size(diff_squared,2));

    distances(:) = sqrt(diff_squared(1,:)+diff_squared(2,:));

    ObjIdx = find(distances==min(distances));

    switch CurrentImage.Object(ObjIdx).Selected
        case true
            CurrentImage.Object(ObjIdx).Selected = false;
%             PODSData.Handles.ObjectBoxes(ObjIdx,1).LineWidth = 1;
%             PODSData.Handles.ObjectBoxes(ObjIdx,2).LineWidth = 1;
        case false
            CurrentImage.Object(ObjIdx).Selected = true;
%             PODSData.Handles.ObjectBoxes(ObjIdx,1).LineWidth = 2;
%             PODSData.Handles.ObjectBoxes(ObjIdx,2).LineWidth = 2;
    end

    UpdateImages(source);

    if strcmp(PODSData.Handles.fH.SelectionType,'extend')
        CurrentImage.CurrentObjectIdx = ObjIdx;
        UpdateSummaryDisplay(hAx,{'Object'});
        UpdateListBoxes(hAx);
    end



end