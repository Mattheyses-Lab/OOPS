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

function [points,info] = detectExtendedMaximaPuncta(I,opts)
%DETECTEXTENDEDMAXIMAPUNCTA Detect puncta with extended regional maxima.
%
%   P = matlabx.image.measure.detectExtendedMaximaPuncta(I) suppresses
%   shallow local maxima with imextendedmax and returns component centroids
%   as N-by-2 [x y] coordinates.
%
%   Extended maxima are useful when ordinary regional maxima over-detect
%   noisy plateaus. The H parameter is a contrast-like depth threshold:
%   larger values retain only more prominent maxima.

    arguments
        % Image to search for puncta candidates.
        I (:,:)
        % H-maxima depth threshold passed to imextendedmax.
        opts.H (1,1) double {mustBeNonnegative(opts.H)} = 0.05
        % Optional Gaussian smoothing before maxima detection.
        opts.Sigma (1,1) double {mustBeNonnegative(opts.Sigma)} = 0
        % Minimum spacing between accepted centroids.
        opts.MinDistance (1,1) double {mustBeNonnegative(opts.MinDistance)} = 0
        % Maximum number of strongest maxima to keep.
        opts.MaxNumPoints (1,1) double {mustBePositive(opts.MaxNumPoints)} = Inf
        % Whether to show a quick visual diagnostic.
        opts.ShowPlots (1,1) logical = false
    end

    if ~isa(I,"double")
        I = im2double(I);
    end
    I = rescale(I);

    if opts.Sigma > 0
        R = imgaussfilt(I, opts.Sigma);
    else
        R = I;
    end

    maximaMask = imextendedmax(R, opts.H, 8);
    CC = bwconncomp(maximaMask);
    props = regionprops(CC, R, "Centroid", "MaxIntensity");

    if isempty(props)
        points = zeros(0,2);
        values = zeros(0,1);
    else
        points = cat(1, props.Centroid);
        values = cat(1, props.MaxIntensity);
    end

    [points,values] = applyPointLimits_(points, values, opts.MinDistance, opts.MaxNumPoints);

    mask = false(size(I));
    if ~isempty(points)
        idx = sub2ind(size(I), round(points(:,2)), round(points(:,1)));
        mask(idx) = true;
    end

    info = struct( ...
        "Method", "extendedMaxima", ...
        "DisplayName", "Extended maxima", ...
        "Parameters", struct( ...
            "H", opts.H, ...
            "Sigma", opts.Sigma, ...
            "MinDistance", opts.MinDistance, ...
            "MaxNumPoints", opts.MaxNumPoints), ...
        "Response", R, ...
        "MaximaMask", maximaMask, ...
        "Mask", mask, ...
        "Values", values);

    if opts.ShowPlots
        showPointPreview_(I, points, "Extended maxima puncta");
    end
end

function [points,values] = applyPointLimits_(points,values,minDistance,maxNumPoints)
%APPLYPOINTLIMITS_ Sort by strength and apply distance/count constraints.

    if isempty(points)
        return
    end

    [values,order] = sort(values, "descend");
    points = points(order,:);

    if minDistance > 0 && size(points,1) > 1
        keep = true(size(points,1),1);
        minDistSq = minDistance.^2;

        for k = 1:size(points,1)
            if ~keep(k)
                continue
            end

            dxy = points(k+1:end,:) - points(k,:);
            reject = sum(dxy.^2,2) < minDistSq;
            keep(k+find(reject)) = false;
        end

        points = points(keep,:);
        values = values(keep);
    end

    if isfinite(maxNumPoints) && size(points,1) > maxNumPoints
        points = points(1:maxNumPoints,:);
        values = values(1:maxNumPoints);
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
