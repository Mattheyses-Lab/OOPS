% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function T = auxiliaryFileTable(project)
%AUXILIARYFILETABLE Build one row per image-to-source channel assignment.

n = 0;
for group = reshape(project.Groups,1,[])
    n = n+sum(arrayfun(@(image) numel(image.AuxiliaryChannels),group.Images));
end

groupIndex = nan(n,1); groupName = strings(n,1); groupID = strings(n,1);
imageIndex = nan(n,1); imageName = strings(n,1); imageID = strings(n,1);
assignmentIndex = nan(n,1); channelName = strings(n,1); channelID = strings(n,1);
componentIndex = nan(n,1); sourceChannel = strings(n,1); componentClass = strings(n,1);
fileName = strings(n,1); filePath = strings(n,1); series = nan(n,1);
sizeY = nan(n,1); sizeX = nan(n,1); sourceComponents = nan(n,1);
sizeZ = nan(n,1); sizeT = nan(n,1); displayMinimum = nan(n,1); displayMaximum = nan(n,1);

row = 0;
for g = 1:numel(project.Groups)
    group = project.Groups(g);
    for i = 1:numel(group.Images)
        image = group.Images(i);
        for a = 1:numel(image.AuxiliaryChannels)
            row = row+1;
            assignment = image.AuxiliaryChannels(a);
            component = assignment.Input.getComponent(assignment.ComponentIndex);
            definition = project.Channels.findByID(assignment.ChannelID);

            groupIndex(row) = g; groupName(row) = group.Name; groupID(row) = group.ID;
            imageIndex(row) = i; imageName(row) = image.Name; imageID(row) = image.ID;
            assignmentIndex(row) = a; channelID(row) = assignment.ChannelID;
            if ~isempty(definition), channelName(row) = definition.Name; end
            componentIndex(row) = assignment.ComponentIndex;
            sourceChannel(row) = component.Name; componentClass(row) = component.Class;
            [filePath(row),series(row)] = oops.export.sourceInfo(assignment.Input);
            [~,stem,extension] = fileparts(filePath(row)); fileName(row) = stem+extension;
            sizeY(row) = component.SizeY; sizeX(row) = component.SizeX;
            sourceComponents(row) = assignment.Input.NumComponents;
            sizeZ(row) = component.SizeZ; sizeT(row) = component.SizeT;
            if ~isempty(assignment.DisplayRange)
                displayMinimum(row) = assignment.DisplayRange(1);
                displayMaximum(row) = assignment.DisplayRange(2);
            end
        end
    end
end

T = table(groupIndex,groupName,groupID,imageIndex,imageName,imageID,assignmentIndex, ...
    channelName,channelID,componentIndex,sourceChannel,componentClass,fileName,filePath, ...
    series,sizeY,sizeX,sourceComponents,sizeZ,sizeT,displayMinimum,displayMaximum, ...
    'VariableNames',{'Group index','Group name','Group ID','Image index','Image name', ...
    'Image ID','Assignment index','Channel name','Channel ID','Component index', ...
    'Source channel','Component class','File name','File path','Series index','Size Y (px)', ...
    'Size X (px)','Source component count','Size Z','Size T', ...
    'Display minimum (A.U.)','Display maximum (A.U.)'});
end
