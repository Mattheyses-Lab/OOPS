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

function matrix_out = checkerboard(sz,Spacing)
%CHECKERBOARD makes evenly spaced 'checkerboard' style matrix
%
%   INPUTS:
%       sz      | (1,2) double | positive integer       | width/height of the output (square)
%       Spacing | (1,1) double | positive, even integer | spacing between neighboring True pixels
%

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

    function tf = iseven(x)
        %ISEVEN  Return true for even integers
        %
        %   tf = isEven(x) returns a logical array the same size as x.

        tf = mod(x,2) == 0;
    end

end