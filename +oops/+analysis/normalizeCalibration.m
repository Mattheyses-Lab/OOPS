% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function normalized = normalizeCalibration(stacks)
%NORMALIZECALIBRATION Average replicates, then divide by one global maximum.
% A single maximum across all four angles preserves their relative sensitivity,
% matching legacy OOPS. Per-angle normalization would bias the FPM response.

validateattributes(stacks,{'cell'},{'vector','nonempty'});

% Accumulator for the summed four-angle calibration response. Legacy OOPS
% summed every replicate first, then divided once by the replicate count.
total = zeros(size(stacks{1}));

% Validate and accumulate each calibration replicate into the shared mean.
for k = 1:numel(stacks)
    validateattributes(stacks{k},{'double'},{'real','finite','nonnegative','size',size(total)});

    if size(stacks{k},3) ~= 4
        error('oops:analysis:InvalidCalibration','Each calibration must contain four planes.');
    end

    total = total + stacks{k};
end

% Arithmetic order intentionally matches the legacy implementation.
average = total/numel(stacks);

% One global maximum shared by all polarization angles.
peak = max(average,[],'all');

if peak <= 0
    error('oops:analysis:EmptyCalibration','Calibration contains no positive signal.');
end

% Mean calibration response scaled by that shared maximum.
normalized = average/peak;
end
