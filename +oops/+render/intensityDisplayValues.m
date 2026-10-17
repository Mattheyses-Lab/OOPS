% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function values = intensityDisplayValues(image,values)
%INTENSITYDISPLAYVALUES Convert intensity data to its source-class display copy.
% Analytical arrays remain unchanged. Integer inputs are rounded and then
% saturated by MATLAB's cast; floating-point inputs retain their source class.

arguments
    image (1,1) oops.model.Image
    values {mustBeNumericOrLogical}
end

% Storage class shared by the four polarization input planes.
[~,className] = oops.analysis.detectorRange(image.Input);

if startsWith(className,"uint") || startsWith(className,"int") || className == "logical"
    values = round(values);
end

values = cast(values,className);
end
