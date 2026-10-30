% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function rgb = renderImage(image,type,scaling,autoMethod,settings,assignment,channel)
%RENDERIMAGE Render one source-resolution RGB export using OOPS display policy.

arguments
    image (1,1) oops.model.Image
    type (1,1) string
    scaling (1,1) string
    autoMethod (1,1) string
    settings (1,1) oops.config.Settings
    assignment = []
    channel = []
end

switch type
    case "average-intensity"
        values = oops.analysis.Analyzer.ensureAverageIntensity(image);
        limits = primaryLimits(image,scaling,autoMethod);
        map = primaryMap(image,settings);
        rgb = applyMap(values,limits,map);
    case "mask"
        rgb = applyMap(image.Mask,[0 1],domainMap(settings,"Mask"));
    case "order"
        limits = orderLimits(image,scaling,autoMethod);
        rgb = applyMap(image.Order,limits,domainMap(settings,"Order"));
    case "azimuth"
        % Axial orientation is always mapped over one 180-degree cycle.
        axial = mod(image.Azimuth,pi)./pi;
        rgb = applyMap(axial,[0 1],domainMap(settings,"Azimuth"));
    case "auxiliary"
        values = assignment.getPlane();
        limits = auxiliaryLimits(assignment,values,scaling,autoMethod);
        rgb = applyMap(values,limits,channelMap(channel,settings));
    case "auxiliary-combined"
        assignments = image.AuxiliaryChannels;
        rgb = zeros(image.Input.SizeY,image.Input.SizeX,3);
        project = image.Parent.Parent;
        for k = 1:numel(assignments)
            itemChannel = project.Channels.findByID(assignments(k).ChannelID);
            layer = oops.export.renderImage(image,"auxiliary",scaling,autoMethod, ...
                settings,assignments(k),itemChannel);
            rgb = max(rgb,layer);
        end
    case {"intensity-weighted-order","intensity-weighted-azimuth", ...
            "azimuth-order-intensity-hsv"}
        intensityLimits = primaryLimits(image,scaling,autoMethod);
        orderRange = orderLimits(image,scaling,autoMethod);
        switch type
            case "intensity-weighted-order", source = "IntensityWeightedOrder";
            case "intensity-weighted-azimuth", source = "IntensityWeightedAzimuth";
            case "azimuth-order-intensity-hsv", source = "AzimuthOrderIntensityHSV";
        end
        rgb = oops.render.derivedVisualization(image,source,settings, ...
            IntensityLimits=intensityLimits,OrderLimits=orderRange);
    otherwise
        error('oops:export:UnknownImageType','Unknown image export type: %s',type);
end

rgb(~isfinite(rgb)) = 0;
rgb = min(max(rgb,0),1);
end

function limits = primaryLimits(image,scaling,method)
statistics = image.getDisplayStatistics("Intensity");
fallback = [statistics.Minimum statistics.Maximum];
switch scaling
    case "unscaled"
        limits = fallback;
    case "user"
        limits = image.IntensityDisplayRange;
        if isempty(limits), limits = fallback; end
    case "auto"
        limits = oops.render.automaticDisplayRange(statistics,method,fallback);
end
limits = validRange(limits,fallback);
end

function limits = orderLimits(image,scaling,method)
fallback = [0 1];
switch scaling
    case "unscaled"
        limits = fallback;
    case "user"
        limits = image.OrderDisplayRange;
    case "auto"
        limits = oops.render.automaticDisplayRange( ...
            image.getDisplayStatistics("Order"),method,fallback);
end
limits = validRange(limits,fallback);
end

function limits = auxiliaryLimits(assignment,values,scaling,method)
statistics = assignment.getDisplayStatistics(values);
fallback = [statistics.Minimum statistics.Maximum];
switch scaling
    case "unscaled"
        limits = fallback;
    case "user"
        limits = assignment.DisplayRange;
        if isempty(limits), limits = fallback; end
    case "auto"
        limits = oops.render.automaticDisplayRange(statistics,method,fallback);
end
limits = validRange(limits,fallback);
end

function limits = validRange(limits,fallback)
if isempty(limits) || any(~isfinite(limits)) || limits(2) <= limits(1)
    limits = fallback;
end
if any(~isfinite(limits)) || limits(2) <= limits(1)
    limits = [0 1];
end
end

function map = primaryMap(image,settings)
if isempty(image.PrimaryChannel)
    map = gray(256);
elseif settings.Display.PrimaryIntensityColorMode == "luts"
    map = matlabx.colors.maps.Registry.map( ...
        image.PrimaryChannel.Colormap,image.PrimaryChannel.ColormapCategory);
else
    map = colorRamp(image.PrimaryChannel.Color);
end
end

function map = channelMap(channel,settings)
if settings.Display.AuxiliaryColorMode == "luts"
    map = matlabx.colors.maps.Registry.map(channel.Colormap,channel.ColormapCategory);
else
    map = colorRamp(channel.Color);
end
end

function map = domainMap(settings,domain)
if settings.Display.(domain+"ColorMode") == "luts"
    if domain == "Azimuth"
        map = oops.render.azimuthImageColormap(settings.Colormaps);
    else
        map = oops.render.colormap(settings.Colormaps,domain);
    end
else
    map = colorRamp(settings.Colormaps.(domain+"Color"));
end
end

function map = colorRamp(color)
[~,rgb] = matlabx.image.normalizeComponentColor(color);
map = linspace(0,1,256)'.*rgb;
end

function rgb = applyMap(values,limits,map)
scaled = (double(values)-limits(1))./(limits(2)-limits(1));
scaled(~isfinite(scaled)) = 0;
scaled = min(max(scaled,0),1);
indices = 1+round(scaled.*(size(map,1)-1));
rgb = reshape(map(indices(:),:),size(values,1),size(values,2),3);
end
