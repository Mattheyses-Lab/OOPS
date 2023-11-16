function varargout = parcellfun_multi(funHandle, inputs, varargin)
% trying to build a multi-threaded version of cellfun that accepts more than one input
% and can handle functions with multiple outputs
%
% seems to work but need to benchmark performance
%
% the function works based on recent tests
% some notes: 
% 
% will likely not be faster than cellfun for simple, speedy functions
%
% you will only notice a benefit to computation time if the total time spent in your function
% outweighs the overhead of this function. This will vary based on machine
%
% the number of outputs requested when calling this function must match 
% exactly the number returned by funHandle (use ~ for unwanted outputs)
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

    % number of outputs requested
    nOutputs = nargout;
    % number of elements in each input cell array
    nElementsPerInput = size(inputs{1},1);
    % preallocate results cell array
    result = cell(nElementsPerInput,nOutputs);

    if size(inputs,2) > 1
        % concatenate all the input cell arrays
        inputCat = cat(2,inputs{:});
    else
        inputCat = inputs{1};
    end

    % evaluate the function on each element within a parfor loop
    % (or set of elements if funHandle takes more than one input)
    parfor i = 1:nElementsPerInput
        % get the next row of inputs
        inputRow = inputCat(i,:);
        % evaluate the function with those inputs and pass to results
        [result{i,:}] = funHandle(inputRow{:});
    end
    
    if p.Results.UniformOutput
        result = cell2mat(result);
    end

    varargout = cell(1,nOutputs);
    for i = 1:nOutputs
        varargout{i} = result(:,i);
    end
end