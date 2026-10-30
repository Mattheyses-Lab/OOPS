% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function summary = images(project,folder,recipes,opts)
%IMAGES Export a validated recipe manifest as OME-TIFF and PNG files.

arguments
    project (1,1) oops.model.Project
    folder (1,1) string
    recipes table
    opts.ImageFolders (1,1) logical = false
    opts.EmbedLUTs (1,1) logical = true
    opts.ExistingFiles (1,1) string {mustBeMember(opts.ExistingFiles, ...
        ["stop","overwrite","skip"])} = "stop"
    opts.Progress = []
end

if ~isfolder(folder)
    error('oops:export:FolderNotFound','Export folder does not exist: %s',folder);
end
manifest = oops.export.imageManifest(project,folder,recipes, ...
    ImageFolders=opts.ImageFolders);
if isempty(manifest)
    error('oops:export:EmptyImageManifest', ...
        'No available image products matched the export recipes.');
end

destinations = arrayfun(@(item) string(fullfile(folder,item.RelativePath)),manifest);
existing = isfile(destinations);
if any(existing) && opts.ExistingFiles == "stop"
    error('oops:export:FilesExist', ...
        '%d export destination(s) already exist. Choose overwrite or skip.',nnz(existing));
end

exported = 0; skipped = 0;
for k = 1:numel(manifest)
    item = manifest(k);
    destination = string(fullfile(folder,item.RelativePath));
    oops.runtime.updateProgress(opts.Progress,sprintf( ...
        'Exporting image %d of %d: %s — %s', ...
        k,numel(manifest),item.ImageName,item.Domain),(k-1)/numel(manifest));
    if isfile(destination) && opts.ExistingFiles == "skip"
        skipped = skipped+1;
        oops.Log.INFO("Skipping existing image export: " + destination + ".");
        continue
    end
    parent = string(fileparts(destination));
    if ~isfolder(parent), mkdir(parent); end
    oops.Log.INFO("Exporting image: " + destination + ".");
    data = item.BuildFcn();
    if item.Format == "ome-tiff"
        cleanupData = onCleanup(@() deleteImage(data));
        embed = opts.EmbedLUTs && supportsEmbeddedLUTs(data);
        if opts.EmbedLUTs && ~embed
            oops.Log.DEBUG("Embedded LUT omitted for unsupported pixel class: " + ...
                destination + ". OME channel colors are still included.");
        end
        matlabx.image.io.writeOmeTiff(destination,data, ...
            Overwrite=opts.ExistingFiles=="overwrite",EmbedLUTs=embed, ...
            Creator="OOPS "+oops.Info.Version);
        clear cleanupData
        deleteImage(data);
    else
        if isfile(destination) && opts.ExistingFiles == "overwrite"
            delete(destination);
        end
        imwrite(im2uint8(data),destination,'png');
    end
    exported = exported+1;
end

oops.runtime.updateProgress(opts.Progress,"Image export complete.",1);
summary = struct(Planned=numel(manifest),Exported=exported,Skipped=skipped);
end

function deleteImage(image)
if ~isempty(image) && isvalid(image), delete(image); end
end

function tf = supportsEmbeddedLUTs(image)
components = image.Components;
tf = all([components.IsScalar]) && ...
    all(ismember(string({components.Class}),["uint8","uint16","logical"]));
end
