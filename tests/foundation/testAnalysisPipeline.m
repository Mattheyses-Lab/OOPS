% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testAnalysisPipeline
%TESTANALYSISPIPELINE Test analytical polarization responses and pipeline invalidation.
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
function testKnownOrderAndCCWOrientation(t)
angles = [0 45 90 135];
for direction = [-70 -30 0 30 80]
    stack = zeros(5,7,4);
    for k = 1:4, stack(:,:,k) = 100*(1+.8*cosd(2*(angles(k)-direction))); end
    [order,azimuth] = oops.analysis.Analyzer.orderOrientation(stack);
    t.verifyEqual(order,.8*ones(5,7),'AbsTol',1e-12);
    t.verifyEqual(rad2deg(azimuth),direction*ones(5,7),'AbsTol',1e-12);
end
[order,azimuth] = oops.analysis.Analyzer.orderOrientation(zeros(2,3,4));
t.verifyTrue(all(isnan(order),'all')); t.verifyTrue(all(isnan(azimuth),'all'));
[order,azimuth] = oops.analysis.Analyzer.orderOrientation(ones(2,3,4));
t.verifyEqual(order,zeros(2,3)); t.verifyTrue(all(isnan(azimuth),'all'));
end
function testSharedCalibrationRecoversPolarizationAndClearsStaleOutputs(t)
p = oops.model.Project(); cleaner = onCleanup(@() delete(p));
calStack = repmat(reshape([2 4 3 1],1,1,4),40,50,1);
truth = repmat(reshape(100*(1+.6*cosd(2*([0 45 90 135]-25))),1,1,4),40,50,1);
a = p.addGroup("A"); b = p.addGroup("B");
for g = [a b]
    im = g.addImage(input(truth.*calStack));
    mask = false(40,50); mask(12:16,12:18) = true;
    im.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
    im.setResults(struct('Order',ones(40,50)));
end
cal = p.addCalibration(input(calStack));
oops.analysis.Analyzer.assignCalibrations(p,[a;b],cal.ID);
t.verifyEqual(a.CalibrationIDs,b.CalibrationIDs); t.verifyEqual(numel(p.Calibrations),1);
t.verifyEqual(a.Calibrations,cal); t.verifyEqual(b.Calibrations,cal);
t.verifyEqual(oops.analysis.Analyzer.correctedStack(a.Images(1)),truth*4,'AbsTol',1e-10);
t.verifyEmpty(a.Images(1).Order); t.verifyEmpty(a.Images(1).Mask);
[~,calibrationInfo] = oops.render.source(a.Images(1),"Calibration",p.Settings);
t.verifyEqual(calibrationInfo.CLim,[0 1]);
oops.analysis.Analyzer.analyzeImages([a.Images;b.Images],p.Settings);
t.verifyEqual(a.Images(1).Order,.6*ones(40,50),'AbsTol',1e-12);
t.verifyEqual(rad2deg(a.Images(1).Azimuth),25*ones(40,50),'AbsTol',1e-12);
t.verifyEqual(a.Images(1).getFrame(1),truth(:,:,1).*calStack(:,:,1));
end
function testCalibrationReplicatesAndPreflight(t)
p = oops.model.Project(); cleaner = onCleanup(@() delete(p)); g = p.addGroup("A");
im = g.addImage(input(ones(20,30,4))); im.setResults(struct('Order',ones(20,30)));
a = p.addCalibration(input(repmat(reshape([1 2 3 4],1,1,4),20,30,1)));
b = p.addCalibration(input(repmat(reshape([3 4 5 6],1,1,4),20,30,1)));
flat = oops.analysis.Analyzer.calibration(p,[a.ID;b.ID]);
t.verifyEqual(flat(1,1,:),reshape([2 3 4 5]/5,1,1,4));
bad = p.addCalibration(input(ones(5,7,4)));
t.verifyError(@() oops.analysis.Analyzer.assignCalibrations(p,g,bad.ID), ...
    'oops:analysis:CalibrationSizeMismatch');
t.verifyEmpty(g.CalibrationIDs); t.verifyEqual(im.Order,ones(20,30));
end
function testFlatFieldMatchesLegacyFormula(t)
%TESTFLATFIELDMATCHESLEGACYFORMULA Preserve old averaging and division order.

calibrations = { ...
    reshape([2 4 6 8;3 5 7 9],1,2,4), ...
    reshape([4 8 10 12;5 9 11 15],1,2,4), ...
    reshape([6 10 14 16;7 13 15 21],1,2,4)};

