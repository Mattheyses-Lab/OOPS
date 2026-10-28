% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testSegmentationParameters
%TESTSEGMENTATIONPARAMETERS Verify recipe provenance and algorithm-independent pruning.
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
t.verifyEqual(limited.CandidateCount,numel(allLists));
end
function testBrightestMeanAndStableTies(t)
s = oops.config.Segmentation(); s.BorderWidth = 0; s.MinimumArea = 1; s.MaxObjects = 2;
recipe = oops.analysis.segment.Parameters(s);
candidate = false(20,30); average = zeros(20,30);
candidate(3:4,3:4) = true; average(3:4,3:4) = 10;
candidate(3:5,12:14) = true; average(3:5,12:14) = 20;
candidate(10:11,23:24) = true; average(10:11,23:24) = 20;
[mask,lists,diagnostics] = oops.analysis.segment.filter(candidate,average,recipe);
t.verifyFalse(any(mask(3:4,3:4),'all')); t.verifyEqual(numel(lists),2);
t.verifyEqual(diagnostics.CandidateCount,3);
t.verifyEqual(diagnostics.RetainedCount,2);
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
t.verifyEqual(im.MaskProvenance.Diagnostics.RetainedCount,numel(im.Objects));
restoredProvenance = oops.model.MaskProvenance.fromStruct( ...
    im.MaskProvenance.toStruct());
t.verifyEqual(restoredProvenance.Algorithm,"Puncta/1");
t.verifyEqual(restoredProvenance.Diagnostics, ...
    im.MaskProvenance.Diagnostics);
p.Settings.Segmentation.MinimumArea = 1000; p.Settings.Segmentation.Algorithm = "Filaments/1";
oops.analysis.Analyzer.adjustSegmentation(im,"Threshold",threshold,p.Settings);
t.verifyEqual(im.SegmentationParameters.Mode,"Manual");
t.verifyEqual(automatic.Mode,"Automatic",'Recipes must have value semantics.');
t.verifyEqual(im.SegmentationParameters.Filtering.MinimumArea, ...
    automatic.Filtering.MinimumArea);
t.verifyEqual(im.SegmentationParameters.Algorithm,"Puncta/1"); t.verifyNotEmpty(im.Objects);
oops.analysis.Analyzer.adjustSegmentation(im,"Automatic",[],p.Settings);
t.verifyEqual(im.SegmentationParameters.Mode,"Automatic");
t.verifyEqual(im.SegmentationParameters.Values.Threshold,threshold);
im.setCorrectionResults(I,strings(0,1));
t.verifyNotEmpty(im.SegmentationParameters);
t.verifyTrue(im.MaskProvenance.isCurrent(im.CorrectionProvenance));
end

function testCommonFilteringCanBeAdjustedOnCommittedMask(t)
%TESTCOMMONFILTERINGCANBEADJUSTEDONCOMMITTEDMASK Re-filter cached membership.

p = oops.model.Project(); cleaner = onCleanup(@() delete(p)); %#ok<NASGU>
g = p.addGroup("A");
I = zeros(40); I(10:12,10:12) = 100; I(25:31,25:31) = 100;
im = g.addImage(matlabx.image.Image5D.fromComponents({I,I,I,I}));
p.Settings.Segmentation.BorderWidth = 0;
p.Settings.Segmentation.MinimumArea = 1;
oops.analysis.Analyzer.segmentImages(im,p.Settings);
initialCount = numel(im.Objects);
t.verifyGreaterThan(initialCount,0);

oops.analysis.Analyzer.adjustSegmentation( ...
    im,"MinimumArea",20,p.Settings);
t.verifyLessThan(numel(im.Objects),initialCount);
t.verifyEqual(im.SegmentationParameters.Filtering.MinimumArea,20);
t.verifyEqual(im.MaskProvenance.Diagnostics.RetainedCount,numel(im.Objects));
end
function testParameterValidationAndCatalog(t)
definitions = oops.analysis.segment.algorithms();
t.verifyEqual([definitions.ID],["Puncta/1","Filaments/1"]);
t.verifyEqual([definitions.Label],["Puncta","Filaments"]);
t.verifyClass(definitions(1).ParameterDefinitions, ...
    'oops.analysis.ParameterDefinition');
s = oops.config.Segmentation(); recipe = oops.analysis.segment.Parameters(s);
t.verifyError(@() recipe.withParameter("Threshold",2),'MATLAB:notLessEqual');
t.verifyError(@() recipe.withParameter("Sensitivity",.5),'oops:analysis:UnknownParameter');
t.verifyError(@() oops.analysis.segment.algorithms("Missing"),'oops:analysis:UnknownAlgorithm');
s.Algorithm = "Filaments/1"; recipe = oops.analysis.segment.Parameters(s);
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
[~,average] = oops.render.source(im,"AverageIntensity",p.Settings);
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

function testOrderAutoScalingMethods(t)
%TESTORDERAUTOSCALINGMETHODS Resolve robust, zero-anchored, and data ranges.

p = oops.model.Project(); cleaner = onCleanup(@() delete(p));
g = p.addGroup("A");
I = ones(10);
im = g.addImage(matlabx.image.Image5D.fromComponents({I,I,I,I}));
order = reshape(linspace(.2,.8,100),10,10);
im.setResults(struct('AverageIntensity',I,'Order',order));

p.Settings.Display.OrderAutoScaleMethod = "Contrast";
[~,~,ranges] = oops.render.displayLimits(im,"Order",p.Settings);
t.verifyEqual(ranges.Auto,prctile(order(:),[1 99]),'AbsTol',eps);

p.Settings.Display.OrderAutoScaleMethod = "Gentle contrast";
[~,~,ranges] = oops.render.displayLimits(im,"Order",p.Settings);
t.verifyEqual(ranges.Auto,prctile(order(:),[0.5 99.5]),'AbsTol',eps);

