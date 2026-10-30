classdef ControlTableRowsChangedData < event.EventData
%CONTROLTABLEROWSCHANGEDDATA Payload for completed row creation or removal.

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
        % Stable identities of rows affected by the operation.
        RowIDs (1,:) string
        % Source identities used by duplication, otherwise empty.
        SourceRowIDs (1,:) string
        % Numeric row positions before the operation, otherwise empty.
        OldRows (1,:) double
        % Numeric row positions after the operation, otherwise empty.
        NewRows (1,:) double
    end

    methods
        function obj = ControlTableRowsChangedData(rowIDs,sourceRowIDs,oldRows,newRows)
        %CONTROLTABLEROWSCHANGEDDATA Construct a structural-change payload.
            obj.RowIDs = reshape(string(rowIDs),1,[]);
            obj.SourceRowIDs = reshape(string(sourceRowIDs),1,[]);
            obj.OldRows = reshape(double(oldRows),1,[]);
            obj.NewRows = reshape(double(newRows),1,[]);
        end
    end
end
