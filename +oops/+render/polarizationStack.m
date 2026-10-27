% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function data = polarizationStack(image,values)
%POLARIZATIONSTACK Wrap four full-size or cropped planes using the input CZT layout.

arguments
    image (1,1) oops.model.Image
    values {mustBeNumeric,mustBeReal}
end

if ndims(values) ~= 3 || size(values,3) ~= 4
    error('oops:render:InvalidPolarizationStack', ...
        'Polarization values must be a Y-by-X-by-4 numeric array.');
end

locations = image.FrameLocations;
sizeCZT = [image.Input.NumComponents image.Input.SizeZ image.Input.SizeT];

% Preserve the acquisition layout when all four mapped planes fit within it.
if size(locations,1) == 4 && all(locations(:) >= 1) && ...
        all(locations(:,1) <= sizeCZT(1)) && ...
        all(locations(:,2) <= sizeCZT(2)) && ...
        all(locations(:,3) <= sizeCZT(3)) && ...
        size(unique(locations,'rows'),1) == 4
    components = cell(1,sizeCZT(1));

    for component = 1:sizeCZT(1)
        components{component} = zeros( ...
            size(values,1),size(values,2),1,sizeCZT(2),sizeCZT(3), ...
            'like',values);
    end

    for k = 1:4
        component = locations(k,1);
        components{component}(:,:,1,locations(k,2),locations(k,3)) = ...
            values(:,:,k);
    end

    data = matlabx.image.Image5D.fromComponents(components);
    return;
end

% Four time points are the conventional fallback for sequential acquisition.
stack = reshape(values,size(values,1),size(values,2),1,1,4);
data = matlabx.image.Image5D.fromComponents(stack);
end
