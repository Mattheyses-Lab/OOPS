% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function pixelLists = objectsFromMask(mask,connectivity)
%OBJECTSFROMMASK Partition a binary mask for Image.setMask.
% This is separate from mask generation so segmentation strategies can evolve.

    arguments
        mask (:,:) logical
        connectivity (1,1) double {mustBeMember(connectivity,[4 8])} = 4
    end
    try

        % Connected components of the supplied mask using the requested connectivity.
        components = bwconncomp(mask,connectivity);

        % Row cell array of parent-image linear indices, one cell per object.
        pixelLists = reshape(components.PixelIdxList,1,[]);
    catch ME
        oops.Log.EXCEPTION(ME);
        rethrow(ME);
    end
end
