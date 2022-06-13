function ImgOut = EnhanceGrayScale(Img)
    ImgOut = Scale0To1(imtophat(QuickDenoise(Img),strel('disk',3,0)));
end