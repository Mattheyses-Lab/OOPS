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

function RGB = mergeChannelsRGB_screen(Icell, clim, colors)
%MERGECHANNELSRGB_SCREEN  Screen-blend merge of grayscale channels into RGB.
%
%   RGB = MERGECHANNELSRGB_SCREEN(Icell, clim, colors) normalizes each
%   grayscale channel using its display limits, tints it by COLORS, then
%   combines channels using SCREEN blending:
%       out = 1 - prod(1 - layer)
%
%   Inputs
%     Icell  : 1xN cell array of grayscale images (same size/type)
%     clim   : Nx2 [low high] display limits per channel
%     colors : Nx3 RGB weights per channel in [0,1] (optional)
%
%   Output
%     RGB    : MxNx3 double in [0,1]

    N = numel(Icell);
    assert(size(clim,1) == N && size(clim,2) == 2, 'clim must be Nx2.');

    if nargin < 3 || isempty(colors)
        base = [1 0 0; 0 1 0; 0 0 1; 1 0 1];  % R,G,B,M
        colors = base(1:N, :);
    end
    assert(size(colors,1) == N && size(colors,2) == 3, 'colors must be Nx3.');

    sz = size(Icell{1});
    RGB = zeros([sz 3], 'double');

    % Start "all dark" in screen-space: (1 - RGB) starts at 1, so RGB starts at 0.
    invOut = ones([sz 3], 'double');  % invOut = (1 - out)

    for k = 1:N
        Ik = double(Icell{k});
        lo = clim(k,1); hi = clim(k,2);
        denom = hi - lo;

        % Normalize to [0,1] with per-channel display limits
        if denom <= 0
            a = zeros(sz, 'double');
        else
            a = (Ik - lo) ./ denom;
            a = min(max(a, 0), 1);
        end

        % Create tinted layer in [0,1]
        layer = cat(3, a * colors(k,1), a * colors(k,2), a * colors(k,3));

        % Screen blend: out = 1 - (1-out).*(1-layer)
        invOut = invOut .* (1 - layer);
    end

    RGB = 1 - invOut;
end