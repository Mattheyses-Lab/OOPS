% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function values = tangent(midline)
%TANGENT Estimate the legacy axial tangent at every midline coordinate.
% The returned angles are radians in [-pi/2, pi/2]. Image coordinates are
% assumed, with x increasing rightward and y increasing downward.

if any(isnan(midline(:)))
    values = [];
    return;
end

% Number of ordered coordinates in the open midline curve.
nPoints = size(midline,1);

% Extend both ends using the legacy wrapped-neighbor construction.
flankingPoints = 1;
wrapped = [midline(end-flankingPoints:end-1,:);midline;midline(2:flankingPoints+1,:)];

% Coordinates one sample before and after each measurement point.
point1 = wrapped(1:nPoints,:);
point3 = wrapped((1:nPoints)+2*flankingPoints,:);

% Reflect the usual Cartesian tangent to account for downward image y.
values = pi-mod(atan2(point1(:,2)-point3(:,2),point1(:,1)-point3(:,1)),pi);

% Copy the nearest interior tangent onto each endpoint of the open curve.
values(1) = values(2);
values(end) = values(end-1);

% Wrap the undirected orientation into the axial half-circle.
values(values > pi/2) = values(values > pi/2)-pi;

end
