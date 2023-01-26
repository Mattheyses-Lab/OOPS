function Scaled = Scale0To1(UnscaledImage)
% rescale the intensity imagevalues  to fall between 0 and 1
    Scaled = rescale(UnscaledImage,0,1);

end