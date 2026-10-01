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

function [points,info] = detectLogPuncta(I,opts)
%DETECTLOGPUNCTA Detect puncta candidates with Laplacian-of-Gaussian peaks.
%
%   P = matlabx.image.measure.detectLogPuncta(I) enhances bright
%   blob-like structures with a LoG filter and returns local maxima as
%   N-by-2 [x y] point coordinates.

    arguments
        % Image to search for puncta candidates.
        I (:,:)
        % LoG sigma in pixels.
        opts.Sigma (1,1) double {mustBePositive(opts.Sigma)} = 1.5
        % Optional LoG filter size.
        opts.FilterSize (1,1) double = NaN
        % Minimum LoG response to accept.
        opts.MinResponse (1,1) double = 0
        % Minimum spacing between accepted maxima.
        opts.MinDistance (1,1) double {mustBeNonnegative(opts.MinDistance)} = 0
        % Maximum number of strongest points to keep.
        opts.MaxNumPoints (1,1) double {mustBePositive(opts.MaxNumPoints)} = Inf
        % Whether to show a quick visual diagnostic.
        opts.ShowPlots (1,1) logical = false
    end

    [R,kernel] = matlabx.image.process.laplacianOfGaussian(I, ...
        "Sigma", opts.Sigma, ...
        "FilterSize", opts.FilterSize);

    [points,mask,values] = matlabx.image.measure.findLocalMaxima(R, ...
        "MinValue", opts.MinResponse, ...
        "MinDistance", opts.MinDistance, ...
        "MaxNumPoints", opts.MaxNumPoints);

    info = struct( ...
        "Method", "log", ...
        "DisplayName", "Laplacian of Gaussian", ...
        "Parameters", struct( ...
            "Sigma", opts.Sigma, ...
            "FilterSize", opts.FilterSize, ...
            "MinResponse", opts.MinResponse, ...
            "MinDistance", opts.MinDistance, ...
            "MaxNumPoints", opts.MaxNumPoints), ...
        "Response", R, ...
        "Kernel", kernel, ...
        "Mask", mask, ...
        "Values", values);

    if opts.ShowPlots
        showPointPreview_(I, points, "LoG puncta");
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
