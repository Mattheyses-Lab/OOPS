% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [mask,pixelLists,diagnostics] = mask(average,settings)
%MASK Dispatch segmentation, then independently filter its connected components.
% Otsu is authoritative: limiting objects never changes the chosen threshold.

arguments
    average (:,:) double
    settings
end

if isa(settings,'oops.config.Segmentation')

    % Segmentation parameter snapshot created from settings or supplied directly.
    recipe = oops.analysis.segment.Parameters(settings);
elseif isa(settings,'oops.analysis.segment.Parameters') && isscalar(settings)
    recipe = settings;
else
    error('oops:analysis:InvalidParameters','Expected segmentation settings or a parameter snapshot.');
end

% Working segmentation image with invalid/negative intensities removed.
input = average;
input(~isfinite(input)) = 0;
input = max(input,0);

% Maximum working intensity used for strategy-input normalization.
peak = max(input,[],'all');

if peak > 0
    input = input/peak;
end

% Catalog entry supplying the requested strategy's algorithm callback.
definition = oops.analysis.segment.strategies(recipe.Strategy);

% Unfiltered mask, enhanced image, and algorithm-updated parameter snapshot.
[candidate,enhanced,recipe] = definition.Algorithm(input,recipe);

% Filtered mask, retained object membership, and updated component counts.
[mask,pixelLists,recipe] = oops.analysis.segment.filter(candidate,average,recipe);

% Enhanced-image cache and recipe metadata retained for inspection/adjustment.
diagnostics = struct('Strategy',recipe.Strategy,'Enhanced',enhanced,'Parameters',recipe);
% Keep the existing diagnostic name useful for callers inspecting puncta results.
if isfield(recipe.Values,'Threshold')
    diagnostics.Threshold = recipe.Values.Threshold;
end

end
