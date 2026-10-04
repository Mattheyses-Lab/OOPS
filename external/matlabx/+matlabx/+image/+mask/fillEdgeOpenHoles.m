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

function IOut = fillEdgeOpenHoles(I,opts)
    arguments
        I (:,:) logical
        opts.ShowResults (1,1) logical = false
    end

    % start with a normal fill
    I1 = imfill(I,"holes");

    % invert the image
    I2 = ~I1;

    % fill again
    I3 = imfill(I2, "holes");

    % remove connected components in I3 touching 3 or more borders
    I4 = matlabx.image.mask.removeBorderTouchers(I3,3);

    % final mask is the logical OR of I1 and I4
    IOut = I1 | I4; % Combine the filled images
    
    % display results if requested
    if opts.ShowResults
        quickshow({I,I1,I2,I3,I4,IOut});
    end

end