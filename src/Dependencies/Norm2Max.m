function Inorm = Norm2Max(I)
% Norm2Max  Normalize N-D input array, I, to the maximum value in the array
% 
%   INPUTS
%       I (mxn double) - the array to normalize
%
%   OUTPUTS
%       Inorm (mxn double) - I normalized to its maximum value

    % throw error if not double
    assert(isa(I,'double'),'I must be of type double, not %s',class(I))
    % normalize by dividing by the maximum value across all elements
    Inorm = I./max(I,[],"all");
end