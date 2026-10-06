% Object-Oriented Polarization Software (OOPS)
% Copyright (C) 2026 William Dean
% SPDX-License-Identifier: GPL-3.0-or-later

function tests = testGUI
%TESTGUI Runtime controller checks with real MATLAB controls; no interaction dialogs.
tests = functiontests(localfunctions);
end
function setupOnce(t)
root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
t.applyFixture(matlab.unittest.fixtures.PathFixture(root));
oops.setup.run();
end
function setup(t)
oops.Log.close(); logger = oops.Log.get(); logger.PrintToCommandWindow = false;
p = oops.model.Project();
for k = 1:2
    g = p.addGroup("Group "+k);
    for j = 1:3
        input = matlabx.image.Image5D.fromComponents({rand(20,30),rand(20,30),rand(20,30),rand(20,30)});
        image = g.addImage(input,"Image "+j);
        mask = false(20,30); mask(2:4,2:4)=true; mask(10:13,18:20)=true;
        image.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
    end
end
t.TestData.Project = p;
t.TestData.GUI = oops.app.GUI(Project=p,Visible='off',WriteLogFile=false);
end
function teardown(t)
delete(t.TestData.GUI); delete(t.TestData.Project); oops.Log.close();
end
function testTreesControlIndependentState(t)
ui = t.TestData.GUI; p = ui.Project; g = p.Groups(1);
t.verifyEqual(ui.ImagesTree.SelectedNodes.NodeData,g.Images(1).ID);
ui.ImagesTree.CheckedNodes = ui.ImagesTree.Children([2 3]);
ui.ImagesTree.CheckedNodesChangedFcn(ui.ImagesTree,[]);
t.verifyEqual(g.SelectedImageIDs,[g.Images(2).ID;g.Images(3).ID]);
t.verifyEqual(g.ActiveImageID,g.Images(1).ID);
ui.ImagesTree.SelectedNodes = ui.ImagesTree.Children(3);
ui.ImagesTree.SelectionChangedFcn(ui.ImagesTree,[]);
t.verifyEqual(g.ActiveImageID,g.Images(3).ID);
t.verifyEqual(numel(ui.ImagesTree.CheckedNodes),2);
p.Groups(2).setActiveImage(p.Groups(2).Images(2));
p.setActiveGroup(p.Groups(2)); p.setActiveGroup(g);
t.verifyEqual(ui.ImagesTree.SelectedNodes.NodeData,g.Images(3).ID);
t.verifyEqual(numel(ui.ImagesTree.CheckedNodes),2);
end

function testGroupSwatchesAndBulkTreeSelection(t)
%TESTGROUPSWATCHESANDBULKTREESELECTION Reflect colors and batch commands.

ui = t.TestData.GUI;
p = ui.Project;
icon = string(ui.GroupsTree.Children(1).Icon);
t.verifyTrue(isfile(icon));
t.verifyTrue(startsWith(icon,string(fullfile(prefdir,'matlabx','cache','icons'))));

menu = ui.ImagesTree.ContextMenu;
selectAll = menu.Children(strcmp(string({menu.Children.Text}),"Select all"));
invert = menu.Children(strcmp(string({menu.Children.Text}),"Invert selection"));
clear = menu.Children(strcmp(string({menu.Children.Text}),"Clear selection"));
selectAll.MenuSelectedFcn(selectAll,[]);
t.verifyEqual(p.ActiveGroup.SelectedImageIDs,oops.model.internal.ids(p.ActiveGroup.Images));
invert.MenuSelectedFcn(invert,[]);
t.verifyEmpty(p.ActiveGroup.SelectedImageIDs);
selectAll.MenuSelectedFcn(selectAll,[]);
clear.MenuSelectedFcn(clear,[]);
t.verifyEmpty(p.ActiveGroup.SelectedImageIDs);
end
function testSummaryTracksActiveObjectWithoutViewerRedraw(t)
%TESTSUMMARYTRACKSACTIVEOBJECTWITHOUTVIEWERREDRAW Keep summary updates independent.
ui = t.TestData.GUI;
t.verifyEqual(ui.SummaryDomain.Items,{'Project','Image','Group','Object'});
t.verifyEqual(ui.SummaryTable.Data{'Total images','Values'},{'6'});
ui.SummaryDomain.Value = 'Object';
ui.SummaryDomain.ValueChangedFcn(ui.SummaryDomain,[]);
im = ui.Project.ActiveImage;
region = im.ActiveObject;
leftData = ui.LeftViewer.ImageData;

