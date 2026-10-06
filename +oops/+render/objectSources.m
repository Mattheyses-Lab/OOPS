% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [sources,info,objectMask] = objectSources(region,settings)
%OBJECTSOURCES Build aligned display-only crops for the active object grid.
% All four sources use one square crop geometry. The object owns only its
% pixel membership; corrected and derived image arrays remain parent-owned.

arguments
    region (1,1) oops.model.Object
    settings (1,1) oops.config.Settings
end

% Parent image supplying corrected data and stored polarization results.
image = region.Parent;

% Display settings defining the common square crop around this object.
display = settings.ObjectDisplay;

% Corrected stack is retrieved from the bounded project cache or computed once.
corrected = oops.analysis.Analyzer.correctedStack(image);

% Shared crop geometry and object-only mask produced with the intensity crop.
[intensity,geometry,objectMask] = region.getCrop(corrected, ...
    Margin=display.CropMargin,Square=display.SquareCrop);

% Quantize only the display copy to the raw detector's integer class.
[detectorLimits,className] = oops.analysis.detectorRange(image.Input);

if ~isempty(detectorLimits)
    intensity = cast(round(intensity),className);
end

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

% Azimuth is temporarily displayed in [0,180] degrees; model radians are untouched.
if isempty(image.Azimuth)
    info(4) = sourceInfo("Azimuth",false,"Azimuth has not been produced", ...
        oops.render.colormap(settings.Colormaps,"Azimuth"),[]);
else
    azimuth = geometry.extract(mod(rad2deg(image.Azimuth),180),FillValue=0);
    sources{4} = matlabx.image.Image5D.fromComponents(azimuth,Names="Azimuth");
    info(4) = sourceInfo("Azimuth (degrees)",true,"", ...
        oops.render.colormap(settings.Colormaps,"Azimuth"),[0 180]);
end
end

function info = sourceInfo(title,available,reason,colormap,limits)
%SOURCEINFO Construct one uniform object-view metadata record.

info = struct('Title',title,'Available',available,'Reason',reason, ...
    'Colormap',colormap,'CLim',limits);
end
