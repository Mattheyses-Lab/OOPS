function UpdateObjectTree(source)

    OOPSData = guidata(source);
    CurrentImage = OOPSData.CurrentImage;
    
%     if numel(CurrentImage)==1
%         % if we have at least one replicate
%         if CurrentImage.nObjects >= 1
%             % delete previous nodes
%             delete(OOPSData.Handles.ObjectTree.Children);
%             % make new nodes
%             for i = 1:CurrentImage.nObjects
%                 uitreenode(OOPSData.Handles.ObjectTree,...
%                     'Text',CurrentImage.Object(i).Name,...
%                     'NodeData',CurrentImage.Object(i));
%             end
%             drawnow
%             OOPSData.Handles.ObjectTree.SelectedNodes = OOPSData.Handles.ObjectTree.Children(CurrentImage.CurrentObjectIdx);
%         else
%             % make sure tree contains no nodes
%             delete(OOPSData.Handles.ObjectTree.Children);
%         end
%     else
%         % make sure tree contains no nodes
%         delete(OOPSData.Handles.ObjectTree.Children);
%     end


    
end