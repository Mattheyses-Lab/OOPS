function Iout = nlfilter2(I,filterSize,fun)




% still testing, not for use!

    % size of the input
    Isz = size(I);
    % how much do we need to buffer around the edges of the image
    filterBuffer = (filterSize-1)/2;
    % the loop mask (the indices across which we will slide the window)
    loopMask = true(Isz);
    loopMask = ClearImageBorder(loopMask,filterBuffer);
    % initialize output
    Iout = zeros(Isz);
    
    parfor Idx = 1:numel(I)
        if loopMask(Idx)
            % [row,col] = ...
            [i,j] = ind2sub(Isz,Idx);
            % the frame we will be working with
            frame = I(i-filterBuffer:i+filterBuffer,j-filterBuffer:j+filterBuffer);
            % get the average
            %Iout(Idx) = getLocalAverage(frame);
            Iout(Idx) = feval(fun,frame);
        end
    end

end