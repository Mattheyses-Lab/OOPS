% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function status = cacheStatus(project)
%CACHESTATUS Describe disposable buffers and resident model analysis arrays.

arguments
    project (1,1) oops.model.Project
end

% Flatten project membership while preserving group identity for display.
groups = strings(0,1);
images = oops.model.Image.empty(0,1);

for group = reshape(project.Groups,1,[])
    images = [images;group.Images]; %#ok<AGROW>
    groups = [groups;repmat(group.Name,numel(group.Images),1)]; %#ok<AGROW>
end

n = numel(images);
Image = strings(n,1);
RawLoaded = false(n,1);
RawMiB = zeros(n,1);
CorrectedCached = false(n,1);
CorrectedMiB = zeros(n,1);
AverageMiB = zeros(n,1);
EnhancedMiB = zeros(n,1);
MaskMiB = zeros(n,1);
OrderMiB = zeros(n,1);
AzimuthMiB = zeros(n,1);
AuxiliarySourcesLoaded = zeros(n,1);
AuxiliaryMiB = zeros(n,1);

% Inspect each image without loading any source or reconstructing any output.
for k = 1:n
    image = images(k);
    Image(k) = image.Name;
    RawLoaded(k) = image.IsLoaded;

    if RawLoaded(k)
        RawMiB(k) = oops.runtime.CacheManager.imageBytes(image.Input)/(1024^2);
    end

    CorrectedCached(k) = project.CacheManager.hasCorrected(image.ID);
    CorrectedMiB(k) = project.CacheManager.correctedBytes(image.ID)/(1024^2);

    if isfield(image.Results,'AverageIntensity')
        AverageMiB(k) = arrayMiB(image.Results.AverageIntensity);
    end

    if isfield(image.Results,'Segmentation') && ...
            isfield(image.Results.Segmentation,'Enhanced')
        EnhancedMiB(k) = arrayMiB(image.Results.Segmentation.Enhanced);
    end

    MaskMiB(k) = arrayMiB(image.Mask);
    OrderMiB(k) = arrayMiB(image.Order);
    AzimuthMiB(k) = arrayMiB(image.Azimuth);

    for assignment = reshape(image.AuxiliaryChannels,1,[])

        if assignment.Input.IsLoaded
            AuxiliarySourcesLoaded(k) = AuxiliarySourcesLoaded(k)+1;
            AuxiliaryMiB(k) = AuxiliaryMiB(k)+ ...
                oops.runtime.CacheManager.imageBytes(assignment.Input)/(1024^2);
        end

    end
end

TotalMiB = RawMiB+CorrectedMiB+AverageMiB+EnhancedMiB+MaskMiB+ ...
    OrderMiB+AzimuthMiB+AuxiliaryMiB;

status = struct( ...
    'Cache',project.CacheManager.summary(), ...
    'Images',table(groups,Image,RawLoaded,RawMiB,CorrectedCached,CorrectedMiB, ...
        AverageMiB,EnhancedMiB,MaskMiB,OrderMiB,AzimuthMiB, ...
        AuxiliarySourcesLoaded,AuxiliaryMiB,TotalMiB, ...
        'VariableNames',{'Group','Image','RawLoaded','RawMiB', ...
        'CorrectedCached','CorrectedMiB','AverageMiB','EnhancedMiB', ...
        'MaskMiB','OrderMiB','AzimuthMiB','AuxiliarySourcesLoaded', ...
        'AuxiliaryMiB','TotalMiB'}), ...
    'Calibrations',project.CacheManager.calibrationStatus());
end

function value = arrayMiB(data)
%ARRAYMIB Return storage for one model-owned array in mebibytes.

if isempty(data)
    value = 0;
    return;
end

value = oops.runtime.CacheManager.valueBytes(data)/(1024^2);
end
