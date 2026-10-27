% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function T = objectTable(group)
%OBJECTTABLE Build one row per object in a group, including auxiliary means.
project = group.Parent;
measurementNames = oops.model.ObjectMeasurements.names();
channels = project.Channels.Channels; channels = channels([channels.IsAuxiliary]);
n = sum(arrayfun(@(image) numel(image.Objects),group.Images));
groupIndex = repmat(find(string({project.Groups.ID}) == group.ID,1),n,1);
groupName = repmat(group.Name,n,1); groupID = repmat(group.ID,n,1);
imageIndex = nan(n,1); imageName = strings(n,1); imageID = strings(n,1);
objectIndex = nan(n,1); objectName = strings(n,1); objectID = strings(n,1);
labelName = strings(n,1); labelID = strings(n,1); labelHotkey = strings(n,1);
labelRed = nan(n,1); labelGreen = nan(n,1); labelBlue = nan(n,1); pixelCount = nan(n,1);
measurements = nan(n,numel(measurementNames)); auxiliary = nan(n,numel(channels));
row = 0;
for i = 1:numel(group.Images)
    image = group.Images(i);
    for j = 1:numel(image.Objects)
        row = row+1; object = image.Objects(j);
        imageIndex(row) = i; imageName(row) = image.Name; imageID(row) = image.ID;
        objectIndex(row) = j; objectName(row) = object.Name; objectID(row) = object.ID;
        labelID(row) = object.LabelID;
        if isempty(object.Label)
            labelName(row) = object.LabelID;
        else
            labelName(row) = object.Label.Name;
            labelHotkey(row) = object.Label.Hotkey;
            labelRed(row) = object.Label.Color(1);
            labelGreen(row) = object.Label.Color(2);
            labelBlue(row) = object.Label.Color(3);
        end
        pixelCount(row) = numel(object.PixelIdxList);
        values = object.getMeasurements();
        for m = 1:numel(measurementNames)
            measurements(row,m) = values.(measurementNames(m));
        end
        for c = 1:numel(channels)
            auxiliary(row,c) = object.auxiliarySignalMean(channels(c).ID);
        end
    end
end
T = table(groupIndex,groupName,groupID,imageIndex,imageName,imageID,objectIndex, ...
    objectName,objectID,labelName,labelID,labelHotkey,labelRed,labelGreen,labelBlue, ...
    pixelCount,'VariableNames', ...
    {'Group index','Group name','Group ID','Image index','Image name','Image ID', ...
    'Object index','Object name','Object ID','Label','Label ID','Label hotkey', ...
    'Label red','Label green','Label blue','Pixel count'});
for m = 1:numel(measurementNames)
    T.(char(measurementNames(m))) = measurements(:,m);
end
auxiliaryNames = strings(1,numel(channels));
auxiliaryLabels = strings(1,numel(channels));
for c = 1:numel(channels)
    auxiliaryNames(c) = oops.model.ObjectMeasurements.auxiliaryName(channels(c).ID);
    auxiliaryLabels(c) = channels(c).Name+" signal mean (A.U.)";
    T.(char(auxiliaryNames(c))) = auxiliary(:,c);
end
identityCount = 16;
labels = [string(T.Properties.VariableNames(1:identityCount)), ...
    oops.model.ObjectMeasurements.exportLabels(measurementNames),auxiliaryLabels];
T.Properties.VariableNames = cellstr(labels);
end
