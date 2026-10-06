% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function value = curveLength(curve)
%CURVELENGTH Sum Euclidean distances between consecutive curve coordinates.
% Coordinates use the legacy [x y] convention. Closed curves must repeat
% their first coordinate at the end when the closing edge is required.

if any(isnan(curve(:)))
    value = NaN;
    return;
end

% Differences between consecutive x and y coordinates along the curve.
dx = curve(2:end,1)-curve(1:end-1,1);
dy = curve(2:end,2)-curve(1:end-1,2);

% Total piecewise-linear length in pixels.
value = sum(sqrt(dx.*dx+dy.*dy));

end
