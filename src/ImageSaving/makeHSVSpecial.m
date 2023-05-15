function HSV = makeHSVSpecial(H,S,V)
% make an "HSV" image (in RGB colorspace) from the H, S,and V inputs and the cmap
% assumes H is in the range [0 1] (representing azimuth values in the range [0 pi])

% convert H to an RGB image with the selected colormap
H_RGB = ind2rgb(im2uint8(H),hsv(256));

%% method 1

% now get H in terms of the input cmap
H_RGB_HSV = rgb2hsv(H_RGB);
H_new = H_RGB_HSV(:,:,1);

% now add in S and V
HSVtemp = cat(3,H_new,S,V);

% convert the above HSV image to RGB for display
HSV = hsv2rgb(HSVtemp);

end