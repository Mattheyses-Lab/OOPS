 classdef OOPSGroup < handle
    % experimental groups class
    properties

        % handle to the OOPSProject containing this group
        Parent OOPSProject

        % the user-defined name of this group
        GroupName char        

        % array of handles to the OOPSImages in this group
        Replicate OOPSImage

        % indexing group members (Replicate/OOPSImage objects)
        CurrentImageIndex double
        PreviousImageIndex double
        
        % FFC info for group
        FFCLoaded = false

        FFC_cal_shortname
        FFC_cal_fullname
        FFC_cal_norm
        FFC_Height
        FFC_Width

        FPMFilesLoaded = false
        
        % group color for plots, etc.
        Color double
        
    end
    
    properties (Dependent = true)
        
        % number of 'images' in this group, depends on the size of obj.Replicate
        nReplicates uint8
        
        % total number of objects in this group, changes depending on user-defined mask
        TotalObjects uint16
        
        % Only the OOPSImage objects will store their name in memory, combining them is quick
        ImageNames cell
        
        % currently selected image in GUI
        CurrentImage OOPSImage
        
        % currently selected object - updates based on user selection
        CurrentObject OOPSObject
        
        % don't want to store in memory for every group
        AllObjectData table

        FilteredObjectData table
        
        % status tracking for the group
        MaskAllDone logical
        OFAllDone logical
        FPMStatsAllDone logical
        FFCAllDone logical
        ObjectDetectionAllDone logical
        LocalSBAllDone logical
        
        % pixel-average OF for all images in this OOPSGroup for which OF has been calculated
        OFAvg double
        
        % name of the color of this OOPSGroup
        ColorString char

        % index of this OOPSGroup in [obj.Parent.Group(:)]
        SelfIdx

        % quick access to project settings
        Settings OOPSSettings

        GroupSummaryDisplayTable table

        % nImages x nLabels array of the number of objects with each label in this group
        labelCounts double

        % array of all objects in this group
        allObjects
    
    end
    
    methods
        
        % constructor
        function obj = OOPSGroup(GroupName,Project)
            if nargin > 0
                obj.GroupName = GroupName;
                %obj.Settings = Settings;
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
        
        % saveobj method
        function group = saveobj(obj)

            disp(['Saving OOPSGroup: ',obj.GroupName])

            group.GroupName = obj.GroupName;
            group.CurrentImageIndex = obj.CurrentImageIndex;
            
            group.FFCLoaded = obj.FFCLoaded;

            if group.FFCLoaded
                group.FFC_cal_shortname = obj.FFC_cal_shortname;
                group.FFC_cal_fullname = obj.FFC_cal_fullname;
                group.FFC_Height = obj.FFC_Height;
                group.FFC_Width = obj.FFC_Width;
            else
                group.FFC_cal_shortname = [];
                group.FFC_cal_fullname = [];
                group.FFC_Height = obj.FFC_Height;
                group.FFC_Width = obj.FFC_Width;
            end

            group.FPMFilesLoaded = obj.FPMFilesLoaded;
            group.Color = obj.Color;
            group.nReplicates = obj.nReplicates;

            for i = 1:obj.nReplicates
                disp(['Saving OOPSImage: ',obj.Replicate(i).rawFPMShortName])
%                 group.Replicate(i) = saveobj(obj.Replicate(i));
                group.Replicate(i) = obj.Replicate(i).saveobj();
            end

        end

        % self indexing
        function SelfIdx = get.SelfIdx(obj)
            SelfIdx = find(obj.Parent.Group==obj);
        end

%% settings

        function Settings = get.Settings(obj)
            try
                Settings = obj.Parent.Settings;
            catch
                Settings = OOPSSettings.empty();
            end
        end

        function updateMaskSchemes(obj)
            for i = 1:obj.nReplicates
                obj.Replicate(i).updateMaskSchemes();
            end
        end