profile clear; profile on;
cleanupProfile = onCleanup(@() profile('off'));
region.setMeasurements(struct('OrderAvg',.75));
profile off;
info = profile('info');
names = string({info.FunctionTable.FunctionName});
t.verifyFalse(any(contains(names,'refreshViewers')));
t.verifyEqual(ui.SummaryTable.Data{'Mean order','Values'},{'0.75'});
t.verifyEqual(ui.LeftViewer.ImageData,leftData);

im.setActiveObject(im.Objects(2));
t.verifyEqual(ui.SummaryTable.Data{'Name','Values'},{'Object 2'});
im.removeObjects(im.Objects);
t.verifyEmpty(ui.SummaryTable.Data);
end

function testSettingsDriveSameViewersAndLog(t)
ui = t.TestData.GUI; p = ui.Project;
left = ui.LeftViewer; right = ui.RightViewer;
control = ui.SettingsUI.View.LeftSource;
control.Value = 'Mask'; control.ValueChangedFcn(control,[]);
t.verifyEqual(p.Settings.View.LeftSource,"Mask");
t.verifyEqual(ui.LeftViewer,left); t.verifyEqual(ui.RightViewer,right);
t.verifyEqual(left.ImageData.getPlane(1,1,1),p.ActiveImage.Mask);
p.Settings.ObjectDisplay.CropMargin = 8;
t.verifyFalse(isfield(ui.SettingsUI,"ObjectDisplay"));
p.Settings.View.LeftSource = "Input";
left.C = 3;
p.ActiveGroup.setSelectedImages(p.ActiveGroup.Images(2));
t.verifyEqual(left.C,3,'Batch selection must preserve the viewer frame.');
oops.Log.INFO("UI sink verification"); oops.Log.flush();
t.verifyTrue(any(contains(string(ui.LogTextArea.Value),"UI sink verification")));
end

function testLabelHotkeyAppliesToCheckedObjects(t)
%TESTLABELHOTKEYAPPLIESTOCHECKEDOBJECTS Route label commands through model IDs.

ui = t.TestData.GUI;
image = ui.Project.ActiveImage;
ui.Project.addLabel("Object",ID="object",Hotkey="1",Color=[0.2 0.8 0.2]);
image.setSelectedObjects(image.Objects(2));

callback = ui.CommandRouter.HotkeyFcnDict("1");
callback(ui.CommandRouter,"1");

t.verifyEqual(image.Objects(1).LabelID,"unlabeled");
t.verifyEqual(image.Objects(2).LabelID,"object");
t.verifyEqual(ui.Project.Labels.ActiveLabelID,"object");
t.verifyEqual(string(ui.LabelsTree.SelectedNodes.NodeData),"object");

ui.SettingsUI.ObjectSelection.ColorMode.Value = 'Label';
ui.SettingsUI.ObjectSelection.ColorMode.ValueChangedFcn( ...
    ui.SettingsUI.ObjectSelection.ColorMode,[]);
overlay = ui.LeftViewer.Overlays.get(image.Objects(2).ID);
t.verifyEqual(overlay.EdgeColor,[0.2 0.8 0.2]);
end
function testImportContinuesPastInvalidFourAngleFile(t)
ui = t.TestData.GUI;
folder = tempname; mkdir(folder); cleaner = onCleanup(@() rmdir(folder,'s'));
valid = fullfile(folder,'valid.tif'); invalid = fullfile(folder,'invalid.tif');
for k = 1:4
    if k == 1, imwrite(uint16(k*ones(12,16)),valid);
    else, imwrite(uint16(k*ones(12,16)),valid,'WriteMode','append'); end
