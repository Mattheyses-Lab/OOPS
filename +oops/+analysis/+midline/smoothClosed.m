% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [smoothX,smoothY] = smoothClosed(x,y,polynomialOrder,windowWidth)
%SMOOTHCLOSED Apply the legacy Savitzky-Golay filter to a closed curve.

% Original coordinate count restored after filtering the wrapped curve.
n = length(x);

% Wrapped coordinates provide samples on both sides of the closure.
wrappedX = [x(end-windowWidth:end);x(2:end-1);x(1:windowWidth)];
wrappedY = [y(end-windowWidth:end);y(2:end-1);y(1:windowWidth)];

% Smooth the extended coordinate vectors independently.
smoothX = sgolayfilt(wrappedX,polynomialOrder,windowWidth);
smoothY = sgolayfilt(wrappedY,polynomialOrder,windowWidth);

% Remove the temporary samples while retaining the original curve length.
smoothX = smoothX(windowWidth+1:windowWidth+n);
smoothY = smoothY(windowWidth+1:windowWidth+n);

end