intensity = reshape(linspace(10,210,100),10,10);
im.setResults(struct('AverageIntensity',intensity,'Order',order));
p.Settings.Display.IntensityAutoScaleMethod = "Gentle contrast";
[~,~,ranges] = oops.render.displayLimits(im,"Intensity",p.Settings);
t.verifyEqual(ranges.Auto,prctile(intensity(:),[0.5 99.5]),'AbsTol',eps);

p.Settings.Display.OrderAutoScaleMethod = "Zero to max";
[~,~,ranges] = oops.render.displayLimits(im,"Order",p.Settings);
t.verifyEqual(ranges.Auto,[0 .8],'AbsTol',eps);

p.Settings.Display.OrderAutoScaleMethod = "Data range";
[~,~,ranges] = oops.render.displayLimits(im,"Order",p.Settings);
t.verifyEqual(ranges.Auto,[.2 .8],'AbsTol',eps);
end

function testIntensityLimitsUseSourceClassDisplayValues(t)
%TESTINTENSITYLIMITSUSESOURCECLASSDISPLAYVALUES Match uint8 display quantization.

p = oops.model.Project(); cleaner = onCleanup(@() delete(p));
p.Settings.Display.KeepAutoDisplayIntensity = false;
p.Settings.Display.LockDisplayIntensity = false;
g = p.addGroup("A");
raw = uint8(10*ones(4,5));
im = g.addImage(matlabx.image.Image5D.fromComponents({raw,raw,raw,raw}));
average = reshape(linspace(10.2,20.8,20),4,5);
im.setResults(struct('AverageIntensity',average));
im.setDisplayRange("Intensity",[10 21]);

[value,bounds,ranges] = oops.render.displayLimits(im,"Intensity",p.Settings);
[display,info] = oops.render.source(im,"AverageIntensity",p.Settings);
displayPlane = display.getPlane(1);

t.verifyClass(displayPlane,'uint8');
t.verifyEqual(displayPlane,uint8(round(average)));
t.verifyEqual(value,[10 21]);
t.verifyEqual(bounds,[10 21]);
t.verifyEqual(ranges.Reset,[10 21]);
expectedAuto = round(prctile(double(uint8(round(average(:)))),[1 99]));
t.verifyEqual(ranges.Auto,expectedAuto);
t.verifyEqual(info.CLim,[10 21]);
t.verifyEqual(oops.render.normalizeIntensityDisplayRange(im,[10.2 20.8]),[10 21]);

% Floating-point sources retain their own class and fractional limits.
singleRaw = single(10*ones(4,5));
singleImage = g.addImage(matlabx.image.Image5D.fromComponents( ...
    {singleRaw,singleRaw,singleRaw,singleRaw}));
singleImage.setResults(struct('AverageIntensity',average));
singleImage.setDisplayRange("Intensity",[10.2 20.8]);
[singleDisplay,singleInfo] = oops.render.source( ...
    singleImage,"AverageIntensity",p.Settings);

t.verifyClass(singleDisplay.getPlane(1),'single');
t.verifyEqual(singleDisplay.getPlane(1),single(average));
t.verifyEqual(singleInfo.CLim,[10.2 20.8]);
end

function testPendingCalibrationInvalidatesAnOldManualRecipe(t)
p = oops.model.Project(); cleaner = onCleanup(@() delete(p)); g = p.addGroup("A");
I = zeros(60); I(20:24,20:24) = 100;
im = g.addImage(matlabx.image.Image5D.fromComponents({I,I,I,I}));
oops.analysis.Analyzer.segmentImages(im,p.Settings);
cal = p.addCalibration(matlabx.image.Image5D.fromComponents({ones(60),ones(60),ones(60),ones(60)}));
g.setCalibrations(cal.ID);
oops.analysis.Analyzer.adjustSegmentation(im,"Threshold",.5,p.Settings);
t.verifyNotEmpty(im.SegmentationParameters);
t.verifyNotEmpty(im.Mask);
t.verifyTrue(im.MaskProvenance.isCurrent(im.CorrectionProvenance));
end

function testAdjustmentUsesCachedEnhancementAndMatchesPreview(t)
p = oops.model.Project(); cleanup = onCleanup(@() delete(p)); g = p.addGroup("Cache");
I = zeros(60); I(20:24,20:24) = 100; I(35:39,35:39) = 60;
image = g.addImage(matlabx.image.Image5D.fromComponents({I,I,I,I}));
oops.analysis.Analyzer.segmentImages(image,p.Settings);
cached = image.Results.Segmentation; average = image.Results.AverageIntensity;
recipe = image.SegmentationParameters.withParameter("Threshold",.4);
definition = oops.analysis.segment.algorithms(recipe.Algorithm);
expected = oops.analysis.segment.filter( ...
    definition.PreviewFcn(cached,recipe),average,recipe);
profile clear; profile on;
profileCleanup = onCleanup(@() profile('off'));
oops.analysis.Analyzer.adjustSegmentation(image,"Threshold",.4,p.Settings);
profile off; stats = profile('info');
names = string({stats.FunctionTable.FunctionName});
t.verifyFalse(any(endsWith(names,"oops.analysis.segment.puncta")), ...
    "Commit must not repeat enhancement/Otsu.");
t.verifyFalse(any(contains(names,"readStack")),"Commit must not reread input frames.");
t.verifyEqual(image.Mask,expected);
t.verifyEqual(image.Results.Segmentation.Enhanced,cached.Enhanced);
t.verifyEqual(image.Results.AverageIntensity,average);
t.verifyEqual(image.SegmentationParameters.Automatic,recipe.Automatic);
end
