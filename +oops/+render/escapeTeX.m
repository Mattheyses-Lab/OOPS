% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function text = escapeTeX(value)
%ESCAPETEX Escape literal text before passing it to MATLAB TeX graphics.
% Model values remain unchanged. Call this helper only at presentation
% boundaries whose graphics objects use MATLAB's default TeX interpreter.

    if ~(ischar(value) || isstring(value) || iscellstr(value))
        error('oops:render:InvalidDisplayText', ...
            'Display text must be a character vector, string, or cell array of character vectors.');
    end

    % Normalize all supported text containers while preserving array shape.
    text = string(value);

    % A literal slash must be converted before adding escape slashes below.
    text = replace(text,"\","\backslash ");
    text = replace(text,"_","\_");
    text = replace(text,"^","\^");
    text = replace(text,"{","\{");
    text = replace(text,"}","\}");
end
