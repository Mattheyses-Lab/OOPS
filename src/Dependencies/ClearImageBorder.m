function ImageOut = ClearImageBorder(ImageIn,n)
%% ClearImageBorder sets all pixels n pixels from the border to 0
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

    ImageOut = ImageIn;
    [rows,cols] = size(ImageOut);
    ImageOut(1:n,1:end) = 0;
    ImageOut(1:end,1:n) = 0;
    ImageOut(rows-(n-1):end,1:end) = 0;
    ImageOut(1:end,cols-(n-1):end) = 0;
end