% Legacy loadFFCImages summed replicates, divided once, then used one global
% maximum across all pixels and polarization frames.
legacyAverage = sum(cat(4,calibrations{:}),4)/numel(calibrations);
legacyFlat = legacyAverage/max(legacyAverage,[],'all');
raw = reshape(101:108,1,2,4);
legacyCorrected = raw./legacyFlat;

actualFlat = oops.analysis.normalizeCalibration(calibrations);
actualCorrected = oops.analysis.flatFieldCorrection(raw,actualFlat);

t.verifyEqual(actualFlat,legacyFlat);
t.verifyEqual(actualCorrected,legacyCorrected);
end
function testDetectorRangeWarningAndDisplayQuantization(t)
%TESTDETECTORRANGEWARNINGANDDISPLAYQUANTIZATION Separate analysis from display.

p = oops.model.Project(); cleaner = onCleanup(@() delete(p));
g = p.addGroup("Detector range");
raw = repmat(uint16(50000),5,7,4);
calibration = repmat(uint16(1000),5,7,4);
calibration(1,1,:) = 500;
image = g.addImage(input(raw),"Bright image");
cal = p.addCalibration(input(calibration),"Half-field pixel");

oops.analysis.Analyzer.assignCalibrations(p,g,cal.ID);

% Analytical correction retains its floating-point value beyond uint16 range.
analytical = oops.analysis.Analyzer.correctedStack(image);
t.verifyClass(analytical,'double');
t.verifyEqual(analytical(1,1,:),repmat(100000,1,1,4));
[limits,className] = oops.analysis.detectorRange(image.Input);
t.verifyEqual(className,"uint16");
t.verifyEqual(limits,[0 65535]);

% Corrected and averaged display copies use the detector storage class and clip.
[corrected,correctedInfo] = oops.render.source(image,"Corrected",p.Settings);
[average,averageInfo] = oops.render.source(image,"Average intensity",p.Settings);
t.verifyClass(corrected.getPlane(1,1,1),'uint16');
t.verifyClass(average.getPlane(1,1,1),'uint16');
correctedPlane = corrected.getPlane(1,1,1);
averagePlane = average.getPlane(1,1,1);
t.verifyEqual(correctedPlane(1,1),uint16(65535));
t.verifyEqual(averagePlane(1,1),uint16(65535));
t.verifyLessThanOrEqual(correctedInfo.CLim(2),65535);
t.verifyLessThanOrEqual(averageInfo.CLim(2),65535);

entries = oops.Log.asTable();
warning = entries.level == "WARN" & contains(entries.msg,"uint16 input range") & ...
    contains(entries.msg,"Bright image") & contains(entries.msg,"4 pixels exceed 65535");
t.verifyTrue(any(warning));
end
function testMissingCalibrationWarnsAndProcessesObjects(t)
p = oops.model.Project(); cleaner = onCleanup(@() delete(p)); g = p.addGroup("A");
I = ones(60,80); I(20:24,25:29) = 100;
truth = zeros(60,80,4);
angles = [0 45 90 135];
for k = 1:4, truth(:,:,k) = I*(1+.5*cosd(2*(angles(k)-35))); end
im = g.addImage(input(truth));
oops.analysis.Analyzer.segmentImages(im,p.Settings);
t.verifyNotEmpty(im.Objects); t.verifyGreaterThan(im.Objects(1).Area,0);
t.verifyGreaterThan(im.Objects(1).SignalAverage,im.Objects(1).BGAverage);
oops.analysis.Analyzer.analyzeImages(im,p.Settings);
t.verifyEqual(im.Objects(1).OrderAvg,.5,'AbsTol',1e-12);
t.verifyEqual(im.Objects(1).AzimuthAverage,35,'AbsTol',1e-12);
t.verifyTrue(isfinite(im.Objects(1).MaxFeretDiameter));
logs = oops.Log.asTable(); t.verifyTrue(any(logs.level == "WARN" & contains(logs.msg,"No calibration")));
end
function testDeadCalibrationPixelsAndProgress(t)
cal = ones(3,5,4); cal(1,1,1) = 0;
corrected = oops.analysis.Analyzer.flatField(10*ones(3,5,4),cal);
t.verifyTrue(isinf(corrected(1,1,1)));
[order,azimuth] = oops.analysis.Analyzer.orderOrientation(corrected);
t.verifyTrue(isnan(order(1,1))); t.verifyTrue(isnan(azimuth(1,1)));
state = containers.Map('KeyType','char','ValueType','any');
oops.analysis.Analyzer.updateProgress(@(message,value) record(state,message,value),"done",1);
t.verifyEqual(state('message'),"done"); t.verifyEqual(state('value'),1);
oops.analysis.Analyzer.updateProgress(@(~,~) error('test:Sink','Broken progress sink'),"ignored",.5);
end
function testPipelineProgressIdentifiesImagesAndMeasurementSteps(t)
%TESTPIPELINEPROGRESSIDENTIFIESIMAGESANDMEASUREMENTSTEPS Support UI and headless sinks.
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup("Progress group");
average = ones(60,80);
average(20:24,25:29) = 100;
images = [g.addImage(input(repmat(average,1,1,4)),"First"); ...
    g.addImage(input(repmat(average,1,1,4)),"Second")];
