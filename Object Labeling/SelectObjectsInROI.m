function SelectObjectsInROI(source,ROI)
% currently working for freehand and rectangular ROIs
% should work with any MATLAB ROI object, but untested
    % get data structure
    OOPSData = guidata(source);
    % get active image
    CurrentImage = OOPSData.CurrentImage(1);
    % initialize array of object centroid coordinates
    Centroids = zeros(2,CurrentImage.nObjects);
    % get x-, and y-coordinates for each centroid
    [Centroids(1,:)] = deal([CurrentImage.Object.CentroidX]);
    [Centroids(2,:)] = deal([CurrentImage.Object.CentroidY]);
    % determine which object centroids are within the ROI
    SelectedStatus = inROI(ROI,Centroids(1,:),Centroids(2,:)).';
    % invert the selection status of objects in the ROI
    CurrentImage.Object(SelectedStatus).InvertSelection();
end