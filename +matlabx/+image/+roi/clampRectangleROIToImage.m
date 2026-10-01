% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

function clampRectangleROIToImage(roi, imageSize)
%clampRectangleROIToImage Shift a rotated images.roi.Rectangle so all
%vertices lie within the pixel-edge bounds of an image.
%
% roi       : images.roi.Rectangle (can be rotated)
% imageSize : [H W] (same as size(I))

    H = imageSize(1);
    W = imageSize(2);

    % Pixel-edge bounds for full image view
    xMin = 0.5; xMax = W + 0.5;
    yMin = 0.5; yMax = H + 0.5;

    V = roi.Vertices; % Nx2 [x y]

    minX = min(V(:,1)); maxX = max(V(:,1));
    minY = min(V(:,2)); maxY = max(V(:,2));

    dx = 0;
    dy = 0;

    if minX < xMin, dx = dx + (xMin - minX); end
    if maxX > xMax, dx = dx - (maxX - xMax); end
    if minY < yMin, dy = dy + (yMin - minY); end
    if maxY > yMax, dy = dy - (maxY - yMax); end

    if dx ~= 0 || dy ~= 0
        % roi.Position = [x y w h] in unrotated frame; shifting x/y shifts
        % the whole ROI in data coordinates.
        p = roi.Position;
        p(1) = p(1) + dx;
        p(2) = p(2) + dy;
        roi.Position = p;
    end
end