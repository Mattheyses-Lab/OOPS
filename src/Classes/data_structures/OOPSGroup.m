 classdef OOPSGroup < handle
% OOPSOBJECT  Group-level of OOPS data hierarchy
%
%   An instance of this class defines an individual Group
%   belonging to its parent OOPSProject.
%
%   See also OOPS, OOPSProject, OOPSImage, OOPSObject, OOPSSettings
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

    % experimental groups class
    properties

        % handle to the OOPSProject containing this group
        Parent OOPSProject
        % the user-defined name of this group
        GroupName char
        % array of handles to the OOPSImages in this group
        Replicate (:,1) OOPSImage
        % index to the currently selected image(s) in this group
        CurrentImageIndex double
        % index to the previously selected image(s) in this group
        PreviousImageIndex double
        % status flag indicating whether FFC stacks have been loaded for this group
        FFCLoaded = false
        % filenames without path and extension
        FFC_cal_shortname
        % filenames with patch and extension
        FFC_cal_fullname
        % averaged and normalized FFC stack
        FFC_cal_norm
        % height of the stack (rows) in pixels
        FFC_Height
        % width of the stack (columns) in pixels
        FFC_Width
        % status flag indicating whether FPM stacks have been loaded for this group
        FPMFilesLoaded = false
        % group color for plots, etc.
        Color double

    end
    
    properties (Dependent = true)
        
        % number of images/replicates in this group
        nReplicates uint8
        % total number of objects in this group
        TotalObjects uint16
        % cell array of names of each image in this group
        ImageNames cell
        % actively selected image(s) in this group
        CurrentImage OOPSImage
        % actively selected object(s) in this group
        CurrentObject OOPSObject
        % don't want to store in memory for every group
        AllObjectData table
        % status flag indicating whether the all images have been segmented
        MaskAllDone logical
        % status flag indicating whether FPM stats have been computed for all images
        FPMStatsAllDone logical
        % status flag indicating whether flat-field correction has been performed for all images
        FFCAllDone logical
        % status flag indicating whether objects have been detected for all images
        ObjectDetectionAllDone logical
        % status flag indicating whether local S/B has been detected for all images
        LocalSBAllDone logical
        % pixel-average Order for all images in this group for which FPM stats have been calculated
        OrderAvg double
        % name of the color of this OOPSGroup
        ColorString char
        % index of this group in its parent project
        SelfIdx
        % project-wide settings
        Settings OOPSSettings
        % table used to display 
        GroupSummaryDisplayTable table
        % summary of the objects found with each unique label
        labelCounts double
        % array of handles to all objects in this group
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

            %ObjsFound = 0;
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
            % allObjects = [];
            % for i = 1:obj.nReplicates
            %     allObjects = [allObjects, obj.Replicate(i).Object];
            % end

            allObjects = cat(1,obj.Replicate(:).Object);
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
            
            % total objects found so far
            count = 0;
            % the next starting idx as we add data from each image
            last = 1;
            % start with an empty array
            ObjectData = [];
            
            for i = 1:obj.nReplicates
                % add to the total count
                count = count + obj.Replicate(i).nObjects;
                % get XData
                XData = obj.Replicate(i).GetAllObjectData(XVar);
                % get YData
                YData = obj.Replicate(i).GetAllObjectData(YVar);
                % column 1 holds x data
                ObjectData(last:count,1) = XData;
                % column 2 holds y data
                ObjectData(last:count,2) = YData;
                % get the next starting idx
                last = count+1;
                % % column 1 holds x data
                % ObjectData(last:count,1) = [obj.Replicate(i).Object.(XVar)];
                % % column 2 holds y data
                % ObjectData(last:count,2) = [obj.Replicate(i).Object.(YVar)];
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
                    ObjectDataByLabel{ii} = [ObjectDataByLabel{ii}; ReplicateObjectDataByLabel{ii}];
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
            % get list of 'good' images (not selected)
            Good = AllReplicates(~Selected);
            % get list of images to delete (selected)
            Bad = AllReplicates(Selected);
            % replace image array of group with only the ones we wish to keep (not selected)
            obj.Replicate = Good;
            % in case current image idx is greater than the total # of images
            if obj.CurrentImageIndex(1) > obj.nReplicates
                % then select the last image in the list
                obj.CurrentImageIndex = obj.nReplicates;
            end
            % delete the bad OOPSImage objects
            for i = 1:length(Bad)
                delete(Bad(i));
            end
            % clear Bad array
            clear Bad
        end

%% retrieve image data

        function nReplicates = get.nReplicates(obj)
            if isvalid(obj.Replicate)
                nReplicates = numel(obj.Replicate);
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

        function FPMStatsAllDone = get.FPMStatsAllDone(obj)
            if obj.nReplicates == 0
                FPMStatsAllDone = false;
                return
            end
            
            for i = 1:obj.nReplicates
                if ~obj.Replicate(i).FPMStatsDone
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

        function OrderAvg = get.OrderAvg(obj)
            OrderAvg = mean([obj.Replicate(find([obj.Replicate.FPMStatsDone])).OrderAvg]);
        end

        function GroupSummaryDisplayTable = get.GroupSummaryDisplayTable(obj)
            % table row titles
            varNames = [...
                "Name",...
                "Total images",...
                "Total objects",...
                "FFC files loaded",...
                "FPM files loaded",...
                "FFC performed",...
                "Mask generated",...
                "FPM stats calculated",...
                "Objects detected",...
                "Local S/B calculated"];
            % table data
            GroupSummaryDisplayTable = table(...
                {obj.GroupName},...
                {obj.nReplicates},...
                {obj.TotalObjects},...
                {Logical2String(obj.FFCLoaded)},...
                {Logical2String(obj.FPMFilesLoaded)},...
                {Logical2String(obj.FFCAllDone)},...
                {Logical2String(obj.MaskAllDone)},...
                {Logical2String(obj.FPMStatsAllDone)},...
                {Logical2String(obj.ObjectDetectionAllDone)},...
                {Logical2String(obj.LocalSBAllDone)},...
                'VariableNames',varNames,...
                'RowNames',"Group");
            % convert rows to variables
            GroupSummaryDisplayTable = rows2vars(GroupSummaryDisplayTable,"VariableNamingRule","preserve");
            % reset row names
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

