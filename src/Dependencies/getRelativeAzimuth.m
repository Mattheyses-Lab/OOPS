function [MidlineRelativeAzimuth,NormalRelativeAzimuth] = getRelativeAzimuth(I,Az,Midline)
%%  GETRELATIVEAZIMUTH calculates the relative direction of azimuths with respect 
%   to the tangents and normals of a midline traced through a binary object
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

    Isz = size(I);

    %% compute the midline tangent in radians in the range [-pi/2 pi/2]
    midlineTangent = getMidlineTangent(Midline);

    % get the list of pixel azimuth values
    AzValues = Az(I);
    
    % initialize tangent image
    IT = zeros(Isz);

    % linear indices in this object mask
    objIdxs = find(I);
    % convert to row and column coordinates
    [objR,objC] = ind2sub(Isz,objIdxs);
    % get the distance between each object pixel and all midline coordinates | hypot(A,B) = sqrt(A^2+B^2)
    dist = hypot(objC'-Midline(:,1),objR'-Midline(:,2));
    % for each object pixel, get the index to the closest midline coordinate
    [~,minIdxs] = min(dist,[],1);
    % use the closest indices to set the tangent value of each object pixel
    IT(objIdxs) = midlineTangent(minIdxs);

    % list of midline tangent angles
    TangentValues = IT(I);

    % list of midline normal values (90° angle to midline) in the range [-pi/2 pi/2]
    NormalValues = TangentValues+pi/2;
    NormalValues(NormalValues>(pi/2)) = NormalValues(NormalValues>(pi/2))-pi;

    % get the angular differences between azimuth and tangent angles
    tangentDiff = angle(exp(2i*AzValues)./exp(2i*TangentValues))*0.5;
    % average the differences
    MidlineRelativeAzimuth = rad2deg(getAzimuthAverage(tangentDiff));

    % get the angular differences between azimuth and midline normal
    normalDiff = angle(exp(2i*AzValues)./exp(2i*NormalValues))*0.5;
    % average the differences
    NormalRelativeAzimuth = rad2deg(getAzimuthAverage(normalDiff));
end