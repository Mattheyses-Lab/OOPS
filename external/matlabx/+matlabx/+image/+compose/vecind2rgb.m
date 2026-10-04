% matlabx - MATLAB utilities for app building, image display, and analysis.
% Copyright (C) 2026 William Dean
%
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free
% Software Foundation; either version 2 of the License, or (at your option)
% any later version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along
% with this program; if not, see <https://www.gnu.org/licenses/>.

function IRGB = vecind2rgb(I,cmap)
%%VECIND2RGB  Vectorized version of ind2rgb, faster when ind2rgb() is called frequently within a loop or callback
%
%   I must be uint8 in the range [0 255]
%   
%   cmap must by 256x3 array of RGB triplets
%
%   Steps
%       
%       I is converted to a column vector
%       Vectorized I is converted to double and incremented by 1 to act as an index into cmap
%       Output colors are then reshaped into a truecolor image array
%
%----------------------------------------------------------------------------------------------------------------------------

IRGB = reshape(cmap(double(I(:))+1,:),[size(I),3]);

end