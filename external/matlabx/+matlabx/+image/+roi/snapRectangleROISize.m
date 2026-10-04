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

function snapRectangleROISize(roi, ds)
%snapRectangleROISize Snap roi width/height to multiples of ds (typically 1 px).

    p = roi.Position; % [x y w h]
    w0 = p(3); h0 = p(4);

    w1 = max(ds, round(w0/ds)*ds);
    h1 = max(ds, round(h0/ds)*ds);

    if w1 ~= w0 || h1 ~= h0
        p(3) = w1;
        p(4) = h1;
        roi.Position = p;
    end
end