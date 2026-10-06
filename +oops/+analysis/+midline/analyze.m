% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function result = analyze(mask)
%ANALYZE Trace one object and derive its legacy tangent-based geometry.
% MASK is an object-only padded crop. Midline coordinates remain local [x y]
% so the caller can translate them using the crop geometry that produced MASK.

% Ordered centerline coordinates calculated by the legacy Voronoi algorithm.
coordinates = oops.analysis.midline.trace(mask);

% Axial tangent at each sampled coordinate along the centerline.
tangents = oops.analysis.midline.tangent(coordinates);

% Tangent assigned to every object pixel from its nearest centerline sample.
pixelTangents = oops.analysis.midline.mapToPixels(coordinates,tangents,mask);

% Scalar geometry derived using the same formulas as legacy OOPS.
lengthValue = oops.analysis.midline.curveLength(coordinates);
orientation = axialMean(tangents);
tortuosity = NaN;

if ~isempty(coordinates) && ~any(isnan(coordinates(:)))

    % Straight endpoint distance used as the denominator of tortuosity.
    endpointDistance = oops.analysis.midline.curveLength(coordinates([1 end],:));
    tortuosity = lengthValue/endpointDistance;
end

% Plain result struct keeps the numerical package independent of the model.
result = struct( ...
    'Coordinates',coordinates, ...
    'Tangents',tangents, ...
    'PixelTangents',pixelTangents, ...
    'Length',lengthValue, ...
    'Tortuosity',tortuosity, ...
    'Orientation',orientation);

end

function value = axialMean(angles)
%AXIALMEAN Calculate the mean undirected angle in degrees.

value = NaN;

if isempty(angles)
    return;
end

% Doubled-angle resultant converts axial data into circular data. This is
% intentionally the same expression used by legacy getAzimuthAverage.
value = rad2deg(0.5*angle(mean(exp(2i*angles))));

end
