function ImOut = Norm2Max(ImIn)
%% Normalizes a grayscale image of type 'double' to the maximum value in the image
% Inputs: ImIn (double) 
% Outputs: ImOut (double)
    
    if isa(ImIn,'double')
        ImOut = ImIn./max(max(ImIn));
    else
        error('Input must be of type double, not %s',class(ImIn));
    end

end