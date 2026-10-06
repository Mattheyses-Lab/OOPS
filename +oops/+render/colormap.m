% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function map = colormap(settings,domain)
%COLORMAP Resolve a domain's independent registry choice; circularize axial maps.

% Registry category saved independently for this display domain.
category = settings.(domain+"Category");

% Registered color lookup table selected for the requested domain.
map = matlabx.colors.maps.Registry.map(settings.(domain),category);

if domain == "Azimuth"
    % Same bridge used by old OOPS: keep the central 192 colors and smoothly
    % connect the trimmed ends across the 180-degree axial seam.

    % Interpolated colors joining the trimmed azimuth-map endpoints across the seam.
    bridge = linspace(0,1,64)' .* map(32,:) + linspace(1,0,64)' .* map(224,:);
    map = [bridge(33:64,:);map(33:224,:);bridge(1:32,:)];
end

end
