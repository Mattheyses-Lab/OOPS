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

function mask = growSeedMask(I, bw, opts)
%GROWSEEDMASK Expand seed regions through pixels above threshold.
%
% mask = growSeedMask(I, bw)
% mask = growSeedMask(I, bw, Threshold=10)
%
% Inputs
%   I   - grayscale image
%   bw  - logical seed mask, same size as I
%
% Name-Value
%   Threshold - minimum pixel value to include, default 0
%
% Output
%   mask - logical mask containing all pixels connected to bw where I > Threshold

    arguments
        I (:,:) {mustBeNumeric}
        bw (:,:) logical
        opts.Threshold double = []
    end

    if ~isequal(size(I), size(bw))
        error("growSeedMask:SizeMismatch", ...
            "I and bw must have the same size.");
    end

    if isempty(opts.Threshold)
        thresh = graythresh(I);
        classRange = getrangefromclass(I);
        opts.Threshold = max(thresh * classRange(2), 0);
    end

    candidateMask = I > opts.Threshold;

    % Keep only candidate pixels connected to the seed mask.
    mask = imreconstruct(bw, candidateMask) > 0;
end