end
imwrite(uint16(ones(12,16)),invalid);
group = ui.Project.ActiveGroup; count = numel(group.Images);
imported = ui.addFiles([string(invalid),string(valid)]);
t.verifyEqual(numel(imported),1); t.verifyEqual(numel(group.Images),count+1);
t.verifyEqual(ui.Project.ActiveImage,imported(1));
t.verifyTrue(imported(1).IsLoaded);
t.verifyEqual(imported(1).getFrame(4),uint16(4*ones(12,16)));
t.verifyEqual(ui.LeftViewer.ImageData,imported(1).Input);
end
function testInvalidSettingRestoresBoundControlAndLogs(t)
ui = t.TestData.GUI;
control = ui.SettingsUI.Segmentation.MinimumArea; old = control.Value;
control.Value = -3; control.ValueChangedFcn(control,[]);
t.verifyEqual(control.Value,old);
t.verifyEqual(ui.Project.Settings.Segmentation.MinimumArea,old);
log = oops.Log.asTable();
t.verifyTrue(any(log.level == "ERROR"));
end
function testDropdownsAndHiddenDeveloperSettings(t)
ui = t.TestData.GUI;
t.verifyClass(ui.SettingsUI.Segmentation.Strategy,'matlab.ui.control.DropDown');
t.verifyClass(ui.SettingsUI.Segmentation.Connectivity,'matlab.ui.control.DropDown');
t.verifyEqual(ui.SettingsUI.Segmentation.Connectivity.ItemsData,[4 8]);
t.verifyEqual(ui.Project.Settings.Segmentation.Connectivity,4);
t.verifyClass(ui.SettingsUI.View.LeftSource,'matlab.ui.control.DropDown');
sources = oops.config.View.sources();
t.verifyEqual(string(ui.SettingsUI.View.LeftSource.Items), ...
    sources(sources ~= "Objects"));
t.verifyEqual(string(ui.SettingsUI.View.RightSource.Items), ...
    sources);
t.verifyTrue(ui.SettingsAccordion.hasItem("Scatterplot"));
t.verifyTrue(ui.SettingsAccordion.hasItem("Swarmplot"));
t.verifyFalse(isprop(ui.Project.Settings,'Analysis'));
t.verifyFalse(ui.SettingsAccordion.hasItem("Analysis"));
t.verifyFalse(ui.SettingsAccordion.hasItem("Object Display"));
t.verifyFalse(ui.SettingsAccordion.hasItem("Local Background"));
end
function testContextDeletionTargetsClickedNode(t)
ui = t.TestData.GUI; p = ui.Project;
active = p.ActiveGroup; target = p.Groups(2);
node = ui.GroupsTree.Children(2);
menus = node.ContextMenu.Children;
item = menus(strcmp(string({menus.Text}),"Delete group"));
item.MenuSelectedFcn(item,[]);
t.verifyEqual(p.ActiveGroup,active); t.verifyEqual(numel(p.Groups),1);
t.verifyFalse(isvalid(target));
activeImage = p.ActiveImage; targetImage = active.Images(3);
node = ui.ImagesTree.Children(3); menus = node.ContextMenu.Children;
item = menus(strcmp(string({menus.Text}),"Delete image")); item.MenuSelectedFcn(item,[]);
t.verifyEqual(p.ActiveImage,activeImage); t.verifyFalse(isvalid(targetImage));
end
function testColormapDomainTree(t)
ui = t.TestData.GUI; settings = ui.Project.Settings.Colormaps;
ui.ColormapDomain.Value = 'Order'; ui.ColormapDomain.ValueChangedFcn(ui.ColormapDomain,[]);
nodes = findall(ui.ColormapTree,'Type','uitreenode'); chosen = [];
for k = 1:numel(nodes)
    data = nodes(k).NodeData;
    if isstruct(data) && data.Category == "MATLAB" && data.Name == "hot", chosen = nodes(k); break; end
end
t.assertNotEmpty(chosen);
ui.ColormapTree.SelectedNodes = chosen;
ui.ColormapTree.SelectionChangedFcn(ui.ColormapTree,[]);
t.verifyEqual(settings.Order,"hot"); t.verifyEqual(settings.Intensity,"gray");
t.verifyEqual(settings.Azimuth,"hsv");
end
function testCalibrationAssignmentAutomaticallyCorrects(t)
ui = t.TestData.GUI; p = ui.Project; g = p.Groups(1);
cal = p.addCalibration(matlabx.image.Image5D.fromComponents( ...
    {ones(20,30),2*ones(20,30),3*ones(20,30),4*ones(20,30)}));
g.setCalibrations(cal.ID);
corrected = oops.analysis.Analyzer.correctedStack(g.Images(1));
t.verifyEqual(corrected(:,:,1),double(g.Images(1).getFrame(1))*4);
t.verifyEmpty(g.Images(1).Mask); t.verifyEmpty(ui.ObjectsTree.Children);
t.verifyFalse(oops.model.internal.hasCurrentCorrection(p.Groups(2).Images(1)));
end
function testGroupContextMenuExposesCalibrationWorkflow(t)
ui = t.TestData.GUI;
node = ui.GroupsTree.Children(1);
menus = node.ContextMenu.Children;
calibration = menus(strcmp(string({menus.Text}),"Calibration"));
t.assertNotEmpty(calibration);
t.verifyEqual(sort(string({calibration.Children.Text})), ...
    sort(["View assignment..." "Assign registered calibrations..." ...
    "Import and assign..." "Clear assignment"]));
