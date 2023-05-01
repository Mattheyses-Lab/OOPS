function squareI = padToSquare(rectI,Options)
    arguments
        rectI (:,:)
        Options.Value (1,1) = 0
    end

    [height,width] = size(rectI);

    if height==width
        squareI = rectI;
        return
    else
        if width > height % wide image; pad top/bot
            padding = [(width-height)/2 0];
        else % tall image; pad l/r
            padding = [0 (height-width)/2];
        end
    end

    % now pad the array to make it square
    squareI = padarray(rectI,floor(padding),Options.Value,'pre');
    squareI = padarray(squareI,ceil(padding),Options.Value,'post');
end