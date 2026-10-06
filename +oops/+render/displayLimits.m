% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [value,bounds] = displayLimits(image,domain,settings)
%DISPLAYLIMITS Resolve shared display-only scaling without overwriting user limits.
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

if domain == "Order"
    bounds = [0 1];
end

if settings.Display.("AutoScaleDisplay"+domain)

    if isempty(values)

        % Effective display limits chosen by auto-scaling or the stored manual range.
        value = [0 1];
    else
        value = prctile(values,[1 99]);
    end

    if value(2) <= value(1)
        value = [min(values,[],'all') max(values,[],'all')];

        if value(2) <= value(1)
            value = bounds;
        end

    end

    if domain == "Order"
        value = max(0,min(1,value));
    end

else
    value = image.getDisplayRange(domain);
end

% Expand UI slider bounds to keep user values accessible after recalibration.
bounds = [min(bounds(1),value(1)) max(bounds(2),value(2))];
end
