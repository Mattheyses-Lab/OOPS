% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function stack = readStack(input)
%READSTACK Read canonical four-angle planes as doubles without intensity rescaling.

% Input plane addresses in 0°/45°/90°/135° order as [component Z T].
locations = oops.io.fourAngleLocations(input);

% Double-precision [row column angle] array populated from those planes.
stack = zeros(input.SizeY,input.SizeX,4);

% Read each polarization plane into the canonical four-angle stack.
for k = 1:4
    stack(:,:,k) = double(input.getPlane(locations(k,1),locations(k,2),locations(k,3)));
end

end
