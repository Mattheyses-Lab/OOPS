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

function T = rotate(T,opts)
%ROTATETABLE  rotates a table such that variables and rows are swapped
    
    arguments
        T (:,:) table
        opts.ColumnNames (:,1) cell = {} % optional
    end

    % swap rows and vars
    T = rows2vars(T,"VariableNamingRule","preserve");

    % set row names to original variable names
    T.Properties.RowNames = T.OriginalVariableNames;

    % remove the "OriginalVariableNames" column, as it contains the same content as the row names
    T = removevars(T,"OriginalVariableNames");

    % set VariableNames to opts.ColumnNames, if not empty
    if ~isempty(opts.ColumnNames)
        if ~isequal(length(T.Properties.VariableNames),length(opts.ColumnNames))
            error('Number of column names must match number of rows in the input table');
        end
        T.Properties.VariableNames = opts.ColumnNames; 
    end

end