% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testNavigationAndRender
%TESTNAVIGATIONANDRENDER Verify independent bookmarks/batch sets and reusable sources.
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
function testBookmarksAndBatchSetsAreIndependent(t)
p = project(); cleaner = onCleanup(@() delete(p));
a = p.Groups(1); b = p.Groups(2);
a.setActiveImage(a.Images(2)); b.setActiveImage(b.Images(1));
a.Images(2).setActiveObject(a.Images(2).Objects(2));
a.Images(1).setActiveObject(a.Images(1).Objects(1));
p.setSelectedGroups(b);
a.setSelectedImages(a.Images(1));
a.Images(2).setSelectedObjects(a.Images(2).Objects(1));
p.setActiveGroup(a);
t.verifyEqual(p.ActiveImage,a.Images(2));
t.verifyEqual(p.ActiveObject,a.Images(2).Objects(2));
t.verifyEqual(p.SelectedGroupIDs,b.ID);
t.verifyEqual(a.SelectedImageIDs,a.Images(1).ID);
p.setActiveGroup(b); p.setActiveGroup(a);
t.verifyEqual(p.ActiveImage,a.Images(2));
t.verifyEqual(p.ActiveObject,a.Images(2).Objects(2));
p.setActiveImage(a.Images(1)); p.setActiveImage(a.Images(2));
t.verifyEqual(p.ActiveObject,a.Images(2).Objects(2));
t.verifyEqual(a.Images(2).SelectedObjectIDs,a.Images(2).Objects(1).ID);
end
function testCanonicalSetsAndSelectionFacade(t)
p = project(); cleaner = onCleanup(@() delete(p));
g = p.Groups(1); image = g.Images(1);
p.setSelectedGroups([p.Groups(2).ID;p.Groups(1).ID;p.Groups(2).ID]);
t.verifyEqual(p.SelectedGroupIDs,oops.model.internal.ids(p.Groups));
image.setSelectedObjects(image.Objects(2));
t.verifyFalse(image.Objects(1).Selected); t.verifyTrue(image.Objects(2).Selected);
image.Objects(1).Selected = true;
t.verifyEqual(image.SelectedObjectIDs,oops.model.internal.ids(image.Objects));
image.Objects(2).Selected = false;
t.verifyEqual(image.SelectedObjectIDs,image.Objects(1).ID);
t.verifyEqual(image.ActiveObjectID,"");
end
function testForeignIDsRejectedWithoutStateChange(t)
p = project(); cleaner = onCleanup(@() delete(p));
a = p.Groups(1); b = p.Groups(2);
a.setActiveImage(a.Images(1)); a.setSelectedImages(a.Images(1));
t.verifyError(@() a.setSelectedImages(b.Images(1).ID),'oops:model:UnknownImage');
t.verifyError(@() a.setActiveImage(b.Images(1)),'oops:model:UnknownImage');
t.verifyEqual(a.ActiveImageID,a.Images(1).ID);
t.verifyEqual(a.SelectedImageIDs,a.Images(1).ID);
end
function testRemovalAndMaskReplacementPruneIDs(t)
p = project(); cleaner = onCleanup(@() delete(p));
g = p.Groups(1); image = g.Images(1);
p.setActiveImage(image); g.setSelectedImages(image);
image.setActiveObject(image.Objects(1)); image.setSelectedObjects(image.Objects);
mask = image.Mask; image.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
t.verifyEqual(image.ActiveObjectID,""); t.verifyEmpty(image.SelectedObjectIDs);
g.removeImage(image);
t.verifyEqual(g.ActiveImageID,""); t.verifyEmpty(g.SelectedImageIDs);
t.verifyEmpty(p.ActiveImage); delete(image);
p.setSelectedGroups(g); p.removeGroup(g);
t.verifyEqual(p.ActiveGroupID,""); t.verifyEmpty(p.SelectedGroupIDs);
delete(g);
end
function testForwardedNavigationCarriesIDs(t)
p = project(); cleaner = onCleanup(@() delete(p));
state = containers.Map('KeyType','char','ValueType','any');
listener = addlistener(p,'NavigationChanged',@(~,e) record(state,e));
listenerCleaner = onCleanup(@() delete(listener));
image = p.Groups(1).Images(1);
image.setSelectedObjects(image.Objects(2));
e = state('last');
t.verifyEqual(e.Domain,"Image"); t.verifyEqual(e.OwnerID,image.ID);
t.verifyEqual(e.Name,"SelectedObjectIDs");
t.verifyEmpty(e.OldIDs); t.verifyEqual(e.NewIDs,image.Objects(2).ID);
end
function testRenderInputCorrectedAndMissingOutputs(t)
p = project(); cleaner = onCleanup(@() delete(p));
image = p.Groups(1).Images(1); s = p.Settings;
[data,info] = oops.render.source(image,"Input",s);
t.verifyEqual(data,image.Input); t.verifyTrue(info.Available);
[data,info] = oops.render.source(image,"Corrected",s);
t.verifyTrue(info.Available); t.verifyEqual(data.NumComponents,4);
stack = oops.analysis.readStack(image.Input);
t.verifyEqual(data.getPlane(4,1,1),stack(:,:,4));
[data,info] = oops.render.source(image,"Order",s);
t.verifyEmpty(data); t.verifyFalse(info.Available);
t.verifyEmpty(image.Order,'Rendering must not run FPM analysis.');
end
function testRenderNumericalOutputs(t)
p = project(); cleaner = onCleanup(@() delete(p));
image = p.Groups(1).Images(1);
avg = reshape(1:120,10,12); azimuth = -pi/4*ones(10,12);
image.setResults(struct('AverageIntensity',avg,'Order',.7*ones(10,12),'Azimuth',azimuth));
[data,info] = oops.render.source(image,"Azimuth",p.Settings);
t.verifyEqual(data.getPlane(1,1,1),mod(rad2deg(azimuth),180)); t.verifyEqual(info.CLim,[0 180]);
t.verifyEqual(image.Results.Azimuth,azimuth);
[data,info] = oops.render.source(image,"Mask",p.Settings);
t.verifyEqual(data.getPlane(1,1,1),image.Mask); t.verifyEqual(info.CLim,[0 1]);
t.verifyError(@() oops.render.source(image,"Unknown",p.Settings),'oops:render:UnknownSource');
end
function p = project()
p = oops.model.Project();
for k = 1:2
    g = p.addGroup("Group "+k);
    for i = 1:2
        input = matlabx.image.Image5D.fromComponents({ones(10,12),2*ones(10,12),3*ones(10,12),4*ones(10,12)});
        image = g.addImage(input,"Image "+i);
        mask = false(10,12); mask(2:3,2:3) = true; mask(7:8,8:9) = true;
        image.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
    end
end
end
function record(state,e)
state('last') = e;
end
