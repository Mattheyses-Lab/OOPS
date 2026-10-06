% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [smoothX,smoothY] = smoothOpen(x,y,polynomialOrder,windowWidth)
%SMOOTHOPEN Apply the legacy Savitzky-Golay filter to an open curve.

smoothX = sgolayfilt(x,polynomialOrder,windowWidth);
smoothY = sgolayfilt(y,polynomialOrder,windowWidth);

end
