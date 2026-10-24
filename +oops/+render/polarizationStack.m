% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function data = polarizationStack(image,values)
%POLARIZATIONSTACK Wrap four polarization planes using the input CZT layout.

arguments
    image (1,1) oops.model.Image
    values {mustBeNumeric,mustBeReal}
end

validateattributes(values,{'numeric'}, ...
    {'size',[image.Input.SizeY image.Input.SizeX 4]});

locations = image.FrameLocations;
sizeCZT = [image.Input.NumComponents image.Input.SizeZ image.Input.SizeT];

% Preserve the acquisition layout when all four mapped planes fit within it.
if size(locations,1) == 4 && all(locations(:) >= 1) && ...
        all(locations(:,1) <= sizeCZT(1)) && ...
        all(locations(:,2) <= sizeCZT(2)) && ...
        all(locations(:,3) <= sizeCZT(3)) && ...
        size(unique(locations,'rows'),1) == 4
    stack = zeros([size(values,1) size(values,2) sizeCZT],'like',values);

    for k = 1:4
        stack(:,:,locations(k,1),locations(k,2),locations(k,3)) = values(:,:,k);
    end

    data = matlabx.image.Image5D.fromComponents(stack);
    return;
end

% Four time points are the conventional fallback for sequential acquisition.
stack = reshape(values,size(values,1),size(values,2),1,1,4);
data = matlabx.image.Image5D.fromComponents(stack);
end
