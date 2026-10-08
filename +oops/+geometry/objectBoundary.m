% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function vertices = objectBoundary(region)
%OBJECTBOUNDARY Return an object's exterior pixel-edge boundary in [x y].
%
% Follow the original OOPS boundary pipeline: trace the object's own binary
% crop with eight-connected tracing and ignore holes. Segmentation connectivity
% still determines object membership; tracing does not merge model objects.
% This helper returns geometry only, leaving display/export to its callers.

arguments
    region (1,1) oops.model.Object
end

try
    % Give the tight object window a one-pixel background border. The crop
    % may extend outside the input image; those pixels are deliberately false
    % so objects touching the image edge still produce closed boundary loops.

    % Parent-image [height width] used to decode object pixel indices.
    imageSize = [region.Parent.Input.SizeY region.Parent.Input.SizeX];

    % Tight object crop with a one-pixel border for exterior-boundary tracing.
    crop = oops.geometry.Crop(region.TightBoundsRC + [-1 1; -1 1],imageSize);

    % Parent-image row and column coordinates of this object's pixels.
    [rows,cols] = ind2sub(imageSize,region.PixelIdxList);

    % Object pixel coordinates translated into the crop window.
    localPixels = crop.toLocal([rows cols]);

    % Local binary object mask populated solely from its own pixel membership.
    mask = false(crop.Size);
    mask(sub2ind(crop.Size,localPixels(:,1),localPixels(:,2))) = true;

    % Match OOPSImage.ObjectProperties: use the first exterior boundary.
    % Eight-connected tracing follows the exterior contour even though the
    % default segmentation labels objects using four-connectivity. Hole loops
    % and special treatment of corner contacts are deferred for now.

    % Exterior pixel-edge contours returned in local [row column] coordinates.
    traced = bwboundaries(mask,8,'noholes','TraceStyle','pixeledge');

    % First exterior contour, subsequently translated into parent coordinates.
    points = traced{1};

    % Moore-neighbor tracing can repeat the starting edge after completing
    % the loop, yielding A -> ... -> A -> B. A line plot tolerates that tail,
    % but a patch closes B -> A again and can render a long miter spike.
    % Keep one traversal and let the patch supply the closing edge itself.
    repeatedStart = find(all(points(2:end,:) == points(1,:),2),1,'first');

    if ~isempty(repeatedStart)
        points = points(1:repeatedStart,:);
    end

    % bwboundaries returns [row column]; overlays expect parent-image [x y].
    % Translate the normalized exterior trace into parent-image coordinates.
    points = crop.toParent(points);

    % Parent-image boundary coordinates reordered to overlay [x y] convention.
    vertices = points(:,[2 1]);

catch ME
    oops.Log.EXCEPTION(ME);
    rethrow(ME);
end

end
