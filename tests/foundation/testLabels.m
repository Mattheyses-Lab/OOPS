% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testLabels
%TESTLABELS Verify project label identity, lookup, and batched assignment.

    tests = functiontests(localfunctions);
end

function setupOnce(t)
%SETUPONCE Configure the package path and quiet logger for this suite.

    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
    oops.setup.run(BioFormats=false);
    logger = oops.Log.get();
    logger.PrintToCommandWindow = false;
end

function teardownOnce(~)
%TEARDOWNONCE Close the shared logger after all label tests finish.

    oops.Log.close();
end

function testDefaultRegistrySupportsStableLookups(t)
%TESTDEFAULTREGISTRYSUPPORTSSTABLELOOKUPS Resolve the default and added labels.

    registry = oops.model.LabelRegistry.default();
    cleanup = onCleanup(@() delete(registry)); %#ok<NASGU>

    t.verifyEqual(registry.ids(),"unlabeled");
    registry.add("Object",ID="object",Hotkey="1",Color=[0.2 0.8 0.2]);
    t.verifyEqual(registry.getByHotkey("1").ID,"object");
    t.verifyEqual(registry.active().ID,"unlabeled");
    t.verifyError(@() registry.add("Duplicate",Hotkey="1"), ...
        'oops:model:DuplicateLabelHotkey');
end

function testImageAppliesOneLabelToSelectedObjectBatch(t)
%TESTIMAGEAPPLIESONELABELTOSELECTEDOBJECTBATCH Preserve unselected labels.

    project = oops.model.Project("Labels");
    cleanup = onCleanup(@() delete(project)); %#ok<NASGU>
    project.addLabel("Object",ID="object",Hotkey="1",Color=[0.2 0.8 0.2]);
    group = project.addGroup("Group");
    plane = zeros(10,12);
    input = matlabx.image.Image5D.fromComponents({plane,plane,plane,plane});
    image = group.addImage(input,"Image");
    mask = false(10,12);
    mask(2:3,2:3) = true;
    mask(7:8,8:9) = true;
    image.setMask(mask,oops.analysis.segment.objectsFromMask(mask));

    image.setSelectedObjects(image.Objects(2));
    image.setObjectLabels(image.SelectedObjectIDs,"object");

    t.verifyEqual(image.Objects(1).LabelID,"unlabeled");
    t.verifyEqual(image.Objects(2).LabelID,"object");
    t.verifyEqual(image.Objects(2).Label.Name,"Object");
    t.verifyEqual(image.Objects(2).SummaryTable{'Label','Values'},{'Object'});
end
