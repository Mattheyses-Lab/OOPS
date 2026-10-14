% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [value,bounds,ranges] = displayLimits(image,domain,settings)
%DISPLAYLIMITS Resolve display policies without overwriting image-local limits.
% Intensity uses all four raw/corrected frames together, so both viewers share
% one range. Order uses finite order values. NaNs never determine limits.

arguments
    image (1,1) oops.model.Image
    domain (1,1) string {mustBeMember(domain,["Intensity","Order"])}
    settings (1,1) oops.config.Settings
end

if domain == "Intensity"

    % Raw/corrected intensity pixels or order pixels used to find display bounds.
    values = oops.analysis.readStack(image.Input);

    if ~isempty(image.Parent.CalibrationIDs)
        corrected = oops.analysis.Analyzer.correctedStack(image);
        values = [values(:);corrected(:)];
    end
else
    values = image.Order(:);
end

values = values(isfinite(values));

if isempty(values)

    % Finite data range used for slider bounds, with an empty-data fallback.
    bounds = [0 1];
else
    bounds = [min(values) max(values)];
end

if bounds(2) <= bounds(1)
    bounds(2) = bounds(1)+max(1,eps(bounds(1)));
end

% One-shot ranges used by the Reset and Auto buttons.
if domain == "Intensity"
    ranges.Reset = bounds;
    ranges.Auto = percentileRange(values,bounds);
else
    bounds = [0 1];
    ranges.Reset = [0 1];

    switch settings.Display.OrderAutoScaleMethod
        case "Contrast"
            ranges.Auto = percentileRange(values,[0 1]);
        case "Zero to max"
            ranges.Auto = zeroToMaxRange(values,[0 1]);
        case "Data range"
            ranges.Auto = finiteRange(values,[0 1]);
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
end

% Expand UI slider bounds to keep user values accessible after recalibration.
bounds = [min(bounds(1),value(1)) max(bounds(2),value(2))];
end

function value = zeroToMaxRange(values,fallback)
%ZEROTOMAXRANGE Anchor order at zero and scale to the finite data maximum.

if isempty(values)
    value = fallback;
else
    value = [0 max(values)];
end

if value(2) <= value(1)
    value = fallback;
end
end

function value = percentileRange(values,fallback)
%PERCENTILERANGE Return robust intensity limits with a valid fallback.

if isempty(values)
    value = fallback;
else
    value = prctile(values,[1 99]);
end

if value(2) <= value(1)
    value = finiteRange(values,fallback);
end
end

function value = finiteRange(values,fallback)
%FINITERANGE Return finite data extrema while preserving a positive span.

if isempty(values)
    value = fallback;
else
    value = [min(values) max(values)];
end

if value(2) <= value(1)
    value = fallback;
end
end
