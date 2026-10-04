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

function snapAndRefresh(roi, ds)
%%SNAPANDREFRESH  Adjusts the Position of an images.roi.Rectangle such that width and height are multiples of ds

    % Current geometry
    pos   = roi.Position;               % [x y w h] in *unrotated* frame

    % Center is invariant for rotation
    cx = pos(1) + pos(3)/2;
    cy = pos(2) + pos(4)/2;

    % Snap width/height to multiples of ds
    wEff = max(ds, round(pos(3)/ds) * ds);
    hEff = max(ds, round(pos(4)/ds) * ds);

    % Rebuild Position as the axis-aligned box around the same center
    newPos = [cx - wEff/2, cy - hEff/2, wEff, hEff];

    % Update Position
    roi.Position      = newPos;

end