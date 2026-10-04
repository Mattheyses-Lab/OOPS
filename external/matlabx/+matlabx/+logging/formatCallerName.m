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

function src = formatCallerName(name, opts)
%FORMATCALLERNAME Format a stack-entry name into a readable logging source.
%
%   src = matlabx.logging.formatCallerName(name)
%   src = matlabx.logging.formatCallerName(name, Detail="short")
%
% Inputs
% ------
% name : char | string
%     A function/method name such as:
%       "desmostorm.model.STORMImage.load"
%       "someFunction"
%       "pkg.func/localHelper"
%
% Name-Value
% ----------
% Detail : "short" | "full", default "short"
%     "short" returns a compact source name suitable for logs.
%     "full"  returns the full package/class/function path, with any
%     local/nested suffix removed.
%
% Output
% ------
% src : string
%
% Examples
% --------
%   matlabx.logging.formatCallerName("desmostorm.model.STORMImage.load")
%       -> "STORMImage"
%
%   matlabx.logging.formatCallerName("desmostorm.model.STORMImage.load", Detail="full")
%       -> "desmostorm.model.STORMImage.load"

    arguments
        name {mustBeTextScalar}
        opts.Detail (1,1) string {mustBeMember(opts.Detail,["short","full"])} = "short"
    end
    
    name = string(name);
    
    % Drop local/nested suffixes, e.g. "func/localHelper" -> "func"
    slashParts = split(name, '/');
    baseName = slashParts(1);
    
    if opts.Detail == "full"
        src = baseName;
        return
    end
    
    parts = split(baseName, '.');
    
    if numel(parts) >= 2
        % Heuristic:
        %   package.Class.method -> Class
        %   package.function     -> function
        penult = parts(end-1);
        last   = parts(end);
    
        % If penultimate token starts uppercase, it is likely a class name.
        if strlength(penult) > 0 && startsWith(extractBetween(penult,1,1), upper(extractBetween(penult,1,1)))
            src = penult;
        else
            src = last;
        end
    else
        src = parts(end);
    end
end


function mustBeTextScalar(x)
    if ~(ischar(x) || (isstring(x) && isscalar(x)))
        error("formatCallerName:InvalidInput", "Input must be a char vector or string scalar.");
    end
end