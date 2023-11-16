function ParallelLines = MultiParallelTranslation(x1,x2,y1,y2,n)
% Returns an (n+1,1) cell array where each cell is a 2x2 double containing the coordinates
% of either the original line (first cell | (x1,y1),(x2,y2)) or a line parallel to it
% n is the number of lines created from the first line
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

    ParallelLines{1,1} = [x1,y1;x2,y2];

    for i = 2:n+1

        [x1,x2,y1,y2] = ParallelTranslation(x1,x2,y1,y2,1);

        ParallelLines{i,1} = [x1,y1;x2,y2];

    end

end