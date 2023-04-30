function write32BitTiff(Img,ImgName)

if isa(Img,'double')
    Img = im2single(Img);
end


t = Tiff(ImgName, 'w');
tagstruct.ImageLength = size(Img, 1);
tagstruct.ImageWidth = size(Img, 2);
tagstruct.Compression = Tiff.Compression.None;
tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = 32;
tagstruct.SamplesPerPixel = size(Img,3);
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
t.setTag(tagstruct);
t.write(Img);
t.close();

end