function UpdateListBoxes(source)

    PODSData = guidata(source);
    CurrentGroup = PODSData.CurrentGroup;
    Replicate = CurrentGroup.CurrentImage;
    % if we have at least one group
    if PODSData.nGroups >= 1
        % update/enable group selection listbox
        PODSData.Handles.GroupSelector.Enable = 1;
        PODSData.Handles.GroupSelector.Items = PODSData.GroupNames;
        PODSData.Handles.GroupSelector.ItemsData = [1:PODSData.nGroups];
        PODSData.Handles.Value = PODSData.CurrentGroupIndex;
        % if we have at least one replicate
        if CurrentGroup.nReplicates >= 1
            % update/enable image selection listbox
            PODSData.Handles.ImageSelector.Enable = 1;
            PODSData.Handles.ImageSelector.Items = CurrentGroup.ImageNames;
            PODSData.Handles.ImageSelector.ItemsData = [1:CurrentGroup.nReplicates];
            PODSData.Handles.ImageSelector.Value = CurrentGroup.CurrentImageIndex;
            % if the number of currently selected images is 1
            if length(Replicate) == 1
                % and at least one object has been detected
                if Replicate.nObjects >= 1
                    % enable/update object selection
                    PODSData.Handles.ObjectSelector.Enable = 1;
                    PODSData.Handles.ObjectSelector.Items = Replicate.ObjectNames;
                    PODSData.Handles.ObjectSelector.ItemsData = [1:length(Replicate.ObjectNames)];
                    PODSData.Handles.ObjectSelector.Value = Replicate.CurrentObjectIdx;
                else
                    PODSData.Handles.ObjectSelector.Items = {'No objects identified for this group...'};
                end
            % else, if there are no currently selected images
            elseif length(Replicate) == 0
                % disable object selection listbox, instruct user to select image
                PODSData.Handles.ObjectSelector.Items = {'Select an image...'};
                PODSData.Handles.ObjectSelector.Enable = 0;
            % else, if the number of currently selected images > 1   
            else
                % disable object selection listbox and indicate that too many images are selected
                PODSData.Handles.ObjectSelector.Items = {'Multiple images selected...'};
                PODSData.Handles.ObjectSelector.Enable = 0;
            end            
        else
            % disable image selection
            PODSData.Handles.ImageSelector.Enable = 0;
            PODSData.Handles.ImageSelector.Items = {'No images found...'};
            % disable object selection
            PODSData.Handles.ObjectSelector.Enable = 0;
            PODSData.Handles.ObjectSelector.Items = {'No image selected...'};
        end
    else
        % diable group selection
        PODSData.Handles.GroupSelector.Enable = 0;
        PODSData.Handles.GroupSelector.Items = {'No groups found...'};
        % disable image selection
        PODSData.Handles.ImageSelector.Enable = 0;
        PODSData.Handles.ImageSelector.Items = {'No group selected...'};
        % disable object selection
        PODSData.Handles.ObjectSelector.Enable = 0;
        PODSData.Handles.ObjectSelector.Items = {'No image selected...'};
    end
end