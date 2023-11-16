function averageAzimuthImage = getAverageAzimuthImage(AzimuthImage)
%%  GETAVERAGEAZIMUTHIMAGE applies an axial mean filter to an image with angular data having pi phase ambiguity
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

% define function for sliding window
fun = @(x) getAzimuthAverage(x(:));

% apply fun to image with sliding window using nlfilter2
averageAzimuthImage = nlfilter2(AzimuthImage,3,fun);

end