end
function testCalibrationFilesApplyOnlyToCheckedGroupsAndAreReused(t)
ui = t.TestData.GUI; p = ui.Project;
folder = tempname; mkdir(folder); cleaner = onCleanup(@() rmdir(folder,'s'));
file = fullfile(folder,'calibration.tif');
for k = 1:4
    if k == 1, imwrite(uint16(k*ones(20,30)),file);
    else, imwrite(uint16(k*ones(20,30)),file,'WriteMode','append'); end
end
p.setSelectedGroups(p.Groups(1)); registered = ui.loadCalibrations(string(file));
t.verifyEqual(p.Groups(1).CalibrationIDs,registered.ID);
t.verifyEmpty(p.Groups(2).CalibrationIDs); t.verifyFalse(oops.model.internal.hasCurrentCorrection(p.Groups(2).Images(1)));
p.setSelectedGroups(p.Groups(2)); reused = ui.loadCalibrations(string(file));
t.verifyEqual(reused.ID,registered.ID); t.verifyEqual(numel(p.Calibrations),1);
t.verifyEqual(p.Groups(2).CalibrationIDs,p.Groups(1).CalibrationIDs);
t.verifyTrue(oops.model.internal.hasCurrentCorrection(p.Groups(2).Images(1)));
end
function testProcessingMenusRunWithoutCalibration(t)
ui = t.TestData.GUI; ui.Fig.Visible = 'on'; drawnow;
menus = findall(ui.Fig,'Type','uimenu');
segment = menus(strcmp(string({menus.Text}),"Segment selected / active images"));
fpm = menus(strcmp(string({menus.Text}),"Order/orientation for selected / active images"));
segment.MenuSelectedFcn(segment,[]); fpm.MenuSelectedFcn(fpm,[]);
t.verifyEqual(size(ui.Project.ActiveImage.Mask),[20 30]);
t.verifyEqual(size(ui.Project.ActiveImage.Order),[20 30]);
t.verifyEqual(size(ui.Project.ActiveImage.Azimuth),[20 30]);
logs = oops.Log.asTable(); t.verifyFalse(any(logs.level == "ERROR"));
end
function testSquarePanelInteriorsAfterResize(t)
ui = t.TestData.GUI;
for width = [1400 1600 1200]
    ui.Fig.Position(3) = width;
    drawnow;
    ui.Fig.SizeChangedFcn(ui.Fig,[]); drawnow;
    chrome = matlabx.UICal.uipanelTopChromeHeightPx(12);
    % R2026b's web layout is asynchronous. Wait for the requested allocation,
    % not merely an old square panel left over from the previous figure width.
    expectedWidth = (width-10-300-5-5)/2-2*ui.ViewerPanels(1).BorderWidth;
    started = tic;
    while toc(started) < 3
        drawnow;
        a = ui.ViewerPanels(1).InnerPosition; b = ui.ViewerPanels(2).InnerPosition;
        if abs(a(3)-expectedWidth) <= 1 && abs(b(3)-expectedWidth) <= 1 && ...
                abs(a(4)-a(3)-chrome) <= 2 && abs(b(4)-b(3)-chrome) <= 2
            break;
        end
        pause(.02);
    end
    t.verifyEqual(a(3),expectedWidth,'AbsTol',1);
    t.verifyEqual(a(3),b(3),'AbsTol',1);
    t.verifyEqual(a(4)-a(3),chrome,'AbsTol',2);
    t.verifyEqual(b(4)-b(3),chrome,'AbsTol',2);
end
end
function testMainFigureHelpersAndSingleInstance(t)
ui = t.TestData.GUI;
t.verifyTrue(oops.app.hasMainFigure()); t.verifyEqual(oops.app.getMainFigure(),ui.Fig);
again = oops.launch();
t.verifyEqual(again,ui);
t.verifyEqual(numel(findall(groot,'Type','figure','Tag',oops.Info.MainFigureTag)),1);
delete(ui);
t.verifyFalse(oops.app.hasMainFigure()); t.verifyEmpty(oops.app.getMainFigure());
t.verifyFalse(oops.Log.get().EnableUISink);
t.verifyTrue(isvalid(t.TestData.Project),'An externally supplied project must survive UI closure.');
end

