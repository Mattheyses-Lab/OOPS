function HSV = makeHSVSpecial(H,S,V,cmap)
% make an "HSV" image (in RGB colorspace) from the H, S,and V inputs and the cmap
% assumes H is in the range [-pi/2 pi/2]

if isempty(cmap)
    cmap = hsv;
end

%H(H<0) = H(H<0)+pi;

% scale so values are between 0 and 1
%H = H./pi;

% convert H to an RGB image with the selected colormap
H_RGB = ind2rgb(im2uint8(H),cmap);

%% method 1

% now get H in terms of the input cmap
H_RGB_HSV = rgb2hsv(H_RGB);
H_new = H_RGB_HSV(:,:,1);

% now add in S and V
HSVtemp = cat(3,H_new,S,V);

% convert the above HSV image to RGB for display
HSV = hsv2rgb(HSVtemp);

%% method 2

% % mask the RGB H image with the V image (essentially a fully saturated HSV image in RGB)
% MaskedRGBImage = bsxfun(@times, H_RGB, cast(V, 'like', H_RGB));
% 
% % %below not working identically
% % % make a fully white RGB image, same size as others
% % WhiteRGBImage = ones(size(H_RGB), 'like', H_RGB);
% % % mask it using the input S image (S image in RGB)
% % WhiteRGBImageMasked = bsxfun(@times, WhiteRGBImage, cast(S, 'like', WhiteRGBImage));
% % % now add it to the H-V image
% % HSV = MaskedRGBImage+WhiteRGBImageMasked;
% 
% MaskedRGBImage_HSV = rgb2hsv(MaskedRGBImage);
% 
% H_new = MaskedRGBImage_HSV(:,:,1);
% V_new = MaskedRGBImage_HSV(:,:,3);
% 
% HSV = hsv2rgb(cat(3,H_new,S,V_new));













end