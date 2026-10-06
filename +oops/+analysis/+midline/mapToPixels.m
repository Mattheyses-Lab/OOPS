% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function pixelValues = mapToPixels(curve,curveValues,mask)
%MAPTOPIXELS Assign each object pixel the value of its nearest curve point.
% Output order matches find(mask), which also matches the stored ascending
% linear pixel-index order after translating the crop into the parent image.

if any(isnan(curve(:))) || isempty(curveValues)
    pixelValues = [];
    return;
end

% Linear indices and local row/column coordinates of object pixels.
objectIndices = find(mask);
[objectRows,objectColumns] = ind2sub(size(mask),objectIndices);

% Distance from every object pixel to every sampled curve coordinate.
distance = hypot(objectColumns'-curve(:,1),objectRows'-curve(:,2));

% Nearest midline sample for each object pixel.
[~,nearest] = min(distance,[],1);

% Pixel values returned in ascending local linear-index order.
valuesImage = zeros(size(mask));
valuesImage(objectIndices) = curveValues(nearest);
pixelValues = valuesImage(mask);

end
