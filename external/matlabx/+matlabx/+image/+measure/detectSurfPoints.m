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

function [points,features] = detectSurfPoints(I,opts)
%DETECTSURFPOINTS Detect blob-like puncta candidates with SURF features.
%
%   P = matlabx.image.measure.detectSurfPoints(I) detects SURF
%   (Speeded-Up Robust Features) points in the 2-D image I and returns an
%   N-by-2 array of point locations as [x y] coordinates.
%
%   [P,FEATURES] = matlabx.image.measure.detectSurfPoints(...) also
%   returns the SURFPoints object produced by detectSURFFeatures. The
%   feature object retains useful diagnostic values such as scale, metric,
%   and orientation, which can be helpful while tuning detection settings.
%
%   Name-value options
%       MetricThreshold : Strongest feature threshold. Smaller values are
%                         more sensitive and usually return more points.
%       NumOctaves      : Number of octaves. Larger values can detect
%                         larger blobs.
%       NumScaleLevels  : Number of scale levels per octave.
%       ShowPlots       : Display a quick visual diagnostic.
%
%   This function is intentionally a light matlabx wrapper around MATLAB's
%   detectSURFFeatures so app code can use the same interface shape as the
%   other puncta detectors.

    arguments
        % Image to search for SURF points.
        I (:,:)
        % Strongest feature threshold. Lower values detect more features.
        opts.MetricThreshold (1,1) double {mustBePositive(opts.MetricThreshold)} = 50
        % Number of octaves. Recommended starting values are 1 to 4.
        opts.NumOctaves (1,1) double {mustBeInteger,mustBeGreaterThanOrEqual(opts.NumOctaves,1)} = 3
        % Number of scale levels per octave. MATLAB requires at least 3.
        opts.NumScaleLevels (1,1) double {mustBeInteger,mustBeGreaterThanOrEqual(opts.NumScaleLevels,3)} = 3
        % Whether to display a quick ImageAxes preview with SURF markers.
        opts.ShowPlots (1,1) logical = false
    end

    % detectSURFFeatures lives in Computer Vision Toolbox. Keep the error
    % message explicit so app-level callers can disable this option cleanly.
    if exist("detectSURFFeatures","file") ~= 2
        error("matlabx:image:measure:detectSurfPoints:MissingToolbox", ...
            "detectSurfPoints requires MATLAB's detectSURFFeatures function.");
    end

    % Match the historical desmostorm wrapper closely: doubles are passed
    % through as-is, while integer/logical inputs are converted to MATLAB's
    % standard floating-point image range.
    if ~isa(I,"double")
        I = im2double(I);
    end

    features = detectSURFFeatures(I, ...
        "MetricThreshold", opts.MetricThreshold, ...
        "NumOctaves", opts.NumOctaves, ...
        "NumScaleLevels", opts.NumScaleLevels);

    points = double(features.Location);

    if opts.ShowPlots
        ax = matlabx.app.quickshow(I, "Tools", {'Zoom'}, "Colormap", turbo);
        hAx = ax.getAxes();
        hold(hAx, "on");
        features.plot(hAx);
        hold(hAx, "off");
    end
end
