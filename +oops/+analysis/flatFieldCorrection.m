% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function corrected = flatFieldCorrection(stack,calibration)
%FLATFIELDCORRECTION Compatibility facade for the default correction recipe.

corrected = oops.analysis.correction.apply(stack,calibration);

end
