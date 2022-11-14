function UpdateObjectTree(source)

    PODSData = guidata(source);
    CurrentImage = PODSData.CurrentImage;
    
%     if numel(CurrentImage)==1
%         % if we have at least one replicate
%         if CurrentImage.nObjects >= 1
%             % delete previous nodes
%             delete(PODSData.Handles.ObjectTree.Children);
%             % make new nodes
%             for i = 1:CurrentImage.nObjects
%                 uitreenode(PODSData.Handles.ObjectTree,...
%                     'Text',CurrentImage.Object(i).Name,...
%                     'NodeData',CurrentImage.Object(i));
%             end
%             drawnow
%             PODSData.Handles.ObjectTree.SelectedNodes = PODSData.Handles.ObjectTree.Children(CurrentImage.CurrentObjectIdx);
%         else
%             % make sure tree contains no nodes
%             delete(PODSData.Handles.ObjectTree.Children);
%         end
%     else
%         % make sure tree contains no nodes
%         delete(PODSData.Handles.ObjectTree.Children);
%     end


    
end