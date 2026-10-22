% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tf = hasCurrentPolarization(image)
%HASCURRENTPOLARIZATION Test whether full-image FPM outputs match correction.

expectedSize = [image.Input.SizeY,image.Input.SizeX];
tf = ~isempty(image.Order) && ~isempty(image.Azimuth) && ...
    isequal(size(image.Order),expectedSize) && ...
    isequal(size(image.Azimuth),expectedSize) && ...
    image.PolarizationProvenance.isCurrent(image.CorrectionProvenance);
end
