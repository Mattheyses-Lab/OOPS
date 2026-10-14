% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function map = azimuthImageColormap(settings)
%AZIMUTHIMAGECOLORMAP Align signed image angles with orientation-field colors.

% Circularized registry map used directly by orientation lines, where zero
% degrees selects the first row through mod(angle,pi)/pi.
map = oops.render.colormap(settings,"Azimuth");

% Signed image data use CLim [-90,90], placing zero degrees at the middle
% of the LUT. Rotate the map so that midpoint receives the original first
% color without changing the numerical azimuth representation.
map = circshift(map,floor(size(map,1)/2),1);
end
