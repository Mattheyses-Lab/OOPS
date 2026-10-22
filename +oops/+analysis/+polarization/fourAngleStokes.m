% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function result = fourAngleStokes(stack,~)
%FOURANGLESTOKES Calculate modulation order and axial azimuth from four planes.

validateattributes(stack,{'double'},{'real'});

if any(stack < 0,'all')
    error('oops:analysis:NegativeIntensity','Polarization intensities must be nonnegative.');
end

if size(stack,3) ~= 4
    error('oops:analysis:InvalidStack','Four-angle Stokes analysis requires four polarization planes.');
end

% Total-intensity Stokes parameter derived from the four analyzer angles.
s0 = sum(stack,3)/2;

% Linear-polarization Stokes parameters for the two orthogonal angle pairs.
s1 = stack(:,:,1)-stack(:,:,3);
s2 = stack(:,:,2)-stack(:,:,4);

% Pixels with four finite intensities and a positive total signal.
valid = all(isfinite(stack),3) & s0 > 0;

% Normalized components are NaN wherever polarization is undefined.
normalizedS1 = nan(size(s0));
normalizedS2 = normalizedS1;
normalizedS1(valid) = s1(valid)./s0(valid);
normalizedS2(valid) = s2(valid)./s0(valid);

% Modulation magnitude constrained to the supported order range.
order = min(max(hypot(normalizedS1,normalizedS2),0),1);
order(~valid) = NaN;

% Axial angle obtained by halving the modulation phase.
azimuth = .5*atan2(normalizedS2,normalizedS1);
azimuth(order == 0) = NaN;

% Named outputs preserve a stable contract across alternative algorithms.
result = struct('Order',order,'Azimuth',azimuth);
end