cal = p.addCalibration(input(ones(60,80,4)),"Flat");
messages = strings(0,1);
fractions = cell(0,1);

% Collect the actual orchestration messages, including intermediate steps.
oops.analysis.Analyzer.assignCalibrations(p,g,cal.ID,Progress=@collect);
oops.analysis.Analyzer.segmentImages(images,p.Settings,Progress=@collect);
oops.analysis.Analyzer.analyzeImages(images,p.Settings,Progress=@collect);

t.verifyTrue(any(contains(messages,"Calibration 1/1: Flat")));
t.verifyTrue(any(contains(messages,"Computing flat field")));
t.verifyTrue(any(contains(messages,"Performing flat-field correction")));
t.verifyTrue(any(contains(messages,"Image 2/2: Second")));
t.verifyTrue(any(contains(messages,"Segmenting image and detecting objects")));
t.verifyTrue(any(contains(messages,"Calculating order and orientation statistics")));
t.verifyEqual(sum(contains(messages,"Measuring objects and local S/B")),4);
t.verifyEqual(fractions{end},1);

    function collect(message,fraction)
        messages(end+1,1) = message;
        fractions{end+1,1} = fraction;
    end
end

function testPhysicalMetadataAndPixelFallback(t)
p = oops.model.Project(); cleaner = onCleanup(@() delete(p)); g = p.addGroup("A");
im = g.addImage(input(ones(5,7,4)));
t.verifyEqual(im.PixelSize,struct('X',1,'Y',1,'UnitX',"px",'UnitY',"px"));
folder = tempname; mkdir(folder); files = onCleanup(@() rmdir(folder,'s'));
file = fullfile(folder,'physical.ome.tif'); stack = uint16(ones(5,7,1,1,4));
metadata = createMinimalOMEXMLMetadata(stack,'XYZCT');
unit = ome.units.UNITS.MICROMETER;
metadata.setPixelsPhysicalSizeX(javaObject('ome.units.quantity.Length',java.lang.Double(.12),unit),0);
metadata.setPixelsPhysicalSizeY(javaObject('ome.units.quantity.Length',java.lang.Double(.18),unit),0);
bfsave(stack,file,'metadata',metadata);
im = g.addImage(oops.io.readInput(file));
t.verifyEqual(im.PixelSize.X,.12); t.verifyEqual(im.PixelSize.Y,.18);
t.verifyEqual(im.PixelSize.UnitX,"µm"); t.verifyEqual(im.PixelSize.UnitY,"µm");
end
function testCircularRenderingKeepsAnglesNumerical(t)
p = oops.model.Project(); cleaner = onCleanup(@() delete(p)); g = p.addGroup("A");
im = g.addImage(input(ones(5,7,4))); im.setResults(struct('Azimuth',-pi/4*ones(5,7)));
[data,info] = oops.render.source(im,"Azimuth",p.Settings);
t.verifyEqual(data.getPlane(1,1,1),135*ones(5,7)); t.verifyEqual(info.CLim,[0 180]);
t.verifyEqual(im.Azimuth,-pi/4*ones(5,7));
map = info.Colormap; t.verifyLessThan(norm(map(1,:)-map(end,:)),.05);
end
function data = input(stack)
frames = arrayfun(@(k) stack(:,:,k),1:4,'UniformOutput',false);
data = matlabx.image.Image5D.fromComponents(frames);
end
function record(state,message,value)
state('message') = message; state('value') = value;
end
