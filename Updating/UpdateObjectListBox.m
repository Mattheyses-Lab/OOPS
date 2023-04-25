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
            % % testing below - adding object label color icons to each list item
            % % first remove all styles
            % removeStyle(PODSData.Handles.ObjectSelector);
            % % preallocate our styles
            % objectIconStyles = matlab.ui.style.Style;
            % objectIconStyles = repmat(objectIconStyles,Replicate.nObjects,1);
            % % get label color icons for each object
            % labelColors = cell(Replicate.nObjects,1);
            % [labelColors{1:end,1}] = deal(Replicate.Object.LabelColorSquare);
            % % deal the icons into our preallocated styles array
            % [objectIconStyles(:).Icon] = deal([labelColors{1:end,1}]);
            % % add the styles to each list item
            % for i = 1:Replicate.nObjects
            %     addStyle(PODSData.Handles.ObjectSelector,objectIconStyles(i),'item',i);
            % end
            % % end testing
            return
        end
    end

    % if the above conditions are unmet, clear and disable the listbox
    PODSData.Handles.ObjectSelector.Items = {};
    PODSData.Handles.ObjectSelector.Enable = 0;

end