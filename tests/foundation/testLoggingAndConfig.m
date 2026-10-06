% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testLoggingAndConfig
%TESTLOGGINGANDCONFIG Verify logger sinks, exceptions, and nested settings.
tests = functiontests(localfunctions);
end

function setupOnce(t)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run(BioFormats=false);
t.TestData.Folder = tempname;
mkdir(t.TestData.Folder);
end

function setup(~)
oops.Log.close();
logger = oops.Log.get();
logger.PrintToCommandWindow = false;
end

function teardown(~)
oops.Log.close();
end

function teardownOnce(t)
rmdir(t.TestData.Folder,'s');
end

function testCommandWindowFilteringAndExplicitSource(t)
logger = oops.Log.get();
logger.PrintToCommandWindow = true;
text = evalc('oops.Log.INFO("visible"); oops.Log.DEBUG("hidden");');
t.verifySubstring(text,'visible');
t.verifyFalse(contains(text,'hidden'));
oops.Log.DEBUG("detail",Source="manual-source");
entries = oops.Log.asTable();
t.verifyEqual(entries.source(end),"manual-source");
t.verifyEqual(entries.level(end),"DEBUG");
end

function testFileContainsDebugAndExceptionDetails(t)
file = fullfile(t.TestData.Folder,'session.log');
[logger,path] = oops.Log.startSession(LogFile=string(file));
logger.PrintToCommandWindow = false;
t.verifyEqual(path,string(file));
oops.Log.DEBUG("file-only debug",Source="explicit");
try
    error('oops:test:Expected','Expected exception for logger verification.');
catch ME
    oops.Log.EXCEPTION(ME);
end
oops.Log.close();
content = fileread(file);
t.verifySubstring(content,'file-only debug');
t.verifySubstring(content,'[explicit]');
t.verifySubstring(content,'oops:test:Expected');
t.verifySubstring(content,'stack:');
t.verifyFalse(oops.Log.exists());
end

function testSessionWithoutFileAndConfig(t)
[logger,path] = oops.Log.startSession(WriteFile=false);
logger.PrintToCommandWindow = false;
t.verifyEmpty(char(path));
t.verifyFalse(logger.EnableFileSink);
config = oops.Log.defaultConfig();
config.CommandWindowLevel = "ERROR";
oops.Log.configure(config);
t.verifyEqual(logger.CommandWindowLevel,"ERROR");
end

function testFailedSessionFileOpenKeepsExistingLogger(t)
existing = oops.Log.get();
blocker = fullfile(t.TestData.Folder,'not-a-folder');
fid = fopen(blocker,'w'); fclose(fid);
try
    oops.Log.startSession(LogFile=string(fullfile(blocker,'session.log')));
    t.assertFail('Invalid output location was accepted.');
catch ME
    t.verifyNotEqual(ME.identifier,'matlab.unittest:AssertionFailed');
end
t.verifyEqual(oops.Log.get(),existing);
t.verifyEqual(existing.Entries(end).level,"ERROR");
end

function testRuntimeErrorIsLoggedAndRethrownWithIdentifier(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup('Group');
input = matlabx.image.Image5D.fromComponents({ones(5),ones(5),ones(5),ones(5)});
im = g.addImage(input);
t.verifyError(@() im.setMask(false(3),{}),'oops:model:MaskSizeMismatch');
entries = oops.Log.asTable();
t.verifyEqual(entries.level(end),"ERROR");
t.verifyEqual(entries.data{end}.identifier,'oops:model:MaskSizeMismatch');
t.verifyNotEmpty(entries.data{end}.stack);
end

function testEveryConfigDomainRoundTripsAndForwards(t)
s = oops.config.Settings();
cleanup = onCleanup(@() delete(s));
expected = ["Segmentation","LocalBackground","Colormaps","Palettes", ...
    "AzimuthDisplay","ObjectDisplay","ObjectSelection","ObjectIntensityProfile", ...
    "PolarHistogram","ScatterPlot","SwarmPlot","Clustering"];
t.verifyTrue(all(ismember(expected,s.domains())));
s.Segmentation.Strategy = "Filaments";
s.Display.BackgroundColor = [0.1 0.2 0.3];
s.ObjectDisplay.CropMargin = 8;
s.Clustering.VariableList = ["Area","OrderAvg"];
snapshot = s.toStruct();
loaded = oops.config.Settings();
loaded.fromStruct(jsondecode(jsonencode(snapshot)));
t.verifyEqual(loaded.toStruct(),snapshot);
sink = containers.Map('KeyType','char','ValueType','any');
l = addlistener(s,'ClusteringChanged',@(~,e) saveEvent(sink,e));
listener = onCleanup(@() delete(l));
s.Clustering.nClusters = 5;
e = sink('event');
t.verifyEqual(e.Domain,"Clustering");
t.verifyEqual(e.Name,"nClusters");
t.verifyEqual(e.OldValue,3);
t.verifyEqual(e.NewValue,5);
end

function testConfigValidationLogsAndPreservesValue(t)
s = oops.config.Settings();
try
    s.Display.BackgroundColor = [2 0 0];
    t.assertFail('Invalid RGB color was accepted.');
catch ME
    t.verifyNotEqual(ME.identifier,'matlab.unittest:AssertionFailed');
end
t.verifyEqual(s.Display.BackgroundColor,[0 0 0]);
entries = oops.Log.asTable();
t.verifyEqual(entries.level(end),"ERROR");
end

function testMalformedSettingsFileLogsAndRethrows(t)
file = fullfile(t.TestData.Folder,'malformed.json');
fid = fopen(file,'w'); fprintf(fid,'{invalid'); fclose(fid);
try
    oops.config.Settings.load(file);
    t.assertFail('Malformed settings were accepted.');
catch ME
    t.verifyNotEqual(ME.identifier,'matlab.unittest:AssertionFailed');
end
entries = oops.Log.asTable();
t.verifyEqual(entries.level(end),"ERROR");
end

function saveEvent(sink,e)
sink('event') = e;
end
