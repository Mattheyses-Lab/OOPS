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

function R = differenceOfGaussians(I,opts)
%DIFFERENCEOFGAUSSIANS Enhance blobs by subtracting two Gaussian smooths.
%
%   R = matlabx.image.process.differenceOfGaussians(I) returns a bright
%   blob response image computed as Gaussian(I,Sigma1) -
%   Gaussian(I,Sigma2), where Sigma2 is larger than Sigma1.
%
%   DoG is a fast, simple approximation to LoG and is often convenient for
%   puncta-like features when the expected spot size is only approximate.

    arguments
        % Image to filter.
        I (:,:)
        % Smaller Gaussian sigma in pixels.
        opts.Sigma1 (1,1) double {mustBePositive(opts.Sigma1)} = 1
        % Larger Gaussian sigma in pixels.
        opts.Sigma2 (1,1) double {mustBePositive(opts.Sigma2)} = 2
        % Whether to clamp negative responses to zero.
        opts.PositiveOnly (1,1) logical = true
    end

    if opts.Sigma2 <= opts.Sigma1
        error("matlabx:image:process:differenceOfGaussians:InvalidSigma", ...
            "Sigma2 must be greater than Sigma1.");
    end

    if ~isa(I,"double")
        I = im2double(I);
    end

    I(~isfinite(I)) = 0;

    R = imgaussfilt(I, opts.Sigma1) - imgaussfilt(I, opts.Sigma2);

    if opts.PositiveOnly
        R(R < 0) = 0;
    end
end
