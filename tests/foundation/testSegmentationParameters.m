% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testSegmentationParameters
%TESTSEGMENTATIONPARAMETERS Verify recipe provenance and strategy-independent pruning.
tests = functiontests(localfunctions);
end
function setupOnce(t)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run(); logger = oops.Log.get(); logger.PrintToCommandWindow = false;
end
function teardownOnce(~)
oops.Log.close();
end
function testOtsuDoesNotChangeWhenLimitingObjects(t)
s = oops.config.Segmentation(); s.BorderWidth = 0; s.MinimumArea = 1;
I = zeros(90);
for y = 10:15:80
    for x = 10:15:80, I(y:y+4,x:x+4) = x+y; end
end
s.MaxObjects = 0;
[~,allLists,full] = oops.analysis.segment.mask(I,s);
s.MaxObjects = 2;
[mask,lists,limited] = oops.analysis.segment.mask(I,s);
t.verifyGreaterThan(numel(allLists),2); t.verifyEqual(numel(lists),2);
t.verifyEqual(limited.Threshold,graythresh(limited.Enhanced));
t.verifyEqual(limited.Threshold,full.Threshold);
t.verifyEqual(sort(vertcat(lists{:})),find(mask));
t.verifyEqual(limited.Parameters.CandidateCount,numel(allLists));
end
function testBrightestMeanAndStableTies(t)
s = oops.config.Segmentation(); s.BorderWidth = 0; s.MinimumArea = 1; s.MaxObjects = 2;
recipe = oops.analysis.segment.Parameters(s);
candidate = false(20,30); average = zeros(20,30);
candidate(3:4,3:4) = true; average(3:4,3:4) = 10;
candidate(3:5,12:14) = true; average(3:5,12:14) = 20;
candidate(10:11,23:24) = true; average(10:11,23:24) = 20;
[mask,lists,recipe] = oops.analysis.segment.filter(candidate,average,recipe);
t.verifyFalse(any(mask(3:4,3:4),'all')); t.verifyEqual(numel(lists),2);
t.verifyEqual(recipe.CandidateCount,3); t.verifyEqual(recipe.RetainedCount,2);
s.MaxObjects = 1;
[mask,~,~] = oops.analysis.segment.filter(candidate,average,oops.analysis.segment.Parameters(s));
t.verifyTrue(all(mask(3:5,12:14),'all')); t.verifyFalse(any(mask(10:11,23:24),'all'));
end
function testManualProvenanceAndSettingsSnapshot(t)
p = oops.model.Project(); cleaner = onCleanup(@() delete(p)); g = p.addGroup("A");
I = zeros(60); I(20:24,20:24) = 100;
im = g.addImage(matlabx.image.Image5D.fromComponents({I,I,I,I}));
oops.analysis.Analyzer.segmentImages(im,p.Settings);
automatic = im.SegmentationParameters; threshold = automatic.Values.Threshold;
p.Settings.Segmentation.MinimumArea = 1000; p.Settings.Segmentation.Strategy = "Filaments";
oops.analysis.Analyzer.adjustSegmentation(im,"Threshold",threshold,p.Settings);
t.verifyEqual(im.SegmentationParameters.Mode,"Manual");
t.verifyEqual(automatic.Mode,"Automatic",'Recipes must have value semantics.');
t.verifyEqual(im.SegmentationParameters.Common.MinimumArea,automatic.Common.MinimumArea);
t.verifyEqual(im.SegmentationParameters.Strategy,"Puncta"); t.verifyNotEmpty(im.Objects);
oops.analysis.Analyzer.adjustSegmentation(im,"Automatic",[],p.Settings);
t.verifyEqual(im.SegmentationParameters.Mode,"Automatic");
t.verifyEqual(im.SegmentationParameters.Values.Threshold,threshold);
im.setCorrectionResults(I,strings(0,1)); t.verifyEmpty(im.SegmentationParameters);
end
function testParameterValidationAndCatalog(t)
definitions = oops.analysis.segment.strategies(); t.verifyEqual([definitions.Name],["Puncta","Filaments"]);
s = oops.config.Segmentation(); recipe = oops.analysis.segment.Parameters(s);
t.verifyError(@() recipe.withParameter("Threshold",2),'MATLAB:notLessEqual');
t.verifyError(@() recipe.withParameter("Sensitivity",.5),'oops:analysis:UnknownParameter');
t.verifyError(@() oops.analysis.segment.strategies("Missing"),'oops:analysis:UnknownStrategy');
s.Strategy = "Filaments"; recipe = oops.analysis.segment.Parameters(s);
t.verifyError(@() recipe.withParameter("Threshold",.5),'oops:analysis:UnknownParameter');
end
function testDisplayLimitsDoNotOverwriteManualValues(t)
p = oops.model.Project(); cleaner = onCleanup(@() delete(p)); g = p.addGroup("A");
I = reshape(1:100,10,10); im = g.addImage(matlabx.image.Image5D.fromComponents({I,2*I,3*I,4*I}));
im.setCorrectionResults(I*10,strings(0,1));
im.setResults(struct('AverageIntensity',I*10,'Order',reshape(linspace(0,1,100),10,10)));
im.setDisplayRange("Intensity",[20 50]); im.setDisplayRange("Order",[.2 .8]);
[~,a] = oops.render.source(im,"Input",p.Settings); [~,b] = oops.render.source(im,"Corrected",p.Settings);
t.verifyEqual(b.CLim,a.CLim);
[~,average] = oops.render.source(im,"Average intensity",p.Settings);
t.verifyEqual(average.CLim,b.CLim);
t.verifyEqual(im.IntensityDisplayRange,[20 50]);
t.verifyEqual(im.OrderDisplayRange,[.2 .8]);
p.Settings.Display.AutoScaleDisplayIntensity = false;
[~,a] = oops.render.source(im,"Input",p.Settings); t.verifyEqual(a.CLim,[20 50]);
[~,b] = oops.render.source(im,"Corrected",p.Settings); t.verifyEqual(b.CLim,[20 50]);
p.Settings.Display.AutoScaleDisplayOrder = false;
[~,a] = oops.render.source(im,"Order",p.Settings); t.verifyEqual(a.CLim,[.2 .8]);
S = p.Settings.toStruct(); copy = oops.config.Settings(); copy.fromStruct(S);
t.verifyFalse(copy.Display.AutoScaleDisplayOrder); t.verifyFalse(copy.Display.AutoScaleDisplayIntensity);
end

