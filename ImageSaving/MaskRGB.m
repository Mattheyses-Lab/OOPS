function MaskedRGBImage = MaskRGB(UnmaskedRGBImage,Mask)

    % RGB image masked with intensity image, Mask (black BG)
    MaskedRGBImage = bsxfun(@times, UnmaskedRGBImage, cast(Mask, 'like', UnmaskedRGBImage));

    % uncommenting below will display the data on a white BG instead (leave above uncommented)
    % WhiteRGBImage = ones(size(UnmaskedRGBImage), 'like', UnmaskedRGBImage);
    % WhiteRGBImageMasked = bsxfun(@times, WhiteRGBImage, cast(imcomplement(Mask), 'like', WhiteRGBImage));
    % MaskedRGBImage = MaskedRGBImage+WhiteRGBImageMasked;

end