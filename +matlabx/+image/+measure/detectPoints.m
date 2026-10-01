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

function [points,info] = detectPoints(I,opts)
%DETECTPOINTS Detect candidate point locations with a selectable method.
%
%   P = matlabx.image.measure.detectPoints(I) detects candidate point
%   locations in the 2-D image I and returns an N-by-2 array of [x y]
%   coordinates.
%
%   [P,INFO] = matlabx.image.measure.detectPoints(...) also returns a
%   diagnostic struct describing the method, parameters, and any
%   method-specific intermediate output. This is meant for tuning apps,
%   previews, and later provenance tracking in analysis pipelines.
%
%   Methods
%       "regionalMaxima" : matlabx.image.measure.detectPuncta detector.
%                          It performs open-close by reconstruction and
%                          extracts regional-maxima centroids. Its primary
%                          knob is DiskRadius.
%
%       "surf"           : SURF feature detector, ported from the
%                          desmostorm detectBlobs helper. Its knobs are
%                          MetricThreshold, NumOctaves, and NumScaleLevels.
%
%       "log"            : Laplacian-of-Gaussian blob response followed by
%                          local-maximum detection.
%
%       "dog"            : Difference-of-Gaussians blob response followed
%                          by local-maximum detection.
%
%       "extendedMaxima" : imextendedmax-based regional maxima detector
%                          with an H-maxima prominence threshold.
%
%   Examples
%       points = matlabx.image.measure.detectPoints(I);
%
%       [points,info] = matlabx.image.measure.detectPoints(I, ...
%           "Method", "surf", ...
%           "MetricThreshold", 25, ...
%           "NumOctaves", 3, ...
%           "NumScaleLevels", 4);
%
%       [points,info] = matlabx.image.measure.detectPoints(I, ...
%           "Method", "regionalMaxima", ...
%           "DiskRadius", 2);

    arguments
        % Image to search for puncta candidates.
        I (:,:)
        % Detector name. Aliases are normalized below.
        opts.Method (1,1) string = "regionalMaxima"
        % Regional-maxima detector structuring element radius.
        opts.DiskRadius (1,1) double = 1
        % SURF strongest feature threshold.
        opts.MetricThreshold (1,1) double {mustBePositive(opts.MetricThreshold)} = 50
        % SURF octave count.
        opts.NumOctaves (1,1) double {mustBeInteger,mustBeGreaterThanOrEqual(opts.NumOctaves,1)} = 3
        % SURF scale levels per octave.
        opts.NumScaleLevels (1,1) double {mustBeInteger,mustBeGreaterThanOrEqual(opts.NumScaleLevels,3)} = 3
        % LoG sigma in pixels.
        opts.Sigma (1,1) double {mustBeNonnegative(opts.Sigma)} = 1.5
        % Optional LoG filter size.
        opts.FilterSize (1,1) double = NaN
        % Smaller DoG sigma in pixels.
        opts.Sigma1 (1,1) double {mustBePositive(opts.Sigma1)} = 1
        % Larger DoG sigma in pixels.
        opts.Sigma2 (1,1) double {mustBePositive(opts.Sigma2)} = 2
        % Minimum LoG/DoG response accepted as a puncta candidate.
        opts.MinResponse (1,1) double = 0
        % Extended-maxima H threshold.
        opts.H (1,1) double {mustBeNonnegative(opts.H)} = 0.05
        % Minimum accepted distance between detected points.
        opts.MinDistance (1,1) double {mustBeNonnegative(opts.MinDistance)} = 0
        % Maximum number of strongest points to return.
        opts.MaxNumPoints (1,1) double {mustBePositive(opts.MaxNumPoints)} = Inf
        % Whether to display detector-specific preview figures.
        opts.ShowPlots (1,1) logical = false
    end

    method = normalizeMethod_(opts.Method);

    switch method
        case "regionalMaxima"
            [points,mask] = matlabx.image.measure.detectPuncta(I, ...
                "DiskRadius", opts.DiskRadius, ...
                "ShowPlots", opts.ShowPlots);

            info = struct( ...
                "Method", method, ...
                "DisplayName", "Regional maxima", ...
                "Parameters", struct("DiskRadius", opts.DiskRadius), ...
                "Mask", mask);

        case "surf"
            [points,features] = matlabx.image.measure.detectSurfPoints(I, ...
                "MetricThreshold", opts.MetricThreshold, ...
                "NumOctaves", opts.NumOctaves, ...
                "NumScaleLevels", opts.NumScaleLevels, ...
                "ShowPlots", opts.ShowPlots);

            info = struct( ...
                "Method", method, ...
                "DisplayName", "SURF features", ...
                "Parameters", struct( ...
                    "MetricThreshold", opts.MetricThreshold, ...
                    "NumOctaves", opts.NumOctaves, ...
                    "NumScaleLevels", opts.NumScaleLevels), ...
                "Features", features);

        case "log"
            [points,info] = matlabx.image.measure.detectLogPuncta(I, ...
                "Sigma", opts.Sigma, ...
                "FilterSize", opts.FilterSize, ...
                "MinResponse", opts.MinResponse, ...
                "MinDistance", opts.MinDistance, ...
                "MaxNumPoints", opts.MaxNumPoints, ...
                "ShowPlots", opts.ShowPlots);

        case "dog"
            [points,info] = matlabx.image.measure.detectDogPuncta(I, ...
                "Sigma1", opts.Sigma1, ...
                "Sigma2", opts.Sigma2, ...
                "MinResponse", opts.MinResponse, ...
                "MinDistance", opts.MinDistance, ...
                "MaxNumPoints", opts.MaxNumPoints, ...
                "ShowPlots", opts.ShowPlots);

        case "extendedMaxima"
            [points,info] = matlabx.image.measure.detectExtendedMaximaPuncta(I, ...
                "H", opts.H, ...
                "Sigma", opts.Sigma, ...
                "MinDistance", opts.MinDistance, ...
                "MaxNumPoints", opts.MaxNumPoints, ...
                "ShowPlots", opts.ShowPlots);
    end

    % Keep common summary fields at the top level so the tuning app can
    % display detector results without special-casing each method.
    info.NumPoints = size(points,1);
    info.Points = points;
end

function method = normalizeMethod_(method)
%NORMALIZEMETHOD_ Convert user-facing method aliases to canonical names.

    method = lower(strtrim(string(method)));
    method = replace(method, ["-","_"," "], "");

    switch method
        case {"regionalmaxima","regionalmax","detectpuncta","findpuncta","reconstructionmaxima"}
            method = "regionalMaxima";
        case {"surf","surffeatures","detectblobs","detectsurfpoints"}
            method = "surf";
        case {"log","laplacianofgaussian","logpuncta","detectlogpuncta"}
            method = "log";
        case {"dog","differenceofgaussians","dogpuncta","detectdogpuncta"}
            method = "dog";
        case {"extendedmaxima","extendedmax","hmaxima","imextendedmax"}
            method = "extendedMaxima";
        otherwise
            error("matlabx:image:measure:detectPoints:UnknownMethod", ...
                "Unknown puncta detection method '%s'. Valid methods are 'regionalMaxima', 'surf', 'log', 'dog', and 'extendedMaxima'.", ...
                method);
    end
end
