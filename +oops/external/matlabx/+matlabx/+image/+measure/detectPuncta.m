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

function [points,mask] = detectPuncta(I,opts)
%DETECTPUNCTA Detect puncta candidates with reconstruction and regional maxima.
%
%   P = matlabx.image.measure.detectPuncta(I) detects puncta-like regional
%   maxima in the 2-D image I and returns an N-by-2 array of [x y]
%   coordinates.
%
%   [P,MASK] = matlabx.image.measure.detectPuncta(...) also returns a binary
%   mask with true pixels at the detected candidate locations.
%
%   This detector is intentionally simple: it rescales the image, performs
%   open-close by reconstruction with a disk structuring element, and then
%   extracts connected regional maxima centroids. For a common entry point
%   that can also run SURF-based detection, see
%   matlabx.image.measure.detectPoints.

    arguments
        % image to process
        I (:,:)
        % radius of disk-shaped structuring element
        opts.DiskRadius (1,1) double = 1
        % whether to display output plots
        opts.ShowPlots (1,1) logical = false
    end

    % --- normalize input ---
    if ~isa(I, "double")
        I = im2double(I);
    end
    I = rescale(I);

    sz = size(I);

    % --- locate puncta ---

    % perform open-close by reconstruction
    SE = strel('disk',opts.DiskRadius,0);
    I_ocbr = matlabx.image.process.openCloseByReconstruct(I,SE);

    % find regional maxima
    I_reg_max = imregionalmax(I_ocbr,8);

    % extract centroids of regional maxima mask
    CC = bwconncomp(I_reg_max);
    props = regionprops(CC, I_reg_max, 'Centroid');
    if isempty(props)
        points = zeros(0,2);
    else
        points = cat(1, props.Centroid);
    end


    % --- make puncta seed mask --- 
    if isempty(points)
        mask = false(sz);
    else
        mask = matlabx.image.mask.fromPoints(points,sz);
    end


    % --- show plots ---
    if opts.ShowPlots
        ax = matlabx.app.quickshow(I,turbo);
        hAx = ax.getAxes();
        % Plot centroids on the original image if requested
        hold(hAx, 'on');
        plot(hAx, points(:,1), points(:,2), ...
            'MarkerSize', 10, ...
            'Marker', 'x', ...
            'Color', [1 1 1], ...
            'LineStyle', 'none', ...
            'LineWidth', 1);
        hold(hAx, 'off');

        matlabx.app.quickshow(I_ocbr,turbo);
    end

end
