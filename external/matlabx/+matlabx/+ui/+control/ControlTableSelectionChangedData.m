classdef ControlTableSelectionChangedData < event.EventData
%CONTROLTABLESELECTIONCHANGEDDATA Payload for ControlTable selection changes.

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

    % Immutable numeric row transition for a selection change.
    properties (SetAccess=immutable)
        % Previously selected row, or zero when none was selected.
        OldRow (1,1) double
        % Newly selected row, or zero when selection was cleared.
        NewRow (1,1) double
    end

    methods
        function obj = ControlTableSelectionChangedData(oldRow,newRow)
        %CONTROLTABLESELECTIONCHANGEDDATA Construct a selection-change payload.
            obj.OldRow = oldRow;
            obj.NewRow = newRow;
        end
    end
end
