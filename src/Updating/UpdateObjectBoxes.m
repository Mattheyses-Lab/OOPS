function UpdateObjectBoxes(source)

    % handle to the main data structure
    OOPSData = guidata(source);
    
%% delete and clear any existing boxes

    if any(isvalid(OOPSData.Handles.ObjectBoxes))
        delete(OOPSData.Handles.ObjectBoxes);
        clear OOPSData.Handles.ObjectBoxes
        %OOPSData.Handles.ObjectBoxes = gobjects(1,1);
    end
    
    if any(isvalid(OOPSData.Handles.SelectedObjectBoxes))
        delete(OOPSData.Handles.SelectedObjectBoxes);
        clear OOPSData.Handles.SelectedObjectBoxes
        %OOPSData.Handles.SelectedObjectBoxes = gobjects(1,1);
    end

%% get the current image

    % current image(s) selection
    cImage = OOPSData.CurrentImage;

    % if the current selection includes at least one image
    if ~isempty(cImage)
        % update the display according to the first image in the list
        cImage = cImage(1);
    else
        % otherwise, exit
        return
    end


%% draw new boxes

    % ShowSelection toolbar state button is pressed,
    if OOPSData.Handles.ShowSelectionAverageIntensity.Value == 1
        switch OOPSData.Settings.ObjectSelectionBoxType
            case 'Box'
                % get patch data for simple rectangles
                [AllVertices,...
                    AllCData,...
                    SelectedFaces,...
                    UnselectedFaces...
                    ] = getObjectRectanglePatchData(cImage);
                objectClickedFun = @SelectObjectRectanglePatches;
            case 'Boundary'
                % get patch data for object boundaries
                [AllVertices,...
                    AllCData,...
                    SelectedFaces,...
                    UnselectedFaces...
                    ] = getObjectPatchData(cImage);
                objectClickedFun = @SelectObjectPatches;
        end
    
        % preallocate graphics placeholders for our patch objects
        OOPSData.Handles.ObjectBoxes = gobjects(1,1);
        OOPSData.Handles.SelectedObjectBoxes = gobjects(1,1);
        % change the current axes of the main window to the AverageIntensity axes
        OOPSData.Handles.fH.CurrentAxes = OOPSData.Handles.AverageIntensityAxH;
        % hold on so we can preserve our images/other objects
        hold on
        % plot a patch object containing the unselected objects
        OOPSData.Handles.ObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
            'Faces',UnselectedFaces,...
            'Vertices',AllVertices,...
            'Tag','ObjectBox',...
            'FaceVertexCData',AllCData,...
            'EdgeColor','Flat',...
            'FaceColor','none',...
            'HitTest','On',...
            'ButtonDownFcn',objectClickedFun,...
            'PickableParts','all',...
            'Interruptible','off');
        OOPSData.Handles.ObjectBoxes.LineWidth = OOPSData.Settings.ObjectSelectionLineWidth;
        % plot a patch object containing the selected objects
        OOPSData.Handles.SelectedObjectBoxes = patch(OOPSData.Handles.AverageIntensityAxH,...
            'Faces',SelectedFaces,...
            'Vertices',AllVertices,...
            'Tag','ObjectBox',...
            'FaceVertexCData',AllCData,...
            'EdgeColor','Flat',...
            'FaceAlpha',0.5,...
            'FaceColor','Flat',...
            'HitTest','On',...
            'ButtonDownFcn',objectClickedFun,...
            'PickableParts','all',...
            'Interruptible','off');
        OOPSData.Handles.SelectedObjectBoxes.LineWidth = OOPSData.Settings.ObjectSelectionSelectedLineWidth;
        % remove the hold
        hold off

    end

end