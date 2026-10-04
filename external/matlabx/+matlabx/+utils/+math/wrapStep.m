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

function x = wrapStep(x, step, lo, hi)
%WRAPSTEP  Step a value through a bounded integer range with wraparound
%
%   x = WRAPSTEP(x, step, lo, hi) advances x by the signed integer STEP
%   within the inclusive range [lo, hi]. When x exceeds the bounds,
%   it wraps around cyclically.
%
%   Inputs
%     x    : current value (scalar)
%     step : signed integer step (+1, -1, etc.)
%     lo   : lower bound of the range (inclusive)
%     hi   : upper bound of the range (inclusive)
%
%   Output
%     x    : updated value after stepping and wraparound
%
%   Example
%     x = 1;
%     x = wrapStep(x,  1, 1, 3);   % -> 2
%     x = wrapStep(x, -1, 1, 3);   % -> 3
%
%   See also MOD

    N = hi - lo + 1;
    x = lo + mod((x - lo) + step, N);
end