function IRGB = vecind2rgb(I,cmap)
%%  VECIND2RGB a vectorized version of ind2rgb, faster when ind2rgb() is called frequently within a loop or callback
%
%   I must be uint8 in the range [0 255]
%   
%   cmap must by 256x3 array of RGB triplets
%
%----------------------------------------------------------------------------------------------------------------------------
%
%   Object-Oriented Polarization Software (OOPS)
%   Copyright (C) 2023  William Dean
% 
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see https://www.gnu.org/licenses/.
%
%----------------------------------------------------------------------------------------------------------------------------

% store the size of the image for later
Isz = size(I);

% vectorize the image (convert into a column vector)
I = I(:);

% get the colors for each pixel by indexing the colormap with the vectorized image
pixelColors = cmap(I+1,:);

% find pixels with value of 255 (the maximum)
idx = I==255;

% set those pixels to the last color in the map
for i = 1:3
    pixelColors(idx,i) = cmap(256,i);
end

% reshape the output
IRGB = reshape(pixelColors,[Isz,3]);

end