function IRGB = vecind2rgb(I,cmap)
% faster ind2rgb()
% I must be uint8 in the range [0 255]
% cmap must by 256x3 RGB array

        % I8 = im2uint8(I);
        % I8 = I8(:);

        Isz = size(I);
        I = I(:);
    
        pixelColors = cmap(I+1,:);
    
        idx = I==255;
    
        for i = 1:3
            pixelColors(idx,i) = cmap(256,i);
        end
    
        IRGB = reshape(pixelColors,[Isz,3]);
end