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

function UUID = uniqueID(ID_class)
%%UNIQUEID  Returns a unique UUID ('string' or 'char')
arguments
    ID_class (1,:) char {mustBeMember(ID_class,{'string','char'})} = 'string'
end

switch ID_class
    case 'string'
        UUID = string(java.util.UUID.randomUUID());
    case 'char'
        UUID = char(java.util.UUID.randomUUID());
end

end