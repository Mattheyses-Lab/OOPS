function colorOut = getBWContrastColor(colorIn)
    % determine whether colorIn contrasts more with black or white and return the result
    if mean(colorIn,"all") < 0.5
        % dark color, return white
        colorOut = [1 1 1];
    else
        % bright color, return black
        colorOut = [0 0 0];
    end
end