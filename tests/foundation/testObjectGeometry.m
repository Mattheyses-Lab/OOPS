% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testObjectGeometry
%TESTOBJECTGEOMETRY Verify stored results and object-only crop geometry.
tests = functiontests(localfunctions);
end

function setupOnce(t)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run(BioFormats=false);
logger = oops.Log.get();
logger.PrintToCommandWindow = false;
end

function setup(t)
p = oops.model.Project('Experiment');
g = p.addGroup('Condition');
plane = uint16(reshape(1:120,10,12));
input = matlabx.image.Image5D.fromComponents({plane,plane+100,plane+200,plane+300});
im = g.addImage(input,'Replicate');
t.TestData.Project = p;
t.TestData.Image = im;
t.TestData.Plane = plane;
end

function teardown(t)
delete(t.TestData.Project);
end

function teardownOnce(~)
oops.Log.close();
end

function testScalarResultsAreStoredAndUnavailableInitially(t)
im = t.TestData.Image;
mask = false(10,12); mask(3:4,4:6) = true;
im.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
obj = im.Objects(1);
t.verifyTrue(isnan(obj.Area) && isnan(obj.OrderAvg) && isnan(obj.AzimuthStd));
t.verifyFalse(isprop(obj,'ReferenceAverage'));
obj.setMeasurements(struct('Area',6,'OrderAvg',0.75,'CentroidX',5,'CentroidY',3.5));
t.verifyEqual(obj.Area,6);
t.verifyEqual(obj.OrderAvg,0.75);
t.verifyEqual(obj.CentroidX,5);
t.verifyTrue(isnan(obj.Perimeter));
values = obj.getMeasurements();
t.verifyEqual(values.OrderAvg,0.75);
t.verifyEqual(obj.BoundingBox,[3.5 2.5 3 2]);
t.verifyEqual(obj.Name,"Object 1");
t.verifyEqual(obj.ImageName,"Replicate");
t.verifyEqual(obj.GroupName,"Condition");
end

function testMeasurementUpdatesAreAtomicAndForwarded(t)
im = t.TestData.Image;
mask = false(10,12); mask(3:4,4:6) = true;
im.setMask(mask,{find(mask)});
obj = im.Objects(1);
sink = containers.Map('KeyType','char','ValueType','any');
listener = addlistener(t.TestData.Project,'DataChanged',@(~,e) saveEvent(sink,e));
cleanup = onCleanup(@() delete(listener));
obj.setMeasurements(struct('Area',6,'AzimuthStd',Inf));
t.verifyEqual(sink('event').ObjectID,obj.ID);
t.verifyEqual(sink('event').ImageID,im.ID);
t.verifyEqual(sink('event').Name,"ObjectMeasurements");
t.verifyError(@() obj.setMeasurements(struct('Area',99,'PixelIdxList',1)), ...
    'oops:model:UnknownMeasurement');
t.verifyEqual(obj.Area,6,'Rejected updates must not alter earlier fields.');
obj.Selected = true;
t.verifyEqual(sink('event').Name,"ObjectSelection");
end

function testImageResultReplacementInvalidatesDependentScalars(t)
im = t.TestData.Image;
mask = false(10,12); mask(3:4,4:6) = true;
im.setMask(mask,{find(mask)});
obj = im.Objects(1);
obj.setMeasurements(struct('Area',6,'OrderAvg',0.75,'SBRatio',2,'MidlineLength',3));
im.setResults(struct('Order',zeros(10,12)));
t.verifyTrue(isnan(obj.OrderAvg) && isnan(obj.SBRatio));
t.verifyEqual(obj.Area,6);
t.verifyEqual(obj.MidlineLength,3);
obj.resetMeasurements();
t.verifyTrue(isnan(obj.Area) && isnan(obj.MidlineLength));
end

