% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function stack = readStack(input)
%READSTACK Read canonical four-angle planes as doubles without intensity rescaling.

% Timing and residency state distinguish disk-backed reads from resident access.
started = tic;
sourceType = string(class(input.Source));
oops.Log.DEBUG(sprintf( ...
    'Reading four-angle stack: source=%s, file-backed=%s, resident=%s, size=%dx%d.', ...
    sourceType,yesNo(input.IsFileBacked),yesNo(input.IsLoaded),input.SizeY,input.SizeX));

% Input plane addresses in 0°/45°/90°/135° order as [component Z T].
locations = oops.io.fourAngleLocations(input);

% Double-precision [row column angle] array populated from those planes.
stack = zeros(input.SizeY,input.SizeX,4);

% Read each polarization plane into the canonical four-angle stack.
for k = 1:4
    planeStarted = tic;
    stack(:,:,k) = double(input.getPlane(locations(k,1),locations(k,2),locations(k,3)));
    oops.Log.DEBUG(sprintf( ...
        'Read polarization plane %d/4 at [C=%d Z=%d T=%d] in %.3f s.', ...
        k,locations(k,1),locations(k,2),locations(k,3),toc(planeStarted)));
end

oops.Log.DEBUG(sprintf('Completed four-angle stack read in %.3f s.',toc(started)));

end

function value = yesNo(tf)
%YESNO Format one logical value for a compact debug message.

if tf
    value = 'yes';
else
    value = 'no';
end
end
