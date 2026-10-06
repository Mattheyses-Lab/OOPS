% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testSummaries
%TESTSUMMARIES Verify presentation and current-output status without loading data.
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

function testSummaryRowsAndStoredObjectMeasurements(t)
p = oops.model.Project("Summary project");
cleanup = onCleanup(@() delete(p));
g = p.addGroup("Summary group");
input = matlabx.image.Image5D.fromComponents({ones(10),ones(10),ones(10),ones(10)});
im = g.addImage(input,"Summary image");
mask = false(10); mask(2:4,3:5) = true;
im.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
region = im.Objects(1);
region.setMeasurements(struct('Area',9,'OrderAvg',.4,'AzimuthAverage',30));

for member = {p,g,im,region}
    T = member{1}.SummaryTable;
    t.verifyEqual(T.Properties.VariableNames,{'Values'});
    t.verifyNotEmpty(T.Properties.RowNames);
    t.verifyEqual(width(T),1);
end
T = region.SummaryTable;
t.verifyEqual(T{'Mean order','Values'},{'0.40'});
t.verifyEqual(T{'Mean azimuth','Values'},{'30.00°'});
t.verifyEqual(T{'Area','Values'},{'9 px²'});
t.verifyEqual(T{'Label','Values'},{'Unlabeled'});
t.verifyTrue(any(strcmp(T.Properties.RowNames,'Midline length')));
t.verifyFalse(any(strcmp(T.Properties.RowNames,'Mean reference intensity')));
T = p.SummaryTable;
t.verifyEqual(T{'Total objects','Values'},{'1'});
T = im.SummaryTable;
t.verifyEqual(T{'Mask generated','Values'},{'1 / 1 images'});
end

function testEmptyCollectionsAndStaleCorrectionStatus(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup("Empty");
T = g.SummaryTable;
t.verifyEqual(T{'FFC performed','Values'},{'0 / 0 images'});
input = matlabx.image.Image5D.fromComponents({ones(10),ones(10),ones(10),ones(10)});
im = g.addImage(input);
im.setCorrectionResults(ones(10,10),strings(0,1));
T = im.SummaryTable;
t.verifyEqual(T{'FFC performed','Values'},{'0 / 1 images'});
cal = p.addCalibration(input,"Calibration");
g.setCalibrations(cal.ID);
im.setCorrectionResults(ones(10,10),cal.ID);
T = im.SummaryTable;
t.verifyEqual(T{'FFC performed','Values'},{'1 / 1 images'});
g.setCalibrations(strings(0,1));
T = im.SummaryTable;
t.verifyEqual(T{'FFC performed','Values'},{'0 / 1 images'});
end
