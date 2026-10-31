% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function manifest = imageManifest(project,folder,recipes,opts)
%IMAGEMANIFEST Build all image-export destinations before reading pixels.

arguments
    project (1,1) oops.model.Project
    folder (1,1) string
    recipes table
    opts.ImageFolders (1,1) logical = false
end

prototype = struct('GroupName',"",'ImageName',"",'Domain',"", ...
    'ChannelName',"",'Format',"",'RelativePath',"",'BuildFcn',[]);
manifest = repmat(prototype,0,1);

for r = 1:height(recipes)
    recipe = recipes(r,:);
    if recipe.Format == "ome-tiff"
        native = nativeEntries(project,folder,recipe.ImageType,opts.ImageFolders);
        for k = 1:numel(native)
            item = prototype;
            item.GroupName = native(k).GroupName;
            item.ImageName = native(k).ImageName;
            item.Domain = native(k).Domain;
            item.ChannelName = native(k).ChannelName;
            item.Format = "ome-tiff";
            item.RelativePath = native(k).RelativePath;
            item.BuildFcn = native(k).BuildFcn;
            manifest(end+1,1) = item; %#ok<AGROW>
        end
    else
        manifest = appendPngEntries(manifest,prototype,project,recipe,opts.ImageFolders);
    end
end

manifest = uniquifyPaths(manifest,folder);
end

function native = nativeEntries(project,folder,type,imageFolders)
flags = struct(AverageIntensity=false,Mask=false,Order=false,Azimuth=false, ...
    AuxiliaryIndividual=false,Channels=false);
switch type
    case "average-intensity", flags.AverageIntensity = true;
    case "mask", flags.Mask = true;
    case "order", flags.Order = true;
    case "azimuth", flags.Azimuth = true;
    case "auxiliary-individual", flags.AuxiliaryIndividual = true;
    case "channels", flags.Channels = true;
    otherwise
        error('oops:export:InvalidOmeRecipe', ...
            'Image type %s cannot be exported as OME-TIFF.',type);
end
native = oops.export.nativeImageManifest(project,folder, ...
    AverageIntensity=flags.AverageIntensity,Mask=flags.Mask,Order=flags.Order, ...
    Azimuth=flags.Azimuth,AuxiliaryIndividual=flags.AuxiliaryIndividual, ...
    Channels=flags.Channels,ImageFolders=imageFolders);
end

function manifest = appendPngEntries(manifest,prototype,project,recipe,imageFolders)
for group = reshape(project.Groups,1,[])
    for image = reshape(group.Images,1,[])
        if ~available(image,recipe.ImageType), continue; end
        base = safeName(image.Name,"image");
        parent = "";
        if imageFolders, parent = base; end
        suffix = recipeSuffix(recipe);

        if recipe.ImageType == "auxiliary-individual"
            assignments = orderedAssignments(image,project);
            for assignment = reshape(assignments,1,[])
                channel = project.Channels.findByID(assignment.ChannelID);
                channelName = safeName(channel.Name,"channel");
                item = prototype;
                item.GroupName = group.Name; item.ImageName = image.Name;
                item.Domain = "Auxiliary"; item.ChannelName = channel.Name;
                item.Format = "png";
                item.RelativePath = relativeFile(parent,base+"_auxiliary-"+ ...
                    channelName+suffix+".png");
                item.BuildFcn = @() oops.export.renderImage(image,"auxiliary", ...
                    recipe.Scaling,recipe.AutoMethod,project.Settings,assignment,channel);
                manifest(end+1,1) = item; %#ok<AGROW>
            end
        else
            item = prototype;
            item.GroupName = group.Name; item.ImageName = image.Name;
            item.Domain = displayName(recipe.ImageType); item.Format = "png";
            item.RelativePath = relativeFile(parent,base+"_"+recipe.ImageType+suffix+".png");
            item.BuildFcn = @() oops.export.renderImage(image,recipe.ImageType, ...
                recipe.Scaling,recipe.AutoMethod,project.Settings);
            manifest(end+1,1) = item; %#ok<AGROW>
        end
    end
end
end

function assignments = orderedAssignments(image,project)
%ORDEREDASSIGNMENTS Return assigned auxiliary channels in registry order.
assignments = oops.model.AuxiliaryChannelAssignment.empty(0,1);
definitions = project.Channels.Channels;
definitions = definitions([definitions.IsAuxiliary]);
for definition = reshape(definitions,1,[])
    assignment = image.getAuxiliaryChannel(definition.ID);
    if ~isempty(assignment), assignments(end+1,1) = assignment; end %#ok<AGROW>
end
end

function tf = available(image,type)
switch type
    case "mask", tf = ~isempty(image.Mask);
    case "order", tf = ~isempty(image.Order);
    case "azimuth", tf = ~isempty(image.Azimuth);
    case "auxiliary-individual", tf = ~isempty(image.AuxiliaryChannels);
    case "channels", tf = ~isempty(image.AuxiliaryChannels);
    case "intensity-weighted-order", tf = ~isempty(image.Order);
    case "intensity-weighted-azimuth", tf = ~isempty(image.Azimuth);
    case "azimuth-order-intensity-hsv"
        tf = ~isempty(image.Order) && ~isempty(image.Azimuth);
    otherwise, tf = true;
end
end

function suffix = recipeSuffix(recipe)
switch recipe.Scaling
    case "unscaled", suffix = "_unscaled";
    case "user", suffix = "_user-scaled";
    case "auto", suffix = "_auto-"+slug(recipe.AutoMethod);
end
end

function value = displayName(type)
value = replace(type,"-"," ");
value = upper(extractBefore(value,2))+extractAfter(value,1);
end

function value = slug(value)
value = lower(regexprep(string(value),'[^a-zA-Z0-9]+','-'));
value = strip(value,"both","-");
end

function path = relativeFile(parent,name)
if parent == "", path = name; else, path = string(fullfile(parent,name)); end
end

function name = safeName(value,fallback)
name = regexprep(strtrim(string(value)),'[<>:"/\\|?*\x00-\x1F]+','-');
name = regexprep(name,'\s+',' ');
name = regexprep(name,'^[ .-]+|[ .-]+$','');
if name == "", name = fallback; end
end

function manifest = uniquifyPaths(manifest,folder)
seen = strings(0,1);
for k = 1:numel(manifest)
    candidate = manifest(k).RelativePath;
    key = lower(candidate);
    if any(seen == key)
        [parent,stem,ext] = fileparts(candidate);
        group = safeName(manifest(k).GroupName,"group");
        candidate = string(fullfile(parent,group+"_"+string(stem)+string(ext)));
        key = lower(candidate); suffix = 2;
        while any(seen == key)
            candidate = string(fullfile(parent,group+"_"+string(stem)+ ...
                "-"+suffix+string(ext)));
            key = lower(candidate); suffix = suffix+1;
        end
    end
    manifest(k).RelativePath = candidate;
    seen(end+1,1) = key; %#ok<AGROW>
end
for k = 1:numel(manifest)
    destination = string(fullfile(folder,manifest(k).RelativePath));
    if ~startsWith(destination,string(folder)+filesep) && destination ~= folder
        error('oops:export:InvalidDestination','Invalid export destination: %s',destination);
    end
end
end