function testMaskControlChronologyAndVisibility(t)
ui = t.TestData.GUI; controls = ui.SettingsUI.Segmentation;
slider = ui.SegmentationUI.Puncta.Threshold;
t.verifyEqual(slider.ValueMode,"scalar"); t.verifyEqual(string(slider.Visible),"on");
t.verifyLessThan(controls.Strategy.Layout.Row,slider.Layout.Row);
t.verifyLessThan(slider.Layout.Row,controls.MinimumArea.Layout.Row);
t.verifyLessThan(controls.MinimumArea.Layout.Row,controls.MaxObjects.Layout.Row);
pane = ui.SettingsAccordion.getItem("Mask").Pane;
labels = findall(pane,'Type','uilabel'); t.verifyTrue(any(string({labels.Text}) == "Object filtering"));
ui.Project.Settings.Segmentation.Strategy = "Filaments";
t.verifyEqual(string(slider.Visible),"off"); t.verifyEqual(pane.RowHeight{slider.Layout.Row},0);
end
function testImageLocalThresholdPreviewAndCommit(t)
ui = t.TestData.GUI; p = ui.Project; image = p.ActiveImage;
p.Settings.Segmentation.BorderWidth = 0; p.Settings.Segmentation.MinimumArea = 1;
oops.analysis.Analyzer.segmentImages(image,p.Settings);
p.Settings.View.RightSource = "Mask";
slider = ui.SegmentationUI.Puncta.Threshold;
oldIDs = oops.model.internal.ids(image.Objects); oldMask = image.Mask;
slider.Value = .9; slider.ValueChangingFcn(slider,[]);
t.verifyEqual(image.Mask,oldMask); t.verifyEqual(oops.model.internal.ids(image.Objects),oldIDs);
input = ui.LeftViewer.ImageData; ui.LeftViewer.C = 3;
profile clear; profile on;
profileCleanup = onCleanup(@() profile('off'));
slider.ValueChangedFcn(slider,[]);
profile off; stats = profile('info');
names = string({stats.FunctionTable.FunctionName});
for method = ["GUI>GUI.refreshNavigation","GUI>GUI.refreshViewers"]
    entry = stats.FunctionTable(names == method);
    t.verifyEqual(numel(entry),1);
    if ~isempty(entry), t.verifyEqual(entry.NumCalls,1); end
end
t.verifyFalse(any(names == "readStack"));
t.verifyEqual(ui.LeftViewer.ImageData,input); t.verifyEqual(ui.LeftViewer.C,3);
t.verifyEqual(image.SegmentationParameters.Mode,"Manual");
t.verifyEqual(image.SegmentationParameters.Values.Threshold,.9);
t.verifyEqual(ui.RightViewer.ImageData.getPlane(1,1,1),image.Mask);
reset = ui.SegmentationUI.Reset; reset.ButtonPushedFcn(reset,[]);
t.verifyEqual(image.SegmentationParameters.Mode,"Automatic");
end
function testIndependentDisplayLimitPolicies(t)
ui = t.TestData.GUI; p = ui.Project; image = p.ActiveImage;
p.Settings.View.LeftSource = "Average intensity";
p.Settings.View.RightSource = "Input";
slider = ui.DisplayLimitUI.Intensity; slider.Value = [.2 .8];
slider.ValueChangingFcn(slider,[]);
t.verifyEmpty(image.IntensityDisplayRange); t.verifyTrue(p.Settings.Display.AutoScaleDisplayIntensity);
slider.ValueChangedFcn(slider,[]);
t.verifyEqual(image.IntensityDisplayRange,[.2 .8]);
t.verifyFalse(p.Settings.Display.AutoScaleDisplayIntensity); t.verifyTrue(p.Settings.Display.AutoScaleDisplayOrder);
t.verifyEqual(ui.LeftViewer.CLim,[.2 .8]); t.verifyEqual(ui.RightViewer.CLim,[.2 .8]);
ui.LeftViewer.C = 3; t.verifyEqual(ui.LeftViewer.CLim,[.2 .8]);
p.Settings.Display.AutoScaleDisplayIntensity = true;
t.verifyEqual(image.IntensityDisplayRange,[.2 .8]);
end


function testPlotPresetAndSingletonSourceMovement(t)
%TESTPLOTPRESETANDSINGLETONSOURCEMOVEMENT Reuse one component per plot source.

ui = t.TestData.GUI;
p = ui.Project;

