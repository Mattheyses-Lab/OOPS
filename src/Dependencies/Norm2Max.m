function Inorm = Norm2Max(I)
% Norm2Max  Normalize N-D input array, I, to the maximum value in the array
% 
%   INPUTS
%       I (mxn double) - the array to normalize
%
%   OUTPUTS
%       Inorm (mxn double) - I normalized to its maximum value
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

    % throw error if not double
    assert(isa(I,'double'),'I must be of type double, not %s',class(I))
    % normalize by dividing by the maximum value across all elements
    Inorm = I./max(I,[],"all");
end