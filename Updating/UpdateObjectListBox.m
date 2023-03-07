function UpdateObjectListBox(source)
    PODSData = guidata(source);

    if PODSData.nGroups>=1
        CurrentGroup = PODSData.CurrentGroup;
    else
        PODSData.Handles.ObjectSelector.Items = {};
        PODSData.Handles.ObjectSelector.Enable = 0;
        return
    end

    Replicate = CurrentGroup.CurrentImage;
    
    % if the number of currently selected images is 1
    if length(Replicate) == 1
        % and at least one object has been detected
        if Replicate.nObjects >= 1
            % enable/update object selection
            PODSData.Handles.ObjectSelector.Enable = 1;
            PODSData.Handles.ObjectSelector.Items = Replicate.ObjectNames;
            PODSData.Handles.ObjectSelector.ItemsData = 1:Replicate.nObjects;
            PODSData.Handles.ObjectSelector.Value = Replicate.CurrentObjectIdx;
            scroll(PODSData.Handles.ObjectSelector,PODSData.Handles.ObjectSelector.Value);
            return
        end
    end

    % if the above conditions are unmet, clear and disable the listbox
    PODSData.Handles.ObjectSelector.Items = {};
    PODSData.Handles.ObjectSelector.Enable = 0;

end