%% manipulate objects

        function Objects = getObjectsByLabel(obj,Label)

            ObjsFound = 0;
            Objects = OOPSObject.empty();

            if obj.nReplicates>=1
                for i = 1:obj.nReplicates
                    TotalObjsCounted = numel(Objects);
                    tempObjects = obj.Replicate(i).getObjectsByLabel(Label);
                    ObjsFound = numel(tempObjects);
                    Objects(TotalObjsCounted+1:TotalObjsCounted+ObjsFound,1) = tempObjects;
                end
            else
                Objects = [];
            end

        end

        function allObjects = get.allObjects(obj)
            allObjects = [];
            for i = 1:obj.nReplicates
                allObjects = [allObjects, obj.Replicate(i).Object];
            end
        end

        % apply OOPSLabel:Label to all selected objects in this OOPSGroup
        function LabelSelectedObjects(obj,Label)
            for i = 1:obj.nReplicates
                obj.Replicate(i).LabelSelectedObjects(Label);
            end
        end

        function DeleteSelectedObjects(obj)
            for i = 1:obj.nReplicates
                obj.Replicate(i).DeleteSelectedObjects();
            end
        end

        function DeleteObjectsByLabel(obj,Label)
            for i = 1:obj.nReplicates
                obj.Replicate(i).DeleteObjectsByLabel(Label);
            end
        end

        % clear selection status of all objects in this group
        function ClearSelection(obj)
            for i = 1:obj.nReplicates
                obj.Replicate(i).ClearSelection();
            end
        end

%% retrieve object data

        function TotalObjects = get.TotalObjects(obj)
            TotalObjects = 0;
            for i = 1:obj.nReplicates
                TotalObjects = TotalObjects + obj.Replicate(i).nObjects;
            end
        end

        function CurrentObject = get.CurrentObject(obj)
            cImage = obj.CurrentImage;
            if ~isempty(cImage)
                CurrentObject = cImage(1).CurrentObject;
            else
                CurrentObject = OOPSObject.empty();
            end
        end

        % get array of [XVar,YVar] data for all objects in group
        function ObjectData = CombineObjectData(obj,XVar,YVar)
            
            count = 0;
            last = 1;

            % test below
            ObjectData = [];
            % end test
            
            for i = 1:obj.nReplicates
                
                count = count + obj.Replicate(i).nObjects;

                % get XData and YData
                XData = obj.Replicate(i).GetAllObjectData(XVar);
                YData = obj.Replicate(i).GetAllObjectData(YVar);

                % column 1 holds x data
                ObjectData(last:count,1) = XData;
                % column 2 holds y data
                ObjectData(last:count,2) = YData;


                % % column 1 holds x data
                % ObjectData(last:count,1) = [obj.Replicate(i).Object.(XVar)];
                % % column 2 holds y data
                % ObjectData(last:count,2) = [obj.Replicate(i).Object.(YVar)];
                
                last = count+1;
                
            end
        end
        
        % return a list of Var2Get for all objects in the group
        function VariableObjectData = GetAllObjectData(obj,Var2Get)
            
            % return if no images exist
            if obj.nReplicates == 0
                VariableObjectData = [];
                return
            end

            count = 0;
            last = 1;
            % line below causes issues with categorical data
            %VariableObjectData = [];
            for i = 1:obj.nReplicates
                count = count + obj.Replicate(i).nObjects;
                
                objectData = obj.Replicate(i).GetAllObjectData(Var2Get);
                VariableObjectData(last:count,1) = objectData;

                % VariableObjectData(last:count,1) = [obj.Replicate(i).Object.(Var2Get)];
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

%% manipulate images

        function deleteReplicates(obj)
            % collect and delete the images in this group
            Replicates = obj.Replicate;
            delete(Replicates);
            % clear the placeholders
            clear Replicates
            % reinitialize the obj.Replicate vector
            obj.Replicate = OOPSImage.empty();
        end

        % delete images from this OOPSGroup based on selection status in GUI
        function DeleteSelectedImages(obj)
            % get handles to all images in this group
            AllReplicates = obj.Replicate;
            % initialize logical selection array to gather selected/unselected images
            Selected = false(obj.nReplicates,1);
            % set any elements to true if the corresponding images are selected
            Selected(obj.CurrentImageIndex) = true;
            % get list of 'good' objects (not selected)
            Good = AllReplicates(~Selected);
            % get list of objects to delete (selected)
            Bad = AllReplicates(Selected);
            % replace image array of group with only the ones we wish to keep (not selected)
            obj.Replicate = Good;
            % in case current image idx is greater than the total # of images
            if obj.CurrentImageIndex(1) > obj.nReplicates
                % then select the last image in the list
                obj.CurrentImageIndex = obj.nReplicates;
            end
            % delete the bad OOPSImage objects
            % set their pixel idxs to 0 in the mask
            for i = 1:length(Bad)
                delete(Bad(i));
            end
            % clear Bad array
            clear Bad
        end

