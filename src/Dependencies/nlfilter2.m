function Iout = nlfilter2(I,filterSize,fun)
%%  nlfilter2  parallelized version of nlfilter that does not display a progress bar
%
%   See also nlfilter

    % how much do we need to buffer around the edges of the image
    filterBuffer = (filterSize-1)/2;
    % the loop mask (the indices across which we will slide the window)
    loopMask = true(size(I));
    % add symmetric padding to I
    I = padarray(I,[filterBuffer,filterBuffer],"symmetric");
    % add zeros to loopMask
    loopMask = padarray(loopMask,[filterBuffer,filterBuffer],false,"both");
    % size of the output with padding
    Isz = size(I);
    % initialize output (with padding)
    Iout = zeros(Isz);
    % slide window across image and apply fun to each frame
    parfor Idx = 1:numel(Iout)
        if loopMask(Idx)
            % get row (i) and col (j) indices to the frame
            [i,j] = ind2sub(Isz,Idx);
            % get the frame on which we will evaluate fun
            frame = I(i-filterBuffer:i+filterBuffer,j-filterBuffer:j+filterBuffer);
            % evaluate fun on the frame
            Iout(Idx) = feval(fun,frame);
        end
    end

    % remove the padding
    Iout = Iout(1+filterBuffer:end-filterBuffer,1+filterBuffer:end-filterBuffer);

end