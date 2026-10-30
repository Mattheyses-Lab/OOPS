classdef ControlTableCellEditedData < event.EventData
%CONTROLTABLECELLEDITEDDATA Payload for a ControlTable CellEdited event.

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

    % Immutable description of one committed cell edit.
    properties (SetAccess=immutable)
        % Numeric row index at the time the edit was committed.
        Row (1,1) double
        % Numeric column index at the time the edit was committed.
        Column (1,1) double
        % Name of the authoritative Data table variable.
        Name (1,1) string
        % Value stored before the edit.
        OldValue
        % Value stored after the edit.
        NewValue
    end

    methods
        function obj = ControlTableCellEditedData(row,column,name,oldValue,newValue)
        %CONTROLTABLECELLEDITEDDATA Construct a committed-edit payload.
            obj.Row = row;
            obj.Column = column;
            obj.Name = string(name);
            obj.OldValue = oldValue;
            obj.NewValue = newValue;
        end
    end
end
