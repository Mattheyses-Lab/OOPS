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

function szChar = size2char(A)
%SIZE2CHAR Return size of array as a character vector
%   szChar = SIZE2CHAR(A) returns a character vector like:
%       '5x7'
%       '5x7x3'
%       '5x7x1x4'
%
%   It always includes the first two dimensions, and includes any
%   additional dimensions up to the last dimension whose size is > 1.

    sz = size(A);

    % Always keep first two dimensions
    if isempty(A)
        lastDim = 2;
    else
        lastDim = max(2, find(sz > 1, 1, 'last'));
    end

    % add each dimension of the array to separate cell
    dims = arrayfun(@(s) sprintf('%d', s), sz(1:lastDim), 'UniformOutput', false);
    % join all dims with an 'x'
    szChar = strjoin(dims, 'x');

end