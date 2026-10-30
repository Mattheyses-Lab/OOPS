classdef ControlTableSelectionChangedData < event.EventData
%CONTROLTABLESELECTIONCHANGEDDATA Complete ControlTable selection transition.

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
        % Active row before the completed selection change, or zero.
        OldActiveRow (1,1) double
        % Active row after the completed selection change, or zero.
        NewActiveRow (1,1) double
        % Stable active-row identity before the change, or empty string.
        OldActiveRowID (1,1) string
        % Stable active-row identity after the change, or empty string.
        NewActiveRowID (1,1) string
        % Ordered numeric selection before the change.
        OldSelectedRows (1,:) double
        % Ordered numeric selection after the change.
        NewSelectedRows (1,:) double
        % Ordered stable row identities before the change.
        OldSelectedRowIDs (1,:) string
        % Ordered stable row identities after the change.
        NewSelectedRowIDs (1,:) string
    end

    methods
        function obj = ControlTableSelectionChangedData(oldState,newState)
        %CONTROLTABLESELECTIONCHANGEDDATA Construct a complete transition payload.
            obj.OldActiveRow = oldState.ActiveRow;
            obj.NewActiveRow = newState.ActiveRow;
            obj.OldActiveRowID = oldState.ActiveRowID;
            obj.NewActiveRowID = newState.ActiveRowID;
            obj.OldSelectedRows = oldState.SelectedRows;
            obj.NewSelectedRows = newState.SelectedRows;
            obj.OldSelectedRowIDs = oldState.SelectedRowIDs;
            obj.NewSelectedRowIDs = newState.SelectedRowIDs;
        end
    end
end
