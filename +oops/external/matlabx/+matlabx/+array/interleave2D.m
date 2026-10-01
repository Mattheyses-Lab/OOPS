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

function OutputArray = interleave2D(A,B,mode)
%INTERLEAVE2D Given 2 input arrays of equal size, A and B, return a new array by interleaving rows or columns of the inputs

    arguments
        A (:,:)
        B (:,:)
        mode (1,:) char {mustBeMember(mode,{'row','column','default'})} = 'default'
    end
   
    % validate input
    assert(all(size(A)==size(B)),'interleave2D:incompatibleArraySizes','Array sizes must match');
    assert(numel(size(A))<=2,'interleave2D:invalidArrayDimensions','Arrays must be 2-dimensional');
    assert(all(size(A)~=0),'interleave2D:invalidDimensionLengths','Dimension lengths must be nonzero');
    
    % get the number of rows and columns
    [nRows,nCols] = size(A);

    % mode not specified as 'row' or 'column', set to interleave along longest dimension
    if strcmp(mode,'default')
        if nRows >= nCols
            mode = 'row';
        else
            mode = 'column';
        end
    end

    % set up output array to be same size as input
    if iscell(A)
        OutputArray = cell(nRows,nCols);
    else
        OutputArray = zeros(nRows,nCols);
    end

    switch mode
        case 'row'
            OutputArray = repmat(OutputArray,2,1); % replicate once along row
            OutputArray(1:2:end,:) = A;
            OutputArray(2:2:end,:) = B;
        case 'column'
            OutputArray = repmat(OutputArray,1,2); % replicate once along column
            OutputArray(:,1:2:end) = A;
            OutputArray(:,2:2:end) = B;
    end

end