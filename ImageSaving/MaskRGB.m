function MaskedRGBImage = MaskRGB(UnmaskedRGBImage,Mask)

    MaskedRGBImage = bsxfun(@times, UnmaskedRGBImage, cast(Mask, 'like', UnmaskedRGBImage));

end