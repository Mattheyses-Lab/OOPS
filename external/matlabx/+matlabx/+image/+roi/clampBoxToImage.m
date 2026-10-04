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

% function Cc = clampBoxToImage(C, boxSize, imageSize)
% %clampBoxToImage Clamp box centers so boxes stay fully inside an image.
% %
% %   Cc = clampBoxToImage(C, boxSize, imageSize)
% %
% % Inputs
% % ------
% % C : Nx2 double
% %     Box centers in image coordinates: [x y].
% %
% % boxSize : scalar or 1x2 double
% %     Box dimensions.
% %     - scalar: square box [s s]
% %     - [w h]: width and height
% %
% % imageSize : 1x2 double
% %     Image size as [W H].
% %
% % Outputs
% % -------
% % Cc : Nx2 double
% %     Clamped box centers. Guaranteed that the box defined by
% %     Cc and boxSize lies fully within the image.
% %
% % Notes
% % -----
% % - Clamping is performed in top-left space, then converted back
% %   to center coordinates.
% % - This preserves the convention:
% %       * odd box width  -> x integer
% %       * even box width -> x ends in .5
% %       * odd box height -> y integer
% %       * even box height -> y ends in .5
% %
% % - Errors if the box does not fit inside the image.
% 
% arguments
%     C (:,2) double
%     boxSize (1,:) double {mustBePositive}
%     imageSize (1,2) double {mustBePositive}
% end
% 
% % Normalize box size
% if isscalar(boxSize)
%     w = boxSize;
%     h = boxSize;
% else
%     w = boxSize(1);
%     h = boxSize(2);
% end
% 
% W = imageSize(1);
% H = imageSize(2);
% 
% % Sanity check: box must fit in image
% if w > W || h > H
%     error("clampBoxToImage:BoxTooLarge", ...
%         "Box size [%g %g] does not fit inside image [%g %g].", w, h, W, H);
% end
% 
% % Compute top-left corners from centers
% x0 = C(:,1) - w/2;
% y0 = C(:,2) - h/2;
% 
% % Clamp top-left so box stays inside image
% x0 = max(1, min(x0, W - w + 1));
% y0 = max(1, min(y0, H - h + 1));
% 
% % Convert back to centers
% Cx = x0 + w/2;
% Cy = y0 + h/2;
% 
% Cc = [Cx Cy];
% end

function Cc = clampBoxToImage(C, boxSize, imageSize)
%clampBoxToImage Clamp box centers so boxes stay fully inside an image.
%
%   Cc = clampBoxToImage(C, boxSize, imageSize)
%
% Inputs
% ------
% C : Nx2 double
%     Centers [x y] in pixel-center coordinates.
%
% boxSize : scalar or 1x2 double
%     Box size in pixels: scalar => [s s], or [w h].
%
% imageSize : 1x2 double
%     Image size [W H] (width, height).
%
% Output
% ------
% Cc : Nx2 double
%     Clamped centers. Guaranteed:
%       - box stays inside image bounds
%       - x is integer for odd w, ends in .5 for even w
%       - y is integer for odd h, ends in .5 for even h
%
% Convention
% ----------
% Uses MATLAB bbox convention with top-left pixel coordinate x,y and size w,h.
% Center is:  cx = x + (w-1)/2, cy = y + (h-1)/2.

arguments
    C (:,2) double
    boxSize (1,:) double {mustBePositive}
    imageSize (1,2) double {mustBePositive}
end

% Normalize box size
if isscalar(boxSize)
    w = boxSize;
    h = boxSize;
else
    w = boxSize(1);
    h = boxSize(2);
end

W = imageSize(1);
H = imageSize(2);

% Box must fit in the image
if w > W || h > H
    error("clampBoxToImage:BoxTooLarge", ...
        "Box size [%g %g] does not fit inside image [%g %g].", w, h, W, H);
end

% Half-extents in "pixel-center" convention
hx = (w - 1)/2;
hy = (h - 1)/2;

% Convert center -> top-left (x0,y0) in bbox convention
x0 = C(:,1) - hx;
y0 = C(:,2) - hy;

% Top-left should land on integer pixel coordinates; rounding preserves your .5 rule
x0 = round(x0);
y0 = round(y0);

% Clamp top-left so full box is inside image
x0 = max(1, min(x0, W - w + 1));
y0 = max(1, min(y0, H - h + 1));

% Convert back to centers (guarantees integer/.5 based on parity of w,h)
Cc = [x0 + hx, y0 + hy];
end

