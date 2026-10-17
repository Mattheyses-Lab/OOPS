% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function value = normalizeIntensityDisplayRange(image,value)
%NORMALIZEINTENSITYDISPLAYRANGE Match limits to the source-class display domain.

arguments
    image (1,1) oops.model.Image
    value (1,2) double {mustBeReal,mustBeFinite}
end

% Integer detector bounds are empty when the source uses floating-point storage.
[limits,~] = oops.analysis.detectorRange(image.Input);

if isempty(limits)
    return;
end

% Integer display images use integral, representable color limits.
value = round(value);
value = [max(value(1),limits(1)) min(value(2),limits(2))];

% Preserve a valid one-count span if rounding or clipping collapsed the range.
if value(1) >= value(2)

    if value(1) < limits(2)
        value(2) = value(1)+1;
    else
        value(1) = value(2)-1;
    end

end
end