% Supply finite stored measurements so both copied components receive real data.
for group = p.Groups'
    for image = group.Images'
        for k = 1:numel(image.Objects)
            image.Objects(k).setMeasurements(struct( ...
                'SBRatio',double(k),'OrderAvg',double(k)/numel(image.Objects)));
        end
    end
end

viewMenu = findall(ui.Fig,'Type','uimenu','Text','View');
plots = findall(viewMenu,'Type','uimenu','Text','Plots');
plots.MenuSelectedFcn(plots,[]);

t.verifyEqual(p.Settings.View.LeftSource,"Scatterplot");
t.verifyEqual(p.Settings.View.RightSource,"Swarmplot");
t.verifyEqual(ui.LeftPlotAxes.Visible,matlab.lang.OnOffSwitchState.on);
t.verifyEqual(ui.RightPlotAxes.Visible,matlab.lang.OnOffSwitchState.on);
t.verifyEqual(ui.LeftPlotAxes.Content,ui.ScatterRenderer);
t.verifyEqual(ui.RightPlotAxes.Content,ui.SwarmRenderer);
t.verifyEqual(numel(ui.ScatterRenderer.Data.XData),numel(p.Groups));
t.verifyEqual(numel(ui.SwarmRenderer.Data.Values),numel(p.Groups));

markerSize = ui.SettingsUI.ScatterPlot.MarkerSize;
markerSize.Value = 31;
markerSize.ValueChangedFcn(markerSize,[]);
t.verifyEqual(p.Settings.ScatterPlot.MarkerSize,31);

% Moving a source transfers its renderer while both panel hosts stay fixed.
scatter = ui.ScatterRenderer;
leftHost = ui.LeftPlotAxes;
rightHost = ui.RightPlotAxes;
p.Settings.View.RightSource = "Scatterplot";
t.verifyEqual(p.Settings.View.LeftSource,"Empty");
t.verifyEqual(string(ui.SettingsUI.View.LeftSource.Value),"Empty");
t.verifyEqual(ui.ScatterRenderer,scatter);
t.verifyEmpty(ui.LeftPlotAxes.Content);
t.verifyEqual(ui.RightPlotAxes.Content,scatter);
t.verifyEqual(scatter.Host,rightHost);
t.verifyEqual(ui.LeftPlotAxes,leftHost);
t.verifyEqual(ui.RightPlotAxes,rightHost);
t.verifyEqual(ui.RightPlotAxes.Axes.XTickMode,'auto');
t.verifyEqual(ui.RightPlotAxes.Axes.XTickLabelMode,'auto');
t.verifyNotEqual(string(ui.RightPlotAxes.Axes.XTickLabel), ...
    ui.SwarmRenderer.Data.SeriesNames);

% Detached MATLABX content removes its primitives from the former host axes.
meanMarkers = findobj(ui.RightPlotAxes.Axes, ...
    'Type','line','Tag','ViolinCentralStatistic');
t.verifyEmpty(meanMarkers);

% Transfer the same primitive-backed renderer to its original host again.
p.Settings.View.LeftSource = "Scatterplot";
t.verifyEqual(p.Settings.View.RightSource,"Empty");
t.verifyEqual(ui.LeftPlotAxes.Content,scatter);
t.verifyEmpty(ui.RightPlotAxes.Content);
t.verifyEqual(scatter.Host,leftHost);
t.verifyNotEmpty(ui.LeftPlotAxes.Axes.Children);
end

function testLaunchHonorsSetupGenerationAndRestoresSessionPaths(t)
t.TestData.SetupHadPreference = oops.Preferences.has("SetupVersion");
t.TestData.SetupPrevious = oops.Preferences.get("SetupVersion","0.0.0");
preferenceCleanup = onCleanup(@() restoreSetupPreference(t.TestData));
delete(t.TestData.GUI);
oops.Preferences.set("SetupVersion","0.3.0");
t.TestData.GUI = oops.launch(Visible='off');
t.verifyEqual(oops.Preferences.get("SetupVersion"),oops.Info.RequiredSetupVersion);
delete(t.TestData.GUI);
% An already newer setup generation must not be downgraded just to launch.
oops.Preferences.set("SetupVersion","9.0.0");
rmpath(oops.Paths.external('matlabx'));
t.TestData.GUI = oops.launch(Visible='off');
t.verifyEqual(oops.Preferences.get("SetupVersion"),"9.0.0");
t.verifyTrue(contains(path,oops.Paths.external('matlabx')));
t.verifyTrue(oops.app.hasMainFigure());
end
function restoreSetupPreference(data)
if data.SetupHadPreference, oops.Preferences.set("SetupVersion",data.SetupPrevious);
else, oops.Preferences.remove("SetupVersion"); end
end

