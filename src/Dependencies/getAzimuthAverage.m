function AzimuthAverage = getAzimuthAverage(azimuths)
%%  GETAZIMUTHAVERAGE returns axial mean of a vector of angles with pi phase ambiguity
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

AzimuthAverage = angle(mean(exp(1i*azimuths*2)))/2;

%% step-by-step version shown for clarity

    % % convert to complex vector (multiply by two because we have axial data) and take the mean
    % z = mean(exp(1i*angles*2));
    % 
    % % get real and imaginary components
    % y = imag(z);
    % x = real(z);
    % 
    % % use 4-quadrant inverse tangent function to get the angle 
    % % between the +x axis and a ray from the origin to point (x,y)
    % % (this is accomplished above with the angle() function)
    % rayAngle = atan2(y,x);
    % 
    % % divide by two to return to original scale
    % biaxialMean = rayAngle/2;

end