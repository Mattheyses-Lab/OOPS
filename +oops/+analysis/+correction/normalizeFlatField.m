% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function normalized = normalizeFlatField(stacks,~)
%NORMALIZEFLATFIELD Average replicates and divide by one global maximum.

validateattributes(stacks,{'cell'},{'vector','nonempty'});

% Accumulator matching the input geometry and legacy arithmetic order.
total = zeros(size(stacks{1}));

% Validate and accumulate every calibration replicate before averaging.
for k = 1:numel(stacks)
    validateattributes(stacks{k},{'double'}, ...
        {'real','finite','nonnegative','size',size(total)});

    if size(stacks{k},3) ~= 4
        error('oops:analysis:InvalidCalibration', ...
            'Each calibration must contain four planes.');
    end

    total = total+stacks{k};
end

% Preserve relative sensitivity between analyzer angles by using one scale.
average = total/numel(stacks);
peak = max(average,[],'all');

if peak <= 0
    error('oops:analysis:EmptyCalibration', ...
        'Calibration contains no positive signal.');
end

% Shared normalized response subsequently applied by element-wise division.
normalized = average/peak;
end
