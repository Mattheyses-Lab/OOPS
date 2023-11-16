function output = parcellfun(funHandle, input, varargin)
% trying to build a multi-threaded version of cellfun that accepts more than one input
% and can handle functions with multiple outputs
%
% seems to work but need to benchmark performance
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

    p = inputParser;
    addParameter(p, 'UniformOutput', 1, @isscalar);
    parse(p, varargin{:});

    % number of elements in each input cell array
    nElements = size(input,1);
    % preallocate results cell array
    output = cell(nElements,1);

    % evaluate the function on each element within a parfor loop
    % (or set of elements if funHandle takes more than one input)
    parfor i = 1:nElements
        thisInput = input{i};
        % evaluate the function with those inputs and pass to results
        output{i} = funHandle(thisInput);
    end

    if p.Results.UniformOutput
        output = cell2mat(output);
    end

end