%% collect data for export

        function tableOut = objectDataTableForExport(obj)

            dataStruct = struct(...
                'GroupIdx',0,...
                'GroupName',[],...
                'ImageIdx',0,...
                'ImageName',[],...
                'ObjectIdx',0,...
                'Area',0,...
                'AzimuthAngularDeviation',0,...
                'AzimuthStd',0,...
                'Circularity',0,...
                'ConvexArea',0,...
                'Eccentricity',0,...
                'EquivDiameter',0,...
                'Extent',0,...
                'LabelName','',...
                'SBRatio',0,...
                'MajorAxisLength',0,...
                'MaxFeretDiameter',0,...
                'AzimuthAverage',0,...
                'MidlineRelativeAzimuth',0,...
                'NormalRelativeAzimuth',0,...
                'BGAverage',0,...
                'OrderAvg',0,...
                'SignalAverage',0,...
                'MidlineLength',0,...
                'MinFeretDiameter',0,...
                'MinorAxisLength',0,...
                'Perimeter',0,...
                'Solidity',0,...
                'Tortuosity',0);

            % get the custom stats
            customStats = obj.Settings.CustomStatisticNames;
            % the number of custom stats
            nCustomStats = numel(customStats);
            % add a field for each custom stat
            for statIdx = 1:numel(nCustomStats)
                dataStruct.(customStats{statIdx}) = 0;
            end

            MasterIdx = 1;
        
            for j = 1:obj.nReplicates
        
                for k = 1:obj.Replicate(j).nObjects
        
                    % get the object
                    thisObject = obj.Replicate(j).Object(k);
        
                    % add group, image, and object names/idxs to the table
                    dataStruct(MasterIdx).GroupIdx = obj.SelfIdx;
                    dataStruct(MasterIdx).GroupName = obj.GroupName;
                    dataStruct(MasterIdx).ImageIdx = j;
                    dataStruct(MasterIdx).ImageName = obj.Replicate(j).rawFPMShortName;
                    dataStruct(MasterIdx).ObjectIdx = k;
        
                    % add object data to the table for each built-in property
                    dataStruct(MasterIdx).Area = thisObject.Area;
                    dataStruct(MasterIdx).AzimuthAngularDeviation = thisObject.AzimuthAngularDeviation;
                    dataStruct(MasterIdx).AzimuthAverage = thisObject.AzimuthAverage;
                    dataStruct(MasterIdx).AzimuthStd = thisObject.AzimuthStd;
                    dataStruct(MasterIdx).BGAverage = thisObject.BGAverage;
                    dataStruct(MasterIdx).Circularity = thisObject.Circularity;
                    dataStruct(MasterIdx).ConvexArea = thisObject.ConvexArea;
                    dataStruct(MasterIdx).Eccentricity = thisObject.Eccentricity;
                    dataStruct(MasterIdx).EquivDiameter = thisObject.EquivDiameter;
                    dataStruct(MasterIdx).Extent = thisObject.Extent;
                    dataStruct(MasterIdx).LabelName = thisObject.LabelName;
                    dataStruct(MasterIdx).MajorAxisLength = thisObject.MajorAxisLength;
                    dataStruct(MasterIdx).MaxFeretDiameter = thisObject.MaxFeretDiameter;
                    dataStruct(MasterIdx).MidlineLength = thisObject.MidlineLength;
                    dataStruct(MasterIdx).MidlineRelativeAzimuth = thisObject.MidlineRelativeAzimuth;
                    dataStruct(MasterIdx).MinFeretDiameter = thisObject.MinFeretDiameter;
                    dataStruct(MasterIdx).MinorAxisLength = thisObject.MinorAxisLength;
                    dataStruct(MasterIdx).NormalRelativeAzimuth = thisObject.NormalRelativeAzimuth;
                    dataStruct(MasterIdx).OrderAvg = thisObject.OrderAvg;
                    dataStruct(MasterIdx).Perimeter = thisObject.Perimeter;
                    dataStruct(MasterIdx).SBRatio = thisObject.SBRatio;
                    dataStruct(MasterIdx).SignalAverage = thisObject.SignalAverage;
                    dataStruct(MasterIdx).Solidity = thisObject.Solidity;
                    dataStruct(MasterIdx).Tortuosity = thisObject.Tortuosity;

                    % add object data for each custom property
                    for statIdx = 1:numel(nCustomStats)
                        dataStruct(MasterIdx).(customStats{statIdx}) = thisObject.(customStats{statIdx});
                    end

                    MasterIdx = MasterIdx+1;
        
                end % end objects
        
            end % end images
        
            % convert struct to table
            tableOut = struct2table(dataStruct);

            % get current table variable names
            oldVarNames = tableOut.Properties.VariableNames;

            % get expanded names
            newVarNames = cellfun(@(x) obj.Settings.expandVariableName(x),oldVarNames,'UniformOutput',false);

            % rename variables in the table
            tableOut = renamevars(tableOut,oldVarNames,newVarNames);

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

                if obj.Replicate(i).FPMStatsDone
                    obj.Replicate(i).FindFPMStatistics();
                end




            end

        end
    end
end