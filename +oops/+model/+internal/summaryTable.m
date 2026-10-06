% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function T = summaryTable(names,values)
%SUMMARYTABLE Present one record as named rows and a single text value column.
%
% Match DesmoSTORM's table presentation: row names supply the left-hand labels,
% avoiding rows2vars' extra OriginalVariableNames column in the uitable.

values = cellfun(@(value) char(string(value)),values,'UniformOutput',false);
T = cell2table(reshape(values,1,[]),'VariableNames',cellstr(names));
T = matlabx.utils.table.rotate(T,ColumnNames={'Values'});
end
