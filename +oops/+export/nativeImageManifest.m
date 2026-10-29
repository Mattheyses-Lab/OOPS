% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function manifest = nativeImageManifest(project,folder,opts)
%NATIVEIMAGEMANIFEST Describe native-resolution OME-TIFF outputs before writing.

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
end

entry = struct('GroupName',"",'ImageName',"",'Domain',"", ...
    'ChannelName',"",'RelativePath',"",'BuildFcn',[]);
manifest = repmat(entry,0,1);

for group = reshape(project.Groups,1,[])
    for image = reshape(group.Images,1,[])
        base = safeName(image.Name,"image");
        parent = "";

        if opts.ImageFolders
            parent = base;
        end

        if opts.AverageIntensity
            manifest(end+1,1) = makeEntry(group,image,"Average intensity","", ...
                relativeFile(parent,base+"_average-intensity.ome.tiff"), ...
                @() buildPrimary(image,"AverageIntensity",project.Settings)); %#ok<AGROW>
        end

        if opts.Mask && ~isempty(image.Mask)
            manifest(end+1,1) = makeEntry(group,image,"Mask","", ...
                relativeFile(parent,base+"_mask.ome.tiff"), ...
                @() buildPrimary(image,"Mask",project.Settings)); %#ok<AGROW>
        end

        if opts.Order && ~isempty(image.Order)
            manifest(end+1,1) = makeEntry(group,image,"Order","", ...
                relativeFile(parent,base+"_order.ome.tiff"), ...
                @() buildPrimary(image,"Order",project.Settings)); %#ok<AGROW>
        end

        if opts.Azimuth && ~isempty(image.Azimuth)
            manifest(end+1,1) = makeEntry(group,image,"Azimuth","", ...
                relativeFile(parent,base+"_azimuth.ome.tiff"), ...
                @() buildPrimary(image,"Azimuth",project.Settings)); %#ok<AGROW>
        end

        assignments = image.AuxiliaryChannels;

        if opts.AuxiliaryIndividual
            for assignment = reshape(assignments,1,[])
                channel = project.Channels.findByID(assignment.ChannelID);

                if isempty(channel)
                    error('oops:export:UnknownAuxiliaryChannel', ...
                        'Image %s refers to an unknown auxiliary channel.',image.Name);
                end

                channelName = safeName(channel.Name,"channel");
                manifest(end+1,1) = makeEntry(group,image,"Auxiliary",channel.Name, ...
                    relativeFile(parent,base+"_auxiliary-"+channelName+".ome.tiff"), ...
                    @() buildAuxiliary(image,assignment,channel)); %#ok<AGROW>
            end
        end

        if opts.AuxiliaryCombined && ~isempty(assignments)
            validateCombinedAuxiliary(image,assignments);
            manifest(end+1,1) = makeEntry(group,image,"Auxiliary channels","", ...
                relativeFile(parent,base+"_auxiliary-channels.ome.tiff"), ...
                @() buildCombinedAuxiliary(image,assignments,project)); %#ok<AGROW>
        end
    end
end

manifest = uniquifyPaths(manifest,folder);
end

function item = makeEntry(group,image,domain,channelName,path,buildFcn)
item = struct('GroupName',group.Name,'ImageName',image.Name, ...
    'Domain',domain,'ChannelName',channelName, ...
    'RelativePath',path,'BuildFcn',buildFcn);
end

function path = relativeFile(parent,name)
if parent == ""
    path = name;
else
    path = string(fullfile(parent,name));
end
end

function name = safeName(value,fallback)
name = regexprep(strtrim(string(value)),'[<>:"/\\|?*\x00-\x1F]+','-');
name = regexprep(name,'\s+',' ');
name = regexprep(name,'^[ .-]+|[ .-]+$','');
if name == "", name = fallback; end
end

function manifest = uniquifyPaths(manifest,folder)
% Use group names only when otherwise identical image/domain names collide.
seen = strings(0,1);
for k = 1:numel(manifest)
    candidate = manifest(k).RelativePath;
    key = lower(candidate);

    if any(seen == key)
        [parent,stem,ext] = fileparts(candidate);
        group = safeName(manifest(k).GroupName,"group");
        candidate = string(fullfile(parent,group+"_"+string(stem)+string(ext)));
        key = lower(candidate);
        suffix = 2;

        while any(seen == key)
            candidate = string(fullfile(parent,group+"_"+string(stem)+ ...
                "-"+suffix+string(ext)));
            key = lower(candidate);
            suffix = suffix+1;
        end
    end

    manifest(k).RelativePath = candidate;
    seen(end+1,1) = key; %#ok<AGROW>
end

% Ensure every generated destination remains under the selected root.
for k = 1:numel(manifest)
    destination = string(fullfile(folder,manifest(k).RelativePath));
    if ~startsWith(destination,string(folder)+filesep) && destination ~= folder
        error('oops:export:InvalidDestination','Invalid export destination: %s',destination);
    end
