% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [mask,lists,parameters] = filter(candidate,average,parameters)
%FILTER Apply common component filters after any segmentation algorithm.
% Ranking uses the original average input, not strategy-specific enhancement.
% Zero maximum means unlimited. Stable component order resolves brightness ties.

% Strategy-independent object filters stored in the committed recipe.
settings = parameters.Common;

% Border exclusion width, clipped to the available image dimensions.
width = min(settings.BorderWidth,min(size(candidate)));

if width > 0
    candidate(1:width,:) = false;
    candidate(end-width+1:end,:) = false;
    candidate(:,1:width) = false;
    candidate(:,end-width+1:end) = false;
end

candidate = bwareaopen(candidate,settings.MinimumArea,settings.Connectivity);

% Connected components remaining after border and minimum-area filtering.
cc = bwconncomp(candidate,settings.Connectivity);

% Number of candidate objects before applying the maximum-object limit.
count = cc.NumObjects;

% Logical flags marking which candidate components will be retained.
keep = true(1,count);

if settings.MaxObjects > 0 && count > settings.MaxObjects

    % Mean original-input intensity for each candidate component.
    brightness = zeros(count,1);

    % Compute each candidate object's mean intensity for brightness ranking.
    for k = 1:count

        % Original average-intensity pixels belonging to the component being ranked.
        values = average(cc.PixelIdxList{k});
        values = values(isfinite(values));

        if isempty(values)
            brightness(k) = -Inf;
        else
            brightness(k) = mean(values);
        end

    end

    % Component indices sorted by brightness, with original order breaking ties.
    [~,order] = sortrows([-brightness,(1:count)'],[1 2]);
    keep(:) = false;
    keep(order(1:settings.MaxObjects)) = true;
end

% Retained component pixel-index lists in their original collection order.
lists = reshape(cc.PixelIdxList(keep),1,[]);

% Final binary mask reconstructed from the retained pixel-index lists.
mask = false(size(candidate));

% Set foreground pixels for each retained object in the final mask.
for k = 1:numel(lists)
    mask(lists{k}) = true;
end

parameters = parameters.withCounts(count,numel(lists));
end
