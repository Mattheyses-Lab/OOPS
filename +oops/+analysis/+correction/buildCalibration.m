% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function model = buildCalibration(stacks,parameters)
%BUILDCALIBRATION Construct the calibration model required by a recipe.

arguments
    stacks cell
    parameters (1,1) oops.analysis.correction.Parameters = ...
        oops.analysis.correction.Parameters()
end

definition = oops.analysis.correction.algorithms(parameters.Algorithm);

if isempty(definition.BuildFcn)
    model = [];
    return;
end

model = definition.BuildFcn(stacks,parameters.Values);
end
