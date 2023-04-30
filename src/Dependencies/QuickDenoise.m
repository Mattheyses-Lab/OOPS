function DenoisedImage = QuickDenoise(NoisyImage)

    DenoisedImage = medfilt2(filter2(fspecial('average',3),NoisyImage));
end