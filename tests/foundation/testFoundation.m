% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testFoundation
% Behavioral checks for the new foundation; requires MATLAB R2026b and IPT.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run();
logger = oops.Log.get();
logger.PrintToCommandWindow = false;
testCase.TestData.Folder = tempname;
mkdir(testCase.TestData.Folder);
file = fullfile(testCase.TestData.Folder,'four-angles.tif');
for k = 1:4
    frame = uint16(reshape(1:120,10,12) + 100*k);
    if k == 1
        imwrite(frame,file);
    else
        imwrite(frame,file,'WriteMode','append');
    end
end
testCase.TestData.File = file;
end

function teardownOnce(testCase)
oops.Log.close();
if isfield(testCase.TestData,'Folder') && isfolder(testCase.TestData.Folder)
    rmdir(testCase.TestData.Folder,'s');
end
end

function testSettingsPayloadAndForwarding(t)
s = oops.config.Settings();
cleanup = onCleanup(@() delete(s));
[generic,l1] = capture(s,'Changed');
[domain,l2] = capture(s,'DisplayChanged');
listeners = onCleanup(@() delete([l1,l2]));
s.Display.AutoScaleDisplayIntensity = false;
e = generic('last');
t.verifyEqual(generic('count'),1);
t.verifyEqual(domain('count'),1);
t.verifyEqual(e.Domain,"Display");
t.verifyEqual(e.Name,"AutoScaleDisplayIntensity");
t.verifyEqual(e.OldValue,true);
t.verifyEqual(e.NewValue,false);
s.Display.AutoScaleDisplayIntensity = false;
t.verifyEqual(generic('count'),1,'Unchanged values must not emit another event.');
end

function testSettingsPersistence(t)
file = fullfile(t.TestData.Folder,'settings.json');
s = oops.config.Settings.load(file);
s.IO.DefaultFolder = "images/μ";
s.Display.AutoScaleDisplayIntensity = false;
s.save(file);
loaded = oops.config.Settings.load(file);
t.verifyEqual(loaded.toStruct(),s.toStruct());
oops.config.Settings.restore(file);
restored = oops.config.Settings.load(file);
t.verifyTrue(restored.Display.AutoScaleDisplayIntensity);
end

function testInvalidSettingsDoNotChangeState(t)
s = oops.config.Settings();
[state,l] = capture(s,'Changed');
cleanup = onCleanup(@() delete(l));
try
    s.Segmentation.Strategy = "unknown";
    t.assertFail('Unsupported strategy was accepted.');
catch e
    t.verifyNotEqual(e.identifier,'matlab.unittest:AssertionFailed');
end
t.verifyEqual(s.Segmentation.Strategy,"Puncta");
t.verifyEqual(state('count'),0);
end

function testHierarchyAndEvents(t)
p = oops.model.Project('Experiment');
cleanup = onCleanup(@() delete(p));
[added,l1] = capture(p,'ImageAdded');
[removed,l2] = capture(p,'ImageRemoved');
listeners = onCleanup(@() delete([l1,l2]));
g = p.addGroup('Any user-defined collection');
im = g.addImage(memoryInput(),'Replicate');
t.verifyEqual(g.Parent,p);
t.verifyEqual(im.Parent,g);
t.verifyEqual(added('last').ImageID,im.ID);
t.verifyEqual(added('last').GroupID,g.ID);
p.setActiveImage(im);
g.removeImage(im);
t.verifyEmpty(im.Parent);
t.verifyEmpty(p.ActiveImage);
t.verifyEmpty(g.Images);
t.verifyEqual(removed('last').ImageID,im.ID);
t.verifyTrue(isvalid(im),'Removal detaches; it does not delete the image.');
delete(im);
end