end
end

function data = buildPrimary(image,domain,settings)
switch domain
    case "AverageIntensity"
        values = oops.analysis.Analyzer.ensureAverageIntensity(image);
        values = oops.render.intensityDisplayValues(image,values);
        name = "Average intensity";
        color = [1 1 1];
        map = gray(256);
        if ~isempty(image.PrimaryChannel)
            name = image.PrimaryChannel.Name + " average intensity";
            color = image.PrimaryChannel.Color;
            map = matlabx.colors.maps.Registry.map( ...
                image.PrimaryChannel.Colormap,image.PrimaryChannel.ColormapCategory);
        end
    case "Mask"
        values = image.Mask;
        name = "Mask";
        color = colorValue(settings.Colormaps.MaskColor);
        map = oops.render.colormap(settings.Colormaps,"Mask");
    case "Order"
        values = image.Order;
        name = "Order";
        color = colorValue(settings.Colormaps.OrderColor);
        map = oops.render.colormap(settings.Colormaps,"Order");
    case "Azimuth"
        % OOPS presents axial orientation in signed degrees throughout its UI.
        values = rad2deg(image.Azimuth);
        name = "Azimuth (degrees)";
        color = colorValue(settings.Colormaps.AzimuthColor);
        map = oops.render.azimuthImageColormap(settings.Colormaps);
    otherwise
        error('oops:export:UnknownNativeDomain','Unknown native export domain: %s',domain);
end

data = matlabx.image.Image5D.fromComponents(values,Names=name,Colors=color, ...
    Metadata=imageMetadata(image,name));
data.Components(1).LUT = map;
end

function data = buildAuxiliary(image,assignment,channel)
values = assignment.getPlane();
data = matlabx.image.Image5D.fromComponents(values,Names=channel.Name, ...
    Colors=channel.Color,Metadata=imageMetadata(image,channel.Name));
data.Components(1).LUT = matlabx.colors.maps.Registry.map( ...
    channel.Colormap,channel.ColormapCategory);
end

function data = buildCombinedAuxiliary(image,assignments,project)
planes = cell(1,numel(assignments));
names = strings(1,numel(assignments));
colors = zeros(numel(assignments),3);
maps = cell(1,numel(assignments));

for k = 1:numel(assignments)
    channel = project.Channels.findByID(assignments(k).ChannelID);
    planes{k} = assignments(k).getPlane();
    names(k) = channel.Name;
    colors(k,:) = channel.Color;
    maps{k} = matlabx.colors.maps.Registry.map( ...
        channel.Colormap,channel.ColormapCategory);
end

data = matlabx.image.Image5D.fromComponents(planes,Names=names,Colors=colors, ...
    Metadata=imageMetadata(image,image.Name+" auxiliary channels"));
for k = 1:numel(maps), data.Components(k).LUT = maps{k}; end
end

function validateCombinedAuxiliary(image,assignments)
classes = strings(numel(assignments),1);
sizes = zeros(numel(assignments),2);
for k = 1:numel(assignments)
    component = assignments(k).Input.Components(assignments(k).ComponentIndex);
    classes(k) = component.Class;
    sizes(k,:) = [component.SizeY component.SizeX];
end
if numel(unique(classes)) ~= 1
    error('oops:export:MixedAuxiliaryClasses', ...
        ['The auxiliary channels assigned to %s use different pixel classes (%s). ' ...
        'Export them individually or disable combined auxiliary export.'], ...
        image.Name,strjoin(unique(classes),', '));
end
if any(sizes ~= sizes(1,:),"all")
    error('oops:export:MixedAuxiliaryGeometry', ...
        ['The auxiliary channels assigned to %s do not share matching image ' ...
        'dimensions and cannot be combined in one OME-TIFF.'],image.Name);
end
end

function metadata = imageMetadata(image,name)
physicalX = image.PixelSize.X;
physicalY = image.PixelSize.Y;
unitX = image.PixelSize.UnitX;
unitY = image.PixelSize.UnitY;

% The model uses one pixel as its fallback scale. OME physical-size fields
% accept physical length units, so omit rather than mislabel pixel units.
if strcmpi(unitX,"px"), physicalX = NaN; unitX = ""; end
if strcmpi(unitY,"px"), physicalY = NaN; unitY = ""; end

metadata = matlabx.image.ImageMetadata( ...
    ImageName=name,Description="Native-resolution image exported from OOPS", ...
    PhysicalSizeX=physicalX,PhysicalSizeY=physicalY, ...
    PhysicalSizeXUnit=unitX,PhysicalSizeYUnit=unitY);
end

function value = colorValue(color)
[~,value] = matlabx.image.normalizeComponentColor(color);
end
