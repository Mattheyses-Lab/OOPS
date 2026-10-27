% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function T = imageTable(project)
%IMAGETABLE Build the group-ordered, image-ordered project image summary.
n = sum(arrayfun(@(group) numel(group.Images),project.Groups));
groupIndex = nan(n,1); groupName = strings(n,1); groupID = strings(n,1);
imageIndex = nan(n,1); imageName = strings(n,1); imageID = strings(n,1);
fileName = strings(n,1); filePath = strings(n,1); series = nan(n,1); sizeY = nan(n,1); sizeX = nan(n,1);
components = nan(n,1); sizeZ = nan(n,1); sizeT = nan(n,1);
pixelSizeX = nan(n,1); pixelSizeY = nan(n,1); unitX = strings(n,1); unitY = strings(n,1);
primaryName = strings(n,1); primaryID = strings(n,1);
calibrationNames = strings(n,1); calibrationIDs = strings(n,1);
objectCount = zeros(n,1); auxiliaryCount = zeros(n,1);
auxiliaryNames = strings(n,1); auxiliaryIDs = strings(n,1); auxiliaryFiles = strings(n,1);
correctionAlgorithm = strings(n,1); maskMethod = strings(n,1); polarizationAlgorithm = strings(n,1);
averageAvailable = false(n,1); maskAvailable = false(n,1); orderAvailable = false(n,1); azimuthAvailable = false(n,1);
row = 0;
for g = 1:numel(project.Groups)
    group = project.Groups(g); calibrations = group.Calibrations;
    for i = 1:numel(group.Images)
        row = row+1; image = group.Images(i);
        groupIndex(row) = g; groupName(row) = group.Name; groupID(row) = group.ID;
        imageIndex(row) = i; imageName(row) = image.Name; imageID(row) = image.ID;
        [filePath(row),series(row)] = oops.export.sourceInfo(image.Input);
        [~,stem,extension] = fileparts(filePath(row)); fileName(row) = stem+extension;
        sizeY(row) = image.Input.SizeY; sizeX(row) = image.Input.SizeX;
        components(row) = image.Input.NumComponents; sizeZ(row) = image.Input.SizeZ; sizeT(row) = image.Input.SizeT;
        pixelSizeX(row) = image.PixelSize.X; pixelSizeY(row) = image.PixelSize.Y;
        unitX(row) = image.PixelSize.UnitX; unitY(row) = image.PixelSize.UnitY;
        primaryID(row) = image.PrimaryChannelID;
        if ~isempty(image.PrimaryChannel), primaryName(row) = image.PrimaryChannel.Name; end
        calibrationIDs(row) = strjoin(group.CalibrationIDs,"; ");
        calibrationNames(row) = strjoin(string({calibrations.Name}),"; ");
        objectCount(row) = numel(image.Objects); auxiliaryCount(row) = numel(image.AuxiliaryChannels);
        assignments = image.AuxiliaryChannels;
        names = strings(1,numel(assignments)); ids = strings(1,numel(assignments));
        files = strings(1,numel(assignments));
        for a = 1:numel(assignments)
            ids(a) = assignments(a).ChannelID;
            definition = project.Channels.findByID(ids(a));
            if ~isempty(definition), names(a) = definition.Name; end
            [files(a),~] = oops.export.sourceInfo(assignments(a).Input);
        end
        auxiliaryNames(row) = strjoin(names,"; ");
        auxiliaryIDs(row) = strjoin(ids,"; ");
        auxiliaryFiles(row) = strjoin(files,"; ");
        correctionAlgorithm(row) = image.CorrectionProvenance.Algorithm;
        maskMethod(row) = image.MaskProvenance.Method;
        polarizationAlgorithm(row) = image.PolarizationProvenance.Algorithm;
        averageAvailable(row) = isfield(image.Results,'AverageIntensity') && ~isempty(image.Results.AverageIntensity);
        maskAvailable(row) = ~isempty(image.Mask); orderAvailable(row) = ~isempty(image.Order);
        azimuthAvailable(row) = ~isempty(image.Azimuth);
    end
end
T = table(groupIndex,groupName,groupID,imageIndex,imageName,imageID,fileName,filePath,series, ...
    sizeY,sizeX,components,sizeZ,sizeT,pixelSizeX,pixelSizeY,unitX,unitY, ...
    primaryName,primaryID,calibrationNames,calibrationIDs,objectCount,auxiliaryCount, ...
    auxiliaryNames,auxiliaryIDs,auxiliaryFiles, ...
    correctionAlgorithm,maskMethod,polarizationAlgorithm,averageAvailable,maskAvailable, ...
    orderAvailable,azimuthAvailable,'VariableNames',{'Group index','Group name','Group ID', ...
    'Image index','Image name','Image ID','File name','File path','Series index','Size Y (px)','Size X (px)', ...
    'Components','Size Z','Size T','Pixel size X','Pixel size Y','Pixel unit X', ...
    'Pixel unit Y','Primary channel','Primary channel ID','Calibrations','Calibration IDs', ...
    'Object count','Auxiliary channel count','Auxiliary channels','Auxiliary channel IDs', ...
    'Auxiliary files','Correction algorithm','Mask method', ...
    'Polarization algorithm','Average intensity available','Mask available', ...
    'Order available','Azimuth available'});
end
