function OutputArray = Interleave2DArrays(A,B,mode)
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
   
    % validate input
    assert(all(size(A)==size(B)),'Interleave2DArrays:incompatibleArraySizes','Array sizes must match');
    assert(numel(size(A))<=2,'Interleave2DArrays:invalidArrayDimensions','Arrays must be 2-dimensional');
    assert(all(size(A)~=0),'Interleave2DArrays:invalidDimensionLengths','Dimension lengths must be nonzero');
    
    % get the number of rows and columns
    [nRows,nCols] = size(A);

    
    if iscell(A)
        OutputArray = cell(nRows*2,nCols);
    else
        OutputArray = zeros(nRows*2,nCols);
    end

    switch mode
        case 'row'
            OutputArray(1:2:end,:) = A;
            OutputArray(2:2:end,:) = B;
        case 'column'
            OutputArray = OutputArray.';
            OutputArray(:,1:2:end) = A;
            OutputArray(:,2:2:end) = B;
    end

end