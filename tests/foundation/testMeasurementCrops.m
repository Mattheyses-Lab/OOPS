% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testMeasurementCrops
%TESTMEASUREMENTCROPS Verify cropped rings against full-image reference geometry.
tests = functiontests(localfunctions);
end
function setupOnce(t)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run(BioFormats=false);
logger = oops.Log.get(); logger.PrintToCommandWindow = false;
end
function teardownOnce(~)
oops.Log.close();
end
function testCroppedBackgroundMatchesFullImageAtBordersAndNeighbors(t)
mask = false(40,55);
mask(1:4,1:3) = true; mask(17:21,19:23) = true;
mask(18:20,27:29) = true; mask(37:40,52:55) = true;
mask(18:19,20:21) = false; % Include a hole in one object.
lists = oops.analysis.segment.objectsFromMask(mask);
average = reshape(1:numel(mask),size(mask)); average(8,8) = NaN;
for radius = [0 3 6]
    for width = [1 2 5]
        for excludeObjects = [false true]
            for excludeBuffers = [false true]
                settings = oops.config.LocalBackground();
                settings.BufferRadius = radius; settings.BackgroundWidth = width;
                settings.ExcludeOtherObjects = excludeObjects;
                settings.ExcludeOtherBuffers = excludeBuffers;
                values = oops.analysis.objectMeasurements(mask,lists,average,[],[],settings);
                allBuffers = imdilate(mask,ones(2*radius+1));
                for k = 1:numel(lists)
                    own = false(size(mask)); own(lists{k}) = true;
                    buffer = imdilate(own,ones(2*radius+1));
                    ring = imdilate(buffer,ones(2*width+1)) & ~buffer;
                    if excludeObjects, ring(mask) = false; end
                    if excludeBuffers, ring(allBuffers) = false; end
                    t.verifyEqual(values{k}.BGAverage,mean(average(ring),'omitnan'),'AbsTol',1e-10);
                    t.verifyEqual(values{k}.SignalAverage,mean(average(lists{k}),'omitnan'),'AbsTol',1e-10);
                end
                delete(settings);
            end
        end
    end
end
end
function testNoBackgroundPixelsProducesNaN(t)
mask = true(8); lists = {find(mask)}; settings = oops.config.LocalBackground();
cleanup = onCleanup(@() delete(settings));
values = oops.analysis.objectMeasurements(mask,lists,ones(8),[],[],settings);
t.verifyTrue(isnan(values{1}.BGAverage)); t.verifyTrue(isnan(values{1}.SBRatio));
end
