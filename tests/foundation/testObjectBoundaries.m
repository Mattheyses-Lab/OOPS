% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testObjectBoundaries
%TESTOBJECTBOUNDARIES Verify the legacy exterior-boundary pipeline.

tests = functiontests(localfunctions);
end

function setupOnce(t)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run(BioFormats=false);

logger = oops.Log.get();
logger.PrintToCommandWindow = false;
end

function teardownOnce(~)
oops.Log.close();
end

function testFourConnectedExteriorBoundaries(t)
%TESTFOURCONNECTEDEXTERIORBOUNDARIES Cover the initial hole-free pipeline.

% Include border objects, a single pixel, a concave contour, and multiple
% objects. These are deliberately ordinary four-connected, hole-free masks.
masks = {true(5), true(1), ...
    logical([1 1 0; 1 0 0; 1 1 1]), ...
    logical([1 0 0; 1 1 0; 0 1 1])};
mask = false(12,15);
mask(1:3,1:4) = true;
mask(5:8,7:9) = true;
mask(12,15) = true;
masks{end+1} = mask;

for k = 1:numel(masks)
    verifyMaskGeometry(t,masks{k},4);
end
end

function verifyMaskGeometry(t,mask,connectivity)
%VERIFYMASKGEOMETRY Check all warning IDs and compare exact pixel coverage.

% verifyWarningFree checks all warning IDs, including short boundaries, rather
% than treating only automatic repair as a failure.


project = oops.model.Project();
projectCleanup = onCleanup(@() delete(project));
group = project.addGroup("Boundary test");
input = matlabx.image.Image5D.fromComponents({double(mask),double(mask),double(mask),double(mask)});
image = group.addImage(input,"Pixels");
image.setMask(mask,oops.analysis.segment.objectsFromMask(mask,connectivity));

[x,y] = meshgrid(1:size(mask,2),1:size(mask,1));

for region = image.Objects'
    t.verifyWarningFree(@() oops.geometry.objectBoundary(region));
    vertices = oops.geometry.objectBoundary(region);

    % Independently reproduce the old tight-crop computation and offset.
    bounds = region.TightBoundsRC;
    own = false(size(mask));
    own(region.PixelIdxList) = true;
    tight = own(bounds(1,1):bounds(1,2),bounds(2,1):bounds(2,2));
    traced = bwboundaries(tight,8,'noholes','TraceStyle','pixeledge');

    % Strip the tracer's repeated starting edge before comparing with the
    % patch-ready geometry returned by objectBoundary.
    expectedVertices = traced{1};
    repeatedStart = find(all(expectedVertices(2:end,:) == ...
        expectedVertices(1,:),2),1,'first');

    if ~isempty(repeatedStart)
        expectedVertices = expectedVertices(1:repeatedStart,:);
    end

    expectedVertices = expectedVertices + [bounds(1,1)-1 bounds(2,1)-1];
    t.verifyEqual(vertices,expectedVertices(:,[2 1]));

    % Patch input contains the starting coordinate exactly once. The patch
    % itself closes the last edge back to this vertex.
    t.verifyEqual(sum(all(vertices == vertices(1,:),2)),1);

    t.verifyWarningFree(@() polyshape(vertices));
    shape = polyshape(vertices);

    expected = false(size(mask));
    expected(region.PixelIdxList) = true;

    t.verifyEqual(reshape(isinterior(shape,x(:),y(:)),size(mask)),expected);
    t.verifyEqual(area(shape),numel(region.PixelIdxList),'AbsTol',1e-12);

    coordinates = vertices(isfinite(vertices));
    t.verifyEqual(mod(coordinates,1),repmat(.5,size(coordinates)));
end
end
