% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function rgb = derivedVisualization(image,sourceID,settings,opts)
%DERIVEDVISUALIZATION Render RGB views derived from polarization outputs.

arguments
    image (1,1) oops.model.Image
    sourceID (1,1) string {mustBeMember(sourceID,[ ...
        "IntensityWeightedOrder","IntensityWeightedAzimuth", ...
        "AzimuthOrderIntensityHSV"])}
    settings (1,1) oops.config.Settings
    opts.IntensityLimits double = []
    opts.OrderLimits double = []
end

average = oops.analysis.Analyzer.ensureAverageIntensity(image);
order = image.Order;
azimuth = image.Azimuth;

if isempty(opts.IntensityLimits)
    opts.IntensityLimits = oops.render.displayLimits(image,"Intensity",settings);
end
intensity = scaleToUnit(average,opts.IntensityLimits);
scaledOrder = [];

if sourceID ~= "IntensityWeightedAzimuth"
    if isempty(opts.OrderLimits)
        opts.OrderLimits = oops.render.displayLimits(image,"Order",settings);
    end
    scaledOrder = scaleToUnit(order,opts.OrderLimits);
end

switch sourceID
    case "IntensityWeightedOrder"
        rgb = applyMap(scaledOrder,displayMap(settings,"Order"));
        rgb = rgb .* intensity;

    case "IntensityWeightedAzimuth"
        axial = mod(azimuth,pi)./pi;
        rgb = applyMap(axial,displayMap(settings,"Azimuth"));
        rgb = rgb .* intensity;

    case "AzimuthOrderIntensityHSV"
        hue = mod(azimuth,pi)./pi;
        hue(~isfinite(hue)) = 0;
        rgb = hsv2rgb(cat(3,hue,scaledOrder,intensity));
end

rgb(~isfinite(rgb)) = 0;
rgb = min(max(rgb,0),1);
end

function values = scaleToUnit(values,limits)
%SCALETOUNIT Apply display limits and clip into the unit interval.

values = (double(values)-limits(1))./(limits(2)-limits(1));
values(~isfinite(values)) = 0;
values = min(max(values,0),1);
end

function map = displayMap(settings,domain)
%DISPLAYMAP Resolve the effective LUT or monochromatic component ramp.

if settings.Display.(domain+"ColorMode") == "luts"
    map = oops.render.colormap(settings.Colormaps,domain);
else
    [~,rgb] = matlabx.image.normalizeComponentColor( ...
        settings.Colormaps.(domain+"Color"));
    map = linspace(0,1,256)'.*rgb;
end
end

function rgb = applyMap(values,map)
%APPLYMAP Convert unit scalar values to an RGB image through a lookup table.

indices = 1+round(values.*(size(map,1)-1));
indices = min(max(indices,1),size(map,1));
rgb = reshape(map(indices(:),:),size(values,1),size(values,2),3);
end
