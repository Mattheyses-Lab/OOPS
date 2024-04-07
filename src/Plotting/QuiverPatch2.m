function hPatch = QuiverPatch2(hAx,...
    x,...
    y,...
    theta,...
    rho,...
    ColorMode,...
    Colormap,...
    LineWidth,...
    LineAlpha,...
    LineScale,...
    theta2)
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


%% NEW METHOD

    nLines = length(x);

    % get cartesian coordinates of line endpoints
    [u,v] = pol2cart(theta,rho);
    % transpose each set of start/endpoint coordinates
    x = x';
    y = y';
    u = u';
    v = v';
    % scaling factor of each 'half-line'
    HalfLineScale = LineScale/2;

    if ~(isscalar(HalfLineScale))
        HalfLineScale = HalfLineScale';
    end
    
    % x and y coordinates for each 'half-line'
    X = [x+HalfLineScale.*u;x-HalfLineScale.*u];
    Y = [y-HalfLineScale.*v;y+HalfLineScale.*v];

    % preallocate line colors array
    PatchColors = zeros(nLines,3);
    
    % calculate colors for each line based on ColorMode
    switch ColorMode
        case 'Magnitude'
            % number of colors in the map (for indexing)
            nColors = length(Colormap);
            % determine the colormap idx of each line based on its pixel's OF (range 0-1)
            ColorIdx = round(rho.*(nColors-1))+1;
            % fill the array with colors based on idxs in ColorIdx
            PatchColors(:,:) = Colormap(ColorIdx,:);
        case 'Direction'
            % determine how many colors in the full map
            nColors = length(Colormap);
            % get the region of the circular map from
            % -pi/2 to pi/2 (the range of our values)
            % (pi/2)/(2pi) = 0.25
            % (3pi/2)/(2pi) = 0.75
            halfcircmap = Colormap(0.25*nColors:0.75*nColors,:);
            % how many colors in the truncated map
            nColors = length(halfcircmap);
            % normalize our theta values and convert to idxs
            % theta is in the range [-pi/2,pi/2]...
            % (theta+pi/2)./(pi) will scale theta to 0-1...
            % thus: 0 -> -pi/2, 1 -> pi/2
            ColorIdxsNorm = round(((theta+pi/2)./(pi))*(nColors-1))+1;
            % fill the array with colors based on idxs in ColorIdxsNorm
            PatchColors(:,:) = halfcircmap(ColorIdxsNorm,:);
        case 'Mono'
            MonoColor = [1 1 1];
            % replicate the MonoColor nLines times since each line is the same color
            PatchColors = repmat(MonoColor,nLines,1);
        case 'RelativeDirection'
            % determine how many colors in the full map
            nColors = length(Colormap);
            % get the region of the circular map from
            % -pi/2 to pi/2 (the range of our values)
            % (pi/2)/(2pi) = 0.25
            % (3pi/2)/(2pi) = 0.75
            halfcircmap = Colormap(0.25*nColors:0.75*nColors,:);
            % how many colors in the truncated map
            nColors = length(halfcircmap);
            % normalize our theta values and convert to idxs
            % theta is in the range [-pi/2,pi/2]...
            % (theta+pi/2)./(pi) will scale theta to 0-1...
            % thus: 0 -> -pi/2, 1 -> pi/2
            ColorIdxsNorm = round(((theta2+pi/2)./(pi))*(nColors-1))+1;
            % fill the array with colors based on idxs in ColorIdxsNorm
            PatchColors(:,:) = halfcircmap(ColorIdxsNorm,:);
    end

C = Interleave2DArrays(PatchColors,nan(size(PatchColors)),'row');

hPatch = patch(hAx,...
    "XData",X,...
    "YData",Y,...
    "FaceVertexCData",C,...
    "EdgeColor","Flat",...
    "HitTest","Off",...
    "PickableParts","None",...
    "LineWidth",LineWidth,...
    "EdgeAlpha",LineAlpha,...
    "Clipping","On");

end