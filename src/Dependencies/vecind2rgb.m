function IRGB = vecind2rgb(I,cmap)
%%  vecind2rgb  a vectorized version of ind2rgb, faster only when ind2rgb() is called frequently within a loop or callback
% faster ind2rgb()
% I must be uint8 in the range [0 255]
% cmap must by 256x3 RGB array

        % store the size of the image for later
        Isz = size(I);

        % vectorize the image (convert into a column vector)
        I = I(:);
    
        % get the colors for each pixel by indexing the colormap with the vectorized image
        pixelColors = cmap(I+1,:);
    
        % find pixels with value of 255 (the maximum)
        idx = I==255;
    
        % set those pixels to the last color in the map
        for i = 1:3
            pixelColors(idx,i) = cmap(256,i);
        end
    
        % reshape the output
        IRGB = reshape(pixelColors,[Isz,3]);
end