function I_out = executeSchemeOnImage(Scheme,I_in)

    Scheme.StartingImage = I_in;

    Scheme.Execute();

    I_out = Scheme.Images(end).ImageData;

end