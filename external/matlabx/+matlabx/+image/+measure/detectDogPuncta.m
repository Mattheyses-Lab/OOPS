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

function [points,info] = detectDogPuncta(I,opts)
%DETECTDOGPUNCTA Detect puncta candidates with Difference-of-Gaussians peaks.
%
%   P = matlabx.image.measure.detectDogPuncta(I) enhances puncta-like
%   bright blobs with a Difference-of-Gaussians response image and returns
%   local maxima as N-by-2 [x y] point coordinates.

    arguments
        % Image to search for puncta candidates.
        I (:,:)
        % Smaller Gaussian sigma in pixels.
        opts.Sigma1 (1,1) double {mustBePositive(opts.Sigma1)} = 1
        % Larger Gaussian sigma in pixels.
        opts.Sigma2 (1,1) double {mustBePositive(opts.Sigma2)} = 2
        % Minimum DoG response to accept.
        opts.MinResponse (1,1) double = 0
        % Minimum spacing between accepted maxima.
        opts.MinDistance (1,1) double {mustBeNonnegative(opts.MinDistance)} = 0
        % Maximum number of strongest points to keep.
        opts.MaxNumPoints (1,1) double {mustBePositive(opts.MaxNumPoints)} = Inf
        % Whether to show a quick visual diagnostic.
        opts.ShowPlots (1,1) logical = false
    end

    R = matlabx.image.process.differenceOfGaussians(I, ...
        "Sigma1", opts.Sigma1, ...
        "Sigma2", opts.Sigma2);

    [points,mask,values] = matlabx.image.measure.findLocalMaxima(R, ...
        "MinValue", opts.MinResponse, ...
        "MinDistance", opts.MinDistance, ...
        "MaxNumPoints", opts.MaxNumPoints);

    info = struct( ...
        "Method", "dog", ...
        "DisplayName", "Difference of Gaussians", ...
        "Parameters", struct( ...
            "Sigma1", opts.Sigma1, ...
            "Sigma2", opts.Sigma2, ...
            "MinResponse", opts.MinResponse, ...
            "MinDistance", opts.MinDistance, ...
            "MaxNumPoints", opts.MaxNumPoints), ...
        "Response", R, ...
        "Mask", mask, ...
        "Values", values);

    if opts.ShowPlots
        showPointPreview_(I, points, "DoG puncta");
    end
end

function showPointPreview_(I,points,titleText)
%SHOWPOINTPREVIEW_ Display detected points on top of the input image.

    ax = matlabx.app.quickshow(I, "Tools", {'Zoom'}, "Colormap", turbo, "Title", titleText);
    hAx = ax.getAxes();
    hold(hAx, "on");
    plot(hAx, points(:,1), points(:,2), ...
        "Marker", "x", ...
        "Color", [1 1 1], ...
        "LineStyle", "none", ...
        "LineWidth", 1);
    hold(hAx, "off");
end
