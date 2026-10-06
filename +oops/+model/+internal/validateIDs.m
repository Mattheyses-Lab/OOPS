% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function ids = validateIDs(values,children,errorID,single)
%VALIDATEIDS Validate membership, accepting IDs or handles at the API boundary.
% Empty active state uses ""; empty batch selection uses a zero-length column.

if isempty(values)
    ids = strings(0,1);
elseif isa(values,'handle')
    ids = oops.model.internal.ids(values);
else
    ids = string(values(:));
    ids(ids == "") = [];
end

available = oops.model.internal.ids(children);

if (single && numel(ids) > 1) || any(~ismember(ids,available)) || any(ismissing(ids))
    error(errorID,'Navigation IDs must belong to the owning collection.');
end

if single

    if isempty(ids)
        ids = "";
    end

else
    ids = available(ismember(available,ids)); % canonical order, no duplicates
end

end
