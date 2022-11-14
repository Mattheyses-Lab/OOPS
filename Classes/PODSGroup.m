classdef PODSGroup < handle
    % experimental groups class
    properties

        % handle to the PODS project containing this group
        Parent PODSProject

        % group info
        GroupName char        

        % replicates within group, no problem storing in memory (handle class)
        Replicate PODSImage
        
%         % this group's index (as child of PODSProject)
%         SelfGroupIndex

        % indexing group members (Replicate/PODSImage objects)
        CurrentImageIndex double
        PreviousImageIndex double
        
        % FFC info for group
        FFCData struct

        FFCLoaded = false
        FPMFilesLoaded = false
        
%         % output values
%         %OFAvg double
%         OFMax double
%         OFMin double
%         FiltOFAvg double
        
%         % status parameters
%         MaskAllDone = false
        
%         CoLocFilesLoaded = false
        
        % store handle to the master GUI settings
        Settings PODSSettings
        
        % group coloring
        Color double
        
    end
    
    properties (Dependent = true)
        
        % number of 'images' in this experimental group, depends on the size of obj.Replicate
        nReplicates uint8
        
        % total number of objects in this group, changes depending on user-defined mask
        TotalObjects uint16
        
        % Only the PODSImage objects will store their name in memory, combining them is quick
        ImageNames cell
        
        % currently selected image in GUI
        CurrentImage PODSImage
        
        % currently selected object - updates based on user selection
        CurrentObject PODSObject
        
        % don't want to store in memory for every group
        AllObjectData table

        FilteredObjectData table
        
        OFAllDone logical
        
        OFAvg double
        
        ColorString char

        SelfIdx
    
    end
    
    methods
        
        % class constructor method
        function obj = PODSGroup(GroupName,Settings,Project)
            if nargin > 0
                obj.GroupName = GroupName;
                obj.Settings = Settings;
                obj.Parent = Project;
            end
        end

        % destructor
        function delete(obj)
            % first delete obj.Replicate
            obj.deleteReplicates();
            % then delete this group
            delete(obj);
        end
        

        function group = saveobj(obj)

            disp('reached saveobj(Group)')

            %group.Parent = [];
            group.GroupName = obj.GroupName;
            group.CurrentImageIndex = obj.CurrentImageIndex;
            group.FFCData = obj.FFCData;
            group.FFCLoaded = obj.FFCLoaded;
            group.FPMFilesLoaded = obj.FPMFilesLoaded;
            group.Color = obj.Color;
            group.nReplicates = obj.nReplicates;

            for i = 1:obj.nReplicates
                disp('calling saveobj(Replicate)')
%                 group.Replicate(i) = saveobj(obj.Replicate(i));
                group.Replicate(i) = obj.Replicate(i).saveobj();
            end

        end

        function SelfIdx = get.SelfIdx(obj)
            SelfIdx = find(obj.Parent.Group==obj);
        end

        function deleteReplicates(obj)
            % collect and delete the objects in this image
            Replicates = obj.Replicate;
            delete(Replicates);
            % clear the placeholders
            clear Replicates
            % reinitialize the obj.Replicate vector
            obj.Replicate = PODSImage.empty();
%             % delete again? CHECK THIS
%             delete(obj.Replicate);
        end

        % delete seleted images from one PODSGroup based on obj.
        function DeleteSelectedImages(obj)
            
            % get handles to all images in this group
            AllReplicates = obj.Replicate;

            % initialize logical selection array to gather selected/unselected images
            Selected = false(obj.nReplicates,1);

            % set any elements to true if the corresponding images are selected
            Selected(obj.CurrentImageIndex) = true;

            % get list of 'good' objects (not selected)
            Good = AllReplicates(~[Selected]);
            
            % get list of objects to delete (selected)
            Bad = AllReplicates([Selected]);
            
            % replace image array of group with only the ones we wish to keep (not selected)
            obj.Replicate = Good;

            % in case current image idx is greater than the total # of images
            if obj.CurrentImageIndex(1) > obj.nReplicates
                % then select the last image in the list
                obj.CurrentImageIndex = obj.nReplicates;
            end
            
            % delete the bad PODSImage objects
            % set their pixel idxs to 0 in the mask
            for i = 1:length(Bad)
                delete(Bad(i));
            end
            % clear Bad array
            clear Bad
        end
            
        function nReplicates = get.nReplicates(obj)
            nReplicates = length(obj.Replicate);
        end
        
        function TotalObjects = get.TotalObjects(obj)
            TotalObjects = 0;
            for i = 1:obj.nReplicates
                TotalObjects = TotalObjects + obj.Replicate(i).nObjects;
            end
        end

        function DeleteSelectedObjects(obj)
            for i = 1:obj.nReplicates
                obj.Replicate(i).DeleteSelectedObjects()
            end
        end
        
        function LabelSelectedObjects(obj,Label)
            for i = 1:obj.nReplicates
                obj.Replicate(i).LabelSelectedObjects(Label)
            end            
        end
        
        function ClearSelection(obj)
            for i = 1:obj.nReplicates
                obj.Replicate(i).ClearSelection();
            end
        end
        
        function ImageNames = get.ImageNames(obj)
            % new cell array of image names
            ImageNames = {};
            [ImageNames{1:obj.nReplicates,1}] = obj.Replicate.pol_shortname;
        end  
        
        function CurrentImage = get.CurrentImage(obj)
            try
                CurrentImage = obj.Replicate(obj.CurrentImageIndex);
            catch
                CurrentImage = PODSImage.empty();
            end
        end
        
        function CurrentObject = get.CurrentObject(obj)
            cImage = obj.CurrentImage;
            CurrentObject = cImage.CurrentObject;
        end
        
        function ColorString = get.ColorString(obj)
