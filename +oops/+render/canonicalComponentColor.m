% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function name = canonicalComponentColor(value)
%CANONICALCOMPONENTCOLOR Resolve metadata/RGB to an ImageAxes color name.
% Empty output means ImageAxes cannot represent the requested color in its
% current categorical component-color API. Callers should retain LUT mode.

name = "";

if isempty(value)
    return;
end

try

    if isnumeric(value)
        validateattributes(value,{'numeric'}, ...
            {'real','finite','size',[1 3],'>=',0,'<=',1});
        value = matlabx.colors.names.fromRGB(value,"Palette","MATLAB");
    end

    name = matlabx.ui.axes.ImageAxes.canonicalComponentColorName(value);
catch
    % Arbitrary metadata colors may not belong to ImageAxes's canonical set.
    name = "";
end
end
