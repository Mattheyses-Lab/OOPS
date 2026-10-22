% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function corrected = flatField(stack,calibration,~)
%FLATFIELD Divide raw intensities by a normalized four-angle response.

validateattributes(stack,{'double'},{'real','finite','nonnegative'});
validateattributes(calibration,{'double'}, ...
    {'real','finite','nonnegative','size',size(stack)});

if size(stack,3) ~= 4
    error('oops:analysis:InvalidStack','Correction requires four polarization planes.');
end

corrected = stack./calibration;

if any(calibration == 0,'all')
    oops.Log.WARN(sprintf( ...
        '%d zero-response calibration pixels produce nonfinite corrected values.', ...
        nnz(calibration == 0)));
end
end