function testGroupRemovalClearsSelection(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup('Group');
im = g.addImage(memoryInput());
p.setActiveImage(im);
p.removeGroup(g);
t.verifyEmpty(p.Groups);
t.verifyEmpty(p.ActiveImage);
t.verifyEmpty(g.Parent);
t.verifyEmpty(im.Parent);
delete(im);
delete(g);
end

function testGroupColorsFollowDefaultOrderAndRemainEditable(t)
%TESTGROUPCOLORSFOLLOWDEFAULTORDERANDREMAINEDITABLE Store group identity colors.

p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
order = get(groot,'defaultAxesColorOrder');
first = p.addGroup("First");
second = p.addGroup("Second");
t.verifyEqual(first.Color,order(1,:));
t.verifyEqual(second.Color,order(2,:));
first.setProperties("Renamed",[0.1 0.2 0.3]);
t.verifyEqual(first.Name,"Renamed");
t.verifyEqual(first.Color,[0.1 0.2 0.3]);
end

function testForeignSelectionAndRemovalAreRejected(t)
p = oops.model.Project();
other = oops.model.Project();
cleanup = onCleanup(@() delete([p,other]));
g = p.addGroup('Here');
foreign = other.addGroup('Elsewhere');
im = foreign.addImage(memoryInput());
t.verifyError(@() p.setActiveImage(im),'oops:model:UnknownImage');
t.verifyError(@() g.removeImage(im),'oops:model:UnknownImage');
t.verifyError(@() p.removeGroup(foreign),'oops:model:UnknownGroup');
t.verifyEmpty(p.ActiveImage);
t.verifyEqual(im.Parent,foreign);
end

function testFourComponentMappingAndValues(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup('Group');
im = g.addImage(memoryInput());
t.verifyEqual(im.FrameLocations,[(1:4)',ones(4,2)]);
t.verifyEqual(im.PolarizationAngles,[0 45 90 135]);
for k = 1:4
    t.verifyEqual(im.getFrame(k),uint16(k*ones(10,12)));
end
end

function testZAndTimeMapping(t)
for axis = [4 5]
    dimensions = [10 12 1 1 1];
    dimensions(axis) = 4;
    input = matlabx.image.Image5D.fromComponents(reshape(uint16(1:480),dimensions));
    locations = oops.io.fourAngleLocations(input);
    expected = ones(4,3);
    expected(:,axis-2) = (1:4)';
    t.verifyEqual(locations,expected);
end
end

function testInvalidInputsDoNotAddImages(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup('Group');
[state,l] = capture(p,'ImageAdded');
listener = onCleanup(@() delete(l));
inputs = {matlabx.image.Image5D.fromComponents(ones(10,12)), ...
    matlabx.image.Image5D.fromComponents({ones(10,12,3),ones(10,12,3),ones(10,12,3),ones(10,12,3)}), ...
    matlabx.image.Image5D.fromComponents({ones(10,12,1,2),ones(10,12,1,2)})};
for k = 1:numel(inputs)
    t.verifyError(@() g.addImage(inputs{k}),'oops:io:InvalidFourAngleInput');
end
t.verifyEmpty(g.Images);
t.verifyEqual(state('count'),0);
end

function testMaskDefinesObjectsAndPreservesImageResults(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup('Group');
im = g.addImage(memoryInput());
[changed,l] = capture(p,'ObjectsChanged');
listener = onCleanup(@() delete(l));
mask = false(10,12);
mask(2:3,2:3) = true;
mask(6:8,8) = true;
im.setResults(struct('Order',ones(10,12)));
lists = oops.analysis.segment.objectsFromMask(mask);
im.setMask(mask,lists);
t.verifyEqual(numel(im.Objects),2);
t.verifyEqual(im.Mask,mask);
t.verifyEqual(im.Results.Order,ones(10,12));
t.verifyEqual(im.Objects(1).Parent,im);
t.verifyEqual(im.Objects(1).PixelIdxList,lists{1});
t.verifyEqual(changed('last').ImageID,im.ID);
old = im.Objects;
im.setMask(false(10,12),{});
t.verifyEmpty(im.Objects);
t.verifyFalse(any(isvalid(old)));
t.verifyEqual(numel(changed('last').OldIDs),2);
end

function testInvalidMaskPartitionIsAtomic(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup('Group');
im = g.addImage(memoryInput());
mask = false(10,12); mask(1:2) = true;
im.setMask(mask,{[1;2]});
old = im.Objects;
t.verifyError(@() im.setMask(mask,{1}),'oops:model:InvalidObjectPartition');
t.verifyError(@() im.setMask(mask,{[1;2],[1;2]}),'oops:model:InvalidObjectPartition');
t.verifyError(@() im.setMask(false(3),{}),'oops:model:MaskSizeMismatch');
t.verifyEqual(im.Objects,old);
t.verifyEqual(im.Mask,mask);
end

function testConnectivityLivesInAnalysis(t)
mask = logical(eye(3));
t.verifyEqual(numel(oops.analysis.segment.objectsFromMask(mask,4)),3);
t.verifyEqual(numel(oops.analysis.segment.objectsFromMask(mask,8)),1);
end

function testFileBackedLifecycleAndExactValues(t)
input = oops.io.readInput(t.TestData.File);
t.verifyTrue(input.IsFileBacked);
t.verifyFalse(input.IsLoaded);
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup('Group');
im = g.addImage(input);
for k = 1:4
    t.verifyEqual(im.getFrame(k),uint16(reshape(1:120,10,12)+100*k));
end
t.verifyFalse(im.IsLoaded,'Individual plane reads must remain lazy.');
im.loadInput();
t.verifyTrue(im.IsLoaded);
im.unloadInput();
t.verifyFalse(im.IsLoaded);
t.verifyEqual(im.getFrame(4),uint16(reshape(1:120,10,12)+400));
end

function testActivePlusPreviousCacheAcrossGroups(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g1 = p.addGroup('One');
g2 = p.addGroup('Two');
a = g1.addImage(oops.io.readInput(t.TestData.File),'A');
b = g2.addImage(oops.io.readInput(t.TestData.File),'B');
c = g1.addImage(oops.io.readInput(t.TestData.File),'C');
[state,l] = capture(p,'ActiveImageChanged');
listener = onCleanup(@() delete(l));
p.setActiveImage(a);
p.setActiveImage(b);
t.verifyTrue(a.IsLoaded && b.IsLoaded);
p.setActiveImage(c);
t.verifyFalse(a.IsLoaded);
t.verifyTrue(b.IsLoaded && c.IsLoaded);
t.verifyEqual(state('last').NewID,c.ID);
t.verifyEqual(state('last').OldID,b.ID);
p.setActiveImage(b); % update recency, even for an already-loaded source
p.setActiveImage(a);
t.verifyFalse(c.IsLoaded);
t.verifyTrue(a.IsLoaded && b.IsLoaded);
p.setActiveImage(a);
t.verifyEqual(state('count'),5);
end

function testDistinctIdentities(t)
p = oops.model.Project();
other = oops.model.Project();
cleanup = onCleanup(@() delete([p,other]));
g1 = p.addGroup('One');
g2 = p.addGroup('Two');
a = g1.addImage(memoryInput());
b = g2.addImage(memoryInput());
t.verifyNotEqual(p.ID,other.ID);
t.verifyNotEqual(g1.ID,g2.ID);
t.verifyNotEqual(a.ID,b.ID);
mask = false(10,12); mask([1,120]) = true;
a.setMask(mask,{1,120});
t.verifyNotEqual(a.Objects(1).ID,a.Objects(2).ID);
end

function testSharedInputSourceIsRejected(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g1 = p.addGroup('One');
g2 = p.addGroup('Two');
input = memoryInput();
g1.addImage(input);
t.verifyError(@() g2.addImage(input),'oops:model:InputAlreadyOwned');
wrapper = matlabx.image.Image5D(input.Source);
t.verifyError(@() g2.addImage(wrapper),'oops:model:InputAlreadyOwned');
t.verifyEmpty(g2.Images);
end

function testDetachedImageStopsForwardingEvents(t)
p = oops.model.Project();
cleanup = onCleanup(@() delete(p));
g = p.addGroup('Group');
im = g.addImage(memoryInput());
[state,l] = capture(p,'DataChanged');
listener = onCleanup(@() delete(l));
im.setResults(struct('Order',ones(10,12)));
t.verifyEqual(state('count'),1);
g.removeImage(im);
im.setResults(struct());
t.verifyEqual(state('count'),1);
delete(im);
end

function input = memoryInput()
frames = arrayfun(@(k) uint16(k*ones(10,12)),1:4,'UniformOutput',false);
input = matlabx.image.Image5D.fromComponents(frames);
end

function [state,listener] = capture(source,eventName)
state = containers.Map('KeyType','char','ValueType','any');
state('count') = 0;
listener = addlistener(source,eventName,@(~,e) record(state,e));
end

function record(state,e)
state('count') = state('count') + 1;
state('last') = e;
end
