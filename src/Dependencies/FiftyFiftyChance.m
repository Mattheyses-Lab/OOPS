function Result = FiftyFiftyChance(behavior)
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

    switch behavior
        case 'TrueFalse'
            if OneOrZero();Result=true;else;Result=false;end
        case 'OneZero'
            if OneOrZero();Result=1;else;Result=0;end
        case 'PosNeg'
            if OneOrZero();Result=1;else;Result=-1;end            
    end

    function Num = OneOrZero()
        switch randi(2)
            case 1
                Num = true;
            case 2
                Num = false;
        end
    end

end