%% retrieve image data

        function nReplicates = get.nReplicates(obj)
            if isvalid(obj.Replicate)
                nReplicates = length(obj.Replicate);
            else
                nReplicates = 0;
            end
        end

        function ImageNames = get.ImageNames(obj)
            % new cell array of image names
            ImageNames = {};
            [ImageNames{1:obj.nReplicates,1}] = obj.Replicate.rawFPMShortName;
        end  
        
        function CurrentImage = get.CurrentImage(obj)
            try
                CurrentImage = obj.Replicate(obj.CurrentImageIndex);
            catch
                CurrentImage = OOPSImage.empty();
            end
        end
        
%% group status tracking

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

        function FPMStatsAllDone = get.FPMStatsAllDone(obj)
            if obj.nReplicates == 0
                FPMStatsAllDone = false;
                return
            end
            
            for i = 1:obj.nReplicates
                if ~obj.Replicate(i).CustomFPMStatsDone
                    FPMStatsAllDone = false;
                    return
                end
            end

            FPMStatsAllDone = true;
        end

        function MaskAllDone = get.MaskAllDone(obj)
            if obj.nReplicates == 0
                MaskAllDone = false;
                return
            end
            
            for i = 1:obj.nReplicates
                if ~obj.Replicate(i).MaskDone
                    MaskAllDone = false;
                    return
                end
            end
            MaskAllDone = true;
        end

        function FFCAllDone = get.FFCAllDone(obj)
            if obj.nReplicates == 0
                FFCAllDone = false;
                return
            end
            
            for i = 1:obj.nReplicates
                if ~obj.Replicate(i).FFCDone
                    FFCAllDone = false;
                    return
                end
            end
            FFCAllDone = true;
        end

        function ObjectDetectionAllDone = get.ObjectDetectionAllDone(obj)
            if obj.nReplicates == 0
                ObjectDetectionAllDone = false;
                return
            end
            
            for i = 1:obj.nReplicates
                if ~obj.Replicate(i).ObjectDetectionDone
                    ObjectDetectionAllDone = false;
                    return
                end
            end
            ObjectDetectionAllDone = true;
        end

        function LocalSBAllDone = get.LocalSBAllDone(obj)
            if obj.nReplicates == 0
                LocalSBAllDone = false;
                return
            end
            
            for i = 1:obj.nReplicates
                if ~obj.Replicate(i).LocalSBDone
                    LocalSBAllDone = false;
                    return
                end
            end
            LocalSBAllDone = true;
        end

%% retrieve group data

        function OFAvg = get.OFAvg(obj)
            OFAvg = mean([obj.Replicate(find([obj.Replicate.OFDone])).OFAvg]);
        end

        function GroupSummaryDisplayTable = get.GroupSummaryDisplayTable(obj)
            varNames = [...
                "FFC files loaded",...
                "FPM files loaded",...
                "Number of replicates",...
                "Mean pixel OF",...
                "Total objects",...
                "FFC performed",...
                "Mask generated",...
                "OF/azimuth calculated",...
                "Objects detected",...
                "Local S/B calculated"];

            GroupSummaryDisplayTable = table(...
                {obj.FFCLoaded},...
                {obj.FPMFilesLoaded},...
                {obj.nReplicates},...
                {obj.OFAvg},...
                {obj.TotalObjects},...
                {obj.FFCAllDone},...
                {obj.MaskAllDone},...
                {obj.OFAllDone},...
                {obj.ObjectDetectionAllDone},...
                {obj.LocalSBAllDone},...
                'VariableNames',varNames,...
                'RowNames',"Group");

            GroupSummaryDisplayTable = rows2vars(GroupSummaryDisplayTable,"VariableNamingRule","preserve");

            GroupSummaryDisplayTable.Properties.RowNames = varNames;
        end

        function labelCounts = get.labelCounts(obj)
            % preallocate our array of label counts
            labelCounts = zeros(obj.nReplicates,obj.Settings.nLabels);
            % get the counts for each group in the project
            for iIdx = 1:obj.nReplicates
                % get the label counts by summing the label counts for each image
                labelCounts(iIdx,:) = sum(obj.Replicate(iIdx).labelCounts,1);
            end
        end

        function ColorString = get.ColorString(obj)
            ColorStringCell = colornames('MATLAB',obj.Color);
            ColorString = ColorStringCell{1};         
        end

    end

    methods (Static)

        function obj = loadobj(group)

            %obj = OOPSGroup(group.GroupName,OOPSProject.empty());
            obj = OOPSGroup(group.GroupName,group.Parent);

            obj.CurrentImageIndex = group.CurrentImageIndex;

            obj.FFCLoaded = group.FFCLoaded;

