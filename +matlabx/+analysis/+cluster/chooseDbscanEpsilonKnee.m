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

function epsilon = chooseDbscanEpsilonKnee(X, minPts, opts)
%CHOOSEDBSCANEPSILONKNEE Choose DBSCAN epsilon via k-distance knee.
%
% Inputs
%   X      : NxD data
%   minPts : DBSCAN MinPts
%   opts (optional Name-Value arguments)
%       MakePlot   (default true)
%       SmoothFrac (default 0.01)   % fraction of points for movmedian smoothing
%
% Outputs:
%   epsilon  : suggested optimal epsilon (in original distance units)

    arguments
        X (:,:)
        minPts (1,1) double = 3
        opts.MakePlot (1,1) logical = false
        opts.SmoothFrac (1,1) double = 0.01
    end
    
    n = size(X,1);
    if n < minPts + 1
        epsilon = NaN;
        return
    end
    
    % k-distance (k = MinPts) excluding self
    [~, D] = knnsearch(X, X, 'K', minPts+1);
    kDist = D(:, end);
    kdSorted = sort(kDist, 'ascend');
    
    y = kdSorted(:);
    m = numel(y);
    x = (1:m)';
    
    % Optional smoothing (helps when curve is jagged)
    w = max(5, round(m * opts.SmoothFrac));
    ySm = smoothdata(y, 'movmedian', w);
    
    % Normalize x,ySm to [0,1]
    xn = (x - x(1)) / (x(end) - x(1));
    yn = (ySm - ySm(1)) / (ySm(end) - ySm(1) + eps);
    
    % Line segment from (0,0) to (1,1). Perpendicular distance in 2D:
    % distance from point (xn,yn) to line y=x is |yn - xn| / sqrt(2)
    d = abs(yn - xn) / sqrt(2);
    [~, kneeIdx] = max(d);
    
    % Return epsilon in ORIGINAL distance units (not log/smoothed)
    epsilon = y(kneeIdx);
    

    %% make plot if requested

    if opts.MakePlot
    
        % True (unnormalized) values used in your knee selection
        m = numel(y);
        x = (1:m)';              % true x (sorted index)
        yTrue = y(:);            % true y (k-distance)
        epsilon = yTrue(kneeIdx); % true epsilon
    
        % Normalize to [0,1] for geometrically correct perpendiculars
        xn = rescale(x);                     % 0..1
        yn = rescale(yTrue);                 % 0..1 (monotone)
        P0 = [xn(kneeIdx), yn(kneeIdx)];     % knee point in normalized coords
        P1 = [xn(1), yn(1)];                 % (0,0)
        P2 = [xn(end), yn(end)];             % (1,1)
    
        figure;
        plot(xn, yn, 'LineWidth', 1); hold on
        plot(P0(1), P0(2), 'o', 'LineWidth', 2)
    
        % Chord between endpoints (dashed)
        plot([P1(1) P2(1)], [P1(2) P2(2)], '--', 'LineWidth', 1)
    
        % Perpendicular projection onto the chord (in normalized coords)
        v = P2 - P1;
        w = P0 - P1;
        t = dot(w, v) / dot(v, v);
        t = max(0, min(1, t));   % clamp to segment
        Pproj = P1 + t * v;
    
        % Perpendicular segment (will LOOK perpendicular because plot is square)
        plot([P0(1) Pproj(1)], [P0(2) Pproj(2)], '-', 'LineWidth', 1.5)
    
        % Make plot square in normalized space
        xlim([0 1]); ylim([0 1]);
        pbaspect([1 1 1]);
        grid on
    
        % ---- Replace tick labels with TRUE values ----
        % Choose tick locations in normalized space
        xt = linspace(0, 1, 6);
        yt = linspace(0, 1, 6);
        xticks(xt);
        yticks(yt);
    
        % Map normalized ticks back to original x and y scales
        % x is linear, so easy:
        xLabels = round(1 + xt * (m-1));
    
        % y mapping is linear because we used rescale(yTrue):
        yMin = yTrue(1);
        yMax = yTrue(end);
        yLabels = yMin + yt * (yMax - yMin);
    
        % Apply as strings (tweak formatting if you want)
        xticklabels(string(xLabels));
        yticklabels(compose('%.4g', yLabels));
    
        xlabel('Sorted point index (true)')
        ylabel(sprintf('%d-distance (true units)', minPts))
        title(sprintf('k-distance knee (MinPts=%d), eps \\approx %.4g', minPts, epsilon))
    
        % Label eps at the knee point (true units)
        text(P0(1), P0(2), sprintf('  eps=%.4g', epsilon), ...
            'VerticalAlignment','bottom', 'HorizontalAlignment','left');
    
        hold off
    end

end