%             ColorStringCell = colornames('MATLAB',obj.Color);
            ColorStringCell = colornames('MATLAB',obj.Color);
            ColorString = ColorStringCell{1};            
        end
        
        function OFAllDone = get.OFAllDone(obj)
            if obj.nReplicates == 0
                OFAllDone = false;
                return
            end
            
            for i = 1:obj.nReplicates
                if ~obj.Replicate(i).OFDone
                    OFAllDone = false;
                    return
                end
            end
            OFAllDone = true;
        end
           
        function OFAvg = get.OFAvg(obj)
            OFAvg = mean([obj.Replicate(find([obj.Replicate.OFDone])).OFAvg]);
        end

        % get x,y data for all objects in group, from first to last replicate
        %       WILL UPDATE TO ALLOW FOR varargin for more flexibility of use
        function ObjectData = CombineObjectData(obj,XVar,YVar)
            
            count = 0;
            last = 1;
            
            for i = 1:obj.nReplicates
                
                count = count + obj.Replicate(i).nObjects;
                % column 1 holds x data
                ObjectData(last:count,1) = [obj.Replicate(i).Object.(XVar)];
                % column 2 holds y data
                ObjectData(last:count,2) = [obj.Replicate(i).Object.(YVar)];
                
                last = count+1;
                
            end
        end % end of CombineObjectData()
        
        function VariableObjectData = GetAllObjectData(obj,Var2Get)
            % return a list of Var2Get for all objects in the group
            count = 0;
            last = 1;
            VariableObjectData = [];
            for i = 1:obj.nReplicates
                count = count + obj.Replicate(i).nObjects;
                % column 1 holds x data
                VariableObjectData(last:count,1) = [obj.Replicate(i).Object.(Var2Get)];
                last = count+1;
            end            
        end
        
        function ObjectDataByLabel = GetObjectDataByLabel(obj,Var2Get)
            
            nLabels = length(obj.Settings.ObjectLabels);
            
            % cell array of Object.(Var2Get), grouped by custom label
            %   single row of cells, each cell holds a vector of object data
            %   for a single label for all replicates in the group
            ObjectDataByLabel = cell(1,nLabels);
            
            for i = 1:obj.nReplicates
                % cell array of ObjectDataByLabel for one replicate
                % each cell is a vector of values for one label
                ReplicateObjectDataByLabel = obj.Replicate(i).GetObjectDataByLabel(Var2Get);
                
                for ii = 1:nLabels
                    ObjectDataByLabel{ii} = [ObjectDataByLabel{ii} ReplicateObjectDataByLabel{ii}];
                end

            end

        end

    
    end

    methods (Static)

        function obj = loadobj(group)

            obj = PODSGroup(group.GroupName,PODSSettings.empty(),PODSProject.empty());

            obj.CurrentImageIndex = group.CurrentImageIndex;
            obj.FFCData = group.FFCData;
            obj.FFCLoaded = group.FFCLoaded;
            obj.FPMFilesLoaded = group.FPMFilesLoaded;
            obj.Color = group.Color;

            % load each replicate
            for i = 1:group.nReplicates
                obj.Replicate(i) = PODSImage.loadobj(group.Replicate(i));
            end

        end
    end
end