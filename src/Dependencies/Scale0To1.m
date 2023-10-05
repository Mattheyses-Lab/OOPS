function Scaled = Scale0To1(UnscaledImage)
% Scale0To1  rescale the intensity image values to fall between 0 and 1
    Scaled = rescale(UnscaledImage,0,1);
end