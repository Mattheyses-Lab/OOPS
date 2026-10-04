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

classdef (Abstract) ImageSource < handle
    %IMAGESOURCE Abstract backing source for Image5D.

    methods (Abstract)
        comps = getComponents(obj)
        tf = isLoaded(obj)
        tf = isFileBacked(obj)
        load(obj)
        unload(obj)
        I = getPlane(obj, idx, z, t)
        md = getOriginalMetadata(obj)
        md = getOMEMetadata(obj)
        md = getCoreMetadata(obj)
        md = getGraphicsFileMetadata(obj)
    end
end