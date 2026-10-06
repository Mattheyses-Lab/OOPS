% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function output = interleaveRows(a,b)
%INTERLEAVEROWS Alternate matching graph-edge endpoint arrays by row.
% This is the row mode of the legacy Interleave2DArrays helper used by the
% fallback graph-ordering branch in the centerline algorithm.

if ~isequal(size(a),size(b)) || ndims(a) > 2 || any(size(a) == 0)
    error('oops:analysis:InvalidInterleaveInput','Interleaved arrays must be matching, nonempty 2-D arrays.');
end

% Preallocated output with two rows for each input edge.
output = zeros(2*size(a,1),size(a,2),'like',a);
output(1:2:end,:) = a;
output(2:2:end,:) = b;

end
