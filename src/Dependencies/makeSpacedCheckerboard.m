function matrix_out = makeSpacedCheckerboard(sz,Spacing)
%%  MAKESPACEDCHECKERBOARD makes evenly spaced 'checkerboard' style matrix
%
%   INPUTS:
%       sz | (1,1) double | positive integer | width/height of the square image, such that size(matrix_out) == [sz,sz]
%       Spacing | (1,1) double | positive, even integer | spacing between neighboring True pixels
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

    nrows = sz(1);
    ncols = sz(2);
    
    counter = 1;

    matrix_out = zeros(nrows,ncols);
    
    for i = 1:(Spacing/2):nrows % for each row
    
        switch iseven(counter)
    
            case true

                for j = (Spacing/2+1):Spacing:ncols
    
                    matrix_out(i,j) = 1;
    
                end

                counter = 1;

            case false

                for j = 1:Spacing:ncols
    
                    matrix_out(i,j) = 1;
    
                end

                counter = 2;
    
        end
    
    end

end