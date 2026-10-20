% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [sources,info,objectMask,geometry] = objectSources(region,settings,opts)
%OBJECTSOURCES Build aligned display-only crops for the active object grid.
% All four sources use one square crop geometry. The object owns only its
% pixel membership; corrected and derived image arrays remain parent-owned.

arguments
    region (1,1) oops.model.Object
    settings (1,1) oops.config.Settings
    opts.Corrected = []
end

% Parent image supplying corrected data and stored polarization results.
image = region.Parent;

% Display settings defining the common square crop around this object.
display = settings.ObjectDisplay;

% Caller-supplied active-view stack avoids a second cache lookup. Other callers
% retain the ordinary on-demand corrected-stack behavior.
corrected = opts.Corrected;

if isempty(corrected)
    corrected = oops.analysis.Analyzer.correctedStack(image);
end

% Shared crop geometry and object-only mask produced with the intensity crop.
[intensity,geometry,objectMask] = region.getCrop(corrected, ...
    Margin=display.CropMargin,Square=display.SquareCrop);

% Match the render-only crop to the parent image's raw input class.
intensity = oops.render.intensityDisplayValues(image,intensity);

% Four display slots returned in the same order as the quadrant UI.
sources = cell(1,4);
info = repmat(struct( ...
    'Title',"",'Available',false,'Reason',"", ...
    'Colormap',gray(256),'CLim',[]),1,4);

% Corrected four-angle crop used by the order/orientation analysis.
sources{1} = matlabx.image.Image5D.fromComponents( ...
    arrayfun(@(k) intensity(:,:,k),1:4,'UniformOutput',false), ...
    Names=string(image.PolarizationAngles) + " deg");
info(1) = sourceInfo("Corrected intensity",true,"", ...
    oops.render.colormap(settings.Colormaps,"Intensity"), ...
    oops.render.displayLimits(image,"Intensity",settings));

% Order crop remains unavailable until the parent analysis has run.
if isempty(image.Order)
    info(2) = sourceInfo("Order",false,"Order has not been produced", ...
        oops.render.colormap(settings.Colormaps,"Order"),[]);
else
    order = geometry.extract(image.Order,FillValue=0);
    sources{2} = matlabx.image.Image5D.fromComponents(order,Names="Order");
    info(2) = sourceInfo("Order",true,"", ...
        oops.render.colormap(settings.Colormaps,"Order"), ...
        oops.render.displayLimits(image,"Order",settings));
end

% Object membership mask excludes neighboring segmented objects in the crop.
sources{3} = matlabx.image.Image5D.fromComponents(objectMask,Names="Mask");
info(3) = sourceInfo("Mask",true,"",gray(256),[0 1]);

% Preserve signed analytical azimuths in degrees for display and inspection.
if isempty(image.Azimuth)
    info(4) = sourceInfo("Azimuth",false,"Azimuth has not been produced", ...
        oops.render.azimuthImageColormap(settings.Colormaps),[]);
else
    azimuth = geometry.extract(rad2deg(image.Azimuth),FillValue=0);
    sources{4} = matlabx.image.Image5D.fromComponents(azimuth,Names="Azimuth");
    info(4) = sourceInfo("Azimuth (degrees)",true,"", ...
        oops.render.azimuthImageColormap(settings.Colormaps),[-90 90]);
end
end

function info = sourceInfo(title,available,reason,colormap,limits)
%SOURCEINFO Construct one uniform object-view metadata record.

info = struct('Title',title,'Available',available,'Reason',reason, ...
    'Colormap',colormap,'CLim',limits);
end
