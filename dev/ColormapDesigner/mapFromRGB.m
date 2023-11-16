function mapOut = mapFromRGB(clrs,Options)
%%  MAPFROMRGB creates a custom colormap from a list of RGB triplets, the positions of the colors in the map, and colorspace
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

    %% validate inputs and set defaults

    arguments
        clrs (:,3) double = [0 0 0;1 1 1]
        Options.nColors (1,1) double = 256
        Options.colorPositions (1,:) = linspace(0,1,size(clrs,1))
        Options.colorSpace (1,:) char {mustBeMember(Options.colorSpace,{'RGB','LAB'})} = 'RGB'
    end

    % check that colorPositions is increasing and strictly monotonic
    if any(diff(Options.colorPositions) <= 0)
        error('colorPositions must be strictly monotonically increasing')
    end

    % check that first and last elements of colorPositions are 0 and 1, respectively
    if ~isequal(Options.colorPositions([1,end]),[0,1])
        error('First and last elements of colorPositions must be 0 and 1, respectively')
    end

    % check that number of input colors matches number of elements in colorPositions
    if size(clrs,1) ~= numel(Options.colorPositions)
        error('Number of RGB triplets in clrs must match number of elements in colorPositions')
    end

    % check that number of desired colors is at least greater than or equal to number of input colors
    if Options.nColors < size(clrs,1)
        error('nColors must be >= number of RGB triplets in clrs')
    end

    %% create the new map by linearly interpolating through the chosen colorspace

    switch Options.colorSpace
        case 'LAB'
            clrs = rgb2lab(clrs,"ColorSpace","adobe-rgb-1998");
            mapOut = interp2(1:3,Options.colorPositions,clrs,1:3,linspace(0,1,Options.nColors)');
            mapOut = min(max(lab2rgb(mapOut,"ColorSpace","adobe-rgb-1998"),0),1);
        case 'RGB'
            mapOut = interp2(1:3,Options.colorPositions,clrs,1:3,linspace(0,1,Options.nColors)');
    end

    %% interp2() usage

    % mapOut = interp2(X,Y,V,Xq,Yq)
    % X: x coordinates of sample points (input color column indices)
    % Y: y coordinates of sample points (input color row indices)
    % V: function values at each sample point (input colors)
    % Xq: x coordinates of query points (output color column indices)
    % Yq: y coordinates of query points (output color row indices)
    
end