function SelectObjectsInRectangularROI(source,ROI)

    % get data structure
    OOPSData = guidata(source);
    % get active image
    CurrentImage = OOPSData.CurrentImage(1);
    % get boundaries of ROI
    right = ROI.Position(1)+ROI.Position(3);
    left = ROI.Position(1);
    bottom = ROI.Position(2);
    top = ROI.Position(2)+ROI.Position(4);
    %% check if the centroid of each object is within the limits of the ROI
    %   if so -> invert the object's selection status
    for i = 1:CurrentImage.nObjects
        % get centroid
        centroid = CurrentImage.Object(i).Centroid;
        % get x and y centroid coords
        x = centroid(1);
        y = centroid(2);
        % check if obj is within retangular roi, save idx if so
        if x > left && x < right && y < top && y > bottom
            switch CurrentImage.Object(i).Selected
                case true
                    % if selected, deselect
                    CurrentImage.Object(i).Selected = false;
                case false
                    % if not selected, select
                    CurrentImage.Object(i).Selected = true;
            end
        end
    end
    
end