function testMasksAndPolygonsFollowCommittedMembership(t)
%TESTMASKSANDPOLYGONSFOLLOWCOMMITTEDMEMBERSHIP Keep geometry and mask in both viewers.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
ui.Project.Settings.View.RightSource = "Average intensity";
ids = oops.model.internal.ids(image.Objects);
for viewer = {ui.LeftViewer,ui.RightViewer}
    axes = viewer{1};
    t.verifyEqual(axes.Mask,image.Mask);
    actual = axes.Overlays.ids(Type="Polygon");
    t.verifyEqual(sort(actual(:)),sort(ids));
end
survivor = ui.LeftViewer.Overlays.get(ids(2));
image.removeObjects(ids(1));
t.verifyFalse(ui.LeftViewer.Overlays.has(ids(1)));
t.verifyFalse(ui.RightViewer.Overlays.has(ids(1)));
t.verifyEqual(ui.LeftViewer.Overlays.get(ids(2)),survivor);
t.verifyEqual(ui.LeftViewer.Mask,image.Mask);
t.verifyEqual(ui.RightViewer.Mask,image.Mask);
end

function testPolygonActivationAndSelectionStayIndependent(t)
%TESTPOLYGONACTIVATIONANDSELECTIONSTAYINDEPENDENT Sync viewer edits and checkbox edits.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
ui.Project.Settings.View.RightSource = "Average intensity";
ids = oops.model.internal.ids(image.Objects);
ui.LeftViewer.Tools.Polygon.setActivePolygonID(ids(2));
ui.LeftViewer.Tools.Polygon.setSelectedPolygonIDs(ids(1));
t.verifyEqual(image.ActiveObjectID,ids(2));
t.verifyEqual(image.SelectedObjectIDs,ids(1));
t.verifyEqual(ui.ObjectsTree.SelectedNodes.NodeData,ids(2));
t.verifyEqual(ui.ObjectsTree.CheckedNodes.NodeData,ids(1));
t.verifyEqual(ui.RightViewer.Overlays.getActiveID(Type="Polygon"),ids(2));
selected = ui.RightViewer.Tools.Polygon.getSelectedPolygonIDs();
t.verifyEqual(selected(:),ids(1));
ui.ObjectsTree.CheckedNodes = ui.ObjectsTree.Children(2);
ui.ObjectsTree.CheckedNodesChangedFcn(ui.ObjectsTree,[]);
t.verifyEqual(image.SelectedObjectIDs,ids(2));
selected = ui.LeftViewer.Tools.Polygon.getSelectedPolygonIDs();
t.verifyEqual(selected(:),ids(2));
t.verifyEqual(image.ActiveObjectID,ids(2));
end

function testPolygonDeletionRemovesModelObjectAndMaskPixels(t)
%TESTPOLYGONDELETIONREMOVESMODELOBJECTANDMASKPIXELS Commit app-owned tool deletion.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
ui.Project.Settings.View.RightSource = "Mask";
removed = image.Objects(1); id = removed.ID; pixels = removed.PixelIdxList;
survivor = image.Objects(2); mask = image.Mask; mask(pixels) = false;
image.setActiveObject(removed); image.setSelectedObjects(image.Objects);
ui.LeftViewer.Tools.Polygon.removePolygon(id);
t.verifyFalse(isvalid(removed));
t.verifyEqual(image.Objects,survivor);
t.verifyEqual(image.Mask,mask);
t.verifyEqual(image.SelectedObjectIDs,survivor.ID);
t.verifyEqual(ui.RightViewer.ImageData.getPlane(1,1,1),mask);
t.verifyFalse(ui.LeftViewer.Overlays.has(id));
t.verifyFalse(ui.RightViewer.Overlays.has(id));
t.verifyEqual(numel(ui.ObjectsTree.Children),1);
end

function testPixelEdgePolygonsPreserveExteriorPixels(t)
%TESTPIXELEDGEPOLYGONSPRESERVEEXTERIORPIXELS Enclose hole-free four-connected objects.
warningID = 'MATLAB:polyshape:repairedBySimplify';
previous = warning('query',warningID);
warning('error',warningID);
warningCleanup = onCleanup(@() warning(previous.state,warningID));

ui = t.TestData.GUI;
image = ui.Project.ActiveImage;

