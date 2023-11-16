function azimuthStd = getAzimuthStd(azimuths)
%%  GETAZIMUTHSTD given a set of angles with pi phase ambiguity, return the circular standard deviation
%
%   INPUTS:
%       azimuths | (mx1) double | vector of angles (in radians) with a range of pi
%
%   OUTPUTS:
%       azimuthSTD | (1x1) double | circular SD of the azimuths in their original scale, but converted to degrees
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

%% mean resultant vector length (r)

% first convert azimuths to complex unit vectors, multiplying by two to map to scale with a range of 2pi
% the take the norm (abs()) of the mean of exponential function of those vectors
r = abs(mean(exp(1i*azimuths*2)));

%% circular standard deviation

% calculate the circular standard deviation, then divide by 2 to return to original scale
azimuthStd = rad2deg(sqrt(-2*log(r))*0.5);

%% angular deviation
%azimuthAngularDeviation = sqrt(2*(1-r))*0.5;

end