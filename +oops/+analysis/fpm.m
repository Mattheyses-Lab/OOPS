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

% Total-intensity Stokes parameter derived from the four analyzer angles.
s0 = sum(stack,3)/2;

% Linear-polarization Stokes parameters for the two orthogonal angle pairs.
s1 = stack(:,:,1)-stack(:,:,3);
s2 = stack(:,:,2)-stack(:,:,4);

% Pixels with four finite intensities and a positive total signal.
valid = all(isfinite(stack),3) & s0 > 0;

% Normalized linear Stokes components, initially NaN where analysis is undefined.
normalizedS1 = nan(size(s0));
normalizedS2 = normalizedS1;

normalizedS1(valid) = s1(valid)./s0(valid);
normalizedS2(valid) = s2(valid)./s0(valid);

% Modulation magnitude, constrained to the supported [0,1] order range.
order = min(max(hypot(normalizedS1,normalizedS2),0),1);
% Restore NaN at undefined pixels after min/max clamps the order magnitude.
order(~valid) = NaN;

% Axial angle in radians, obtained by halving the modulation phase.
azimuth = .5*atan2(normalizedS2,normalizedS1);
azimuth(order == 0) = NaN;
end
