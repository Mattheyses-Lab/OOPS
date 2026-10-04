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

function [R,kernel] = laplacianOfGaussian(I,opts)
%LAPLACIANOFGAUSSIAN Enhance bright blob-like structures with a LoG filter.
%
%   R = matlabx.image.process.laplacianOfGaussian(I) filters image I with a
%   Laplacian-of-Gaussian kernel and returns a positive response image for
%   bright blobs on a darker background.
%
%   [R,K] = matlabx.image.process.laplacianOfGaussian(...) also returns the
%   filter kernel. Positive blob responses are produced by negating the LoG
%   filtered image. If NormalizeScale is true, responses are multiplied by
%   Sigma^2 so values are more comparable across scales.

    arguments
        % Image to filter.
        I (:,:)
        % Gaussian sigma in pixels.
        opts.Sigma (1,1) double {mustBePositive(opts.Sigma)} = 1.5
        % Filter size. By default, choose a size large enough for Sigma.
        opts.FilterSize (1,1) double = NaN
        % Whether to multiply by Sigma^2 for scale-normalized response.
        opts.NormalizeScale (1,1) logical = true
        % Whether to clamp negative responses to zero.
        opts.PositiveOnly (1,1) logical = true
    end

    I = normalizeImage_(I);

    if isnan(opts.FilterSize)
        filterSize = 2 * ceil(3 * opts.Sigma) + 1;
    else
        if opts.FilterSize <= 0 || opts.FilterSize ~= round(opts.FilterSize)
            error("matlabx:image:process:laplacianOfGaussian:InvalidFilterSize", ...
                "FilterSize must be a positive integer or NaN for automatic sizing.");
        end

        filterSize = opts.FilterSize;
    end

    if mod(filterSize,2) == 0
        filterSize = filterSize + 1;
    end

    kernel = fspecial("log", filterSize, opts.Sigma);
    R = -imfilter(I, kernel, "replicate", "same");

    if opts.NormalizeScale
        R = R .* opts.Sigma.^2;
    end

    if opts.PositiveOnly
        R(R < 0) = 0;
    end
end

function I = normalizeImage_(I)
%NORMALIZEIMAGE_ Convert image to finite double precision values.

    if ~isa(I,"double")
        I = im2double(I);
    end

    I(~isfinite(I)) = 0;
end