mask = false(20,30);
mask(1:5,1:5) = true;
mask(10,10) = true;
mask(11,11) = true;
mask(6:8,14:16) = logical([1 1 0; 1 0 0; 1 1 1]);
image.setMask(mask,oops.analysis.segment.objectsFromMask(mask,4));
[x,y] = meshgrid(1:30,1:20);
for region = image.Objects'
    vertices = oops.geometry.objectBoundary(region); shape = polyshape(vertices);
    expected = false(20,30); expected(region.PixelIdxList) = true;
    t.verifyEqual(reshape(isinterior(shape,x(:),y(:)),size(mask)),expected);
    t.verifyEqual(area(shape),numel(region.PixelIdxList),'AbsTol',1e-10);
    coordinates = vertices(isfinite(vertices));
    t.verifyEqual(mod(coordinates,1),repmat(.5,size(coordinates)));
end
end

function testBatchDeletionRetainsSurvivingNodesAndPolygons(t)
%TESTBATCHDELETIONRETAINSSURVIVINGNODESANDPOLYGONS One request keeps unrelated UI intact.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
ui.Project.Settings.View.RightSource = "Mask";
mask = false(20,30);
mask(2:3,2:3) = true; mask(2:3,8:9) = true; mask(2:3,14:15) = true;
image.setMask(mask,oops.analysis.segment.objectsFromMask(mask));
ids = oops.model.internal.ids(image.Objects);
removed = image.Objects(1:2); survivor = image.Objects(3);
node = ui.ObjectsTree.Children(3); menu = node.ContextMenu;
left = ui.LeftViewer.Overlays.get(ids(3)); right = ui.RightViewer.Overlays.get(ids(3));
image.setActiveObject(survivor); image.setSelectedObjects(removed);
image.setDisplayRange("Intensity",[.1 .9]);
[events,listener] = observeObjectChanges(image);
cleanup = onCleanup(@() delete(listener));
ui.LeftViewer.Tools.Polygon.deleteSelectedPolygons();
t.verifyEqual(events(),1,'Batch deletion must emit one collection change.');
t.verifyFalse(any(isvalid(removed)));
t.verifyEqual(image.Objects,survivor);
t.verifyEqual(image.ActiveObjectID,ids(3));
t.verifyEmpty(image.SelectedObjectIDs);
t.verifyEqual(ui.ObjectsTree.Children,node);
t.verifyEqual(node.ContextMenu,menu);
t.verifyEqual(ui.LeftViewer.Overlays.get(ids(3)),left);
t.verifyEqual(ui.RightViewer.Overlays.get(ids(3)),right);
t.verifyEqual(ui.LeftViewer.Mask,image.Mask);
t.verifyEqual(ui.RightViewer.ImageData.getPlane(1,1,1),image.Mask);
t.verifyEqual(image.IntensityDisplayRange,[.1 .9]);
% The retained subscription must still forward measurement updates.
[updates,dataListener] = observeDataChanges(image);
dataCleanup = onCleanup(@() delete(dataListener));
survivor.setMeasurements(struct('Area',4));
t.verifyEqual(updates(),1);
end

function testObjectTreeBatchDeletionUsesSameFlow(t)
%TESTOBJECTTREEBATCHDELETIONUSESSAMEFLOW Tree commands remove a checked set together.
ui = t.TestData.GUI; image = ui.Project.ActiveImage;
image.setSelectedObjects(image.Objects);
[events,listener] = observeObjectChanges(image);
cleanup = onCleanup(@() delete(listener));
menu = findall(ui.ObjectsTree.ContextMenu,'Type','uimenu','Text','Delete selected objects');
menu.MenuSelectedFcn(menu,[]);
t.verifyEqual(events(),1);
t.verifyEmpty(image.Objects); t.verifyEmpty(ui.ObjectsTree.Children);
t.verifyFalse(any(image.Mask,'all'));
t.verifyEmpty(ui.LeftViewer.Overlays.ids(Type="Polygon"));
end

function [read,listener] = observeObjectChanges(image)
%OBSERVEOBJECTCHANGES Count collection notifications without retaining deleted objects.
count = 0;
read = @getCount;
listener = addlistener(image,'ObjectsChanged',@increment);
    function value = getCount(), value = count; end
    function increment(~,~), count = count+1; end
end

function [read,listener] = observeDataChanges(image)
%OBSERVEDATACHANGES Check that survivor subscriptions still forward data events.
count = 0;
read = @getCount;
listener = addlistener(image,'DataChanged',@increment);
    function value = getCount(), value = count; end
    function increment(~,~), count = count+1; end
end
