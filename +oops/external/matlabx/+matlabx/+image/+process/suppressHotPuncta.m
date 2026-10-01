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

function Iout = suppressHotPuncta(I, PercentileThreshold, DilateRadius)
%SUPPRESSHOTPUNCTA Mask extreme bright puncta and replace locally.
% PercentileThreshold: percentile defining "hot" (e.g. 99.95)
% DilateRadius: in pixels (e.g. 2 to 4)

    arguments
        I
        PercentileThreshold = 99.99
        DilateRadius = 3
    end

    % convert to double
    I = im2double(I);

    % find pixels above specified threshold
    hi = prctile(I(:), PercentileThreshold);
    mask = I >= hi;

    % opening to remove very small objects
    mask = imopen(mask,strel('disk',1,0));

    % Dilate to cover the full bright blob
    se = strel('disk', DilateRadius, 0);
    mask = imdilate(mask, se);

    % fill regions specified by mask
    Iout = inpaintCoherent(I,mask,...
        "SmoothingFactor",2,...
        "Radius",3);

    % create mask of dilated border around each region
    borderMask = imdilate(mask,strel('disk',1,0)) & ~imerode(mask,strel('disk',1,0));

    % median filter to smooth border
    Imed = medfilt2(Iout,[3 3]);

    % fill the border pixels
    Iout(borderMask) = Imed(borderMask);

    % rescale output
    Iout = rescale(Iout);

end