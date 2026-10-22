% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [order,azimuth] = fpm(stack)
%FPM Compatibility facade for the default polarization-analysis recipe.

result = oops.analysis.polarization.analyze(stack);
order = result.Order;
azimuth = result.Azimuth;
end
