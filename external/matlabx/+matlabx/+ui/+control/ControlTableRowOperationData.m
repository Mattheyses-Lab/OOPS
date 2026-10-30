classdef ControlTableRowOperationData < event.EventData
%CONTROLTABLEROWOPERATIONDATA Cancellable structural row-operation request.
%
%   ControlTable passes this mutable event data to
%   RowOperationRequestedFcn before changing its data, stable identities,
%   graphics, selection, or ordering. Set Cancel to true to reject the
%   proposed operation.

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
        % Requested operation: add, duplicate, remove, or reorder.
        Operation (1,1) string
        % Stable identities of existing rows affected by the request.
        RowIDs (1,:) string
        % Current numeric indices of existing affected rows.
        Rows (1,:) double
        % Source row for duplicate or reorder, otherwise zero.
        SourceRow (1,1) double
        % Proposed insertion or final row, otherwise zero.
        DestinationRow (1,1) double
        % Proposed or current data associated with the affected rows.
        ProposedData table
    end

    properties
        % Whether the application rejects the requested operation.
        Cancel (1,1) logical = false
    end

    methods
        function obj = ControlTableRowOperationData(operation,rowIDs,rows, ...
                sourceRow,destinationRow,proposedData)
        %CONTROLTABLEROWOPERATIONDATA Construct a normalized request payload.
            operation = string(operation);
            mustBeMember(operation,["add","duplicate","remove","reorder"]);
            obj.Operation = operation;
            obj.RowIDs = reshape(string(rowIDs),1,[]);
            obj.Rows = reshape(double(rows),1,[]);
            obj.SourceRow = double(sourceRow);
            obj.DestinationRow = double(destinationRow);
            obj.ProposedData = proposedData;
        end
    end
end
