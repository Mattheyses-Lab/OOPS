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

function RGB = mergeChannelsRGB_LUT(Icell, clim, cmaps)
%MERGECHANNELSRGB_ADDLUT  Additively merge grayscale channels using per-channel colormaps.
%
%   RGB = MERGECHANNELSRGB_ADDLUT(Icell, clim, cmaps) normalizes each
%   grayscale image using its display limits (CLIM), maps the normalized
%   values into the corresponding 256x3 colormap in CMAPS, then additively
%   sums the resulting RGB layers and clamps the result to [0,1].
%
%   Inputs
%     Icell : 1xN cell array of grayscale images (all same size/type)
%     clim  : Nx2 array of [low high] display limits per channel
%     cmaps : 1xN cell array of 256x3 colormaps (double/single in [0,1])
%             First row maps to clim(:,1), last row maps to clim(:,2).
%
%   Output
%     RGB   : MxNx3 double image in [0,1]
%
%   Example
%     RGB = mergeChannelsRGB_addLUT({ch1,ch2}, [100 800; 50 400], {hot(256), cool(256)});
%
%   See also VECIND2RGB, IM2UINT8, RESCALELINEAR, COLORMAP

    N = numel(Icell);
    assert(size(clim,1) == N && size(clim,2) == 2, 'clim must be Nx2.');
    assert(iscell(cmaps) && numel(cmaps) == N, 'cmaps must be a 1xN cell array.');

    % preallocate output RGB
    RGB = zeros([size(Icell{1}) 3], 'double');

    for k = 1:N
        cmap = cmaps{k};
        assert(ismatrix(cmap) && size(cmap,1) == 256 && size(cmap,2) == 3, ...
            'Each colormap must be 256x3.');

        % normalize to [0,1] using clim, convert to uint8, 
        % convert to RGB using LUT (cmap), add to cumulative result
        RGB = RGB + matlabx.image.compose.vecind2rgb(im2uint8(matlabx.image.process.rescaleLinear(Icell{k},clim(k,:))),cmap);
    end

    RGB = min(RGB, 1);
end