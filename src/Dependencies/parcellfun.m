function output = parcellfun(funHandle, input, varargin)
% trying to build a multi-threaded version of cellfun that accepts more than one input
% and can handle functions with multiple outputs

% seems to work but need to benchmark performance

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