function testPendingCalibrationInvalidatesAnOldManualRecipe(t)
p = oops.model.Project(); cleaner = onCleanup(@() delete(p)); g = p.addGroup("A");
I = zeros(60); I(20:24,20:24) = 100;
im = g.addImage(matlabx.image.Image5D.fromComponents({I,I,I,I}));
oops.analysis.Analyzer.segmentImages(im,p.Settings);
cal = p.addCalibration(matlabx.image.Image5D.fromComponents({ones(60),ones(60),ones(60),ones(60)}));
g.setCalibrations(cal.ID);
t.verifyError(@() oops.analysis.Analyzer.adjustSegmentation(im,"Threshold",.5,p.Settings),'oops:analysis:NoSegmentation');
t.verifyEmpty(im.SegmentationParameters); t.verifyEmpty(im.Mask);
end

function testAdjustmentUsesCachedEnhancementAndMatchesPreview(t)
p = oops.model.Project(); cleanup = onCleanup(@() delete(p)); g = p.addGroup("Cache");
I = zeros(60); I(20:24,20:24) = 100; I(35:39,35:39) = 60;
image = g.addImage(matlabx.image.Image5D.fromComponents({I,I,I,I}));
oops.analysis.Analyzer.segmentImages(image,p.Settings);
cached = image.Results.Segmentation; average = image.Results.AverageIntensity;
recipe = image.SegmentationParameters.withParameter("Threshold",.4);
definition = oops.analysis.segment.strategies(recipe.Strategy);
expected = oops.analysis.segment.filter(definition.Preview(cached,recipe),average,recipe);
profile clear; profile on;
profileCleanup = onCleanup(@() profile('off'));
oops.analysis.Analyzer.adjustSegmentation(image,"Threshold",.4,p.Settings);
profile off; stats = profile('info');
names = string({stats.FunctionTable.FunctionName});
t.verifyFalse(any(contains(names,"puncta")),"Commit must not repeat enhancement/Otsu.");
t.verifyFalse(any(contains(names,"readStack")),"Commit must not reread input frames.");
t.verifyEqual(image.Mask,expected);
t.verifyEqual(image.Results.Segmentation.Enhanced,cached.Enhanced);
t.verifyEqual(image.Results.AverageIntensity,average);
t.verifyEqual(image.SegmentationParameters.AutomaticParameters,recipe.AutomaticParameters);
end
