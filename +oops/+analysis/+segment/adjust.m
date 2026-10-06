% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [mask,lists,diagnostics] = adjust(average,cached,recipe)
%ADJUST Reapply adjustable segmentation parameters to existing enhancement data.
% Preview and commit use the same strategy callback and component filters.
% Automatic reset uses the original algorithm-selected parameters in the recipe.

arguments
    average (:,:) double
    cached (1,1) struct
    recipe (1,1) oops.analysis.segment.Parameters
end
try

    % Catalog entry supplying this strategy's cached-preview callback.
    definition = oops.analysis.segment.strategies(recipe.Strategy);

    if isempty(definition.Preview)
        % A future strategy without a cached rethresholding operation can still
        % use its full algorithm; currently Puncta supplies the cached path.
        [mask,lists,diagnostics] = oops.analysis.segment.mask(average,recipe);
        return;
    end

    if ~isfield(cached,'Strategy') || string(cached.Strategy) ~= recipe.Strategy || ...
            ~isfield(cached,'Enhanced') || ~isequal(size(cached.Enhanced),size(average))
        error('oops:analysis:InvalidSegmentationCache','Run segmentation again before adjusting parameters.');
    end

    % Foreground generated from cached enhancement using the adjusted recipe.
    candidate = definition.Preview(cached,recipe);

    % Filtered foreground, retained objects, and updated recipe counts.
    [mask,lists,recipe] = oops.analysis.segment.filter(candidate,average,recipe);

    % Copy of the existing enhancement cache to pair with the new recipe.
    diagnostics = cached;
    diagnostics.Parameters = recipe;

    if isfield(recipe.Values,'Threshold')
        diagnostics.Threshold = recipe.Values.Threshold;
    end

catch ME
    oops.Log.EXCEPTION(ME);
    rethrow(ME);
end
end
