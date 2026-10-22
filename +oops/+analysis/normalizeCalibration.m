% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function normalized = normalizeCalibration(stacks)
%NORMALIZECALIBRATION Compatibility facade for the default correction recipe.

normalized = oops.analysis.correction.buildCalibration(stacks);
end
