% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

function kv = toKeyValueCell(S)
%MATLABX.STRUCT.TOKEYVALUECELL  Convert a scalar struct to key-value pairs.
%
%   kv = matlabx.struct.toKeyValueCell(S) returns a 1-by-(2N) cell array containing
%   alternating field names and values from the scalar struct S.

    arguments
        S (1,1) struct
    end

    keys = fieldnames(S);
    values = struct2cell(S);

    kv = reshape([keys.'; values.'], 1, []);
end