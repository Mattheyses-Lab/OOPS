% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [names,values] = processingSummary(images)
%PROCESSINGSUMMARY Count current numerical outputs without loading input pixels.
%
% Report counts rather than an all-done flag: an empty collection should not
% appear processed, and partially analyzed groups/projects remain informative.

names = ["FFC performed","Mask generated","FPM stats calculated"];
counts = zeros(1,3);

for image = reshape(images,1,[])
    counts(1) = counts(1) + oops.model.internal.hasCurrentCorrection(image);
    counts(2) = counts(2) + ~isempty(image.Mask);
    counts(3) = counts(3) + (~isempty(image.Order) && ~isempty(image.Azimuth));
end

values = arrayfun(@(count) sprintf('%d / %d images',count,numel(images)), ...
    counts,'UniformOutput',false);
end
