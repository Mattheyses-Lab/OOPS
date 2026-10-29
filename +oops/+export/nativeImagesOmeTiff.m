% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function summary = nativeImagesOmeTiff(project,folder,opts)
%NATIVEIMAGESOMETIFF Export a validated native-resolution image manifest.

arguments
    project (1,1) oops.model.Project
    folder (1,1) string
    opts.AverageIntensity (1,1) logical = true
    opts.Mask (1,1) logical = true
    opts.Order (1,1) logical = true
    opts.Azimuth (1,1) logical = true
    opts.AuxiliaryIndividual (1,1) logical = true
    opts.AuxiliaryCombined (1,1) logical = true
    opts.ImageFolders (1,1) logical = false
    opts.EmbedLUTs (1,1) logical = true
    opts.ExistingFiles (1,1) string {mustBeMember(opts.ExistingFiles,["stop","overwrite","skip"])} = "stop"
    opts.Progress = []
end

if ~isfolder(folder)
    error('oops:export:FolderNotFound','Export folder does not exist: %s',folder);
end

manifest = oops.export.nativeImageManifest(project,folder, ...
    AverageIntensity=opts.AverageIntensity,Mask=opts.Mask, ...
    Order=opts.Order,Azimuth=opts.Azimuth, ...
    AuxiliaryIndividual=opts.AuxiliaryIndividual, ...
    AuxiliaryCombined=opts.AuxiliaryCombined,ImageFolders=opts.ImageFolders);

if isempty(manifest)
    error('oops:export:EmptyNativeManifest', ...
        'No available image products matched the selected export options.');
end

destinations = arrayfun(@(item) string(fullfile(folder,item.RelativePath)),manifest);
existing = isfile(destinations);
if any(existing) && opts.ExistingFiles == "stop"
    error('oops:export:FilesExist', ...
        '%d export destination(s) already exist. Choose overwrite or skip.',nnz(existing));
end

exported = 0;
skipped = 0;
for k = 1:numel(manifest)
    item = manifest(k);
    destination = string(fullfile(folder,item.RelativePath));
    fraction = (k-1)/numel(manifest);
    oops.runtime.updateProgress(opts.Progress,sprintf( ...
        'Exporting image %d of %d: %s — %s', ...
        k,numel(manifest),item.ImageName,item.Domain),fraction);

    if isfile(destination) && opts.ExistingFiles == "skip"
        skipped = skipped+1;
        oops.Log.INFO("Skipping existing image export: " + destination + ".");
        continue;
    end

    parent = string(fileparts(destination));
    if ~isfolder(parent), mkdir(parent); end

    oops.Log.INFO("Exporting native image: " + destination + ".");
    data = item.BuildFcn();
    cleanupData = onCleanup(@() deleteImage(data));
    embedLUTs = opts.EmbedLUTs && supportsEmbeddedLUTs(data);
    if opts.EmbedLUTs && ~embedLUTs
        oops.Log.DEBUG("Embedded LUT omitted for unsupported pixel class: " + ...
            destination + ". OME channel colors are still included.");
    end
    matlabx.image.io.writeOmeTiff(destination,data, ...
        Overwrite=opts.ExistingFiles=="overwrite", ...
        EmbedLUTs=embedLUTs,Creator="OOPS "+oops.Info.Version);
    clear cleanupData
    deleteImage(data);
    exported = exported+1;
end

oops.runtime.updateProgress(opts.Progress,"Native image export complete.",1);
summary = struct('Planned',numel(manifest),'Exported',exported,'Skipped',skipped);
end

function deleteImage(image)
if ~isempty(image) && isvalid(image), delete(image); end
end

function tf = supportsEmbeddedLUTs(image)
% Embedded TIFF LUTs are restricted by the MATLABX writer and TIFF format.
components = image.Components;
tf = all([components.IsScalar]) && ...
    all(ismember(string({components.Class}),["uint8","uint16","logical"]));
end
