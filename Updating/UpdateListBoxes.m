function UpdateListBoxes(source)

%     OOPSData = guidata(source);
%     CurrentGroup = OOPSData.CurrentGroup;
%     Replicate = CurrentGroup.CurrentImage;
%     % if we have at least one group
%     if OOPSData.nGroups >= 1
%         % update/enable group selection listbox
%         OOPSData.Handles.GroupSelector.Enable = 1;
%         OOPSData.Handles.GroupSelector.Items = OOPSData.GroupNames;
%         OOPSData.Handles.GroupSelector.ItemsData = [1:OOPSData.nGroups];
%         OOPSData.Handles.Value = OOPSData.CurrentGroupIndex;
%         % if we have at least one replicate
%         if CurrentGroup.nReplicates >= 1
%             % update/enable image selection listbox
%             OOPSData.Handles.ImageSelector.Enable = 1;
%             OOPSData.Handles.ImageSelector.Items = CurrentGroup.ImageNames;
%             OOPSData.Handles.ImageSelector.ItemsData = [1:CurrentGroup.nReplicates];
%             OOPSData.Handles.ImageSelector.Value = CurrentGroup.CurrentImageIndex;
%             % if the number of currently selected images is 1
%             if length(Replicate) == 1
%                 % and at least one object has been detected
%                 if Replicate.nObjects >= 1
%                     % enable/update object selection
%                     OOPSData.Handles.ObjectSelector.Enable = 1;
%                     OOPSData.Handles.ObjectSelector.Items = Replicate.ObjectNames;
%                     OOPSData.Handles.ObjectSelector.ItemsData = 1:length(Replicate.ObjectNames);
%                     OOPSData.Handles.ObjectSelector.Value = Replicate.CurrentObjectIdx;
%                     scroll(OOPSData.Handles.ObjectSelector,OOPSData.Handles.ObjectSelector.Value);
%                 else
%                     OOPSData.Handles.ObjectSelector.Items = {'No objects identified for this group...'};
%                 end
%             % else, if there are no currently selected images
%             elseif isempty(Replicate)
%                 % disable object selection listbox, instruct user to select image
%                 OOPSData.Handles.ObjectSelector.Items = {'Select an image...'};
%                 OOPSData.Handles.ObjectSelector.Enable = 0;
%             % else, if the number of currently selected images > 1   
%             else
%                 % disable object selection listbox and indicate that too many images are selected
%                 OOPSData.Handles.ObjectSelector.Items = {'Multiple images selected...'};
%                 OOPSData.Handles.ObjectSelector.Enable = 0;
%             end            
%         else
%             % disable image selection
%             OOPSData.Handles.ImageSelector.Enable = 0;
%             OOPSData.Handles.ImageSelector.Items = {'No images found...'};
%             % disable object selection
%             OOPSData.Handles.ObjectSelector.Enable = 0;
%             OOPSData.Handles.ObjectSelector.Items = {'No image selected...'};
%         end
%     else
%         % diable group selection
%         OOPSData.Handles.GroupSelector.Enable = 0;
%         OOPSData.Handles.GroupSelector.Items = {'No groups found...'};
%         % disable image selection
%         OOPSData.Handles.ImageSelector.Enable = 0;
%         OOPSData.Handles.ImageSelector.Items = {'No group selected...'};
%         % disable object selection
%         OOPSData.Handles.ObjectSelector.Enable = 0;
%         OOPSData.Handles.ObjectSelector.Items = {'No image selected...'};
%     end
end