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

function txt = formatKeyValueText(keys, values)
%FORMATKEYVALUETEXT Formats two cell arrays of char vectors as a text table for display
    % maximum length of the left column of text
    maxLen = max(cellfun(@numel, keys));
    % add each line of the table to separate cell
    lines = cellfun(@(k,v) ...
        sprintf('%-*s  %s', maxLen, k, v), ...
        keys, values, 'UniformOutput', false);
    % join all lines with newline
    txt = strjoin(lines, newline);
end