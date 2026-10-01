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

function Iout = mergeRGBImages(Icell, opts)
%MERGERGBIMAGES  Merge multiple RGB images using common blending methods
%
%   Iout = mergeRGBImages(Icell)
%   Iout = mergeRGBImages(Icell, opts)
%
%   Inputs
%   ------
%   Icell : cell array of MxNx3 RGB images
%
%   Name-Value Options (opts)
%   ------------------------
%   Method  : 'additive' | 'average' | 'weighted' | 'alpha' | 'screen'
%             (default = 'additive')
%   Weights : numeric vector, length = numel(Icell)
%             Used for 'weighted'
%   Alpha   : scalar in [0 1]
%             Used for 'alpha' (pairwise only)
%
%   Output
%   ------
%   Iout : merged RGB image

arguments
    Icell (1,:) cell
    opts.Method  (1,:) char {mustBeMember(opts.Method, ...
        {'additive','average','weighted','alpha','screen'})} = 'additive'
    opts.Weights (1,:) double = []
    opts.Alpha   (1,1) double {mustBeGreaterThanOrEqual(opts.Alpha,0), ...
                               mustBeLessThanOrEqual(opts.Alpha,1)} = 0.5
end

% stack images: MxNx3xN
Istack = cat(4, Icell{:});
N = size(Istack,4);

switch opts.Method
    case 'additive'
        Iout = sum(Istack,4);

    case 'average'
        Iout = mean(Istack,4);

    case 'weighted'
        assert(~isempty(opts.Weights), ...
            'Weights must be provided for weighted blending.')
        assert(numel(opts.Weights) == N, ...
            'Number of weights must match number of images.')

        w = reshape(opts.Weights,1,1,1,[]);
        Iout = sum(Istack .* w, 4);

    case 'alpha'
        assert(N == 2, ...
            'Alpha blending requires exactly two images.')
        a = opts.Alpha;
        Iout = a*Istack(:,:,:,1) + (1-a)*Istack(:,:,:,2);

    case 'screen'
        % screen blend: 1 - prod(1 - I)
        Iout = 1 - prod(1 - Istack, 4);
end

% clip output
if isfloat(Iout)
    Iout = min(max(Iout,0),1);
else
    Iout = min(Iout, intmax(class(Iout)));
end
end