function testCropExcludesNeighborMembershipButRetainsContext(t)
im = t.TestData.Image;
mask = false(10,12);
mask(4:5,5:6) = true;
mask(4,8) = true; % A second component inside the first object's crop.
im.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
obj = im.Objects(1);
[data,geometry,objectMask,valid] = obj.getCrop(t.TestData.Plane,Margin=2);
t.verifyEqual(geometry.Size,[6 6]);
t.verifyEqual(data,t.TestData.Plane(2:7,3:8));
t.verifyEqual(nnz(objectMask),4);
t.verifyFalse(objectMask(3,6),'The neighboring component must not enter this object mask.');
t.verifyTrue(all(valid(:)));
t.verifyEqual(geometry.toParent(geometry.toLocal([4 5;5 6])),[4 5;5 6]);
end

function testSquareCropAtCornerPreservesSizeAndValidity(t)
im = t.TestData.Image;
mask = false(10,12); mask(1:2,1:3) = true;
im.setMask(mask,{find(mask)});
obj = im.Objects(1);
[data,geometry,objectMask,valid] = obj.getCrop(t.TestData.Plane,Margin=2);
t.verifyEqual(geometry.Size,[7 7]);
t.verifyEqual(geometry.OriginRC,[-1 -1]);
t.verifyEqual(nnz(objectMask),6);
t.verifyEqual(nnz(valid),25);
t.verifyEqual(data(3:7,3:7),t.TestData.Plane(1:5,1:5));
t.verifyEqual(data(~valid),zeros(24,1,'uint16'));
local = geometry.toLocal([1 1;2 3]);
t.verifyEqual(local,[3 3;4 5]);
end

function testMaskAndCropDoNotRequireStoredSubimages(t)
im = t.TestData.Image;
mask = false(10,12); mask(4:5,4:7) = true;
im.setMask(mask,{find(mask)});
obj = im.Objects(1);
[local,geometry] = obj.getMask();
t.verifyEqual(size(local),[2 4]);
t.verifyTrue(all(local(:)));
t.verifyEqual(geometry.BoundsRC,[4 5;4 7]);
t.verifyFalse(isprop(obj,'paddedSubImage'));
t.verifyFalse(isprop(obj,'paddedPixelIdxList'));
end

function testInputCropPreservesPolarizationOrder(t)
im = t.TestData.Image;
mask = false(10,12); mask(3:4,4:6) = true;
im.setMask(mask,{find(mask)});
obj = im.Objects(1);
[input,geometry,objectMask,valid] = obj.getInputCrop(Frames=[4 1],Margin=0,Square=false);
t.verifyEqual(input.NumComponents,2);
t.verifyEqual(input.getPlane(1),t.TestData.Plane(3:4,4:6)+300);
t.verifyEqual(input.getPlane(2),t.TestData.Plane(3:4,4:6));
t.verifyEqual(input.Components(1).Name,"135 deg");
t.verifyEqual(geometry.Size,[2 3]);
t.verifyTrue(all(objectMask(:)) && all(valid(:)));
end

function testTrailingAxesAndFillValues(t)
geometry = oops.geometry.Crop([-1 3;1 4],[10 12]);
stack = cat(3,t.TestData.Plane,t.TestData.Plane+100);
data = geometry.extract(stack);
t.verifyEqual(size(data),[5 4 2]);
t.verifyEqual(data(3:5,:,2),stack(1:3,1:4,2));
t.verifyError(@() geometry.extract(stack,FillValue=NaN),'oops:geometry:InvalidFillValue');
floating = geometry.extract(double(stack),FillValue=NaN);
t.verifyTrue(all(isnan(floating(1:2,:,:)),'all'));
singleData = geometry.extract(single(stack),FillValue=0.1);
t.verifyEqual(singleData(1,1,1),single(0.1));
t.verifyError(@() geometry.extract(ones(3)), 'oops:geometry:DataSizeMismatch');
end

function testDifferentImageDimensionsAndOversizedWindows(t)
geometry = oops.geometry.Crop.aroundBounds([2 3;6 8],[4 8],Margin=10);
t.verifyEqual(geometry.Size,[23 23]);
t.verifyEqual(nnz(geometry.validMask()),32);
t.verifyEqual(size(geometry.extract(ones(4,8))),[23 23]);
end

function saveEvent(sink,e)
sink('event') = e;
end
