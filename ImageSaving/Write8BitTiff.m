function Write8BitTiff(I,filename,map)
    I = im2uint8(I);
    t = Tiff(filename, 'w');
    tagstruct.ImageLength = size(I, 1);
    tagstruct.ImageWidth = size(I, 2);
    tagstruct.Compression = Tiff.Compression.None;
    tagstruct.SampleFormat = 1;
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample = 8;
    tagstruct.SamplesPerPixel = size(I,3);
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tagstruct.ColorMap = map;
    tagstruct.Software = 'Object-Oriented Polarization Software (OOPS)';
    t.setTag(tagstruct);
    t.write(I);
    t.close();
end