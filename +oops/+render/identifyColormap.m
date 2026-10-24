% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function [name,category] = identifyColormap(map)
%IDENTIFYCOLORMAP Find the registered identity of an exact numeric LUT.

name = "";
category = "";

for candidateCategory = matlabx.colors.maps.Registry.categories()
    for candidateName = matlabx.colors.maps.Registry.names(candidateCategory)
        candidate = matlabx.colors.maps.Registry.map(candidateName,candidateCategory);

        if isequal(size(candidate),size(map)) && ...
                max(abs(double(candidate(:))-double(map(:))),[],'omitnan') <= 1e-12
            name = candidateName;
            category = candidateCategory;
            return;
        end
    end
end
end