%% IN DEVELOPMENT

            % get FFCData if the files were loaded into the project, otherwise 'simulate'
            if obj.FFCLoaded
                % get the 'short' filename (without path and extension)
                FFC_cal_shortname = group.FFC_cal_shortname;
                % get the 'full' filename (with path and extension)
                FFC_cal_fullname = group.FFC_cal_fullname;

                % get other relevant parameters
                nFFCFiles = numel(group.FFC_cal_shortname);

                for i=1:nFFCFiles

                    fullFilename = char(FFC_cal_fullname{i,1});

                    % throw an error if file does not exist
                    if ~isfile(fullFilename)
                        error('OOPSGroup:fileNotFound',...
                            ['Unable to load file: ',fullFilename,'\nMake sure the file is in the location shown above.'])
                    end

                    % open the image with bioformats
                    bfData = bfopen(fullFilename);
                    % get the image info (pixel values and filename) from the first element of the bf cell array
                    imageInfo = bfData{1,1};

                    % make sure this is a 4-image stack
                    nSlices = length(imageInfo(:,1));

                    if nSlices ~= 4
                        error('LoadFFCData:incorrectSize', ...
                            ['Error while loading ', ...
                            FFC_cal_fullname{i,1}, ...
                            '\nFile must be a stack of four images'])
                    end

                    % from the bfdata cell array of image data, concatenate slices along 3rd dim and convert to matrix
                    rawFFCStack = cell2mat(reshape(imageInfo(1:4,1),1,1,4));

                    % get the range of values in the input stack using its class
                    rawFFCRange = getrangefromclass(rawFFCStack);

                    % if this is this first file
                    if i == 1
                        % get the height and width of the input stack
                        [Height,Width] = size(rawFFCStack,[1 2]);
                        % preallocate the 4D matrix which will hold the FFC stacks
                        rawFFCStacks = zeros(Height,Width,4,nFFCFiles);
                    else
                        % throw error if dimensions of this image stack do not match those of the first one
                        assert(size(rawFFCStack,1)==Height,'Dimensions of FFC files do not match');
                        assert(size(rawFFCStack,2)==Width,'Dimensions of FFC files do not match');
                    end

                    % add this stack to our 4D array of stacks, convert to double with the same values
                    rawFFCStacks(:,:,:,i) = im2double(rawFFCStack).*rawFFCRange(2);
                end

                % add short and full filenames to this OOPSGroup
                obj.FFC_cal_shortname = FFC_cal_shortname;
                obj.FFC_cal_fullname = FFC_cal_fullname;
                % store height and width of the FFC files
                obj.FFC_Height = Height;
                obj.FFC_Width = Width;
                % average the raw input stacks along the fourth dimension
                FFC_cal_average = sum(rawFFCStacks,4)./nFFCFiles;
                % normalize to the maximum value across all pixels/images in the average stack
                obj.FFC_cal_norm = FFC_cal_average/max(FFC_cal_average,[],'all');
            else
                obj.FFC_cal_shortname = [];
                obj.FFC_cal_fullname = [];
                obj.FFC_Height = group.FFC_Height;
                obj.FFC_Width = group.FFC_Width;
                obj.FFC_cal_norm = ones(obj.FFC_Height,obj.FFC_Width,4);
            end

%% END IN DEVELOPMENT

            obj.FPMFilesLoaded = group.FPMFilesLoaded;
            obj.Color = group.Color;

            % for each replicate in group
            for i = 1:group.nReplicates
                % add group handle to the image struct
                group.Replicate(i).Parent = obj;
                % load the replicate
                obj.Replicate(i) = OOPSImage.loadobj(group.Replicate(i));

                if obj.Replicate(i).FFCDone
                    obj.Replicate(i).FlatFieldCorrection();
                end

                if obj.Replicate(i).OFDone
                    obj.Replicate(i).FindOrderFactor();
                end




            end

        end
    end
end