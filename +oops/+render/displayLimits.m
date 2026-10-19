% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [value,bounds,ranges] = displayLimits(image,domain,settings)
%DISPLAYLIMITS Resolve display policies without overwriting image-local limits.
% Intensity uses the durable average image as one stable reference shared by
% raw, corrected, and average viewers. Order uses finite order values. NaNs
% never determine limits.

arguments
    image (1,1) oops.model.Image
    domain (1,1) string {mustBeMember(domain,["Intensity","Order"])}
    settings (1,1) oops.config.Settings
end

started = tic;
oops.Log.DEBUG("Resolving " + domain + " display limits for " + image.Name + ".");

statistics = image.getDisplayStatistics(domain);
bounds = [statistics.Minimum statistics.Maximum];

if bounds(2) <= bounds(1)
    bounds(2) = bounds(1)+max(1,eps(bounds(1)));
end

% One-shot ranges used by the Reset and Auto buttons.
if domain == "Intensity"
    ranges.Reset = bounds;
    ranges.Auto = [statistics.Percentile1 statistics.Percentile99];
    ranges.Auto = oops.render.normalizeIntensityDisplayRange(image,ranges.Auto);
else
    bounds = [0 1];
    ranges.Reset = [0 1];

    switch settings.Display.OrderAutoScaleMethod
        case "Contrast"
            ranges.Auto = [statistics.Percentile1 statistics.Percentile99];
        case "Zero to max"
            ranges.Auto = zeroToMaxRange(statistics.Maximum,[0 1]);
        case "Data range"
            ranges.Auto = [statistics.Minimum statistics.Maximum];
    end
end

% Keep Auto has precedence over Lock, followed by the image-local range.
if settings.Display.("KeepAutoDisplay"+domain)
    value = ranges.Auto;
elseif settings.Display.("LockDisplay"+domain)
    value = settings.Display.("LockedDisplayRange"+domain);

    if isempty(value)
        value = image.getDisplayRange(domain);
    end
else
    value = image.getDisplayRange(domain);

    % Until the user stores manual intensity limits, display the extrema of
    % the resident average-intensity copy. Never initialize from raw frames.
    if isempty(value)
        value = ranges.Reset;
    end
end

% Effective intensity limits follow the class and range of the displayed copy.
if domain == "Intensity"
    value = oops.render.normalizeIntensityDisplayRange(image,value);
end

% Expand UI slider bounds to keep user values accessible after recalibration.
bounds = [min(bounds(1),value(1)) max(bounds(2),value(2))];
oops.Log.DEBUG(sprintf( ...
    'Resolved %s display limits for %s in %.3f s: value=[%.6g %.6g], bounds=[%.6g %.6g].', ...
    domain,image.Name,toc(started),value(1),value(2),bounds(1),bounds(2)));
end

function value = zeroToMaxRange(maximum,fallback)
%ZEROTOMAXRANGE Anchor order at zero and scale to the finite data maximum.

if ~isfinite(maximum)
    value = fallback;
else
    value = [0 maximum];
end

if value(2) <= value(1)
    value = fallback;
end
end
