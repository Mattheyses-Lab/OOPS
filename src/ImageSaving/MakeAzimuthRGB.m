function AzimuthRGB = MakeAzimuthRGB(AzimuthImage,AzimuthColormap)
    % values originally in [-pi/2 pi/2], adjust to fall in [0 pi]
    AzimuthImage(AzimuthImage<0) = AzimuthImage(AzimuthImage<0)+pi;
    % scale values to [0 1]
    AzimuthImage = AzimuthImage./pi;
    % call hsv to use as circular colormap
    %cmap = hsv(65535);
    % convert to uint8 then to RGB
    AzimuthRGB = ind2rgb(im2uint8(AzimuthImage),AzimuthColormap);
end