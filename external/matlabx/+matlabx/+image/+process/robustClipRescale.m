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

function Iout = robustClipRescale(I, pHigh)
%%ROBUSTCLIPRESCALE  Clip extreme highs then rescale to [0,1]
% pHigh: e.g. 99.9, 99.95, 99.99

    if nargin < 2 || isempty(pHigh), pHigh = 99.95; end

    I = im2single(I);
    hi = prctile(I(:), pHigh);

    Iclip = min(I, hi);
    Iout = rescale(Iclip);
end