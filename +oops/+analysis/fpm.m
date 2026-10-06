% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [order,azimuth] = fpm(stack)
%FPM Calculate legacy OOPS order and axial azimuth from 0/45/90/135-degree planes.
% Azimuth is radians, CCW from image X. A zero modulation has no defined angle.

validateattributes(stack,{'double'},{'real'});

if any(stack < 0,'all')
    error('oops:analysis:NegativeIntensity','FPM intensities must be nonnegative.');
end

if size(stack,3) ~= 4
    error('oops:analysis:InvalidStack','FPM requires four polarization planes.');
end

% Half the total intensity across the four polarization frames.
halfTotal = sum(stack,3)/2;

% Pixels with four finite intensities and a positive total signal.
valid = all(isfinite(stack),3) & halfTotal > 0;

% Normalized 0°/90° difference, initially NaN where analysis is undefined.
a = nan(size(halfTotal));

% Normalized 45°/135° difference, initially NaN where analysis is undefined.
b = a;

% Intensity difference between the 0° and 90° frames.
x = stack(:,:,1)-stack(:,:,3);

% Intensity difference between the 45° and 135° frames.
y = stack(:,:,2)-stack(:,:,4);
a(valid) = x(valid)./halfTotal(valid);
b(valid) = y(valid)./halfTotal(valid);

% Modulation magnitude, constrained to the supported [0,1] order range.
order = min(max(hypot(a,b),0),1);
% Restore NaN at undefined pixels after min/max clamps the order magnitude.
order(~valid) = NaN;

% Axial angle in radians, obtained by halving the modulation phase.
azimuth = .5*atan2(b,a);
azimuth(order == 0) = NaN;
end
