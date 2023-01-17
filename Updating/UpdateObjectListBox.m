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
            PODSData.Handles.ObjectSelector.ItemsData = 1:length(Replicate.ObjectNames);
            PODSData.Handles.ObjectSelector.Value = Replicate.CurrentObjectIdx;
            scroll(PODSData.Handles.ObjectSelector,PODSData.Handles.ObjectSelector.Value);
            return
%         else
%             PODSData.Handles.ObjectSelector.Items = {'No objects found...'};
        end
        % else, if there are no currently selected images
%     elseif isempty(Replicate)
%         % disable object selection listbox, instruct user to select image
%         PODSData.Handles.ObjectSelector.Items = {'Select an image...'};
%         PODSData.Handles.ObjectSelector.Enable = 0;
%         % else, if the number of currently selected images > 1
%     else
%         % disable object selection listbox and indicate that too many images are selected
%         PODSData.Handles.ObjectSelector.Items = {'Multiple images selected...'};
%         PODSData.Handles.ObjectSelector.Enable = 0;
    end

    PODSData.Handles.ObjectSelector.Items = {};
    PODSData.Handles.ObjectSelector.Enable = 0;

end