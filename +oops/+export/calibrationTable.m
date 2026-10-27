% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function T = calibrationTable(project)
%CALIBRATIONTABLE Build one row per registered calibration source.
calibrations = project.Calibrations; n = numel(calibrations); index = (1:n)';
name = strings(n,1); id = strings(n,1); fileName = strings(n,1); filePath = strings(n,1); series = nan(n,1);
sizeY = nan(n,1); sizeX = nan(n,1); components = nan(n,1); sizeZ = nan(n,1); sizeT = nan(n,1);
groupCount = zeros(n,1); groups = strings(n,1);
for k = 1:n
    calibration = calibrations(k); name(k) = calibration.Name; id(k) = calibration.ID;
    [filePath(k),series(k)] = oops.export.sourceInfo(calibration.Input);
    [~,stem,extension] = fileparts(filePath(k)); fileName(k) = stem+extension;
    sizeY(k) = calibration.Input.SizeY; sizeX(k) = calibration.Input.SizeX;
    components(k) = calibration.Input.NumComponents; sizeZ(k) = calibration.Input.SizeZ;
    sizeT(k) = calibration.Input.SizeT;
    assigned = project.Groups(arrayfun( ...
        @(group) ismember(calibration.ID,group.CalibrationIDs),project.Groups));
    groupCount(k) = numel(assigned); groups(k) = strjoin(string({assigned.Name}),"; ");
end
T = table(index,name,id,fileName,filePath,series,sizeY,sizeX,components,sizeZ,sizeT, ...
    groupCount,groups,'VariableNames',{'Calibration index','Calibration name', ...
    'Calibration ID','File name','File path','Series index','Size Y (px)','Size X (px)','Components', ...
    'Size Z','Size T','Assigned group count','Assigned groups'});
end
