% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function values = ids(children)
%IDS Return child IDs in collection order without retaining handles.

values = strings(numel(children),1);

for k = 1:numel(children)
    values(k) = children(k).ID;
end

end
