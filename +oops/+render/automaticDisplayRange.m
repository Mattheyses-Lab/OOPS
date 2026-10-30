% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function value = automaticDisplayRange(statistics,method,fallback)
%AUTOMATICDISPLAYRANGE Resolve one named scaling method from cached statistics.

switch string(method)
    case "Light contrast"
        value = [statistics.Percentile0_5 statistics.Percentile99_95];
    case "Medium contrast"
        value = [statistics.Percentile0_5 statistics.Percentile99_9];
    case "Strong contrast"
        value = [statistics.Percentile1 statistics.Percentile99_5];
    case "Zero to max"
        value = [0 statistics.Maximum];
    case "Data range"
        value = [statistics.Minimum statistics.Maximum];
    otherwise
        error('oops:render:UnknownAutoScaleMethod', ...
            'Unknown automatic scaling method: %s',method);
end

if any(~isfinite(value)) || value(2) <= value(1)
    value = fallback;
end
end
