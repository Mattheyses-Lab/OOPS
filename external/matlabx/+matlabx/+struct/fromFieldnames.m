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

function S = fromFieldnames(fnames, vals)
%FROMFIELDNAMES Returns a struct with fields and values specified by cell arrays fnames and vals
    arguments
        fnames (1,:) cell
        vals   (:,:) cell = {}
    end
    % no vals provided, use empty cell
    if isempty(vals); vals = cell(size(fnames)); end
    % vals incorrect shape, error
    if ~isequal(size(fnames),size(vals))
        error('fromFieldnames:IncompatibleArraySizes', ...
            'Arrays must have the same size: fnames (%s) and vals (%s) have different sizes.',...
            matlabx.array.size2char(fnames),matlabx.array.size2char(vals));
    end
    % create one cell array with interleaved fieldnames and values
    field_value_cell = matlabx.array.interleave2D(fnames,vals);
    % create the struct
    S = struct(field_value_cell{:});
end