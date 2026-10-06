% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function child = resolve(children,id)
%RESOLVE Resolve a stored ID against the current child collection.

child = children([]);

if strlength(id) == 0
    return;
end

idx = find(oops.model.internal.ids(children) == id,1);

if ~isempty(idx)
    child = children(idx);
end

end
