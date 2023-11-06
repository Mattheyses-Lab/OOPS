function mapOut = mapFromRGB(clrs,Options)

    %% validate inputs and set defaults

    arguments
        clrs (:,3) double = [0 0 0;1 1 1]
        Options.nColors (1,1) double = 256
        Options.colorPositions (1,:) = linspace(0,1,size(clrs,1))
    end

    % check that colorPositions is increasing and strictly monotonic
    if any(diff(Options.colorPositions) <= 0)
        error('colorPositions must be strictly monotonically increasing')
    end

    % check that first and last elements of colorPositions are 0 and 1, respectively
    if ~isequal(Options.colorPositions([1,end]),[0,1])
        error('First and last elements of colorPositions must be 0 and 1, respectively')
    end

    % check that number of input colors matches number of elements in colorPositions
    if size(clrs,1) ~= numel(Options.colorPositions)
        error('Number of RGB triplets in clrs must match number of elements in colorPositions')
    end

    % check that number of desired colors is at least greater than or equal to number of input colors
    if Options.nColors < size(clrs,1)
        error('nColors must be >= number of RGB triplets in clrs')
    end


    % testing below

    clrs = rgb2lab(clrs,"ColorSpace","adobe-rgb-1998");

    % end testing



    %% create the output map using interp2()

    mapOut = interp2(1:3,Options.colorPositions,clrs,1:3,linspace(0,1,Options.nColors)');

    % mapOut = interp2(X,Y,V,Xq,Yq)
    % X: x coordinates of sample points (input color column indices)
    % Y: y coordinates of sample points (input color row indices)
    % V: function values at each sample point (input colors)
    % Xq: x coordinates of query points (output color column indices)
    % Yq: y coordinates of query points (output color row indices)


    % testing below

    mapOut = min(max(lab2rgb(mapOut,"ColorSpace","adobe-rgb-1998"),0),1);

    % end testing
    
end