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

function [points,mask,values] = findLocalMaxima(R,opts)
%FINDLOCALMAXIMA Find local maxima in a 2-D response image.
%
%   P = matlabx.image.measure.findLocalMaxima(R) returns an N-by-2 array of
%   [x y] coordinates for regional maxima in response image R.
%
%   [P,MASK,VALUES] = matlabx.image.measure.findLocalMaxima(...) also
%   returns the maxima mask and response values at the accepted points.
%
%   Name-value options
%       MinValue     : Keep only maxima with R >= MinValue.
%       MinDistance  : Greedily suppress weaker maxima within this distance
%                      of a stronger maximum.
%       MaxNumPoints : Keep at most this many strongest maxima.
%       Connectivity : Connectivity passed to imregionalmax.

    arguments
        % Response image whose local maxima should be detected.
        R (:,:) double
        % Minimum accepted response value.
        opts.MinValue (1,1) double = -Inf
        % Minimum allowed distance between accepted maxima, in pixels.
        opts.MinDistance (1,1) double {mustBeNonnegative(opts.MinDistance)} = 0
        % Maximum number of points to keep.
        opts.MaxNumPoints (1,1) double {mustBePositive(opts.MaxNumPoints)} = Inf
        % Pixel connectivity used by imregionalmax.
        opts.Connectivity (1,1) double {mustBeMember(opts.Connectivity,[4 8])} = 8
    end

    R(~isfinite(R)) = -Inf;

    mask = imregionalmax(R, opts.Connectivity) & R >= opts.MinValue;
    [y,x] = find(mask);

    if isempty(x)
        points = zeros(0,2);
        values = zeros(0,1);
        mask = false(size(R));
        return
    end

    values = R(mask);
    [values,order] = sort(values, "descend");
    points = [x(order), y(order)];

    % Greedy non-maximum suppression keeps the strongest point first, then
    % rejects nearby weaker points. This is intentionally simple and stable
    % for interactive tuning.
    if opts.MinDistance > 0 && size(points,1) > 1
        keep = true(size(points,1),1);
        minDistSq = opts.MinDistance.^2;

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

    if isfinite(opts.MaxNumPoints) && size(points,1) > opts.MaxNumPoints
        points = points(1:opts.MaxNumPoints,:);
        values = values(1:opts.MaxNumPoints);
    end

    mask = false(size(R));
    if ~isempty(points)
        idx = sub2ind(size(R), points(:,2), points(:,1));
        mask(idx) = true;
    end
end
