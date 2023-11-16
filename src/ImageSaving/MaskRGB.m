function MaskedRGBImage = MaskRGB(UnmaskedRGBImage,Mask)
%%  MASKRGB applies mask to an RGB image
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

% RGB image masked with intensity image or logical image, Mask (black BG)
MaskedRGBImage = bsxfun(@times, UnmaskedRGBImage, cast(Mask, 'like', UnmaskedRGBImage));

% uncommenting below will display the data on a white BG instead (leave above uncommented)
% WhiteRGBImage = ones(size(UnmaskedRGBImage), 'like', UnmaskedRGBImage);
% WhiteRGBImageMasked = bsxfun(@times, WhiteRGBImage, cast(imcomplement(Mask), 'like', WhiteRGBImage));
% MaskedRGBImage = MaskedRGBImage+WhiteRGBImageMasked;

end