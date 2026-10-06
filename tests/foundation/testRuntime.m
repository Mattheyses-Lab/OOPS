% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testRuntime
%TESTRUNTIME Verify preference-driven logging without changing the user's preferences.
tests = functiontests(localfunctions);
end
function setupOnce(t)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run(BioFormats=false);
end
function setup(t)
if ispref('oops'), t.TestData.Preferences = getpref('oops'); rmpref('oops');
else, t.TestData.Preferences = struct(); end
oops.Log.close();
end
function teardown(t)
oops.Log.close();
if ispref('oops'), rmpref('oops'); end
names = fieldnames(t.TestData.Preferences);
for k = 1:numel(names), setpref('oops',names{k},t.TestData.Preferences.(names{k})); end
end
function testDeveloperProfilesAndExplicitOverrides(t)
t.verifyFalse(oops.runtime.isDeveloperMode());
logger = oops.Log.get(); logger.PrintToCommandWindow = false;
t.verifyEqual(logger.CommandWindowLevel,"INFO");
oops.runtime.enableDeveloperMode(Verbose=false);
t.verifyTrue(oops.runtime.isDeveloperMode());
t.verifyEqual(logger.CommandWindowLevel,"DEBUG"); t.verifyEqual(logger.SourceDetail,"full");
oops.Preferences.set("LoggingUILevel","WARN");
oops.runtime.disableDeveloperMode(Verbose=false);
t.verifyEqual(logger.CommandWindowLevel,"INFO"); t.verifyEqual(logger.UILevel,"WARN");
t.verifyFalse(oops.Preferences.has("LoggingCommandWindowLevel"),'Profiles must not persist defaults.');
end
function testPreferenceFacadeAndDeferredLogging(t)
oops.runtime.enableDeveloperMode(ApplyLogging=false,Verbose=false);
t.verifyFalse(oops.Log.exists());
t.verifyTrue(oops.Preferences.has("DeveloperMode"));
t.verifyEqual(oops.Preferences.get("Missing",17),17);
t.verifyTrue(ismember("DeveloperMode",oops.Preferences.names()));
info = oops.Preferences.describe();
t.verifyTrue(info.Explicit(info.Name == "DeveloperMode"));
oops.Preferences.remove("DeveloperMode"); t.verifyFalse(oops.runtime.isDeveloperMode());
end

function testAnalysisCacheSharesCalibrationsAndBoundsCorrections(t)
%TESTANALYSISCACHESHARESCALIBRATIONSANDBOUNDSCORRECTIONS Verify cache policy.

cache = oops.runtime.AnalysisCache();
ids = ["cal-a";"cal-b"];
flat = reshape(1:24,2,3,4);
cache.putCalibration(ids,flat);
[actual,found] = cache.getCalibration(ids);
t.verifyTrue(found);
t.verifyEqual(actual,flat);

% Reading image A makes B the least-recently-used entry before C is inserted.
cache.putCorrected("image-a",ids,ones(2,3,4));
cache.putCorrected("image-b",ids,2*ones(2,3,4));
[~,found] = cache.getCorrected("image-a",ids);
t.verifyTrue(found);
cache.putCorrected("image-c",ids,3*ones(2,3,4));
[~,foundA] = cache.getCorrected("image-a",ids);
[~,foundB] = cache.getCorrected("image-b",ids);
[valueC,foundC] = cache.getCorrected("image-c",ids);
t.verifyTrue(foundA);
t.verifyFalse(foundB);
t.verifyTrue(foundC);
t.verifyEqual(valueC,3*ones(2,3,4));
end
