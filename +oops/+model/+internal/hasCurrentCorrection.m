% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tf = hasCurrentCorrection(image)
%HASCURRENTCORRECTION Distinguish calibrated outputs from a raw-stack fallback.

tf = ~isempty(image.Parent.CalibrationIDs) && ...
    isfield(image.Results,'AverageIntensity') && isfield(image.Results,'CalibrationIDs') && ...
    isequal(image.Results.CalibrationIDs,image.Parent.CalibrationIDs);
end
