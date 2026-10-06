% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function locations = fourAngleLocations(input)
%FOURANGLELOCATIONS Map an unambiguous four-frame source to [component Z T].
% Frame order is 0,45,90,135 degrees. C, Z, and T storage are accepted,
% but mixed axes, RGB data, additional channels, and larger stacks are not.

    arguments
        input (1,1) matlabx.image.Image5D
    end

    % Component, Z, and T lengths checked for a single four-frame axis.
    dimensions = [input.NumComponents,input.SizeZ,input.SizeT];

    if ~(all(dimensions >= 1) && nnz(dimensions == 4) == 1 && prod(dimensions) == 4)
        error( ...
            'oops:io:InvalidFourAngleInput', ...
            'Expected exactly four scalar frames along one component, Z, or T axis.');
    end

    % Image5D components inspected to reject RGB or other nonscalar input.
    components = input.Components;

    % Check every component to ensure all input frames are scalar images.
    for k = 1:numel(components)

        if ~(components(k).IsScalar && ~components(k).IsRGB)
            error( ...
                'oops:io:InvalidFourAngleInput','Polarization frames must be scalar images.');
        end

    end

    % Four [component Z T] addresses initialized before setting the varying axis.
    locations = ones(4,3);
    locations(:,dimensions == 4) = (1:4)';
end
