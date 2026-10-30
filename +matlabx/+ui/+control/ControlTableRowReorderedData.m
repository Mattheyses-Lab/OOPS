classdef ControlTableRowReorderedData < event.EventData
%CONTROLTABLEROWREORDEREDDATA Payload for one completed row move.

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

    properties (SetAccess=immutable)
        % Stable identity of the moved row.
        RowID (1,1) string
        % Numeric position before the move.
        OldRow (1,1) double
        % Numeric position after the move.
        NewRow (1,1) double
    end

    methods
        function obj = ControlTableRowReorderedData(rowID,oldRow,newRow)
        %CONTROLTABLEROWREORDEREDDATA Construct a row-reordering payload.
            obj.RowID = string(rowID);
            obj.OldRow = double(oldRow);
            obj.NewRow = double(newRow);
        end
    end
end
