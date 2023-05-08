function varargout = parcellfun_multi(funHandle, inputs, varargin)
% trying to build a multi-threaded version of cellfun that accepts more than one input
% and can handle functions with multiple outputs

% seems to work but need to benchmark performance

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