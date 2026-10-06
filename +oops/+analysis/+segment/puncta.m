% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [candidate,enhanced,parameters] = puncta(input,recipe)
%PUNCTA Enhance compact signals, then use Otsu or an explicit manual threshold.

% Median-filtered top-hat signal emphasizing compact bright structures.
enhanced = medfilt2(input-imopen(input,strel('disk',3,0)));

% Maximum enhanced intensity used to scale the threshold input to [0,1].
peak = max(enhanced,[],'all');

if peak > 0
    enhanced = enhanced/peak;
end

% Recipe snapshot containing the automatically determined Otsu threshold.
parameters = recipe.withAutomatic(struct('Threshold',graythresh(enhanced)));

% Unfiltered foreground pixels exceeding the recipe's effective threshold.
candidate = enhanced > parameters.Values.Threshold;
end
