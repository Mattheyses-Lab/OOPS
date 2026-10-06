% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testVersioning
%TESTVERSIONING Verify independent generations, migration scope, and safe persistence.
tests = functiontests(localfunctions);
end
function setupOnce(t)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run(BioFormats=false); logger = oops.Log.get(); logger.PrintToCommandWindow = false;
end
function setup(t)
folder = tempname; mkdir(folder); t.TestData.Folder = folder;
end
function teardown(t)
rmdir(t.TestData.Folder,'s');
end
function teardownOnce(~)
oops.Log.close();
end
function testNumericVersionOrdering(t)
t.verifyEqual(oops.Version.compare("2.0","2.0.0"),0);
t.verifyEqual(oops.Version.compare("2","2.0.0"),0);
t.verifyEqual(oops.Version.compare("1.100.0","2.0.0"),-1);
t.verifyEqual(oops.Version.compare("2.0.100","2.1.0"),-1);
t.verifyEqual(oops.Version.compare("2.10.0","2.9.999"),1);
t.verifyEqual(oops.Version.compare("2.0.1","2.0.0"),1);
for value = ["","unknown","2.0.0.1","2.-1","2.0-beta"]
    t.verifyError(@() oops.Version.compare(value,"2.0.0"),'oops:version:InvalidVersion');
end
end
function testAllMetadataUsesInfo(t)
s = oops.config.Settings(); cleaner = onCleanup(@() delete(s)); S = s.toStruct();
t.verifyEqual(string(S.Version),oops.Info.Version);
t.verifyEqual(string(S.SettingsSchemaVersion),oops.Info.SettingsSchemaVersion);
t.verifyEqual(string(S.FactoryDefaultsVersion),oops.Info.FactoryDefaultsVersion);
t.verifyEqual(oops.Info.Version,"2.0.0");
p = oops.model.Project(); projectCleaner = onCleanup(@() delete(p));
t.verifyEqual(p.Version,oops.Info.Version); t.verifyEqual(p.SchemaVersion,oops.Info.ProjectSchemaVersion);
end
function testSchemaPreservesIntentAndFillsMissingFields(t)
S = oldSnapshot(); S = rmfield(S,'View');
S.Display = rmfield(S.Display,'AutoScaleDisplayOrder');
[S,migrated] = oops.config.Settings.migrate(S);
t.verifyTrue(migrated); t.verifyEqual(S.Segmentation.MinimumArea,42);
t.verifyFalse(S.Display.AutoScaleDisplayIntensity); t.verifyTrue(S.Display.AutoScaleDisplayOrder);
t.verifyEqual(string(S.SettingsSchemaVersion),oops.Info.SettingsSchemaVersion);
t.verifyEqual(string(S.FactoryDefaultsVersion),"0.3.0");
t.verifyEqual(string(S.View.LeftSource),"Input");
s = oops.config.Settings(); cleaner = onCleanup(@() delete(s)); s.fromStruct(S);
t.verifyEqual(s.Segmentation.MinimumArea,42); t.verifyFalse(s.Display.AutoScaleDisplayIntensity);
end
function testMissingVersionFieldsAndOldColormapCategory(t)
S = struct('Colormaps',struct('Intensity','gray','Order','parula','Azimuth','hsv','Category','MATLAB'));
[S,migrated] = oops.config.Settings.migrate(S);
t.verifyTrue(migrated); t.verifyFalse(isfield(S.Colormaps,'Category'));
t.verifyEqual(string(S.Colormaps.IntensityCategory),"MATLAB");
t.verifyEqual(string(S.Colormaps.OrderCategory),"MATLAB");
t.verifyEqual(string(S.FactoryDefaultsVersion),"0.0.0");
end
function testFactoryDefaultsAreSeparateAndIdempotent(t)
S = oldSnapshot(); [schema,~] = oops.config.Settings.migrate(S);
[factory,migrated] = oops.config.Settings.migrate(S,ApplyFactoryDefaults=true);
defaults = oops.config.Settings(); cleaner = onCleanup(@() delete(defaults));
t.verifyTrue(migrated); t.verifyEqual(schema.Segmentation.MinimumArea,42);
t.verifyEqual(factory.Segmentation.MinimumArea,defaults.Segmentation.MinimumArea);
t.verifyTrue(factory.Display.AutoScaleDisplayIntensity);
t.verifyEqual(string(factory.IO.DefaultFolder),"images/μ");
t.verifyEqual(string(factory.FactoryDefaultsVersion),oops.Info.FactoryDefaultsVersion);
[again,changed] = oops.config.Settings.migrate(factory,ApplyFactoryDefaults=true);
t.verifyFalse(changed); t.verifyEqual(again,factory);
end
function testLoadPersistsMigrationAndBacksUpDefaults(t)
file = fullfile(t.TestData.Folder,'settings.json'); original = jsonencode(oldSnapshot());
write(file,original); s = oops.config.Settings.load(file); cleaner = onCleanup(@() delete(s));
saved = jsondecode(fileread(file));
t.verifyEqual(string(saved.SettingsSchemaVersion),oops.Info.SettingsSchemaVersion);
t.verifyEqual(string(saved.FactoryDefaultsVersion),oops.Info.FactoryDefaultsVersion);
t.verifyEqual(s.IO.DefaultFolder,"images/μ");
backup = string(file)+".before-"+oops.Info.FactoryDefaultsVersion+".bak";
t.verifyEqual(fileread(backup),original);
s.Segmentation.MinimumArea = 77; s.save(file);
again = oops.config.Settings.load(file); otherCleaner = onCleanup(@() delete(again));
t.verifyEqual(again.Segmentation.MinimumArea,77);
t.verifyEqual(fileread(backup),original,'Later loads must not overwrite the original backup.');
end
function testFutureSchemaCannotRewriteAFile(t)
s = oops.config.Settings(); cleaner = onCleanup(@() delete(s)); S = s.toStruct();
S.SettingsSchemaVersion = '9.0.0'; file = fullfile(t.TestData.Folder,'future.json');
original = jsonencode(S); write(file,original);
t.verifyError(@() oops.config.Settings.load(file),'oops:config:NewerSchema');
t.verifyEqual(fileread(file),original);
end
function testFutureFactoryDefaultsCannotRewriteAppSettings(t)
s = oops.config.Settings(); cleaner = onCleanup(@() delete(s)); S = s.toStruct();
S.FactoryDefaultsVersion = '9.0.0'; file = fullfile(t.TestData.Folder,'future-defaults.json');
original = jsonencode(S); write(file,original);
t.verifyError(@() oops.config.Settings.load(file),'oops:config:NewerFactoryDefaults');
t.verifyEqual(fileread(file),original);
% Embedded snapshots keep their explicit values regardless of factory generation.
s.fromStruct(S); t.verifyEqual(s.Segmentation.MinimumArea,S.Segmentation.MinimumArea);
end
function S = oldSnapshot()
s = oops.config.Settings(); cleaner = onCleanup(@() delete(s));
s.Segmentation.MinimumArea = 42; s.Display.AutoScaleDisplayIntensity = false;
s.IO.DefaultFolder = "images/μ"; S = s.toStruct();
S.Version = '0.3.0'; S.SettingsSchemaVersion = '0.3.0'; S.FactoryDefaultsVersion = '0.3.0';
end
function write(file,contents)
fid = fopen(file,'w','n','UTF-8'); cleaner = onCleanup(@() fclose(fid)); fprintf(fid,'%s',contents);
end
